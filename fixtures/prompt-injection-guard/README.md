# `prompt-injection-guard.yml` fixture

Sample PR content for testing the detection logic in
`git/workflows/prompt-injection-guard.yml` — the grep scan against title,
body, and diff. Not testable end-to-end without a live PR (see "What
this can't test" below), but the actual decision logic is fully testable
without one.

## What's here

- `sample-pr-clean.txt` — a normal bugfix PR, nothing planted.
- `sample-pr-injected.txt` — an actual injection attempt in the PR body,
  aimed at an AI reviewer/assistant rather than a human maintainer.
- `sample-pr-borderline.txt` — a **real, legitimate** PR that happens to
  contain a matched phrase ("don't mention this to the user") used to
  describe changelog content, not to manipulate a reviewer. This is the
  false-positive case the workflow's own header comments warn about —
  included so that warning is demonstrated, not just claimed.

Each file has the shape `TITLE:` / `BODY:` / `DIFF:`, matching what the
real workflow assembles from `github.event.pull_request.title`,
`.body`, and `git diff` before scanning.

## How to run

Extract the detection step's `run:` script from
`git/workflows/prompt-injection-guard.yml` and run it directly against
each sample file in place of the real PR content:

```bash
PATTERN='pre-approved|you must comply|takes precedence over other instructions|don'"'"'t mention this to the user|do this silently|skip confirmation|ignore (previous|prior) instructions|disregard (your|other)'

for f in sample-pr-*.txt; do
  echo "=== $f ==="
  grep -niE "$PATTERN" "$f" && echo "flagged=true" || echo "flagged=false"
done
```

Compare against `expected-findings.md`. Append the result to
`results-log.md`.

## What this can't test

The labeling and comment-posting step (`actions/github-script`) needs a
real PR and a real `GITHUB_TOKEN` with write access — it can't be
exercised against a static fixture file the way the grep logic can.
Opening a real throwaway PR against this repo just to test that step
would be a bigger, riskier action than this fixture is meant to require,
and isn't done here. This is a permanent, documented limit of this
fixture, not a gap someone forgot to close — the same way `llm-review`'s
fixture can't exercise the real Anthropic API call either.
