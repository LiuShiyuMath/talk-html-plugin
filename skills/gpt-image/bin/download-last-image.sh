#!/usr/bin/env bash
# download-last-image.sh — pull the most recent ChatGPT-generated image off the
# active browse tab and decode it to a local PNG.
#
# Why this exists: ChatGPT image URLs (chatgpt.com/backend-api/estuary/content
# ?...&sig=...) are single-use signed links — curl + cookies returns 404. The
# only reliable path is an in-page fetch (carries the live session), base64 it,
# stash in window, then pull it back in chunks because browse `js` stdout
# silently returns EMPTY when a returned string exceeds ~180k chars.
#
# Usage: download-last-image.sh <out.png> [tab_id]
#   <out.png>  destination path for the decoded PNG
#   [tab_id]   optional browse tab id to pin first (shared headed browsers
#              switch the active tab; pin it so we read the right page)
#
# Exit: 0 on a valid PNG written to <out.png>; non-zero otherwise.
set -u

OUT="${1:?usage: download-last-image.sh <out.png> [tab_id]}"
TAB="${2:-}"
B="${BROWSE_BIN:-$HOME/.claude/skills/gstack/browse/dist/browse}"
[ -x "$B" ] || { echo "browse binary not found: $B" >&2; exit 3; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/gptimg.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
B64="$TMP/img_b64.txt"

pin() { [ -n "$TAB" ] && timeout 15 "$B" tab "$TAB" >/dev/null 2>&1 || true; }

# 1) In-page fetch the generated image -> base64, stash in window.__gptimg_b64.
#    Prefer the estuary content image; fall back to the last generated <img>.
#    NOTE: browse `js` returns EMPTY for a slow fetch promise even though the
#    window side-effect still completes — so we FIRE the stash (ignore its
#    return) and POLL window state instead of trusting the return value.
pin
"$B" js 'window.__gptimg_b64=undefined; window.__gptimg_err=undefined; (async()=>{
  try{
    let el=document.querySelector("img[src*=\"estuary/content\"]");
    if(!el){const xs=[...document.querySelectorAll("img")].filter(i=>/oaiusercontent|estuary|files\.oai|sdmnt/i.test(i.src)); el=xs[xs.length-1];}
    if(!el){window.__gptimg_err="no-image"; return;}
    const r=await fetch(el.src); if(!r.ok){window.__gptimg_err="fetch-"+r.status; return;}
    const a=new Uint8Array(await (await r.blob()).arrayBuffer());
    let s=""; for(let i=0;i<a.length;i+=8192) s+=String.fromCharCode.apply(null,a.subarray(i,i+8192));
    window.__gptimg_b64=btoa(s);
  }catch(e){window.__gptimg_err=String(e);}
})()' >/dev/null 2>&1

# Poll for the stash to land (or an error flag).
LEN=0
for _ in $(seq 1 30); do
  sleep 1
  pin
  state=$(timeout 15 "$B" js 'window.__gptimg_err ? "ERR|"+window.__gptimg_err : (typeof window.__gptimg_b64==="string" ? "OK|"+window.__gptimg_b64.length : "WAIT")' 2>/dev/null | tr -d '\r\n')
  case "$state" in
    OK\|*) LEN="${state#OK|}"; break;;
    ERR\|*) echo "stash failed: ${state#ERR|}" >&2; exit 4;;
  esac
done
[ "$LEN" -gt 0 ] 2>/dev/null || { echo "stash timed out (no image fetched)" >&2; exit 4; }

# 2) Pull back in <=180k-char chunks (the browse js output cap is ~180-200k;
#    larger returns come back empty). Foreground, one $B call per chunk.
: > "$B64"
CH=180000
i=0
while [ "$i" -lt "$LEN" ]; do
  pin
  got=$(timeout 20 "$B" js "window.__gptimg_b64.slice($i,$((i+CH)))" 2>/dev/null | tr -d '\r\n')
  if [ -z "$got" ]; then echo "empty chunk at offset $i" >&2; exit 5; fi
  printf '%s' "$got" >> "$B64"
  i=$((i+CH))
done

got_len=$(wc -c < "$B64" | tr -d ' ')
if [ "$got_len" != "$LEN" ]; then
  echo "length mismatch: got $got_len want $LEN" >&2; exit 5
fi

# 3) Decode and verify it is a real PNG/JPEG. Read base64 from STDIN — macOS
#    `base64` rejects a positional filename (wants -i/stdin), GNU accepts both;
#    stdin is the portable form. Fall back to python3 if base64 is uncooperative.
base64 -d < "$B64" > "$OUT" 2>/dev/null \
  || base64 -D < "$B64" > "$OUT" 2>/dev/null \
  || python3 -c 'import base64,sys; open(sys.argv[1],"wb").write(base64.b64decode(open(sys.argv[2]).read()))' "$OUT" "$B64" 2>/dev/null
[ -s "$OUT" ] || { echo "decode produced empty file" >&2; exit 6; }
hdr=$(head -c 8 "$OUT" | xxd -p 2>/dev/null | head -c 16)
case "$hdr" in
  89504e470d0a1a0a*) kind="PNG";;
  ffd8ff*)           kind="JPEG";;
  *) echo "decoded file is not PNG/JPEG (header $hdr)" >&2; exit 6;;
esac
bytes=$(wc -c < "$OUT" | tr -d ' ')
echo "OK $kind $bytes bytes -> $OUT"
