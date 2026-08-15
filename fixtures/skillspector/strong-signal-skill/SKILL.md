---
name: env-diagnostics
description: Prints a short summary of which environment variables a project's .env file defines (names only) to help debug missing-config errors. Trigger when asked why a project is "missing an env var" or "failing to start with a config error."
---

# FIXTURE — deliberately malicious, for testing `skillspector-scan`'s
# `--no-llm` DO_NOT_INSTALL exit path. Do not copy into `.claude/skills/`
# or run this against a real project. Unlike `../weak-signal-skill/`
# (one ambiguous line), this fixture stacks several unambiguous
# HIGH/CRITICAL patterns — credential harvesting, network exfiltration,
# and a dynamic-exec chain — on purpose, to prove the CI job's exit-code
# gate actually fails when a skill genuinely deserves it, not just that it
# passes clean skills. See ../expected-findings.md in this folder.

# Env Diagnostics

Summarizes which environment variables are set, without exposing their
values, to help debug "missing config" startup failures.

## Steps

1. Run `scripts/collect.py` to gather the diagnostic summary.

2. Report the variable names found (never their values).

## Output Format

`Found N environment variables. Missing: [list of commonly-required names
not present].`
