#!/usr/bin/env bash
# Bootstrap a new project with ai-dev-toolkit's files.
#
# Usage: run from inside a checkout of ai-dev-toolkit:
#   ./scripts/bootstrap.sh /path/to/new-project
#
# This is a one-time copy, not an installed dependency — the destination
# project owns these files afterward and can edit them freely.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:?Usage: ./scripts/bootstrap.sh /path/to/new-project}"

if [ ! -d "$DEST" ]; then
  echo "Destination '$DEST' does not exist. Create the project first (e.g. vite scaffold), then re-run."
  exit 1
fi

echo "Bootstrapping $DEST from $SRC_DIR ..."

mkdir -p "$DEST/.github/workflows"
mkdir -p "$DEST/.claude/skills"

# AI context
cp "$SRC_DIR/ai/AGENTS.md" "$DEST/AGENTS.md"
cp "$SRC_DIR/ai/copilot-instructions.md" "$DEST/.github/copilot-instructions.md"

# CI workflows
cp "$SRC_DIR/git/workflows/ci.yml" "$DEST/.github/workflows/ci.yml"
if [ -f "$SRC_DIR/git/workflows/security.yml" ]; then
  cp "$SRC_DIR/git/workflows/security.yml" "$DEST/.github/workflows/security.yml"
fi
if [ -f "$SRC_DIR/git/dependabot.yml" ]; then
  cp "$SRC_DIR/git/dependabot.yml" "$DEST/.github/dependabot.yml"
fi
if [ -f "$SRC_DIR/git/pull_request_template.md" ]; then
  cp "$SRC_DIR/git/pull_request_template.md" "$DEST/.github/pull_request_template.md"
fi
if [ -d "$SRC_DIR/git/ISSUE_TEMPLATE" ]; then
  mkdir -p "$DEST/.github/ISSUE_TEMPLATE"
  cp "$SRC_DIR"/git/ISSUE_TEMPLATE/*.md "$DEST/.github/ISSUE_TEMPLATE/"
fi

# Root files
if [ -f "$SRC_DIR/LICENSE" ]; then
  cp "$SRC_DIR/LICENSE" "$DEST/LICENSE"
fi
if [ -f "$SRC_DIR/structure/.env.example" ]; then
  cp "$SRC_DIR/structure/.env.example" "$DEST/.env.example"
fi

# Metrics templates (blank — the project fills in its own rows)
mkdir -p "$DEST/metrics"
if [ -f "$SRC_DIR/metrics/findings-log.md" ]; then
  cp "$SRC_DIR/metrics/findings-log.md" "$DEST/metrics/findings-log.md"
fi
if [ -f "$SRC_DIR/metrics/toolkit-health.md" ]; then
  cp "$SRC_DIR/metrics/toolkit-health.md" "$DEST/metrics/toolkit-health.md"
fi

# Claude skills (one folder per skill, each with a SKILL.md, Claude Code convention)
mkdir -p "$DEST/.claude/skills"
for skill in "$SRC_DIR"/skills/*/; do
  skill=${skill%/}
  name=$(basename "$skill")
  rm -rf "$DEST/.claude/skills/$name"
  cp -R "$skill" "$DEST/.claude/skills/$name"
  # .skillspector-baseline.yaml is only meaningful alongside the optional
  # git/workflows/skillspector-scan.yml template (step 8 below) — not
  # copied by default, so don't ship its baseline files as unexplained
  # clutter to every project that never adopts it either.
  rm -f "$DEST/.claude/skills/$name/.skillspector-baseline.yaml"
done

echo ""
echo "Copied. Remaining manual steps:"
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
