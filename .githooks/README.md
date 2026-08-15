# Git hooks (this repo)

`git/hooks/` documents the Husky + lint-staged setup for *adopting*
projects — ones with a `package.json`. This repo doesn't have one, so
Husky doesn't fit here: there's nothing for `npx husky init` to hook into,
and pulling in an npm dependency just to run two shell scripts would be
exactly the kind of unnecessary tooling this toolkit argues against.

Same rule, no Node: these hooks are plain scripts checked into
`.githooks/`, wired up via `git config core.hooksPath`.

## Setup

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/pre-push
```

This is per-clone, not automatic — there's no `npm install` step here to
run it for you. Run it once after cloning.

## pre-commit

Runs against staged `SKILL.md` files only: frontmatter check, dangerous
command patterns, prompt-injection-style phrasing. Fast, mirrors the
`audit-skill-security` CI job scoped to what you're about to commit.

## pre-push

The slower, full pass: every skill file (not just staged), the orphan and
README-doc-sync checks, and — if the tool is installed locally —
`shellcheck` on `scripts/bootstrap.sh`, `actionlint` on
`git/workflows/*.yml`, and `gitleaks`. Missing tools are skipped locally
with a note; CI still runs all of them, so nothing silently goes
unchecked.

## Rule

Never use `--no-verify` to skip these. If a hook is blocking you, fix the
underlying issue.
