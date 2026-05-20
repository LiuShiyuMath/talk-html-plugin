#!/usr/bin/env bash
# record-to-gif.sh — talk-html visual-artifact recorder.
#
# Turns a REAL local web run into an optimized, self-contained GIF (+ base64
# data-URI + poster frame + run-log) that the talk-html page embeds as proof.
# This is a real-machine, real-run recorder: it builds with the project's OWN
# code, serves the actual output, and drives a real Chromium over it.
#
# CORE RULE — use existing build code, never reinvent it:
#   --build-cmd MUST be the project's existing build entrypoint
#   (e.g. `bash landing/build-static.sh`, `pnpm build`, `make site`,
#   `next build && next export`). This script NEVER contains build logic of
#   its own. If a project has no build step (already-static dir), omit
#   --build-cmd and just point --serve-dir at the real artifact directory.
#
# Usage:
#   record-to-gif.sh \
#     --serve-dir <dir>            # directory of the real built artifact to serve (required)
#     --routes '<json array>'      # e.g. '["/","/org","/agents"]' (required)
#     [--build-cmd '<cmd>']        # the project's OWN build command, run verbatim first
#     [--build-cwd <dir>]          # cwd for --build-cmd (default: current dir)
#     [--out <dir>]                # artifact output dir (default: $TMPDIR/talk-html-rec-<ts>)
#     [--speed <float>]            # GIF speed-up factor (default 1.6)
#     [--fps <int>]                # GIF fps (default 10)
#     [--width <int>]              # GIF width px (default 820)
#     [--viewport <WxH>]           # browser viewport (default 1180x760)
#     [--port <int>]               # serve port (default: first free in 4178..4250)
#     [--spa]                      # serve in SPA single mode (rewrite every route
#                                  #   to index.html). OFF by default — a static-site
#                                  #   export (Next.js export, etc.) is multi-page:
#                                  #   single mode would serve the homepage for
#                                  #   EVERY route. Only pass --spa for a true
#                                  #   client-routed single-page app.
#
# Prints (KEY=VALUE lines) on success:
#   GIF=<path>  GIF_B64=<path>  POSTER=<path>  POSTER_B64=<path>
#   WEBM=<path> RUNLOG=<path>   GIF_BYTES=<n>  WEBM_BYTES=<n>
#
# Requires: node, npx, ffmpeg. Bootstraps playwright + chromium on first run
# into ~/.agents/talk-html/.recorder/ (idempotent).
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORDER_HOME="${HOME}/.agents/talk-html/.recorder"

SERVE_DIR=""; ROUTES=""; BUILD_CMD=""; BUILD_CWD="$PWD"
OUT=""; SPEED="1.6"; FPS="10"; WIDTH="820"; VIEWPORT="1180x760"; PORT=""; SPA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --serve-dir) SERVE_DIR="$2"; shift 2;;
    --routes)    ROUTES="$2"; shift 2;;
    --build-cmd) BUILD_CMD="$2"; shift 2;;
    --build-cwd) BUILD_CWD="$2"; shift 2;;
    --out)       OUT="$2"; shift 2;;
    --speed)     SPEED="$2"; shift 2;;
    --fps)       FPS="$2"; shift 2;;
    --width)     WIDTH="$2"; shift 2;;
    --viewport)  VIEWPORT="$2"; shift 2;;
    --port)      PORT="$2"; shift 2;;
    --spa)       SPA=1; shift;;
    *) echo "record-to-gif: unknown arg $1" >&2; exit 2;;
  esac
done
[[ -n "$ROUTES" ]] || { echo "record-to-gif: --routes required" >&2; exit 2; }
command -v node >/dev/null || { echo "record-to-gif: node not found" >&2; exit 3; }
command -v ffmpeg >/dev/null || { echo "record-to-gif: ffmpeg not found (brew install ffmpeg)" >&2; exit 3; }

TS="$(date -u +%Y%m%d-%H%M%S)"
OUT="${OUT:-${TMPDIR:-/tmp}/talk-html-rec-${TS}}"
mkdir -p "$OUT"
VW="${VIEWPORT%x*}"; VH="${VIEWPORT#*x}"

# --- 1. Build with the project's OWN code (if a build step was given) --------
if [[ -n "$BUILD_CMD" ]]; then
  echo "[record] build (existing project code): $BUILD_CMD" >&2
  ( cd "$BUILD_CWD" && eval "$BUILD_CMD" ) >"$OUT/build.log" 2>&1 \
    || { echo "[record] build FAILED — see $OUT/build.log" >&2; tail -20 "$OUT/build.log" >&2; exit 4; }
  echo "[record] build OK" >&2
fi
[[ -d "$SERVE_DIR" ]] || { echo "record-to-gif: --serve-dir '$SERVE_DIR' missing (build did not produce it?)" >&2; exit 4; }

