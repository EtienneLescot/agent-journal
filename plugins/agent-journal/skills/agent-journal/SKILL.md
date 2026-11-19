---
name: agent-journal
description: Keep a git journal of every document change made for the user, in repositories that contain a `.agent-journal` file at their root. Use whenever you create, edit, move or delete files in such a repository; when the user asks to try or explore an idea, keep or drop it, go back to an earlier version, mark something as validated or sent; and when the user asks what changed, when, or why. Also use when the user asks to start journaling a folder. The user never touches git; you do, and you answer for the journal.
---

# Agent journal

The user directs the work in conversation: they ask for changes, ask questions and open ideas to explore. You turn each intent into a tracked document change. Git is your logbook, not the user's tool: never ask them to run a git command, and only use git vocabulary with them if they use it first.

## When this applies

The repository root (`git rev-parse --show-toplevel`) contains a file named `.agent-journal`. Read it at the start of a session; it may hold settings, one `key: value` per line:

- `auto_push: true` pushes after each commit and tag when the branch has an upstream. Default: `false`.
- `main_branch: <name>` names the branch that holds the agreed state. Default: the branch checked out when the session starts.

To start journaling a folder at the user's request: run `git init` if needed, create `.agent-journal`, and commit it with the format below.

## One intent, one commit

1. Before editing, run `git status`. If the working tree holds changes you did not make, do not stage or discard them: tell the user, in one sentence, what you found.
2. If `auto_push` is on and the branch has an upstream, run `git pull --rebase` before editing.
3. Make every change the request needs, then commit once, before ending your turn. Do not commit after each file, and do not mix two unrelated requests in one commit.
4. Stage only the files this request changed (`git add <paths>`, never `git add -A` on a tree that holds foreign changes).
5. Then tell the user in one line, in their language, what is now recorded and where: "Recorded: risk R12 added (exploration: no-notion)."

A pure question that changes no file creates no commit.

## Commit message format

```
<short summary of the change, imperative, under 72 characters>

<optional: why, in one or two sentences>

Request: <the user's request, in their own words, one line, trimmed>
```

- Write the summary and the why in the language the team writes its documents in, usually the user's language, so that anyone on the team can read the journal.
- The `Request:` line quotes what the user asked, not your interpretation. Shorten a long request with `[...]`, never reword it. It is what makes the journal checkable months later.
- Keep any trailer your harness adds, such as `Co-Authored-By`. The commit author is the person you work for, from their git configuration.
- Never put secrets or personal data about third parties in a message.

## Explorations are branches

- "Try...", "explore...", "what if...": create `explore/<short-slug>` from the current branch, switch to it and tell the user which exploration is active.
- "Keep it": merge into the main branch with `git merge --no-ff`, with a message in the format above, then delete the exploration branch.
- "Drop it": tag the branch tip `archive/explore-<slug>`, switch back, delete the branch. Nothing is lost; say so.
- When the user asks where things stand, and at the first change of a session, list the open explorations if there are any (`git branch --list 'explore/*'`), so none is forgotten.

## Decisions keep their reason

Keeping or dropping an exploration, and marking a milestone, are decisions. The journal records what was decided; only the user can say why. If they gave no reason, ask for it in one short question before recording, and put the answer in the message body. If they do not want to give one, record the decision without it. Later, "why did we do this?" can then be answered from the journal instead of "no reason was recorded".

## Milestones are tags

When the user says something is validated, sent, presented or delivered, create an annotated tag `milestone/<YYYY-MM-DD>-<short-slug>` on the current commit. Its message follows the commit format, with the `Request:` line. The tagged version can always be found again: tell the user its name.

## Answering from the history

Answer questions about the past from git, not from memory, and cite what you used (short hash, date, request):

- "What changed since the steering committee?": `git log` and `git diff` since the matching `milestone/` tag.
- "Why did we decide this?": `git log -S` or `git blame` on the line, then `git show` to read the request behind it.
- "What did it look like on the 15th?": `git log --before` and `git show <hash>:<path>`.
- "What have we explored?": open `explore/*` branches and `archive/explore-*` tags.

## Never rewrite shared history

- To undo, use `git revert`, which records the undo as a new intent.
- Never `push --force`, never `reset --hard` or rebase commits that are already pushed, never delete a `milestone/` tag.
- On a conflict after `git pull --rebase`, resolve it so that both intents survive, finish the rebase, and tell the user what you merged. If the two intents contradict each other, stop and ask the user which one wins.

## Data

- No secrets, no personal data about people outside the team. Refer to external people by role and organisation.
- If the user pastes such content, keep only what the document needs, or ask them.
- History cannot be cleanly erased: what is committed stays in every copy of the repository.

## Tasks

If the repository uses a task tool with its own command line, such as Backlog.md, change tasks through that tool, then commit its file changes under the same rule: one intent, one commit, with the `Request:` line.
