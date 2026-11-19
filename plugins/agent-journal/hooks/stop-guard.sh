#!/usr/bin/env bash
# Stop hook: refuse to end a turn while a journaled repository has uncommitted changes.
# A repository is journaled when its root contains a .agent-journal file.
# The hook asks only once per turn (stop_hook_active), so it can never loop.
set -uo pipefail

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
already_asked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')

[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/.agent-journal" ] || exit 0

changes=$(git -C "$root" status --porcelain --untracked-files=normal 2>/dev/null)
[ -z "$changes" ] && exit 0

if [ "$already_asked" = "true" ]; then
  echo "agent-journal: uncommitted changes remain in $root" >&2
  exit 0
fi

reason="This repository is journaled (.agent-journal) and has uncommitted changes:
$changes

Commit the changes you made for the user's request, following the agent-journal skill: one commit per intent, with a 'Request:' line quoting the user's words. If some of these changes are not yours, leave them untouched and tell the user."

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
