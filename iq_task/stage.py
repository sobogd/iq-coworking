"""One pipeline stage: child process with an LLM agent loop.

Transcript: stages/<stage_key>/transcript.jsonl, one JSON object per line:
{"m": <message>} — a finished message (assistant or tool result)
{"compact": <message>, "tail": <messages>} — compaction point; the working
history restarts from it. Incomplete turns are never written, so resume
replays a consistent prefix into the same mtplx session (KV warm).
"""
from __future__ import annotations

import asyncio
import json
import pathlib
import sys

from . import prompts
from .config import load_settings
from .llm import LLMClient, LLMError, ContextOverflowError
from .lock import new_llm_lock
from .state import load_task
from .tools import SCHEMAS, ROLE_TOOLS, execute

COMPACT_SYSTEM = (
    "Summarize this coding-agent transcript as a brief with exactly these "
    "sections, factual bullets, under 400 words total: ## Segment — what "
    "happened: decisions, files changed, commands run, errors fixed. "
    "## State — where the work stands. ## Next — remaining steps "
    "(empty if done).")


def _load_working(transcript_path: pathlib.Path,
                  system: dict) -> tuple[list[dict], bool]:
    messages = [system]
    if not transcript_path.exists():
        return messages, False
    for line in transcript_path.read_text().splitlines():
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if "compact" in obj:
            messages = [system, obj["compact"]]
            messages.extend(obj.get("tail", []))
        elif "m" in obj:
            messages.append(obj["m"])
    _drop_dangling(messages)
    return messages, True


def _drop_dangling(messages: list[dict]) -> None:
    answered = {m.get("tool_call_id") for m in messages
                if m.get("role") == "tool"}
    out = []
    for m in messages:
        if m.get("role") == "assistant" and m.get("tool_calls"):
            missing = {tc["id"] for tc in m["tool_calls"]} - answered
            if missing:
                continue
        out.append(m)
    del messages[:]
    messages.extend(out)


def _append(transcript_path: pathlib.Path, batch: list[dict]) -> None:
    transcript_path.parent.mkdir(parents=True, exist_ok=True)
    with open(transcript_path, "a") as f:
        for m in batch:
            f.write(json.dumps({"m": m}, ensure_ascii=False) + "\n")
        f.flush()
        import os
        os.fsync(f.fileno())


async def _compact(client: LLMClient, settings, task, messages: list[dict],
                   transcript_path: pathlib.Path) -> list[dict]:
    body = messages[1:]
    keep = max(2, min(10, len(body)))
    cut = len(body) - keep
    while cut > 0 and body[cut].get("role") == "tool":
        cut += 1
    to_summarize, tail = body[:cut], body[cut:]
    if not to_summarize:
        return messages
    flat = []
    for m in to_summarize:
        role = m.get("role", "?")
        content = (m.get("content") or "")[:1500]
        tcs = m.get("tool_calls") or []
        extra = (" [tools: " +
                 "; ".join(t.get("name", "?") for t in tcs) + "]") if tcs else ""
        flat.append(f"[{role}] {content}{extra}")
    summary_client = LLMClient(settings)
    try:
        summary = await summary_client.complete(
            [{"role": "system", "content": COMPACT_SYSTEM},
             {"role": "user", "content": "\n".join(flat)[:120_000]}],
            max_tokens=2000)
    except LLMError:
        await summary_client.close()
        return messages
    await summary_client.close()
    brief = {"role": "user",
             "content": f"[Context compacted]\n{summary}"}
    new_msgs = [messages[0], brief, *tail]
    with open(transcript_path, "a") as f:
        f.write(json.dumps({"compact": brief, "tail": tail},
                           ensure_ascii=False) + "\n")
        f.flush()
        import os
        os.fsync(f.fileno())
    client.session_id = client.new_session_id()
    task.sessions[transcript_path.parent.name] = client.session_id
    task.save()
    return new_msgs


