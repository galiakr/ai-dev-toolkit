# ai-starter-playbook

A personal set of standards, skills, and templates for building AI-ready projects.

## What this actually is

It all started as an accident and became a deliberate practice. I ran this playbook's `review-tests` skill against a real project's test suite and it reported the coverage gate passing at 100%. Run again with coverage enabled, it caught that the coverage tool was only measuring 1 of 12 source files. The fix went into `review-tests` itself, not just that one project, and it's live in this repo. That was luck, in the sense that nobody planned to find it.

`fixtures/` is what happened once I stopped waiting for accidents. It's deliberately broken (and deliberately fine-looking) examples, built to verify a skill actually catches what it claims to catch instead of just trusting that it does because it sounds right. The coverage-lie catch proved the idea works by accident once. `fixtures/` is the same idea, on purpose, repeatable, and visible in the repo.
See `fixtures/README.md` for how it's organized.

It's also a learning document. Some of what's here I already knew well, other parts I added because I wanted to understand them, and writing it down is how it stuck. If it works for you too, that's the point.

It's a reference I reuse across my own projects, a starting point if you want something similar, and a living document that changes as my tooling and understanding do. It's not a framework or a CLI. Every skill is a standalone file you can lift out and use with zero context on the others. Just files you copy, adapt, and then own.

## What's inside

- **`ai/`**: an `AGENTS.md` template + GitHub Copilot instructions, so an AI assistant has real context instead of starting cold. Also `guardrails.md`, optional reference for runtime prompt-injection protection, only relevant if the project exposes an LLM to end users.
- **`skills/`**: Claude skills — a11y audits, GitHub CLI workflows, test review (with coverage-scope verification), context-drift checks, i18n string centralization, application-code security review, skill-security auditing, and two "meta" skills (`add-logging-step`, `project-memory`) that keep the others honest over time.
- **`fixtures/`**: deliberately broken examples used to verify a skill's claims are actually true, not just plausible. Not a template but this repo's own proof.
- **`git/hooks/`**: Husky pre-commit/pre-push setup.
- **`git/workflows/`**: CI and security GitHub Actions, plus optional/advanced ones (prompt-injection PR scanning, LLM-as-judge review, NVIDIA SkillSpector skill-security scanning) that `bootstrap.sh` does _not_ copy automatically.
- **`git/dependabot.yml`**: weekly auto dependency updates.
- **`git/pull_request_template.md`**: a PR description template with a checklist so reviews start with context instead of a blank box.
- **`git/ISSUE_TEMPLATE/`**: bug report and feature request templates.
- **`testing/`**: Vitest + RTL + Playwright setup guide.
- **`structure/`**: recommended folder layout, naming conventions, and `.env.example`.
- **`scripts/`**: one-time bootstrap script that scaffolds all of the above into a new project.
- **`metrics/`**: _templates only_. A blank findings log and a quarterly health-check guide. Nothing in this repo is pre-filled with real project data. Each project that adopts the playbook fills in its own copy.
- **`LICENSE`**: MIT.

## Digging into each folder

### `ai/`

`AGENTS.md` is the template for giving Claude/Cursor project context: what the project is, the stack, coding conventions, testing rules, what to avoid, and a "current focus" section meant to be kept updated. Copy it to the project root and fill in the blanks. `copilot-instructions.md` says the same things, reformatted for where Copilot looks (`.github/copilot-instructions.md`). Keep the two in sync by hand, or let the `sync-context` skill check for drift between them.

`guardrails.md` is a separate, optional reference. Read it if the project actually exposes an LLM to end users. Covers runtime protection against prompt injection: a no-dependency DIY tier, platform-native moderation APIs, and NVIDIA NeMo Guardrails for when the lighter tiers stop being enough. `AGENTS.md`'s Security basics section links to it conditionally.

### `skills/`

