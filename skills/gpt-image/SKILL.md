---
name: gpt-image
description: Generate a SET of images (配图) for a talk-html page by driving the already-logged-in ChatGPT web app through the gstack /browse daemon, then download every generated image to disk. Use whenever the user wants to 配图 / illustrate / add images / generate a set of images for an HTML one-pager, says "/gpt-image", "给这页配图", "生成一组配图", "add images to this page", or "draw images for X". The contract is deliberately simple: open a FRESH ChatGPT chat, send ONE short sentence carrying ONLY the page's public talk-html link, let ChatGPT read the page and decide the images, then pull them all back. No OpenAI API key — reuses the human's live web session.
---

# /gpt-image — 配图: a set of images for a talk-html page

Drive the **already-logged-in** ChatGPT web app (`chatgpt.com`) through the
gstack **/browse** daemon, ask it to illustrate a published talk-html page, then
pull **every** generated image to disk. No OpenAI API key — it reuses the
human's live web session.

## The contract (read this first — it is the whole point)

Four rules, each there because the alternative already failed in practice:

1. **Always a FRESH chat.** Start a brand-new conversation before generating.
   A reused chat carries unrelated context and, worse, leaves *old* generated
   images on the page — and "download all images" then can't tell new from old.
   A fresh chat means **every** `estuary/content` image on the page is part of
   the set we just asked for, which makes the download step trivial and correct.
2. **Always via /browse.** Visit and drive `chatgpt.com` through the gstack
   browse daemon (the `browse` binary below). Never curl the page or the image
   URLs directly — image links are single-use signed URLs (see §Download).
3. **One short sentence, only a link — never a hand-written art prompt.** The
   prompt is literally `帮我生成一组配图：<rendered talk-html URL>`. Do **not**
   describe the scene, the palette, the style, the composition. The page itself
   already carries all of that (its topic, its colors, its mood); ChatGPT reads
   the link and decides. Long bespoke prompts were the old failure mode — they
   fight the page instead of trusting it, and they drift off-topic.
4. **Download them all.** A "组" (a set) means several images. Pull every one,
   in order, with the bundled `download-all-images.sh`.

Plus one model rule, just as load-bearing: **switch to the advanced "Thinking"
model (Step 1.5) and then prove it took (Step 1.6) before sending.** The default
Instant model does not reliably browse the link — it hallucinates from the URL —
so the link-only contract only works on the model that actually reads the page.
The switch can silently no-op, so the run is gated on reading the model label
back: confirmed Thinking/advanced → proceed; Instant or unconfirmed → stop.

