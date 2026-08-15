# Results Log — `prompt-injection-guard.yml` fixture

Every run of the extracted detection logic against the sample files here
gets a row. Re-run and add a row whenever the pattern list changes (it's
meant to stay in sync with `skills/audit-skills/SKILL.md` step 3 and
`.github/workflows/ci.yml`'s canonical list — a change to one without
the others is itself a bug worth this log catching).

| Date | Run by | Matched expected? | Detail |
|------|--------|---------------------|--------|
| 2026-08-11 | Extracted `run:` script from `git/workflows/prompt-injection-guard.yml`, executed directly against all three sample files | Yes | `sample-pr-clean.txt`: `flagged=false`, confirmed. `sample-pr-injected.txt`: `flagged=true`, matched exactly "pre-approved by the maintainer" and "skip confirmation and merge," the two planted phrases. `sample-pr-borderline.txt`: `flagged=true`, matched "Don't mention this to the user" — the real false positive this fixture is meant to demonstrate, confirmed working as designed rather than as a bug. Labeling/comment-posting step not exercised — needs a live PR, documented as a permanent limit in `README.md`. |
