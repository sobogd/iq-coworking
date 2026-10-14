from __future__ import annotations

import json
import pathlib

import httpx

from . import prompts, tools
from .config import load_settings
from .llm import (LLMClient, LLMError, ContextOverflowError, build_request)
from .state import BUSY, FAILED, IDLE, Registry, Session, STOPPED, save_repo

MEM_THRESHOLD = 16_000
TOOL_RESULT_MAX = 32_000
SUMMARY_INPUT_MAX = 120_000
COMPACT_MAX_TOKENS = 2_000
ARCHIVE_MAX_TOKENS = 1_500
BRIEF_BUDGET = 96_000
ARCHIVE_KEEP = 3


# ---------------------------------------------------------------- helpers


def _clip_tool_result(out: str) -> str:
    if len(out) <= TOOL_RESULT_MAX:
        return out
    return out[:TOOL_RESULT_MAX] + f"\n...[truncated {len(out) - TOOL_RESULT_MAX} chars]"


def _store(s: Session, text: str) -> str:
    mem = s.path / "mem"
    mem.mkdir(parents=True, exist_ok=True)
    n = len(list(mem.glob("tool-*.txt")))
    f = mem / f"tool-{n}.txt"
    while f.exists():
        n += 1
        f = mem / f"tool-{n}.txt"
    f.write_text(text, encoding="utf-8")
    return (f"[full result saved to {f} ({len(text)} chars)]\n"
            f"beginning:\n{text[:1500]}\n... end:\n{text[-500:]}")


def _est_tokens(messages: list[dict]) -> int:
    total = 0
    for m in messages:
        c = m.get("content")
        if isinstance(c, str):
            total += len(c)
        for tc in m.get("tool_calls") or []:
            fn = tc.get("function") or {}
            total += len(fn.get("arguments") or "") + len(fn.get("name") or "")
    return total // 4 + 8


def _load_working(tp: pathlib.Path, sp: str) -> tuple[list[dict], dict | None, int]:
    messages: list[dict] = [{"role": "system", "content": sp}]
    brief: dict | None = None
    base = 1
    if not tp.exists():
        return messages, None, 1
    for line in tp.read_text(encoding="utf-8").splitlines():
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if "compact" in obj:
            messages = [messages[0], obj["compact"]]
            brief = obj.get("brief")
            base = 2 + len(obj.get("tail") or [])
            messages.extend(obj.get("tail") or [])
        elif "m" in obj:
            messages.append(obj["m"])
    if not brief:
        base = 1
    return messages, brief, base


def _drop_dangling(messages: list[dict]) -> None:
    for i in range(1, len(messages)):
        m = messages[i]
        if m.get("role") == "tool":
            prev = messages[i - 1]
            ids = {tc.get("id") for tc in prev.get("tool_calls") or []}
            if prev.get("role") != "assistant" or m.get("tool_call_id") not in ids:
                messages.pop(i)
                i -= 1
        elif m.get("role") == "assistant" and not m.get("content") and not m.get("tool_calls"):
            messages.pop(i)
            i -= 1


def _append(tp: pathlib.Path, batch: list[dict]) -> None:
    tp.parent.mkdir(parents=True, exist_ok=True)
    with tp.open("a", encoding="utf-8") as f:
        for m in batch:
            f.write(json.dumps({"m": m}, ensure_ascii=False) + "\n")


def _sys_and_tools(s: Session) -> tuple[str, list[dict]]:
    if s.repo:
        save_repo(s.repo)
    sp = prompts.build_system(s.repo, s.system_prompt)
    return sp, (tools.SCHEMAS if s.repo else [])


# ---------------------------------------------------------------- brief


def _first_user_message(tp: pathlib.Path) -> str:
    if not tp.exists():
        return ""
    for line in tp.read_text(encoding="utf-8").splitlines():
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        m = obj.get("m")
        if m and m.get("role") == "user":
            return (m.get("content") or "")[:2000]
    return ""


def _render_brief(b: dict) -> str:
    parts = [f"[context compacted — {len(b['segments'])} segment(s)]"]
    parts += ["## Task", b["task"].strip()]
    if b.get("users"):
        parts += ["## Users"] + [u.strip() for u in b["users"]]
    for i, seg in enumerate(b["segments"], 1):
        parts += [f"## C{i}", seg.strip()]
    if b.get("archive"):
        parts += ["## Archive", b["archive"].strip()]
    if b.get("state"):
        parts += ["## State", b["state"].strip()]
    if b.get("next"):
        parts += ["## Next", b["next"].strip()]
    return "\n\n".join(parts)


def _flatten(msgs: list[dict]) -> str:
    parts: list[str] = []
    total = 0
    for m in msgs:
        role = m.get("role", "?")
        line = m.get("content") or ""
        for tc in m.get("tool_calls") or []:
            fn = tc.get("function") or {}
            line += f"\n[tool: {fn.get('name', '')}({fn.get('arguments', '')})]"
        if role == "tool":
            line = line[:800]
        parts.append(f"### {role}\n{line}")
        total += len(line)
        if total > SUMMARY_INPUT_MAX:
            break
    return "\n\n".join(parts)