If the user hands you a local file path instead of a public link, publish it
first (talk-html's `publish.sh` returns a `rendered:` URL) and pass *that* — a
`file://` path is invisible to ChatGPT.

## Setup (every run)

```bash
B="${BROWSE_BIN:-$HOME/.claude/skills/gstack/browse/dist/browse}"
"$B" status            # must be "healthy"; if not, start the daemon (/browse) first
"$B" tabs              # note any existing chatgpt.com tab id
```

The browser is usually **headed and shared** with the user, so other tabs steal
focus. Always `"$B" tab <id>` to pin the ChatGPT tab before each read/write.

## Step 1 — Open a FRESH ChatGPT chat

Navigate straight to the new-chat URL (most reliable way to guarantee a clean
conversation, no leftover images):

```bash
"$B" tab <id>                       # or open a tab if none exists
"$B" goto "https://chatgpt.com/?model=auto"
"$B" wait --load
"$B" text | head -3                 # logged-in shows the composer, not a login wall
```

If it shows a login/signup wall, STOP and tell the user to log into ChatGPT in
that browser first — this skill never handles credentials.

Confirm the page starts with **zero** generated images (proves it's a clean
chat, so the later "download all" only ever sees this run's output):

```bash
"$B" js 'document.querySelectorAll("img[src*=\"estuary/content\"]").length'   # expect 0
```

## Step 1.5 — Switch the model to ADVANCED + THINKING (not Instant)

This step is load-bearing and was added because skipping it produces garbage.
The default model is the **fast "Instant"** one; on a browse/illustrate task it
often does **not** actually fetch the link — it guesses the topic from the URL
string and hallucinates an off-topic image. (Real failure: a page published as
`read-version.html` produced an infographic about distributed-systems "read
versions", because Instant never read the page.) The **advanced "Thinking"**
model actually browses the page before drawing, which is the whole point of
passing a link.

**Where the control actually is (verified on a live zh-CN account, 2026-05):**
there is no top-left "model-switcher-dropdown-button" on this UI. The mode
picker is a button **inside the composer**, collapsed-labelled **`进阶`**
(= "Advanced"). Clicking it opens a small menu with exactly two
`[role=menuitemradio]` entries — **`Instant`** and **`Thinking • 进阶`** — and
the active one carries `aria-checked="true"` (or `[checked]`). The collapsed
button only ever says `进阶`, so do **not** gate on the collapsed text — gate on
which **radio is checked** (that is Step 1.6).

So **before** sending the prompt, open that menu and select Thinking:

```bash
"$B" tab <id>
# 1) Open the composer mode dropdown. It is the button labelled exactly "进阶"
#    (Advanced); also match Instant/Thinking in case the label localizes.
"$B" snapshot -i | grep -iE '\[button\] "(进阶|Instant|Thinking)' | head   # find its @eNN ref
"$B" click @eNN          # click that ref (more reliable than JS .click() on a wrapper)
sleep 1
# 2) Pick the Thinking radio (covers "Thinking • 进阶" and locale variants).
"$B" js 'var m=[...document.querySelectorAll("[role=menuitemradio],[role=menuitem],[role=option]")].find(x=>/thinking|思考|advanced|高级/i.test(x.textContent)); if(m){m.click();"picked:"+m.textContent.trim().slice(0,40)}else"NO-THINKING-ITEM"'
sleep 1
```

If the dropdown cannot be found, or the menu offers no Thinking entry (e.g. a
free tier with only Instant, or an upgrade/pay prompt), **do not silently fall
back to Instant** — that reintroduces the hallucination. Stop and tell the user
to **manually flip the composer mode to "Thinking • 进阶"** in the shared
browser, then continue. Selectors drift; if the grep finds no ref or the JS
returns `NO-THINKING-ITEM`, snapshot the composer
(`"$B" snapshot -i | grep -iE 'textbox|进阶|button'`) to relocate the control.

## Step 1.6 — Double-check the model (fail-closed gate, run every time)

Step 1.5 *attempts* the switch; this step *proves* it took. They are different
jobs: a click can silently no-op (menu didn't open, label localized
differently, account downgraded mid-session), and the failure is invisible —
you only find out when the image comes back off-topic. So before sending the
prompt, **read which mode radio is checked and gate on it**. Do not parse the
collapsed `进阶` button text — it says `进阶` whether Instant or Thinking is
active, so it cannot tell them apart. The truth signal is the **checked
`menuitemradio`** inside the open menu. This is the load-bearing check the user
asked for: positively confirm the **checked** mode is Thinking and **not**
Instant. Anything else stops the run — never "probably fine".

```bash
"$B" tab <id>
# Re-open the composer mode dropdown (same "进阶"/Instant/Thinking button as Step 1.5).
"$B" snapshot -i | grep -iE '\[button\] "(进阶|Instant|Thinking)' | head
"$B" click @eNN
sleep 1
# Read the CHECKED radio's label — this is the active model, unambiguously.
CHECKED="$("$B" js '[...document.querySelectorAll("[role=menuitemradio]")].filter(r=>r.getAttribute("aria-checked")==="true"||r.hasAttribute("checked")).map(r=>r.textContent.trim()).join("|")||"NO-CHECKED"' 2>/dev/null | tr -d '\r\n')"
"$B" press Escape   # close the menu before sending
echo "checked mode radio: [$CHECKED]"
# Fail-closed verdict: the checked radio must be Thinking AND must NOT be Instant.
printf '%s' "$CHECKED" | grep -Eqi 'thinking|思考|advanced|高级' \
  && ! printf '%s' "$CHECKED" | grep -Eqi 'instant|即时|fast' \
  && [ "$CHECKED" != "NO-CHECKED" ] \
  && echo "GATE: PASS — checked mode is Thinking, proceeding" \
  || echo "GATE: FAIL — checked mode is Instant or unconfirmed; STOP, do not send the prompt"
```

Read the verdict, do not assume it:

- **`GATE: PASS`** — the checked radio affirmatively reads Thinking (e.g.
  `Thinking • 进阶`) with no Instant marker. Only now continue to Step 2.
- **`GATE: FAIL`** (checked radio is `Instant`/`即时`, `NO-CHECKED`, or anything
  you can't positively read as Thinking) — **do not send the prompt.** Re-run
  the Step 1.5 switch once; if it still fails, stop and tell the user to
  **manually set the composer mode to "Thinking • 进阶"** in the shared browser,
  then resume. Sending on an unconfirmed model is the exact failure this skill
  exists to prevent — an Instant run that looks fine and ships an off-topic
  image (verified: an Instant run hallucinated a "并发寄存器" infographic from a
  filename; the same page on Thinking produced a correct, on-topic illustration).

Why fail-closed (refuse on doubt) rather than fail-open (proceed and hope): a
false "looks ok" here is silent and expensive — it costs a full generate +
download + embed cycle before anyone notices the image is wrong. A hard stop is
cheap and obvious. When the label is ambiguous, treat it as FAIL.

## Step 2 — Send the one-sentence prompt

Re-snapshot for a fresh textbox ref each turn (refs change after every submit):

```bash
"$B" tab <id>
TB=$("$B" snapshot -i | grep -i '\[textbox\]' | head -1 | grep -o '@e[0-9]*')
"$B" fill "$TB" "帮我生成一组配图：<rendered talk-html URL>"
"$B" press Enter
```

That's the entire prompt. No style words, no scene description — just the link.
ChatGPT will browse the page and produce a set of images that match it.

## Step 3 — Wait for the set to finish

Image generation runs ~30–90s **per image**, and a set generates them in
sequence, so be patient. Poll the count until it stops rising AND the status
text has settled (no 「正在生成 / Creating image」):

```bash
"$B" tab <id>
"$B" js 'document.querySelectorAll("img[src*=\"estuary/content\"]").length'
"$B" text | tail -3      # settled when it shows "Thought for…/已思考", not "正在生成"
```

Re-check every ~12s. Treat the count as final only after it is unchanged across
two checks **and** the status text is no longer "generating". A common shape is
the assistant emitting 3–5 images one after another; don't download mid-stream.

## Step 4 — Download every image

Because this is a fresh chat, all `estuary/content` images are this run's set.
The bundled helper fetches each **in-page** (the only way that works — the URLs
are single-use signed links that 404 under `curl`), base64-encodes it, stashes
it on `window`, pulls it back in ≤180k-char chunks (the browse `js` stdout cap),
decodes, and verifies each is a real PNG/JPEG:

```bash
~/.claude/skills/gpt-image/bin/download-all-images.sh "<out_dir>" <tab-id> [basename]
# prints one "OK PNG <bytes> -> <out_dir>/<basename>-N.png" per image, then "TOTAL <n>"
```

Default `<out_dir>` to `$CLAUDE_JOB_DIR/imgs` (or the directory the user named).
`basename` defaults to `img` → `img-1.png`, `img-2.png`, …

For a **single** image (rare — only if the user explicitly wants one), the older
`download-last-image.sh "<out.png>" <tab-id>` still works, but note it grabs the
*first* DOM match; prefer `download-all-images.sh` and take `img-1.png`.

## Step 5 — Verify + report (and embed if asked)

```bash
file "<out_dir>"/*.png      # e.g. "PNG image data, 1672 x 941"
```

Read each saved file back (Read tool) to confirm it visually matches the page's
topic. Report the paths, dimensions, and byte sizes. If the user wants the
images shown in the page, embed downscaled copies (e.g. base64 `data:` URIs so
they survive a gist) and re-publish via talk-html's `publish.sh`.

## Args

| Arg | Meaning |
|-----|---------|
| `<rendered talk-html URL>` | The public page link to illustrate. Always a real HTTPS URL, never `file://`. |
| `--ask <question>` | Plain text Q&A mode — fill the question verbatim, press Enter, return ChatGPT's settled text reply, no image. |
| `<out_dir>` | Where to save the set. Default `$CLAUDE_JOB_DIR/imgs`. |

## Failure modes

| Symptom | Cause / fix |
|---------|-------------|
| `"$B" status` not healthy | Daemon down — start it via /browse / open-gstack-browser before retrying. |
| `text` shows a login wall | Not logged in — ask the user to sign into ChatGPT in that browser. |
| count stays 0 after submit | Prompt didn't trigger image gen — confirm the link is reachable and re-send `帮我生成一组配图：<url>`; do NOT add a long art prompt to force it. |
| image is off-topic / hallucinated from the URL or filename, not the page | You're on the **Instant** model — it didn't actually fetch the link. Do Step 1.5: switch to advanced + Thinking, start a fresh chat, re-send. Also avoid generic read-file names like `read-version.html` (Instant latches onto the words). |
| downloaded an old/stale image | You reused a chat. Start a FRESH chat (Step 1) so the page has only this run's images. |
| `download-all-images.sh` finds 0 | Generation not finished, or you're on the wrong tab — re-poll Step 3 and pass the correct ChatGPT `<tab-id>`. |
| `empty chunk` / `length mismatch` for one image | Tab navigated mid-pull and cleared the stash; that image is skipped, others still land — re-run the helper to retry the misses. |
| `curl` of an image URL 404s | Expected — signed links are single-use. Never curl them; the helper fetches in-page. |

## Limits

- Reuses a live human ChatGPT session; subject to that account's rate/usage
  limits and OpenAI terms. Generated content quality/rights are OpenAI's.
- ChatGPT decides how many images to emit for "一组" — you don't control the
  exact count, by design (the page drives the brief, not a hand-tuned prompt).
- The browse `js` output cap (~180k chars/call) is why download is chunked; if a
  future browse version raises it, the helper still works (just fewer chunks).
