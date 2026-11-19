#!/usr/bin/env bash
# PreToolUse hook (Bash) for journaled repositories:
# - a git commit must carry a "Request:" line quoting the user's words;
# - force pushes and rewrites of shared history are refused.
# Repositories without a .agent-journal file at their root are left alone.
set -uo pipefail

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

case "$cmd" in
  *git*) ;;
  *) exit 0 ;;
esac

[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/.agent-journal" ] || exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([^;&|]*)(--force|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[^[:space:]]+)'; then
  deny "agent-journal: force push is not allowed in a journaled repository. Shared history is never rewritten; use git revert to undo."
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+tag([^;&|]*)[[:space:]](-d|--delete)[^;&|]*milestone/'; then
  deny "agent-journal: milestone tags are never deleted."
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit' \
  && ! printf '%s' "$cmd" | grep -Eq -- '--amend[^;&|]*--no-edit|--no-edit[^;&|]*--amend'; then
  message="$cmd"
  file=$(printf '%s' "$cmd" | sed -nE 's/.*(-F|--file)[[:space:]=]+([^[:space:];&|]+).*/\2/p' | head -n 1)
  if [ -n "$file" ]; then
    case "$file" in
      /*) path="$file" ;;
      *) path="$cwd/$file" ;;
    esac
    [ -f "$path" ] && message=$(cat "$path")
  fi
  if ! printf '%s' "$message" | grep -Eq 'Request:[[:space:]]*[^[:space:]"'"'"']'; then
    deny "agent-journal: this commit has no 'Request:' line. Add one that quotes the user's request in their own words (see the agent-journal skill), then commit again."
  fi
fi

exit 0
