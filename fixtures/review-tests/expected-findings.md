# Expected findings — `review-tests` fixture

Run `review-tests` against `fixtures/review-tests/fixture-project`.

| #   | Category                                | Location                                | What should be flagged                                                                                                                                                                                                            |
| --- | --------------------------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Coverage-scope mismatch                 | `vitest.config.ts`                      | Coverage `include` only covers `src/utils/**`; `src/components/` and `src/hooks/` have real logic and zero tests, but are silently excluded from the measured percentage — the coverage number is not measuring the whole project |
| 2   | Tautological assertion                  | `math.test.ts`, "adds two numbers"      | `expect(add(2, 3)).toBeTruthy()` passes for any non-falsy result, never checks the actual value                                                                                                                                   |
| 3   | Wrong expected value                    | `math.test.ts`, "adds negative numbers" | Asserts `add(-2, -3)` equals `1`; the correct result is `-5`                                                                                                                                                                      |
| 4   | Missing edge case                       | `math.test.ts`, `isPositive`            | Only the trivial positive case (`5`) is tested; `0` and a negative number are the obvious edge cases for a function named `isPositive` and neither is covered                                                                     |
| 5   | Untested files hidden by coverage scope | `Button.tsx`, `useToggle.ts`            | Both have real logic and no test file at all; because they're excluded from `vitest.config.ts`'s coverage `include`, this doesn't show up as a coverage gap — the direct consequence of issue #1                                  |

**Not expected to be flagged:** `isPositive`'s positive-case test and
`add`'s basic structure — both are correctly written for what they test;
the problem is what's missing around them, not what's there.

**Severity note:** issue #1 is the load-bearing one — it's what makes
issue #5 invisible. A correct run should connect the two, not report them
as unrelated findings.

**A framing note on issue #3.** A real run (`results-log.md`, 2026-08-05,
actual `vitest run --coverage`) confirmed this test fails outright —
`AssertionError: expected -5 to be 1` — it doesn't pass silently the way
issue #2's tautology does. That makes it a weaker demonstration of
`review-tests`' specific value than the other four issues here: anyone
running `npm test` would see this failure immediately, without needing a
dedicated test-quality review to surface it. It's still a legitimate
finding — review-tests should still name it, the same way it would name
any other test-quality issue it reads — but don't treat "review-tests
caught issue #3" alone as proof the skill is pulling its weight the way
catching #1, #2, or #5 would. Those three are invisible without it; #3
isn't.
