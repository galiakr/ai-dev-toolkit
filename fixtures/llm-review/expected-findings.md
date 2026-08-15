# Expected findings — `llm-review.yml` fixture

Run the extracted parsing/decision logic (see `README.md`) against each
canned response, under both `LLM_REVIEW_BLOCKING` values.

| Response file | Parsed verdict | Exit, blocking=false (default) | Exit, blocking=true |
|---|---|---|---|
| `canned-response-approve.json` | `APPROVE` | 0 | 0 |
| `canned-response-concerns.json` | `CONCERNS` | 0 (comment-only) | 1 (fails the check) |
| `canned-response-needs-human.json` | `NEEDS_HUMAN` | 0 (comment-only) | 1 (fails the check) |
| `canned-response-api-error.json` | `NEEDS_HUMAN` (empty-response fallback) | 0 (comment-only) | 1 (fails the check) |

Every row except `APPROVE` should exit 0 under the default
(non-blocking) mode regardless of how bad the verdict is — this is by
design, matching the toolkit's flag-don't-block posture everywhere else.
Only `LLM_REVIEW_BLOCKING=true` should ever turn a non-`APPROVE` verdict
into a failing check.

**Not expected:** any response file should ever exit 1 under the default
`blocking=false` mode. If one does, that's a real bug in the "Apply
verdict to check status" step's logic, not a fixture problem.

## What a real run found (2026-08-11)

All 8 combinations (4 files × 2 blocking modes) were actually run against
the extracted logic, not reasoned about — see `results-log.md` for the
full output. All matched the table above **after** a real bug found
during this run was fixed in `git/workflows/llm-review.yml` itself: the
original `echo "$RESPONSE" | jq` pattern corrupted valid JSON containing
escaped newlines before jq ever parsed it (this shell's `echo` converts
literal `\n` to a real newline byte). See `README.md`'s "A real bug this
fixture already found and fixed" section for the full explanation and the
fix. Before the fix, all four canned responses incorrectly fell through
to the empty-response fallback path regardless of their actual content.