# --- 2. Bootstrap the recorder env (playwright + chromium), idempotent ------
if [[ ! -d "$RECORDER_HOME/node_modules/playwright" ]]; then
  echo "[record] bootstrapping playwright into $RECORDER_HOME" >&2
  mkdir -p "$RECORDER_HOME"
  if ! ( cd "$RECORDER_HOME" && npm install playwright >"$OUT/npm-bootstrap.log" 2>&1 ); then
    echo "[record] playwright bootstrap FAILED — see $OUT/npm-bootstrap.log" >&2
    tail -15 "$OUT/npm-bootstrap.log" >&2
    exit 7
  fi
fi
( cd "$RECORDER_HOME" && npx --no-install playwright install chromium >"$OUT/pw-browser.log" 2>&1 ) || \
  echo "[record] warning: chromium install step non-zero (may already be present) — see $OUT/pw-browser.log" >&2

# --- 3. Serve the real artifact dir on a free local port -------------------
if [[ -z "$PORT" ]]; then
  for p in $(seq 4178 4250); do
    if ! (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then PORT="$p"; break; fi
    exec 3>&- 3<&- 2>/dev/null || true
  done
fi
[[ -n "$PORT" ]] || { echo "record-to-gif: no free port in 4178..4250" >&2; exit 5; }

# proxy env routes localhost through a proxy on some machines — bypass it for
# every child here (serve, curl, node/chromium). Unsetting alone is not enough
# on macOS (curl can still pick proxy up); curl also gets explicit --noproxy.
export NO_PROXY='*' no_proxy='*'
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY 2>/dev/null || true

SERVE_LOG="$OUT/serve.log"
# bind explicitly to IPv4 127.0.0.1 so the health check + chromium reach it.
# NO -s/--single by default: a static-site export is multi-page, so single
# mode would rewrite every route to index.html and the recording would show
# the homepage for all routes. Pass --spa only for a true single-page app.
SERVE_SINGLE=""
[[ -n "$SPA" ]] && SERVE_SINGLE="-s"
( cd "$SERVE_DIR" && npx --yes serve -l "tcp://127.0.0.1:${PORT}" $SERVE_SINGLE . ) >"$SERVE_LOG" 2>&1 &
SERVE_PID=$!
cleanup() { kill "$SERVE_PID" 2>/dev/null || true; }
trap cleanup EXIT

BASE="http://127.0.0.1:${PORT}"
UP=0
for i in $(seq 1 60); do
  if curl -s --noproxy '*' -o /dev/null "$BASE/"; then UP=1; break; fi
  sleep 0.5
done
[[ "$UP" == 1 ]] || { echo "record-to-gif: server never came up on $BASE (30s)" >&2; cat "$SERVE_LOG" >&2; exit 5; }
echo "[record] serving $SERVE_DIR at $BASE" >&2

# --- 4. Drive Chromium across the routes, record video ----------------------
# Run the driver FROM the recorder home so Node's ESM resolver finds the
# sibling node_modules/playwright (NODE_PATH does not apply to ESM imports).
export BASE_URL="$BASE" ROUTES="$ROUTES" OUT_DIR="$OUT/video" VIEWPORT_W="$VW" VIEWPORT_H="$VH"
cp "$SKILL_DIR/record-playwright.mjs" "$RECORDER_HOME/record-playwright.mjs"
node "$RECORDER_HOME/record-playwright.mjs" >&2
WEBM="$(find "$OUT/video" -name '*.webm' | head -1)"
[[ -n "$WEBM" ]] || { echo "record-to-gif: no .webm produced" >&2; exit 6; }

# --- 5. webm -> optimized GIF (palettegen/paletteuse) + poster + base64 -----
PAL="$OUT/palette.png"
GIF="$OUT/recording.gif"
POSTER="$OUT/poster.jpg"
VF="setpts=PTS/${SPEED},fps=${FPS},scale=${WIDTH}:-1:flags=lanczos"
ffmpeg -y -i "$WEBM" -vf "${VF},palettegen=stats_mode=diff" "$PAL" 2>/dev/null
ffmpeg -y -i "$WEBM" -i "$PAL" -lavfi "${VF}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" "$GIF" 2>/dev/null
ffmpeg -y -i "$WEBM" -vf "scale=${WIDTH}:-1" -frames:v 1 "$POSTER" 2>/dev/null
base64 -i "$GIF"    | tr -d '\n' > "$GIF.b64"
base64 -i "$POSTER" | tr -d '\n' > "$POSTER.b64"

GIF_BYTES=$(wc -c < "$GIF" | tr -d ' ')
WEBM_BYTES=$(wc -c < "$WEBM" | tr -d ' ')
echo "[record] GIF ${GIF} (${GIF_BYTES} bytes)" >&2

# --- 6. Emit machine-readable result lines on stdout ------------------------
echo "GIF=$GIF"
echo "GIF_B64=$GIF.b64"
echo "POSTER=$POSTER"
echo "POSTER_B64=$POSTER.b64"
echo "WEBM=$WEBM"
echo "RUNLOG=$OUT/video/run-log.json"
echo "GIF_BYTES=$GIF_BYTES"
echo "WEBM_BYTES=$WEBM_BYTES"
echo "BASE_URL=$BASE"
