# Results Log — `language-tokens` fixture

Every real run of `test_generate.py` gets a row. CI runs it on every push
too, but a CI run isn't logged here; add a row when `generate.py` or the
fixture changes, or when a run turns up something worth keeping.

**This is not `metrics/findings-log.md`.** That file never gets real rows
in this repo (see `AGENTS.md`). This log records whether the check itself
still works.

| Date | Run against | Matched expected? | Detail | Ref |
|------|-------------|-------------------|--------|-----|
| 2026-11-15 | `generate.py` at `f2e55ec` (after #7 and #8) | Yes, 25/25 | Every input behaved as `expected-findings.md` describes. Both collision orders fail with both keys named and nothing written; `../escaped` and `en,EN` headers fail before the output folder is created; valid input, TODO/blank handling, duplicate-key warning, and the CSV → JSON → CSV → JSON round trip all match. | #14 |
| 2026-11-15 | `generate.py` at `d7fdb1f` (before #7 and #8), same fixture | No, 11/25 failed, as intended | Confirms the fixture catches the bugs it was built for. `collision-child-first.csv` exited 0 and silently dropped `nav.menu.open`. `collision-parent-first.csv` failed but didn't name both keys. `header-traversal.csv` wrote `escaped.json` outside the project folder. `header-duplicate.csv` was accepted. `duplicate-key.csv` reported 2 tokens instead of 1. All 14 valid-input and round-trip checks passed on both versions, so the fixes changed no existing behavior. | #7, #8 |
