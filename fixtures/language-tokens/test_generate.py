#!/usr/bin/env python3
"""
Regression checks for skills/language-tokens/assets/generate.py, run against
the planted CSVs in inputs/. Standard library only, deterministic, and every
run happens in a throwaway temp directory.

    python3 -I fixtures/language-tokens/test_generate.py

Expected outcomes and why each input exists: expected-findings.md.
Runs in CI (validate-skills) and in .githooks/pre-push.
"""

import csv
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GENERATE = os.path.join(ROOT, "skills", "language-tokens", "assets", "generate.py")
INPUTS = os.path.join(HERE, "inputs")

failures = 0


def check(desc, ok, detail=""):
    global failures
    if ok:
        print(f"  ok    {desc}")
    else:
        failures += 1
        print(f"  FAIL  {desc}" + (f"\n          {detail}" if detail else ""))


def run(*args, cwd):
    p = subprocess.run([sys.executable, "-I", GENERATE, *args], cwd=cwd,
                       capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def files_under(path):
    found = []
    for base, _, names in os.walk(path):
        found += [os.path.relpath(os.path.join(base, n), path) for n in names]
    return sorted(found)


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def read_csv(path):
    """key -> {column: value}, whitespace-stripped — the CSV's meaning, not its bytes."""
    with open(path, newline="", encoding="utf-8-sig") as f:
        return {r["key"].strip(): {k.strip(): (v or "").strip() for k, v in r.items()}
                for r in csv.DictReader(f) if (r.get("key") or "").strip()}


def fresh(name):
    """Temp dir containing a copy of inputs/<name>, and nothing else."""
    d = tempfile.mkdtemp()
    shutil.copy(os.path.join(INPUTS, name), d)
    return d


print("Valid input: nested keys, placeholders, quoted commas, TODO and blank cells")
d = fresh("valid.csv")
code, out = run("valid.csv", "--out", "locales", cwd=d)
check("exits 0", code == 0, out)
check("writes exactly en.json and es.json", files_under(os.path.join(d, "locales")) == ["en.json", "es.json"],
      str(files_under(d)))
en, es = load(os.path.join(d, "locales", "en.json")), load(os.path.join(d, "locales", "es.json"))
check("dotted keys become nested objects",
      en == {"checkout": {"pay_button": "Pay now"},
             "common": {"cancel": "Cancel", "save": "Save"},
             "home": {"greeting": "Welcome, {name}!", "title": {"main": "Home"}}}, json.dumps(en))
check("placeholders and quoted commas survive", es["home"]["greeting"] == "¡Bienvenido, {name}!")
check("a blank cell is left out, not written as \"\"", "main" not in es["home"].get("title", {}), json.dumps(es))
check("TODO is written through as a visible placeholder", es["common"]["cancel"] == "TODO")
check("missing/TODO cells are reported per language",
      "es: 2 missing/TODO -> common.cancel, home.title.main" in out and "en: complete" in out, out)

print("Round trip: CSV -> JSON -> CSV keeps the meaning (and descriptions)")
shutil.copy(os.path.join(d, "valid.csv"), os.path.join(d, "roundtrip.csv"))
code, out = run("locales", "--to-csv", "roundtrip.csv", cwd=d)
check("--to-csv exits 0", code == 0, out)
before, after = read_csv(os.path.join(d, "valid.csv")), read_csv(os.path.join(d, "roundtrip.csv"))
check("same keys, same values, same descriptions", before == after,
      f"before={before}\n          after={after}")
code, out = run("roundtrip.csv", "--out", "locales2", cwd=d)
check("regenerated JSON is identical to the first pass",
      code == 0 and load(os.path.join(d, "locales2", "en.json")) == en
      and load(os.path.join(d, "locales2", "es.json")) == es, out)
shutil.rmtree(d)

print("Duplicate key: warns, later row wins")
d = fresh("duplicate-key.csv")
code, out = run("duplicate-key.csv", "--out", "locales", cwd=d)
check("exits 0 with a warning naming the key", code == 0 and "duplicate key 'common.save'" in out, out)
check("later row wins", load(os.path.join(d, "locales", "en.json")) == {"common": {"save": "Save changes"}})
check("counted once", "1 tokens across 1 language(s)" in out, out)
shutil.rmtree(d)

print("Key used as both a value and a group — must fail in either row order (#7)")
for name in ("collision-child-first.csv", "collision-parent-first.csv"):
    d = fresh(name)
    code, out = run(name, "--out", "locales", cwd=d)
    check(f"{name}: fails", code != 0, out)
    check(f"{name}: names both keys", "'nav.menu'" in out and "'nav.menu.open'" in out, out)
    check(f"{name}: writes nothing", files_under(d) == [name], str(files_under(d)))
    shutil.rmtree(d)

print("Unsafe or duplicate language headers — must fail before writing anything (#8)")
for name, needle in (("header-traversal.csv", "'../escaped' isn't a language code"),
                     ("header-duplicate.csv", "'EN' appears more than once")):
    parent = tempfile.mkdtemp()
    d = os.path.join(parent, "project")
    os.mkdir(d)
    shutil.copy(os.path.join(INPUTS, name), d)
    code, out = run(name, "--out", "locales", cwd=d)
    check(f"{name}: fails", code != 0, out)
    check(f"{name}: says why", needle in out, out)
    check(f"{name}: nothing written, inside or outside the project", files_under(parent) == [os.path.join("project", name)],
          str(files_under(parent)))
    shutil.rmtree(parent)

print("")
if failures:
    print(f"{failures} check(s) failed.")
    sys.exit(1)
print("All language-tokens generator checks passed.")
