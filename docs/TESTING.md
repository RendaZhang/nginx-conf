# Nginx Repository Validation

The repository validation boundary is intentionally portable. Run the same checks locally that
GitHub Actions runs for Pull Requests, `master` pushes, and manual dispatches:

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
or reproduce server-local includes. A configuration release still requires `nginx -t` against the
complete production filesystem before any reload. Documentation-only changes do not require that
production gate.
