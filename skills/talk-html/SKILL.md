---
name: talk-html
description: Invoke when the user wants a shareable HTML one-pager out of the current conversation, a writeup, or assembled context — recap, postmortem, retro, status board, transition letter, founder/exec update, decision log, or "send a link, not a chat scroll" artifact. The skill provides what raw HTML cannot: publish.sh uploads to a GitHub gist and returns the shareable URL; recall.sh + ~/.claude/talk-html/index.jsonl let the user grep past pages weeks later. zh-CN by default; embeds real screenshots/video/diff for non-static content, never hand-drawn mocks. Triggers: /talk-html, "make a page", "one-pager", "html version", "publish this", "shareable page", "gist link", "做成一页", "做个网页", "html 版本", "用 html 解释", "推到 gist". When the user names an audience for the page ("for ops", "for the CEO", "founder update", "send to data team"), trigger this — they want a recallable shareable artifact, not a stray HTML file. NOT for shipped UI, landing pages, React components, doc conversion, QA bug reports, or scripts.
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
> never a static screenshot or diagram standing in for motion. Source-grounding
> reaches *inside* the run: a real binary, built by the project's own pipeline
> and recorded honestly, is still a drawn mock if every number, status, and
> series it displays is a hardcoded literal. Real run + invented data is a mock
> wearing a real binary's clothes. §3.0, §3.0.1 and §3.1 below make this
> concrete and active.

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
> `bash ~/.agents/skills/talk-html/check-canon.sh --heal --all --quiet` — it
> prints the canonical sha256 and **collapses every vendored copy (persisted
> *and* transient `.claude/worktrees/` checkouts) back onto canonical in the
> same pass**. Only the latest canonical is ever ground truth: drift is
> overwritten, not merely reported, so a stale copy can never survive into a
> later run to be read as spec.

## When to invoke

- The current answer is structured enough that an HTML page beats a chat scroll (essay, recap, status board, proposal, letter).
- The user said "html version", "make a page", "publish this", "share this with X".
- The user wants to remember today's decision/insight in a recallable, linkable form.
- Another agent needs to hand a polished communication to a human user.

If the topic is **a finished UI feature / production page** belonging to a real product, use `frontend-design` or `design-html` instead. `talk-html` is for ephemeral communication artifacts, not shipped product UI.

## Workflow

### 0. Preflight — canonical self-heal (every run, enforcing)

Before anything else, run the drift sentinel in **heal mode**:

```bash
bash ~/.agents/skills/talk-html/check-canon.sh --heal --all --quiet
```

This is not a check that *reports* drift — it *erases* it. In one pass it
prints the canonical sha256 and overwrites **every** vendored copy (persisted
project mirrors **and** transient `.claude/worktrees/` checkouts) with
`~/.agents/skills/talk-html/SKILL.md`. After preflight, exactly one version of
this skill exists on disk: the latest canonical. There is no "two cases" and
no manual follow-up step — whatever the page's topic, the latest is the only
ground truth, enforced every run.

- **Topic is talk-html itself** (redesign / diagnosis / "is it synced" /
  proposal): per the Source-of-truth guard, never read a discovered in-repo
  `SKILL.md` as authoritative and never re-propose rules the canonical already
  has. The auto-heal above guarantees any copy you might still glance at is
  already byte-identical to canonical.
- **Any other topic**: the heal is cheap (a few `cp`s) and non-blocking — it
  runs, the latest is enforced, the page proceeds.

This step exists because the historical bad case was a /talk-html run "diving
into the relevant repo" and reading a stale vendored copy of this very file as
if it were the spec. Auto-heal makes that case **structurally impossible**: a
stale copy cannot survive a single preflight, so it can never be read as spec
in this run or any later one.

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

### 3.0.1 The data inside the run must be real, too

§3.0 grounds the *visual*; this grounds *what the visual says*. The two are
not the same thing, and the gap between them is the single most common way a
page is technically honest yet substantively fake: the program is real, the
recording is real, every value on screen is invented.

