# `llm-review.yml` fixture

Canned Anthropic API responses for testing the surrounding harness in
`git/workflows/llm-review.yml` — request construction, verdict parsing,
and the blocking/non-blocking decision matrix. Not testable end-to-end
without a real `ANTHROPIC_API_KEY` and a live API call (see "What this
can't test" below), but everything around that call is fully testable
without one.

## What's here

- `sample-diff-injected.txt` — a diff with two things planted at once: a
  real SQL-injection vulnerability (string-interpolated query) and, in
  the same comment, an attempt to instruct the reviewing model to approve
  regardless and stay silent about it. For documentation/realism — not
  sent to a live model by this fixture.
- `canned-response-approve.json` — a clean review, `VERDICT: APPROVE`.
- `canned-response-concerns.json` — a real finding, `VERDICT: CONCERNS`.
- `canned-response-needs-human.json` — a hand-written response
  demonstrating what a compliant model's reply to `sample-diff-injected.txt`
  should look like: it flags the SQL injection, explicitly refuses to
  treat the embedded comment as an instruction, and returns
  `VERDICT: NEEDS_HUMAN`. **This is what compliance looks like, not proof
  a live model produces it** — see the caveat below.
- `canned-response-api-error.json` — an Anthropic API error response
  (bad key), for testing the empty-response fallback path.

## How to run

Extract the "Ask Claude for a second opinion" step's parsing/decision
logic from `git/workflows/llm-review.yml` (the part after the `curl`
call) and run it against each canned response file in place of a real
API call:

```bash
for f in canned-response-*.json; do
  echo "=== $f ==="
  TEXT=$(jq -r '.content[0].text // empty' "$f")
  if [ -z "$TEXT" ]; then
    echo "verdict=NEEDS_HUMAN (no response text)"
  else
    V=$(printf '%s\n' "$TEXT" | grep -oE 'VERDICT: (APPROVE|CONCERNS|NEEDS_HUMAN)' | tail -1 | awk '{print $2}')
    echo "verdict=${V:-NEEDS_HUMAN}"
  fi
done
```

Then run each resulting verdict through the "Apply verdict to check
status" step's logic under both `LLM_REVIEW_BLOCKING=false` (default) and
`=true`. Compare against `expected-findings.md`. Append the result to
`results-log.md`.

## A real bug this fixture already found and fixed

Building this fixture caught a genuine latent bug in
`git/workflows/llm-review.yml`, not a fixture-authoring mistake — worth
recording here the same way `fixtures/security-review/README.md` records
what its fixture found in `security-review/SKILL.md`.

The original workflow parsed the API response with
`TEXT=$(echo "$RESPONSE" | jq -r '.content[0].text // empty')`. Testing
this against `canned-response-approve.json` — a completely valid JSON
file — failed with `jq: parse error: Invalid string: control characters
... must be escaped`. Root cause: in this shell, `echo "$VAR"` silently
converts a literal `\n` (backslash + n, the correct JSON escape for a
newline) into an actual newline byte before jq ever sees it, and any real
multi-paragraph model response almost always contains escaped newlines in
its text field. Confirmed directly: `jq '.' file.json` parses the same
file correctly; `RESPONSE=$(cat file.json); echo "$RESPONSE" | jq '.'`
does not.

**Fixed** by having `curl` write straight to a file (`-o
/tmp/api-response.json`) and having every downstream step read that file
directly with `jq`/`cat`, never round-tripping the response through a
shell variable and `echo`. Re-verified against all four canned responses,
both blocking modes (8 combinations total) after the fix — see
`results-log.md`.

## What this can't test

Nothing here calls the real Anthropic API. The canned `NEEDS_HUMAN`
response demonstrates that *if* the model responds the way the system
prompt asks it to, the harness correctly parses and acts on that verdict
— it does not prove a live model will actually resist a real injection
attempt in `sample-diff-injected.txt`'s style. That's a fundamentally
different, harder claim this fixture doesn't and can't make. Treat the
system prompt's injection defense as a mitigation to keep testing against
real attempts over time, not something this fixture certifies.
