from __future__ import annotations

import os
import pathlib
from dataclasses import dataclass

STATE_ROOT = pathlib.Path(os.environ.get(
    "IQ_TASK_STATE", pathlib.Path.home() / ".iq-task"))
VERSION = "0.2.0"
MAX_ARTIFACT_BYTES = 1_000_000
ENV_FILE = pathlib.Path.home() / "work" / ".env"
REPO = pathlib.Path(__file__).resolve().parent.parent

SERVER_HOST = "127.0.0.1"
SERVER_PORT = 46000
CERT_FILE = pathlib.Path.home() / "work" / "certs" / "iq-task.crt"
KEY_FILE = pathlib.Path.home() / "work" / "certs" / "iq-task.key"
EDGE_LOCAL_PORT = 46001
EDGE_K = 8
MAX_TEXT_BYTES = 4 * 1024 * 1024


def load_env_file(path: pathlib.Path) -> dict[str, str]:
    out: dict[str, str] = {}
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return out
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        out[key.strip()] = val.strip().strip('"').strip("'")
    return out


def env() -> dict[str, str]:
    return {**load_env_file(ENV_FILE), **os.environ}


def get_credentials() -> tuple[str, str]:
    e = env()
    return (e.get("IQ_TASK_LOGIN", "iq"),
            e.get("IQ_TASK_PASSWORD", ""))


def get_work_token() -> str:
    return env().get("IQ_WORK_TOKEN", "")


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
    stage_retries: int = 3
    review_cycles: int = 3
    max_files: int = 10
    max_related: int = 3
    max_file_processes: int = 40

    def validate(self) -> None:
        if self.max_context_tokens + self.max_output_tokens > 204_800 - 2_048:
            raise ValueError("context + output exceeds the server window")


def load_settings() -> Settings:
    e = env()
    s = Settings(
        base_url=e.get("MTPLX_URL", Settings.base_url),
        model=e.get("MTPLX_MODEL", Settings.model),
        api_key=e.get("MTPLX_API_KEY", Settings.api_key),
    )
    s.validate()
    return s
