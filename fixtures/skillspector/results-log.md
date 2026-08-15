# Fixture Results Log

Runs of `skillspector-scan` (and the standalone `skillspector` CLI,
`v2.9.4`) against its own fixtures in this folder — proof that the claims
in `.github/workflows/ci.yml`'s `skillspector-scan` job comment and
`SECURITY.md`'s `skillspector-scan` section hold, checked against each
fixture's `expected-findings.md` (or `HOW-TO-TEST.md` for
`baseline-suppression-skill`). Re-run every fixture and add a row
whenever the pinned SkillSpector version changes or the CI job's logic
changes, so drift gets caught the same way `expected-findings.md` is
meant to catch it in a single run.

**This is not `metrics/findings-log.md`.** That file never gets real rows
in this repo (see `AGENTS.md`) — a fixture run isn't a finding about a
real project, it's a finding about whether the check *itself* still
works. Same reasoning `fixtures/audit-skills/results-log.md` states for
itself.

## Log

| Date | Fixture | Outcome | Detail | Ref |
|------|---------|---------|--------|-----|
| 2026-08-15 | `weak-signal-skill` | Matched expected | `skillspector scan --no-llm`: score 40, MEDIUM, CAUTION, exit 0 — flagged PE3 (`.npmrc` read, line 16) and SC2 (`curl \| bash`, line 21); the literal injection phrase on line 22 was *not* flagged as its own finding under `--no-llm`. Same file against `audit-skill-security`'s two grep patterns: both matched (line 21 command pattern, line 22 injection phrasing) — that job would fail this file unconditionally. Confirmed stable across 3 repeated `skillspector` runs (identical score and findings each time). First draft of this fixture's header comment quoted the planted pattern in prose and inflated the score to 78/DO_NOT_INSTALL — fixed by trimming the header; see `../README.md`'s contamination note. | `weak-signal-skill/expected-findings.md` |
| 2026-08-15 | `strong-signal-skill` | Matched expected | `skillspector scan --no-llm`: score 100, CRITICAL, DO_NOT_INSTALL, exit 1. Findings included AST8 (dangerous exec chain), AST2 (`eval`), AST6 (`compile`), TT5 (network input to exec/eval — taint tracking), E2 (env-var harvesting), E1 (external POST/GET, x4), plus LP3/PE3 on `SKILL.md` itself. None of the AST/TT/E2 findings have an `audit-skill-security` grep equivalent — confirms the job catches a category the grep job structurally cannot. | `strong-signal-skill/expected-findings.md` |
| 2026-08-15 | `baseline-suppression-skill` | Matched expected | Full 3-claim procedure run against a throwaway `/tmp` copy, `SKILL.md` + `.skillspector-baseline.yaml` only (copying `HOW-TO-TEST.md` itself into the scan target on the first attempt reproduced the same contamination bug found in `weak-signal-skill` — fixed by copying only the two real skill files). **Claim 1** (clean baseline): score 0, SAFE, exit 0, top-level `suppressed_count: 1`, 0 active issues — without `--baseline`, same file scores 15/SAFE with 1 active PE3. **Claim 2** (moderate drift, stale baseline): after appending one unrelated `curl \| bash` line, re-scanned with the *same* unedited baseline — score 46, MEDIUM, CAUTION, exit 0, `suppressed_count: 0` (the original PE3 finding came back **active**, not suppressed — confirms a fingerprint binds the whole file, not just the flagged line), plus 2 new real findings (E1 x2, SC2) on the added line. Combined severity still landed under the block threshold — exit stayed 0. **Claim 3** (severe drift, same stale baseline): restored the original `SKILL.md`, added `strong-signal-skill/scripts/collect.py` instead — score 100, CRITICAL, DO_NOT_INSTALL, exit 1, `suppressed_count: 0`. Confirms a stale/mismatched baseline does not prevent a clearly severe addition from failing, even though it didn't prevent a moderate one from passing in claim 2. | `baseline-suppression-skill/HOW-TO-TEST.md` |

## How to add a row

Same shape as `metrics/findings-log.md`: date, which fixture, whether the
actual output matched what its `expected-findings.md`/`HOW-TO-TEST.md`
says it should, and enough detail to check the claim later without
re-running it — name the specific scores, rule IDs, and exit codes, not
just "passed."

**If a run ever says "Not matched," that's a real change worth
investigating** — either SkillSpector's behavior shifted (check the
pinned version in `ci.yml` against what's installed) or the CI job's
wiring has a bug. Fix whichever it is, re-run every fixture in this
folder (a fix for one scenario can change another's numbers), and add a
new row rather than editing the old one — the history of "it changed,
here's what changed" is worth keeping, the same reason
`metrics/findings-log.md` archives instead of overwrites.
