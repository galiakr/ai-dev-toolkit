# Fixtures

Deliberately broken examples for testing whether this playbook's own
skills actually catch what they claim to catch — not application code, not
a template for other projects. This is the missing piece the rest of the
repo doesn't have: `review-tests` catching the 8queens coverage lie was
real evidence it works, but it happened by accident, on someone else's
project. Fixtures make that kind of proof repeatable and deliberate,
instead of waiting for the next accident.

**This directory is excluded from the repo's own automated scans.** It
lives outside `skills/`, so `.github/workflows/ci.yml`'s
`audit-skill-security` job (which scans every `skills/*/SKILL.md` for the
exact patterns planted in the `audit-skills` fixture) never touches it. If
a fixture ever needs to sit inside `skills/` for a specific test, it must
be added to that job's exclusion list the same way
`skills/audit-skills/SKILL.md` already is — don't skip this, or CI breaks
permanently on a fixture that's supposed to be broken.

## Structure

Every skill or workflow template being tested gets its own folder,
always the same shape:

```
fixtures/
  <skill-name>/
    README.md              <- what's planted, why, how to run it
    <planted artifact(s)>  <- the deliberately broken file(s) or fixture project
    expected-findings.md   <- what a correct run should (and should not) catch
    results-log.md         <- every actual run against this fixture, logged
```

`results-log.md` is this fixture's own metrics substitute. A skill's real
`metrics/findings-log.md` records what it found in a real project;
fixtures don't have a real project, so `results-log.md` plays the same
role — proof the fixture was actually re-run, not just built once and
assumed to still pass. Same principle `project-memory` applies to a real
findings log, one level up.

## Currently covers

### Claude skills

| Skill | What's planted |
|-------|-----------------|
| `audit-skills` | A fake skill with one issue per detection category: injection phrasing, an unexplained `curl`, a `.env` read that contradicts its stated purpose, a write outside the project dir. A second fixture (`rephrased-injection-skill`) tests the Advanced model-classification section specifically, worded to evade the regex while saying the same thing. |
| `review-tests` | A coverage config that silently excludes half the source tree, plus tests with a tautological assertion, a wrong expected value, and a missing edge case |
| `project-memory` | An `AGENTS.md` checklist item that doesn't match reality, plus a findings-log row that should get archived |
| `sync-context` | An `AGENTS.md`/`copilot-instructions.md` pair where one file states a rule the other silently omits and then contradicts |
| `security-review` | A cookie-auth route with a real CSRF gap, a bearer-token route that looks the same but isn't (false-positive check), unsanitized rendering, and a hardcoded credential |
| `a11y` | Missing alt text, an unlabeled input, and low-contrast text, each paired with a correctly-marked-up equivalent (false-positive check) |

### GitHub Actions templates (`git/workflows/`)

| Template | What's planted |
|----------|-----------------|
| `prompt-injection-guard.yml` | Sample PR content: clean, an actual injection attempt, and a borderline legitimate PR that trips the filter anyway (demonstrating the workflow's documented false-positive tradeoff for real, not just claiming it) |
| `llm-review.yml` | Canned API responses (approve / concerns / needs-human / API error) for the parsing and blocking-decision logic — building this fixture caught and fixed a real bug in the workflow itself, see `llm-review/README.md` |

### This repo's own CI (`.github/workflows/ci.yml`)

| Job | What's planted |
|-----|-----------------|
| `skillspector-scan` | Three scenarios for NVIDIA SkillSpector, run `--no-llm`: a low-signal skill that stays under the DO_NOT_INSTALL threshold but still fails `audit-skill-security`'s grep job (the reason both jobs run), a clearly malicious skill that reliably scores CRITICAL and fails, and a baseline-suppression test proving a fingerprint binds a skill's whole file (not just the flagged line) and that suppression doesn't change the scoring-threshold gap — see `skillspector/README.md` |

Any skill, workflow template, or CI job making a specific, checkable
claim is a candidate for the next one.

## How to use any fixture here

1. Read that fixture's own `README.md` for what's planted and the exact
   command to run.
2. Run the skill against the fixture.
3. Compare the actual output against that fixture's `expected-findings.md`.
4. If something expected didn't get caught — or something *not* expected
   got flagged — that's a real bug in the skill, not a fixture problem.
   Fix the skill, not just this run.
5. Append the result to that fixture's `results-log.md`.
