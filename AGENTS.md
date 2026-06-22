# AGENTS.md

Last updated: 2026-06-22

This file gives AI coding agents the project context needed to work safely in the
`nginx-conf` operations repository. The repository is public, so do not add
secrets, private host details, real environment values, SSH keys, certificates,
private IP allowlists, cookies, or tokens to this file or to any committed
document.

## Project Role

- This repository mirrors the production Nginx configuration for
  `www.rendazhang.com`.
- It documents reverse proxy, static serving, TLS, CSP/security headers, cache
  behavior, and small-server operations.
- Related repositories:
  - `rendazhang`: Astro + React frontend deployed as static files.
  - `python-cloud-chat`: Flask backend served through `/cloudchat/*`.

## First Steps For Every Task

1. Run `git status --short --branch`.
2. Read the relevant docs before changing behavior:
   - `README.md`
   - `docs/SERVER_RUNBOOK.md`
   - `docs/TROUBLESHOOTING.md`
   - `docs/MIGRATION_GUIDE.md`
   - `docs/SMALL_SERVER_OPTIMIZATIONS.md`
   - `docs/REQUIREMENTS.md`
3. Keep changes scoped to Nginx config and operations docs.
4. Do not change frontend or backend code from this repo.
5. Do not use `--no-verify` unless the reason is explicit and documented.
6. Do not force push.

## Repository And Server Mapping

- Local repository: `nginx-conf`.
- Production Git worktree: `/etc/nginx`.
- Static frontend files are served from `/var/www/html`, but that directory is
  deployed by the frontend GitHub Actions workflow and is not this Git worktree.
- Backend code is managed separately in `/opt/cloudchat`.

## Files That Must Not Be Published Or Overwritten

- Certificate and private key directories.
- `.env` or environment files.
- Backups.
- Server-local runtime state.
- `ip-blacklist.conf`.

`ip-blacklist.conf` is intentionally ignored by Git. It is maintained on the
server as runtime state and must not be replaced by repository syncs.

## Validation

For docs-only changes:

```bash
pre-commit run --all-files
```

## Local Tooling Notes

- This repository normally does not own a project runtime pin. Local validation
  is mostly Git, pre-commit, and Nginx config checks.
- `mise` is not macOS-only. For Windows agents working across the three
  PersonalWeb repositories, prefer WSL2 + Ubuntu + mise as the supported local
  baseline. Native Windows PowerShell + mise may work, but it is not the primary
  validated environment for this operations repository.
- A developer machine may keep a non-committed parent workspace `.mise.toml` to
  provide shared Node/Python defaults for `rendazhang`, `python-cloud-chat`, and
  `nginx-conf`. Do not depend on that file in production docs or scripts; each
  code repository's committed runtime files remain authoritative where they
  exist.
- If a non-interactive shell resolves system Node/Python instead of mise, check
  that `~/.local/share/mise/shims` is on `PATH` and run `mise doctor`. Do not
  add machine-specific runtime paths to committed Nginx docs or config.

For Nginx config changes, validate on the authorized server before reload:

```bash
cd /etc/nginx
git pull --ff-only origin master
nginx -t
systemctl reload nginx
```

Do not reload Nginx when only documentation changed.

## Deployment

- Normal Nginx config release flow:
  1. Commit and push this repository.
  2. On the authorized production server:

     ```bash
     cd /etc/nginx
     git pull --ff-only origin master
     nginx -t
     systemctl reload nginx
     ```

  3. Perform read-only checks with `curl -I` for the affected routes.

- For docs-only updates, `git pull --ff-only` is enough; no `nginx -t` or reload
  is required unless configuration files changed.
- Never copy an entire local directory over `/etc/nginx`; use Git pull so ignored
  runtime files remain untouched.

## CSP And Security Header Constraints

- Security headers are centralized in `snippets/security-headers.conf`.
- Any `location` block that declares `add_header` must also preserve the
  intended security headers.
- The current frame policy supports:
  - same-origin Chat Widget iframe loading `/deepseek_chat/`;
  - Credly certificate iframe loading from `https://www.credly.com`.
- Preserve:
  - `frame-src 'self' https://www.credly.com`
  - `frame-ancestors 'self'`
  - `X-Frame-Options: SAMEORIGIN`
- Do not add `unsafe-inline` to `script-src` without explicit approval and a
  documented security rationale.
- Frontend rebuilds, Astro upgrades, Sentry output changes, and hydration
  directive changes may require CSP revalidation in browser console.

## Operations Safety

- Prefer `git pull --ff-only` on production worktrees.
- Do not run destructive Git commands on the server.
- Do not restart unrelated services.
- Do not print certificate contents, environment files, private keys, cookies,
  or full secret-bearing command output.
- If a config change affects TLS, CSP, proxying, cache, or redirects, include
  read-only production verification commands in the final report.

## Documentation Rules

- Public docs may mention repository names, public paths, public URLs, endpoint
  names, and placeholder environment variable names.
- Public docs must not include real secret values, private keys, cookies,
  certificates, IP allowlists, or local-only incident data that should remain
  private.
- Update the runbook and troubleshooting docs when production behavior changes.

## Final Report Checklist

When handing work back, include:

- What changed.
- What validation commands ran.
- Deployment/sync status.
- Whether `nginx -t` and reload ran.
- Any remaining risk or follow-up slice.