Each one lives in its own folder, copy the whole thing into `.claude/skills/<name>/`. `scripts/bootstrap.sh` does this for you. Every _project-check_ skill ends with a "log the result" step that appends a row to the project's own `metrics/findings-log.md`. `add-logging-step` and `audit-skills` are exempt. They're authoring/meta skills that check the playbook's own artifacts, so they don't log to a project's findings record.
`audit-skills` does log when it audits skills adopted _into_ a real project. The exemption is for auditing this repo's own skills, not the skill in general.

- **`a11y`**: runs an accessibility audit (axe-core, falling back to Lighthouse, then pa11y), and reports WCAG violations by severity with fix suggestions.
- **`github`**: GitHub CLI workflows for issues and PRs, a rebase-based conflict resolution process, and a triage mode that turns another skill's findings into labeled, assigned issues without duplicating ones that already exist.
- **`review-tests`**: runs tests with coverage, checks that the coverage report is actually measuring the full source tree before trusting the percentage, and reviews test files for the usual AI-written-test problems: tautological assertions, wrong expected values, missing edge cases, weak `toBeTruthy` checks. This is the skill that found the coverage lie described above.
- **`sync-context`**: reads `AGENTS.md` and `copilot-instructions.md`, pulls out the rules each one states, and reports where they've drifted.
- **`language-tokens`**: centralizes user-facing text into one CSV a non-coder can edit, with a generator script that produces per-language JSON. Adapts to an existing i18n setup rather than replacing it, migrates strings incrementally, and won't invent a translation it's not confident about.
- **`security-review`**: a judgment-level review of a _consuming project's application code_, scoped to what CI's gitleaks/`npm audit` gate doesn't catch. Uses real tools where they exist.
  `semgrep` for injection patterns,
  `gitleaks detect` for secrets (both full history for pre-adoption leaks and a `--no-git` scan of the current tree for anything that hasn't reached CI yet),
  `npm audit --json` for dependency triage. Falls back to explicitly-labeled-as-degraded grep only if the tool isn't installed. Checks CSRF exposure on state-changing routes, distinguishing cookie-authenticated routes from bearer-token routes. Upfront about its own limits: a heuristic review, not a substitute for a professional audit on anything touching payments or regulated data.
- **`audit-skills`**: reviews the _skill files themselves_, not application code. Scans for command patterns with no connection to a skill's stated purpose, prompt-injection-style phrasing embedded in the instructions, description-vs-behavior mismatches, and scope violations, and tracks a provenance hash for any skill adopted from outside this repo so a later silent change gets flagged. Has an optional advanced step for a higher-stakes review: a model-based classification pass on top of the regex scan, catching a rephrased injection attempt the fixed pattern list would miss. Never auto-fixes or auto-trusts - every finding is a report for a human decision. The mechanical half (command patterns, injection phrasing) also runs automatically in this repo's own CI. Validated against `fixtures/audit-skills/`.
- **`add-logging-step`**: retrofits the "log the result" step into skills that don't have one yet, scanning for the gap, skipping skills that already log, and picking outcome vocabulary (`Clean`, `Found → Fixed`, `Action taken`, etc.) that fits each skill. This is what keeps "every project-check skill logs its results" true as new skills get added.
- **`project-memory`**: checks `AGENTS.md`'s "known issues / current focus" checklist against what's actually true in the repo, instead of trusting the checkboxes. It also archives, never deletes, resolved rows out of `findings-log.md` once their linked issues close, so the log stays readable as it grows.

### `fixtures/`

Everything above proves itself by being used on a real project, eventually, maybe. `fixtures/` doesn't wait for that. Dliberately broken (and deliberately fine-looking) examples that verify a claim is true right now, on demand, each with its own `README.md`, `expected-findings.md`, and `results-log.md`. Full detail, including how to run each one, is in `fixtures/README.md` and each fixture's own folder, not repeated here.

### `git/`

`hooks/README.md` covers Husky + lint-staged: `pre-commit` (lint-staged on staged files, fast), `pre-push` (full test suite, slower, catches what commit-time linting can't), and an optional `commit-msg` hook for conventional commits.

`workflows/ci.yml` runs on every push/PR to `main`. Install, lint, type-check, test with coverage, upload the artifact. It's the gate `--no-verify` can't get around. `workflows/security.yml` runs gitleaks and `npm audit` on push/PR and weekly, so a newly disclosed CVE in an existing dependency gets caught even without a code change (`security-review` picks up where this leaves off, and `audit-skills` covers a layer neither of these touches at all).

`workflows/prompt-injection-guard.yml` and `workflows/llm-review.yml` are optional, advanced templates. They are **not** copied by `bootstrap.sh`. The first scans new PR titles/bodies/diffs for the same injection-style phrasing `audit-skills` looks for in skill files, and flags a match for human review.
The second is an LLM-as-judge second opinion on PRs, non-blocking by default, that explicitly treats the diff it reviews as untrusted data rather than instructions. Both only matter once something AI-driven is actually reading PR content in the project. Each file explains when to reach for it.

`dependabot.yml` opens weekly PRs for outdated npm packages and GitHub Actions versions.

`pull_request_template.md` is what GitHub pre-fills into the PR description box: what the change does, how it was tested, and a short checklist (tests, docs, no committed secrets, linked issue). Copy it to `.github/pull_request_template.md` in the destination project and GitHub picks it up automatically.

`ISSUE_TEMPLATE/` holds the forms GitHub shows when someone clicks "New issue": `bug_report.md` (what happened, steps to reproduce, environment, logs) and `feature_request.md` (problem, proposed solution, alternatives considered). Copy the whole folder to `.github/ISSUE_TEMPLATE/` and GitHub wires it in. No config needed.

### `testing/`

`setup.md` is the full Vitest + React Testing Library + Playwright + MSW setup: install commands, `vitest.config.ts`, coverage thresholds, file conventions, and a side-by-side of a specific, readable test versus a vague one.

### `structure/`

`project-template.md` lays out folder structure and naming conventions (components, hooks, utils, types) for React + TypeScript, plus the files every project should have. `.env.example` is a template for documenting every env var a project uses, placeholders only.

### `scripts/`

`bootstrap.sh` copies `AGENTS.md`, Copilot instructions, the CI/security workflows, `dependabot.yml`, the PR and issue templates, `LICENSE`, `.env.example`, every skill folder, and a blank `metrics/` folder into a new project in one pass. It's a one-time scaffold, not a dependency. The destination project owns the files afterward and can edit them freely.
`fixtures/` isn't copied. It exists to test this repo's own skills, not to be handed to an adopting project.

### `metrics/`

`findings-log.md` is a blank template. Once it's copied into a real project, every skill run appends a row: date, skill, outcome, one-sentence detail. `project-memory` is what keeps it from growing forever. `playbook-health.md` is a quarterly checklist that reads from that log rather than starting from scratch — which skills are earning their place, whether `--no-verify` usage is creeping up, whether CI failures are real catches or flaky noise, whether coverage is actually trending and not just passing.

### Root

Everything above this line is a template. Something `bootstrap.sh` copies _out_ of this repo and into someone else's. The files below run this repo itself and never get copied anywhere:

- **`LICENSE`**: MIT.
- **`.gitignore`**: this repo's own ignore rules, `structure/` has the `.env.example` for that.
- **`AGENTS.md`**: this repo's own project context file, filled in for real, not to be confused with `ai/AGENTS.md`, which is the blank template other projects copy.
- **`.github/`**: this repo's own CI.
  `ci.yml`: validates skill frontmatter, orphaned files, README/skill drift, plus a `secret-scan` job. `audit-skill-security` job running the mechanical half of `audit-skills` against every real skill on every push.
  `skillspector-scan` job running [NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector) in `--no-llm` mode against every skill, with per-skill `.skillspector-baseline.yaml` files suppressing confirmed false positives.
  `pull_request_template.md` and `ISSUE_TEMPLATE/`, and its own `dependabot.yml`.
- **`.githooks/`**: this repo's own pre-commit/pre-push hooks.
- **`fixtures/`**: this repo's own proof mechanism. Never copied anywhere. It exists to test the skills as they live in _this_ repo.
- **`SECURITY.md`**: a deep, step-by-step walkthrough of every security/audit/CI mechanism in this repo — what triggers each one, why it exists, and whether it's active here or shipped as a template.

## How the metrics system actually works

Worth being explicit about this, since it's easy to set up wrong: **`metrics/` here is a template, not a record.** Nothing in this repo is ever filled in with real project data.

The actual flow: `bootstrap.sh` copies a blank findings log and health-check guide into a new project, same as it does with `AGENTS.md`. From then on that copy is local and self-contained. Every time you run a project-check skill in that project, its last step appends a row to _that project's_ log. Over time each project builds its own history of what a skill has actually found, not just what it's supposed to catch in theory.

`project-memory` periodically archives resolved rows out of that log (never deletes) and checks the `AGENTS.md` checklist against reality, so the record stays useful instead of turning into noise. Quarterly, or whenever you're checking in, `playbook-health.md` reads that log to answer questions like "is this skill finding anything" and "is `--no-verify` creeping up."

If you want a cross-project view — comparing findings across everything that's adopted the playbook — that's a manual step during a health check, copying interesting rows out of each project's local log by hand. Nothing automates the rollup, because a session working inside one project's repo can't see the others (yet).

And if you use a skill that isn't in this repo (a built-in Claude Code skill, or a third-party one), it won't have a "log the result" step. Add the row by hand, run `add-logging-step` after copying that skill's definition in locally, and run `audit-skills` on it before you trust it with bash access in the first place.

The reason any of this exists: a rule is easy to write down and easy to assume is helping. `findings-log.md` and `project-memory` are how that stays checked instead of assumed for a _specific project_.

## How to use it

No install step, no required tooling. Browse the folder that's relevant to what you're setting up, copy what you need, adapt it.

For a whole new project, `scripts/bootstrap.sh /path/to/new-project` copies the default set in one pass,then prints the manual steps that are left.

## How I think about AI-assisted development

**Check the checks, not just the code.** This is the actual thesis, not one item on a list. A rule you write down and never verify is a claim, not a guardrail. The coverage-scope check in `review-tests` exists because a real coverage gate was found passing against 1 of 12 files. `project-memory` exists because a real `AGENTS.md` checklist was found stale. `audit-skills` exists because a skill with bash access is a security surface, and "I wrote it carefully" isn't a substitute for actually checking. `fixtures/` exists because even that isn't enough — a check that catches something once, by accident, on a real project, is good evidence but not proof it reliably works; a deliberately planted, known-answer test is what turns "it caught something once" into "here's what it catches, verified, on demand." None of this was planned upfront as a system. It's what kept happening once I started actually checking instead of assuming.

Everything else here follows from that, at a smaller scale:

**Give the AI context, not just code.** The single most useful thing you can do is write a good `AGENTS.md`: what the project is, how it's structured, what the rules are. Without it, every session starts cold.

**Automate the boring gates.** Pre-commit lint, pre-push tests, CI on every PR, secret scanning, dependency updates. None of that is optional once AI is writing code. It matters more, because AI can introduce subtle bugs confidently, and hooks are what catch them before they land.

**Accessibility isn't an afterthought.** AI-generated UI tends to skip ARIA labels, landmark regions, focus management. The `a11y` skill runs an automated audit and surfaces exactly these gaps.

**Test quality matters more than test quantity.** AI writes tests that pass without proving anything.Tautologies, wrong expected values, assertions that can't fail. `review-tests` catches that.

**Standards you don't understand are still worth writing down.** If something's in this playbook and you're not sure why, that's a prompt to go find out. The goal is understanding your own standards, not just following them.

## Contributing

Find something useful — adapt it freely. Spot an error or have a suggestion — open an issue.
