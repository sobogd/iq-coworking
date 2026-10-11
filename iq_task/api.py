from __future__ import annotations

import asyncio
import secrets
import time

import grpc

from . import task_pb2, task_pb2_grpc
from .config import (MAX_TEXT_BYTES, SERVER_HOST, SERVER_PORT,
                     get_credentials)
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
    def _check_token(self, context, public: bool) -> None:
        if public:
            return
        md = dict(context.invocation_metadata())
        token = md.get("x-iq-token", "")
        exp = self.tokens.get(token)
        if exp is None or time.time() > exp:
            context.abort(grpc.StatusCode.UNAUTHENTICATED, "bad token")

    def _drop_expired(self) -> None:
        now = time.time()
        for t in [t for t, e in self.tokens.items() if now > e]:
            del self.tokens[t]
        self.login_hits = [t for t in self.login_hits if now - t < LOGIN_RATE[1]]

    # -- rpcs --------------------------------------------------------------
    async def Login(self, request, context):
        login, password, _ = get_credentials()
        self._drop_expired()
        if (len(self.login_hits) >= LOGIN_RATE[0]
                and time.time() - self.login_hits[-1] < LOGIN_RATE[1]):
            context.abort(grpc.StatusCode.RESOURCE_EXHAUSTED, "too many logins")
        self.login_hits.append(time.time())
        if login and (request.login != login or request.password != password):
            context.abort(grpc.StatusCode.UNAUTHENTICATED, "bad credentials")
        token = secrets.token_hex(16)
        self.tokens[token] = time.time() + TOKEN_TTL
        return task_pb2.LoginResponse(token=token,
                                      expires_at=int(time.time()) + TOKEN_TTL)

    async def CreateTask(self, request, context):
        self._check_token(context, public=False)
        if len(request.text.encode()) > MAX_TEXT_BYTES:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, "text too large")
        import pathlib
        repo = request.repo
        p = pathlib.Path(repo).expanduser()
        if not p.is_absolute() or not p.exists() or not p.is_dir():
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, "bad repo path")
        home = pathlib.Path.home()
        if not p.resolve().is_relative_to(home) or p.resolve() == home:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                          "repo must live under $HOME")
        task = self.registry.create(request.text, str(p.resolve()))
        self._spawn(task)
        return self._to_proto(task)

    async def GetTask(self, request, context):
        self._check_token(context, public=False)
        t = self.registry.get(request.id)
        if t is None:
            context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
        return self._to_proto(t)

    async def ListTasks(self, request, context):
        self._check_token(context, public=False)
        return task_pb2.Tasks(
            tasks=[self._to_proto(t) for t in self.registry.list()])

    async def WatchTask(self, request, context):
        self._check_token(context, public=False)
        t = self.registry.get(request.id)
        if t is None:
            context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
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
        self._check_token(context, public=False)
        t = self.registry.get(request.id)
        if t is None:
            context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
        t.stop_file().write_text("stop")
        return self._to_proto(t)

    async def ResumeTask(self, request, context):
        self._check_token(context, public=False)
        t = self.registry.get(request.id)
        if t is None:
            context.abort(grpc.StatusCode.NOT_FOUND, "no such task")
        if t.status not in ("INTERRUPTED", "FAILED"):
            context.abort(grpc.StatusCode.FAILED_PRECONDITION,
                          f"cannot resume from {t.status}")
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
    server.add_insecure_port(f"{SERVER_HOST}:{SERVER_PORT}")
    return server, servicer


async def serve() -> None:
    server, servicer = start_server()
    await server.start()
    for t in servicer.registry.list():
        if t.status == "QUEUED":
            servicer._spawn(t)
    print(f"iq-task server on {SERVER_HOST}:{SERVER_PORT}")
    await server.wait_for_termination()
