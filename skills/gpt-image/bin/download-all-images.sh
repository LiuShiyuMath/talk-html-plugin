#!/usr/bin/env bash
# download-all-images.sh — pull EVERY ChatGPT-generated image off the active
# browse tab and decode each to a local PNG.
#
# Why a separate helper from download-last-image.sh: a single prompt like
# "帮我生成一组配图" makes ChatGPT emit a SET of images. The old helper used
# `querySelector` (FIRST match only), so it could only ever return one image —
# and in a reused chat it returned a stale one. This skill now always works in
# a FRESH chat (see SKILL.md), so every `estuary/content` <img> on the page is
# part of the set we just generated. We pull all of them, in DOM order.
#
# Same single-use-signed-link workaround as the single-image helper: the URLs
# (chatgpt.com/backend-api/estuary/content?...&sig=...) are one-shot, so curl +
# cookies 404s. We fetch IN-PAGE (carries the live session), base64 it, stash in
# window, then pull back in <=180k-char chunks (browse `js` stdout silently
# returns EMPTY above ~180-200k chars).
#
# Usage: download-all-images.sh <out_dir> [tab_id] [basename]
#   <out_dir>   directory to write decoded PNGs into (created if missing)
#   [tab_id]    browse tab id to pin first (shared headed browsers switch the
#               active tab; pin it so we read the right page)
#   [basename]  filename stem; default "img" -> img-1.png, img-2.png, ...
#
# Exit: 0 if >=1 valid PNG was written; non-zero otherwise. Prints one
#       "OK <KIND> <bytes> -> <path>" line per image, then "TOTAL <n>".
set -u

OUT_DIR="${1:?usage: download-all-images.sh <out_dir> [tab_id] [basename]}"
TAB="${2:-}"
STEM="${3:-img}"
B="${BROWSE_BIN:-$HOME/.claude/skills/gstack/browse/dist/browse}"
[ -x "$B" ] || { echo "browse binary not found: $B" >&2; exit 3; }
mkdir -p "$OUT_DIR"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/gptimgall.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pin() { [ -n "$TAB" ] && timeout 15 "$B" tab "$TAB" >/dev/null 2>&1 || true; }

# How many generated images are on the page right now?
pin
COUNT=$(timeout 15 "$B" js 'document.querySelectorAll("img[src*=\"estuary/content\"]").length' 2>/dev/null | tr -dc '0-9')
[ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] 2>/dev/null || { echo "no generated images found on page" >&2; exit 4; }
echo "found $COUNT image(s)" >&2

written=0
idx=0
while [ "$idx" -lt "$COUNT" ]; do
  OUT="$OUT_DIR/${STEM}-$((idx+1)).png"
  B64="$TMP/img_$idx.b64"; : > "$B64"

  # 1) Stash the idx-th estuary image as base64 in window.__giAll.
  #    Fire-and-poll: a slow fetch promise returns EMPTY from `js` even though
  #    the window side-effect completes, so we never trust the call's return.
  pin
  timeout 20 "$B" js "window.__giAll=undefined; window.__giErr=undefined; (async()=>{
    try{
      const xs=[...document.querySelectorAll('img[src*=\"estuary/content\"]')];
      const el=xs[$idx];
      if(!el){window.__giErr='no-image-at-$idx'; return;}
      const r=await fetch(el.src); if(!r.ok){window.__giErr='fetch-'+r.status; return;}
      const a=new Uint8Array(await (await r.blob()).arrayBuffer());
      let s=''; for(let i=0;i<a.length;i+=8192) s+=String.fromCharCode.apply(null,a.subarray(i,i+8192));
      window.__giAll=btoa(s);
    }catch(e){window.__giErr=String(e);}
  })()" >/dev/null 2>&1

  LEN=0
  for _ in $(seq 1 30); do
    sleep 1
    pin
    state=$(timeout 15 "$B" js 'window.__giErr ? "ERR|"+window.__giErr : (typeof window.__giAll==="string" ? "OK|"+window.__giAll.length : "WAIT")' 2>/dev/null | tr -d '\r\n')
    case "$state" in
      OK\|*) LEN="${state#OK|}"; break;;
      ERR\|*) echo "image $((idx+1)): stash failed: ${state#ERR|}" >&2; LEN=0; break;;
    esac
  done
  if ! [ "$LEN" -gt 0 ] 2>/dev/null; then
    echo "image $((idx+1)): no data (skipped)" >&2; idx=$((idx+1)); continue
  fi

  # 2) Pull back in <=180k-char chunks, foreground, one $B call per chunk.
  CH=180000; i=0; ok=1
  while [ "$i" -lt "$LEN" ]; do
    pin
    got=$(timeout 20 "$B" js "window.__giAll.slice($i,$((i+CH)))" 2>/dev/null | tr -d '\r\n')
    if [ -z "$got" ]; then echo "image $((idx+1)): empty chunk at $i (skipped)" >&2; ok=0; break; fi
    printf '%s' "$got" >> "$B64"
    i=$((i+CH))
  done
  [ "$ok" = 1 ] || { idx=$((idx+1)); continue; }

  got_len=$(wc -c < "$B64" | tr -d ' ')
  [ "$got_len" = "$LEN" ] || { echo "image $((idx+1)): length mismatch $got_len/$LEN (skipped)" >&2; idx=$((idx+1)); continue; }

  # 3) Decode + verify it is a real PNG/JPEG.
  base64 -d < "$B64" > "$OUT" 2>/dev/null \
    || base64 -D < "$B64" > "$OUT" 2>/dev/null \
    || python3 -c 'import base64,sys; open(sys.argv[1],"wb").write(base64.b64decode(open(sys.argv[2]).read()))' "$OUT" "$B64" 2>/dev/null
  if [ ! -s "$OUT" ]; then echo "image $((idx+1)): decode empty (skipped)" >&2; idx=$((idx+1)); continue; fi
  hdr=$(head -c 8 "$OUT" | xxd -p 2>/dev/null | head -c 16)
  case "$hdr" in
    89504e470d0a1a0a*) kind="PNG";;
    ffd8ff*)           kind="JPEG";;
    *) echo "image $((idx+1)): not PNG/JPEG (header $hdr, skipped)" >&2; rm -f "$OUT"; idx=$((idx+1)); continue;;
  esac
  bytes=$(wc -c < "$OUT" | tr -d ' ')
  echo "OK $kind $bytes bytes -> $OUT"
  written=$((written+1))
  idx=$((idx+1))
done

echo "TOTAL $written"
[ "$written" -gt 0 ]
