#!/usr/bin/env bash
set -euo pipefail

# Sanitized file writer for workspace bootstrap files.
# Used by interactive setup to route all writes through script-level
# sanitization rather than having the agent write files directly.
#
# Usage: write-file.sh <filename> <content>
#   filename: must be a whitelisted bootstrap file (e.g. SOUL.md, AGENTS.md)
#   content:  the full file content to write
#
# Modes:
#   Default:  refuses to overwrite an existing file
#   --force:  overwrites existing file (requires explicit flag)

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true; shift ;;
  esac
done

FILENAME="${1:?Usage: write-file.sh [--force] <filename> <content>}"
CONTENT="${2:?Missing file content}"

# --- Validate filename ---
# Must be a simple name, no path traversal
if printf '%s' "$FILENAME" | grep -qE '/|\\|\.\.'; then
  echo "ERROR: Invalid filename '$FILENAME'. Must be a simple filename, no paths."
  exit 1
fi

# Whitelist: only known workspace bootstrap files
case "$FILENAME" in
  SOUL.md|AGENTS.md|USER.md|TOOLS.md|IDENTITY.md|MEMORY.md) ;;
  *)
    echo "ERROR: Only bootstrap files can be written through this script."
    echo "Allowed: SOUL.md, AGENTS.md, USER.md, TOOLS.md, IDENTITY.md, MEMORY.md"
    exit 1
    ;;
esac

TARGET="$WORKSPACE/$FILENAME"

# --- Check overwrite ---
if [ -f "$TARGET" ] && [ "$FORCE" != "true" ]; then
  echo "ERROR: $FILENAME already exists. Use --force to overwrite."
  exit 1
fi

# --- Validate content: shell metacharacters ---
if printf '%s' "$CONTENT" | grep -qE '`|\$\('; then
  echo "ERROR: Content contains shell metacharacters (\` or \$()). Refusing to write."
  echo "Remove backticks and command substitutions, then retry."
  exit 1
fi

# --- Validate content: prompt injection ---
CONTENT_LOWER=$(printf '%s' "$CONTENT" | tr '[:upper:]' '[:lower:]')

PATTERNS=(
  'ignore (all |any )?(previous |prior |above )?instructions'
  'ignore (all |any )?(previous |prior |above )?rules'
  'disregard (all |any )?(previous |prior |above )?instructions'
  'forget (all |any )?(previous |prior |above )?instructions'
  'override (all |any )?(previous |prior |above )?instructions'
  'you are now'
  'new instructions:'
  'system prompt'
  'act as if'
  'pretend (that |to )'
  'from now on.*(ignore|disregard|forget|override)'
  'do not follow.*(previous|prior|above|original)'
  'secret(ly)? (send|transmit|upload|exfiltrate|forward|email|post)'
  'send.*(all|every).*(file|data|content|message|info).* to'
  'upload.*(all|every).*(file|data|content|message|info).* to'
  'exfiltrate'
  'curl .*(POST|PUT|PATCH)'
  'wget .*--post'
  'base64 (encode|decode|--decode|-d)'
)

for pattern in "${PATTERNS[@]}"; do
  if printf '%s' "$CONTENT_LOWER" | grep -qEi "$pattern"; then
    echo "ERROR: Content rejected -- matches prompt injection pattern."
    printf 'Blocked pattern: %s\n' "$pattern"
    echo ""
    echo "If this is legitimate content, write the file manually."
    exit 1
  fi
done

# --- Write file ---
mkdir -p "$WORKSPACE"
printf '%s\n' "$CONTENT" > "$TARGET"

echo "=== File Written ==="
printf '  File: %s\n' "$TARGET"
printf '  Size: %s bytes\n' "$(wc -c < "$TARGET" | tr -d ' ')"
