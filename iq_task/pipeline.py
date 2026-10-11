"""Parent-side pipeline machine: spawns stage children, validates
artifacts, runs checks, drives the review loop."""
from __future__ import annotations

import asyncio
import json
import pathlib
import re
import subprocess
import sys

from . import prompts
from .config import load_settings
from .state import Registry, Task, load_env_repo_sessions, save_repo_sessions


class StageFailed(Exception):
    def __init__(self, stage_key: str, reason: str):
        super().__init__(f"{stage_key}: {reason}")
        self.stage_key = stage_key
        self.reason = reason


class Stopped(Exception):
    pass


def _topo(items: list[dict], id_field: str = "id") -> list[dict]:
    by_id = {it[id_field]: it for it in items}
    for it in items:
        for dep in it.get("depends_on") or []:
            if dep not in by_id:
                raise ValueError(f"dangling dep {dep} in {it[id_field]}")
    state: dict[str, int] = {}
    order: list[dict] = []

    def visit(node: dict, stack: list[str]) -> None:
        nid = node[id_field]
        if state.get(nid) == 1:
            raise ValueError(f"cycle at {nid}")
        if state.get(nid) == 2:
            return
        state[nid] = 1
        for dep in node.get("depends_on") or []:
            visit(by_id[dep], stack + [nid])
        state[nid] = 2
        order.append(node)

    for it in items:
        visit(it, [])
    return order


def _last_assistant_message(transcript: pathlib.Path) -> str | None:
    text = None
    if not transcript.exists():
        return None
    for line in transcript.read_text().splitlines():
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        m = obj.get("m")
        if m is None and isinstance(obj.get("tail"), list):
            for t in obj["tail"]:
                if t.get("role") == "assistant":
                    text = t.get("content")
        if m is not None and m.get("role") == "assistant":
            text = m.get("content")
    return text


async def _run_stage(task: Task, key: str, stage_input: dict,
                     registry: Registry, settings) -> str:
    """Run one stage child (with retries); return final assistant text."""
    log_path = task.path / "logs" / f"{key.replace('/', '_')}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    last_err = ""
    for attempt in range(1, settings.stage_retries + 1):
        if task.stop_file().exists():
            raise Stopped()
        task.data["stage_input"] = stage_input
        task.save()
        registry.update(task)
        with open(log_path, "a") as log:
            log.write(f"\n=== attempt {attempt} ===\n")
            log.flush()
            proc = await asyncio.create_subprocess_exec(
                sys.executable, "-m", "iq_task", "stage", task.id, key,
                stdout=log, stderr=subprocess.STDOUT,
                cwd=str(pathlib.Path(__file__).parent.parent))
            code = await proc.wait()
        if task.stop_file().exists():
            raise Stopped()
        if code == 0:
            text = _last_assistant_message(task.transcript(key))
            if text is not None:
                return text
            last_err = "stage exited 0 without a final message"
        elif code == 3:
            raise Stopped()
        else:
            last_err = f"exit {code}"
        await asyncio.sleep(2.0)
    raise StageFailed(key, last_err)


async def _run_stage_json(task: Task, key: str, stage_input: dict,
                          registry: Registry, settings):
    for _ in range(settings.stage_retries):
        text = await _run_stage(task, key, stage_input, registry, settings)
        obj = prompts.json_block(text)
        if obj is not None:
            return obj
        tp = task.transcript(key)
        note = {"role": "user",
                "content": "Your previous final message had no valid JSON "
                           "artifact (unbalanced braces or bad syntax). "
                           "Send the artifact again: one ```json fenced "
                           "block, nothing else."}
        with open(tp, "a") as f:
            f.write(json.dumps({"m": note}, ensure_ascii=False) + "\n")
            f.flush()
    raise StageFailed(key, "no valid JSON artifact in final message")


def clear_repo_sessions(task: Task) -> None:
    repos = load_env_repo_sessions()
    old = repos.get(task.repo, [])
    if not old:
        return
    import httpx
    s = load_settings()
    headers = {"Content-Type": "application/json",
               "Authorization": f"Bearer {s.api_key}",
               "x-mtplx-client": s.client_header}
    for sid in old:
        try:
            httpx.post(s.base_url.rstrip("/")
                       + f"/admin/sessions/{sid}/clear",
                       headers=headers, timeout=10)
        except Exception:
            pass


