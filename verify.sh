#!/usr/bin/env bash
# Tests your deploy.sh against five releases (one of them broken). Run with: ./verify.sh
set -uo pipefail
cd "$(dirname "$0")"; ROOT=$(pwd)
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
export DEPLOY_HOME; DEPLOY_HOME="$(mktemp -d)/deploy-verify"
cleanup() { [ -x "$DEPLOY_HOME/app-ctl.sh" ] && "$DEPLOY_HOME/app-ctl.sh" stop >/dev/null 2>&1; rm -rf "$(dirname "$DEPLOY_HOME")"; }
trap cleanup EXIT
./setup.sh >/dev/null 2>&1
ver() { curl -fs --max-time 3 http://127.0.0.1:8090/healthz 2>/dev/null | sed -n 's/.*"version":"\([^"]*\)".*/\1/p'; }
cur() { basename "$(readlink "$DEPLOY_HOME/current" 2>/dev/null)"; }
run() { ./deploy.sh "$@" >"$DEPLOY_HOME/last.out" 2>&1; echo $? > "$DEPLOY_HOME/last.rc"; }
rc() { cat "$DEPLOY_HOME/last.rc"; }

echo "== The script =="
check "deploy.sh exists and is executable"                      test -x deploy.sh
check "valid bash syntax"                                       bash -n deploy.sh
check "uses strict mode (set -euo pipefail)"                    grep -q 'set -euo pipefail' deploy.sh
check "uses a trap for cleanup"                                 grep -q '^[[:space:]]*trap ' deploy.sh
check "has a usage message"                                     bash -c "grep -qi usage deploy.sh"

echo "== Bad input =="
run;                 check "no arguments: usage and exit code 2"               test "$(rc)" = 2
run v9.9.9;          check "unknown version: exit code 2, nothing deployed"    bash -c "[ \"$(rc)\" = 2 ] && [ ! -e '$DEPLOY_HOME/current' ]"

echo "== First deploys =="
run v1.0.0;          check "v1.0.0 deploys (exit 0)"                           test "$(rc)" = 0
check "current points at releases/v1.0.0"                       test "$(cur)" = v1.0.0
check "the app answers with version 1.0.0"                      test "$(ver)" = 1.0.0
run v1.1.0;          check "v1.1.0 deploys (exit 0) and is live"               bash -c "[ \"$(rc)\" = 0 ] && [ \"\$(curl -fs http://127.0.0.1:8090/healthz | grep -c 1.1.0)\" = 1 ]"

echo "== The broken release =="
run v1.2.0
check "v1.2.0 is unhealthy: the script exits non-zero"          test "$(rc)" != 0
check "...and rolled back: current is still v1.1.0"             test "$(cur)" = v1.1.0
check "...and the site is up and serving 1.1.0"                 test "$(ver)" = 1.1.0
check "...and the output says what happened (rollback)"         bash -c "grep -qi 'roll' '$DEPLOY_HOME/last.out'"

echo "== Repeat, prune, log =="
run v1.1.0;          check "deploying the current version again is harmless (exit 0)" test "$(rc)" = 0
run v1.3.0; run v1.4.0; run v1.5.0
check "v1.5.0 is live after three more deploys"                 test "$(ver)" = 1.5.0
check "at most 3 release directories are kept"                  bash -c "[ \$(ls '$DEPLOY_HOME/releases' | wc -l) -le 3 ]"
check "no temp or half-copied directories are left behind"      bash -c "[ -z \"\$(ls -A '$DEPLOY_HOME/releases' | grep -v '^v')\" ]"
check "the current release was never pruned"                    test -d "$DEPLOY_HOME/releases/$(cur)"
check "deploy.log has timestamped lines for every step"         bash -c "[ \$(grep -cE '[0-9]{2}:[0-9]{2}:[0-9]{2}' '$DEPLOY_HOME/deploy.log') -ge 12 ]"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
