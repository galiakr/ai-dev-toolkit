# `language-tokens` fixture

Planted CSVs for `skills/language-tokens/assets/generate.py` — the one
piece of executable code this toolkit ships inside a skill. Unlike the
other skill fixtures, what's under test here isn't an agent's judgment but
a script's behavior, so the check is fully deterministic and runs in CI.

## What's here

```
language-tokens/
  inputs/
    valid.csv                    <- nested keys, a 3-level key, {placeholders}, quoted commas, a TODO cell, a blank cell
    duplicate-key.csv            <- the same key twice: warn, later row wins, counted once
    collision-child-first.csv    <- nav.menu.open, then nav.menu (silently dropped the child before #7)
    collision-parent-first.csv   <- nav.menu, then nav.menu.open (always failed, but named only one key)
    header-traversal.csv         <- a language column named ../escaped (wrote outside the output folder before #8)
    header-duplicate.csv         <- en and EN as two language columns
  test_generate.py               <- runs the real generate.py on each input in a temp dir and checks the result
  expected-findings.md           <- what each input must (and must not) produce, and why
  results-log.md                 <- every real run
```

## How to run

```bash
python3 -I fixtures/language-tokens/test_generate.py
```

Standard library only, no install. CI runs it in the `validate-skills`
job and `.githooks/pre-push` runs it locally.

## The round trip is checked by meaning, not bytes

`--to-csv` sorts rows by key and strips whitespace, which is existing,
intended behavior. So the round-trip check compares what the CSV *says*
(same keys, same values per language, same descriptions) and that
regenerating JSON from the round-tripped CSV gives identical JSON — not
that the two CSV files are byte-identical.

## What building it confirmed

Run against `generate.py` as it was before issues #7 and #8 were fixed
(commit `d7fdb1f`), 11 of 25 checks fail — the two collision inputs, both
header inputs, and the duplicate-key count. Every valid-input and
round-trip check passes on both versions, so the fixes didn't change any
existing behavior. See `results-log.md`.
