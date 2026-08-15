---
name: project-memory
description: Review AGENTS.md's "known issues / current focus" checklist against the actual state of the repo and flag stale items, and consolidate metrics/findings-log.md by archiving resolved findings so the log stays readable as it grows. Trigger when the user asks to clean up, audit, or update AGENTS.md's checklist, or asks to consolidate/prune/archive the findings log.
---

# Project Memory Skill

Two things drift quietly in every project that adopts this toolkit, and
nothing else in the toolkit catches either one:

1. **`AGENTS.md`'s "known issues / current focus" checklist goes stale.**
   Someone ships a fix and forgets to check the box, or a line describes a
   plan that changed (a project that said "deploy to Vercel" but shipped to
   GitHub Pages instead, with a live link already in the README, and the
   line just never got removed).
2. **`metrics/findings-log.md` only ever grows.** A project six months in
   has a long table where resolved findings sit next to open ones with no
   distinction, and the log stops being something anyone reads closely.

Your job is to catch both, verify against the actual repo rather than
guessing, and never silently delete something you're not confident about.

## Steps

### 1. Check AGENTS.md's checklist against reality

Read the "known issues / current focus" section (or equivalent) in
`AGENTS.md`. For each item, verify it against the actual repo instead of
trusting the checkbox:

- An item like "add CI" — check whether `.github/workflows/ci.yml` exists.
- "Add husky hooks" — check for `.husky/pre-commit` and `.husky/pre-push`.
- "Deploy to X" — check the README for a live link, `package.json`'s
  `homepage` field, or a deploy workflow (`.github/workflows/*.yml`
  mentioning `pages`, `vercel`, `netlify`) targeting a _different_ platform
  than the checklist item names. A live link to platform A sitting next to
  an unchecked "deploy to platform B" item is the stale-item pattern to
  catch specifically.
- General items with no clear file to check — search the codebase for
  related keywords before concluding either way.

Classify each item as: **Done, box unchecked** (stale — recommend
checking it off or removing it), **Still accurate** (leave it), or
**Unverifiable** (say so rather than guessing).

### 2. Consolidate the findings log

Read `metrics/findings-log.md`. For each row:

- If it references an issue number (`Ref` column), check whether that
  issue is closed (`gh issue view <n>` or `gh issue list --state closed`).
- Rows referencing closed issues, or rows whose `Found — open` outcome has
  since been superseded by a later `Found → Fixed` row for the same
  finding, are candidates for archiving.

**Never delete history — archive it.** Move candidate rows out of the main
`## Log` table into a `## Archive` section at the bottom of the same file
(or a separate `findings-log-archive.md` if the archive grows large),
preserving every column exactly as it was. The main log should end up
short enough to actually read; the archive preserves the full record for
anyone who wants it.

### 3. Report, don't silently act

Present both sets of findings — stale checklist items and archive
candidates — and apply changes only after they're clear. Do not remove an
`AGENTS.md` line or move a log row without the specific reasoning visible
in the report first; this mirrors `sync-context`'s rule of reporting drift
rather than silently fixing it, for the same reason: a wrong guess here
quietly destroys project history.

### 4. Log the result

Append one row to `metrics/findings-log.md`: date, project,
`project-memory`, an outcome (`Clean` if nothing was stale, `Action taken`
if items were archived or flagged), and one sentence naming how many
checklist items were flagged stale and how many log rows were archived.

## Output Format

---

## Project Memory Check

### AGENTS.md checklist

| Item                         | Status                               | Evidence                                                                                                     |
| ---------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| Deploy to Vercel             | **Stale — already done differently** | Live link in README points to GitHub Pages; `.github/workflows/deploy.yml` deploys to `gh-pages`, not Vercel |
| Add screenshot/GIF to README | Still accurate                       | No image found in README                                                                                     |

### Findings log archive candidates

| Row                                                  | Reason                                               |
| ---------------------------------------------------- | ---------------------------------------------------- |
| 2026-07-13 — review-tests — 4 gaps in solver.test.ts | Issue tracking these gaps' underlying bugs is closed |

**Recommendation:** [one line — e.g. "Remove the stale Vercel line, archive 1 row."]

---

If nothing is stale and nothing needs archiving:
`AGENTS.md checklist is current and the findings log has no archive
candidates yet. No changes made.`
