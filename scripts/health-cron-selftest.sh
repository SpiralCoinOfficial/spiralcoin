#!/usr/bin/env bash
# Self-test for SpiralCoin cron watchdog helper scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="${ROOT_DIR}/scripts/install-health-cron.sh"
REMOVE_SCRIPT="${ROOT_DIR}/scripts/remove-health-cron.sh"
IDENT="spiralcoin-health-watchdog"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$INSTALL_SCRIPT" ]] || fail "missing script: $INSTALL_SCRIPT"
[[ -f "$REMOVE_SCRIPT" ]] || fail "missing script: $REMOVE_SCRIPT"

if command -v crontab >/dev/null 2>&1; then
  echo "INFO: crontab detected; running live idempotency test"

  TMP_CRON="$(mktemp)"
  HAD_CRONTAB=0

  restore_crontab() {
    if [[ "$HAD_CRONTAB" -eq 1 ]]; then
      crontab "$TMP_CRON"
    else
      crontab -r 2>/dev/null || true
    fi
  }

  cleanup() {
    restore_crontab
    rm -f "$TMP_CRON"
  }

  trap cleanup EXIT

  if crontab -l > "$TMP_CRON" 2>/dev/null; then
    HAD_CRONTAB=1
  else
    : > "$TMP_CRON"
  fi

  bash "$INSTALL_SCRIPT"
  bash "$INSTALL_SCRIPT"

  ENTRY_COUNT="$(crontab -l 2>/dev/null | grep -c "$IDENT" || true)"
  [[ "$ENTRY_COUNT" == "1" ]] || fail "expected 1 watchdog entry after double install, got $ENTRY_COUNT"

  bash "$REMOVE_SCRIPT"

  POST_REMOVE_COUNT="$(crontab -l 2>/dev/null | grep -c "$IDENT" || true)"
  [[ "$POST_REMOVE_COUNT" == "0" ]] || fail "expected 0 watchdog entries after remove, got $POST_REMOVE_COUNT"

  echo "PASS: live cron install/remove idempotency"
else
  echo "INFO: crontab not detected; running dry-run contract fallback"

  OUT1="$(bash "$INSTALL_SCRIPT" --dry-run 2>&1)"
  OUT2="$(bash "$INSTALL_SCRIPT" --dry-run 2>&1)"
  [[ "$OUT1" == "$OUT2" ]] || fail "dry-run install output changed between identical runs"

  bash "$REMOVE_SCRIPT" --dry-run >/dev/null

  set +e
  INSTALL_ERR="$(bash "$INSTALL_SCRIPT" 2>&1)"
  INSTALL_CODE=$?
  REMOVE_ERR="$(bash "$REMOVE_SCRIPT" 2>&1)"
  REMOVE_CODE=$?
  set -e

  [[ "$INSTALL_CODE" -ne 0 ]] || fail "install script should fail without crontab in non-dry-run mode"
  [[ "$REMOVE_CODE" -ne 0 ]] || fail "remove script should fail without crontab in non-dry-run mode"

  echo "$INSTALL_ERR" | grep -q "'crontab' command not found" || fail "install error message missing crontab prerequisite hint"
  echo "$REMOVE_ERR" | grep -q "'crontab' command not found" || fail "remove error message missing crontab prerequisite hint"

  echo "PASS: dry-run fallback and prerequisite guards"
fi

echo "SELFTEST_RESULT=PASS"
