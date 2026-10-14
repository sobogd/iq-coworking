from __future__ import annotations

import asyncio
import json
import pathlib
import secrets
import time

import grpc

from . import agent, mdstrip, task_pb2, task_pb2_grpc
from .config import (CERT_FILE, KEY_FILE, MAX_TEXT_BYTES, SERVER_HOST,
                     SERVER_PORT, VERSION, get_work_token)
from .state import BUSY, FAILED, Registry, STOPPED, Session, save_repo

ACTIVITY_LIMIT = 20
COMPLETE_DEBOUNCE = 0.4


def _act_msg(m: dict) -> task_pb2.ActivityMessage:
    tools = []
    for tc in m.get("tool_calls") or []:
        fn = tc.get("function") or {}
        name = fn.get("name", "")
        try:
            args = json.loads(fn.get("arguments") or "{}")
        except ValueError:
            args = {}
        s = str(args.get("path") or args.get("oldText") or "")[:120]
        tools.append(f"{name} {s}".strip())
    return task_pb2.ActivityMessage(
        role=m.get("role", ""),
        content=mdstrip.strip_markdown(m.get("content") or "")[:1500],
        tool_calls=tools,
        reasoning=mdstrip.strip_markdown(
            m.get("reasoning_content") or "")[:4000])


def _replay_messages(s: Session) -> list[dict]:
    msgs: list[dict] = []
    if not s.transcript.exists():
        return msgs
    for line in s.transcript.read_text().splitlines():
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if "compact" in obj:
            msgs.append(obj["compact"])
            msgs.extend(obj.get("tail", []))
        elif "m" in obj:
            msgs.append(obj["m"])
    return msgs


