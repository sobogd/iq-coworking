from __future__ import annotations

import asyncio
import secrets
import time

import grpc

from . import task_pb2, task_pb2_grpc
from .config import (CERT_FILE, KEY_FILE, MAX_TEXT_BYTES, SERVER_HOST,
                     SERVER_PORT, get_credentials, get_work_token)
from .pipeline import run_pipeline
from .state import Registry, Task, load_task

TOKEN_TTL = 86_400
LOGIN_RATE = (5, 60)


class HarnessServicer(task_pb2_grpc.HarnessServicer):
    def __init__(self, registry: Registry):
        self.registry = registry
        self.tokens: dict[str, float] = {}
        self.login_hits: list[float] = []
        self.pipelines: dict[str, asyncio.Task] = {}

    # -- auth helpers ------------------------------------------------------
    async def _check_token(self, context, public: bool) -> bool:
        if public:
            return True
        md = dict(context.invocation_metadata())
        token = md.get("x-iq-token", "")
        work = get_work_token()
        if work and secrets.compare_digest(token, work):
            return True
        exp = self.tokens.get(token)
        if exp is None or time.time() > exp:
            await context.abort(grpc.StatusCode.UNAUTHENTICATED, "bad token")
            return False
        return True

    def _drop_expired(self) -> None:
        now = time.time()
        for t in [t for t, e in self.tokens.items() if now > e]:
            del self.tokens[t]
        self.login_hits = [t for t in self.login_hits if now - t < LOGIN_RATE[1]]

    # -- rpcs --------------------------------------------------------------
    async def Login(self, request, context):
        if get_work_token():
            await context.abort(grpc.StatusCode.UNAUTHENTICATED,
                               "login disabled: IQ_WORK_TOKEN in use")
            return None
        login, password, _ = get_credentials()
        self._drop_expired()
        if (len(self.login_hits) >= LOGIN_RATE[0]
                and time.time() - self.login_hits[-1] < LOGIN_RATE[1]):
            await context.abort(
                grpc.StatusCode.RESOURCE_EXHAUSTED, "too many logins")
            return None
        self.login_hits.append(time.time())
        if login and (request.login != login or request.password != password):
            await context.abort(
                grpc.StatusCode.UNAUTHENTICATED, "bad credentials")
            return None
        token = secrets.token_hex(16)
        self.tokens[token] = time.time() + TOKEN_TTL
        return task_pb2.LoginResponse(token=token,
                                      expires_at=int(time.time()) + TOKEN_TTL)

    async def CreateTask(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        if len(request.text.encode()) > MAX_TEXT_BYTES:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "text too large")
            return None
        import pathlib
        repo = request.repo
        p = pathlib.Path(repo).expanduser()
        if not p.is_absolute() or not p.exists() or not p.is_dir():
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "bad repo path")
            return None
        home = pathlib.Path.home()
        if not p.resolve().is_relative_to(home) or p.resolve() == home:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "repo must live under $HOME")
            return None
        task = self.registry.create(request.text, str(p.resolve()))
        self._spawn(task)
        return self._to_proto(task)

    async def GetTask(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        t = self.registry.get(request.id)
        if t is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
            return None
        return self._to_proto(t)

    async def ListTasks(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        return task_pb2.Tasks(
            tasks=[self._to_proto(t) for t in self.registry.list()])

    async def WatchTask(self, request, context):
        if not await self._check_token(context, public=False):
            return
        t = self.registry.get(request.id)
        if t is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
            return
        queue: asyncio.Queue = asyncio.Queue()
        self.registry.subscribers(request.id).append(queue)
        try:
            yield self._to_proto(t)
            while True:
                try:
                    data = await asyncio.wait_for(queue.get(), timeout=30)
                except asyncio.TimeoutError:
                    continue
                task = task_pb2.Task(**data)
                yield task
                if task.status in ("DONE", "FAILED", "INTERRUPTED"):
                    return
        finally:
            subs = self.registry.subscribers(request.id)
            if queue in subs:
                subs.remove(queue)

    async def StopTask(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        t = self.registry.get(request.id)
        if t is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
            return None
        t.stop_file().write_text("stop")
        return self._to_proto(t)

    async def ResumeTask(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        t = self.registry.get(request.id)
        if t is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
            return None
        if t.status not in ("INTERRUPTED", "FAILED"):
            await context.abort(grpc.StatusCode.FAILED_PRECONDITION,
                               f"cannot resume from {t.status}")
            return None
        t.stop_file().unlink(missing_ok=True)
        t.error = ""
        self.registry.update(t)
        self._spawn(t)
        return self._to_proto(t)

    # -- helpers -------------------------------------------------------------
    def _to_proto(self, t: Task) -> task_pb2.Task:
        return task_pb2.Task(**t.to_proto_dict())

    def _spawn(self, t: Task) -> None:
        self.pipelines.pop(t.id, None)
        self.pipelines[t.id] = asyncio.create_task(
            self._drive(t), name=f"pipeline:{t.id}")

    async def _drive(self, t: Task) -> None:
        try:
            await run_pipeline(t, self.registry)
        except Exception:
            pass
        finally:
            self.pipelines.pop(t.id, None)
            self.registry.update(t)


def start_server() -> tuple[grpc.aio.Server, HarnessServicer]:
    registry = Registry()
    registry.rescan()
    servicer = HarnessServicer(registry)
    server = grpc.aio.server()
    task_pb2_grpc.add_HarnessServicer_to_server(servicer, server)
    key = KEY_FILE.read_bytes()
    cert = CERT_FILE.read_bytes()
    creds = grpc.ssl_server_credentials([(key, cert)])
    server.add_secure_port(f"{SERVER_HOST}:{SERVER_PORT}", creds)
    return server, servicer


async def serve() -> None:
    server, servicer = start_server()
    await server.start()
    for t in servicer.registry.list():
        if t.status == "QUEUED":
            servicer._spawn(t)
    print(f"iq-task server on {SERVER_HOST}:{SERVER_PORT}")
    await server.wait_for_termination()
