#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

readonly TARGET_SHA="${1:-}"
readonly FORCE_RELOAD="${2:-}"
readonly DEPLOY_PATH="${3:-}"
readonly PUBLIC_HOST="${4:-}"

[[ "$TARGET_SHA" =~ ^[0-9a-f]{40}$ ]] || fail "target SHA must be a full commit SHA"
[[ "$FORCE_RELOAD" == "true" || "$FORCE_RELOAD" == "false" ]] ||
  fail "force_reload must be true or false"
[[ "$DEPLOY_PATH" == "/etc/nginx" ]] || fail "unexpected deployment path"
[[ "$PUBLIC_HOST" =~ ^[A-Za-z0-9.-]+$ ]] || fail "invalid public host"

cd "$DEPLOY_PATH"

[[ "$(git branch --show-current)" == "master" ]] ||
  fail "production checkout must remain on master"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] ||
  fail "production checkout has tracked changes"

require_blacklist_contract() {
  [[ -f ip-blacklist.conf ]] || fail "server-local blacklist is missing"
  git check-ignore -q --no-index -- ip-blacklist.conf ||
    fail "server-local blacklist is not ignored"
  if git ls-files --error-unmatch -- ip-blacklist.conf >/dev/null 2>&1; then
    fail "server-local blacklist must remain untracked"
  fi
}

require_blacklist_contract
readonly BLACKLIST_HASH_BEFORE="$(sha256sum -- ip-blacklist.conf | awk '{print $1}')"
readonly BLACKLIST_SIZE_BEFORE="$(stat -c '%s' -- ip-blacklist.conf)"
readonly BLACKLIST_MODE_BEFORE="$(stat -c '%u:%g:%a' -- ip-blacklist.conf)"

systemctl is-active --quiet nginx || fail "nginx is not active before deployment"
readonly NGINX_PID_BEFORE="$(systemctl show nginx --property=MainPID --value)"
readonly NGINX_ACTIVE_BEFORE="$(
  systemctl show nginx --property=ActiveEnterTimestampMonotonic --value
)"
readonly NGINX_START_BEFORE="$(
  systemctl show nginx --property=ExecMainStartTimestampMonotonic --value
)"
[[ "$NGINX_PID_BEFORE" =~ ^[1-9][0-9]*$ ]] || fail "nginx master PID is invalid"

readonly PRIOR_SHA="$(git rev-parse HEAD)"
git fetch --no-tags origin refs/heads/master:refs/remotes/origin/master
readonly ORIGIN_MASTER_SHA="$(git rev-parse refs/remotes/origin/master)"
git cat-file -e "${TARGET_SHA}^{commit}" || fail "target commit is unavailable"
git merge-base --is-ancestor "$TARGET_SHA" "$ORIGIN_MASTER_SHA" ||
  fail "workflow SHA is not reachable from origin/master"
git merge-base --is-ancestor "$PRIOR_SHA" "$TARGET_SHA" ||
  fail "target commit is not a fast-forward"

