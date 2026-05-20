#!/usr/bin/env bash
# install.sh — install the talk-html plugin.
#
# Installs two things, both idempotent:
#   1. The `talk-html` skill into ~/.claude/skills/talk-html/
#      (preserves the existing /talk-html invocation and `skill/SKILL.md`-driven
#       render pipeline — preflight, real-content grounding, embed, publish, recall)
#   2. The plugin's router + role commands into ~/.claude/plugins/talk-html-plugin/
#      (registers /talk-html, /talk-ux, /talk-ceo, /talk-data, /talk-reviewer,
#       /talk-cto, /talk-qa, /talk-docs, /talk-legal as slash commands)
#
#   curl -fsSL https://raw.githubusercontent.com/LiuShiyuMath/talk-html-plugin/main/install.sh | bash
#
# Existing installs are backed up to *.bak.<timestamp>, never clobbered.

set -euo pipefail

REPO="https://github.com/LiuShiyuMath/talk-html-plugin"
SKILL_DEST="$HOME/.claude/skills/talk-html"
PLUGIN_DEST="$HOME/.claude/plugins/talk-html-plugin"
ARTIFACT_DIR="$HOME/.claude/talk-html"

echo "→ installing talk-html-plugin from $REPO"

command -v git >/dev/null 2>&1 || {
  echo "✗ git is required but not installed." >&2
  exit 1
}

backup_if_present() {
  local target="$1"
  if [[ -d "$target" || -L "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "  note: $target already exists — moving it to $backup"
    mv "$target" "$backup"
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 "$REPO" "$TMP/repo" >/dev/null 2>&1 || {
  echo "✗ git clone failed. check your network, or clone manually:" >&2
  echo "    git clone $REPO" >&2
  exit 1
}

# 1. skill install (canonical render pipeline)
backup_if_present "$SKILL_DEST"
mkdir -p "$SKILL_DEST"
cp -R "$TMP/repo/skills/talk-html/." "$SKILL_DEST/"
chmod +x "$SKILL_DEST/publish.sh" "$SKILL_DEST/recall.sh" 2>/dev/null || true

# 2. plugin install (router + 8 role commands)
backup_if_present "$PLUGIN_DEST"
mkdir -p "$PLUGIN_DEST"
cp -R "$TMP/repo/.claude-plugin"   "$PLUGIN_DEST/"
cp -R "$TMP/repo/commands"         "$PLUGIN_DEST/"
cp -R "$TMP/repo/skills"           "$PLUGIN_DEST/"

mkdir -p "$ARTIFACT_DIR"

echo "✓ skill   installed to $SKILL_DEST"
echo "✓ plugin  installed to $PLUGIN_DEST"
echo ""
echo "  use the router:    /talk-html        (infers audience, dispatches)"
echo "  use a role direct: /talk-ux | /talk-ceo | /talk-data | /talk-reviewer"
echo "                     /talk-cto | /talk-qa | /talk-docs | /talk-legal"
echo ""
echo "  publishing to a gist needs the GitHub CLI, authed:"
echo "    brew install gh && gh auth login"
