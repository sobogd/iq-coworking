from __future__ import annotations

import re

_FENCE = re.compile(r"```[a-zA-Z0-9_+-]*\n?")
_HEADER = re.compile(r"^#{1,6}\s+", re.M)
_BULLET = re.compile(r"^\s*[-*+]\s+", re.M)
_NUMBERED = re.compile(r"^\s*\d+\.\s+", re.M)
_QUOTE = re.compile(r"^\s*>\s?", re.M)
_HR = re.compile(r"^\s*[-*_]{3,}\s*$", re.M)
_BOLD_STAR = re.compile(r"\*\*(.+?)\*\*", re.S)
_BOLD_UNDER = re.compile(r"__(.+?)__", re.S)
_ITAL_STAR = re.compile(r"(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)", re.S)
_ITAL_UNDER = re.compile(r"(?<!_)_(?!\s)(.+?)(?<!\s)_(?!_)", re.S)
_INLINE_CODE = re.compile(r"`([^`]+)`")
_LINK = re.compile(r"\[([^\]]+)\]\([^)]+\)")
_IMAGE = re.compile(r"!\[([^\]]*)\]\([^)]+\)")


def _strip_fences(text: str) -> str:
    out = []
    for line in text.split("\n"):
        if line.lstrip().startswith("```"):
            continue
        out.append(line)
    return "\n".join(out)


def strip_markdown(text: str) -> str:
    """Convert markdown to plain text; keeps dashes and ordinary punctuation."""
    out = _strip_fences(text)
    for pat, repl in (
        (_HEADER, ""),
        (_BULLET, "- "),
        (_NUMBERED, ""),
        (_QUOTE, ""),
        (_HR, ""),
        (_BOLD_STAR, r"\1"),
        (_BOLD_UNDER, r"\1"),
        (_ITAL_STAR, r"\1"),
        (_ITAL_UNDER, r"\1"),
        (_INLINE_CODE, r"\1"),
        (_LINK, r"\1"),
        (_IMAGE, r"\1"),
    ):
        out = pat.sub(repl, out)
    return re.sub(r"\n{3,}", "\n\n", out).strip()
