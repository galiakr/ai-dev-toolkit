# Expected findings — `strong-signal-skill/`

This fixture is the counterpart to `../weak-signal-skill/`: it proves
`skillspector-scan`'s CI exit-code gate actually fails when a skill
genuinely deserves it, not just that the job passes clean skills and lets
a low-signal one through. `scripts/collect.py` stacks credential
harvesting, network exfiltration, and a network-controlled `eval` chain —
things `audit-skill-security`'s grep job has no equivalent for at all
(no AST parsing, no taint tracking), which is the other half of why
`skillspector-scan` earns its place alongside the grep job rather than
being redundant with it.

## Run

```bash
skillspector scan fixtures/skillspector/strong-signal-skill/ --no-llm
```

**Expected (confirmed by a real run):**

```
score: 100, severity: CRITICAL, recommendation: DO_NOT_INSTALL
  CRITICAL  AST8  Dangerous Code Execution   scripts/collect.py:18  (exec/eval + dynamic source)
  HIGH      AST2  Dangerous Code Execution   scripts/collect.py:18  (eval() call)
  MEDIUM    AST6  Dangerous Code Execution   scripts/collect.py:18  (compile() call)
  CRITICAL  TT5   Data Flow                  scripts/collect.py:18  (network input -> exec/eval)
  HIGH      E2    Data Exfiltration          scripts/collect.py:11  (os.environ harvested)
  MEDIUM    E1    Data Exfiltration          scripts/collect.py:12,17  (POST/GET to external domain, x4)
  MEDIUM    LP3   MCP Least Privilege        SKILL.md:1  (same permissions-field heuristic every skill in this repo trips)
  HIGH      PE3   Privilege Escalation       SKILL.md:3  (frontmatter mentions .env-adjacent context)
exit code: 1
```

None of the AST8/AST2/AST6/TT5/E2 findings are things
`audit-skill-security`'s grep job could catch — they require parsing
`scripts/collect.py` as Python (AST) and tracing a value from
`os.environ`/a network response into `requests.post`/`eval` (taint
tracking), not matching a fixed string. This is the concrete evidence for
the other half of `skillspector-scan`'s reason to exist: not just "catches
what the grep job also catches" (see `weak-signal-skill/`) but "catches a
category the grep job structurally cannot."

**Exit code `1` confirms the job's fail path works** — `skillspector-scan`
is not a check that only ever passes.

## What a real run found

See `../results-log.md` for the dated entry. The score, rule IDs, and
line numbers above are copied from real `skillspector scan --format json`
output against this exact fixture, not predicted.
