from __future__ import annotations

import os
import pathlib
from dataclasses import dataclass

ENV_FILE = pathlib.Path("~/work/.env").expanduser()

STATE_ROOT = pathlib.Path(
    os.environ.get("IQ_TASK_STATE", "~/.iq-task")).expanduser()
SESS_DIR = STATE_ROOT / "sessions"

SERVER_HOST = "127.0.0.1"
SERVER_PORT = int(os.environ.get("IQ_TASK_PORT", "46000"))
CERT_FILE = pathlib.Path("~/work/certs").expanduser() / "iq-task.crt"
KEY_FILE = pathlib.Path("~/work/certs").expanduser() / "iq-task.key"
EDGE_K = int(os.environ.get("IQ_TASK_EDGE_K", "5"))

MAX_TEXT_BYTES = 4 * 1024 * 1024
VERSION = "0.3.0"


@dataclass(frozen=True)
class Settings:
    model: str = "mtplx-qwen38-27b-optimized-speed"
    base_url: str = "http://127.0.0.1:8000"
    api_key: str = "mtplx-local"
    client_header: str = "iq-task"
    max_context_tokens: int = 32_000
    max_output_tokens: int = 8_000
    temperature: float | None = 0.4
    top_p: float | None = 0.95
    max_turns: int = 80


def load_env_file(path: pathlib.Path = ENV_FILE) -> dict[str, str]:
    out: dict[str, str] = {}
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return out
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        k, v = k.strip(), v.strip()
        if k and (v.startswith('"') or v.startswith("'")) and v.endswith(v[0]) \
                and len(v) >= 2:
            v = v[1:-1]
        out[k] = v
    return out


def env() -> dict[str, str]:
    e = dict(load_env_file())
    e.update({k: v for k, v in os.environ.items() if v})
    return e


def get_credentials() -> tuple[str, str, str]:
    e = env()
    return e.get("IQ_TASK_LOGIN", "iq"), e.get("IQ_TASK_PASSWORD", ""), e.get("IQ_TASK_DEVICE", "")


def get_work_token() -> str:
    return env().get("IQ_WORK_TOKEN", "")


def load_settings() -> Settings:
    e = env()
    return Settings(
        model=e.get("MTPLX_MODEL", "mtplx-qwen38-27b-optimized-speed"),
        base_url=e.get("MTPLX_URL", "http://127.0.0.1:8000").rstrip("/"),
        api_key=e.get("MTPLX_API_KEY", "mtplx-local"),
        client_header="iq-task",
    )