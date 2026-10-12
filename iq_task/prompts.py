from __future__ import annotations

import json
import re

SYSTEM = ("You are one stage of a batch pipeline that writes code in a git "
          "repo. You work through tools: read (file or directory listing), "
          "write, edit, bash. The repo root is the working directory. "
          "Be decisive and minimal. When the stage is done, answer with a "
          "final message and no tool calls.")


def _extract(text: str) -> str | None:
    depth, start, in_str, esc = 0, -1, False, False
    for i, ch in enumerate(text):
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    return None


def json_block(text: str) -> dict | None:
    m = re.search(r"```json\s*(.*?)```", text, re.DOTALL)
    body = m.group(1) if m else text
    i = body.find("{")
    if i < 0:
        return None
    raw = _extract(body) or body[i:]
    for cand in (raw, _balance(raw)):
        try:
            obj = json.loads(cand)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            return obj
    return None


def _balance(text: str) -> str:
    stack: list[str] = []
    in_str, esc = False, False
    for ch in text:
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch in "{[":
            stack.append("}" if ch == "{" else "]")
        elif ch in "}]":
            if stack and stack[-1] == ch:
                stack.pop()
    if in_str:
        text += '"'
    return text + "".join(reversed(stack))


ARTIFACT_NOTE = (
    "\n\nYour FINAL message (no tool calls) must contain exactly one "
    "```json fenced block with the artifact described above and nothing "
    "else after it. Valid JSON only, no comments, no markdown outside the "
    "fence.")


def research_1a(task_text: str) -> tuple[str, str]:
    prompt = (
        "Stage RESEARCH, step 1 of 2.\n"
        f"Task: {task_text}\n\n"
        "Explore the repo with read (directories list their entries). "
        "Pick the at most 10 files most relevant to the task: the entry "
        "points, the code the task touches, its tests. List only files "
        "that already exist in the repo, not files to be created. "
        "Do not analyze yet.\n"
        "Artifact: {\"files\": [{\"path\": \"relative/path\", "
        "\"purpose\": \"one line\"}]}")
    return SYSTEM, prompt + ARTIFACT_NOTE


def research_file(task_text: str, path: str, purpose: str) -> tuple[str, str]:
    prompt = (
        "Stage RESEARCH, step 2 of 2 (one of several parallel file "
        "analyses).\n"
        f"Task: {task_text}\n\n"
        f"Analyze file {path} ({purpose}). Read it (and its direct "
        "dependencies if needed to understand it).\n"
        "Artifact: {\"file\": \"same path\", "
        "\"analysis\": \"markdown, up to 400 words: what this code does, "
        "key functions/classes, invariants, how it connects\", "
        "\"related_files\": [\"up to 3 other repo files that matter for "
        "the task and this file\"]}")
    return SYSTEM, prompt + ARTIFACT_NOTE


def research_related(path: str) -> tuple[str, str]:
    prompt = (
        "Stage RESEARCH, follow-up: analyze one supporting file.\n"
        f"Analyze file {path}: what it does and why it matters. Read it "
        "with read.\n"
        "Artifact: {\"file\": \"same path\", \"analysis\": \"markdown, "
        "up to 250 words\"}")
    return SYSTEM, prompt + ARTIFACT_NOTE


def analyst(task_text: str, research_md: str) -> tuple[str, str]:
    prompt = (
        "Stage ANALYST.\n"
        f"Task: {task_text}\n\n"
        f"Research report:\n{research_md}\n\n"
        "Plan the implementation as a DAG of small steps (3-15). "
        "Do NOT write code. Do NOT use bash. Every step lists the files "
        "it will touch.\n"
        "Artifact: {\"steps\": [{\"id\": \"step-1\", \"goal\": \"one or "
        "two sentences\", \"files\": [\"paths\"], "
        "\"depends_on\": [\"ids or empty\"]}]}\n"
        "The graph must be a DAG (no cycles); depends_on may be empty "
        "for independent steps.")
    return SYSTEM, prompt + ARTIFACT_NOTE


def orchestrator(task_text: str, plan_json: dict) -> tuple[str, str]:
    prompt = (
        "Stage ORCHESTRATOR.\n"
        f"Task: {task_text}\n\n"
        f"Plan (from the ANALYST stage):\n{json.dumps(plan_json, indent=1)}\n\n"
        "Turn the plan into build specs. Each spec is one builder "
        "process: a self-contained goal, the files it owns or reads "
        "(specs run one by one, so a verify spec may list the files it "
        "checks), a dependency list from the plan, "
        "and a check: a shell command run in the repo root that must "
        "exit 0 when the spec is done (a test command, or a build, or "
        "'true' if there is nothing runnable). Keep specs small.\n"
        "Artifact: {\"specs\": [{\"id\": \"S1\", \"goal\": \"...\", "
        "\"files\": [\"...\"], \"depends_on\": [\"ids or empty\"], "
        "\"check\": \"shell command\"}]}")
    return SYSTEM, prompt + ARTIFACT_NOTE


def builder(task_text: str, spec: dict) -> tuple[str, str]:
    prompt = (
        "Stage BUILD: you are one builder process with write access.\n"
        f"Task: {task_text}\n\n"
        f"Your spec: {json.dumps(spec, indent=1)}\n\n"
        "Implement the spec. Touch only the files in the spec (plus "
        "tests for them). Depend on specs you are told about only "
        "through the code that already exists. Run the check command "
        "with bash when you think you are done; fix failures. If a "
        "command is not found (exit 127), use the closest available "
        "alternative (e.g. python3 instead of python). You may finish "
        "when the check passes.\n"
        "Final message: one line summary of what you changed, no "
        "tool calls.")
    return SYSTEM, prompt


def reviewer(task_text: str, changed_files: list[str],
             specs: list[dict]) -> tuple[str, str]:
    prompt = (
        "Stage REVIEW: you are the code reviewer. You have read and bash "
        "only, no write.\n"
        f"Task: {task_text}\n\n"
        f"Specs that were implemented: {json.dumps(specs, indent=1)}\n"
        f"Changed files: {', '.join(changed_files) or '(none reported)'}\n\n"
        "Review the changed files: do they implement the task? Run the "
        "relevant tests/commands. Look for real defects, not style.\n"
        "Artifact: {\"verdict\": \"PASS\" or \"FAIL\", "
        "\"issues\": [\"concrete defect + file + why\"]}\n"
        "PASS means no real defects.")
    return SYSTEM, prompt + ARTIFACT_NOTE


def fixer(task_text: str, issues: list[str]) -> tuple[str, str]:
    prompt = (
        "Stage FIX: the reviewer failed the build. You have full write "
        "access.\n"
        f"Task: {task_text}\n\n"
        "Reviewer issues:\n" + "\n".join(f"- {i}" for i in issues) +
        "\n\nFix these issues (and only these, plus whatever the fix "
        "breaks). Run tests with bash to verify. Final message: one "
        "line summary, no tool calls.")
    return SYSTEM, prompt