behavior_changed=false
while IFS= read -r changed_path; do
  [[ -n "$changed_path" ]] || continue
  case "$changed_path" in
    fastcgi.conf | fastcgi_params | mime.types | nginx.conf | proxy_params | \
      scgi_params | uwsgi_params | modules-enabled/* | sites-available/* | \
      sites-enabled/* | snippets/*)
      behavior_changed=true
      ;;
  esac
done < <(git diff --name-only "$PRIOR_SHA" "$TARGET_SHA")
readonly behavior_changed

git merge --ff-only "$TARGET_SHA"
readonly FINAL_SHA="$(git rev-parse HEAD)"
[[ "$FINAL_SHA" == "$TARGET_SHA" ]] || fail "production did not reach the workflow SHA"
[[ "$(git branch --show-current)" == "master" ]] ||
  fail "production branch changed during deployment"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] ||
  fail "production checkout is not clean after synchronization"

assert_blacklist_integrity() {
  require_blacklist_contract
  [[ "$(sha256sum -- ip-blacklist.conf | awk '{print $1}')" == \
    "$BLACKLIST_HASH_BEFORE" ]] || fail "server-local blacklist bytes changed"
  [[ "$(stat -c '%s' -- ip-blacklist.conf)" == "$BLACKLIST_SIZE_BEFORE" ]] ||
    fail "server-local blacklist size changed"
  [[ "$(stat -c '%u:%g:%a' -- ip-blacklist.conf)" == "$BLACKLIST_MODE_BEFORE" ]] ||
    fail "server-local blacklist ownership or mode changed"
}

assert_blacklist_integrity

reload_required=false
if [[ "$behavior_changed" == "true" || "$FORCE_RELOAD" == "true" ]]; then
  reload_required=true
fi
readonly reload_required

printf 'deployment prior_sha=%s\n' "$PRIOR_SHA"
printf 'deployment target_sha=%s\n' "$TARGET_SHA"
printf 'deployment final_sha=%s\n' "$FINAL_SHA"
printf 'deployment behavior_changed=%s\n' "$behavior_changed"
printf 'deployment force_reload=%s\n' "$FORCE_RELOAD"
printf 'deployment reload_required=%s\n' "$reload_required"

if [[ "$reload_required" == "true" ]]; then
  nginx -t
  printf 'deployment nginx_test=passed\n'
  systemctl reload nginx
  printf 'deployment nginx_action=reloaded\n'
else
  printf 'deployment nginx_test=skipped\n'
  printf 'deployment nginx_action=skipped\n'
fi

systemctl is-active --quiet nginx || fail "nginx is not active after deployment"
readonly NGINX_PID_AFTER="$(systemctl show nginx --property=MainPID --value)"
readonly NGINX_ACTIVE_AFTER="$(
  systemctl show nginx --property=ActiveEnterTimestampMonotonic --value
)"
readonly NGINX_START_AFTER="$(
  systemctl show nginx --property=ExecMainStartTimestampMonotonic --value
)"
[[ "$NGINX_PID_AFTER" == "$NGINX_PID_BEFORE" ]] ||
  fail "nginx master PID changed; reload contract was not preserved"
[[ "$NGINX_ACTIVE_AFTER" == "$NGINX_ACTIVE_BEFORE" ]] ||
  fail "nginx active timestamp changed; restart may have occurred"
[[ "$NGINX_START_AFTER" == "$NGINX_START_BEFORE" ]] ||
  fail "nginx process start timestamp changed; restart may have occurred"
printf 'deployment nginx_service=active identity=preserved\n'

readonly PUBLIC_BASE_URL="https://${PUBLIC_HOST}"

check_route() {
  local path="$1"
  local status

  status="$(
    curl --fail --silent --show-error --location \
      --connect-timeout 10 --max-time 30 \
      --output /dev/null --write-out '%{http_code}' \
      "${PUBLIC_BASE_URL}${path}"
  )"
  [[ "$status" == "200" ]] || fail "public route is unhealthy: $path ($status)"
  printf 'health route=%s status=200\n' "$path"
}

check_route "/"
check_route "/docs/"
check_route "/certifications/"
check_route "/deepseek_chat/"

readonly BACKEND_HEALTH="$(
  curl --fail --silent --show-error --connect-timeout 10 --max-time 30 \
    "${PUBLIC_BASE_URL}/cloudchat/auth/healthz"
)"
printf '%s' "$BACKEND_HEALTH" | grep -Eq '"ok"[[:space:]]*:[[:space:]]*true' ||
  fail "backend health does not report ok=true"
printf '%s' "$BACKEND_HEALTH" | grep -Eq '"redis"[[:space:]]*:[[:space:]]*true' ||
  fail "backend health does not report redis=true"
printf '%s' "$BACKEND_HEALTH" | grep -Eq '"db"[[:space:]]*:[[:space:]]*true' ||
  fail "backend health does not report db=true"
printf 'health backend=ok redis=true db=true\n'

check_frame_policy() {
  local path="$1"
  local headers
  local csp
  local x_frame_options

  headers="$(
    curl --fail --silent --show-error --head \
      --connect-timeout 10 --max-time 30 \
      "${PUBLIC_BASE_URL}${path}" | tr -d '\r'
  )"
  csp="$(
    printf '%s\n' "$headers" |
      awk 'tolower($0) ~ /^content-security-policy:/ {
        sub(/^[^:]*:[[:space:]]*/, ""); print; exit
      }'
  )"
  x_frame_options="$(
    printf '%s\n' "$headers" |
      awk 'tolower($0) ~ /^x-frame-options:/ {
        sub(/^[^:]*:[[:space:]]*/, ""); print; exit
      }'
  )"
  [[ "$csp" == *"frame-src 'self' https://www.credly.com;"* ]] ||
    fail "frame-src policy is missing for $path"
  [[ "$csp" == *"frame-ancestors 'self';"* ]] ||
    fail "frame-ancestors policy is missing for $path"
  [[ "$x_frame_options" == "SAMEORIGIN" ]] ||
    fail "X-Frame-Options policy is invalid for $path"
  printf 'health frame_policy=%s status=passed\n' "$path"
}

