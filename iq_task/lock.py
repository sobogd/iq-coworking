from __future__ import annotations

import fcntl
import os
import pathlib
import time

from .config import STATE_ROOT


class LLMLock:
    """flock on a shared file; LLM is serial, callers wait for their turn."""

    def __init__(self, path: pathlib.Path, holder: str = ""):
        self.path = path
        self.holder = holder
        self._fd: int | None = None

    def acquire(self, timeout: float = 900.0) -> bool:
        if self._fd is not None:
            return True
        self.path.parent.mkdir(parents=True, exist_ok=True)
        fd = os.open(self.path, os.O_RDWR | os.O_CREAT, 0o600)
        deadline = time.monotonic() + timeout
        while True:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() > deadline:
                    os.close(fd)
                    return False
                time.sleep(0.5)
        self._fd = fd
        pid_path = self.path.with_suffix(".pid")
        with open(pid_path, "w") as f:
            f.write(f"{os.getpid()} {self.holder}".strip())
            f.flush()
            os.fsync(f.fileno())
        return True

    def release(self) -> None:
        if self._fd is None:
            return
        try:
            fcntl.flock(self._fd, fcntl.LOCK_UN)
        finally:
            os.close(self._fd)
            self._fd = None

    def __enter__(self) -> "LLMLock":
        if not self.acquire():
            raise TimeoutError("llm lock timeout")
        return self

    def __exit__(self, *exc) -> None:
        self.release()


def llm_lock_holder(lock_path: pathlib.Path | None = None) -> str | None:
    path = lock_path or (STATE_ROOT / "llm.lock")
    pid_path = path.with_suffix(".pid")
    try:
        pid = int(pid_path.read_text().strip().split()[0])
    except (OSError, ValueError):
        return None
    try:
        os.kill(pid, 0)
    except OSError:
        return None
    try:
        return f"pid {pid}: {pid_path.read_text().strip()[len(str(pid)):].strip()}"
    except OSError:
        return f"pid {pid}"


def new_llm_lock(holder: str = "") -> LLMLock:
    return LLMLock(STATE_ROOT / "llm.lock", holder)