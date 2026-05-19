---
name: talk-html
description: Talk to humans in HTML, not chat. Generate a polished, self-contained zh-CN HTML page from the current conversation, preview it locally, and publish it to a GitHub gist by default unless the user explicitly opts out. The page MUST use real content — dive deep into the relevant repo(s) to find the actual code/data/artifacts behind every visual, or build the missing source with existing code paths; never draw a demo or mock unless the user explicitly asks for one. Any non-static content — interactive features, live/status boards, animations, running demos — MUST carry an embedded real video or GIF captured from a real run, never a static screenshot or diagram standing in for motion. Use for shareable explainers, recaps, status boards, letters, durable breadcrumbs, or prompts like /talk-html, talk in html, make a page, publish as gist, 用 html 解释, 做个网页, 推到 gist, or html 版本.
---

# talk-html

Communicate in HTML, not chat. Local preview first, then gist-publish for permanence. **Output language is always Simplified Chinese.**

> **Load-bearing principle — real content, not drawn demos.** Every page MUST be
> grounded in real sources. Before designing, dive deep into the relevant repo(s)
> and find the actual code, data, commands, routes, fixtures, screenshots, or
> generated artifacts that should drive the visual content. If the source you
> need does not exist yet and the user permits implementation work, build the
> smallest missing source with existing code paths and render *that*. Never
> substitute a hand-drawn mock, concept sketch, or fabricated UI for a missing
> run — the only exception is when the user explicitly asks for a mock or demo.
> And anything **non-static** — an interactive flow, a live/status board, an
> animation, a running UI — must be shown through a real embedded video or GIF,
> never a static screenshot or diagram standing in for motion. §3.0 and §3.1
> below make this concrete and active.

> **Source-of-truth guard — read this before any self-referential run.** The
> *only* canonical spec for this skill is `~/.agents/skills/talk-html/SKILL.md`
> (the symlink target that `~/.claude/skills/talk-html` and
> `~/.codex/skills/talk-html` load). Any `*/talk-html/SKILL.md` found *inside a
> project repo or a `.claude/worktrees/` checkout* is a **vendored copy**, not
> the spec — it may be stale or trimmed. When the page's topic is talk-html
> itself (redesign, diagnosis, "is it synced", proposal), the "dive into the
> relevant repo" rule above does **not** apply to this file: never treat a
> discovered in-repo `SKILL.md` as authoritative, and never re-propose rules
> that the canonical already contains. Preflight, every run:
> `bash ~/.agents/skills/talk-html/check-canon.sh --quiet` — it reports the
> canonical sha256 and flags every drifted vendored copy (exit 1 on drift).
> Run with `--heal` to collapse all vendored copies back onto canonical.

## When to invoke

- The current answer is structured enough that an HTML page beats a chat scroll (essay, recap, status board, proposal, letter).
- The user said "html version", "make a page", "publish this", "share this with X".
- The user wants to remember today's decision/insight in a recallable, linkable form.
- Another agent needs to hand a polished communication to a human user.

If the topic is **a finished UI feature / production page** belonging to a real product, use `frontend-design` or `design-html` instead. `talk-html` is for ephemeral communication artifacts, not shipped product UI.

## Workflow

### 0. Preflight — canonical self-check (every run, blocking)

Before anything else, run the drift sentinel:

```bash
bash ~/.agents/skills/talk-html/check-canon.sh --quiet
```

It prints the canonical sha256 and any persisted vendored copy that has
drifted (transient `.claude/worktrees/` copies are skipped by default; add
`--all` for a full sweep). Two cases:

- **Topic is talk-html itself** (redesign / diagnosis / "is it synced" /
  proposal): this preflight is **load-bearing**. Per the Source-of-truth guard,
  the only spec is `~/.agents/skills/talk-html/SKILL.md`. Do not read any
  in-repo `SKILL.md` as authoritative, and do not re-propose rules the
  canonical already has. If the sentinel reports drift, run it once with
  `--heal` to collapse the persisted copies back, then proceed.
- **Any other topic**: the preflight is a cheap sanity line — note drift if
  present, but it does not block the page.

This step exists because the historical bad case was a /talk-html run "diving
into the relevant repo" and reading a stale vendored copy of this very file as
if it were the spec. The guard plus this preflight make that structurally
impossible, not merely unlikely.

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
| `status` | What's done / in flight / blocked. Dashboard register. If it mirrors a live pipeline/board/run, that is non-static — §3.1 requires an embedded video/GIF of the real thing. |
| `pitch` | One-page proposal with a single CTA. |
| `letter` | Personal note / memo to a named recipient. |

When in doubt: `explainer`.

For `pitch` / `status` and any "show the boss / VC / customer" proof page, the
template only picks the skeleton — the page's job is to *convince a specific
reader*, so also apply **§3.2 (audience-first structure)** before writing.

