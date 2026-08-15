# Toolkit Health Check

This toolkit makes claims ("this reduces AI-introduced bugs," "this catches
low-quality tests") that would otherwise be unmeasured. Run this check
quarterly, or after adopting the toolkit into a new project. It pulls from
`metrics/findings-log.md` — the raw, per-run data — rather than starting
from scratch each time.

## 0. Pull the raw data

Before anything else, open `findings-log.md` and filter to the period you're
reviewing. Everything below is analysis of that log, not a separate
investigation.

## 1. Which skills are earning their place?

For each skill, count from the log: how many runs, how many were `Clean` vs.
`Found`, and whether findings were real (led to a fix or a filed issue) or
noise. A skill with many runs and zero findings ever is either confirming
solid code or isn't sensitive enough to be useful — the log won't tell you
which, but it tells you to go check.

## 2. Are the gates being bypassed?

```bash
git log --all --grep="no-verify" --oneline
git log --all -p | grep -c -- "--no-verify"
```

A rising count means the local hooks are friction people route around, not
guardrails people trust. If it's happening often, the hooks are probably too
slow or too strict — fix the hook, don't just note the workaround.

## 3. Is CI catching real problems, or just failing on noise?

Pull the last 20 CI runs on `main` and classify each failure:
- caught a real bug/regression
- flaky (passed on rerun with no code change)
- caused by an environment/config issue, not the code

```bash
gh run list --branch main --limit 20 --json conclusion,name,createdAt
```

High flaky-failure rate erodes trust in the pipeline faster than it prevents
bugs — treat it as a bug in the pipeline itself.

## 4. Is coverage trending, not just passing?

Coverage passing the 80% gate tells you nothing about whether it's trending
up or down over time — and per the `review-tests` skill's coverage-scope
check, confirm the denominator is still the full source tree before trusting
the percentage at all. Track the number from the CI coverage artifact each
month:

| Month | Line coverage | Function coverage | Scope verified? |
|-------|---------------|--------------------|-------------------|
|       |               |                    |                   |

## 5. Before/after comparison

The strongest evidence this toolkit works: pick one project that adopted it
and one that didn't (or a before/after on the same project), and compare:
- bug reports per month
- time-to-detect for regressions (caught in CI vs. caught in production)
- PR review comments flagging things the hooks/skills should have caught

Cross-reference against `findings-log.md` for concrete examples rather than
impressions — write the result here, even if it's inconclusive. An honest
"no measurable difference yet, sample size too small" is more credible than
an unverified claim of success.
