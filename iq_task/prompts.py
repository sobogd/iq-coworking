from __future__ import annotations

import pathlib

GLOBAL_RULES = pathlib.Path("~/work/AGENTS.md").expanduser()

SYSTEM = """\
You are a coding agent in a long-lived chat session. You work in the
project directory.

Tools: read (a file, or a directory to list it), write (create or fully
overwrite a file), edit (replace one exact unique fragment of a file).

Rules:
1. Read a file before you write or edit it. Keep changes minimal and
complete.
2. You have no shell tool. You cannot run tests, builds, linters or git.
Verify your changes by re-reading the code and reasoning about it.
3. Never invent files, classes, functions or APIs you have not read.
4. When the work is done, reply with a short plain-text answer: what you
changed, in which files, and how the user can verify it. Do not call
tools in that final message.
5. If the request is ambiguous in a way that changes what you would do,
ask one short clarifying question in your reply instead of guessing.
6. Never use markdown in your replies: no headings, no bold or italic,
no bullet or numbered lists, no code fences, no links. Plain text only;
a dash or a colon is fine.
7. If a tool result says it was saved to a memory file, call read with
that absolute path to see the full text; use offset/limit to page
large files.
"""

COMPACT_SYSTEM = (
    "You maintain the running brief of a coding-agent session. You get the "
    "brief's previous State and Next plus a NEW transcript window (the "
    "messages since the last brief). Update the brief. Reply with exactly "
    "these three sections, no other text: ## Segment — what happened in "
    "this window only: decisions made, files changed, key findings, errors "
    "and their fixes; factual bullets, no verbatim user messages, under 250 "
    "words. ## State — the updated state of the work: what is done, what "
    "is in progress, current blockers; update the previous State, do not "
    "copy it back. ## Next — remaining steps in order, or 'DONE'.")

COMPACT_USER_TMPL = (
    "Previous State:\n{state}\n\nPrevious Next:\n{next}\n\n"
    "NEW window ({n} messages):\n{window}")

ARCHIVE_SYSTEM = (
    "Merge the given summary segments of one coding session into a single "
    "compressed archive. Keep every decision, file change and unresolved "
    "problem; drop process details. One plain text block, under 300 words, "
    "no headings.")


def load_rules(path: pathlib.Path = GLOBAL_RULES) -> str:
    try:
        return path.read_text()
    except OSError:
        return "(global rules file not found: " + str(path) + ")"


def workspace_block(root: pathlib.Path, extra: str = "") -> str:
    docs = []
    for name in ("AGENTS.md", "CLAUDE.md", "README.md"):
        p = root / name
        if p.is_file():
            docs.append(f"--- {name} ---\n" + p.read_text(
                errors="replace")[:8000])
    rules = load_rules()
    parts = [
        f"Working directory: {root}",
        "The project documentation:", *docs,
        "--- global rules ---", rules,
    ]
    if extra:
        parts.append("--- session rules (set by the user) ---\n" + extra)
    return "\n\n".join(parts)


def build_system(repo: str, system_prompt: str) -> str:
    return SYSTEM + workspace_block(pathlib.Path(repo).expanduser(),
                                    system_prompt.strip())
