#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

NAME="${1:?Usage: generate-skill.sh <name> <description> <instructions> [requires_bins] [requires_env]}"
DESCRIPTION="${2:?Missing description}"
INSTRUCTIONS="${3:?Missing instructions}"
REQUIRES_BINS="${4:-}"
REQUIRES_ENV="${5:-}"

# --- Input validation ---
# Reject inputs containing shell metacharacters that could cause issues
validate_input() {
  local label="$1"
  local input="$2"
  if printf '%s' "$input" | grep -qE '`|\$\('; then
    printf 'ERROR: %s contains shell metacharacters (` or $()). Refusing to proceed.\n' "$label"
    echo "Remove backticks and command substitutions, then retry."
    exit 1
  fi
}

validate_input "name" "$NAME"
validate_input "description" "$DESCRIPTION"
validate_input "instructions" "$INSTRUCTIONS"
validate_input "requires_bins" "$REQUIRES_BINS"
validate_input "requires_env" "$REQUIRES_ENV"

# Validate requires_bins and requires_env: only allow alphanumeric, hyphens, underscores, commas
if [ -n "$REQUIRES_BINS" ]; then
  if printf '%s' "$REQUIRES_BINS" | grep -qE '[^a-zA-Z0-9_,.-]'; then
    echo "ERROR: requires_bins contains invalid characters. Only alphanumeric, hyphens, underscores, dots, and commas allowed."
    exit 1
  fi
fi

if [ -n "$REQUIRES_ENV" ]; then
  if printf '%s' "$REQUIRES_ENV" | grep -qE '[^a-zA-Z0-9_,]'; then
    echo "ERROR: requires_env contains invalid characters. Only alphanumeric, underscores, and commas allowed."
    exit 1
  fi
fi

# Sanitize skill name: lowercase, hyphens only
SLUG=$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

if [ -z "$SLUG" ]; then
  echo "ERROR: Name sanitized to empty string. Use alphanumeric characters."
  exit 1
fi

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
  BINS_JSON=$(printf '%s' "$REQUIRES_BINS" | sed 's/,/","/g')
  REQUIRES_PARTS+=("\"bins\":[\"$BINS_JSON\"]")
fi

if [ -n "$REQUIRES_ENV" ]; then
  ENV_JSON=$(printf '%s' "$REQUIRES_ENV" | sed 's/,/","/g')
  REQUIRES_PARTS+=("\"env\":[\"$ENV_JSON\"]")
fi

if [ ${#REQUIRES_PARTS[@]} -gt 0 ]; then
  REQUIRES_JOINED=$(IFS=,; printf '%s' "${REQUIRES_PARTS[*]}")
  METADATA="metadata: {\"openclaw\":{\"requires\":{$REQUIRES_JOINED}}}"
fi

# Write SKILL.md using printf to avoid echo expansion issues
{
  printf '%s\n' "---"
  printf 'name: %s\n' "$SLUG"
  printf 'description: %s\n' "$DESCRIPTION"
  if [ -n "$METADATA" ]; then
    printf '%s\n' "$METADATA"
  fi
  printf '%s\n' "---"
  printf '\n'
  printf '# %s\n' "$NAME"
  printf '\n'
  printf '%s\n' "$INSTRUCTIONS"
} > "$SKILL_DIR/SKILL.md"

echo "=== Skill Generated ==="
printf '  Directory: %s\n' "$SKILL_DIR"
printf '  File: %s/SKILL.md\n' "$SKILL_DIR"
echo ""
echo "--- Content ---"
cat "$SKILL_DIR/SKILL.md"
echo ""
echo "--- End ---"
echo ""
printf 'Review the skill above. Install with: cp -r %s ~/.openclaw/workspace/skills/\n' "$SKILL_DIR"