A real run earns trust because it shows what the system *actually does with
real inputs*. A binary whose dashboard reads `status: "周环比 +12%"` from a
`const` table, or whose chart is `vec![3,5,4,6,8,…]` written by hand, does not
do that — it performs a screenshot the author drew, just rendered by a
compiler instead of a design tool. Recording it in a real PTY with honest
timestamps proves the *terminal* was real; it proves nothing about the claim
the reader takes away, which is the numbers. The reader cannot tell hardcoded
`+12%` from measured `+12%`; that is exactly why the burden is on the page.

So before you record anything that displays data, ask the question §3.0 asks
of the visual, now of the values: **where does each number, status, label, and
series come from, and could a reader re-derive it from a source named on the
page?** Acceptable answers are a file the program reads, a command it runs, an
API it calls, a fixture committed to the repo, a real metric computed at run
time. Not acceptable: a literal in the source, a "仅作示意 / illustrative"
placeholder, a plausible-looking series with no origin. If the program does
not yet read a real source, §3.0 already told you the move — build the
smallest path that makes it read one (an env-pointed dir, a generated data
file stamped with the command + source path + timestamp, a real query), then
record *that*. Drive the real binary from real data; do not record the real
binary reciting fake data.

When the real source genuinely cannot back a panel — there is no real
engagement metric, the input does not exist yet — that panel is a failed
artifact, and the **§3.1.1 decision tree governs it exactly as a failed build
does**: ① narrow the claim (drop the fabricated sparkline, or relabel it to
the real series you *do* have — file sizes, commit counts, test results); ②
rebuild it from the project's own real source; ③ if neither holds, render an
honest empty/"数据不可用" state and note it in 诚实边界; ④ if the whole page
has no real data behind it, block and report. A fabricated value is never an
exit, for the same reason a drawn mock never is — it is the precise thing the
load-bearing principle exists to forbid, and a compiler in the loop does not
launder it.

The page must make the data's origin checkable: near the run, name the source
files / commands / fixtures the values came from, and put the exact
reproduction commands behind a `<details>` so a reader can run `wc`, `git
log`, `curl`, or the generator and land on the same numbers. "Real run" in
the verification caption means *real binary on real data*; if only the binary
was real, the caption must say so and the §3.1.1 narrowing applies.

### 3.1 Non-static content → record a real video or GIF (no exceptions)

§3.0 says visual content must be source-grounded. This step makes that **active, not aspirational**, and it is the rule the whole skill turns on:

**If anything in the artifact is non-static, the page MUST embed a real video or GIF of it.** A static screenshot, an SVG diagram, or prose describing what "would" happen does not satisfy this — non-static content has to actually move on the page. You record it from a real run on this machine and embed the result; you do not draw it, mock it, or describe it.

Recording does not launder data. A real PTY capture of a real binary that is displaying hardcoded `const` literals satisfies the *motion* requirement and still fails §3.0.1 — the run must be of the real binary **on real data**, not the real binary reciting placeholders. Before you record, confirm the values on screen trace to a source per §3.0.1; a recorded fake is no better than a drawn one, just more expensive to make.

"Non-static" is deliberately broad. Apply the rule whenever *either* the subject you are communicating *or* the page you are building has any of:

- a **UI, demo, dashboard, or terminal** — anything a reader would expect to *see running*;
- an **interactive feature** — a flow the user clicks / types / navigates through, a control that responds, a reveal that carries real content. This holds for interactivity in the *page itself*, too: this skill is JS-free by design so most pages genuinely are static and need no recording — but if you build a page whose value depends on interaction, that interaction still needs a moving capture for the reader who only ever sees a snapshot;
- a **status / live feature** — a `status`-template board, a progress register, a streaming build, anything whose worth is "what state is it in *right now*";
- **motion** — an animation, a transition, an animated diagram, anything beyond decorative CSS.

Static artifacts — a plain essay, a letter, a recap of past decisions with no live element — are unaffected. The rule only bites when something actually moves; when it does, the moving proof is non-negotiable. §3.2.1 turns this static-vs-motion call into a per-artifact lookup — which artifact types owe a moving capture, and which reviewer rejects the page without it.

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

