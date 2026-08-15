# Results Log — `llm-review.yml` fixture

Every run of the extracted parsing/decision logic against the canned
responses here gets a row. Re-run and add a row whenever
`git/workflows/llm-review.yml`'s parsing or decision logic changes.

| Date | Run by | Matched expected? | Detail |
|------|--------|---------------------|--------|
| 2026-08-11 | Extracted "Ask Claude" + "Apply verdict" logic from `git/workflows/llm-review.yml`, run against all 4 canned responses × 2 blocking modes (8 combinations) | No, on first attempt — real bug found | **First run (original `echo "$RESPONSE" \| jq` logic):** all 4 canned responses failed to parse — `jq: parse error: Invalid string: control characters ... must be escaped` — even though every file is independently valid JSON (confirmed via `python3 -m json.tool` and `jq '.' file.json` directly). Root cause: this shell's `echo "$VAR"` converts a literal `\n` inside the variable into an actual newline byte before jq sees it. All 4 files incorrectly fell through to the empty-response/`NEEDS_HUMAN` fallback path regardless of their real verdict. **Fixed** in `git/workflows/llm-review.yml`: `curl` now writes to a file (`-o /tmp/api-response.json`) and every downstream step reads that file directly, never round-tripping through `echo`. **Second run (fixed logic):** all 8 combinations matched `expected-findings.md` exactly — APPROVE→0/0, CONCERNS→0/1, NEEDS_HUMAN→0/1, api-error→0/1 (blocking=false/true). |
