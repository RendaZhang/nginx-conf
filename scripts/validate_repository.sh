#!/usr/bin/env bash

set -euo pipefail

readonly ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

pass() {
  printf 'OK: %s\n' "$*"
}

index_mode() {
  local path="$1"
  local entry

  entry="$(git ls-files -s -- "$path")"
  [[ -n "$entry" ]] || fail "required path is not tracked: $path"
  printf '%s' "${entry%% *}"
}

expected_link_target() {
  case "$1" in
    modules-enabled/50-mod-http-cache-purge.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-http-cache-purge.conf'
      ;;
    modules-enabled/50-mod-http-geoip2.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-http-geoip2.conf'
      ;;
    modules-enabled/50-mod-http-image-filter.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-http-image-filter.conf'
      ;;
    modules-enabled/50-mod-http-xslt-filter.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-http-xslt-filter.conf'
      ;;
    modules-enabled/50-mod-mail.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-mail.conf'
      ;;
    modules-enabled/50-mod-stream.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-stream.conf'
      ;;
    modules-enabled/70-mod-stream-geoip2.conf)
      printf '%s' '/usr/share/nginx/modules-available/mod-stream-geoip2.conf'
      ;;
    sites-enabled/rendazhang.conf)
      printf '%s' '/etc/nginx/sites-available/rendazhang.conf'
      ;;
    *)
      return 1
      ;;
  esac
}

required_files=(
  .gitattributes
  .gitignore
  .pre-commit-config.yaml
  fastcgi.conf
  fastcgi_params
  mime.types
  nginx.conf
  proxy_params
  scgi_params
  sites-available/rendazhang.conf
  snippets/fastcgi-php.conf
  snippets/security-headers.conf
  snippets/snakeoil.conf
  snippets/ssl-rendazhang.conf
  uwsgi_params
)

for path in "${required_files[@]}"; do
  [[ "$(index_mode "$path")" == "100644" ]] ||
    fail "required file has unexpected Git mode: $path"
  [[ -f "$path" && ! -L "$path" ]] ||
    fail "required path is not a regular file: $path"
done
pass "required configuration and snippet files are tracked regular files"

script_count=0
while IFS= read -r script; do
  [[ -n "$script" ]] || continue
  script_count=$((script_count + 1))
  [[ "$(index_mode "$script")" == "100755" ]] ||
    fail "shell script must be tracked executable: $script"
  [[ -f "$script" && ! -L "$script" ]] ||
    fail "tracked shell script is not a regular file: $script"
  bash -n "$script" || fail "Bash syntax check failed: $script"
done < <(git ls-files -- '*.sh')
[[ "$script_count" -gt 0 ]] || fail "no tracked shell scripts were found"
pass "$script_count tracked shell scripts pass Bash syntax checks"

expected_links=(
  modules-enabled/50-mod-http-cache-purge.conf
  modules-enabled/50-mod-http-geoip2.conf
  modules-enabled/50-mod-http-image-filter.conf
  modules-enabled/50-mod-http-xslt-filter.conf
  modules-enabled/50-mod-mail.conf
  modules-enabled/50-mod-stream.conf
  modules-enabled/70-mod-stream-geoip2.conf
  sites-enabled/rendazhang.conf
)

for link in "${expected_links[@]}"; do
  expected_target="$(expected_link_target "$link")"
  [[ "$(index_mode "$link")" == "120000" ]] ||
    fail "expected tracked symlink mode 120000: $link"
  [[ -L "$link" ]] || fail "working tree path is not a symlink: $link"
  [[ "$expected_target" == /* ]] || fail "reviewed link target is not absolute: $link"

  if ! cmp -s \
    <(printf '%s' "$expected_target") \
    <(git cat-file blob ":$link"); then
    fail "tracked symlink target differs from reviewed target: $link"
  fi

  if ! cmp -s \
    <(printf '%s\n' "$expected_target") \
    <(readlink "$link"); then
    fail "working tree symlink target differs from reviewed target: $link"
  fi

  [[ "$(git check-attr text -- "$link")" == "$link: text: unset" ]] ||
    fail "symlink must remain excluded from text normalization: $link"

  case "$link" in
    modules-enabled/*)
      [[ "$expected_target" == /usr/share/nginx/modules-available/* ]] ||
        fail "module link target is outside the reviewed prefix: $link"
      ;;
  esac
done

tracked_link_count=0
while IFS=$'\t' read -r metadata path; do
  [[ "${metadata%% *}" == "120000" ]] || continue
  tracked_link_count=$((tracked_link_count + 1))
  expected_link_target "$path" >/dev/null ||
    fail "unexpected tracked symlink: $path"
done < <(git ls-files -s)
[[ "$tracked_link_count" -eq "${#expected_links[@]}" ]] ||
  fail "tracked symlink count differs from the reviewed contract"
pass "$tracked_link_count tracked symlinks match reviewed absolute targets"

grep -Eq \
  '^[[:space:]]*include[[:space:]]+/etc/nginx/modules-enabled/\*\.conf;[[:space:]]*$' \
  nginx.conf || fail "nginx.conf is missing the modules-enabled include"
grep -Eq \
  '^[[:space:]]*include[[:space:]]+/etc/nginx/sites-enabled/\*;[[:space:]]*$' \
  nginx.conf || fail "nginx.conf is missing the sites-enabled include"
grep -Eq \
  '^[[:space:]]*include[[:space:]]+/etc/nginx/ip-blacklist\.conf;[[:space:]]*$' \
  nginx.conf || fail "nginx.conf is missing the server-local blacklist include"
pass "required production include contracts remain present"

if git ls-files --error-unmatch -- ip-blacklist.conf >/dev/null 2>&1; then
  fail "ip-blacklist.conf must remain untracked runtime state"
fi
git check-ignore -q --no-index -- ip-blacklist.conf ||
  fail "ip-blacklist.conf must remain ignored"
git check-ignore -q --no-index -- cert/repository-check.pem ||
  fail "certificate directory must remain ignored"
git check-ignore -q --no-index -- ssl/repository-check.key ||
  fail "private-key directory must remain ignored"
pass "runtime blacklist and certificate directories remain Git-excluded"

while IFS= read -r path; do
  case "$path" in
    ip-blacklist.conf | */ip-blacklist.conf | \
      cert/* | */cert/* | \
      ssl/* | */ssl/* | \
      letsencrypt/* | */letsencrypt/* | \
      *.cer | *.crt | *.der | *.jks | *.key | *.p12 | *.pem | *.pfx)
      fail "sensitive or runtime-owned path must not be tracked: $path"
      ;;
  esac
done < <(git ls-files)

pem_begin='-----BEGIN '
pem_pattern="${pem_begin}(RSA |EC |OPENSSH )?PRIVATE KEY-----|${pem_begin}CERTIFICATE-----"
if git grep -I -q -E -e "$pem_pattern" -- .; then
  fail "tracked files contain certificate or private-key material"
fi
pass "no certificate, private-key, or runtime blacklist material is tracked"

printf 'Repository validation passed.\n'
