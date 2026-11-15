#!/usr/bin/env bash
# Smoke checks for scripts/bootstrap.sh, against throwaway temp directories.
# Plain Bash, no dependencies. Run by CI (validate-shell-scripts) and by
# .githooks/pre-push.
#
#   ./scripts/test-bootstrap.sh
#
# Covers: fresh scaffolding lands every expected file; nothing that's this
# repo's own (fixtures/, .githooks/, its own CI, SkillSpector baselines)
# leaks out; reruns are no-ops; existing and customized files survive a
# rerun; --force replaces templates but never metrics/ or files the project
# added; --dry-run writes nothing; bad invocations fail.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP="$SRC_DIR/scripts/bootstrap.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0
pass() { echo "  ok    $1"; }
fail() { echo "  FAIL  $1"; failures=$((failures + 1)); }
check() { # description, then a command that must succeed
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}
check_not() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then fail "$desc"; else pass "$desc"; fi
}
same() { cmp -s "$1" "$2"; }

run() { "$BOOTSTRAP" "$@" >"$WORK/out.txt" 2>&1; }

# --- Fresh project ----------------------------------------------------------
echo "Fresh project"
P="$WORK/fresh"; mkdir "$P"
check "bootstrap exits 0" run "$P"
for f in AGENTS.md .github/copilot-instructions.md .github/workflows/ci.yml \
         .github/workflows/security.yml .github/dependabot.yml \
         .github/pull_request_template.md .github/ISSUE_TEMPLATE/bug_report.md \
         .github/ISSUE_TEMPLATE/feature_request.md LICENSE .env.example \
         metrics/findings-log.md metrics/toolkit-health.md; do
  check "created $f" test -f "$P/$f"
done
check "AGENTS.md is the template, not this repo's own" same "$SRC_DIR/ai/AGENTS.md" "$P/AGENTS.md"
check "ci.yml is the template, not this repo's own" same "$SRC_DIR/git/workflows/ci.yml" "$P/.github/workflows/ci.yml"
for skill in "$SRC_DIR"/skills/*/; do
  name=$(basename "$skill")
  check "skill $name copied" same "$skill/SKILL.md" "$P/.claude/skills/$name/SKILL.md"
done
check "nested skill files copied (language-tokens assets)" \
  same "$SRC_DIR/skills/language-tokens/assets/generate.py" "$P/.claude/skills/language-tokens/assets/generate.py"
check_not "no .skillspector-baseline.yaml shipped" \
  test -n "$(find "$P" -name .skillspector-baseline.yaml)"
check_not "fixtures/ not shipped" test -e "$P/fixtures"
check_not ".githooks/ not shipped" test -e "$P/.githooks"
check_not "scripts/ not shipped" test -e "$P/scripts"
check_not "optional workflows not shipped" test -e "$P/.github/workflows/llm-review.yml"

# --- Rerun is a no-op ---------------------------------------------------------
echo "Rerun"
check "rerun exits 0" run "$P"
check "rerun reports 0 created / 0 skipped" grep -q "^0 created, 0 replaced, .* 0 skipped, 0 kept" "$WORK/out.txt"

# --- Existing project with customizations ------------------------------------
echo "Existing project, no --force"
echo "my own context" >"$P/AGENTS.md"
echo "| 2026-01-01 | me | a11y | Clean | real history | |" >>"$P/metrics/findings-log.md"
cp "$P/metrics/findings-log.md" "$WORK/log.bak"
echo "my tweak" >>"$P/.claude/skills/a11y/SKILL.md"
echo "mine" >"$P/.claude/skills/a11y/my-notes.md"
rm "$P/LICENSE"
check "rerun exits 0" run "$P"
check "customized AGENTS.md preserved" grep -qx "my own context" "$P/AGENTS.md"
check "findings history preserved" same "$WORK/log.bak" "$P/metrics/findings-log.md"
check "customized skill preserved" grep -q "my tweak" "$P/.claude/skills/a11y/SKILL.md"
check "project's own file in a skill folder preserved" test -f "$P/.claude/skills/a11y/my-notes.md"
check "missing file recreated" test -f "$P/LICENSE"
check "skipped AGENTS.md is listed" grep -q "SKIPPED   AGENTS.md" "$WORK/out.txt"
check "skipped skill is listed" grep -q "SKIPPED   .claude/skills/a11y/SKILL.md" "$WORK/out.txt"

# --- --force -------------------------------------------------------------------
echo "--force"
check "--force exits 0" run --force "$P"
check "AGENTS.md replaced" same "$SRC_DIR/ai/AGENTS.md" "$P/AGENTS.md"
check "skill replaced" same "$SRC_DIR/skills/a11y/SKILL.md" "$P/.claude/skills/a11y/SKILL.md"
check "findings history still preserved" same "$WORK/log.bak" "$P/metrics/findings-log.md"
check "project's own file in a skill folder still preserved" test -f "$P/.claude/skills/a11y/my-notes.md"

# --- --dry-run ---------------------------------------------------------------
echo "--dry-run"
D="$WORK/dry"; mkdir "$D"
check "--dry-run exits 0" run --dry-run "$D"
check "--dry-run wrote nothing" test -z "$(ls -A "$D")"
check "--dry-run still reports the plan" grep -q "created   AGENTS.md" "$WORK/out.txt"

# --- Bad invocations ---------------------------------------------------------
echo "Bad invocations"
check_not "no destination fails" run
check_not "missing destination fails" run "$WORK/does-not-exist"
check_not "unknown flag fails" run --bogus "$D"
check_not "bootstrapping into the toolkit itself fails" run "$SRC_DIR"

echo ""
if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed."
  exit 1
fi
echo "All bootstrap checks passed."
