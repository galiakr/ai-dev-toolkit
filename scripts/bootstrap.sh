#!/usr/bin/env bash
# Bootstrap a project with ai-dev-toolkit's files.
#
# Usage: run from anywhere, pointing at a checkout of ai-dev-toolkit:
#   ./scripts/bootstrap.sh [--dry-run] [--force] /path/to/project
#
# This is a one-time copy, not an installed dependency — the destination
# project owns these files afterward and can edit them freely.
#
# Safe to run on an existing project, and safe to rerun:
#   - A file that doesn't exist yet in the project is created.
#   - A file that already exists with identical content is left alone.
#   - A file that already exists with different content is SKIPPED and
#     listed at the end, so a customized AGENTS.md, CI workflow, or skill
#     is never silently replaced.
#   - Files inside a skill folder that this toolkit doesn't ship (your own
#     additions) are never touched or deleted.
#
#   --force    replace existing files that differ, EXCEPT anything under
#              metrics/ — that's the project's own findings history, not a
#              template, and is never replaced.
#   --dry-run  print what would be created/replaced/skipped; write nothing.
#
# Every copy is planned before anything is written, so a bad source path
# fails before the project is touched.

set -euo pipefail

usage() {
  echo "Usage: $0 [--dry-run] [--force] /path/to/project" >&2
  exit 1
}

FORCE=0
DRY_RUN=0
DEST=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) usage ;;
    -*) echo "Unknown option: $arg" >&2; usage ;;
    *)
      [ -z "$DEST" ] || { echo "Only one destination allowed." >&2; usage; }
      DEST="$arg"
      ;;
  esac
done
[ -n "$DEST" ] || usage

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$DEST" ]; then
  echo "Destination '$DEST' does not exist. Create the project first (e.g. vite scaffold), then re-run." >&2
  exit 1
fi
DEST="$(cd "$DEST" && pwd)"

if [ "$DEST" = "$SRC_DIR" ]; then
  echo "Destination is this toolkit's own checkout — refusing to bootstrap into itself." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Plan: collect every (source, destination) pair. Nothing is written yet.
# ---------------------------------------------------------------------------

PLAN_SRC=()
PLAN_DEST=()

# plan <source relative to toolkit> <destination relative to project>
# Missing optional sources are skipped by the caller with plan_if_exists.
plan() {
  if [ ! -f "$SRC_DIR/$1" ]; then
    echo "Toolkit file missing: $SRC_DIR/$1 — is this a complete checkout?" >&2
    exit 1
  fi
  PLAN_SRC+=("$1")
  PLAN_DEST+=("$2")
}

plan_if_exists() {
  if [ -f "$SRC_DIR/$1" ]; then plan "$1" "$2"; fi
}

# AI context
plan ai/AGENTS.md AGENTS.md
plan ai/copilot-instructions.md .github/copilot-instructions.md

# CI workflows and GitHub templates
plan git/workflows/ci.yml .github/workflows/ci.yml
plan_if_exists git/workflows/security.yml .github/workflows/security.yml
plan_if_exists git/dependabot.yml .github/dependabot.yml
plan_if_exists git/pull_request_template.md .github/pull_request_template.md
for f in "$SRC_DIR"/git/ISSUE_TEMPLATE/*.md; do
  [ -f "$f" ] || continue
  plan "git/ISSUE_TEMPLATE/$(basename "$f")" ".github/ISSUE_TEMPLATE/$(basename "$f")"
done

# Root files
plan_if_exists LICENSE LICENSE
plan_if_exists structure/.env.example .env.example

# Metrics templates (blank — the project fills in its own rows)
plan_if_exists metrics/findings-log.md metrics/findings-log.md
plan_if_exists metrics/toolkit-health.md metrics/toolkit-health.md

# Claude skills, file by file, so files the project added inside a skill
# folder are left alone. .skillspector-baseline.yaml is only meaningful
# alongside the optional git/workflows/skillspector-scan.yml template (step
# 8 below), so it isn't shipped by default.
for skill in "$SRC_DIR"/skills/*/; do
  skill=${skill%/} # BSD find would otherwise print "skills/x//file"
  [ -f "$skill/SKILL.md" ] || continue
  name=$(basename "$skill")
  while IFS= read -r f; do
    rel=${f#"$SRC_DIR"/skills/"$name"/}
    case "$(basename "$rel")" in
      .skillspector-baseline.yaml | .DS_Store) continue ;;
    esac
    plan "skills/$name/$rel" ".claude/skills/$name/$rel"
  done < <(find "$skill" -type f | sort)
