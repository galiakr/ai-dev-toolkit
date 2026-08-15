# ai-starter-playbook

> This is the playbook's own project file and not `ai/AGENTS.md`, which is the
> template handed to _other_ projects. If you're an AI assistant working in
> this repo, this is the file that describes it.

## What this project is

A personal, opinionated set of standards, skills, and templates for
starting and maintaining projects that work well with AI coding
assistants. It's not an app. There's no build, no server, no UI. The
"product" is the files themselves: Claude skills, GitHub Actions
templates, a bootstrap script, and the docs explaining how they fit
together. Read `README.md` first; it's the source of truth for what's
here and why.

## Stack

None. No `package.json`, no framework, no runtime dependency. The repo is Markdown (skills, docs), YAML (GitHub Actions templates), and Bash (`scripts/bootstrap.sh`, `.githooks/`). Don't
introduce npm/Node tooling just to gain a familiar workflow. If a check can be a plain shell script or a grep, prefer that over adding a dependency this repo would then have to maintain.

## Project structure

```
ai/             AGENTS.md + Copilot instructions template (for OTHER projects)
skills/         Claude skills. One folder per skill, each a SKILL.md
git/hooks/      Husky setup guide (template, for OTHER projects)
git/workflows/  CI + security workflow templates (for OTHER projects)
testing/        Vitest/RTL/Playwright setup guide
structure/      Folder layout + .env.example template
scripts/        bootstrap.sh - scaffolds all of the above into a new project
metrics/        BLANK TEMPLATES ONLY. See "What to avoid" below
fixtures/       THIS repo's own proof mechanism — deliberately broken (and
                deliberately fine-looking) examples that verify a skill
                catches what it claims to. See fixtures/README.md.
.github/        THIS repo's own CI, PR/issue templates, dependabot config
.githooks/      THIS repo's own git hooks (same as git/hooks/ note above)
```

The `ai/`, `git/hooks/`, `git/workflows/`, `testing/`, `structure/`,
`metrics/` folders are things this repo _ships_ to other projects. Don't
confuse a template with this repo's own configuration. `fixtures/`,
`.github/`, and `.githooks/` are the real thing, scoped to this repo —
none of the three are ever copied by `bootstrap.sh`.

## Conventions

### Skill files (`skills/<name>/SKILL.md`)

- Frontmatter needs `name:` and `description:`. The description states
  when to trigger the skill, specifically enough that another skill (or a
  human) can tell whether it applies.
- A numbered `## Steps` list, ending in a **"Log the result"** step that
  appends one row to `metrics/findings-log.md`. Every _project-check_
  skill does this. Meta/authoring skills that edit other skills' files
  (`add-logging-step`, `audit-skills`) are exempt; they don't log to a
  project's findings record because they don't check a project.
- An `## Output Format` section with a concrete example, and a one-line
  fallback string for the "nothing found" case.
- Judgment-level skills (`sync-context`, `project-memory`, `audit-skills`)
  report findings and let a human decide. They never silently rewrite or
  delete something on their own authority.

### Workflow templates (`git/workflows/*.yml`)

Must pass `actionlint`. The `validate-workflow-templates` CI job checks
this on every push. `.github/workflows/ci.yml` (this repo's own CI, not a
template) isn't linted the same way, but keep it valid YAML and consistent
in style with the templates it sits next to.

### Shell (`scripts/bootstrap.sh`, `.githooks/*`)

Must pass `shellcheck`. Prefer plain POSIX-ish Bash over anything clever —
this script runs unattended on someone else's machine during their first
five minutes with the repo; a cryptic failure there is a bad first
impression.

## What to avoid

- **Never fill in `metrics/findings-log.md` or `metrics/playbook-health.md`
  with real rows in this repo.** They're blank templates that get copied
  into adopting projects; this repo's own copy stays empty, permanently.
  Filling it in here would make it look like a specific project's actual
  results, which is exactly the kind of confusion the metrics system
  exists to prevent.
