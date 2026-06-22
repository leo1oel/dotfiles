#!/usr/bin/env python3

# /// script
# requires-python = ">=3.8"
# dependencies = []
# ///

"""
Pre-tool use hook for Claude Code to guide UV usage in Python projects.

Uses exit code 2 + stderr to block commands (current Claude Code API).

Exit 0 allows the command to proceed.

Source: https://gist.github.com/glennmatlin/fadc41edc3bb9ff68ff9cfa5d6b8aca7
Managed by chezmoi (dot_claude/hooks/). Invoked from ~/.claude/settings.json.
"""

import json
import shutil
import sys
import re
from pathlib import Path
from typing import Dict, Any


class UVCommandHandler:
    """Handle Python commands with UV awareness."""

    def __init__(self):
        self.project_root = Path.cwd()
        self.has_uv = self.check_uv_available()
        self.in_project = self.check_in_project()

    def check_uv_available(self) -> bool:
        """Check if UV is available in PATH."""
        return shutil.which("uv") is not None

    def check_in_project(self) -> bool:
        """Check if we're in a Python project with pyproject.toml."""
        return (self.project_root / "pyproject.toml").exists()

    def analyze_command(self, command: str) -> Dict[str, Any]:
        """Analyze command to determine how to handle it."""

        # Check if command already uses uv
        if command.strip().startswith("uv"):
            return {"action": "allow", "reason": "Already using uv"}

        # Skip non-Python commands entirely
        skip_prefixes = [
            "git ", "cd ", "ls ", "cat ", "echo ", "grep ", "find ", "mkdir ",
            "rm ", "cp ", "mv ", "curl ", "wget ", "which ", "touch ", "chmod ",
            "chown ", "ln ", "tar ", "zip ", "unzip ", "head ", "tail ", "less ",
            "more ", "wc ", "sort ", "diff ", "sed ", "awk ", "cut ", "tr ",
            "xargs ", "tee ", "date ", "pwd ", "whoami ", "env ", "export ",
            "source ", ".", "npm ", "npx ", "node ", "yarn ", "pnpm ", "cargo ",
            "rustc ", "go ", "make ", "cmake ", "docker ", "kubectl ", "brew ",
            "apt ", "apt-get ", "yum ", "dnf ", "pacman ",
        ]

        if any(command.strip().startswith(prefix) for prefix in skip_prefixes):
            return {"action": "allow", "reason": "Not a Python command"}

        # Check for actual Python command execution
        python_exec_patterns = [
            r"^python3?\s+",
            r"^python3?\s*$",
            r"\|\s*python3?\s+",
            r";\s*python3?\s+",
            r"&&\s*python3?\s+",
            r"^pip3?\s+",
            r"\|\s*pip3?\s+",
            r";\s*pip3?\s+",
            r"&&\s*pip3?\s+",
            r"^(pytest|ruff|mypy|black|flake8|isort|pylint|bandit|safety)\s*",
            r";\s*(pytest|ruff|mypy|black|flake8|isort|pylint|bandit|safety)\s*",
            r"&&\s*(pytest|ruff|mypy|black|flake8|isort|pylint|bandit|safety)\s*",
        ]

        is_python_exec = any(
            re.search(pattern, command) for pattern in python_exec_patterns
        )

        if not is_python_exec:
            return {"action": "allow", "reason": "Not a Python execution command"}

        # If we're in a UV project, block and provide guidance
        if self.has_uv and self.in_project:
            suggestion = self.suggest_uv_command(command)
            return {
                "action": "block",
                "reason": f"This project uses UV for Python management. {suggestion}",
            }

        return {"action": "allow", "reason": "UV not required"}

    def suggest_uv_command(self, command: str) -> str:
        """Provide UV command suggestions."""

        if "&&" in command:
            parts = command.split("&&")
            transformed_parts = []

            for part in parts:
                part = part.strip()
                if re.search(
                    r"\b(python3?|pip3?|pytest|ruff|mypy|black|flake8|isort|pylint|bandit|safety)\b",
                    part,
                ):
                    transformed_parts.append(self._transform_single_command(part))
                else:
                    transformed_parts.append(part)

            return f"Try: {' && '.join(transformed_parts)}"

        return f"Try: {self._transform_single_command(command)}"

    def _transform_single_command(self, command: str) -> str:
        """Transform a single Python command to use UV."""

        if re.match(r"^python3?\s+", command):
            return re.sub(r"^python3?\s+", "uv run python ", command)

        elif re.match(r"^pip3?\s+install\s+", command):
            return re.sub(r"^pip3?\s+install\s+", "uv add ", command)

        elif re.match(r"^pip3?\s+", command):
            return re.sub(r"^pip3?\s+", "uv pip ", command)

        elif re.match(
            r"^(pytest|ruff|mypy|black|flake8|isort|pylint|bandit|safety)", command
        ):
            return f"uv run {command}"

        return command

    def main(self):
        """Main hook function."""

        try:
            input_data = json.loads(sys.stdin.read())

            tool_name = input_data.get("tool_name", "")

            if tool_name not in ["Bash", "Run"]:
                sys.exit(0)  # Allow non-Bash tools

            tool_input = input_data.get("tool_input", {})

            command = tool_input.get("command", "")

            if not command:
                sys.exit(0)  # Allow empty commands

            handler = UVCommandHandler()

            result = handler.analyze_command(command)

            if result["action"] == "block":
                # Exit 2 + stderr message blocks the command (current API)
                print(result["reason"], file=sys.stderr)
                sys.exit(2)

            sys.exit(0)  # Allow

        except Exception as e:
            # On error, allow to avoid blocking workflow
            print(f"Hook error (allowing): {e!s}", file=sys.stderr)
            sys.exit(0)


if __name__ == "__main__":
    handler = UVCommandHandler()
    handler.main()
