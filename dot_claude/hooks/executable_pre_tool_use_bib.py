#!/usr/bin/env python3

# /// script
# requires-python = ">=3.8"
# dependencies = []
# ///

"""
Pre-tool use hook for Claude Code: .bib files must go through the bibcite CLI.

Blocks direct Edit/Write on *.bib files, and Bash commands that write to a
.bib file (redirection, sed -i, tee, perl -i). Read access and the bibcite /
bibtex-tidy tools themselves are always allowed.

Uses exit code 2 + stderr to block (current Claude Code API); exit 0 allows.
Managed by chezmoi (dot_claude/hooks/). Invoked from ~/.claude/settings.json.
"""

import json
import re
import sys

GUIDANCE = (
    "Direct .bib edits are blocked. Use the bibcite skill: route the change "
    "through the bibcite CLI (e.g. `bibcite add <file.bib> <arXiv id|DOI|title>`), "
    "which verifies metadata online, canonicalizes venues and entry types, "
    "dedupes, tidies, and prints the citation key as JSON."
)

# Bash patterns that WRITE to a .bib file. Conservative on purpose:
# reading (cat/grep/less) must stay allowed.
BIB = r"[^\s>|;&]*\.bib"
BASH_WRITE_PATTERNS = [
    rf">>?\s*['\"]?{BIB}",              # echo ... > refs.bib / >> refs.bib
    rf"\bsed\s+(-\w+\s+)*-i[^|;&]*{BIB}",  # sed -i ... refs.bib
    rf"\bperl\s+[^|;&]*-i[^|;&]*{BIB}",    # perl -pi -e ... refs.bib
    rf"\btee\s+(-a\s+)?['\"]?{BIB}",       # ... | tee refs.bib
    rf"\b(mv|cp)\s+[^|;&]+\s['\"]?{BIB}",  # mv/cp something refs.bib
]

# Tools that are allowed to touch .bib files.
ALLOWED_TOOL_RE = re.compile(r"\b(bibcite|bibtex-tidy)\b")


def should_block(tool_name: str, tool_input: dict) -> bool:
    if tool_name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        file_path = tool_input.get("file_path", "") or tool_input.get(
            "notebook_path", ""
        )
        return file_path.endswith(".bib")

    if tool_name in ("Bash", "Run"):
        command = tool_input.get("command", "")
        if not command or ".bib" not in command:
            return False
        if ALLOWED_TOOL_RE.search(command):
            return False
        return any(re.search(p, command) for p in BASH_WRITE_PATTERNS)

    return False


def main():
    try:
        input_data = json.loads(sys.stdin.read())
        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {}) or {}

        if should_block(tool_name, tool_input):
            print(GUIDANCE, file=sys.stderr)
            sys.exit(2)

        sys.exit(0)
    except Exception as e:
        # On error, allow to avoid blocking workflow
        print(f"Hook error (allowing): {e!s}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
