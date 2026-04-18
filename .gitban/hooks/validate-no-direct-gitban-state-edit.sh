#!/bin/bash
# Validate-at-rest Layer A — PreToolUse hook (ADR-045).
#
# Blocks Write/Edit/Bash tool calls that mutate *hard-protected* gitban state
# directly. Emits stderr warnings (never blocks) for *soft-protected* paths.
# Ignores *unprotected* paths.
#
# Hard-protected (block):
#   .gitban/cards/, .gitban/roadmap/, .gitban/agents/*/inbox/,
#   .gitban/cards/archive/, .gitban/audit/
# Soft-protected (warn-not-block):
#   .gitban/templates/, .gitban/handle.json, .gitban/validation_config.json,
#   .gitban/scaffold.example.yaml and other *.example.{json,yaml} files,
#   .gitban/examples/
# Unprotected (silent allow):
#   .gitban/hooks/, .gitban/template_config.json, .gitban/user_config.json,
#   .gitban/agents/*/logs/, .gitban/agents/traces/, .gitban/views/,
#   .gitban/validation_mode_audit.jsonl, .gitban/.viewer-port
#
# Escape hatch:
#   GITBAN_ALLOW_DIRECT_EDIT=1 turns blocks into stderr warnings. The detection
#   still fires — validate-on-read (ADR-045 Layer B) will surface the drift at
#   the next MCP read.
#
# Portability: uses grep/sed, not jq (MSYS2/Git Bash-friendly).

INPUT=$(cat)

# -------------------------------------------------------------------------
# JSON extraction
# -------------------------------------------------------------------------
TOOL_NAME=$(printf '%s' "$INPUT" | grep -oE '"tool_name"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

# Read-only / discovery tools never block. They may get stderr advisories in
# future revisions; for now they short-circuit.
case "$TOOL_NAME" in
  Read|Grep|Glob)
    exit 0
    ;;
esac

# -------------------------------------------------------------------------
# Path classification
# -------------------------------------------------------------------------
# Hard-protected regex: matches .gitban/(cards|roadmap|archive|audit)/ or
# .gitban/agents/<role>/inbox/. Supports both / and \ separators.
HARD_RE='\.gitban[/\\](cards|roadmap|archive|audit)([/\\]|$)|\.gitban[/\\]agents[/\\][^/\\]+[/\\]inbox([/\\]|$)'

# Soft-protected regex: matches individual user-config files and the templates/
# examples directories. Anything not in hard or soft with a .gitban/ prefix is
# treated as unprotected.
SOFT_RE='\.gitban[/\\](templates|examples)([/\\]|$)|\.gitban[/\\](handle\.json|validation_config\.json|scaffold\.example\.yaml|claude-mcp-setup\.example\.json|template_config\.example\.json|validation_config\.example\.json)$'

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------
classify_path() {
  # Returns "hard", "soft", or "none" (unprotected or non-gitban).
  local path="$1"
  if echo "$path" | grep -qiE "$HARD_RE"; then
    echo "hard"
  elif echo "$path" | grep -qiE "$SOFT_RE"; then
    echo "soft"
  else
    echo "none"
  fi
}

