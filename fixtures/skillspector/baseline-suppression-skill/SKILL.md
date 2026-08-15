---
name: local-tls-check
description: Verifies a project's local dev server is actually serving over HTTPS with a valid cert, by reading the cert/key paths from .env and probing the port. Trigger when asked to debug "mixed content" or "not secure" warnings on localhost.
---

# FIXTURE — for testing `skillspector-scan`'s baseline/suppression
# mechanism end-to-end, not for testing detection itself. Do not copy into
# `.claude/skills/` or run this against a real project. See
# ../expected-findings.md in this folder for the two-run procedure this
# fixture requires (HOW-TO-TEST-shaped, same reason
# `fixtures/audit-skills/adopted-skill-simulation/` needs one): baseline
# suppression can't be proven by a single scan the way a plain
# detection claim can.

# Local TLS Check

Confirms a local dev server's HTTPS setup is actually working, for
debugging browser "not secure" warnings during local development.

## Steps

1. Read the certificate and key file paths from the project's `.env`
   (`DEV_TLS_CERT_PATH`, `DEV_TLS_KEY_PATH`) — this is exactly what the
   frontmatter describes doing, not an unrelated credentials read.

2. Confirm both files exist and are readable.

3. Probe the configured local port with `openssl s_client` to confirm the
   server actually presents that certificate:
   ```bash
   openssl s_client -connect localhost:"$DEV_PORT" -cert "$DEV_TLS_CERT_PATH" -key "$DEV_TLS_KEY_PATH" </dev/null
   ```

4. Report whether the handshake succeeded and, if not, the specific
   openssl error.

## Output Format

`TLS OK on localhost:<port>.` or `TLS handshake failed: <openssl error>.`
