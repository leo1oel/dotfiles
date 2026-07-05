#!/usr/bin/env python3

# /// script
# requires-python = ">=3.8"
# dependencies = []
# ///

"""
Pre-tool use hook for Claude Code to route arXiv paper reads through arxiv2md.

Blocks direct WebFetch and shell commands that include arxiv.org URLs, then tells
the model to use the arxiv-reading workflow instead. ar5iv.org is intentionally
allowed as a fallback, and figure/image asset URLs (e.g. .../html/<id>/x1.png)
are allowed so the model can download and view a paper's figures — arxiv2md
renders those as inert "Refer to caption:" paths and never fetches the bytes.

Managed by chezmoi (dot_claude/hooks/). Invoked from ~/.claude/settings.json.
"""

from __future__ import annotations

import json
import re
import sys
from typing import Iterable


ARXIV_URL_RE = re.compile(
    r"(?:https?://)?(?:[A-Za-z0-9-]+\.)*arxiv\.org/[^\s'\"<>)]*",
    re.IGNORECASE,
)

PAPER_ID_RE = re.compile(
    r"(?:arxiv\.org/(?:abs|pdf|html|e-print|src)/)"
    r"(?P<id>(?:\d{4}\.\d{4,5}|[a-z-]+(?:\.[A-Z]{2})?/\d{7})(?:v\d+)?)",
    re.IGNORECASE,
)

# A Bash command is only a "fetch" when a downloader appears in command
# position — merely CONTAINING an arxiv.org URL (a BibTeX blob piped to
# `bibcite add --bibtex`, an echo into a notes file) must not trigger.
FETCH_CMD_RE = re.compile(
    r"(?:^|[|;&]|\$\(|`)\s*(?:curl|wget|aria2c|httpie|xh|http)\b"
)

# Tools that legitimately handle arXiv URLs/ids themselves.
ALLOWED_TOOL_RE = re.compile(r"\b(bibcite|arxiv2md|bibtex-tidy)\b")

# Static figure/image assets under an arXiv HTML render
# (.../html/<id>/x1.png, .../figures/foo.jpg). These are the paper's figures,
# not a paper read, so downloading and viewing them is allowed. Note: .pdf is
# deliberately excluded — a raw PDF read stays blocked.
ASSET_URL_RE = re.compile(
    r"\.(?:png|jpe?g|gif|svg|webp|bmp|tiff?|ico|avif)(?:[?#]|$)",
    re.IGNORECASE,
)


def _is_asset_url(url: str) -> bool:
    """True for image/figure asset URLs the model may fetch directly."""

    return bool(ASSET_URL_RE.search(url))


def _extract_values(value) -> Iterable[str]:
    """Yield string leaves from nested hook input values."""

    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from _extract_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from _extract_values(child)


def _find_arxiv_urls(text: str) -> list[str]:
    """Return direct arxiv.org URLs, excluding ar5iv.org."""

    return [url for url in ARXIV_URL_RE.findall(text) if "ar5iv" not in url.lower()]


def _find_paper_ids(urls: list[str]) -> list[str]:
    """Extract stable paper ids from known arXiv URL shapes."""

    ids: list[str] = []
    seen: set[str] = set()
    for url in urls:
        match = PAPER_ID_RE.search(url)
        if not match:
            continue
        paper_id = match.group("id")
        if paper_id not in seen:
            seen.add(paper_id)
            ids.append(paper_id)
    return ids


def _block_message(urls: list[str]) -> str:
    """Build the guidance returned to Claude when a direct arXiv read is blocked."""

    ids = _find_paper_ids(urls)
    id_text = ", ".join(ids) if ids else "<id>"
    command = f"uvx --from arxiv2markdown arxiv2md {id_text} -o paper.md"
    return (
        "Do not directly fetch arxiv.org URLs with WebFetch, curl, wget, or raw "
        "PDF/HTML reads. Use the arxiv-reading skill: convert the paper with "
        f"`{command}`, then read the generated markdown. ar5iv.org is allowed "
        "only as a fallback after arxiv2md cannot convert the paper."
    )


def main() -> None:
    """Main hook function."""

    try:
        input_data = json.loads(sys.stdin.read())
        tool_name = input_data.get("tool_name", "")

        if tool_name not in {"WebFetch", "Bash", "Run"}:
            sys.exit(0)

        tool_input = input_data.get("tool_input", {})

        if tool_name in {"Bash", "Run"}:
            command = tool_input.get("command", "")
            urls = _find_arxiv_urls(command)
            blockable = [url for url in urls if not _is_asset_url(url)]
            if (
                blockable
                and FETCH_CMD_RE.search(command)
                and not ALLOWED_TOOL_RE.search(command)
            ):
                print(_block_message(blockable), file=sys.stderr)
                sys.exit(2)
            sys.exit(0)

        # WebFetch: any direct arXiv paper read is redirected to the skill;
        # figure/image asset URLs are allowed to pass through.
        text = "\n".join(_extract_values(tool_input))
        urls = _find_arxiv_urls(text)
        blockable = [url for url in urls if not _is_asset_url(url)]
        if blockable:
            print(_block_message(blockable), file=sys.stderr)
            sys.exit(2)

        sys.exit(0)

    except Exception as e:
        print(f"arXiv hook error (allowing): {e!s}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
