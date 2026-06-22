# Leo's Agent Instructions

These are common instructions for Leo's agents across all scenarios.

## General Guidelines

- When writing commit messages, never auto-add your agent name as a co-author.
- Never manually modify CHANGELOG.md files, or any files that are marked as auto-generated.
- When writing or substantially editing long Markdown files, put each full sentence on its own line.
  Preserve normal Markdown structure, but avoid wrapping multiple sentences onto one physical line.
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When doing bug fixes, always start by reproducing the bug in an E2E setting, as closely aligned as possible with how a real end user would hit it.
  This makes sure you find the real problem, so your fix will actually solve it.
- If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- For anything Python, use `uv` exclusively.
  Run code with `uv run` (e.g. `uv run python`, `uv run pytest`) and manage dependencies with `uv add` / `uv sync`; never invoke a bare `python`/`pip` or hand-activate a virtualenv.
  In a git worktree, which carries only tracked files and so has no `.venv`, let `uv run` build that worktree's own `.venv` from the lockfile rather than reusing another checkout's environment.

## Research Taste

For research-related work, read ~/TASTES.md when Leo's taste, priors, or preferred research style would improve the outcome.

## Writing

When you are writing or posting on behalf of Leo, using his identity, read ~/WRITING.md to see how Leo writes.