### 3. Write the HTML

Save to: `~/.agents/talk-html/<slug>-YYYYMMDD-HHMMSS.html`

### 3.0 Source-ground the visual content

Default to **real contents, not drawn demos**. Unless the user explicitly asks
for a mock, concept sketch, or fictional demo, the page must be grounded in
actual sources:

- Dive into the relevant repo(s) before designing the page. Find the real
  code, docs, commands, data files, routes, endpoints, screenshots, tests,
  fixtures, or generated artifacts that should drive the visual content.
- If no suitable visual source exists yet and the user permits implementation
  work, build the smallest missing source with existing code paths, then render
  that real source. Do not replace missing product content with invented UI.
- If a page claims a terminal run, browser run, screenshot, GIF, chart, or
  dashboard is real, create it from an actual command on the current machine.
  Record the command, host, path, timestamp, and output artifact in the HTML.
- For tmux / Playwright evidence, a static illustration is not enough: start a
  real tmux session, run the real server or command in it, drive it with real
  Playwright, and use screenshots/video/GIF captured from that run.
- The final artifact should make clear which parts are source-backed and link
  or name the exact source files/commands. Speculative product framing is fine
  only when labeled as such and separated from verified evidence.

Hard requirements:

- **Language (load-bearing)**: All artifact content — title, lede, headings, body prose, captions, pull-quotes, CTA copy, footer text — **must be in Simplified Chinese (zh-CN)**. The only English allowed is: structural metadata (`<!-- talk-html-meta ... -->`), file paths, shell commands, code snippets, URLs, technical identifiers (slug, session id), and short inline tokens where a Chinese rendering would be confusing (e.g. `gh gist create`, `~/.agents/...`). Set `<html lang="zh-CN">` and include `<meta charset="utf-8">`. Avoid 中英夹杂 marketing speak ("我们 leverage best-of-breed solutions") — Chinese prose should read like a human wrote it.
- **Self-contained**: inline CSS, no external JS. Google Fonts via `<link>` is allowed. JS is sanctioned in exactly **two** narrow places, both pure clipboard utilities, never general page scripting:
  1. the **audit pill** copy handlers — `copy id` and copy-`claude --resume` (§5);
  2. the **“继续修改” bar** prompt builder (§5.1) — reads one text input and writes one clipboard string.
  Both are inline `onclick`/IIFE handlers with no network, no timers, and no DOM mutation beyond reading their own input. They are utility chrome, not page content, so they do **not** count as “non-static content” under §3.1 (the same carve-out the pill always had). Anything past these two — animation, `fetch`, frameworks, reveal logic — is out of bounds; a page that seems to need it is the wrong job for this skill (use `frontend-design`).
- **Editorial typography**: pair a Latin display/body family with **Noto Serif SC** (思源宋体) — the Chinese face must carry the body text, not fall through to a system default. Recommended pairings: Fraunces + Noto Serif SC, or Newsreader + Noto Serif SC. Name the typographic mood in one sentence (Chinese is fine); if you cannot, redo it.
- **Diagrams**: SVG. Diagram labels in Chinese (or technical English where labels reference real identifiers like `index.jsonl`). Reserve ASCII art for explicit "terminal" flavor sections only.
- **Reflow**: works on mobile (≤ 420 px). No fixed pixel heights that clip text. Chinese reflows differently from English — test the narrow viewport.
- **Motion**: respect `prefers-reduced-motion`.
- **No "AI SaaS landing page" aesthetic**: no centered hero gradient, no random emoji, no rainbow CTAs.
- **No emoji** unless the user asked for emoji.
- **Size**: < 200 KB unless content genuinely warrants more.
- **Published-page portability (load-bearing)**: anything that makes the local HTML "good" must also work in the gist/htmlpreview version. Do **not** rely on `file://` links, local relative asset paths, or local-only source links for primary evidence, images, demos, downloads, or "click to view" controls. For gist-published pages, embed critical media as `data:` URLs, include critical source/proof inline behind native clickable controls such as `<details><summary>...</summary>`, or link to a real public HTTPS URL. A local URL such as `http://127.0.0.1:4177` may be included only as an optional "try it on this machine" control, never as the only copy of evidence or source. Before publishing, review every `<a href>` and `<img src>`: if a remote reader on `htmlpreview.github.io` cannot click or view it, fix it before `publish.sh`.

A skeletal example with the required structural elements (meta comment, audit pill, footer link) lives at `templates/skeleton.html`. Read it once to learn the structural slots, then design the actual page fresh — do **not** copy the template's content or its visual style verbatim.

### 3.1 Non-static content → record a real video or GIF (no exceptions)

§3.0 says visual content must be source-grounded. This step makes that **active, not aspirational**, and it is the rule the whole skill turns on:

