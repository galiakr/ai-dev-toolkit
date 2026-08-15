# Expected findings — `prompt-injection-guard.yml` fixture

Run the workflow's extracted detection logic against each sample file (see
`README.md`).

| File | Expected | Why |
|------|----------|-----|
| `sample-pr-clean.txt` | `flagged=false` | Ordinary bugfix PR, no matched phrasing anywhere |
| `sample-pr-injected.txt` | `flagged=true`, matches on "pre-approved" and "skip confirmation" | Body explicitly addresses "reviewer/assistant" and tries to preempt review — the real attack this workflow exists to catch |
| `sample-pr-borderline.txt` | `flagged=true`, matches on "don't mention this to the user" | **This is a real false positive, expected on purpose.** The phrase describes changelog content ("don't mention this [flag removal] to the user in the changelog"), not an instruction to a reviewer — but the workflow's regex has no way to tell the difference, and by design doesn't try to; it flags any match for a human to look at. |

## What this proves

The workflow's own header comments state its tradeoff plainly: flag on
any match, never auto-block, because a false positive costs a real
contributor and this template has no appeals process. The borderline
sample is what makes that claim checkable instead of asserted — a real,
plausible PR that trips the filter for an entirely innocent reason,
demonstrating exactly the cost the header comments already admit to.
That's the right failure mode for this design (a human looks and
dismisses it in seconds) rather than a flaw to fix — "fixing" it would
mean adding judgment to a plain grep, which is what `audit-skills`' model-
classification Advanced section exists for in a different context, not
what this lightweight PR-scanning workflow is trying to be.
