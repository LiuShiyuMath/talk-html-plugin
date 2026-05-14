---
name: talk-html
description: Talk to humans in HTML, not chat. Generate a polished, self-contained HTML page from the current conversation context, preview it locally in the user's browser, then publish it to a GitHub gist for permanence. All artifact content is rendered in Simplified Chinese (zh-CN) — only structural metadata, file paths, and code snippets stay English. Use when an agent has a structured/long answer the user would rather look at than scroll through chat, when the user wants to share an explainer / recap / status / letter with another human, or when the user wants a durable breadcrumb to recall later. Every artifact carries a footer pill linking back to its originating Claude session, so any HTML can be traced to "which session made this" in one click. Trigger phrases include English ("/talk-html", "talk in html", "explain this in html", "give me an html version", "make this an html i can share", "make a page out of this", "publish as gist", "html recap", "send this as a page", "send this to <person>") and Chinese ("用 html 解释", "用 html 说", "做个网页", "做一页", "推到 gist", "html 回看", "解释给 <人> 看", "html 版本", "做成一页", "html 备忘", "html 给我看一下", "推个 gist").
---

# talk-html

Communicate in HTML, not chat. Local preview first, then gist-publish for permanence. **Output language is always Simplified Chinese.**

## When to invoke

- The current answer is structured enough that an HTML page beats a chat scroll (essay, recap, status board, proposal, letter).
- The user said "html version", "make a page", "publish this", "share this with X".
- The user wants to remember today's decision/insight in a recallable, linkable form.
- Another agent needs to hand a polished communication to a human user.

If the topic is **a finished UI feature / production page** belonging to a real product, use `frontend-design` or `design-html` instead. `talk-html` is for ephemeral communication artifacts, not shipped product UI.

## Workflow

### 1. Resolve context

Identify what you are communicating. Look at:

- The user's last few messages.
- Files referenced in the conversation.
- If the user gave you a topic phrase, use that as the spine.

Synthesize a `slug` (3–5 kebab-case words) and a one-sentence `prompt_summary` (≤ 200 chars).

### 2. Pick a template

| Template | Use when |
|---|---|
| `explainer` (default) | Long-form essay / "explain X to Y". Editorial magazine style. |
| `recap` | Decision log: timeline + decisions + open questions. |
| `status` | What's done / in flight / blocked. Dashboard register. |
| `pitch` | One-page proposal with a single CTA. |
| `letter` | Personal note / memo to a named recipient. |

When in doubt: `explainer`.

### 3. Write the HTML

Save to: `~/.claude/talk-html/<slug>-YYYYMMDD-HHMMSS.html`

Hard requirements:

- **Language (load-bearing)**: All artifact content — title, lede, headings, body prose, captions, pull-quotes, CTA copy, footer text — **must be in Simplified Chinese (zh-CN)**. The only English allowed is: structural metadata (`<!-- talk-html-meta ... -->`), file paths, shell commands, code snippets, URLs, technical identifiers (slug, session id), and short inline tokens where a Chinese rendering would be confusing (e.g. `gh gist create`, `~/.claude/...`). Set `<html lang="zh-CN">` and include `<meta charset="utf-8">`. Avoid 中英夹杂 marketing speak ("我们 leverage best-of-breed solutions") — Chinese prose should read like a human wrote it.
- **Self-contained**: inline CSS, no external JS. Google Fonts via `<link>` is allowed. The one exception: a single inline `onclick` handler for the audit-pill copy-to-clipboard is permitted.
- **Editorial typography**: pair a Latin display/body family with **Noto Serif SC** (思源宋体) — the Chinese face must carry the body text, not fall through to a system default. Recommended pairings: Fraunces + Noto Serif SC, or Newsreader + Noto Serif SC. Name the typographic mood in one sentence (Chinese is fine); if you cannot, redo it.
- **Diagrams**: SVG. Diagram labels in Chinese (or technical English where labels reference real identifiers like `index.jsonl`). Reserve ASCII art for explicit "terminal" flavor sections only.
- **Reflow**: works on mobile (≤ 420 px). No fixed pixel heights that clip text. Chinese reflows differently from English — test the narrow viewport.
- **Motion**: respect `prefers-reduced-motion`.
- **No "AI SaaS landing page" aesthetic**: no centered hero gradient, no random emoji, no rainbow CTAs.
- **No emoji** unless the user asked for emoji.
- **Size**: < 200 KB unless content genuinely warrants more.

