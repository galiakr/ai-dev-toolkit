---
name: language-tokens
description: Set up a single, central place to hold all user-facing text ("language tokens") in a project instead of hard-coding strings in the code. Use this whenever a project needs internationalization / localization / i18n / translations / multi-language support, OR whenever someone wants one source of truth for UI copy so non-coders can edit wording without touching code. Trigger this even for single-language projects that want their text centralized rather than scattered as hard-coded strings. Also use when someone mentions "translation file", "language file", "copy deck", "string catalog", "locale", "adding a second language", or "let the content person edit the text".
---

# Language Tokens

## What this skill is for

Most projects start with user-facing text ("Save", "Welcome back", "Your order shipped") hard-coded directly in the code. This causes two problems:

1. **Adding a language means hunting for every string** scattered across the codebase.
2. **Only coders can change wording**, so a content person, translator, or manager has to file a ticket for every typo.

The fix is a **single source of truth for all UI text**, made of **tokens**. A token is a short, stable key (like `checkout.pay_button`) paired with the human text for each language. Code refers to the key; the actual words live in one place that a non-coder can edit.

This is worth doing **even for a single-language project** — it means all copy lives in one file a non-technical person can own, and adding a second language later becomes trivial instead of a rewrite.

## The two roles this supports

- **Non-coders** (content owners, translators, PMs) edit a friendly **spreadsheet / CSV** — one row per token, one column per language, plus a description column explaining where the text appears.
- **Coders** consume machine-friendly **JSON** — one file per language — through a tiny lookup helper.

A generator script converts between the two so nobody has to hand-edit JSON and nobody has to learn code. The CSV/spreadsheet is the source non-coders touch; the JSON is generated for the app.

## Steps

### Step 1 — Assess the project

Before creating anything, understand what exists:

- Is there already an i18n setup (folders like `locales/`, `i18n/`, files like `en.json`, or a library like i18next, vue-i18n, gettext, `.strings`, `.resx`, Android `strings.xml`)? If so, **adapt to it** rather than replacing it — extend the existing structure and offer to wire the spreadsheet workflow on top.
- How many languages today? Ask the user which languages they want now and which they might add later (use ISO codes like `en`, `es`, `fr`, `de`, `ja`).
- Roughly how many hard-coded strings exist, and where? A quick scan for quoted text in the UI layer gives a sense of scale. Do NOT try to migrate everything at once — set up the structure, seed it with a few real strings, and leave the bulk migration as a follow-up the user can do incrementally.

Confirm the plan with the user before writing files, especially the folder location and the language list.

### Step 2 — Create the central token store

Create a single folder to hold everything (default name `tokens/`, or match an existing convention). Put three things in it:

```
tokens/
├── tokens.csv          <- the source non-coders edit (one row per token)
├── generate.py         <- converts tokens.csv <-> per-language JSON
└── locales/            <- generated; coders/app read these (do not hand-edit)
    ├── en.json
    ├── es.json
    └── ...
```

Copy `assets/generate.py` into the project's token folder, and seed `tokens.csv` from `assets/tokens.template.csv` with a handful of real strings pulled from the project so the user sees their own text, not lorem ipsum.

**CSV format** (this is what the non-coder edits):

```csv
key,description,en,es
common.save,Save button used across all forms,Save,Guardar
common.cancel,Cancel button,Cancel,Cancelar
home.greeting,Greeting on the home page. {name} is filled in with the user's first name,"Welcome, {name}!","¡Bienvenido, {name}!"
```

Key rules to explain to the user:

- **`key`** is a stable ID grouped by area with dots (`checkout.pay_button`). Coders reference this; it should not change once code uses it.
- **`description`** tells the translator/editor where the text appears and what any placeholders mean. This context dramatically improves translation quality.
- **One column per language**, header = ISO code. Leave a cell blank if a translation isn't ready yet.
- **Placeholders** use `{name}` style so the same slot survives translation. Explain that the words around the placeholder can move but `{name}` must stay.
- If a cell contains a comma, quote/escape it (standard spreadsheet behavior — Excel/Google Sheets do this automatically on export).

For a non-coder who prefers a spreadsheet app: they can open/edit `tokens.csv` in Excel or Google Sheets and "Save as CSV" — no code needed. See `references/for-non-coders.md` for a plain-language guide to hand them.

### Step 3 — Generate the JSON

Run the generator to turn the CSV into per-language JSON the app reads:

```bash
python tokens/generate.py tokens/tokens.csv --out tokens/locales
```

This writes `tokens/locales/en.json`, `es.json`, etc. Dotted keys become nested objects, so `checkout.pay_button` becomes `{"checkout": {"pay_button": "..."}}` — the shape most i18n libraries expect. It also reports missing translations so nothing silently ships blank.

The reverse direction also works (useful when code adds new keys and you want to hand a fresh CSV back to the content owner):

```bash
python tokens/generate.py tokens/locales --to-csv tokens/tokens.csv
```

### Step 4 — Wire the code to read tokens (coder step)

Replace hard-coded strings with lookups by key. The exact call depends on the stack — detect it and match its conventions. `references/consuming-tokens.md` has concrete patterns for i18next/React, Vue, plain JS, Python, and mobile, plus a minimal zero-dependency `t()` helper for projects with no i18n library.

The universal shape is:

- Load the JSON for the active language.
- Replace `"Save"` in code with `t("common.save")`.
- Fill placeholders at call time: `t("home.greeting", { name: user.firstName })`.

Migrate incrementally — every string moved to a token is a win; there's no need to convert the whole app in one pass.

### Step 5 — Explain the ongoing loop

Leave the user with the simple cycle:

1. Content owner edits `tokens.csv` (in Excel/Sheets or any text editor).
2. Someone runs `python tokens/generate.py tokens/tokens.csv --out tokens/locales`.
3. The app now shows the updated text. Adding a language = add one column and regenerate.

If the project has a build step, suggest wiring the generate command into it so JSON is never stale. Offer to add it, but don't assume the build setup — ask.

### Step 6 — Log the result

Append one row to `metrics/findings-log.md`: date, project, `language-tokens`, an outcome (`Action taken`), and one sentence covering what was centralized — how many strings migrated, how many languages, and whether an existing i18n setup was extended rather than replaced.

## Output Format

```
## Language Tokens — set up in `tokens/`

- Existing setup: none found (new `tokens/` folder) | extended existing `src/locales/` (i18next)
- Languages: en, es (es: 3 missing/TODO — need a human translator: common.cancel, home.greeting, checkout.pay_button)
- Strings migrated this pass: 12 of ~80 found in src/components/ — the rest can move incrementally
- Code wired: `t()` helper in src/lib/t.js; Header.jsx and Checkout.jsx now use it
- To update text: edit tokens/tokens.csv, then run
  python tokens/generate.py tokens/tokens.csv --out tokens/locales
```

If the project already has every user-facing string centralized: `Text is already centralized in <location> — no changes made.`

## Notes

- Keep JSON out of manual editing. The CSV is the source of truth; JSON is a build artifact. If the user insists on JSON-only (some coder-heavy teams prefer this), that's fine — the generator's `--to-csv` direction lets non-coders still get a spreadsheet view on demand.
- Don't over-engineer. A small project needs one CSV and the generator, nothing more. Only reach for a full i18n library when the project needs plural rules, date/number formatting, or language auto-detection — and say so rather than adding dependencies silently.
- Never invent translations. If asked to fill a language column and you're not confident, mark cells as blank/`TODO` and tell the user which need a human translator.

See `references/consuming-tokens.md` for framework-specific code and `references/for-non-coders.md` for the guide to hand to content owners.
