#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

NAME="${1:?Usage: generate-skill.sh <name> <description> <instructions> [requires_bins] [requires_env]}"
DESCRIPTION="${2:?Missing description}"
INSTRUCTIONS="${3:?Missing instructions}"
REQUIRES_BINS="${4:-}"
REQUIRES_ENV="${5:-}"

# Sanitize skill name: lowercase, hyphens only
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

SKILL_DIR="$WORKSPACE/skills/$SLUG"

if [ -d "$SKILL_DIR" ]; then
  echo "ERROR: Skill directory already exists: $SKILL_DIR"
  echo "Remove it first or choose a different name."
  exit 1
fi

mkdir -p "$SKILL_DIR"

# Build metadata JSON
# NOTE: JSON is constructed via string concatenation. This works for simple
# comma-separated values (e.g. "curl,jq") but will break if bin/env names
# contain quotes, spaces, or special characters. For complex cases, pipe
# through jq if available:
#   jq -n --arg bins "$REQUIRES_BINS" '$bins | split(",") | {bins: .}'
METADATA=""
REQUIRES_PARTS=()

if [ -n "$REQUIRES_BINS" ]; then
  # Convert comma-separated bins to JSON array
  BINS_JSON=$(echo "$REQUIRES_BINS" | sed 's/,/","/g')
  REQUIRES_PARTS+=("\"bins\":[\"$BINS_JSON\"]")
fi

if [ -n "$REQUIRES_ENV" ]; then
  ENV_JSON=$(echo "$REQUIRES_ENV" | sed 's/,/","/g')
  REQUIRES_PARTS+=("\"env\":[\"$ENV_JSON\"]")
fi

if [ ${#REQUIRES_PARTS[@]} -gt 0 ]; then
  REQUIRES_JOINED=$(IFS=,; echo "${REQUIRES_PARTS[*]}")
  METADATA="metadata: {\"openclaw\":{\"requires\":{$REQUIRES_JOINED}}}"
fi

# Write SKILL.md
{
  echo "---"
  echo "name: $SLUG"
  echo "description: $DESCRIPTION"
  if [ -n "$METADATA" ]; then
    echo "$METADATA"
  fi
  echo "---"
  echo ""
  echo "# $NAME"
  echo ""
  echo "$INSTRUCTIONS"
} > "$SKILL_DIR/SKILL.md"

echo "=== Skill Generated ==="
echo "  Directory: $SKILL_DIR"
echo "  File: $SKILL_DIR/SKILL.md"
echo ""
echo "--- Content ---"
cat "$SKILL_DIR/SKILL.md"
echo ""
echo "--- End ---"
echo ""
echo "Review the skill above. Install with: cp -r $SKILL_DIR ~/.openclaw/workspace/skills/"
