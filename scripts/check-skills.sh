#!/usr/bin/env bash
# The one place this repo's skill-validation rules live. Called by
# .githooks/pre-commit (--staged), .githooks/pre-push, and both skill jobs
# in .github/workflows/ci.yml (--gha), so the same content gets the same
# verdict everywhere.
#
# Usage:
#   ./scripts/check-skills.sh [--staged] [--gha] [--only structure|security]
#
#   --staged   check only staged skills/*/SKILL.md files, reading the
#              STAGED content (git's index), not the working-tree file —
#              so an unstaged edit can't hide a bad staged one.
#   --gha      print GitHub Actions ::error::/::warning:: annotations.
#   --only     run one group: "structure" (frontmatter, orphans, README
#              docs) or "security" (the mechanical half of audit-skills:
#              dangerous command patterns, injection phrasing). Default: both.
#
# The shipped git/workflows/ci.yml and prompt-injection-guard.yml templates
# can't call this script (it isn't copied into adopting projects), so they
# carry their own inline copies of the patterns. The "security" group checks
# they still match the ones below, so they can't silently drift.
#
# Exit 1 if any error was reported; warnings don't fail.

set -uo pipefail

STAGED=0
GHA=0
ONLY=all
while [ "$#" -gt 0 ]; do
  case "$1" in
    --staged) STAGED=1 ;;
    --gha) GHA=1 ;;
    --only)
      shift
      case "${1:-}" in structure | security) ONLY="$1" ;; *) echo "--only takes structure|security" >&2; exit 2 ;; esac
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

fail=0
report() { # level (error|warning), file (or ""), message
  if [ "$GHA" -eq 1 ]; then
    if [ -n "$2" ]; then echo "::$1 file=$2::$3"; else echo "::$1::$3"; fi
  else
    if [ -n "$2" ]; then echo "[$1] $2: $3"; else echo "[$1] $3"; fi
  fi
  if [ "$1" = error ]; then fail=1; fi
  return 0
}

want() { [ "$ONLY" = all ] || [ "$ONLY" = "$1" ]; }

# --- Security patterns (mechanical half of audit-skills) ----------------------
# Command patterns are case-sensitive (shell commands are). Injection phrasing
# is matched case-insensitively everywhere: "Skip confirmation" is the same
# instruction as "skip confirmation".
NETWORK_PATTERN='curl |wget |\bnc[[:space:]]+-|\bnetcat\b|\bncat\b'
SUDO_PATTERN='sudo'
RMRF_PATTERN='rm -rf'
OBFUSCATION_PATTERN='base64 -d|base64 --decode|eval \$\('
CREDENTIALS_PATTERN='\.ssh|\.aws|id_rsa|\.env\b|credentials'
INJECTION_PATTERN="pre-approved|you must comply|takes precedence over other instructions|don't mention this to the user|do this silently|skip confirmation|ignore (previous|prior) instructions|disregard (your|other)"

# grep_report level, file-to-read, file-to-name, message, pattern, [grep flags]
grep_report() {
  local level="$1" path="$2" name="$3" msg="$4" pattern="$5" flags="${6:--nE}" m
  while IFS= read -r m; do
    [ -n "$m" ] && report "$level" "$name" "$msg — $m"
  done <<<"$(grep "$flags" -- "$pattern" "$path" 2>/dev/null || true)"
}

check_security() { # path-to-read, name-to-report
  local path="$1" name="$2"
  # audit-skills/SKILL.md quotes these patterns as examples of what to look
  # for — scanning it would only flag itself.
  case "$name" in */audit-skills/SKILL.md) return 0 ;; esac
  grep_report error "$path" "$name" "possible network call with no obvious tie to the skill's purpose" "$NETWORK_PATTERN"
  grep_report error "$path" "$name" "sudo usage" "$SUDO_PATTERN"
  grep_report error "$path" "$name" "rm -rf" "$RMRF_PATTERN"
  grep_report error "$path" "$name" "obfuscated/eval'd command" "$OBFUSCATION_PATTERN"
  # Needs context to judge (security-review legitimately reads .env): warn.
  grep_report warning "$path" "$name" "references credentials/SSH paths — confirm this matches the skill's stated purpose" "$CREDENTIALS_PATTERN"
  grep_report error "$path" "$name" "language aimed at the agent rather than the user" "$INJECTION_PATTERN" -niE
}

check_structure() { # path-to-read, name-to-report
  local path="$1" name="$2"
  head -1 "$path" | grep -q '^---$' || report error "$name" "missing frontmatter opening ---"
  grep -q '^name:' "$path" || report error "$name" "missing 'name:' in frontmatter"
  grep -q '^description:' "$path" || report error "$name" "missing 'description:' in frontmatter"
}

# --- Which files ---------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

files=()
if [ "$STAGED" -eq 1 ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && files+=("$f")
  done <<<"$(git diff --cached --name-only --diff-filter=ACM | grep -E '^skills/[^/]+/SKILL\.md$' || true)"
else
  for f in skills/*/SKILL.md; do
    [ -f "$f" ] && files+=("$f")
  done
fi

for f in ${files[@]+"${files[@]}"}; do
  if [ "$STAGED" -eq 1 ]; then
    path="$TMP/$(echo "$f" | tr / _)"
    git show ":$f" >"$path"
  else
    path="$f"
  fi
  want structure && check_structure "$path" "$f"
  want security && check_security "$path" "$f"
done

# --- Repo-wide checks (skipped for --staged: they're about the whole tree) ----
if [ "$STAGED" -eq 0 ]; then
  if want structure; then
    orphans=$(find skills -maxdepth 1 -name "skill-*.md" -type f 2>/dev/null || true)
    [ -z "$orphans" ] || report error "" "orphaned flat skill files (should be skills/<name>/SKILL.md): $orphans"
    for dir in skills/*/; do
      name=$(basename "$dir")
      grep -q "\`$name\`" README.md || report warning "" "skill '$name' exists but isn't documented in README.md"
    done
  fi

  if want security; then
    template=git/workflows/ci.yml
    for p in "$NETWORK_PATTERN" "$SUDO_PATTERN" "$RMRF_PATTERN" "$OBFUSCATION_PATTERN" "$CREDENTIALS_PATTERN"; do
      grep -qF -- "'$p'" "$template" ||
        report error "$template" "shipped template is missing this repo's pattern '$p' — update its audit-skill-security job to match scripts/check-skills.sh"
    done
    # Both shipped workflows that match injection phrasing quote the
    # apostrophe in "don't" shell-style; compare with that one substitution
    # applied. (skills/audit-skills/SKILL.md lists the same phrases as prose
    # for a human/model to read, so it's still kept in sync by hand.)
    template_injection=${INJECTION_PATTERN//\'/\'\"\'\"\'}
    for t in "$template" git/workflows/prompt-injection-guard.yml; do
      grep -qF -- "$template_injection" "$t" ||
        report error "$t" "shipped workflow's injection pattern differs from scripts/check-skills.sh — update it to match"
    done
    # shellcheck disable=SC2016 # literal text to find, not an expansion
    grep -qF -- 'grep -niE "$pattern"' "$template" ||
      report error "$template" "shipped template's injection check isn't case-insensitive (grep -niE)"
  fi
fi

exit $fail
