#!/usr/bin/env bash
# install.sh — install the talk-html Claude Code skill into ~/.claude/skills/talk-html/
#
#   curl -fsSL https://raw.githubusercontent.com/LiuShiyuMath/talk-html-skill/main/install.sh | bash
#
# Idempotent: if the skill already exists it is backed up, not clobbered.

set -euo pipefail

REPO="https://github.com/LiuShiyuMath/talk-html-skill"
DEST="$HOME/.claude/skills/talk-html"
ARTIFACT_DIR="$HOME/.claude/talk-html"

echo "→ installing talk-html skill from $REPO"

command -v git >/dev/null 2>&1 || {
  echo "✗ git is required but not installed." >&2
  exit 1
}

if [[ -d "$DEST" ]]; then
  BACKUP="${DEST}.bak.$(date +%Y%m%d-%H%M%S)"
  echo "  note: $DEST already exists — moving it to $BACKUP"
  mv "$DEST" "$BACKUP"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 "$REPO" "$TMP/repo" >/dev/null 2>&1 || {
  echo "✗ git clone failed. check your network, or clone manually:" >&2
  echo "    git clone $REPO" >&2
  exit 1
}

mkdir -p "$DEST"
cp -R "$TMP/repo/skill/." "$DEST/"
chmod +x "$DEST/publish.sh" "$DEST/recall.sh" 2>/dev/null || true
mkdir -p "$ARTIFACT_DIR"

echo "✓ installed to $DEST"
echo ""
echo "  use it:  open Claude Code and type  /talk-html"
echo "  or say:  \"做成一页\"  /  \"make a page out of this\""
echo ""
echo "  publishing to a gist needs the GitHub CLI, authed:"
echo "    brew install gh && gh auth login"
