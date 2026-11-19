## Journal

This repository is journaled by its agents. The people who direct the work never use git; the agent does, and answers for the journal.

- One user intent, one commit, made before the end of the turn. Stage only the files changed for that intent, never someone else's changes.
- Every commit message ends with `Request: <the user's request in their own words>`.
- An idea to try is a branch `explore/<slug>`. Kept: merged with `--no-ff`. Dropped: tagged `archive/explore-<slug>`, then deleted.
- Something validated, sent or presented is an annotated tag `milestone/<YYYY-MM-DD>-<slug>`.
- Questions about the past are answered from git (`log`, `diff`, `blame`, `show`), citing the commit.
- Undo with `git revert`. Never force push, never rewrite pushed history, never delete a milestone tag.
- No secrets and no personal data about people outside the team.
