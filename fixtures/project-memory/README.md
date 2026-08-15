# `project-memory` fixture

Recreates the actual bug that motivated this skill: an `AGENTS.md`
checklist that's stale relative to what the repo actually does, plus a
findings-log with a resolved row that should get archived, not left to
pile up.

## What's planted

- `fixture-project/AGENTS.md` — "Current focus" checklist has an item
  marked "Deploy to Vercel" and checked off, but the repo's own
  `.github/workflows/deploy.yml` deploys to GitHub Pages, and there's no
  Vercel config anywhere. The checklist claim doesn't match reality.
- `fixture-project/.github/workflows/deploy.yml` — the actual deploy
  target, GitHub Pages, contradicting the AGENTS.md claim above.
- `fixture-project/metrics/findings-log.md` — three rows: one tied to an
  issue that's since closed (marked resolved in the row itself), two
  still open. A correct run should archive the resolved row into a
  `## Archive` section and leave the open ones untouched in the active log.

## How to run

    project-memory fixtures/project-memory/fixture-project

Compare against `expected-findings.md`. Append the result to
`results-log.md`.