**If anything in the artifact is non-static, the page MUST embed a real video or GIF of it.** A static screenshot, an SVG diagram, or prose describing what "would" happen does not satisfy this — non-static content has to actually move on the page. You record it from a real run on this machine and embed the result; you do not draw it, mock it, or describe it.

"Non-static" is deliberately broad. Apply the rule whenever *either* the subject you are communicating *or* the page you are building has any of:

- a **UI, demo, dashboard, or terminal** — anything a reader would expect to *see running*;
- an **interactive feature** — a flow the user clicks / types / navigates through, a control that responds, a reveal that carries real content. This holds for interactivity in the *page itself*, too: this skill is JS-free by design so most pages genuinely are static and need no recording — but if you build a page whose value depends on interaction, that interaction still needs a moving capture for the reader who only ever sees a snapshot;
- a **status / live feature** — a `status`-template board, a progress register, a streaming build, anything whose worth is "what state is it in *right now*";
- **motion** — an animation, a transition, an animated diagram, anything beyond decorative CSS.

Static artifacts — a plain essay, a letter, a recap of past decisions with no live element — are unaffected. The rule only bites when something actually moves; when it does, the moving proof is non-negotiable.

**Use the project's OWN existing build code. Never reinvent build logic.** The whole point: the artifact is trustworthy because it came out of the same pipeline the project actually ships. Find the project's existing entrypoint — `landing/build-static.sh`, `pnpm build`, `make site`, `next build`, a `justfile` target, a documented script in `README` / `CLAUDE.md` — and run *that* verbatim. If you cannot find an existing build path, that is a finding to report, not a license to write your own.

The skill ships two helpers for the common "build → serve → drive a browser → GIF" case:

- `record-to-gif.sh` — orchestrator. Runs the project's build command, serves the real output dir, drives Chromium across your routes, and emits an optimized self-contained GIF + base64 data-URI + poster frame + `run-log.json`.
- `record-playwright.mjs` — the generic Playwright driver it calls (also runnable standalone).

```bash
# Full path — build with the project's own script, then record:
bash ~/.agents/skills/talk-html/record-to-gif.sh \
  --build-cmd 'bash landing/build-static.sh' \   # the project's EXISTING build entrypoint, verbatim
  --build-cwd /path/to/repo \
  --serve-dir /path/to/repo/build/output/dir \   # the real artifact the build produced
  --routes '["/","/page-a","/page-b"]' \
  --out "$CLAUDE_JOB_DIR/rec" --speed 1.6 --fps 10 --width 820

# Already-static artifact (no build step) — omit --build-cmd:
bash ~/.agents/skills/talk-html/record-to-gif.sh \
  --serve-dir /path/to/static/site --routes '["/"]' --out "$CLAUDE_JOB_DIR/rec"
```

On success it prints `KEY=VALUE` lines (`GIF=`, `GIF_B64=`, `POSTER=`, `POSTER_B64=`, `WEBM=`, `RUNLOG=`, `GIF_BYTES=`, `WEBM_BYTES=`). Embed the GIF as a `data:image/gif;base64,…` URL so it survives gist/htmlpreview (§ portability rule). Add a `prefers-reduced-motion` fallback to the poster frame. In the page, near the artifact, state plainly: the build command run, the host, the routes + their HTTP statuses (from `run-log.json`), and the recording timestamp — and offer the exact command chain behind a `<details>` so a reader can reproduce it.

