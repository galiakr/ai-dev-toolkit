---
name: add-logging-step
description: Retrofit the "log the result" step into a skill's SKILL.md that doesn't have one yet, so every skill run appends a row to metrics/findings-log.md. Trigger when the user adds a new skill, adopts a third-party skill, or asks to make an existing skill log its results.
---

# Add Logging Step Skill

Every skill in this toolkit is supposed to end with a **"log the result"**
step: a final step that appends one row to the project's
`metrics/findings-log.md` so the metrics system has a record of what each
skill actually caught, run by run. A skill without that step runs silently —
its history is lost, and the health check in `toolkit-health.md` has nothing
to read.

Your job is to add that step to a skill that's missing it, matching the house
style of the skills that already have one, without duplicating a step that's
already there.

## Steps

### 1. Determine the target skill(s)

- If the user named a skill, target its `SKILL.md`.
- Otherwise, scan every `SKILL.md` under `skills/` (in this repo) or
  `.claude/skills/` (in an adopting project) and find the ones with no
  logging step yet:

  ```bash
  for f in skills/*/SKILL.md .claude/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    grep -qi "findings-log" "$f" || echo "MISSING: $f"
  done
  ```

Report the list before editing. If a skill already references
`findings-log.md`, **skip it** — do not add a second step. Adding a duplicate
row-append is worse than doing nothing.

### 2. Read the skill to learn its shape

Before writing the step, read the target `SKILL.md` and note:

- **What it produces** — findings it can fix vs. only report, a pass/fail, a
  count, a drift report, an action it takes.
- **Its numbered `## Steps` list** — the new step is appended as the last
  numbered step, immediately before `## Output Format` (or before the first
  non-step section if there's no Output Format).
- **The outcome vocabulary that fits it** (see step 3).

### 3. Pick outcome values that fit this skill

The findings log uses a fixed outcome vocabulary
(`metrics/findings-log.md`): `Found → Fixed`, `Found — open`, `Clean`,
`Action taken`. Choose the subset that this skill can actually produce:

| Skill nature | Outcomes to offer |
|--------------|-------------------|
| Audits/reviews that can fix (a11y, review-tests) | `Clean`, `Found → Fixed`, `Found — open` |
| Report-only checks (sync-context) | `Clean`, `Found — open` |
| Skills that perform a change (language-tokens, this one) | `Action taken`, or `Clean` if nothing needed doing |

A clean run is always worth logging — say so in the step, because the
instinct is to log only findings.

### 4. Write the step

Append a final numbered step in this exact shape, adapted to the skill:

```markdown
### N. Log the result

Append one row to `metrics/findings-log.md`: date, project, `<skill-name>`,
an outcome (<the outcomes from step 3, with what each means for this skill>),
and one sentence naming <the specific number this skill produces — violation
count, drift count, tests reviewed, strings migrated>. A clean run is worth
logging too — it's evidence the practice is holding, not nothing to report.
```

Rules for the wording:
- Use the skill's own `name:` from its frontmatter as the logged skill name.
- Name the **specific number** the skill produces, not "some findings" —
  round summaries can't be checked later; specific counts can.
- Match the surrounding numbering (`### N.` vs `N.`) and heading depth the
  target file already uses.

### 5. Confirm

Re-read the edited file to confirm the step landed in the right place (last
step, before the output section) and that there's exactly one logging step.

> This skill does **not** log its own run to `metrics/findings-log.md`. That
> log is a record of what project-check skills found or did in a project;
> `add-logging-step` edits skill *definitions* in the toolkit, so its runs
> don't belong there. Authoring/meta skills are exempt from the "every skill
> logs" rule.

## Output Format

---

## Logging Step Retrofit

**Scanned:** `skills/*/SKILL.md` (6 skills)

| Skill | Had logging step? | Action |
|-------|-------------------|--------|
| a11y | yes | skipped |
| my-new-skill | no | added step 6, outcomes `Clean` / `Action taken` |

**Result:** Added the logging step to 1 skill. Every project-check skill in
`skills/` now appends to `findings-log.md` on completion.

---

If every scanned skill already had the step:
`All skills already log their results. Nothing to add.`
