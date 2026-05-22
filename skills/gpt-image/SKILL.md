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

Plus one model rule, just as load-bearing: **always switch to the advanced
"Thinking" model before sending** (Step 1.5). The default Instant model does
not reliably browse the link — it hallucinates from the URL — so the link-only
contract only works on the model that actually reads the page.

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

So **before** sending the prompt, switch the model to advanced + thinking:

```bash
"$B" tab <id>
# Open the model switcher (top of a fresh chat). Primary: stable testid.
"$B" js 'var b=document.querySelector("[data-testid=\"model-switcher-dropdown-button\"]")||[...document.querySelectorAll("button")].find(x=>/gpt|model|instant|thinking|auto/i.test((x.getAttribute("aria-label")||"")+x.textContent)); if(b){b.click();"opened:"+b.textContent.trim().slice(0,40)}else"NO-SWITCHER"'
sleep 1
# Pick the advanced / Thinking entry from the menu (match several labels/locales).
"$B" js 'var m=[...document.querySelectorAll("[role=menuitem],[role=option],button,a")].find(x=>/thinking|advanced|思考|高级|GPT-5\s*(Thinking|Pro)/i.test(x.textContent)); if(m){m.click();"picked:"+m.textContent.trim().slice(0,40)}else"NO-THINKING-ITEM"'
sleep 1
# Verify the header now reflects an advanced/thinking model (not Instant).
"$B" js 'var h=document.querySelector("[data-testid=\"model-switcher-dropdown-button\"]"); h?h.textContent.trim():"?"'
```

If the switcher cannot be found or the account has no access to the advanced
model (e.g. a free tier showing an upgrade/pay prompt), **do not silently fall
back to Instant** — that reintroduces the hallucination. Stop and tell the user
to **manually flip the model to the advanced "Thinking" mode** in the shared
browser, then continue. Selectors drift; if the JS above returns
`NO-SWITCHER` / `NO-THINKING-ITEM`, snapshot the top bar
(`"$B" snapshot -i | head -30`) to find the current control before retrying.

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
