---
name: review-tests
description: Review test files for quality issues like wrong assertions, missing edge cases, poor naming, and coverage gaps — and verify the coverage report itself is measuring what it claims to. Trigger for test quality review or before a PR.
---

# Review Tests Skill

You are performing a focused code review of the test files in this project. Your goal is to identify concrete, actionable quality issues — not style preferences — and to confirm the coverage number can actually be trusted before treating it as evidence of anything.

## Steps

0. **Check the project's test environment before anything else — read it from memory if it's already known.** `AGENTS.md`'s `## Testing` section is where this belongs; check there first instead of re-deriving it every run:
   - If `AGENTS.md` has a `## Testing` section with a stack, coverage command, and coverage threshold, sanity-check it against reality (does the named config file — `vitest.config.ts`, `jest.config.js`, etc. — still exist? does `package.json` still list that test runner?). If it checks out, use it directly and skip straight to step 1.
   - If it's missing, stale, or `AGENTS.md` doesn't exist, detect it yourself: the test runner and coverage tool (from `package.json` dependencies), the coverage config file and its `include`/`all`-equivalent setting, the coverage script name, and the configured threshold if any.
   - If `AGENTS.md` exists, write what you detected into its `## Testing` section (stack line, `Commands` block, coverage threshold) so the next run — by this skill, another skill, or a human — doesn't repeat the detection work. Say in your output that you did this and what you wrote, the same way a `Found → Fixed` outcome is stated rather than left implicit.
   - If `AGENTS.md` doesn't exist at all, detect fresh for this run and note in the report that adding one (see `ai/AGENTS.md` in the toolkit) would let future runs skip this step — but don't create the file yourself; that's outside this skill's job.
   - A stale cache is worth flagging on its own: if what's written in `AGENTS.md` doesn't match what you actually found (test runner changed, threshold changed), say so explicitly rather than silently overwriting it.

1. **Run tests with coverage**, not a plain test run — coverage is the default, not an opt-in extra. Use the project's coverage script (e.g. `npm run test:coverage`) — the one from step 0.

2. **Verify the coverage report's scope before trusting its percentage.** This is a required step, not optional:
   - Glob the actual source files that should be under test (e.g. `src/**/*.{ts,tsx}`, excluding `*.test.*`, `*.spec.*`, type-only files, and config).
   - Compare that list against the files the coverage report actually measured.
   - If the coverage tool measured meaningfully fewer files than exist in the source tree (e.g. only files directly imported by a test, rather than all source files), this is a **coverage configuration issue** — report it as its own top-level finding, above the per-file test-quality findings, regardless of what percentage the tool printed. A high percentage over the wrong denominator is not a passing result; it's an unverified one.
   - Common root cause: the coverage config is missing an `include`/`all` (or equivalent) setting, so the tool only instruments files a test happens to import, rather than the full source tree. If you find this, name the specific config file and the fix.

3. **Find all test files** using Glob with patterns like `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**/*`.

4. **Read each test file** and review it against the criteria below.

5. **Report findings** grouped by file, with line numbers where applicable — with the coverage-scope finding (if any) reported first, before any file-level findings.

6. **Log the result.** Append one row to `metrics/findings-log.md`: date, project, `review-tests`, an outcome (`Clean`, `Found → Fixed` if issues were fixed this run, or `Found — open`), and one sentence covering the coverage-scope result plus the count of test-quality issues found. If the coverage-scope check found a mismatch, say so explicitly in the log line even if you also fixed it — that's the finding worth being able to look back on.

## Review Criteria

### Coverage scope (checked first, applies to the whole report)
- Does the coverage tool's file count match the actual source file count?
- Are entire files or directories (e.g. all components, a specific hook) invisible to the report because nothing imports them in a test?
- Does the configured threshold (e.g. 80%) mean anything given what's actually being measured?

### Correctness
- Assertions that can never fail (e.g., `expect(true).toBe(true)`, tautologies)
- Wrong expected values (typos like `'JavaScript111'` instead of `'JavaScript'`)
- Tests that test the mock, not the real behavior
- Missing `await` on async operations

### Test naming
- Vague names like `it('works')` or `it('test 1')`
- Names that don't describe the expected behavior or the scenario
- Names that duplicate the describe block redundantly

### Assertions
- Missing assertions (a test that runs code but asserts nothing)
- Weak assertions (`toBeTruthy` when `toBe('exact value')` is appropriate)
- Asserting too many unrelated things in one test

### Edge cases and coverage
- Happy path only — no error/null/empty/boundary cases tested
- Obvious inputs that are untested (empty string, 0, negative numbers, undefined, very long strings)
- Missing tests for recently added code paths visible in the source files
- Files with zero tests that the coverage scope check (above) surfaced — cross-reference rather than re-deriving

### Test isolation
- Tests that depend on execution order (shared mutable state between tests)
- Missing cleanup (timers, mocks, side effects left over)
- Global state modified without reset

### Structure
- `describe` blocks that group unrelated tests
- Deeply nested describes that make failures hard to trace
- Repeated setup code that belongs in `beforeEach`

## Output Format

---

## Test Review

### Coverage Scope

*(Only include this section if a mismatch was found. If the coverage report's file count matches the actual source file count, state that explicitly instead: "Coverage scope verified — N of N source files measured.")*

**Coverage tool measured:** 1 of 12 source files
**Configured threshold:** 80% lines/functions
**Root cause:** `vitest.config.ts` has no `coverage.include`/`coverage.all`, so v8 only instruments files a test directly imports.
**Impact:** The 80% gate is passing against a 1-file denominator. It provides no signal about the other 11 files.
**Fix:** Add `coverage.all: true` (or explicit `include` globs matching the full `src/` tree) to the coverage config, then re-run — expect the percentage to drop until real tests are added for the newly-visible files.

### `src/utils/__tests__/foo.test.js`

| # | Severity | Line | Issue |
|---|----------|------|-------|
| 1 | 🔴 CRITICAL | 21 | Wrong expected value — `'JavaScript111'` should be `'JavaScript'` |
| 2 | 🟡 WARNING  | 45 | No edge case for empty string input |
| 3 | 🔵 INFO     | 67 | Test name is vague — rename to describe the expected behavior |

---

### Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 1 |
| 🟡 WARNING  | 2 |
| 🔵 INFO     | 1 |
| **Total**   | **4** |

**Fix first:** [If a coverage scope mismatch was found, this is always the answer — an unmeasured file outranks any single wrong assertion, because it means unknown numbers of untested behaviors exist with no visibility into them at all.]

---

Severity guide:
- 🔴 **CRITICAL** — test is wrong or misleading (passes when it should fail, or vice versa), **or the coverage report cannot be trusted** (scope mismatch)
- 🟡 **WARNING** — meaningful gap in coverage or assertion quality
- 🔵 **INFO** — naming or structure improvement

If a file has no issues, omit it from the report. If no issues are found at all *and* coverage scope is verified: `All test files look good, and coverage scope is verified. No issues found.`