A skeletal example with the required structural elements (meta comment, audit pill, footer link) lives at `templates/skeleton.html`. Read it once to learn the structural slots, then design the actual page fresh — do **not** copy the template's content or its visual style verbatim.

### 4. Stamp metadata

At the **top of `<head>`**, before any other content:

```html
<!-- talk-html-meta {"session_id":"<id>","job_dir":"<dir-or-null>","branch":"<git-branch-or-null>","prompt_summary":"<≤200 chars>","template":"<template-name>","generated_at":"<ISO8601 UTC>"} -->
```

Resolve values at generation time:

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
JOB_DIR="${CLAUDE_JOB_DIR:-}"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
GENERATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

If `$CLAUDE_JOB_DIR` is unset, link to the most recent session jsonl under `~/.claude/projects/<encoded-cwd>/*.jsonl`.

### 5. Add the audit pill

In `<body>`, append a small fixed pill (`position: fixed; bottom: 1rem; right: 1rem;`) showing:

- Short session id (8 chars).
- Click-to-copy full id (`navigator.clipboard.writeText(...)`) — yes, this one tiny inline `<script>` is allowed.
- Hover tooltip: full id + generated-at timestamp.
- Link to `file://<absolute path to session jsonl or job dir>`.

In the document footer, also include a one-line text version: "Made in Claude session `<short id>` · `<date>` · `<template>`", with the same `file://` link.

### 6. Preview locally

```bash
open "$HTML_PATH"
```

Then say to the user, in **exactly one line**:

> Preview opened: `file://<path>`. Reply `y` to publish, `n` to revise, `e` to edit locally first.

When the caller is another agent (no human), skip confirmation and go straight to step 8.

### 7. Confirm

- `y` → step 8.
- `n` → ask "what should change?", regenerate the HTML in-place (same filename), go back to step 6.
- `e` → tell user the local path; wait for them to say `done`, then go back to step 6.

### 8. Publish

```bash
bash ~/.claude/skills/talk-html/publish.sh "$HTML_PATH"          # default: secret gist (link-only sharing)
bash ~/.claude/skills/talk-html/publish.sh "$HTML_PATH" --public # public gist (listed on profile)
```

The script:

1. Pushes via `gh gist create`, retries up to 3× on transient 5xx.
2. Computes raw URL and `htmlpreview.github.io` rendered URL.
3. Appends a row to `~/.claude/talk-html/index.jsonl`.

If `gh` is not installed or not authed, the script keeps the local file, prints instructions, and exits non-zero — surface this clearly to the user.

### 9. Print URLs

Output exactly these four lines, in this order:

```
local:    file://<path>
gist:     <gist page URL>
raw:      <raw.githubusercontent URL>
rendered: <htmlpreview.github.io URL>
```

The **rendered** URL is the one the user shares with other humans. The **raw** URL is for re-fetching or embedding. The **gist** URL is for editing the file later.

### 10. (Optional) Verify CDN propagation

If the user says "verify it loads" or you are about to send the URL to someone else:

```bash
until curl -sI "$RAW" | head -1 | grep -q "200"; do sleep 2; done
```

Raw URLs have 5–10 s CDN lag.

## Recall

List the most recent 20 artifacts:

```bash
bash ~/.claude/skills/talk-html/recall.sh
```

Open one by slug substring (opens the rendered gist URL in browser):

```bash
bash ~/.claude/skills/talk-html/recall.sh <substring>
```

The index lives at `~/.claude/talk-html/index.jsonl` — one JSON object per line.

## Failure modes

| Failure | Recovery |
|---|---|
| `gh` not installed | Print install hint (`brew install gh`). Keep local file. Print local path. |
| `gh` not authed | Print `gh auth login`. Keep local file. Print local path. |
| Gist push 5xx | 3 retries with backoff. Still failing → keep local file, surface error. |
| `htmlpreview.github.io` 404 right after publish | Expected CDN lag. Wait 10 s then retry. |
| User says "n" 3 times | Stop. Ask "what direction would actually work?" — do not keep regenerating blindly. |

## Quality bar — do not violate

1. Real editorial design. One-sentence mood description must exist.
2. No emoji unless the user asked for emoji.
3. No fixed pixel heights that clip reflow.
4. Diagrams in SVG, not Mermaid (Mermaid blocks need JS; we ship JS-free except the audit-pill copy handler).
5. File < 200 KB unless content genuinely demands more.
6. Every HTML can be traced back to its originating session in one click via the audit pill **and** the `<!-- talk-html-meta -->` comment **and** the index.jsonl row.
