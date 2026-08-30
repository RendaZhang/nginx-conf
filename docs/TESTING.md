# Nginx Repository Validation

The repository validation boundary is intentionally portable. Run the same checks locally that
GitHub Actions runs before any deployment for Pull Requests, `master` pushes, and manual
dispatches:

```bash
bash scripts/validate_repository.sh
bash -n scripts/*.sh
pre-commit run --all-files
```

CI uses Python 3.13.14 and `pre-commit==4.2.0` as pinned tooling. Python is not an Nginx runtime
requirement for this repository.

The validator checks required tracked configuration files, shell syntax, tracked symlink modes and
reviewed absolute targets, module and site-link contracts, server-local blacklist ownership, the
absence of tracked certificate or private-key material, and the portable edge-security contract:
direct socket-peer identity, replacement rather than extension of forwarded chains, explicit
CloudChat cache allowlisting, independent paid-Chat limiting with 429 semantics, loopback purge,
version suppression, and required frame policy. The absolute links are expected to be broken in a
checkout that does not provide the production module and `/etc/nginx` paths; CI reads their Git
metadata and targets without replacing or dereferencing them.

These checks do not parse Nginx configuration syntax, load installed modules, read certificates,
or reproduce server-local includes. Pull Requests stop after repository validation. A successful
`master` push or `master` manual dispatch then serializes a production job that requires a clean
tracked `/etc/nginx` checkout, fetches `origin/master`, proves a fast-forward, and synchronizes the
exact workflow SHA while preserving ignored runtime state.

The production job classifies root Nginx config/parameter/type files and files under
`modules-enabled/`, `sites-available/`, `sites-enabled/`, and `snippets/` as behavior paths. A
change to one of those paths runs production `nginx -t` and then reloads Nginx. Workflow, script,
and documentation-only commits sync without testing or reloading. A manual dispatch with
`force_reload=true` exercises the same authoritative test/reload path on an unchanged commit.

Every deployment verifies the exact final SHA, clean tracked worktree, ignored/untracked and
byte-identical `ip-blacklist.conf`, active Nginx master identity, public page status, backend health,
and the required frame policy. SSH credentials are removed from the runner unconditionally. A
failed production job must be repaired through a normal follow-up commit; do not manually pull or
reload to make the failed run appear successful.

## Production Edge Security Checks

Run these checks only after the exact deployment workflow succeeds. Use no real cookie, token, cache
key, or user data.

Client identity and Chat limiting can be verified without invoking the model by sending an empty
JSON object while rotating reserved example forwarding addresses. Accepted requests retain the
backend's 400 validation response; an excess request must return 429 because all requests share the
socket-peer bucket:

```bash
for octet in 1 2 3 4 5; do
  curl -sS -o /dev/null -w '%{http_code}\n' \
    -H "X-Forwarded-For: 198.51.100.${octet}" \
    -H 'Content-Type: application/json' \
    --data '{}' \
    https://www.rendazhang.com/cloudchat/deepseek_chat
done
```

Use a unique query to prove that only the public test route owns dynamic cache state. With
`proxy_cache_min_uses 2`, three anonymous requests should progress through `MISS`, `MISS`, `HIT`;
auth/health responses should not expose an active `X-Cache-Status` value:

```bash
stamp="$(date +%s)"
for attempt in 1 2 3; do
  curl -sS -D - -o /dev/null \
    "https://www.rendazhang.com/cloudchat/test?edge-check=${stamp}" |
    tr -d '\r' | grep -i '^X-Cache-Status:'
done
curl -sS -D - -o /dev/null \
  "https://www.rendazhang.com/cloudchat/auth/healthz?edge-check=${stamp}" |
  tr -d '\r' | grep -i '^X-Cache-Status:' || true
```

The purge boundary uses fake keys only. A public request that spoofs loopback must be denied; from
an approved server session the same fake-key path may reach the purge handler over `127.0.0.1` or
`::1`. Never substitute a real cache key.

Finally, verify that the public `Server` header has no version, `X-XSS-Protection` is absent, and
HSTS, CSP, XFO, `nosniff`, Referrer Policy, same-origin Chat Widget framing, Credly framing, direct
Chat streaming, public routes, and backend health remain intact. Inspect only the scoped deployment
window for Nginx/CloudChat errors and confirm neither service restarted.
