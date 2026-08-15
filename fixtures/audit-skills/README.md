# `audit-skills` fixtures

Deliberately broken (or deliberately fine-looking) `SKILL.md` files for
verifying `audit-skills` catches what it claims to catch — and doesn't
flag what it shouldn't. See `../README.md` for what's true across every
skill's fixtures (the CI exclusion, the never-log-to-`metrics/findings-log.md`
rule); this file covers what's specific to testing `audit-skills`.

## Structure

```
audit-skills/
  results-log.md                   <- every fixture run, matched or not — see "Logging results" below
  planted-bad-skill/               <- one issue per detection category (command pattern, injection, mismatch, scope)
    SKILL.md
    expected-findings.md
  obfuscated-commands-skill/       <- the command-pattern sub-checks planted-bad-skill doesn't cover: sudo, rm -rf, base64/eval
    SKILL.md
    expected-findings.md
  legitimate-lookalike-skill/      <- false-positive check: curl + .env read that ARE legitimate — expects zero findings
    SKILL.md
    expected-findings.md
  adopted-skill-simulation/        <- provenance-hash tracking (step 6) — needs a two-run procedure, see its HOW-TO-TEST.md
    SKILL.md
    HOW-TO-TEST.md
  rephrased-injection-skill/       <- tests the Advanced (optional) model-classification section, not step 3's regex — worded to say the same thing without matching the pattern list
    SKILL.md
    expected-findings.md
```

Add a scenario folder whenever a detection category (or a sub-pattern
within one) hasn't been exercised yet — `obfuscated-commands-skill/`
exists because `planted-bad-skill/` only ever planted the `curl`/`.env`
sub-patterns of the command-pattern category, leaving `sudo`, `rm -rf`,
and base64/`eval` obfuscation untested.

## How to use

1. Run `audit-skills` against the fixture's `SKILL.md` directly — every
   fixture here is deliberately outside the default `skills/*/SKILL.md`
   scan path, so it has to be pointed at explicitly.
2. Compare the actual output against that fixture's `expected-findings.md`
   (or follow `HOW-TO-TEST.md` for `adopted-skill-simulation/`, which
   needs a two-run procedure against a throwaway copy — provenance
   tracking can't be tested with a single run against a file that's never
   had a baseline).
3. If something expected didn't get caught — or something *not* expected
   did (see `legitimate-lookalike-skill/`) — that's a real bug in
   `audit-skills`. Fix the skill, not just this one run.
4. Add a row to `results-log.md`.

## Running each fixture

| Fixture | What to ask | Expect |
|---------|--------------|--------|
| `planted-bad-skill` | "Run audit-skills against `fixtures/audit-skills/planted-bad-skill/SKILL.md` directly." | 4 findings — see `planted-bad-skill/expected-findings.md` |
| `obfuscated-commands-skill` | "Run audit-skills against `fixtures/audit-skills/obfuscated-commands-skill/SKILL.md` directly." | 3 findings — see `obfuscated-commands-skill/expected-findings.md` |
| `legitimate-lookalike-skill` | "Run audit-skills against `fixtures/audit-skills/legitimate-lookalike-skill/SKILL.md` directly." | 0 findings — see `legitimate-lookalike-skill/expected-findings.md` |
| `adopted-skill-simulation` | Not a single ask — follow `adopted-skill-simulation/HOW-TO-TEST.md`'s two-run procedure against a throwaway `/tmp` copy. | Run 1: baseline hash recorded (INFO). Run 2 (after a planted change): hash-mismatch flagged. |
| `rephrased-injection-skill` | Run the mechanical scan first (expect 0), then run the Advanced classification pass per `SKILL.md`'s Advanced section — see `rephrased-injection-skill/expected-findings.md` for the exact prompt shape. | Mechanical: 0 findings. Model classification: 3 findings. |

## Logging results

Append one row to `results-log.md` after every run: date, which fixture,
whether the actual output matched what `expected-findings.md` (or
`HOW-TO-TEST.md`) says it should, and enough specific detail — which
findings, at what severity — to check the claim later without re-running
it. If a run doesn't match, that's a real bug: fix `audit-skills`, re-run
*every* fixture here (a fix for one detection category can regress
another), and add a new row rather than editing the old one — the history
of "it broke, then it was fixed" is worth keeping.
