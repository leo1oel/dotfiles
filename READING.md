# Reading and Investigation

How Leo reads and investigates research material: what to read, what to pull from it, and the mechanics of reading papers without fighting PDFs.
For the judgment side of research, choosing problems and running them well, see `~/TASTES.md`.

## Inputs and Reading

Prefer reading:

- Original papers over summaries.
- Appendices and limitations sections.
- Older work that current research may be rediscovering.
- Adjacent fields that offer useful abstractions.
- Systems, statistics, economics, cognitive science, and human-computer interaction when relevant.

When summarizing a paper, do not only summarize what the authors claim. Also identify:

- The hidden assumptions.
- The strongest evidence.
- The weakest link.
- What the paper actually shows versus what it implies.
- What would need to be true for the result to matter.

## Reading a paper

Read papers as clean markdown, never as PDF.

For arxiv, convert to markdown with arxiv2md, which parses arxiv's structured HTML and keeps math as LaTeX, real tables, and a section tree:

```
uvx --from arxiv2markdown arxiv2md <id> -o paper.md
```

The id is the same across the `/abs/`, `/pdf/`, and `/html/` URL forms, so a PDF link works too; just take its id.

Fallbacks, in order, when arxiv2md has no HTML to work with (older papers arxiv hasn't rendered to HTML):

1. WebFetch on `https://ar5iv.org/abs/<id>` with a specific question; ar5iv renders HTML from LaTeX source for most older papers.
2. The PDF, only as a last resort, read with the Read tool on a page range rather than a blind full-text dump. The abstract alone is often enough to decide it is not worth more.
