from __future__ import annotations

import asyncio
import json
import os
import pathlib
import shutil
import time
import uuid

from .config import STATE_ROOT

RUNNING_STATUSES = ("QUEUED", "RUNNING", "BUILDING", "REVIEW")
TERMINAL_STATUSES = ("DONE", "FAILED", "INTERRUPTED")


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


def load_env_repo_sessions() -> dict[str, list[str]]:
    p = STATE_ROOT / "repo_sessions.json"
    try:
        return json.loads(p.read_text())
    except (OSError, ValueError):
        return {}


def save_repo_sessions(data: dict[str, list[str]]) -> None:
    _atomic_write(STATE_ROOT / "repo_sessions.json",
                  json.dumps(data).encode())


class Task:
    def __init__(self, data: dict):
        self.data = data

    # -- fields ----------------------------------------------------------
    @property
    def id(self) -> str:
        return self.data["id"]

    @property
    def text(self) -> str:
        return self.data.get("text", "")

    @property
    def repo(self) -> str:
        return self.data.get("repo", "")

    @property
    def path(self) -> pathlib.Path:
        return STATE_ROOT / "tasks" / self.id

    @property
    def stage(self) -> str:
        return self.data.get("stage", "")

    @stage.setter
    def stage(self, v: str) -> None:
        self.data["stage"] = v

    @property
    def status(self) -> str:
        return self.data.get("status", "QUEUED")

    @status.setter
    def status(self, v: str) -> None:
        self.data["status"] = v

    @property
    def sessions(self) -> dict[str, str]:
        return self.data.setdefault("sessions", {})

    @property
    def rounds(self) -> dict[str, dict]:
        return self.data.setdefault("rounds", {})

    @property
    def build_index(self) -> int:
        return self.data.get("build_index", 0)

    @property
    def builds_total(self) -> int:
        return self.data.get("builds_total", 0)

    @property
    def error(self) -> str:
        return self.data.get("error", "")

    @error.setter
    def error(self, v: str) -> None:
        self.data["error"] = v

    # -- disk ------------------------------------------------------------
    def save(self) -> None:
        self.data["updated_at"] = int(time.time())
        _atomic_write(self.path / "state.json",
                      json.dumps(self.data, indent=1).encode())

    def to_proto_dict(self) -> dict:
        d = self.data
        return {
            "id": d["id"],
            "text": d.get("text", ""),
            "repo": d.get("repo", ""),
            "stage": d.get("stage", ""),
            "status": d.get("status", ""),
            "build_index": d.get("build_index", 0),
            "builds_total": d.get("builds_total", 0),
            "error": d.get("error", ""),
            "created_at": d.get("created_at", 0),
            "updated_at": d.get("updated_at", 0),
            "stage_key": d.get("stage_key", ""),
            "review_cycle": d.get("review_cycle", 0),
        }

    def artifacts(self, name: str) -> pathlib.Path:
        return self.path / "artifacts" / name

    def transcript(self, stage_key: str) -> pathlib.Path:
        return self.path / "stages" / stage_key / "transcript.jsonl"

    def stop_file(self) -> pathlib.Path:
        return self.path / "STOP"


def create_task(text: str, repo: str) -> Task:
    now = int(time.time())
    t = Task({
        "id": uuid.uuid4().hex,
        "text": text,
        "repo": repo,
        "stage": "",
        "status": "QUEUED",
        "build_index": 0,
        "builds_total": 0,
        "error": "",
        "created_at": now,
        "updated_at": now,
        "sessions": {},
        "rounds": {},
    })
    t.path.mkdir(parents=True, exist_ok=True)
    t.save()
    return t


def load_task(task_id: str) -> Task | None:
    p = STATE_ROOT / "tasks" / task_id / "state.json"
    try:
        return Task(json.loads(p.read_text()))
    except (OSError, ValueError):
        return None


def load_repos() -> list[str]:
    p = STATE_ROOT / "repos.json"
    try:
        data = json.loads(p.read_text())
    except (OSError, ValueError):
        return []
    if not isinstance(data, list):
        return []
    return [str(x) for x in data]


class Registry:
    def __init__(self):
        self.tasks: dict[str, Task] = {}
        self.events: dict[str, list[asyncio.Queue]] = {}
        self._scanning = False

    def rescan(self) -> None:
        base = STATE_ROOT / "tasks"
        if not base.exists():
            return
        for d in base.iterdir():
            if not d.is_dir():
                continue
            t = load_task(d.name)
            if t is None:
                continue
            self.tasks[t.id] = t
            if t.status in RUNNING_STATUSES:
                t.status = "INTERRUPTED"
                t.error = "server restarted"
                t.save()

    def create(self, text: str, repo: str) -> Task:
        t = create_task(text, repo)
        self.tasks[t.id] = t
        self.events[t.id] = []
        return t

    def get(self, task_id: str) -> Task | None:
        t = self.tasks.get(task_id)
        if t is None:
            t = load_task(task_id)
            if t is not None:
                self.tasks[task_id] = t
                self.events.setdefault(task_id, [])
        return t

    def list(self) -> list[Task]:
        return sorted(self.tasks.values(), key=lambda t: t.data["created_at"])

    def delete(self, task: Task) -> None:
        self.tasks.pop(task.id, None)
        self.events.pop(task.id, None)
        shutil.rmtree(task.path, ignore_errors=True)

    def update(self, task: Task) -> None:
        task.save()
        for q in self.events.get(task.id, ()):
            if q.qsize() < 1000:
                q.put_nowait(task.to_proto_dict())

    def subscribers(self, task_id: str) -> list[asyncio.Queue]:
        return self.events.setdefault(task_id, [])
