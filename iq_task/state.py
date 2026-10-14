from __future__ import annotations

import asyncio
import json
import os
import pathlib
import shutil
import time
import uuid

from .config import SESS_DIR

IDLE = "IDLE"
BUSY = "BUSY"
STOPPED = "STOPPED"
FAILED = "FAILED"
# statuses from which the session can be resumed
RESUMABLE = (STOPPED, FAILED)
# statuses that stop the Watch stream (everything except BUSY)
ACTIVE = (BUSY,)


def _atomic_write(path: pathlib.Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + f".tmp{os.getpid()}")
    with open(tmp, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)
    dfd = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(dfd)
    finally:
        os.close(dfd)


class Session:
    def __init__(self, data: dict):
        self.data = data

    @property
    def id(self) -> str:
        return self.data["id"]

    @property
    def repo(self) -> str:
        return self.data.get("repo", "")

    @property
    def system_prompt(self) -> str:
        return self.data.get("system_prompt", "")

    @property
    def title(self) -> str:
        return self.data.get("title", "")

    @title.setter
    def title(self, v: str) -> None:
        self.data["title"] = v

    @property
    def status(self) -> str:
        return self.data.get("status", IDLE)

    @status.setter
    def status(self, v: str) -> None:
        self.data["status"] = v

    @property
    def error(self) -> str:
        return self.data.get("error", "")

    @error.setter
    def error(self, v: str) -> None:
        self.data["error"] = v

    @property
    def mtplx_session_id(self) -> str:
        return self.data.get("mtplx_session_id", "")

    @mtplx_session_id.setter
    def mtplx_session_id(self, v: str) -> None:
        self.data["mtplx_session_id"] = v

    @property
    def thinking(self) -> str:
        return self.data.get("thinking") or "low"

    @property
    def context_tokens(self) -> int:
        return int(self.data.get("context_tokens") or 32_000)

    @property
    def path(self) -> pathlib.Path:
        return SESS_DIR / self.id

    @property
    def transcript(self) -> pathlib.Path:
        return self.path / "transcript.jsonl"

    def stop_file(self) -> pathlib.Path:
        return self.path / "STOP"

    def is_stopped(self) -> bool:
        return self.stop_file().exists()

    def save(self) -> None:
        self.data["updated_at"] = int(time.time())
        _atomic_write(self.path / "state.json",
                      json.dumps(self.data, indent=1).encode())

    def to_proto_dict(self) -> dict:
        d = self.data
        return {
            "id": d["id"],
            "repo": d.get("repo", ""),
            "system_prompt": d.get("system_prompt", ""),
            "title": d.get("title", ""),
            "status": d.get("status", IDLE),
            "error": d.get("error", ""),
            "created_at": d.get("created_at", 0),
            "updated_at": d.get("updated_at", 0),
            "thinking": d.get("thinking") or "low",
            "context_tokens": int(d.get("context_tokens") or 32_000),
        }


def create_session(repo: str, system_prompt: str, message: str,
                   thinking: str = "low",
                   context_tokens: int = 0) -> Session:
    if thinking not in ("off", "low", "medium", "xhigh"):
        thinking = "low"
    if not 4_096 <= int(context_tokens or 0) <= 204_800:
        context_tokens = 32_000
    now = int(time.time())
    title = (message.strip().splitlines() or [""])[0][:80]
    s = Session({
        "id": uuid.uuid4().hex,
        "repo": repo,
        "system_prompt": system_prompt,
        "title": title,
        "status": IDLE,
        "error": "",
        "mtplx_session_id": uuid.uuid4().hex,
        "thinking": thinking,
        "context_tokens": context_tokens,
        "created_at": now,
        "updated_at": now,
    })
    s.path.mkdir(parents=True, exist_ok=True)
    s.save()
    return s


def load_session(session_id: str) -> Session | None:
    p = SESS_DIR / session_id / "state.json"
    try:
        return Session(json.loads(p.read_text()))
    except (OSError, ValueError):
        return None


def load_repos() -> list[str]:
    p = SESS_DIR.parent / "repos.json"
    try:
        data = json.loads(p.read_text())
    except (OSError, ValueError):
        return []
    if not isinstance(data, list):
        return []
    return [str(x) for x in data]


def save_repo(path: str) -> None:
    repos = load_repos()
    if path not in repos:
        p = SESS_DIR.parent / "repos.json"
        _atomic_write(p, json.dumps(repos + [path]).encode())


class Registry:
    def __init__(self):
        self.sessions: dict[str, Session] = {}
        self.events: dict[str, list[asyncio.Queue]] = {}

    def rescan(self) -> None:
        if not SESS_DIR.exists():
            return
        for d in SESS_DIR.iterdir():
            if not d.is_dir():
                continue
            s = load_session(d.name)
            if s is None:
                continue
            self.sessions[s.id] = s
            self.events.setdefault(s.id, [])
            if s.status in ACTIVE:
                s.status = STOPPED
                s.error = "server restarted"
                s.save()

    def create(self, repo: str, system_prompt: str, message: str,
               thinking: str = "low",
               context_tokens: int = 0) -> Session:
        s = create_session(repo, system_prompt, message, thinking,
                           context_tokens)
        self.sessions[s.id] = s
        self.events.setdefault(s.id, [])
        return s

    def get(self, session_id: str) -> Session | None:
        s = self.sessions.get(session_id)
        if s is None:
            s = load_session(session_id)
            if s is not None:
                self.sessions[session_id] = s
                self.events.setdefault(session_id, [])
        return s

    def list(self) -> list[Session]:
        return sorted(self.sessions.values(),
                      key=lambda s: s.data["created_at"])

    def delete(self, session: Session) -> None:
        self.sessions.pop(session.id, None)
        self.events.pop(session.id, None)
        shutil.rmtree(session.path, ignore_errors=True)

    def update(self, session: Session) -> None:
        session.save()
        for q in self.events.get(session.id, ()):
            if q.qsize() < 1000:
                q.put_nowait(session.to_proto_dict())

    def subscribers(self, session_id: str) -> list[asyncio.Queue]:
        return self.events.setdefault(session_id, [])
