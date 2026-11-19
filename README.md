# agent-journal

A Claude Code plugin in which the agent keeps a git journal of the documents it changes for you.

You work in conversation: you ask for changes, ask questions, open ideas to explore. The agent turns each intent into a tracked document change and answers for the journal. You never touch git; the agent does.

| You say | The agent does |
|---|---|
| "Add this risk", "reword the decision" | One commit per intent, with your words in a `Request:` line |
| "Let's try a version without X" | A branch `explore/<slug>`, and tells you which exploration is active |
| "Keep it" or "drop it" | Merges the branch, or archives it under a tag: nothing is lost |
| "What changed since the steering committee?" | Reads the diff since the matching milestone tag and cites the commits |
| "Why did we decide this?" | Finds the line's origin with `log` and `blame`, and the request behind it |
| "Go back to the previous version" | `git revert`, never a history rewrite |
| "It's validated, we send it" | An annotated tag `milestone/<date>-<slug>` freezes the version |

## What is inside

- **A skill** (`skills/agent-journal/SKILL.md`): the conventions. One intent per commit, the `Request:` line, explorations as branches, milestones as tags, answering from the history, never rewriting shared history, data rules.
- **Two hooks**, so the rules do not depend on the agent's goodwill:
  - `stop-guard.sh` will not let a turn end while the repository has uncommitted changes. It asks once per turn, so it cannot loop.
  - `git-guard.sh` refuses a commit without a `Request:` line, a force push, and the deletion of a milestone tag.
- **Templates** for other agents and harnesses: a native git `commit-msg` hook with the same rule, and an `AGENTS.md` section.

The plugin only acts in repositories whose root contains a `.agent-journal` file. Everywhere else it does nothing.

## Install

In Claude Code:

```
/plugin marketplace add EtienneLescot/agent-journal
/plugin install agent-journal@agent-journal
```

The hooks need `git` and `jq`.

## Turn journaling on in a folder

Ask the agent: "journal this folder". Or create the marker yourself:

```bash
git init
touch .agent-journal
```

`.agent-journal` can hold settings, one per line:

```
auto_push: true
main_branch: main
```

`auto_push` pushes after each commit and tag when the branch has an upstream (default `false`).

For agents other than Claude Code, add `templates/AGENTS.md` to your `AGENTS.md`, and install the native hook:

```bash
mkdir -p .githooks && cp templates/commit-msg .githooks/ && chmod +x .githooks/commit-msg
git config core.hooksPath .githooks
```

## A commit

```
Add supplier delay to the risk register

The supplier confirmed a three-week slip on the hardware.

Request: add the supplier delay to the risks, three weeks
Co-Authored-By: Claude <noreply@anthropic.com>
```

The `Request:` line quotes the person, not the agent's interpretation. That is what makes the journal checkable months later. The commit author is the person the agent works for.

## What it does not do

- It does not store prompts or conversation transcripts. The journal records intents and changes, which people can read; a transcript is long, noisy, and may hold content that should not stay in a history forever.
- It does not replace a task tool. If the repository uses one with its own command line (Backlog.md, for example), the agent changes tasks through it and commits the result under the same rule.
- It does not give fine-grained permissions: git rights apply per repository. Split repositories by who may read them.
- History cannot be cleanly erased. Keep secrets and personal data about people outside the team out of journaled documents.

## Tests

```bash
tests/run.sh
```

## License

MIT
