# [Project Name]

> This file is the most important file for AI-assisted development. It gives Claude, Copilot, and Cursor the context they need to help you without constant re-explanation. Copy it into every project and keep it updated as the project evolves.

---

## What this project is

One paragraph. What does it do, who is it for, what problem does it solve?

## Stack

- **Frontend:** React + TypeScript + Tailwind + Vite
- **Backend:** Node.js / Express (if applicable)
- **Database:** (if applicable)
- **Deploy:** Vercel / GitHub Pages

## Project structure

```
src/
  components/    React components
  hooks/         Custom hooks
  utils/         Pure utility functions
  types/         TypeScript type definitions
  constants/     App-wide constants
  test/
    setup.ts     jest-dom imports
    fixtures/    shared test data
```

---

## Coding conventions

- Functional React components only — no class components
- TypeScript strict mode — no `any`
- Named exports — no default exports except pages
- CSS via Tailwind utility classes — no inline styles
- Component files: `PascalCase.tsx`
- Utility files: `camelCase.ts`
- Test files: `*.test.ts` co-located with the file they test

## Code quality

- Prefer explicit over clever — code is read more than written
- No commented-out code in commits — delete it or open an issue
- No magic numbers — name your constants
- Every exported function gets a one-line JSDoc comment
- Complex logic gets an inline comment explaining the *why*, not the *what*
- Update this file and README when the project structure changes

## What to avoid

- Do not mutate props or state directly
- Do not use `useEffect` for data that can be derived
- Do not skip accessibility attributes (`alt`, `aria-label`, `role`)
- Do not commit `.env`, credentials, or secrets
- Do not log sensitive data (tokens, passwords, PII)
- Do not hardcode secrets — always use env vars
- Do not add `any` to TypeScript to silence errors

## Performance defaults

- Lazy load routes and heavy components
- Images always need `width`, `height`, and `alt`
- Use `memo` / `useCallback` only when profiling shows a need — not by default

## Security basics

- Validate and sanitize all external input
- Never log tokens, passwords, or PII
- All secrets via environment variables — documented in `.env.example`
- If this project exposes an LLM to end users (chat, an AI-assisted
  feature, an agent that acts on user requests), see `ai/guardrails.md`
  for runtime protection against prompt injection — this list covers
  general app security, not that specific risk

## Git hygiene

- One logical change per commit
- PR descriptions explain *why*, not just *what*
- Never commit directly to `main`
- Never use `--no-verify` to skip hooks

---

## Testing

Stack: **Vitest** + **React Testing Library** + **Playwright** (e2e)

### Rules

- Every utility function has unit tests
- Every component has at least a render test and one interaction test
- Tests cover: happy path, empty/null input, and at least one error case
- Name tests as: `it('returns X when Y')`
- Avoid `toBeTruthy` — assert the specific value instead
- Do not test implementation details — test behavior the user would see

### File conventions

```
src/utils/format.ts          ← source
src/utils/format.test.ts     ← unit test, lives next to source
src/test/fixtures/           ← shared test data
e2e/                         ← Playwright end-to-end tests
```

### Commands

```bash
npm test                # run once
npm run test:watch      # watch mode
npm run test:coverage   # with coverage report
```

Coverage threshold: 80% lines and functions. Run `/review-tests` in Claude Code to audit test quality.

---

## Commands

```bash
npm run dev       # start dev server
npm run build     # production build
npm run lint      # ESLint
npm test          # run tests once
```

## Pre-commit hooks

Husky runs lint-staged (ESLint + Prettier) on pre-commit and the full test suite on pre-push. Never use `--no-verify`.

---

## Instructions for AI assistants

- Run lint and tests before declaring something done
- Surface edge cases and error states — not just the happy path
- Add accessibility attributes to every interactive element
- Suggest before refactoring — don't restructure without asking
- If something is unclear, ask rather than assume
- When writing tests, follow the testing rules above

---

## Current focus / known issues

> Update this section regularly — it is the most useful thing you can tell an AI assistant.

- [ ] What you are working on right now
- [ ] Known bugs or rough edges
- [ ] Areas of the code that need extra care
