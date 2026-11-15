#!/usr/bin/env bash
# Exercises the actual "Scan every skill with SkillSpector" loop from both
# .github/workflows/ci.yml (this repo) and git/workflows/skillspector-scan.yml
# (the shipped template), not a re-typed copy of it: the run: block is
# extracted from the YAML and executed under the same shell GitHub Actions
# uses (bash --noprofile --norc -eo pipefail), with a stub `skillspector`
# whose exit code is chosen per skill.
#
#   ./fixtures/skillspector/test-ci-loop.sh
#
# Regression test for issue #11: under bash -e, a bare
# `skillspector ...; code=$?` ended the step on the first nonzero exit,
# skipping the diagnostics, ::endgroup::, and every later skill.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Print the body of the run: | block under the step with this exact name,
# with the YAML indentation removed.
extract_run() {
  awk -v step="- name: $2" '
    index($0, step) { in_step = 1; next }
    in_step && /run: \|/ { in_run = 1; base = -1; next }
    in_run {
      if ($0 ~ /^[[:space:]]*$/) { print ""; next }
      match($0, /^ */); ind = RLENGTH
      if (base < 0) base = ind
      if (ind < base) exit
      print substr($0, base + 1)
    }
  ' "$1"
}

# Stub scanner: exit code comes from STUB_<skill name>, default 0.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/skillspector" <<'EOF'
#!/usr/bin/env bash
name=$(basename "${2%/}")
var="STUB_${name//-/_}"
echo "stub scan of $name"
exit "${!var:-0}"
EOF
chmod +x "$WORK/bin/skillspector"

failures=0
expect() { # description, then a command that must succeed
  local desc="$1"; shift
  if "$@"; then echo "  ok    $desc"; else echo "  FAIL  $desc"; failures=$((failures + 1)); fi
}
count() { grep -c "$1" "$2" || true; }

run_case() { # yaml, skills dir, label, expected exit, env assignments...
  local yaml="$1" skills_dir="$2" label="$3" want="$4"; shift 4
  local proj="$WORK/proj" out="$WORK/out.txt" code=0
  rm -rf "$proj"
  for s in alpha beta gamma; do mkdir -p "$proj/$skills_dir/$s"; echo "---" >"$proj/$skills_dir/$s/SKILL.md"; done
  extract_run "$yaml" "Scan every skill with SkillSpector" >"$WORK/step.sh"
  (cd "$proj" && env PATH="$WORK/bin:$PATH" "$@" bash --noprofile --norc -eo pipefail "$WORK/step.sh") >"$out" 2>&1 || code=$?

  echo "$label"
  expect "step exits $want (got $code)" [ "$code" -eq "$want" ]
  expect "all 3 skills scanned" [ "$(count '^stub scan of' "$out")" -eq 3 ]
  expect "every ::group:: closed" [ "$(count '^::group::' "$out")" -eq "$(count '^::endgroup::' "$out")" ]
  if [ "$want" -ne 0 ]; then
    expect "an ::error:: names the failing skill" grep -q '^::error file=.*alpha/SKILL.md' "$out"
  fi
}

for pair in ".github/workflows/ci.yml:skills" "git/workflows/skillspector-scan.yml:.claude/skills"; do
  yaml="$ROOT/${pair%%:*}"
  dir="${pair#*:}"
  if [ -z "$(extract_run "$yaml" "Scan every skill with SkillSpector")" ]; then
    echo "FAIL  couldn't find the scan step in ${pair%%:*} — was it renamed?"
    failures=$((failures + 1))
    continue
  fi
  echo "== ${pair%%:*}"
  run_case "$yaml" "$dir" "all clean" 0
  run_case "$yaml" "$dir" "first skill above threshold (exit 1)" 1 STUB_alpha=1
  run_case "$yaml" "$dir" "first skill scan error (exit 2)" 1 STUB_alpha=2
  run_case "$yaml" "$dir" "first skill unexpected exit (3)" 1 STUB_alpha=3
done

echo ""
if [ "$failures" -gt 0 ]; then echo "$failures check(s) failed."; exit 1; fi
echo "All SkillSpector CI loop checks passed."
