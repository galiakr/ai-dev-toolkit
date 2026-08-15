# `skillspector-scan` fixtures

Deliberately planted `SKILL.md`/script examples for verifying
`.github/workflows/ci.yml`'s `skillspector-scan` job — and the specific
claims made in that job's own comment and in `SECURITY.md`'s
`skillspector-scan` section — actually hold, rather than reading
plausibly and being trusted on that alone. See `../README.md` for what's
true across every fixture in this repo (the CI exclusion, the
never-log-to-`metrics/findings-log.md` rule); this file covers what's
specific to testing `skillspector-scan`.

## Structure

```
skillspector/
  results-log.md                     <- every fixture run, matched or not
  weak-signal-skill/                 <- proves a single ambiguous bad line doesn't cross the DO_NOT_INSTALL threshold under --no-llm, but audit-skill-security's grep job still catches it
    SKILL.md
    expected-findings.md
  strong-signal-skill/               <- proves the CI job's fail path works: a clearly malicious skill (credential harvesting + network-controlled eval) does cross the threshold and fail
    SKILL.md
    scripts/collect.py
    expected-findings.md
  baseline-suppression-skill/        <- tests the .skillspector-baseline.yaml mechanism itself: clean suppression, fingerprint invalidation on any file edit, and whether a stale baseline still blocks a severe addition
    SKILL.md
    .skillspector-baseline.yaml
    HOW-TO-TEST.md                   <- three-run procedure, same shape as audit-skills/adopted-skill-simulation/HOW-TO-TEST.md
```

## Why three scenarios, not one

Each proves a different, independently-falsifiable claim this repo makes
about `skillspector-scan`:

1. **`weak-signal-skill`** — the reason the job runs *alongside*
   `audit-skill-security`'s grep job rather than replacing it.
   `--no-llm` static scoring has a real recall gap on low-signal content;
   a plain grep match has no such gap.
2. **`strong-signal-skill`** — the reason (1) isn't "SkillSpector doesn't
   work." A clearly malicious skill scores 100/CRITICAL and fails,
   reliably, and catches categories (AST/taint analysis) the grep job
   structurally cannot attempt at all.
3. **`baseline-suppression-skill`** — the suppression mechanism itself
   has two non-obvious behaviors (fingerprints bind the whole file, not
   just the flagged line; suppression doesn't change the scoring
   threshold gap from (1)) that are easy to assume don't exist until
   tested.

## How to use

1. Read the fixture's own `expected-findings.md` (or `HOW-TO-TEST.md` for
   `baseline-suppression-skill`, which needs a multi-run procedure).
2. Run `skillspector scan <fixture>/ --no-llm` (add `--baseline` where the
   fixture has one) exactly as that file describes.
3. Compare the actual score, severity, recommendation, exit code, and
   specific rule IDs against what's documented. For
   `baseline-suppression-skill`, also compare `suppressed_count`.
4. If something expected didn't happen — or something unexpected did —
   that's either a real change in SkillSpector's behavior (it's pinned to
   `v2.9.4` in `ci.yml`; a version bump is exactly when this should be
   re-run) or a bug in how the CI job is wired. Either way, don't just
   re-word the docs to match — figure out which one it is.
5. Append a row to `results-log.md`.

## A contamination bug this fixture-building process found (and fixed) twice

Building `weak-signal-skill/` originally included an explanatory
`# FIXTURE` header comment that spelled out the planted pattern in prose
("an exfil-shaped `curl | bash`... a literal concealment phrase") —
SkillSpector's static analysis picked up on the *explanation*, not just
the planted line, and scored the file 78/DO_NOT_INSTALL instead of the
40/CAUTION the actual planted content produces on its own. Fixed by
trimming the header to a one-line pointer at this README instead of
describing the pattern. The exact same bug showed up again independently
while first drafting `baseline-suppression-skill/HOW-TO-TEST.md`'s test
procedure, which instructed copying the whole fixture folder — including
`HOW-TO-TEST.md` itself, which also quotes dangerous patterns to explain
the test — into the scan target. Fixed by copying only `SKILL.md` and
`.skillspector-baseline.yaml`. Both are the same root cause
`fixtures/audit-skills/rephrased-injection-skill/` already ran into once:
a fixture's own explanatory text is itself untrusted input to whatever
it's testing, and has to be kept out of the scan target or written to not
reproduce the pattern it's describing.
