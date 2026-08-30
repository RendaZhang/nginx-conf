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

require_literal() {
  local path="$1"
  local value="$2"
  local message="$3"

  grep -Fq -- "$value" "$path" || fail "$message"
}

reject_literal() {
  local path="$1"
  local value="$2"
  local message="$3"

  if grep -Fq -- "$value" "$path"; then
    fail "$message"
  fi
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

if grep -Eq \
  '^[[:space:]]*(set_real_ip_from|real_ip_header|real_ip_recursive)[[:space:]]' \
  nginx.conf; then
  fail "direct origin must not replace socket-peer identity from forwarding headers"
fi
for path in nginx.conf proxy_params sites-available/rendazhang.conf; do
  reject_literal \
    "$path" \
    '$proxy_add_x_forwarded_for' \
    "untrusted forwarded chains must not be propagated: $path"
done
require_literal \
  proxy_params \
  'proxy_set_header X-Forwarded-For $remote_addr;' \
  "shared proxy parameters must forward only the trusted edge client identity"
[[ "$(grep -Fc 'proxy_set_header X-Forwarded-For $remote_addr;' \
  sites-available/rendazhang.conf)" -eq 3 ]] ||
  fail "every CloudChat proxy location must forward exactly one trusted client identity"
pass "direct-origin client identity cannot be replaced or extended by caller headers"

reject_literal \
  nginx.conf \
  'proxy_ignore_headers Set-Cookie' \
  "upstream Set-Cookie must retain its default cache-control semantics"
require_literal \
  sites-available/rendazhang.conf \
  'location = /cloudchat/test {' \
  "the explicit public cache demonstration route is missing"
[[ "$(grep -Fc 'proxy_cache cloudchat_cache;' sites-available/rendazhang.conf)" -eq 1 ]] ||
  fail "CloudChat cache usage must remain restricted to one explicit route"
require_literal \
  sites-available/rendazhang.conf \
  'location = /cloudchat/deepseek_chat {' \
  "paid Chat must retain an exact edge policy location"
require_literal \
  nginx.conf \
  'limit_req_zone $binary_remote_addr zone=chat_limit:10m rate=10r/m;' \
  "paid Chat rate zone is missing or has drifted"
require_literal nginx.conf 'limit_req_status 429;' "rate-limit rejection status must remain 429"
require_literal \
  sites-available/rendazhang.conf \
  'limit_req zone=chat_limit burst=3 nodelay;' \
  "paid Chat must use the independent bounded rate zone"
pass "CloudChat cache allowlist and paid-Chat rate policy are explicit"

require_literal nginx.conf 'server_tokens off;' "Nginx version disclosure must remain disabled"
reject_literal \
  snippets/security-headers.conf \
  'X-XSS-Protection' \
  "deprecated X-XSS-Protection header must not be reintroduced"
require_literal \
  snippets/security-headers.conf \
  'add_header X-Frame-Options "SAMEORIGIN" always;' \
  "same-origin frame policy is missing"
require_literal \
  snippets/security-headers.conf \
  "frame-src 'self' https://www.credly.com;" \
  "required Chat Widget and Credly frame sources are missing"
require_literal \
  snippets/security-headers.conf \
  "frame-ancestors 'self';" \
  "same-origin frame ancestor policy is missing"
require_literal \
  sites-available/rendazhang.conf \
  'location ~ ^/cloudchat/purge-cache/(.+)$ {' \
  "cache purge route must remain anchored"
require_literal sites-available/rendazhang.conf 'allow 127.0.0.1;' \
  "cache purge must allow IPv4 loopback"
require_literal sites-available/rendazhang.conf 'allow ::1;' \
  "cache purge must allow IPv6 loopback"
reject_literal \
  sites-available/rendazhang.conf \
  'X-Purge-' \
  "cache purge responses must not expose debug metadata"
pass "disclosure, framing, and loopback purge contracts remain enforced"

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
