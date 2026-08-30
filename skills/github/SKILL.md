---
name: github
description: Use this skill for any GitHub operations in the terminal or Claude Code: opening issues, creating pull requests, reviewing PRs, listing issues, adding labels or comments, checking PR status, merging branches, cloning repos, or any other GitHub workflow. Trigger whenever the user mentions issues, PRs, pull requests, tickets, GitHub, wants to interact with a repository, or asks about repo activity.
---

# GitHub Skill

Use the `gh` CLI for all GitHub operations. The token is already set via `GITHUB_TOKEN` env variable.

## Before anything

Always confirm which repo you're in:

```bash
gh repo view
```

---

## Issues

### Create an issue

```bash
gh issue create --title "Bug: X is broken" --body "Steps to reproduce..." --label bug
```

### List open issues

```bash
gh issue list --state open
```

### View a specific issue

```bash
gh issue view 42
```

### Add a comment

```bash
gh issue comment 42 --body "Looking into this now"
```

### Close an issue

```bash
gh issue close 42
```

---

## Pull Requests

### Create a PR

```bash
gh pr create --title "feat: add X" --body "## What\nDescription here" --base main
```

**Closing multiple issues from one PR:** GitHub only auto-closes the issue
immediately after a closing keyword. `Closes #21, #22, #23, #24` in the PR
body only closes **#21** on merge — #22–#24 just get referenced, not closed.
Repeat the keyword before each one instead: `closes #21, closes #22, closes
#23, closes #24`. Verify what actually linked before assuming a merge closed
everything: `gh api repos/<owner>/<repo>/pulls/<n> -q '.closingIssuesReferences[].number'`.
If a PR already merged with the comma-list form, close the missed issues
manually (`gh issue close <n> --comment "..."`) rather than leaving them open.

### List open PRs

```bash
gh pr list
```

### View a PR

```bash
gh pr view 42
```

### See a PR's code diff

```bash
gh pr diff 42
```

### Merge a PR

```bash
gh pr merge 42 --squash
```

### Add a comment to a PR

```bash
gh pr comment 42 --body "Looks good, merging tomorrow"
```

---

## Resolving PR Conflicts

When a PR has conflicts with the base branch, resolve them via rebase (preferred over merge commits).

### 1. Check which files conflict

```bash
gh pr view 42          # confirm the base branch
git fetch origin main
git rebase origin/main # git will stop at each conflicting file
```

### 2. For each conflicting file

Look for conflict markers:

```
<<<<<<< HEAD
your branch's version
=======
main's version
>>>>>>> origin/main
```

Edit the file, then stage it:

```bash
git add path/to/file
```

### 3. Continue or abort

```bash
git rebase --continue
git rebase --abort    # to undo everything
```

### 4. Push the resolved branch

```bash
git push --force-with-lease
```

### Tips

- Prefer `git rebase origin/main` over `git merge origin/main` for linear history
- If the conflict is in a generated file (e.g. `package-lock.json`), delete it, re-run `npm install`, then `git add` and `git rebase --continue`
- Use `git diff --name-only --diff-filter=U` to list all unresolved files

---

## Triaging findings from other skills (a11y, review-tests)

When asked to open and assign issues from another skill's findings:

1. **Check for existing issues first** — search open and recently closed issues (`gh issue list --search "<keyword>"`) before creating new ones. If a finding is already tracked, add the appropriate label and a comment with the concrete repro/root cause/fix instead of opening a duplicate. Avoiding duplicate issues is part of the job, not an edge case.
2. **Label consistently** — use labels that describe the finding's category (`bug`, `accessibility`, `tests`, `enhancement`), not just a generic `todo`.
3. **Assign to the requester** unless told otherwise.
4. **Report a summary**, not just a list of numbers: how many were new vs. recognized as existing, and why — that judgment call is worth surfacing, not hiding inside a terse "done."

## Log the result

Append one row to `metrics/findings-log.md`: date, project, `github`, an
outcome (`Action taken`), and one sentence covering how many issues were
newly opened vs. recognized as already-tracked. The duplicate-avoidance
count is worth keeping — it's evidence of judgment, not just throughput.

---

## General Tips

- Add `--web` to any command to open it in the browser
- Use `gh issue list --assignee @me` to see only your issues
- Use `gh pr list --author @me` to see your own PRs
- Always confirm the current repo with `gh repo view` before running commands