# Return a suggested MCP tool name for a given hard-protected path. Used to
# make block messages teach the correct alternative.
suggest_mcp_tool() {
  local path="$1"
  case "$path" in
    *.gitban/roadmap/*|*.gitban\\roadmap\\*)      echo "mcp__gitban__upsert_roadmap" ;;
    *.gitban/audit/*|*.gitban\\audit\\*)          echo "(audit log is write-only via MCP; do not edit directly)" ;;
    *.gitban/agents/*/inbox/*|*.gitban\\agents\\*\\inbox\\*)
      echo "(inbox files are written by dispatcher/agents via MCP; do not edit directly)" ;;
    *.gitban/cards/archive/*|*.gitban\\cards\\archive\\*)
      echo "mcp__gitban__archive_card (already archived; use mcp__gitban__delete_archive or mcp__gitban__import_archive)" ;;
    *)                                             echo "mcp__gitban__edit_card or mcp__gitban__create_card or mcp__gitban__archive_card (for deletion)" ;;
  esac
}

# Escape a string for safe inclusion in a JSON string literal. Handles
# backslashes, double quotes, tabs, newlines, and carriage returns. Kept
# small and pure-bash so the hook has no external dependency (no jq).
_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# Write a single JSONL entry to .gitban/audit/direct_edits.jsonl recording a
# hatch-allowed direct edit. Schema:
#   {"timestamp": ISO-8601 UTC, "tool_name": ..., "file_path": ...,
#    "reason": ..., "handle": ...}
# Handle is read from .gitban/handle.json if present (best effort — a missing
# or malformed file degrades to "unknown" rather than blocking the edit).
# The audit log is the audit surface the ADR requires (Layer A). It is
# intentionally append-only; the hook itself is the only sanctioned writer.
_write_audit_entry() {
  local tool_name="$1"
  local file_path="$2"
  local reason="$3"
  local audit_dir=".gitban/audit"
  local audit_file="$audit_dir/direct_edits.jsonl"
  local ts handle handle_file

  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
  handle_file=".gitban/handle.json"
  handle="unknown"
  if [ -f "$handle_file" ]; then
    handle=$(grep -oE '"handle"\s*:\s*"[^"]*"' "$handle_file" 2>/dev/null \
             | head -1 | sed 's/.*: *"//;s/"//')
    [ -z "$handle" ] && handle="unknown"
  fi

  mkdir -p "$audit_dir" 2>/dev/null || return 0
  printf '{"timestamp":"%s","tool_name":"%s","file_path":"%s","reason":"%s","handle":"%s"}\n' \
    "$(_json_escape "$ts")" \
    "$(_json_escape "$tool_name")" \
    "$(_json_escape "$file_path")" \
    "$(_json_escape "$reason")" \
    "$(_json_escape "$handle")" \
    >> "$audit_file" 2>/dev/null || true
}

# Emit the standard block message to stderr, with suggested MCP tool and the
# escape-hatch hint. Exits with code 2 (block) unless the escape hatch is set,
# in which case it emits a warning, writes an audit-log entry, and exits 0.
block_or_warn() {
  local reason="$1"
  local path="$2"
  local mcp_tool
  mcp_tool=$(suggest_mcp_tool "$path")
  if [ "${GITBAN_ALLOW_DIRECT_EDIT:-}" = "1" ]; then
    _write_audit_entry "${TOOL_NAME:-unknown}" "$path" "$reason"
    echo "WARNING: direct edit of gitban-managed state allowed by GITBAN_ALLOW_DIRECT_EDIT=1. Path: $path. Reason: $reason. Audit entry written to .gitban/audit/direct_edits.jsonl. This edit will be flagged as drift on next MCP read." >&2
    exit 0
  fi
  echo "BLOCKED: $reason" >&2
  echo "  Path: $path" >&2
  echo "  Use $mcp_tool instead." >&2
  echo "  To allow a legitimate hand-edit, set GITBAN_ALLOW_DIRECT_EDIT=1. The edit will be audited." >&2
  exit 2
}

warn_soft() {
  local path="$1"
  echo "NOTE: direct edit of soft-protected gitban file: $path. Allowed, but consider updating via MCP tools or a template change." >&2
}

# -------------------------------------------------------------------------
# Write / Edit: classify file_path directly
# -------------------------------------------------------------------------
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(printf '%s' "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  if [ -n "$FILE_PATH" ]; then
    tier=$(classify_path "$FILE_PATH")
    if [ "$tier" = "hard" ]; then
      block_or_warn "direct $TOOL_NAME on hard-protected gitban state" "$FILE_PATH"
    elif [ "$tier" = "soft" ]; then
      warn_soft "$FILE_PATH"
    fi
  fi
  exit 0
fi

# -------------------------------------------------------------------------
# Bash: parse command, apply short-circuits and cd-prefix normalization
# -------------------------------------------------------------------------
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(printf '%s' "$INPUT" | grep -oE '"command"\s*:\s*"(\\.|[^"\\])*"' | head -1 | sed 's/^"command"\s*:\s*"//;s/"$//')
  if [ -z "$COMMAND" ]; then
    COMMAND=$(printf '%s' "$INPUT" | grep -oE '"command"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  fi
  [ -z "$COMMAND" ] && exit 0

  # Short-circuit: any command starting with `git ` is a legitimate git
  # plumbing call. Git references card/roadmap paths routinely (commit
  # messages, `git add`, `git log --`); blocking these breaks the dispatcher.
  # See ADR-045 Layer A for the rationale.
  if echo "$COMMAND" | grep -qE '^[[:space:]]*git([[:space:]]|$)'; then
    exit 0
  fi

  # cd-prefix resolution (EXTFB pluh31). If the command starts with
  # `cd .gitban/<dir>[ &&|;|\n] <rest>`, rewrite <rest>'s bare paths to their
  # fully-qualified .gitban/... forms for classification.
  CD_PREFIX_DIR=""
  if echo "$COMMAND" | grep -qE '^[[:space:]]*cd[[:space:]]+\.gitban[/\\][^[:space:];&|]+'; then
    CD_PREFIX_DIR=$(echo "$COMMAND" | sed -nE 's/^[[:space:]]*cd[[:space:]]+(\.gitban[/\\][^[:space:];&|]+).*/\1/p' | head -1)
    # Strip the cd prefix so the remainder can be matched.
    REMAINDER=$(echo "$COMMAND" | sed -E 's/^[[:space:]]*cd[[:space:]]+[^[:space:];&|]+[[:space:]]*(&&|;|\|\|)?[[:space:]]*//')
    # Compose an effective command that re-prefixes the cd target onto the
    # first bare filename argument of the remainder. This is coarse but
    # sufficient for the common cases (mv, sed -i, echo >>, tee).
    EFFECTIVE_COMMAND="$REMAINDER $CD_PREFIX_DIR/"
  else
    EFFECTIVE_COMMAND="$COMMAND"
  fi

  # If there is a cd-prefix into a hard-protected directory, the intent is
  # already suspect — block (or warn under hatch) regardless of what the
  # rest of the command does, because even a seemingly-benign `cd x && mv a
  # b` is a state mutation inside a protected root.
  if [ -n "$CD_PREFIX_DIR" ]; then
    cd_tier=$(classify_path "$CD_PREFIX_DIR/")
    if [ "$cd_tier" = "hard" ]; then
      # Only block if the remainder actually looks like a mutation (not a
      # pure read like `cd cards && ls` or `cd cards && cat x.md`).
      if echo "$REMAINDER" | grep -qE '\b(mv|cp|touch|mkdir|tee|rm|rmdir|chmod|chown)\b' \
         || echo "$REMAINDER" | grep -qE '\bsed[[:space:]]+(-[a-zA-Z]*i|-i)\b' \
         || echo "$REMAINDER" | grep -qE '(^|[^2])>[>]?[[:space:]]'; then
        block_or_warn "cd .gitban/ prefix + mutating command bypasses hook (EXTFB pluh31)" "$CD_PREFIX_DIR/"
      fi
    fi
  fi

  # -----------------------------------------------------------------------
  # Classify paths referenced in the (possibly cd-expanded) command.
  # -----------------------------------------------------------------------
  # Extract every token that looks like a .gitban/... path (including the
  # effective cd-expanded form).
  PATHS=$(echo "$EFFECTIVE_COMMAND" | grep -oiE '\.gitban[/\\][^[:space:]"'"'"';&|]*' || true)

  # Also capture redirect targets explicitly so something like `echo x >.gitban/cards/y.md`
  # (no space) is caught.
  PATHS="$PATHS $(echo "$EFFECTIVE_COMMAND" | grep -oiE '>[>]?[[:space:]]*\.gitban[/\\][^[:space:]"'"'"';&|]*' | sed -E 's/^>[>]?[[:space:]]*//' || true)"

  HAS_HARD=0
  HAS_SOFT=0
  HARD_HIT_PATH=""
  SOFT_HIT_PATH=""
  for p in $PATHS; do
    [ -z "$p" ] && continue
    tier=$(classify_path "$p")
    if [ "$tier" = "hard" ]; then
      HAS_HARD=1
      HARD_HIT_PATH="$p"
    elif [ "$tier" = "soft" ]; then
      HAS_SOFT=1
      SOFT_HIT_PATH="$p"
    fi
  done

  # If no hard-protected path is referenced, we're done (soft warnings below).
  if [ "$HAS_HARD" = "1" ]; then
    # Now check whether the command actually mutates. Read-only commands on
    # protected paths are allowed (cat, grep, ls, head, tail, diff, wc).
    # A mutation is: shell redirect out (> or >>), or a mutating utility
    # (cp, mv, mkdir, touch, tee, chmod, chown, rm, rmdir, sed -i).
    # See ADR-045 "Mutating utilities enumerated" for the derivation rule:
    # any shell utility that mutates filesystem state on a protected path
    # must appear here. `rm`/`rmdir` added per FBSWEEP1 step 5B (card 5yogor).
    if echo "$EFFECTIVE_COMMAND" | grep -qE '(^|[^2])>[>]?[[:space:]]' \
       || echo "$EFFECTIVE_COMMAND" | grep -qE '\b(cp|mv|mkdir|touch|tee|chmod|chown|rm|rmdir)\b' \
       || echo "$EFFECTIVE_COMMAND" | grep -qE '\bsed[[:space:]]+(-[a-zA-Z]*i|-i)\b' \
       || echo "$EFFECTIVE_COMMAND" | grep -qE '^[[:space:]]*cat[[:space:]]*>[>]?'; then
      block_or_warn "Bash command mutates hard-protected gitban state" "$HARD_HIT_PATH"
    fi
    # Heredoc-style append: `cat >> file << EOF ... EOF` is a mutation too.
    if echo "$EFFECTIVE_COMMAND" | grep -qE '>[>]?[[:space:]]*\.gitban[/\\](cards|roadmap|archive|audit|agents[/\\][^/\\]+[/\\]inbox)[/\\]'; then
      block_or_warn "Bash heredoc/redirect mutates hard-protected gitban state (EXTFB l6osbk)" "$HARD_HIT_PATH"
    fi
  fi

  if [ "$HAS_SOFT" = "1" ]; then
    # Soft-protected: warn, don't block, only on apparent mutations.
    if echo "$EFFECTIVE_COMMAND" | grep -qE '(^|[^2])>[>]?[[:space:]]' \
       || echo "$EFFECTIVE_COMMAND" | grep -qE '\b(cp|mv|mkdir|touch|tee|chmod|chown|rm|rmdir)\b' \
       || echo "$EFFECTIVE_COMMAND" | grep -qE '\bsed[[:space:]]+(-[a-zA-Z]*i|-i)\b'; then
      warn_soft "$SOFT_HIT_PATH"
    fi
  fi
fi

exit 0