- Don't add a skill folder without documenting it in `README.md`'s skill
  list — the `validate-skills` CI job warns (doesn't block) when one's
  missing, but treat the warning as real.
- Don't add npm/Node tooling to this repo to solve a problem a shell
  script already solves — see "Stack" above.
- Never use `--no-verify` to skip a hook. If `.githooks/pre-commit` or
  `pre-push` is blocking you, fix the underlying issue.

## Git hygiene

- **Direct commits to `main` are the norm here, not an oversight.** This
  is a solo-maintained repo — one committer, so a PR-to-self workflow
  would be ceremony without a second reviewer to justify it. `ai/AGENTS.md`
  (the template shipped to *other* projects) says "never commit directly
  to main" because that rule earns its keep once there's a team; it isn't
  being applied to this repo about itself, deliberately.
- CI still gates every push to `main`, not just PRs — `.github/workflows/ci.yml`
  runs on `push: branches: [main]` specifically because there's no
  required-status-check branch protection blocking a bad commit *before*
  it lands. The trade-off is real: a broken commit gets caught right
  after landing, not before. `.githooks/pre-commit`/`pre-push` exist to
  catch most of that locally, before it's even pushed.
- `.github/pull_request_template.md` and `.github/ISSUE_TEMPLATE/` still
  exist and still matter even though the maintainer's own commits don't
  go through them — dependabot's automated PRs land in this repo's PR
  surface, and they're what an outside contributor would see if this repo
  ever took an external PR.
- One logical change per commit, and a message that explains *why* — still
  true here regardless of the above. It's about keeping `git log` useful
  later, not about review ceremony.
- Never use `--no-verify` to skip a hook, here or anywhere it's set up.

## Local checks

```bash
git config core.hooksPath .githooks   # one-time, per clone — see .githooks/README.md
chmod +x .githooks/pre-commit .githooks/pre-push
```

`pre-commit` checks staged `SKILL.md` files (frontmatter, dangerous
command patterns, injection-style phrasing). `pre-push` runs the full
pass across all skills, plus `shellcheck`/`actionlint`/`gitleaks` if
they're installed locally (CI runs all three regardless).

## Testing

There's no test suite. Nothing here is application code to unit-test.
"Correctness" for this repo means: skill files have valid frontmatter and
a logging step, workflow templates lint clean, `bootstrap.sh` passes
shellcheck, and the README accurately describes what's in the repo. CI
(`.github/workflows/ci.yml`) checks all of that on every push and PR.

## Instructions for AI assistants

- Treat `README.md` as the authoritative description of what's in this
  repo. If you add, remove, or meaningfully change a file that README
  documents, update README with the change.
- A change to a skill's behavior belongs in that skill's own `SKILL.md`,
  not scattered across README prose. README describes _what_ a skill
  does at a summary level; `SKILL.md` is the actual instructions.
- Before proposing a new CI job or hook, check whether it already exists
  in `.github/workflows/ci.yml`, `.githooks/`, or as a `git/workflows/*`
  template. This repo tends to grow mechanical counterparts to its own
  judgment-level skills (`security-review` ↔ `security.yml`,
  `audit-skills` ↔ the `audit-skill-security` CI job); check that pattern
  before inventing a new one.
- If asked to add something that would only make sense with npm/Node
  present, say so explicitly rather than adding a `package.json` as a side
  effect.

## Current focus / known issues

- [x] `audit-skills`' provenance-hash tracking mechanism has been
      exercised and verified — `fixtures/audit-skills/adopted-skill-simulation/`
      (see its `HOW-TO-TEST.md`) ran the real two-run procedure against a
      throwaway copy: baseline hash recorded on run 1, drift correctly
      detected on run 2. Still true, separately: no skill in this repo's
      own `skills/` has actually been adopted from outside it, so
      `metrics/skill-provenance.md` correctly still doesn't exist here —
      that's a different fact from "the mechanism was never tested."
- [x] This repo's own CI, hooks, and PR/issue templates were audited
      against the playbook's own philosophy and closed out — root
      `AGENTS.md` (this file), `.githooks/`, `.github/pull_request_template.md`,
      `.github/ISSUE_TEMPLATE/`, `.github/dependabot.yml` (github-actions only),
      and a `secret-scan` job in `.github/workflows/ci.yml`.
- [x] Six skills now have fixtures under `fixtures/` (`audit-skills`,
      `a11y`, `review-tests`, `project-memory`, `security-review`,
      `sync-context`), each actually run for real rather than reasoned
      about — two real gaps in `security-review/SKILL.md` were found this
      way and fixed (see `fixtures/security-review/README.md`).
- [x] Added four optional/advanced AI-security additions to the
      *template* (not to this repo's own operational config — none are
      wired up here, since this repo has no live LLM-facing feature and
      no branch protection to attach a required check to): a model-
      classification step in `audit-skills` for rephrased injection
      attempts the regex scan misses, `ai/guardrails.md` for runtime
      protection on projects that do expose an LLM to end users, and two
      opt-in GitHub Actions templates — `git/workflows/prompt-injection-guard.yml`
      (flags, never blocks) and `git/workflows/llm-review.yml` (non-blocking
      LLM second opinion by default). All validated by extracting and
      running the actual shell logic against sample data, not just read
      for plausibility — see each file's own header comments for scope
      and when a project should actually reach for it.
- [x] Fixtures added for all three of the above that have testable
      logic (`audit-skills`' Advanced classification step, and both new
      workflow templates — `ai/guardrails.md` is a pure reference doc
      with nothing to fixture). Building `fixtures/llm-review/`'s fixture
      caught a real bug in `git/workflows/llm-review.yml` before it ever
      ran for real: `echo "$RESPONSE" | jq` silently corrupted valid JSON
      containing escaped newlines (this shell's `echo` converts a literal
      `\n` into an actual newline byte), which would have broken parsing
      on almost any real multi-paragraph model response. Fixed by having
      `curl` write to a file and every downstream step read that file
      directly — see `fixtures/llm-review/README.md`. The
      `rephrased-injection-skill` fixture also proved the model-
      classification technique for real: a fresh, blind subagent caught
      all 3 planted lines that a verified-clean regex scan found nothing
      in.
- [x] Wired NVIDIA SkillSpector (a purpose-built agent-skill security
      scanner, 69 patterns/17 categories — AST/taint analysis, YARA
      signatures, OSV.dev CVE lookups, tool-poisoning/excessive-agency
      heuristics) into this repo's own CI as a new `skillspector-scan`
      job, `--no-llm` static-only so it needs no API key. Kept alongside
      `audit-skill-security` rather than replacing it, and this one was
      tested rather than assumed: a planted skill with an obvious
      `curl | bash` plus "don't mention this to the user" scored only
      40/100 (CAUTION, exit 0, non-blocking) under SkillSpector's
      `--no-llm` scoring — the grep job fails hard on that same file, on
      both patterns, no threshold involved. A clearly malicious skill
      (credential harvesting + a network-controlled exec chain) reliably
      scored 100/CRITICAL and did fail, so the gap is specifically
      low-signal content, not the job being toothless. Validated against
      every real skill before landing: 5 of 9 skills tripped real
      (false-positive) findings — `audit-skills` for quoting injection
      phrasing as documentation (same reason it's already excluded from
      the grep job), `security-review` for its own `.env` hygiene check,
      `a11y` for `npx`-installing scan tooling, `project-memory` for
      describing its own memory-log archiving, `language-tokens` for a
      permissions heuristic every skill here trips (none declare an MCP
      permissions field). Each is suppressed with a specific written
      reason in that skill's own `.skillspector-baseline.yaml`, not a
      blanket exclusion. Two caveats found by testing the suppression
      mechanism itself, not just the detections: a baseline fingerprint
      binds a skill's *entire* file content, so any edit to a baselined
      `SKILL.md` reactivates its suppressed finding too, not just new
      content; and a moderate-severity addition to an already-baselined
      file isn't guaranteed to cross the block threshold on its own
      (same scoring gap as above) — only a clearly severe one reliably
      does. Regenerate and re-triage a baseline whenever its skill file
      changes at all. Fixtures built and re-run for all of this at
      `fixtures/skillspector/` — see `SECURITY.md`'s `skillspector-scan`
      section for the full rationale.