def _record_repo_sessions(task: Task) -> None:
    repos = load_env_repo_sessions()
    repos[task.repo] = list(task.sessions.values())
    save_repo_sessions(repos)


async def _run_check(repo: str, check: str) -> tuple[bool, str]:
    def _go(cmd: str) -> tuple[int, str]:
        try:
            r = subprocess.run(cmd, shell=True, cwd=repo,
                               capture_output=True, text=True, timeout=300)
            out = ((r.stdout or "") + (r.stderr or ""))
            return r.returncode, out[-4000:]
        except subprocess.TimeoutExpired:
            return 124, "check timed out after 300s"

    code, out = await asyncio.to_thread(_go, check)
    if code == 127 and "command not found" in out:
        alt = re.sub(r"\bpython\b", "python3", check)
        if alt != check:
            code, out = await asyncio.to_thread(_go, alt)
    return code == 0, out


def _changed_files(repo: str) -> list[str]:
    try:
        r = subprocess.run("git diff --name-only HEAD", shell=True, cwd=repo,
                           capture_output=True, text=True, timeout=30)
        names = r.stdout.split()
        if names:
            return names
        r = subprocess.run("git status --porcelain", shell=True, cwd=repo,
                           capture_output=True, text=True, timeout=30)
        return [ln[3:] for ln in r.stdout.splitlines() if len(ln) > 3]
    except Exception:
        return []


def _validate_files(obj, repo: pathlib.Path, max_files: int):
    files = obj.get("files")
    if not isinstance(files, list) or not files:
        raise ValueError("artifact: 'files' must be a non-empty list")
    if len(files) > max_files:
        raise ValueError(f"artifact: {len(files)} files, max {max_files}")
    out = []
    for f in files:
        p = str(f.get("path", ""))
        rp = (repo / p).resolve()
        if not rp.is_relative_to(repo) or not rp.is_file():
            raise ValueError(f"artifact: file not found: {p}")
        out.append({"path": p, "purpose": str(f.get("purpose", ""))})
    return out


def _validate_plan(obj) -> list[dict]:
    steps = obj.get("steps")
    if not isinstance(steps, list) or not steps or len(steps) > 50:
        raise ValueError("artifact: 'steps' must be a list (1..50)")
    ids = set()
    for s in steps:
        sid = str(s.get("id", ""))
        if not sid or sid in ids:
            raise ValueError(f"artifact: bad or duplicate step id: {sid}")
        ids.add(sid)
        if not str(s.get("goal", "")).strip():
            raise ValueError(f"artifact: step {sid} has no goal")
    _topo(steps)
    return steps


def _validate_specs(obj, repo: pathlib.Path) -> list[dict]:
    specs = obj.get("specs")
    if not isinstance(specs, list) or not specs or len(specs) > 50:
        raise ValueError("artifact: 'specs' must be a list (1..50)")
    ids = set()
    for s in specs:
        sid = str(s.get("id", ""))
        if not sid or sid in ids:
            raise ValueError(f"artifact: bad or duplicate spec id: {sid}")
        ids.add(sid)
        if not str(s.get("goal", "")).strip():
            raise ValueError(f"artifact: spec {sid} has no goal")
        check = str(s.get("check", "")).strip()
        if not check:
            raise ValueError(f"artifact: spec {sid} has no check command")
    out = _topo(specs)
    return [{**s, "check": str(s.get("check", ""))} for s in out]


def _set(task: Task, registry: Registry, stage: str, status: str) -> None:
    task.stage = stage
    task.status = status
    registry.update(task)