§3.0/§3.1 assume the real run succeeds *and renders real data*. Often it
doesn't: the build is broken, the recorder crashes, a tool is missing on this
machine, the run produces garbage — **or it builds and records cleanly but its
panels are hardcoded literals (§3.0.1)**. That last case is the same failure,
not a lesser one: a run with no real data behind it is an unsupported
artifact, and it enters this tree exactly where a failed build does — most
often at ② (drive the real binary from the project's own real source) or ①
(narrow/relabel the panel to the real series you do have). The failure of a
supporting artifact is **never** a license to fabricate one — it is a fork with four ordered exits and one path that is
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
a fabricated UI, a static screenshot standing in for motion, **or a real
binary recorded while it recites hardcoded `const` data (§3.0.1)** is **not**
one of the four exits — it is precisely the move the load-bearing principle,
§3.0, §3.0.1, §3.1, and Quality bar #8 all exist to forbid. A compiler between
you and the fake values changes the cost of the lie, not its nature. The only time a drawn mock is
legitimate is when the user explicitly asked for one. Absent that explicit
request, "the artifact failed to build" routes ①→②→③→④ and never to a drawn
substitute; there is no fifth door.

### 3.1.2 录制交互式 Claude Code CLI — a live-TUI pane is a composer, not a shell

§3.1's `tmux` + `asciinema` fallback is the path you take to record an
interactive Claude Code (or any REPL/TUI) session — a real demo of the agent
being driven, denied, corrected. It has one trap that has already shipped a
broken proof, so it gets its own rule.

The instant you launch `claude` in a pane, that pane stops being a shell. It is
now the **model's input composer**. Every later `tmux send-keys` to that pane
is a *user turn* — the model reads it and answers it. That includes
"narration" you only meant for the orchestrator or the viewer: a line like
`echo; echo '[team-sync] published rule'; tail -n1 store.jsonl | jq …` sent to
a still-live claude pane is **not** run by bash — it is typed into the composer
and submitted as the next prompt. On the recording it shows up as a real extra
user turn (a stray prompt starting with `echo`), visually indistinguishable
from a fabricated one. A demo whose entire claim is "these are exactly the N
real turns a human sent" is destroyed by an N+1th turn made of shell plumbing.
It is the §3.0 lie in a new costume: the capture is real, the turn count is
not — and the page is now asserting something false.

The root cause is always the same: addressing panes by **position or timeline**
("then send the summary to the left pane") instead of by **state** ("is this
pane a bash prompt or a live TUI *right now*?"). Drive panes by state:

- **Send a live-TUI pane only the inputs that are meant to be real model
  turns** — the actual prompts, nothing else. Their count and content are the
  exact thing the page is proving; treat every keystroke into that pane as
  load-bearing evidence.
- **Route every narration / inspection / "show the artifact" line to a pane
  that is still a bash shell.** A second pane whose own TUI hasn't launched yet
  is ideal — it doubles as the natural place to show the hand-off. Otherwise
  fully quit the TUI first: send its real exit, then *verify* the pane is back
  at a shell prompt before sending any shell command — never assume the exit
  landed.
- The real side effect (appending to a store, copying a file) is performed by
  the orchestrator in the shell that runs the demo — **not** by typing a
  command into a recorded pane. A command typed into a pane exists only for the
  viewer, and only ever belongs in a pane that is genuinely a shell.

**Preflight check — run it before recording, and again before you re-embed.**
For each pane that launches `claude`, every `send-keys … Enter` (or wrapper
like `send_prompt`/`send`) that targets that pane *after* its launch line must
be one of its intended real user turns. List them and confirm the count is
exactly right:

```bash
# Every input sent to Alice's pane ($P0) AFTER claude launched must be one of
# her intended prompts. Read the list; the count must equal the turns the
# page claims (e.g. EXHIBIT A claims TWO).
awk '/launch_coder "\$P0"|claude .*\$P0/{after=1}
     after && /send-keys -t "\$P0"|send(_prompt)? "\$P0"/{print NR": "$0}' demo/driver.sh
```

A wrong count means the bug is in the **driver script**, not the recorder or
the encoder — re-recording without fixing the script just reproduces the bad
turn, and re-embedding ships it. After re-recording, watch the clip once at the
relevant moment and confirm the pane shows exactly the intended prompts: this
is the §3.1 "watch the capture, don't assume it worked" discipline applied to
turn count, and it is the last gate before the video becomes the proof.

### 3.1.3 证据闸门 — the fail-closed finish gate (mechanical, not advisory)

Everything above this line — §3.0, §3.0.1, §3.1, §3.1.1, Quality bar #8 — was
*prose*. Prose is reasoned with, and under deadline pressure a model reasons
its way around it: "close enough", "the motion looks real", "I'll note it
later". Nothing ever mechanically refused a fabricated video, so fabricated
videos shipped.

This was measured, not assumed. A 36-clip human ground-truth set
(`~/.agents/mp4-eval/ground-truth.json`) was scored against a *motion*-based
probe. The probe agreed with the human on only **19/36** and **never once
returned FAIL** — clips with heavy motion (`YAVG` up to 195) were labelled
fake by the human because the *data on screen was invented*. The lesson is
exact: **you cannot gate "is this video real" on pixels.** Motion, sharpness,
duration, file size — all of it is the thing a real-binary-reciting-fake-data
recording sails through. The one property that is both load-bearing and
mechanically checkable is **provenance**: can a reader trace this motion
artifact back to a real command, host, data source, and time?

So the anti-fake rule is now a **gate, run before §7 publish / before you
declare the page done**, not a paragraph you affirm:

```bash
bash ~/.agents/skills/talk-html/verify-evidence.sh "$HTML_PATH"
```

It is fail-closed. A page that embeds a motion artifact (video / webm /
animated gif / `data:video`) PASSES only if one of these is true:

- **inline provenance** — a `<!-- talk-html-evidence {"cmd":"…","host":"…","source":"…","recorded_at":"<ISO8601>"} -->`
  record near the artifact (all of `cmd`, `source`, `recorded_at` non-empty),
  where `source` names the real file/command/fixture/metric the on-screen data
  came from (this is the §3.0.1 claim, made checkable);
- **a co-located `run-log.json`** — what `record-to-gif.sh` already emits
  (build cmd + routes/HTTP + timestamp);
- **a DECLARED un-recorded gap** — the §3.1.1 ③ honest exit: a
  `data-evidence="unrecorded"` element plus a visible 未录制 / un-recorded
  label. A *declared* gap is honest and ships; a *silent* gap is the lie.

A page with no motion artifact is static and passes untouched (essays,
letters, recaps stay exempt). `publish.sh` runs this same gate as a hard
precondition and **refuses to upload** (exit non-zero, local file kept, no
prompt) when it fails — publishing is the act that turns a fabricated video
into a shared lie, so the publish path itself is where the refusal lives.

A non-zero gate is **not** a signal to "fix the gate" or pass `--public`
harder. It is a §3.1.1 ④ block: state plainly what evidence is missing and
stop. The gate has the same four honest exits and the same one walled-off
path as §3.1.1 — embedding the artifact anyway, or hand-writing a
`talk-html-evidence` record for a run that did not happen, *is* the
fabrication this whole section exists to forbid. A passing gate is a floor,
not a certificate: it proves the run is traceable, the reader still judges
whether the traced run actually supports the claim. Which programmatic tools
produce that machine-checkable verdict, and the deterministic pass/fail
threshold, are tabulated per `artifact_type` in §3.2.1's
`proof-build-eval-matrix.csv` — the gate there feeds this one, it does not
replace it.

### 3.1.4 Eval / bad-case pages that ask for videos must play video

When a page explains expected evals, judge harnesses, bad-case coverage, probe
failures, Gate Rule mappings, or MP4/video artifact evaluation, and the user
asks for "videos", "playable videos", "attach videos", or equivalent, a static
table, screenshot, poster, or contact sheet is not enough. Every claimed bad
case, failed probe group, or `#Gate Rule {index}` cluster needs a visible
`<video controls>` artifact attached to it.

- Prefer short derived clips (3-8 seconds) from the real source MP4 when full
  files are too large. Keep a manifest with source path, label/case id, offset,
  clip path/bytes, and the exact `ffmpeg` command. Add SHA checksums when cheap.
- Embed clips as `data:video/mp4;base64,...` or link to public HTTPS media.
  Never publish `file://` or local relative video paths in a gist page.
- Add nearby `<!-- talk-html-evidence {...} -->` provenance naming the clip
  generation command, source label/manifest, host, and `recorded_at`.
- The page structure must make the mapping inspectable: `#Gate Rule {index}` ->
  failed case ids / probe failures -> related playable videos.
- Before publish, verify the video elements locally: metadata loads, duration is
  greater than zero, and at least one frame can render. If a remote rendered URL
  is used, verify it after publish when practical.
- If a video cannot be made playable, explicitly mark it un-recorded /
  不可播放 and apply §3.1.1. Do not silently replace it with a screenshot.

### 3.2 Audience-first structure for proof / pitch / status pages

When the page's job is to **convince a reader** — a proof-of-work page, a
pitch, a status board, a "show the boss / VC / customer" artifact — it is
judged by that reader, not by the engineer who built it. §3.0/§3.1 make the
evidence *real*; this step makes it *legible to the buyer* — and §3.2.1 names,
per artifact type, the exact proof modality and the reviewer who must see it. A page that is
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

### 3.2.1 证据类型 × 必看人 × 怎么机判 — the proof, reviewer & gate matrices

§3.1 decides *whether* a thing needs motion; §3.2 decides *who* the page must
convince. Between them sits a recurring miss: the page is honest and embeds *a*
proof, but the wrong *kind* of proof for the artifact it reports, so the one
reviewer whose sign-off it needs bounces. A code reviewer asked to approve a
change does not read raw post-change source — they read the diff. A UX reviewer
cannot judge an interaction from a screenshot — they need it recorded. A QA
engineer will not take "bug fixed" as a sentence — they need failing-before /
passing-after. The proof *modality* is part of the claim, not packaging; pick
the wrong one and the page is unfalsifiable to exactly the person it is for.

`references/proof-matrix.csv` (absolute, since the loader symlinks vary:
`~/.agents/skills/talk-html/references/proof-matrix.csv`) tabulates the floor.
Each row maps one `artifact_type` → the `visual_proof_type` it owes, the
`role_that_MUST_see_it`, the `recommended_view` that role actually reads, and
`why_they_need_it`. Consult it whenever the page's subject is a concrete change
or deliverable — code / UI / interactive UI or TUI / bug fix / test / perf /
security / API / DB migration / architecture / data pipeline / dashboard / docs
/ localization / a11y / release / mobile / deploy / incident / ML model /
payments / permissions, and the like.

Use it in order:

1. **Name the artifact_type.** What did this page actually report a change to?
   Match the closest row(s). One page can be several types at once (an API
   change *and* a DB migration) — it then owes the proof each row lists, not
   one proof for the pair.
2. **Owe that visual_proof_type, in that recommended_view.** This is the §3.1
   static-vs-motion call made concrete per artifact: rows whose proof is
   `GIF / MP4` or a `recording` are **non-static** — §3.1 / §3.1.4 apply in
   full, the page embeds a real moving capture, never a screenshot standing in
   for it. Rows whose proof is a diff / report / chart / matrix are static but
   still specific: a code change owes a *diff view*, not a wall of raw source;
   a DB migration owes a *schema/ERD diff + dry-run output*, not prose.
3. **Shape §3.2 around the role_that_MUST_see_it.** That role is this page's
   buyer; `why_they_need_it` is the proof-chain caption written in their words,
   not the engineer's. When two rows name two genuinely different roles for the
   same artifact (Code Reviewer *and* Tech Lead; Designer *and* Product Owner),
   that is the §3.2 two-audience split — two re-framed tracks over the **same**
   evidence, not one averaged page.

Once you know *what* proof to build, `references/proof-build-eval-matrix.csv`
(absolute: `~/.agents/skills/talk-html/references/proof-build-eval-matrix.csv`)
carries the operational layer for the same `artifact_type` rows:
`visual_proof_to_build`, candidate `build_tools`, the
`programmatic_evaluation_tools` and the `deterministic_gate` that decide
pass/fail, and the `ci_output` artifact to embed or link. It is the bridge from
"I know the proof" to a *mechanically checkable* one:

- **build_tools are candidates, not a license to reinvent.** §3.1 still rules:
  if the project has its own entrypoint that produces this proof, run *that*
  verbatim; reach for a listed tool only when none exists. A `build_tool` here
  is a starting point for the §3.1.1 ② rebuild path, never permission to
  hand-roll build logic just so a visual exists.
- **deterministic_gate is the §3.1.3 / third-party-judge rule per artifact.**
  Run the `programmatic_evaluation_tools`, let them emit their own machine
  output (`junit.xml`, `coverage.html`, `sarif`, `lhci`, `ffprobe.json`, …),
  and read the gate from *that* — never from the page author's, the executing
  agent's, or the artifact's own say-so. The gate string is the objective
  pass/fail a third party can re-run; it sits *in front of* the §3.1.3
  `verify-evidence.sh` provenance gate, it does not replace it.
- **ci_output is what the page embeds or links**, carrying §3.0.1 provenance
  so a reader can re-derive the verdict — not a screenshot of a green check.

One carve-out: where `build_tools` lists Mermaid / PlantUML, that means
*render them to a static SVG/PNG at build time and embed the image* — never a
live Mermaid block (Quality bar #4: the page ships JS-free).

Both tables are a floor on *specificity*, not a substitute for any rule above
them. Neither relaxes §3.0.1 (a recording is still a real run on real data, not
a binary reciting `const` literals) or the §3.1.3 evidence gate (the moving
proof still needs checkable provenance). An `artifact_type` not in the tables is
not exempt — fall back to reasoning about whether it moves under §3.1. Their
whole value is catching the most common failure — right honesty, wrong proof,
wrong reader, unverifiable gate — *before* the page is built rather than after
a reviewer has already bounced.

For a single lookup, the two tables are also shipped pre-joined as
`references/proof-matrix-merged.csv` (absolute:
`~/.agents/skills/talk-html/references/proof-matrix-merged.csv`) — one row per
`artifact_type` × `role_that_MUST_see_it`, carrying the reviewer-view columns
*and* the build / eval / `deterministic_gate` / `ci_output` columns side by
side, so the whole obligation (who, what view, why, how to build it, how to
mechanically gate it, which CI artifact) reads without cross-referencing. It is
a deterministic join, not a hand-merge: the two component files stay the
normalized source of truth — a reviewer-intent table and a build/gate table —
and the merged view is regenerated from them by
`python3 ~/.agents/skills/talk-html/merge-proof-matrices.py` (a deterministic,
idempotent join). **Maintain the components, rerun the script, hand-edit the
merge never.** Where a build/gate type has no reviewer-intent row of its
own (e.g. `Web performance`), it still appears, with an empty
`why_they_need_it` — that blank is honest, not a gap to invent copy into. Use
whichever serves the moment: the merged file to act on one artifact, the
components to maintain the rules.

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
| User asks for eval / bad cases / Gate Rules "with playable videos" but the draft has only screenshots, posters, contact sheets, or static tables | Generate short clips from the real source MP4s, embed them as `data:video` or public HTTPS media, map each `#Gate Rule` to failed cases and related videos, add evidence provenance, and verify video metadata/frame playback before publish. If impossible, mark the video un-recorded / 不可播放 and explain the gap. |
| Core claim has no real evidence at all | §3.1.1 exit ④: this is a build defect, not a publish signal. Stop, state what is missing, report it. Do not ship a hollow or fabricated page to keep the flow moving. |

## Quality bar — do not violate

1. Real editorial design. One-sentence mood description must exist.
2. No emoji unless the user asked for emoji.
3. No fixed pixel heights that clip reflow.
4. Diagrams in SVG, not Mermaid (Mermaid blocks need JS; we ship JS-free except the audit-pill copy handler).
5. File < 200 KB unless content genuinely demands more. A real embedded recording (GIF/video data-URI) is a legitimate reason to exceed it — note the size in the page and offer to compress.
6. Every HTML can be traced back to its originating session via three independent paths: the audit pill (shows the human-readable `origin_prompt` name and offers a copy-to-clipboard `claude --resume <id>` command to re-enter the conversation), the `<!-- talk-html-meta -->` comment, **and** the index.jsonl row. The pill must never reduce to a bare session hash, and must not rely on a `file://` transcript link — that link is dead in the published gist.
7. Gist/htmlpreview parity: if the local preview has a visible GIF/image/evidence block or a clickable source/proof control, the rendered gist must expose the same material without broken `file://` or local relative links.
8. Non-static content is recorded, not drawn (§3.1), **and the run renders real data, not hardcoded literals (§3.0.1)**. Anything interactive, live/status, animated, or "this UI/demo/dashboard runs" — in the subject matter *or* the page itself — is backed by a real embedded video or GIF from a real-machine real-run capture, produced through the **project's own existing build code**, **with every number/status/series on screen tracing to a named source (a file read, a command, a fixture, a real metric) a reader can re-derive** — never reinvented build logic, never a static screenshot or mock standing in for motion, never a real binary reciting `const` placeholders. A page that is entirely static (essay, letter, past-decision recap) needs no recording; the moment something moves, it does. When the capture *or the data behind it* fails, the §3.1.1 decision tree governs the fallback (①收窄结论 → ②用现有 code path 补建 → ③诚实标注 gap → ④block 上报) — a drawn substitute, or a recorded fake, is never one of the exits.
9. Every page ships the “继续修改” bar from §5.1 — a text input plus a copy-prompt button — so a reader can turn a requested change into one terminal paste without hand-copying any URL. The copied prompt is self-contained: a `claude --resume <id>` handle **plus** the `slug` + `recall.sh` relocation path, never only a `file://` link, and it works the same in the published gist as locally. This bar and the audit pill are the only scripted elements on the page.
10. Convincing pages (proof / pitch / status / "show the boss / VC / customer") follow §3.2: inverted pyramid — one-sentence value claim + proof chain on the first screen; no secret / key / internal job-dir / host path / failed-take / compression-log in the visible artifact; real limitations preserved but collapsed into a final 「诚实边界 / Verification notes」 `<details>`; the embedded motion artifact is self-labeled (cover title + burned-in step labels, MP4-primary + poster) so it stands alone; copy in ≤3-line paragraphs, non-engineer-legible headings, zero hype adjectives; two real buyer types get two re-framed tracks over the same evidence, never a fabricated second audience. Pure static communication (essay / letter / recap) is exempt.
11. The evidence rule is **mechanical, not advisory** (§3.1.3). Before publish / before declaring the page done, `verify-evidence.sh` must pass: a page that embeds a motion artifact carries checkable provenance (inline `talk-html-evidence` record, a co-located `run-log.json`, or a *declared* `data-evidence="unrecorded"` gap), or it is provably static. `publish.sh` enforces the same gate as a fail-closed precondition. A failing gate is a §3.1.1 ④ block — never a reason to weaken the gate, and never a publish. This exists because a 36-clip human ground truth proved a pixel/motion proxy agrees with reality only ~half the time and never rejects fakes; provenance is the only signal that holds. Static pages (essay / letter / recap with no motion artifact) pass untouched.
12. Eval / bad-case / Gate Rule pages obey §3.1.4. If the user asks for videos, playable videos, or attached videos, the page includes real `<video controls>` elements for the relevant failed cases or rule groups. Screenshots, posters, contact sheets, and static tables are supporting material only; they do not satisfy the video request. The mapping from `#Gate Rule {index}` to failed cases and related videos is visible, provenance is checkable, and playability is verified before publish.
13. Pages whose subject is a concrete change or deliverable consult the §3.2.1 matrices. From `~/.agents/skills/talk-html/references/proof-matrix.csv`: the embedded proof matches the artifact's owed `visual_proof_type` rendered in its `recommended_view`, the page is structured for the `role_that_MUST_see_it` with `why_they_need_it` as the proof-chain caption, and GIF/MP4/recording rows are treated as non-static under §3.1/§3.1.4. From `~/.agents/skills/talk-html/references/proof-build-eval-matrix.csv`: the proof is built with the project's own entrypoint where one exists (`build_tools` are candidates, never a license to reinvent build logic — §3.1 / §3.1.1 ②), its `deterministic_gate` is decided by the listed `programmatic_evaluation_tools`' own machine output (not self-judged by author/agent/artifact — the §3.1.3 / third-party-judge rule per artifact), and the `ci_output` is embedded or linked with §3.0.1 provenance, not a screenshot of a green check. Both are a floor on *specificity*; neither relaxes §3.0.1 or the §3.1.3 evidence gate, and Mermaid/PlantUML `build_tools` mean render-to-static-SVG, never a live JS block (Quality bar #4). The same obligation is shipped pre-joined as `~/.agents/skills/talk-html/references/proof-matrix-merged.csv` (one row per artifact_type × reviewer, all ten columns) for a single lookup — it is a deterministic join of the two component files, so maintain the components and never hand-edit the merge. Pure static communication (essay / letter / recap) with no reported artifact is exempt.
