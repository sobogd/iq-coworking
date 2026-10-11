from __future__ import annotations

import json
import os
import pathlib
import subprocess

OUTPUT_CAP = 20_000
BASH_TIMEOUT = 300

ROLE_TOOLS = {
    "RESEARCH": ("read",),
    "ANALYST": ("read",),
    "ORCHESTRATOR": ("read",),
    "BUILD": ("read", "write", "edit", "bash"),
    "REVIEW": ("read", "bash"),
}

SCHEMAS = [
    {"type": "function", "function": {
        "name": "read",
        "description": ("Read a file, or list a directory (pass a directory "
                        "path, or empty for the repo root)."),
        "parameters": {"type": "object",
                       "properties": {"path": {"type": "string"}},
                       "required": ["path"]}}},
    {"type": "function", "function": {
        "name": "write",
        "description": "Create or fully overwrite a file with the given content.",
        "parameters": {"type": "object",
                       "properties": {"path": {"type": "string"},
                                     "content": {"type": "string"}},
                       "required": ["path", "content"]}}},
    {"type": "function", "function": {
        "name": "edit",
        "description": ("Replace one exact occurrence of oldText with newText. "
                        "oldText must match the file exactly and be unique."),
        "parameters": {"type": "object",
                       "properties": {"path": {"type": "string"},
                                     "oldText": {"type": "string"},
                                     "newText": {"type": "string"}},
                       "required": ["path", "oldText", "newText"]}}},
    {"type": "function", "function": {
        "name": "bash",
        "description": "Run a shell command in the repo root and return its output.",
        "parameters": {"type": "object",
                       "properties": {"command": {"type": "string"}},
                       "required": ["command"]}}},
]


def _cap(text: str) -> str:
    if len(text) <= OUTPUT_CAP:
        return text
    return text[:OUTPUT_CAP] + f"\n... [truncated, {len(text)} chars total]"


def _jail(root: pathlib.Path, path: str) -> pathlib.Path:
    p = (root / path).resolve() if not os.path.isabs(path) \
        else pathlib.Path(path).resolve()
    if not p.is_relative_to(root):
        raise PermissionError(f"path escapes repo jail: {path}")
    return p


def _read(root: pathlib.Path, path: str) -> str:
    p = _jail(root, path or ".")
    if not p.exists():
        return f"error: no such path: {path}"
    if p.is_dir():
        out = []
        for d in sorted(p.iterdir()):
            out.append(d.name + ("/" if d.is_dir() else ""))
        return _cap("\n".join(out) or "(empty directory)")
    try:
        data = p.read_bytes()
    except OSError as e:
        return f"error: {e}"
    if b"\0" in data[:8192]:
        return f"error: binary file: {path}"
    return _cap(data.decode("utf-8", "replace"))


def _write(root: pathlib.Path, path: str, content: str) -> str:
    p = _jail(root, path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    return f"wrote {len(content)} bytes to {path}"


def _edit(root: pathlib.Path, path: str, old: str, new: str) -> str:
    p = _jail(root, path)
    if not p.is_file():
        return f"error: no such file: {path}"
    text = p.read_text()
    n = text.count(old)
    if n == 0:
        return "error: oldText not found in the file"
    if n > 1:
        return f"error: oldText occurs {n} times, must be unique; add context"
    p.write_text(text.replace(old, new))
    return f"edited {path}"


def _bash(root: pathlib.Path, command: str) -> str:
    try:
        r = subprocess.run(command, shell=True, cwd=root,
                           capture_output=True, text=True,
                           timeout=BASH_TIMEOUT)
        out = (r.stdout or "") + (("\n[stderr]\n" + r.stderr) if r.stderr else "")
        return _cap(f"exit {r.returncode}\n{out}" or f"exit {r.returncode}")
    except subprocess.TimeoutExpired:
        return f"error: command timed out after {BASH_TIMEOUT}s"


def execute(name: str, args: dict, root: pathlib.Path,
            role: str) -> str:
    allowed = ROLE_TOOLS.get(role, ())
    if name not in allowed:
        return f"error: tool '{name}' is not allowed in stage {role} (allowed: {', '.join(allowed)})"
    try:
        if name == "read":
            return _read(root, args.get("path", ""))
        if name == "write":
            return _write(root, args.get("path", ""), args.get("content", ""))
        if name == "edit":
            return _edit(root, args.get("path", ""),
                         args.get("oldText", ""), args.get("newText", ""))
        if name == "bash":
            return _bash(root, args.get("command", ""))
        return f"error: unknown tool: {name}"
    except PermissionError as e:
        return f"error: {e}"
    except Exception as e:  # noqa: BLE001 — reported back to the model
        return f"error: {type(e).__name__}: {e}"
