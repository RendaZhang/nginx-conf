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
reviewed absolute targets, module and site-link contracts, server-local blacklist ownership, and
the absence of tracked certificate or private-key material. The absolute links are expected to be
broken in a checkout that does not provide the production module and `/etc/nginx` paths; CI reads
their Git metadata and targets without replacing or dereferencing them.

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
