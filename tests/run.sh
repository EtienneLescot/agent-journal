#!/usr/bin/env bash
# Tests for the agent-journal hooks. Requires git and jq. Usage: tests/run.sh
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
hooks="$here/../plugins/agent-journal/hooks"
template="$here/../templates/commit-msg"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

check() { # check <name> <expected: allow|deny|block> <output>
  local got=allow
  case "$3" in
    *'"deny"'*) got=deny ;;
    *'"block"'*) got=block ;;
  esac
  if [ "$got" = "$2" ]; then echo "ok    $1"; else echo "FAIL  $1 (expected $2, got $got)"; failures=$((failures + 1)); fi
}

new_repo() { # new_repo <dir> <journaled: yes|no>
  mkdir -p "$1" && git -C "$1" init -q -b main
  git -C "$1" config user.email test@example.com && git -C "$1" config user.name Test
  [ "$2" = yes ] && touch "$1/.agent-journal"
  echo start > "$1/doc.md" && git -C "$1" add -A && git -C "$1" commit -q -m init
}

stop() { jq -n --arg cwd "$1" --argjson active "$2" '{cwd: $cwd, stop_hook_active: $active}' | "$hooks/stop-guard.sh" 2>/dev/null; }
bash_cmd() { jq -n --arg cwd "$1" --arg c "$2" '{cwd: $cwd, tool_input: {command: $c}}' | "$hooks/git-guard.sh"; }

new_repo "$work/plain" no
new_repo "$work/journal" yes

echo "# stop-guard"
echo change >> "$work/plain/doc.md"
check "plain repository with changes" allow "$(stop "$work/plain" false)"
check "journaled repository, clean" allow "$(stop "$work/journal" false)"
echo change >> "$work/journal/doc.md"
check "journaled repository with changes" block "$(stop "$work/journal" false)"
check "journaled repository, already asked once" allow "$(stop "$work/journal" true)"
check "subfolder of a journaled repository" block "$(mkdir -p "$work/journal/sub" && stop "$work/journal/sub" false)"

echo "# git-guard"
j="$work/journal"
check "plain repository, commit without Request" allow "$(bash_cmd "$work/plain" 'git commit -m "update"')"
check "not a git command" allow "$(bash_cmd "$j" 'ls -la')"
check "commit without Request" deny "$(bash_cmd "$j" 'git commit -m "Add risk R12"')"
check "commit with Request in a second -m" allow "$(bash_cmd "$j" 'git commit -m "Add risk R12" -m "Request: add the supplier risk"')"
check "commit with Request in a heredoc" allow "$(bash_cmd "$j" "git commit -F - <<'EOF'
Add risk R12

Request: add the supplier risk
EOF")"
printf 'Add risk R12\n\nRequest: add the risk\n' > "$j/msg.txt"
check "commit -F file with Request" allow "$(bash_cmd "$j" 'git commit -F msg.txt')"
printf 'Add risk R12\n' > "$j/msg2.txt"
check "commit -F file without Request" deny "$(bash_cmd "$j" 'git commit -F msg2.txt')"
check "empty Request" deny "$(bash_cmd "$j" 'git commit -m "x" -m "Request: "')"
check "amend without editing the message" allow "$(bash_cmd "$j" 'git commit --amend --no-edit')"
check "normal push" allow "$(bash_cmd "$j" 'git push origin main')"
check "push --force" deny "$(bash_cmd "$j" 'git push --force origin main')"
check "push -f" deny "$(bash_cmd "$j" 'git push -f')"
check "push --force-with-lease" deny "$(bash_cmd "$j" 'git push --force-with-lease')"
check "push +refspec" deny "$(bash_cmd "$j" 'git push origin +main')"
check "push --follow-tags" allow "$(bash_cmd "$j" 'git push --follow-tags')"
check "delete a milestone tag" deny "$(bash_cmd "$j" 'git tag -d milestone/2026-11-19-review')"
check "delete another tag" allow "$(bash_cmd "$j" 'git tag -d wip')"

echo "# commit-msg template"
printf 'Add risk\n\nRequest: add the risk\n' > "$work/m1"
printf 'Add risk\n' > "$work/m2"
printf 'Revert "Add risk"\n' > "$work/m3"
"$template" "$work/m1" 2>/dev/null && check "template with Request" allow "" || check "template with Request" allow '"deny"'
"$template" "$work/m2" 2>/dev/null && check "template without Request" deny "" || check "template without Request" deny '"deny"'
"$template" "$work/m3" 2>/dev/null && check "template on a revert" allow "" || check "template on a revert" allow '"deny"'

echo
[ "$failures" -eq 0 ] && echo "all tests passed" || echo "$failures test(s) failed"
exit "$failures"
