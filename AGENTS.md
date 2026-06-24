# General rules

- When writing commit messages, never auto-add your agent name as a co-author.
- Never manually modify CHANGELOG.md files, or files marked as auto-generated.
- When writing or substantially editing long Markdown files, put each full sentence on its own line.
  Preserve normal Markdown structure, but avoid wrapping multiple sentences onto one physical line.
- Do not let implementation time estimates constrain technical decisions.
  Prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When doing bug fixes, start by reproducing the bug in an E2E setting, as closely aligned as possible with how a real user would hit it.
- If something clearly looks off, including lint failures, test failures, or flaky tests, try to fix it even when it is not directly related to the current task.
- For Python, use `uv` exclusively.
  Run code with `uv run`; manage dependencies with `uv add` / `uv sync`.
  Never invoke bare `python` / `pip` or hand-activate a virtualenv.
  In git worktrees, symlink the main checkout's `.venv` when possible, but still run commands through `uv run`.
