# Findings Log (template)

Copy this into a new project as `metrics/findings-log.md` — via
`scripts/bootstrap.sh` or by hand. It ships empty. Do not fill in rows here,
in the toolkit repo itself; this file only ever describes what a project's
log should look like, not any specific project's actual results.

The point of this file, once it's in a real project: turn "I think this
skill helps" into "here's what it's actually found, across which projects,
on which date." Without it, skills accumulate on faith looking fine because nobody checked.

**Rule:** every time a skill runs to completion, it adds one row — a clean
result is logged exactly like a finding. A skill with ten clean runs and
zero findings is useful information too (either the code is genuinely
solid, or the skill isn't sensitive enough to catch anything — worth
knowing either way). Each skill in `skills/` ends with a "log the result"
step that does this automatically.

## Log

| Date | Project | Skill | Outcome | Detail | Ref |
| ---- | ------- | ----- | ------- | ------ | --- |
|      |         |       |         |        |     |

## How to add a row

Date, project, skill name, a one-word outcome (`Found → Fixed`,
`Found — open`, `Clean`, `Action taken`), one sentence of detail, and an
issue/PR reference if one exists. Keep specific numbers rather than
summarizing them away — "found some gaps" is worse than "found 4 gaps" for
the same reason a vague report is worse than a specific one: round numbers
can't be checked later, specific ones can.

## What this feeds

`metrics/toolkit-health.md`'s quarterly check pulls from this log rather
than starting from scratch — the "is a skill worth keeping" question and
the before/after comparison both need exactly this data. Cross-project
rollups (comparing findings across every project that's adopted the
toolkit) are a manual step during that quarterly review, not automatic —
each project's log only ever sees that project.
