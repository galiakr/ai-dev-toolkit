#!/usr/bin/env python3
"""
generate.py — convert the language-token spreadsheet (CSV) into per-language
JSON files that an app can read, and back again.

The CSV is the source of truth that non-coders edit. The JSON files are
generated build artifacts that code reads. Nobody should hand-edit the JSON.

CSV shape (first two columns are fixed, then one column per language):

    key,description,en,es,fr
    common.save,Save button,Save,Guardar,Enregistrer
    home.greeting,"Home greeting, {name} = first name","Hi, {name}!","¡Hola, {name}!","Salut, {name} !"

Dotted keys become nested JSON:
    common.save            -> {"common": {"save": "Save"}}
    checkout.pay_button    -> {"checkout": {"pay_button": "..."}}

Usage:
    # CSV -> one JSON file per language
    python generate.py tokens.csv --out locales

    # JSON folder -> a single CSV (round-trip, e.g. after code adds new keys)
    python generate.py locales --to-csv tokens.csv

Requires only the Python standard library (Python 3.7+). No pip install needed.
"""

import argparse
import csv
import json
import os
import re
import sys

RESERVED = {"key", "description"}

# Language column headers become output filenames (<header>.json), so they
# must look like a locale code — en, es, pt-BR, zh-Hant, sr_Latn_RS — and
# nothing else. Anything with a path separator or "..", or just a typo like
# "english ", is rejected before a single file is written.
LOCALE_RE = re.compile(r"^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$")


def csv_to_json(csv_path, out_dir):
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            sys.exit(f"error: {csv_path} is empty.")
        fields = [c.strip() for c in reader.fieldnames]
        if "key" not in fields:
            sys.exit("error: CSV must have a 'key' column.")
        languages = [c for c in fields if c and c not in RESERVED]
        if not languages:
            sys.exit("error: CSV has no language columns (need at least one, e.g. 'en').")
        _validate_languages(languages)

        rows = []
        seen = set()
        for raw in reader:
            row = {(k.strip() if k else k): (v if v is not None else "") for k, v in raw.items()}
            key = (row.get("key") or "").strip()
            if not key:
                continue
            if key in seen:
                print(f"warning: duplicate key '{key}' — later row wins.")
            seen.add(key)
            rows.append((key, row))

    # Check the whole key set before building anything, so the result
    # doesn't depend on row order: 'a' + 'a.b' would otherwise either fail
    # or silently drop 'a.b', depending on which row came first.
    collisions = _group_collisions(seen)
    if collisions:
        for parent, child in collisions:
            print(f"error: '{parent}' is used both as a value and as a group "
                  f"(it's also the start of '{child}').", file=sys.stderr)
        sys.exit(f"error: {len(collisions)} key collision(s); rename one side of each "
                 f"(e.g. '{collisions[0][0]}' -> '{collisions[0][0]}.label'). Nothing was written.")

    # lang -> nested dict
    trees = {lang: {} for lang in languages}
    missing = {lang: [] for lang in languages}
    for key, row in rows:
        for lang in languages:
            value = (row.get(lang) or "").strip()
            if value == "" or value.upper() == "TODO":
                missing[lang].append(key)
                if value == "":
                    continue
            _set_nested(trees[lang], key, value)

    os.makedirs(out_dir, exist_ok=True)
    out_real = os.path.realpath(out_dir)
    for lang in languages:
        path = os.path.join(out_dir, f"{lang}.json")
        # Backstop for _validate_languages: never write outside out_dir.
        if os.path.dirname(os.path.realpath(path)) != out_real:
            sys.exit(f"error: refusing to write {path!r} outside {out_dir!r}.")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(trees[lang], f, ensure_ascii=False, indent=2, sort_keys=True)
            f.write("\n")
        print(f"wrote {path}")

    print(f"\n{len(seen)} tokens across {len(languages)} language(s).")
    for lang in languages:
        if missing[lang]:
            print(f"  {lang}: {len(missing[lang])} missing/TODO -> "
                  + ", ".join(missing[lang][:8])
                  + (" ..." if len(missing[lang]) > 8 else ""))
        else:
            print(f"  {lang}: complete")


def json_to_csv(in_dir, csv_path):
    files = [f for f in sorted(os.listdir(in_dir)) if f.endswith(".json")]
    if not files:
        sys.exit(f"error: no .json files found in {in_dir}")
    languages = [os.path.splitext(f)[0] for f in files]

    # key -> {lang: value}
    table = {}
    for fname, lang in zip(files, languages):
        with open(os.path.join(in_dir, fname), encoding="utf-8") as f:
            data = json.load(f)
        for key, value in _flatten(data):
            table.setdefault(key, {})[lang] = value

    # Preserve descriptions if the target CSV already exists.
    descriptions = {}
    if os.path.exists(csv_path):
        with open(csv_path, newline="", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                k = (row.get("key") or "").strip()
                if k:
                    descriptions[k] = row.get("description", "")

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["key", "description"] + languages)
        for key in sorted(table):
            writer.writerow(
                [key, descriptions.get(key, "")]
                + [table[key].get(lang, "") for lang in languages]
            )
    print(f"wrote {csv_path} ({len(table)} tokens, {len(languages)} language(s)).")


def _validate_languages(languages):
    """Exit (before anything is written) if any language header is unsafe or duplicated."""
    problems = []
    for lang in languages:
        if not LOCALE_RE.match(lang):
            problems.append(f"'{lang}' isn't a language code (expected e.g. en, es, pt-BR, zh-Hant)")
    seen = set()
    for lang in languages:
        if lang.lower() in seen:
            problems.append(f"'{lang}' appears more than once (one column per language)")
        seen.add(lang.lower())
    if problems:
        for p in problems:
            print(f"error: language column {p}.", file=sys.stderr)
        sys.exit(f"error: {len(problems)} bad language column header(s). Nothing was written.")


def _group_collisions(keys):
    """(parent, child) pairs where 'parent' is a key and also a group prefix of 'child'."""
    found = []
    for key in sorted(keys):
        parts = key.split(".")
        for i in range(1, len(parts)):
            prefix = ".".join(parts[:i])
            if prefix in keys:
                found.append((prefix, key))
    return found


def _set_nested(tree, dotted_key, value):
    parts = dotted_key.split(".")
    node = tree
    for part in parts[:-1]:
        node = node.setdefault(part, {})
        if not isinstance(node, dict):
            sys.exit(f"error: key collision at '{part}' in '{dotted_key}' "
                     f"(a key is used both as a value and as a group).")
    if isinstance(node.get(parts[-1]), dict):
        # Backstop: _group_collisions should already have caught this.
        sys.exit(f"error: key collision at '{dotted_key}' "
                 f"(a key is used both as a value and as a group).")
    node[parts[-1]] = value


def _flatten(data, prefix=""):
    for k, v in data.items():
        full = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            yield from _flatten(v, full)
        else:
            yield full, v


def main():
    p = argparse.ArgumentParser(description="Convert language tokens between CSV and JSON.")
    p.add_argument("source", help="Path to the CSV (to make JSON) or the JSON folder (to make CSV).")
    p.add_argument("--out", help="Output folder for generated JSON (CSV -> JSON mode).")
    p.add_argument("--to-csv", help="Output CSV path (JSON folder -> CSV mode).")
    args = p.parse_args()

    if args.to_csv:
        json_to_csv(args.source, args.to_csv)
    elif args.out:
        csv_to_json(args.source, args.out)
    else:
        p.error("choose a direction: --out <folder> (CSV->JSON) or --to-csv <file> (JSON->CSV).")


if __name__ == "__main__":
    main()
