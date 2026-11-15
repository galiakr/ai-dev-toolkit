#!/usr/bin/env bash
# Summarize what the toolkit's skills and checks have actually found, per
# repo, from GitHub issues labelled `found-by:<source>`.
#
# Usage:
#   ./scripts/toolkit-report.sh owner/repo [owner/repo ...]
#
# Requires `gh` (authenticated) and `jq`. Read-only: it never creates,
# edits, or comments on anything.
#
# This only counts what was recorded as an issue with a found-by: label.
# A project that logs to metrics/findings-log.md instead won't show up
# here — read that file for those. And a count is not a verdict: open the
# issues before claiming a skill "works" (see metrics/toolkit-health.md).

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 owner/repo [owner/repo ...]" >&2
  exit 1
fi

for tool in gh jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    exit 1
  fi
done

for repo in "$@"; do
  echo "## $repo"
  echo ""

  # Up to 1000 issues per repo; raise --limit if a repo ever outgrows it.
  if ! issues=$(gh issue list -R "$repo" --state all --limit 1000 \
      --json number,state,stateReason,labels 2>/dev/null); then
    echo "Could not read issues for $repo (does it exist, and is gh authenticated?)"
    echo ""
    continue
  fi

  echo "$issues" | jq -r '
    [ .[]
      | . as $i
      | ($i.labels | map(.name)) as $names
      | $names[]
      | select(startswith("found-by:"))
      | { source: (. | ltrimstr("found-by:")),
          outcome: (
            if ($names | index("wontfix")) or ($names | index("invalid")) then "noise"
            elif $i.state == "OPEN" then "open"
            elif $i.stateReason == "COMPLETED" then "fixed"
            else "closed-other" end) }
    ]
    | if length == 0 then
        "No issues with a found-by: label yet."
      else
        (["Source", "Total", "Fixed", "Open", "Noise", "Closed (other)"] | join(" | ")),
        (["---", "---", "---", "---", "---", "---"] | join(" | ")),
        ( group_by(.source)[]
          | [ .[0].source,
              length,
              (map(select(.outcome == "fixed")) | length),
              (map(select(.outcome == "open")) | length),
              (map(select(.outcome == "noise")) | length),
              (map(select(.outcome == "closed-other")) | length) ]
          | map(tostring) | join(" | ") )
      end'

  # Clean runs live as comments on the skill-runs tracking issue, if any.
  runs=$(echo "$issues" | jq -r '[.[] | select(.labels | map(.name) | index("skill-runs"))][0].number // empty')
  if [ -n "$runs" ]; then
    count=$(gh issue view "$runs" -R "$repo" --json comments --jq '.comments | length')
    echo ""
    echo "Skill runs logged (including clean runs): $count — see #$runs"
  fi
  echo ""
done