check_frame_policy "/"
check_frame_policy "/deepseek_chat/"

readonly INDIGO_HOST="indigo.rendazhangisthebest.top"
readonly INDIGO_HTTP="http://$INDIGO_HOST"
readonly INDIGO_HTTPS="https://$INDIGO_HOST"
readonly INDIGO_MARKER="indigo-placeholder-v1"
probe_dir="$(mktemp -d)"
readonly probe_dir
trap 'rm -rf -- "$probe_dir"' EXIT

check_local_route() {
  local url="$1"
  local expected_status="$2"
  local status location_headers

  # Keep the URL's Host and TLS name while connecting directly to this Nginx.
  status="$(curl --disable --noproxy '*' --connect-to '::127.0.0.1:' \
    --silent --show-error --no-location --connect-timeout 10 --max-time 30 \
    --dump-header "$probe_dir/headers" --output "$probe_dir/body" \
    --write-out '%{http_code}' "$url")" || fail "request failed: $url"
  [[ "$status" == "$expected_status" ]] ||
    fail "expected HTTP $expected_status, got $status: $url"

  if (( $# == 3 )); then
    # Keep a field name so even an empty or duplicate Location is detectable.
    location_headers="$(awk 'tolower($0) ~ /^location:/ {
      sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t\r]+$/, ""); print "Location: " $0
    }' "$probe_dir/headers")"
    [[ "$location_headers" == "$3" ]] || fail "unexpected Location header: $url"
  fi
}

check_local_route "$INDIGO_HTTP/" 301 "Location: $INDIGO_HTTPS/"
check_local_route "$INDIGO_HTTP/indigo-deploy-probe-missing?check=indigo" 301 \
  "Location: $INDIGO_HTTPS/indigo-deploy-probe-missing?check=indigo"
check_local_route "$INDIGO_HTTPS/" 200 ""
grep -Fq -- "$INDIGO_MARKER" "$probe_dir/body" || fail "Indigo homepage marker missing"

check_local_route "$INDIGO_HTTP/.well-known/acme-challenge/indigo-deploy-probe" 200 ""
cmp -s "$probe_dir/body" <(printf '%s\n' 'indigo-acme-probe-v1') ||
  fail "Indigo ACME probe content differs from the expected bytes"

check_local_route "$INDIGO_HTTP/.well-known/acme-challenge/indigo-deploy-probe-missing" 404 ""
check_local_route "$INDIGO_HTTPS/indigo-deploy-probe-missing" 404 ""
check_local_route "$INDIGO_HTTPS/cloudchat/" 404 ""

check_local_route "http://unmatched.invalid/?check=indigo" 301 "Location: https://www.rendazhang.com/?check=indigo"
check_local_route "https://www.rendazhang.com/" 200 ""
if grep -Fq -- "$INDIGO_MARKER" "$probe_dir/body"; then
  fail "personal homepage contains the Indigo marker"
fi
check_local_route "https://rendazhang.com/" 301 "Location: https://www.rendazhang.com/"

local_leaf_fingerprint() {
  # An IP-literal connection without -servername sends no SNI.
  openssl x509 -noout -fingerprint -sha256 < <(
    timeout 10 openssl s_client -connect 127.0.0.1:443 "$@" </dev/null 2>/dev/null
  )
}

# The named HTTPS probes above have already verified the personal chain and name.
personal_leaf="$(local_leaf_fingerprint -servername rendazhang.com)" || fail "personal TLS probe failed"
unknown_leaf="$(local_leaf_fingerprint -servername unmatched.invalid)" || fail "unknown-SNI TLS probe failed"
no_sni_leaf="$(local_leaf_fingerprint)" || fail "no-SNI TLS probe failed"
[[ "$unknown_leaf" == "$personal_leaf" && "$no_sni_leaf" == "$personal_leaf" ]] ||
  fail "default TLS listener did not present the personal certificate"
printf 'health named_sites=passed indigo_http=passed indigo_https=passed personal_https=passed default_tls=passed\n'

assert_blacklist_integrity
printf 'deployment blacklist_integrity=preserved\n'
printf 'Production synchronization passed.\n'
