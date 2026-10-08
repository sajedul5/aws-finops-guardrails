---
name: step-done
description: Finish a roadmap step by giving the user copy-paste commands to commit, push, open a PR, merge and sync. Use at the end of EVERY completed step in docs/ROADMAP.md, or when the user asks for "command", "commit command" or "PR command".
---

# Step done: hand over the ship commands

Claude doesn't commit, push or merge. The user runs these commands.

## 1. Before printing anything
- Run `/validate`. If anything fails, fix it first. Never hand over commands for a broken step.
- Mark the step ✅ in `docs/ROADMAP.md` and add the changes to `CHANGELOG.md` under `[Unreleased]`.
- Run `git status --short` and `git branch --show-current`. List only the files that belong to **this** step; leave out placeholders for later steps.

## 2. Print this block, filled in
Use the real step number, branch name, file list and summary. If work is already on a feature branch, skip the `git switch -c` line.

```bash
# 1. Branch from an up-to-date main
git switch main && git pull
git switch -c <type>/<short-name>

# 2. Stage only this step's files
git add <file1> <file2> ...

# 3. Check (only the files above should be staged)
git status --short

# 4. Commit
git commit -m "<type>: <summary> (Step N)

- <change 1>
- <change 2>"

# 5. Push the branch (never main)
git push -u origin <branch>

# 6. Open the pull request
gh pr create --base main --title "<type>: <summary> (Step N)" --body "<one-paragraph summary + checks that passed>"

# 7. Review and merge (only you)
gh pr view --web
gh pr merge --merge --delete-branch

# 8. Sync local main
git switch main && git pull && git branch -d <branch>
```

## 3. After the block
One line: what the next step is. Then stop and wait.
