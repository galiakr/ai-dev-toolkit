---
name: github
description: Use this skill for any GitHub operations in the terminal or Claude Code: opening issues, creating pull requests, reviewing PRs, listing issues, adding labels or comments, checking PR status, merging branches, cloning repos, or any other GitHub workflow. Trigger whenever the user mentions issues, PRs, pull requests, tickets, GitHub, wants to interact with a repository, or asks about repo activity.
---

# GitHub Skill

Use the `gh` CLI for all GitHub operations. `gh` uses `GITHUB_TOKEN` if it's
set, otherwise its own stored login — `gh auth status` shows which.

## Steps

1. **Confirm the repo and auth.** Run `gh repo view` (and `gh auth status`
   if anything fails). Acting on the wrong repo is the most expensive
   mistake this skill can make.
2. **Look before you create.** Before opening an issue or PR, search for an
   existing one (`gh issue list --search "<keyword>" --state all`). A
   comment on an existing issue beats a duplicate.
3. **Do the operation**, using the command reference below — issues, pull
   requests, or rebase-based conflict resolution.
4. **If you're turning another skill's findings into issues**, follow
   "Triaging findings from other skills" below: dedupe, label (including
   `found-by:`), assign.
5. **Report what you did**, in the Output Format below — what was created,
   what was recognized as already tracked, and why.
6. **Log the result.** Append one row to `metrics/findings-log.md`: date,
   project, `github`, an outcome (`Action taken`), and one sentence covering
   how many issues were newly opened vs. recognized as already-tracked. The
   duplicate-avoidance count is worth keeping — it's evidence of judgment,
   not just throughput.

   If the project's `AGENTS.md` says findings are tracked as GitHub issues
   instead of in `metrics/findings-log.md` (or says that file must stay
   blank), don't write the row. Post the same sentence as a comment on the
   project's `skill-runs` tracking issue instead, and skip logging entirely
   only if neither exists — say so in the summary rather than silently.

## Output Format

```
## GitHub — owner/repo

Opened 3, recognized 1 as already tracked:
- #41 Missing alt text on product images (new) — bug, accessibility, found-by:a11y
- #42 Unlabeled search input (new) — bug, accessibility, found-by:a11y
- #43 Coverage excludes src/api/ (new) — tests, found-by:review-tests
- #37 Low-contrast footer text (existing) — commented with the repro, added found-by:a11y

Logged: 3 opened, 1 already tracked.
```

If nothing needed doing: `No GitHub changes made — <one-line reason, e.g.
every finding was already tracked>.`

---

# Command reference

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
2. **Label consistently** — use labels that describe the finding's category (`bug`, `accessibility`, `tests`, `enhancement`), not just a generic `todo`. Also add a `found-by:<source>` label naming what produced the finding (`found-by:a11y`, `found-by:ci`, `found-by:review` for a review pass that wasn't a skill run), creating it with `gh label create` if it doesn't exist yet. That attribution is what lets the toolkit's `scripts/toolkit-report.sh` say which skills actually find things.
3. **Assign to the requester** unless told otherwise.
4. **Report a summary**, not just a list of numbers: how many were new vs. recognized as existing, and why — that judgment call is worth surfacing, not hiding inside a terse "done."

---

## General Tips

- Add `--web` to any command to open it in the browser
- Use `gh issue list --assignee @me` to see only your issues
- Use `gh pr list --author @me` to see your own PRs
- Always confirm the current repo with `gh repo view` before running commands