done

# ---------------------------------------------------------------------------
# 2. Classify each planned copy against what's already in the project.
# ---------------------------------------------------------------------------

ACTIONS=()
created=0 unchanged=0 replaced=0 skipped=0 protected=0

for i in "${!PLAN_SRC[@]}"; do
  src="$SRC_DIR/${PLAN_SRC[$i]}"
  dest="$DEST/${PLAN_DEST[$i]}"
  if [ ! -e "$dest" ]; then
    action=create; created=$((created + 1))
  elif cmp -s "$src" "$dest"; then
    action=unchanged; unchanged=$((unchanged + 1))
  else
    case "${PLAN_DEST[$i]}" in
      metrics/*) action=protect; protected=$((protected + 1)) ;;
      *)
        if [ "$FORCE" -eq 1 ]; then
          action=replace; replaced=$((replaced + 1))
        else
          action=skip; skipped=$((skipped + 1))
        fi
        ;;
    esac
  fi
  ACTIONS+=("$action")
done

# ---------------------------------------------------------------------------
# 3. Apply (unless --dry-run) and report.
# ---------------------------------------------------------------------------

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run — nothing will be written. Planned for $DEST:"
else
  echo "Bootstrapping $DEST from $SRC_DIR ..."
fi
echo ""

for i in "${!PLAN_SRC[@]}"; do
  src="$SRC_DIR/${PLAN_SRC[$i]}"
  rel="${PLAN_DEST[$i]}"
  dest="$DEST/$rel"
  case "${ACTIONS[$i]}" in
    create | replace)
      if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
      fi
      if [ "${ACTIONS[$i]}" = create ]; then
        echo "  created   $rel"
      else
        echo "  replaced  $rel"
      fi
      ;;
    skip) echo "  SKIPPED   $rel (already exists and differs — rerun with --force to replace)" ;;
    protect) echo "  kept      $rel (project data — never replaced, even with --force)" ;;
    unchanged) ;;
  esac
done

echo ""
echo "$created created, $replaced replaced, $unchanged already up to date, $skipped skipped, $protected kept."

if [ "$DRY_RUN" -eq 1 ]; then
  exit 0
fi

if [ "$skipped" -gt 0 ]; then
  echo ""
  echo "Skipped files are yours as they are. To see what the toolkit would have changed:"
  echo "  diff <toolkit file> <project file>   (sources are under $SRC_DIR)"
fi

echo ""
echo "Remaining manual steps:"
echo "  1. Fill in the placeholders in AGENTS.md and copilot-instructions.md (stack, project description)."
echo "  2. cd $DEST && npm install --save-dev husky lint-staged"
echo "  3. npx husky init, then add pre-commit/pre-push hooks per git/hooks/README.md"
echo "  4. Follow testing/setup.md to install Vitest + RTL + Playwright"
echo "  5. Fill in real values locally in .env (never commit it) — .env.example stays as placeholders"
echo "  6. Update LICENSE copyright line if the author differs"
echo "  7. Optional, advanced: if this project accepts outside PRs or has anything AI-driven"
echo "     reading PR content, see git/workflows/prompt-injection-guard.yml and llm-review.yml"
echo "     (not copied automatically). If it exposes an LLM to end users, see ai/guardrails.md."
echo "  8. Optional, advanced: your .claude/skills/ folder was just copied from this repo's own"
echo "     skills — if you'll adopt skills from outside contributors or third-party sources, see"
echo "     git/workflows/skillspector-scan.yml (not copied automatically) for a real, tool-based"
echo "     skill-security scan beyond ci.yml's mechanical grep pattern check. Its known-false-positive"
echo "     baselines weren't copied either (see skills/*/.skillspector-baseline.yaml in this repo) —"
echo "     copy the ones for skills you kept, or run 'skillspector baseline' fresh for your own."
echo "  9. If this project will ever accept an outside contributor's PR: none of ci.yml's checks"
echo "     actually block a merge until you turn on branch protection (repo Settings > Branches)"
echo "     with required status checks + a required review — a red check is only a suggestion"
echo "     until then. Exempt admins if you're the sole maintainer for now; that keeps your own"
echo "     direct-push workflow while still gating anyone who isn't you. This isn't a file"
echo "     bootstrap.sh can copy — it's a GitHub repo setting you set once, per project."