async def run_pipeline(task: Task, registry: Registry) -> None:
    settings = load_settings()
    repo = pathlib.Path(task.repo)
    try:
        await asyncio.to_thread(clear_repo_sessions, task)

        _set(task, registry, "RESEARCH", "RUNNING")
        obj = await _run_stage_json(task, "RESEARCH_1A", {}, registry, settings)
        files = _validate_files(obj, repo, settings.max_files)

        research_parts = []
        related: set[str] = set()
        used = 0
        for f in files:
            key = "RESEARCH_file:" + f["path"].replace("/", "__")
            text = await _run_stage(
                task, key, {"path": f["path"], "purpose": f["purpose"]},
                registry, settings)
            a = prompts.json_block(text) or {}
            research_parts.append(
                f"## {f['path']}\n"
                f"{a.get('analysis', text)[:3000]}")
            for rf in (a.get("related_files") or [])[:settings.max_related]:
                if rf not in {x["path"] for x in files}:
                    related.add(str(rf))
        for rf in sorted(related):
            if used >= settings.max_file_processes:
                break
            used += 1
            rp = (repo / rf).resolve()
            if not rp.is_relative_to(repo) or not rp.is_file():
                continue
            key = "RESEARCH_related:" + rf.replace("/", "__")
            text = await _run_stage(task, key, {"path": rf}, registry,
                                    settings)
            a = prompts.json_block(text) or {}
            research_parts.append(f"## {rf} (related)\n"
                                  f"{a.get('analysis', text)[:2000]}")
        research_md = "\n\n".join(research_parts)
        (task.path / "artifacts" / "research.md").parent.mkdir(
            parents=True, exist_ok=True)
        (task.path / "artifacts" / "research.md").write_text(research_md)

        _set(task, registry, "ANALYST", "RUNNING")
        obj = await _run_stage_json(task, "ANALYST",
                                    {"research_md": research_md[:100_000]},
                                    registry, settings)
        plan = _validate_plan(obj)
        (task.path / "artifacts" / "plan.json").write_text(
            json.dumps({"steps": plan}, indent=1))

        _set(task, registry, "ORCHESTRATOR", "RUNNING")
        obj = await _run_stage_json(task, "ORCHESTRATOR", {"plan": {"steps": plan}},
                                    registry, settings)
        specs = _validate_specs(obj, repo)
        (task.path / "artifacts" / "specs.json").write_text(
            json.dumps({"specs": specs}, indent=1))
        task.data["builds_total"] = len(specs)
        task.data["build_index"] = 0

        for i, spec in enumerate(specs):
            _set(task, registry, "BUILD", "BUILDING")
            task.data["build_index"] = i
            registry.update(task)
            ok = False
            err_tail = ""
            for attempt in range(1, settings.stage_retries + 1):
                if task.stop_file().exists():
                    raise Stopped()
                payload = dict(spec)
                if err_tail:
                    payload["previous_check_error"] = err_tail
                key = f"BUILD_{spec['id'].replace('/', '_')}"
                await _run_stage(task, key, {"spec": payload}, registry,
                                 settings)
                ok, out = await _run_check(task.repo, spec["check"])
                if ok:
                    break
                err_tail = out[-4000:]
            if not ok:
                task.error = f"spec {spec['id']} check failed: {err_tail[-500:]}"
                _set(task, registry, "BUILD", "FAILED")
                raise StageFailed(spec["id"], "check failed after retries")

        files_changed = _changed_files(task.repo)
        for cycle in range(1, settings.review_cycles + 1):
            if task.stop_file().exists():
                raise Stopped()
            _set(task, registry, "REVIEW", "REVIEW")
            obj = await _run_stage_json(
                task, "REVIEW",
                {"files": files_changed, "specs": specs}, registry, settings)
            verdict = str(obj.get("verdict", "")).upper()
            issues = [str(x) for x in obj.get("issues") or []]
            (task.path / "artifacts" / f"verdict-{cycle}.json").write_text(
                json.dumps({"verdict": verdict, "issues": issues}, indent=1))
            if verdict == "PASS":
                _set(task, registry, "DONE", "DONE")
                _record_repo_sessions(task)
                return
            if cycle == settings.review_cycles:
                task.error = f"review FAILED: {issues[:5]}"
                _set(task, registry, "REVIEW", "FAILED")
                _record_repo_sessions(task)
                return
            await _run_stage(task, "FIX", {"issues": issues}, registry,
                             settings)
            files_changed = _changed_files(task.repo)
        _record_repo_sessions(task)

    except Stopped:
        task.error = "stopped"
        _set(task, registry, task.stage or "", "FAILED")
    except StageFailed as e:
        task.error = str(e)
        _set(task, registry, task.stage or "", "FAILED")
        _record_repo_sessions(task)
    except Exception as e:
        task.error = f"{type(e).__name__}: {e}"
        _set(task, registry, task.stage or "", "FAILED")
        _record_repo_sessions(task)
