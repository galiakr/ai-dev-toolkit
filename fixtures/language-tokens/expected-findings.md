# Expected findings — `language-tokens` fixture

What `generate.py` must do with each input. `test_generate.py` checks
every row; if one fails, that's a bug in `generate.py`, not in the fixture.

| Input | Expected exit | Expected result |
|---|---|---|
| `valid.csv` → JSON | 0 | Exactly `en.json` and `es.json`. Dotted keys nest (`home.title.main` → `{"home": {"title": {"main": ...}}}`). `{name}` placeholders and quoted commas survive unchanged. The blank `es` cell is left out of `es.json`, not written as `""`. The `TODO` cell is written through as `"TODO"`, a visible placeholder. Output reports `es: 2 missing/TODO -> common.cancel, home.title.main` and `en: complete`. |
| `valid.csv` → JSON → CSV → JSON | 0 | The round-tripped CSV has the same keys, values, and descriptions as the original (compared by meaning: `--to-csv` sorts and strips whitespace by design). JSON regenerated from it is identical to the first pass. |
| `duplicate-key.csv` | 0 | Warns `duplicate key 'common.save' — later row wins`. `en.json` holds `Save changes`. Reports `1 tokens`, not 2. |
| `collision-child-first.csv` | non-zero | Error names both `'nav.menu'` and `'nav.menu.open'`. **No files written.** Before #7 this exited 0 and silently dropped `nav.menu.open`, reporting `en: complete`. |
| `collision-parent-first.csv` | non-zero | Same error as above, regardless of row order. **No files written.** |
| `header-traversal.csv` | non-zero | Error: `'../escaped' isn't a language code`. **Nothing written anywhere** — not in the output folder, not beside it. Before #8 this wrote `escaped.json` one level above the output folder. |
| `header-duplicate.csv` | non-zero | Error: `'EN' appears more than once`. **Nothing written.** |

**Not expected:** any input that fails should leave a partial output
behind. The checks run before anything is written, so "fails" always means
"fails with nothing written."
