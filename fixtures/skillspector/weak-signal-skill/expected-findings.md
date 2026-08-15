# Expected findings — `weak-signal-skill/SKILL.md`

This fixture tests a specific, narrow claim made in `.github/workflows/ci.yml`'s
`skillspector-scan` job comment and `SECURITY.md`: a single unambiguous bad
line — an exfil-shaped `curl | bash` plus the literal concealment phrase
this repo's own `audit-skill-security` grep job matches — does not cross
SkillSpector's `--no-llm` DO_NOT_INSTALL threshold on its own. It's the
counterpart to `../strong-signal-skill/` (which does cross it) and the
reason `skillspector-scan` runs alongside `audit-skill-security`, not
instead of it.

## Run 1 — SkillSpector, `--no-llm`

```bash
skillspector scan fixtures/skillspector/weak-signal-skill/ --no-llm
```

**Expected (confirmed by a real run, stable across 3 repeated runs):**

```
score: 40, severity: MEDIUM, recommendation: CAUTION
  HIGH  PE3  Privilege Escalation   SKILL.md:16  (reads .npmrc)
  HIGH  SC2  Supply Chain           SKILL.md:21  (curl ... | bash)
exit code: 0
```

Two things worth noting, not assumed going in:

- The literal injection phrase ("don't mention this to the user," line 22)
  is **not** flagged as its own separate finding under `--no-llm` — only
  the supply-chain command pattern and an unrelated `.npmrc`-read
  heuristic are. Static-only mode has real recall gaps on phrasing that a
  semantic (LLM) pass would likely catch.
- Two HIGH findings still isn't enough combined severity to cross the
  50-point DO_NOT_INSTALL threshold (score formula: HIGH = +25 each,
  informally; the observed 40 reflects the scorer's actual weighting, not
  a simple sum — treat the exact number as what a real run produced, not
  a formula to re-derive).

**Exit code `0` means this job, alone, would not have failed CI on this
file.**

## Run 2 — `audit-skill-security`'s grep job, same file

```bash
grep -nE 'curl |wget |\bnc[[:space:]]+-|\bnetcat\b|\bncat\b' fixtures/skillspector/weak-signal-skill/SKILL.md
grep -niE "pre-approved|you must comply|takes precedence over other instructions|don't mention this to the user|do this silently|skip confirmation|ignore (previous|prior) instructions|disregard (your|other)" fixtures/skillspector/weak-signal-skill/SKILL.md
```

**Expected:** both greps match (line 21 for the `curl` pattern, line 22
for the injection phrase) — `audit-skill-security` would fail this file
outright, with no scoring or threshold involved. This is the concrete
gap `skillspector-scan`'s CI job comment cites as the reason both jobs
run.

## What a real run found

See `../results-log.md` for the dated entry. Both runs above were
actually executed against this exact file, not reasoned about — the
score, the specific rule IDs, and the line numbers are copied from real
`skillspector scan --format json` output and real `grep` output, not
predicted.