def _parse_compact(text: str) -> tuple[str, str, str]:
    out: dict[str, list[str]] = {}
    cur = None
    for line in text.splitlines():
        s = line.strip()
        key = {"## Segment": "segment", "## State": "state",
               "## Next": "next"}.get(s)
        if key:
            cur = key
            out.setdefault(cur, [])
        elif cur:
            out[cur].append(line)
    get = lambda k: "\n".join(out.get(k, [])).strip()
    return get("segment"), get("state"), get("next")


async def _summarize_window(client: LLMClient, s: Session,
                            prev: dict, window: list[dict]) -> tuple[str, str, str]:
    user = prompts.COMPACT_USER_TMPL.format(
        state=prev.get("state") or "—",
        next=prev.get("next") or "—",
        n=len(window),
        window=_flatten(window))
    reply = await client.complete([
        {"role": "system", "content": prompts.COMPACT_SYSTEM},
        {"role": "user", "content": user}], COMPACT_MAX_TOKENS)
    return _parse_compact(reply)


async def _fit_brief(client: LLMClient, s: Session, b: dict) -> None:
    if len(_render_brief(b)) <= BRIEF_BUDGET:
        return
    if len(b["segments"]) > ARCHIVE_KEEP:
        old = b["segments"][:-ARCHIVE_KEEP]
        kept = b["segments"][-ARCHIVE_KEEP:]
        if b.get("archive"):
            old = [b["archive"]] + old
        try:
            b["archive"] = await client.complete([
                {"role": "system", "content": prompts.ARCHIVE_SYSTEM},
                {"role": "user", "content": "\n\n".join(old)}],
                ARCHIVE_MAX_TOKENS)
        except LLMError:
            b["archive"] = "\n\n".join(x[:1000] for x in old)
        b["segments"] = kept
    if len(_render_brief(b)) > BRIEF_BUDGET and len(b["users"]) > 5:
        b["users"] = b["users"][-5:]


def _fit_tail(s: Session, tail: list[dict], max_context_tokens: int) -> None:
    budget = int(max_context_tokens * 0.6) * 4
    while sum(len(m.get("content") or "") for m in tail) > budget:
        biggest, idx = max(((len(m.get("content") or ""), i)
                            for i, m in enumerate(tail)), default=(-1, -1))
        if biggest < MEM_THRESHOLD:
            break
        m = tail[idx]
        if not m["content"].startswith("[full result saved"):
            tail[idx] = {**m, "content": _store(s, m["content"])}


async def _compact(client: LLMClient, s: Session, messages: list[dict],
                   brief: dict | None, base: int,
                   tp: pathlib.Path) -> tuple[list[dict], dict, int]:
    brief = (brief or {"task": "", "users": [], "segments": [],
                       "archive": "", "state": "", "next": ""})
    brief = {**brief, "users": list(brief["users"]),
             "segments": list(brief["segments"])}
    if not brief.get("task"):
        brief["task"] = _first_user_message(tp)
    window = messages[base:]
    keep = max(2, min(10, len(window)))
    cut = max(0, len(window) - keep)
    while cut > 0 and window[cut].get("role") == "tool":
        cut -= 1
    to_summarize, tail = window[:cut], window[cut:]
    if to_summarize:
        prev = {"state": brief.get("state", ""), "next": brief.get("next", "")}
        segment, state, nxt = await _summarize_window(client, s, prev,
                                                      to_summarize)
        if segment:
            brief["segments"].append(segment)
        brief["state"], brief["next"] = state, nxt
        brief["users"] += [(m.get("content") or "")[:2000]
                           for m in to_summarize
                           if m.get("role") == "user"]
    await _fit_brief(client, s, brief)
    _fit_tail(s, tail, s.context_tokens)
    rec = {"compact": {"role": "user",
                       "content": _render_brief(brief)},
           "brief": brief, "tail": tail}
    with tp.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    client.new_session_id()
    s.mtplx_session_id = client.session_id
    s.save()
    return [messages[0], rec["compact"], *tail], brief, 2 + len(tail)


# ---------------------------------------------------------------- turn


def _status(reg: Registry, s: Session, status: str, err: str = "") -> None:
    s.error = err
    s.status = status
    reg.update(s)


async def _update_title(client: LLMClient, s: Session,
                        messages: list[dict]) -> None:
    if s.title:
        return
    last = next((m for m in reversed(messages)
                 if m.get("content") and m.get("role") == "user"), None)
    if last is None:
        return
    try:
        t = (await client.complete([
            {"role": "system", "content": "Сожми суть сообщения в заголовок "
                                          "до 6 слов, без кавычек и точек"},
            {"role": "user", "content": last["content"][:2000]}], 40)).strip()
        if t:
            s.title = t[:60]
            s.save()
    except LLMError:
        pass