When the helper does not fit (native app, hardware, a flow Playwright can't drive), still record reality — `tmux` + `asciinema`, `screencapture`, an `ffmpeg` screen grab — and embed that. The rule is *real run, real capture, embedded*; the helper is just the fast path for web UIs.

If recording genuinely cannot be done (no display, the build is broken, credentials unavailable), do **not** fabricate a visual. Say so on the page in plain Chinese, show whatever raw evidence you do have (build log, `run-log.json`, HTTP statuses), and label the section as un-recorded. The full decision is §3.1.1 — work it top to bottom.

### 3.1.1 失败降级决策树 — when the supporting artifact fails to build

§3.0/§3.1 assume the real run succeeds. Often it doesn't: the build is broken,
the recorder crashes, a tool is missing on this machine, the run produces
garbage. The failure of a supporting artifact is **never** a license to
fabricate one — it is a fork with four ordered exits and one path that is
structurally walled off. The exits exist because the cheapest move under
pressure is "just draw something close enough", and that is exactly the move
this skill is built to make impossible. Work down the list; take the first
exit that holds, and stop there.

**① 收窄结论 — narrow the conclusion.** Before reaching for any rebuild, ask
what the *real evidence you already have* can honestly support, and shrink the
claim to exactly that. A build log alone supports "the build step produced X,
log attached" — not "the pipeline runs end to end." The conclusion follows the
evidence; you never stretch the evidence to fit a conclusion you already wrote.
Most "missing artifact" situations resolve here: the page stays true, just
narrower. This exit is first because it is the only one that needs no new run —
if a smaller honest claim still does the job, the artifact was never required.

**② 用现有 code path 补建 — rebuild via the project's own path.** If a
narrowed claim still needs a live artifact, produce it the way the project
itself does: its existing entrypoint (`landing/build-static.sh`, `pnpm build`,
`make site`, a documented script in `README` / `CLAUDE.md`), run verbatim,
rendering what that path really emits. This is the §3.1 "use the project's OWN
build code, never reinvent" rule applied as a *recovery* step, not just the
happy path. If there is **no** existing build path, that absence is itself a
finding for exit ④ — never a license to hand-write build logic so you can
manufacture a visual. A run is only trustworthy because it came out of the
pipeline the project actually ships; a bespoke build you wrote to pass your own
page is not evidence.

**③ 诚实标注 gap — honestly label the gap.** If it cannot be recorded, do not
draw a stand-in. Say so on the page in plain Chinese, show the raw evidence you
*do* have (build log, `run-log.json`, HTTP statuses), and mark that section
explicitly as 未录制 / un-recorded. Per §3.2 this belongs in the collapsed
「诚实边界 / Verification notes」 block — preserved, not hidden. A page that
openly says "this part could not be recorded, here is the raw log" is honest
and shippable; one that draws the missing run is not, no matter how plausible
the drawing looks.

**④ block 上报 — block and report.** If the core claim has *zero* real
evidence behind it — nothing to narrow to, no usable build path, no raw log, or
the originating session cannot be traced (Quality bar #6) — that is a build
defect, not a publish signal. Stop. State plainly what is missing and why the
page cannot stand, and surface it to whoever asked. Do not ship a hollow or
fabricated page to keep the flow moving: a blocked report is a correct outcome,
a fake page never is. Exit ④ is a real, expected ending, not a failure of the
skill.

**The walled-off path — never an exit.** A hand-drawn mock, a concept sketch,
a fabricated UI, or a static screenshot standing in for motion is **not** one
of the four exits — it is precisely the move the load-bearing principle, §3.0,
§3.1, and Quality bar #8 all exist to forbid. The only time a drawn mock is
legitimate is when the user explicitly asked for one. Absent that explicit
request, "the artifact failed to build" routes ①→②→③→④ and never to a drawn
substitute; there is no fifth door.

### 3.2 Audience-first structure for proof / pitch / status pages

When the page's job is to **convince a reader** — a proof-of-work page, a
pitch, a status board, a "show the boss / VC / customer" artifact — it is
judged by that reader, not by the engineer who built it. §3.0/§3.1 make the
evidence *real*; this step makes it *legible to the buyer*. A page that is
technically honest but front-loads engineering exhaust still fails its job: the
reader bounces before reaching the proof. This is the most common way a
source-grounded page underperforms — strong evidence buried under build notes.

**Inverted pyramid — value and proof first, plumbing last.** The first screen
carries only two things: a one-sentence value claim a non-engineer can repeat,
and the proof chain (what was shown, what it rules out). Everything the reader
did not ask for moves down or out:

- **Out of the visible artifact entirely** — this is leakage, not honesty:
  secrets and API keys, internal job dirs, the host machine's OS / username /
  absolute paths, raw multi-screen JSON dumps, `*.cast` paths, the failed or
  retried takes, compression command logs (`gifsicle -O3 …`, `ffmpeg` flags),
  per-tool plumbing. A reader does not audit your recording process; a key or
  an internal path on a shared page is a defect, not transparency.
- **Sunk to the bottom, collapsed, not deleted** — real limitations and scope
  caveats. Keep them; hiding limits *is* dishonest. But put them in one final
  section titled **「诚实边界 / Verification notes」**, inside `<details>`,
  never on the first screen. Honest ≠ first.

**Shape a convincing page as ~6 blocks**, in order: (1) Hero — one value
sentence; (2) Problem — the failure the reader recognizes, in their words;
(3) Proof — the embedded real run (§3.1) with a proof-chain caption that says
what it rules out, not just what it shows; (4) What to verify — the causal
chain as discrete checkable claims; (5) Judge / third-party result — the
external verdict surfaced as a strong endorsement *next to* the proof, not
buried; (6) 诚实边界 — collapsed, last.

**Two-audience artifacts.** When the same proof genuinely serves two distinct
buyers — e.g. an investor who needs *market / moat / repeatable infrastructure*
and a customer who needs *risk reduction / auditability / their own acceptance
path* — give them two tracks: audience tabs or two in-page anchors that re-frame
the copy over the **same** evidence, not one averaged page that lands with
neither. Do not invent a second audience to look thorough; split only when both
readers are real for this artifact.

**The motion artifact must stand alone.** The embedded video/GIF (§3.1) is
often seen without the surrounding prose — dropped into a deck, forwarded, read
on a phone. It must carry its own meaning: a cover title, short step labels
burned into the frames, a held/zoomed beat on each pivotal moment (the DENY,
the PASS), legible at phone size. Prefer **MP4 primary + GIF fallback + poster
frame**; a reader who only ever sees the poster should still get the claim. The
page prose may explain the artifact; the artifact must not *depend* on it.

**Copy discipline (the buyer reads this, not your team).** Paragraphs ≤ 3
lines. Every heading legible to a non-engineer — a recruiter, a CFO, a founder.
No hype adjectives: "革命性", "颠覆性", "revolutionary", "game-changing" are
banned — the proof is the claim. The page should read like something you would
hand a boss / VC / customer, not like an internal retro or a build log.

Pure static communication (essay, letter, past-decision recap) is exempt — this
section bites only when the page's job is to convince.

### 4. Stamp metadata

At the **top of `<head>`**, before any other content:

```html
<!-- talk-html-meta {"session_id":"<id>","job_dir":"<dir-or-null>","branch":"<git-branch-or-null>","prompt_summary":"<≤200 chars>","origin_prompt":"<verbatim first user message, ≤200 chars>","template":"<template-name>","generated_at":"<ISO8601 UTC>"} -->
```

`prompt_summary` is your own one-sentence synthesis (used for `recall.sh` /
`index.jsonl` search). `origin_prompt` is different: it is the **verbatim first
thing the user typed** in this session — the real words, not a paraphrase. It
exists because a human scanning a stack of artifacts recognises *"tidy up the
local worktrees please"* instantly, but recognises nothing in `39b3f403`. The
footer and audit pill display `origin_prompt`, never the bare session hash.

Resolve values at generation time. This skill runs under **either** Claude Code
or Codex — resolve from whichever harness is active, never hard-code one:

```bash
# Claude Code sets CLAUDE_*; Codex sets CODEX_*. Try both, then fall back.
SESSION_ID="${CLAUDE_SESSION_ID:-${CODEX_THREAD_ID:-}}"
JOB_DIR="${CLAUDE_JOB_DIR:-${CODEX_JOB_DIR:-}}"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
GENERATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Claude Code background jobs expose only $CLAUDE_JOB_DIR, whose basename is the
# short (8-char) session id. Recover the full id from the matching transcript.
TRANSCRIPT=""
if [ -n "$JOB_DIR" ]; then
  SHORT="$(basename "$JOB_DIR")"
  TRANSCRIPT="$(ls -t "$HOME"/.claude/projects/*/"$SHORT"*.jsonl 2>/dev/null | head -1)"
fi
if [ -z "$TRANSCRIPT" ] && [ -n "$SESSION_ID" ]; then
  TRANSCRIPT="$(ls -t "$HOME"/.claude/projects/*/"$SESSION_ID"*.jsonl 2>/dev/null | head -1)"
fi
if [ -z "$SESSION_ID" ] && [ -n "$TRANSCRIPT" ]; then
  SESSION_ID="$(basename "$TRANSCRIPT" .jsonl)"
fi
SESSION_ID="${SESSION_ID:-unknown}"

# origin_prompt: the verbatim first user message from the transcript. This is
# what the footer/pill show as the session's name — a human-readable handle,
# not the hash. Take the first `type:"user"` line whose content is real text.
ORIGIN_PROMPT=""
if [ -n "$TRANSCRIPT" ]; then
  ORIGIN_PROMPT="$(python3 - "$TRANSCRIPT" <<'PY'
import json, sys
for line in open(sys.argv[1], encoding="utf-8"):
    try: o = json.loads(line)
    except Exception: continue
    if o.get("type") != "user": continue
    c = o.get("message", {}).get("content")
    text = c if isinstance(c, str) else next(
        (b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"), ""
    ) if isinstance(c, list) else ""
    text = " ".join(text.split())
    if text:
        print(text[:200]); break
PY
)"
fi
ORIGIN_PROMPT="${ORIGIN_PROMPT:-$SESSION_ID}"   # fall back to the hash only if extraction fails
```

The audit pill no longer carries a `file://` link to the raw transcript — that
link opened a wall of JSON and, worse, was dead the moment the page was
published to a gist (§3.0 portability). What a reader actually wants is to
*re-enter the conversation*, so the pill instead offers a copy-to-clipboard
`claude --resume <session_id>` command (see §5).

If `session_id` still resolves to `unknown`, that is a build defect — stop and
find the real id before publishing (Quality bar #6 is load-bearing). Likewise,
if `origin_prompt` had to fall back to the bare hash, the transcript lookup
failed — investigate before publishing rather than shipping a hash-named page.

### 5. Add the audit pill

The pill's job is to answer one question for whoever finds this HTML later:
*"which conversation made this, and how do I get back into it?"* So it leads
with the human-readable session name and gives a one-click way back in — not a
raw hash and not a dead file link.

In `<body>`, append a small fixed pill (`position: fixed; bottom: 1rem; right: 1rem;`) showing:

- **The session name** — `origin_prompt`, the verbatim first user message
  (truncate to ~50 chars + `…` so the pill stays small). This is the load-bearing
  element: a hash like `39b3f403` tells a human nothing; *"tidy up the local
  worktrees please…"* tells them everything.
- **A `copy id` button** — copies the full `session_id` to the clipboard. Keep
  this; the bare id is still what you paste into tooling and search.
- **A "resume" control** — copies the command `claude --resume <session_id>` to
  the clipboard, so the reader can paste it into a terminal and re-enter the
  exact conversation. This is the "go back to the session" affordance that
  replaces the old `file://` transcript link.
- **Hover tooltip**: full `session_id` + `generated_at` timestamp.

Both copy controls use `navigator.clipboard.writeText(...)` via inline `onclick`
handlers. This is the **one** sanctioned exception to the no-JS rule — it is
narrow on purpose: only clipboard copy, only inside the audit pill. Do not let
it grow into general page scripting.

Do **not** add a `file://` link to the transcript `.jsonl`. It rendered as a
wall of JSON, and it was always dead in the published gist version anyway
(§3.0). The resume command is the supported way back to the conversation.

In the document footer, also include a one-line text version: "Made in session
`<origin_prompt>` · `<date>` · `<template>`" — show the same human-readable
session name, and you may repeat the copy-to-clipboard `claude --resume` control
here too. (Name the harness — "Claude" / "Codex" — only if you are certain which
one is running; otherwise the neutral "Made in session" is correct.) Do not put
a `file://` link in the footer either.

### 5.1 Add the “继续修改” bar (text input + copy-prompt)

The audit pill answers *“which conversation made this?”*. It does **not** solve
the very next thing a reader wants: they look at the finished page, want one
detail changed, and today the only path is to hand-copy the file/gist URL into a
terminal and improvise a prompt. That round-trip is exactly the friction this
skill exists to kill. So **every page also carries a small “继续修改这页” bar**
that turns “I want a tweak” into a single paste.

Put it as its own labeled block just above the footer — not inside the pill, a
text field has no business in an 11px pill. Three parts:

- a one-line **text input** where the reader types the change they want
  (Chinese placeholder, e.g. `描述要改什么，例如：把流程图改成横向 / 补一节风险`);
- a **“复制续修指令” button** that assembles a complete CLI prompt from what
  they typed and copies it to the clipboard;
- one muted helper line: paste it into a terminal running Claude to continue.

**The exact string the button must place on the clipboard** (with `INSTR` =
whatever the reader typed):

```
claude --resume <session_id> "继续修改我用 talk-html 生成的产物（slug: <slug>；本地 <local_path>；若会话已失效，先跑 bash ~/.agents/skills/talk-html/recall.sh <slug> 定位它）。修改要求：INSTR。改完按 talk-html 流程重新发布 gist 并打印四个 URL。"
```

Why this shape, not just the URL the human would have pasted by hand:

- It leads with `claude --resume <session_id>` because on the origin machine
  that reloads the full context — Claude already knows the exact local file and
  the gist it just published, so the follow-up is reliable and needs no URL.
- It still **stands alone** if the session is gone or the reader is on another
  machine: it names the artifact by `slug` and tells Claude to relocate it with
  `recall.sh <slug>`, which reads `index.jsonl` (including the published
  `rendered_url`). It must **not** lean on a `file://` path as the only handle —
  that is dead in the gist (§3.0). The local path is a same-machine convenience,
  listed alongside the durable handles, never instead of them.
- It carries the reader's instruction *and* the re-publish step, so one paste
  goes all the way from “I want X” to a fresh shareable link — no “resume, then
  think of what to say.”

Resolve `session_id`, `slug`, and `local_path` at generation time. `INSTR` is
read live from the input. The mechanism is deliberately trivial: read
`#tlh-ask`, fall back to a `<在此描述要改什么>` placeholder if it's empty (a
curious click should never copy garbage), splice it into the template above,
`navigator.clipboard.writeText(...)`. No other JS — this is the second and last
sanctioned exception; see the Self-contained bullet in §3 for why it is bounded
this tightly. It must behave identically in the published gist/htmlpreview
version (Quality bar #7), which pure inline input-read + clipboard-write does.

The structural slot for this bar lives in `templates/skeleton.html` alongside
the pill and footer slots — read it once for the shape, then design the bar's
look fresh to match the page.

### 6. Preview locally

```bash
open "$HTML_PATH"
```

Opening the local preview is informational, not a gate — do **not** stop here to ask "should I publish?". The whole point of this skill is to hand the human a durable, link-shareable artifact; a gist that nobody had to approve is the success case, a forgotten local file is the failure case.

### 7. Publish (default — no confirmation step, no permission prompt)

Publishing to a gist happens automatically. Do not pause for a `y`/`n`, do not ask permission, do not wait for the user to react to the preview. Just publish.

**The upload requires no tool permission.** `publish.sh` is pre-authorized at the user level in `~/.claude/settings.json` (`permissions.allow` lists every invocation form — `bash`-prefixed and direct-exec, `~/.agents/...`, absolute `/Users/m1/.agents/...`, and the `~/.claude/skills/...` symlink path). Running it never raises a permission prompt. Treat the `publish.sh` call as a pre-approved, non-interactive command: invoke it exactly as written below — do not wrap it, do not rename the path, do not split it across shells — and never surface a permission/approval question for the upload itself. If you ever see a permission prompt for `publish.sh`, that is a settings regression to report, not a reason to ask the user to approve it manually.

**Skip publishing only when the user has explicitly opted out.** Look back through the conversation for an unambiguous opt-out — e.g. "don't publish", "don't send", "local only", "just preview", "no gist", "别发 / 不要发 / 先别推 / 本地就行 / 不用推 gist". If and only if you find one:

- Stop here. Print one line: `local: file://<path>`.
- Tell the user, in one more line, how to publish later: `bash ~/.agents/skills/talk-html/publish.sh "<path>"`.
- Do not run the publish command.

In every other case — including when the caller is another agent, and including when the user never said anything about publishing at all — run the publish command below. "The user didn't explicitly say to publish" is **not** an opt-out; absence of an opt-out means publish.

If the user later wants changes, regenerate and re-run `publish.sh` — it creates a fresh gist. Don't treat the first publish as a point of no return.

A portability pass is **built into `publish.sh`**: it greps the file for `file://` and local relative asset paths and prints any hits to stderr as a non-blocking warning, then publishes anyway. You do not need to run a separate prompted command before publishing — that would just add friction to a flow that is meant to be one pre-authorized call. If you *want* a pre-check before generating the gist (optional, not a gate), this standalone scan is equivalent:

```bash
rg -n 'file://|src="(?!data:|https://)|href="(?!https://|http://127\.0\.0\.1|#|data:)' "$HTML_PATH"
```

A hit that points to primary evidence, images, downloadable/source material, or a "click to view" affordance is still a real defect — fix it by converting to embedded content or a public HTTPS URL, then re-run `publish.sh` (it makes a fresh gist). But the upload itself is never blocked or gated on this; `publish.sh` warns and proceeds.

```bash
bash ~/.agents/skills/talk-html/publish.sh "$HTML_PATH"          # default: secret gist (link-only sharing)
bash ~/.agents/skills/talk-html/publish.sh "$HTML_PATH" --public # public gist (listed on profile)
```

The script:

1. Runs the non-blocking portability scan (warns on `file://`/local paths, never rejects).
2. Pushes via `gh gist create`, retries up to 3× on transient 5xx.
3. Computes raw URL and `htmlpreview.github.io` rendered URL.
4. Appends a row to `~/.agents/talk-html/index.jsonl`.

It is pre-authorized at the user level (see §7) and runs with no permission prompt. If `gh` is not installed or not authed, the script keeps the local file, prints instructions, and exits non-zero (it does **not** prompt) — surface this clearly to the user.

### 8. Print URLs

Output exactly these four lines, in this order:

```
local:    file://<path>
gist:     <gist page URL>
raw:      <raw.githubusercontent URL>
rendered: <htmlpreview.github.io URL>
```

The **rendered** URL is the one the user shares with other humans. The **raw** URL is for re-fetching or embedding. The **gist** URL is for editing the file later.

### 9. (Optional) Verify CDN propagation

If the user says "verify it loads" or you are about to send the URL to someone else:

```bash
until curl -sI "$RAW" | head -1 | grep -q "200"; do sleep 2; done
```

Raw URLs have 5–10 s CDN lag.

## Recall

List the most recent 20 artifacts:

```bash
bash ~/.agents/skills/talk-html/recall.sh
```

Open one by slug substring (opens the rendered gist URL in browser):

```bash
bash ~/.agents/skills/talk-html/recall.sh <substring>
```

The index lives at `~/.agents/talk-html/index.jsonl` — one JSON object per line.

## Gallery (static, no server)

A visual index of every artifact. It is a **single static HTML file** — no
server is run. Thumbnails are downscaled and base64-inlined, cards are
pre-rendered, and the only JS is a search filter + a copy button. It opens from
`file://` and behaves identically once published to a gist.

```bash
cd ~/.agents/talk-html/_gallery && bun build.ts            # rebuild gallery.html (incremental thumbs)
cd ~/.agents/talk-html/_gallery && bun build.ts --publish  # + push to a secret gist, print the htmlpreview URL
cd ~/.agents/talk-html/_gallery && bun verify.ts           # judge harness → JSON verdict + proof PNG
```

- Each card's action links to the **previewed gist** (`rendered_url`,
  `htmlpreview.github.io/?…`), never the raw gist page or a local path.
  Unpublished pages show a muted "本地未发布" badge, no link.
- There is **no sync button**. The header has a "复制更新指令" button that
  copies a fixed prompt (the single-source-of-truth `UPDATE_PROMPT` constant in
  `build.ts`) — paste it into Claude Code to rebuild + republish. `verify.ts`
  asserts the embedded copy equals the constant byte-for-byte (no LLM in the
  prompt path).
- Share the gist's `htmlpreview` URL, not the gist page. `build.ts` aborts if
  any `href`/`src` carries a local path, so the published gallery is portable.

## Failure modes

| Failure | Recovery |
|---|---|
| `gh` not installed | Print install hint (`brew install gh`). Keep local file. Print local path. |
| `gh` not authed | Print `gh auth login`. Keep local file. Print local path. |
| Gist push 5xx | 3 retries with backoff. Still failing → keep local file, surface error. |
| `htmlpreview.github.io` 404 right after publish | Expected CDN lag. Wait 10 s then retry. |
| User wants changes after publish | Regenerate the HTML, re-run `publish.sh` (creates a fresh gist). The first publish is not final. |
| User explicitly said "don't publish" | Honor it — keep the local file, print the local path + the manual `publish.sh` command. Never publish over an explicit opt-out. |
| `record-to-gif.sh` build step fails | Run the §3.1.1 tree: narrow the claim (①) or rebuild via the project's own path (②); if neither holds, surface `build.log` as raw evidence and label the section un-recorded (③, §3.1.1). Never substitute a mock. |
| `ffmpeg` / `node` missing for recording | Print install hint (`brew install ffmpeg`). Per §3.1.1: fall back to still screenshots from `screencapture` / Playwright if they honestly support a narrowed claim (①); otherwise label the section un-recorded (③), never a drawn stand-in. |
| Core claim has no real evidence at all | §3.1.1 exit ④: this is a build defect, not a publish signal. Stop, state what is missing, report it. Do not ship a hollow or fabricated page to keep the flow moving. |

## Quality bar — do not violate

1. Real editorial design. One-sentence mood description must exist.
2. No emoji unless the user asked for emoji.
3. No fixed pixel heights that clip reflow.
4. Diagrams in SVG, not Mermaid (Mermaid blocks need JS; we ship JS-free except the audit-pill copy handler).
5. File < 200 KB unless content genuinely demands more. A real embedded recording (GIF/video data-URI) is a legitimate reason to exceed it — note the size in the page and offer to compress.
6. Every HTML can be traced back to its originating session via three independent paths: the audit pill (shows the human-readable `origin_prompt` name and offers a copy-to-clipboard `claude --resume <id>` command to re-enter the conversation), the `<!-- talk-html-meta -->` comment, **and** the index.jsonl row. The pill must never reduce to a bare session hash, and must not rely on a `file://` transcript link — that link is dead in the published gist.
7. Gist/htmlpreview parity: if the local preview has a visible GIF/image/evidence block or a clickable source/proof control, the rendered gist must expose the same material without broken `file://` or local relative links.
8. Non-static content is recorded, not drawn (§3.1). Anything interactive, live/status, animated, or "this UI/demo/dashboard runs" — in the subject matter *or* the page itself — is backed by a real embedded video or GIF from a real-machine real-run capture, produced through the **project's own existing build code** — never reinvented build logic, never a static screenshot or mock standing in for motion. A page that is entirely static (essay, letter, past-decision recap) needs no recording; the moment something moves, it does. When that capture fails, the §3.1.1 decision tree governs the fallback (①收窄结论 → ②用现有 code path 补建 → ③诚实标注 gap → ④block 上报) — a drawn substitute is never one of the exits.
9. Every page ships the “继续修改” bar from §5.1 — a text input plus a copy-prompt button — so a reader can turn a requested change into one terminal paste without hand-copying any URL. The copied prompt is self-contained: a `claude --resume <id>` handle **plus** the `slug` + `recall.sh` relocation path, never only a `file://` link, and it works the same in the published gist as locally. This bar and the audit pill are the only scripted elements on the page.
10. Convincing pages (proof / pitch / status / "show the boss / VC / customer") follow §3.2: inverted pyramid — one-sentence value claim + proof chain on the first screen; no secret / key / internal job-dir / host path / failed-take / compression-log in the visible artifact; real limitations preserved but collapsed into a final 「诚实边界 / Verification notes」 `<details>`; the embedded motion artifact is self-labeled (cover title + burned-in step labels, MP4-primary + poster) so it stands alone; copy in ≤3-line paragraphs, non-engineer-legible headings, zero hype adjectives; two real buyer types get two re-framed tracks over the same evidence, never a fabricated second audience. Pure static communication (essay / letter / recap) is exempt.
