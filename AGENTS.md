# Leo's Agent Instructions

These are common instructions for Leo's agents across all scenarios.

## General Guidelines

- Never use em dashes; use a plain hyphen ("-") instead.
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

## Opinions

When you are working on something that would benefit from being informed by Leo's viewpoints, read ~/OPINIONS.md to understand them.

## Writing Profile

When you are writing or posting on behalf of Leo, using his identity, read ~/WRITING.md to see how Leo writes.