async def _generate(client: LLMClient, s: Session, messages: list[dict],
                    tool_list: list[dict]) -> tuple[dict, int]:
    """One model generation. Returns (assistant_message, prompt_tokens)."""
    content, reasoning = "", ""
    tc: dict[int, dict] = {}
    used = 0
    request = build_request(messages, load_settings(), tool_list,
                            s.thinking)
    async for ev in client.stream_with_retry(request):
        k = ev.get("kind")
        if k == "text":
            content += ev.get("text", "")
        elif k == "reasoning":
            reasoning += ev.get("text", "")
        elif k == "tool":
            i = ev.get("index", 0)
            p = tc.setdefault(i, {"id": None, "name": None, "arguments": ""})
            if ev.get("id"):
                p["id"] = ev["id"]
            if ev.get("name"):
                p["name"] = ev["name"]
            p["arguments"] += ev.get("arguments") or ""
        elif k == "finish":
            u = ev.get("usage") or {}
            used = u.get("prompt_tokens") or used
    assistant: dict = {"role": "assistant"}
    if s.mtplx_session_id:
        assistant["mtplx_session_id"] = s.mtplx_session_id
    if reasoning:
        assistant["reasoning_content"] = reasoning
    if content:
        assistant["content"] = content
    if tc:
        assistant["tool_calls"] = [
            {"id": p["id"], "type": "function",
             "function": {"name": p["name"],
                          "arguments": p["arguments"] or "{}"}}
            for _, p in sorted(tc.items())]
    return assistant, used


async def run_turn(reg: Registry, s: Session) -> None:
    st = load_settings()
    ctx = s.context_tokens or st.max_context_tokens
    client = LLMClient(st, s.mtplx_session_id)
    s.mtplx_session_id = client.session_id
    s.save()
    s.status = BUSY
    reg.update(s)
    try:
        sp, tool_list = _sys_and_tools(s)
        messages, brief, base = _load_working(s.transcript, sp)
        _drop_dangling(messages)
        oom = 0
        for _ in range(st.max_turns):
            if s.stop_file().exists():
                _status(reg, s, STOPPED)
                return
            if _est_tokens(messages) > ctx:
                messages, brief, base = await _compact(client, s, messages,
                                                       brief, base,
                                                       s.transcript)
                s.title = s.title or "сессия iq-task"
            try:
                assistant, used = await _generate(client, s, messages,
                                                  tool_list)
            except ContextOverflowError:
                messages, brief, base = await _compact(client, s, messages,
                                                       brief, base,
                                                       s.transcript)
                s.title = s.title or "сессия iq-task"
                continue
            except LLMError as e:
                msg = str(e)
                if "insufficient memory" in msg:
                    oom += 1
                    if oom >= 2:
                        _status(reg, s, FAILED, msg[:300])
                        return
                    messages = [messages[0]]
                    if brief:
                        messages.append({"role": "user",
                                         "content": _render_brief(brief)})
                    base = len(messages)
                    continue
                _status(reg, s, FAILED, msg[:300])
                return
            except httpx.HTTPError as e:
                _status(reg, s, FAILED,
                        f"{type(e).__name__}: {str(e)[:200]}")
                return
            if (used and used + st.max_output_tokens >= ctx
                    and _est_tokens(messages) <= ctx):
                messages, brief, base = await _compact(client, s, messages,
                                                       brief, base,
                                                       s.transcript)
                s.title = s.title or "сессия iq-task"
            if "tool_calls" in assistant:
                messages.append(assistant)
                root = pathlib.Path(s.repo or str(pathlib.Path.home()))
                results = []
                for t in assistant["tool_calls"]:
                    fn = t.get("function") or {}
                    name = fn.get("name", "")
                    try:
                        args = json.loads(fn.get("arguments") or "{}")
                    except ValueError:
                        args = {}
                    if name not in {x["function"]["name"] for x in tool_list}:
                        out = f"error: unknown tool {name!r}"
                    else:
                        out = tools.execute(name, args, root,
                                            s.path / "mem")
                    out = _clip_tool_result(str(out))
                    if len(out) > MEM_THRESHOLD:
                        out = _store(s, out)
                    results.append({"role": "tool",
                                    "tool_call_id": t.get("id", ""),
                                    "content": out})
                _append(s.transcript, [assistant, *results])
                messages.extend(results)
                continue
            _append(s.transcript, [assistant])
            messages.append(assistant)
            if s.stop_file().exists():
                _status(reg, s, STOPPED)
                return
            _status(reg, s, IDLE)
            await _update_title(client, s, messages)
            return
        _status(reg, s, IDLE)
        return
    except LLMError as e:
        _status(reg, s, FAILED, str(e)[:300])
    finally:
        await client.close()


async def complete_text(s: Session, text: str) -> str:
    st = load_settings()
    sp, _ = _sys_and_tools(s)
    messages, _, _ = _load_working(s.transcript, sp)
    keep = [m for m in messages[1:4]
            if m.get("role") == "user" and m.get("content")]
    if not keep:
        return ""
    client = LLMClient(st, s.mtplx_session_id)
    try:
        return await client.complete(
            messages[:1] + keep + [{"role": "user", "content": text}], 600)
    finally:
        await client.close()