class HarnessServicer(task_pb2_grpc.HarnessServicer):
    def __init__(self, registry: Registry):
        self.registry = registry
        self.turns: dict[str, asyncio.Task] = {}
        self._complete_at: dict[str, float] = {}

    # -- auth ------------------------------------------------------------
    async def _check_token(self, context, public: bool) -> bool:
        if public:
            return True
        md = dict(context.invocation_metadata())
        token = md.get("x-iq-token", "")
        work = get_work_token()
        ok = bool(work) and secrets.compare_digest(token, work)
        if not ok:
            await context.abort(grpc.StatusCode.UNAUTHENTICATED, "bad token")
        return ok

    # -- rpcs ------------------------------------------------------------
    async def Ping(self, request, context):
        return task_pb2.PingResponse(version=VERSION,
                                     sessions=len(self.registry.sessions))

    async def Login(self, request, context):
        work = get_work_token()
        if not (work and secrets.compare_digest(request.token, work)):
            await context.abort(grpc.StatusCode.UNAUTHENTICATED,
                               "bad token")
            return None
        return task_pb2.LoginResponse(token=request.token)

    async def CreateSession(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        if len(request.message.encode()) > MAX_TEXT_BYTES:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "message too large")
            return None
        if len(request.system_prompt.encode()) > MAX_TEXT_BYTES:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "system prompt too large")
            return None
        repo = self._valid_repo(request.repo)
        if repo is None:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "repo must be an existing dir under $HOME")
            return None
        thinking = request.thinking or "low"
        if thinking not in ("off", "low", "medium", "xhigh"):
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "thinking must be off low medium or xhigh")
            return None
        if repo:
            save_repo(repo)
        s = self.registry.create(repo, request.system_prompt.strip(),
                                 request.message.strip(), thinking,
                                 request.context_tokens)
        agent._append(s.transcript, [{"role": "user",
                                      "content": request.message.strip()}])
        self._spawn(s)
        return self._to_proto(s)

    def _valid_repo(self, repo: str) -> str | None:
        if not repo:
            return ""
        p = pathlib.Path(repo).expanduser()
        if not p.is_absolute() or not p.is_dir():
            return None
        home = pathlib.Path.home().resolve()
        p = p.resolve()
        if p == home or not p.is_relative_to(home):
            return None
        return str(p)

    async def GetSession(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        s = self.registry.get(request.id)
        if s is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such session")
            return None
        return self._to_proto(s)

    async def ListSessions(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        return task_pb2.Sessions(
            sessions=[self._to_proto(s) for s in self.registry.list()])

    async def WatchSession(self, request, context):
        if not await self._check_token(context, public=False):
            return
        s = self.registry.get(request.id)
        if s is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such session")
            return
        queue: asyncio.Queue = asyncio.Queue()
        self.registry.subscribers(request.id).append(queue)
        try:
            proto = self._to_proto(s)
            while True:
                yield proto
                if proto.status != BUSY:
                    return
                try:
                    data = await asyncio.wait_for(queue.get(), timeout=30)
                except asyncio.TimeoutError:
                    continue  # heartbeat: re-yield the last snapshot
                proto = task_pb2.Session(**data)
        finally:
            subs = self.registry.subscribers(request.id)
            if queue in subs:
                subs.remove(queue)

    async def StopSession(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        s = self.registry.get(request.id)
        if s is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such session")
            return None
        s.stop_file().write_text("stop")
        if s.status != BUSY:
            s.status = STOPPED
            s.error = ""
            self.registry.update(s)
        return self._to_proto(s)

    async def ResumeSession(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        s = self.registry.get(request.id)
        if s is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such session")
            return None
        if s.status not in (STOPPED, FAILED):
            await context.abort(grpc.StatusCode.FAILED_PRECONDITION,
                               f"cannot resume from {s.status}")
            return None
        s.stop_file().unlink(missing_ok=True)
        s.error = ""
        s.status = BUSY
        self.registry.update(s)
        self._spawn(s)
        return self._to_proto(s)

    async def DeleteSession(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        s = self.registry.get(request.id)
        if s is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such session")
            return None
        if s.status == BUSY:
            await context.abort(grpc.StatusCode.FAILED_PRECONDITION,
                               "stop the session first")
            return None
        self.registry.delete(s)
        return task_pb2.SessionRef(id=s.id)

    async def SendMessage(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        text = request.text.strip()
        if not text:
            return self._to_proto(self._get_or_404(context, request.id))
        if len(text.encode()) > MAX_TEXT_BYTES:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "message too large")
            return None
        s = await self._get_or_404(context, request.id)
        if s is None:
            return None
        if s.status == BUSY:
            await context.abort(grpc.StatusCode.FAILED_PRECONDITION,
                               "session is busy")
            return None
        agent._append(s.transcript, [{"role": "user", "content": text}])
        s.stop_file().unlink(missing_ok=True)
        s.error = ""
        s.status = BUSY
        self.registry.update(s)
        self._spawn(s)
        return self._to_proto(s)

    async def GetActivity(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        s = await self._get_or_404(context, request.id)
        if s is None:
            return None
        msgs = _replay_messages(s)
        tail = msgs[-ACTIVITY_LIMIT:]
        return task_pb2.Activity(
            messages=[_act_msg(m) for m in tail],
            more=len(msgs) > ACTIVITY_LIMIT)

    async def ListDirs(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        home = pathlib.Path.home().resolve()
        p = pathlib.Path(request.path).expanduser()
        if not p.is_absolute():
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "path must be absolute")
            return None
        p = p.resolve()
        if not p.is_relative_to(home):
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                               "path must live under $HOME")
            return None
        if not p.is_dir():
            await context.abort(grpc.StatusCode.NOT_FOUND,
                               "no such directory")
            return None
        return task_pb2.Dirs(path=str(p), dirs=[
            str(d) for d in sorted(p.iterdir())
            if d.is_dir() and not d.name.startswith(".")])

    async def Complete(self, request, context):
        if not await self._check_token(context, public=False):
            return None
        s = await self._get_or_404(context, request.id)
        if s is None:
            return None
        now = time.monotonic()
        if now - self._complete_at.get(s.id, 0.0) < COMPLETE_DEBOUNCE:
            return task_pb2.CompleteResponse(text="")
        self._complete_at[s.id] = now
        text = await agent.complete_text(s, request.text)
        return task_pb2.CompleteResponse(text=text)

    # -- helpers -----------------------------------------------------------
    async def _get_or_404(self, context, session_id: str) -> Session | None:
        s = self.registry.get(session_id)
        if s is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, "no such session")
        return s

    def _to_proto(self, s: Session) -> task_pb2.Session:
        return task_pb2.Session(**s.to_proto_dict())

    def _spawn(self, s: Session) -> None:
        self.turns.pop(s.id, None)
        self.turns[s.id] = asyncio.create_task(
            agent.run_turn(self.registry, s), name=f"turn:{s.id}")


def start_server() -> tuple[grpc.aio.Server, HarnessServicer]:
    registry = Registry()
    registry.rescan()
    servicer = HarnessServicer(registry)
    server = grpc.aio.server()
    task_pb2_grpc.add_HarnessServicer_to_server(servicer, server)
    creds = grpc.ssl_server_credentials(
        [(KEY_FILE.read_bytes(), CERT_FILE.read_bytes())])
    server.add_secure_port(f"{SERVER_HOST}:{SERVER_PORT}", creds)
    return server, servicer


async def serve() -> None:
    server, servicer = start_server()
    await server.start()
    for s in servicer.registry.list():
        if s.status == BUSY:
            servicer._spawn(s)
    print(f"iq-task server on {SERVER_HOST}:{SERVER_PORT}")
    await server.wait_for_termination()
