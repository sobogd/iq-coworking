from __future__ import annotations

import os
import pathlib

OUTPUT_CAP = 20_000

SCHEMAS = [
    {"type": "function", "function": {
        "name": "read",
        "description": ("Read a file, or list a directory (pass a directory "
                        "path, or empty for the project root)."),
        "parameters": {"type": "object",
                       "properties": {
                           "path": {"type": "string"},
                           "offset": {"type": "integer",
                                      "description": "first line (1-based)"},
                           "limit": {"type": "integer",
                                    "description": "max lines to return"}},
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
]


def _cap(text: str) -> str:
    if len(text) <= OUTPUT_CAP:
        return text
    return text[:OUTPUT_CAP] + f"\n... [truncated, {len(text)} chars total]"


def _jail(root: pathlib.Path, path: str,
          mem: pathlib.Path | None = None) -> pathlib.Path:
    p = (root / path).resolve() if not os.path.isabs(path) \
        else pathlib.Path(path).resolve()
    if p.is_relative_to(root):
        return p
    if mem is not None and p.is_relative_to(mem):
        return p
    raise PermissionError("path escapes the project directory")


def _read(root: pathlib.Path, path: str,
          offset: int | None = None, limit: int | None = None,
          mem: pathlib.Path | None = None) -> str:
    p = _jail(root, path or ".", mem)
    if not p.exists():
        return f"error: no such path: {path}"
    if p.is_dir():
        out = [d.name + ("/" if d.is_dir() else "")
               for d in sorted(p.iterdir())]
        return _cap("\n".join(out) or "(empty directory)")
    try:
        data = p.read_bytes()
    except OSError as e:
        return f"error: {e}"
    if b"\0" in data[:8192]:
        return f"error: binary file: {path}"
    lines = data.decode("utf-8", "replace").splitlines()
    if offset is not None or limit is not None:
        start = max(int(offset or 1) - 1, 0)
        end = len(lines) if not limit else start + max(int(limit), 0)
        body = "\n".join(lines[start:end])
        return (f"lines {start + 1}-{start + len(lines[start:end])} of "
                f"{len(lines)}\n" + body)
    return _cap("\n".join(lines))


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


def execute(name: str, args: dict, root: pathlib.Path,
            mem: pathlib.Path | None = None) -> str:
    try:
        if name == "read":
            return _read(root, args.get("path", ""),
                         args.get("offset"), args.get("limit"), mem)
        if name == "write":
            return _write(root, args.get("path", ""), args.get("content", ""))
        if name == "edit":
            return _edit(root, args.get("path", ""),
                         args.get("oldText", ""), args.get("newText", ""))
        return f"error: unknown tool: {name}"
    except PermissionError as e:
        return f"error: {e}"
    except Exception as e:  # noqa: BLE001 — reported back to the model
        return f"error: {type(e).__name__}: {e}"