async def run_stage(task, stage_key: str, settings) -> int:
    root = pathlib.Path(task.repo)
    role = stage_key.split("_")[0]
    if stage_key == "RESEARCH_1A":
        system, user = prompts.research_1a(task.text)
    elif stage_key.startswith("RESEARCH_file:"):
        p = task.data["stage_input"]["path"]
        purpose = task.data["stage_input"].get("purpose", "")
        system, user = prompts.research_file(task.text, p, purpose)
    elif stage_key.startswith("RESEARCH_related:"):
        system, user = prompts.research_related(task.data["stage_input"]["path"])
    elif stage_key == "ANALYST":
        system, user = prompts.analyst(task.text,
                                       task.data["stage_input"]["research_md"])
    elif stage_key == "ORCHESTRATOR":
        system, user = prompts.orchestrator(task.text,
                                            task.data["stage_input"]["plan"])
    elif stage_key.startswith("BUILD_"):
        system, user = prompts.builder(task.text,
                                       task.data["stage_input"]["spec"])
    elif stage_key == "REVIEW":
        system, user = prompts.reviewer(task.text,
                                        task.data["stage_input"]["files"],
                                        task.data["stage_input"]["specs"])
    elif stage_key == "FIX":
        system, user = prompts.fixer(task.text,
                                     task.data["stage_input"]["issues"])
    else:
        print(f"unknown stage key: {stage_key}", file=sys.stderr)
        return 2

    sid = task.sessions.get(stage_key) or None
    client = LLMClient(settings, session_id=sid)
    task.sessions[stage_key] = client.session_id
    task.save()

    tp = task.transcript(stage_key)
    system_msg = {"role": "system", "content": system}
    messages, resumed = _load_working(tp, system_msg)
    if not resumed:
        _append(tp, [{"role": "user", "content": user}])
        messages.append({"role": "user", "content": user})

    lock = new_llm_lock(f"task:{task.id} {stage_key}")
    allowed = ROLE_TOOLS.get(role, ())
    tool_schemas = [s for s in SCHEMAS if s["function"]["name"] in allowed]
    turns = 0
    try:
        while turns < settings.max_turns:
            if task.stop_file().exists():
                return 3
            turns += 1
            req_messages = messages
            got_overflow = False
            with lock:
                req = {"model": settings.model, "stream": True,
                       "stream_options": {"include_usage": True},
                       "max_tokens": settings.max_output_tokens,
                       "enable_thinking": False, "messages": req_messages}
                if settings.temperature is not None:
                    req["temperature"] = settings.temperature
                if settings.top_p is not None:
                    req["top_p"] = settings.top_p
                if tool_schemas:
                    req["tools"] = tool_schemas
                content = ""
                tcs: dict[int, dict] = {}
                prompt_tokens = 0
                while True:
                    try:
                        ev_iter = client.stream_with_retry(req)
                        async for ev in ev_iter:
                            if ev["kind"] == "text":
                                content += ev["text"]
                            elif ev["kind"] == "tool":
                                tc = tcs.setdefault(
                                    ev["index"],
                                    {"id": ev["id"], "name": ev["name"],
                                     "arguments": ""})
                                tc["arguments"] += ev["arguments"] or ""
                            elif ev["kind"] == "finish" and ev.get("usage"):
                                prompt_tokens = ev["usage"].get(
                                    "prompt_tokens", 0)
                        break
                    except ContextOverflowError:
                        got_overflow = True
                        break
                    except LLMError as e:
                        if e.status == 409:
                            await asyncio.sleep(5.0)
                            continue
                        raise
            if got_overflow:
                messages = await _compact(client, settings, task, messages, tp)
                continue
            assistant: dict = {"role": "assistant", "content": content}
            if tcs:
                assistant["tool_calls"] = [
                    {"id": v["id"], "type": "function",
                     "function": {"name": v["name"],
                                  "arguments": v["arguments"]}}
                    for _, v in sorted(tcs.items())]
            if not assistant.get("tool_calls"):
                _append(tp, [assistant])
                return 0
            results = []
            for tc in assistant["tool_calls"]:
                try:
                    args = json.loads(tc["function"]["arguments"] or "{}")
                except json.JSONDecodeError:
                    args = {}
                out = execute(tc["function"]["name"], args, root, role)
                results.append({"role": "tool",
                               "tool_call_id": tc["id"], "content": out})
            _append(tp, [assistant, *results])
            messages.append(assistant)
            messages.extend(results)
            if (prompt_tokens + settings.max_output_tokens
                    > settings.max_context_tokens):
                messages = await _compact(client, settings, task, messages, tp)
        print("max turns reached", file=sys.stderr)
        return 1
    except LLMError as e:
        print(f"llm error: {e}", file=sys.stderr)
        return 1
    finally:
        await client.close()


def main() -> None:
    if len(sys.argv) != 3:
        print("usage: python -m iq_task.stage <task_id> <stage_key>",
              file=sys.stderr)
        sys.exit(2)
    task = load_task(sys.argv[1])
    if task is None:
        print(f"no such task: {sys.argv[1]}", file=sys.stderr)
        sys.exit(2)
    settings = load_settings()
    code = asyncio.run(run_stage(task, sys.argv[2], settings))
    sys.exit(code)


if __name__ == "__main__":
    main()
