#!/usr/bin/env bash
# Install/update a cron job that runs the SpiralCoin production watchdog.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDENT="# spiralcoin-health-watchdog"
INTERVAL="${CRON_INTERVAL:-*/5 * * * *}"
LOG_FILE="${HEALTH_LOG_FILE:-/var/log/spiralcoin-health.log}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: bash scripts/install-health-cron.sh [--dry-run] [--interval "*/5 * * * *"]

Options:
  --dry-run              Print resulting crontab without applying it.
  --interval "SPEC"      Cron schedule spec (default: */5 * * * *).

Environment variables:
  CRON_INTERVAL          Alternate schedule spec.
  HEALTH_LOG_FILE        Alternate log file path.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --interval)
      INTERVAL="${2:-}"
      if [[ -z "$INTERVAL" ]]; then
        echo "ERROR: --interval requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

CRON_CMD="cd ${ROOT_DIR} && bash scripts/prod_health_check.sh >> ${LOG_FILE} 2>&1"
CRON_LINE="${INTERVAL} ${CRON_CMD} ${IDENT}"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

(crontab -l 2>/dev/null || true) | awk -v ident="$IDENT" 'index($0, ident)==0' > "$TMP_FILE"
echo "$CRON_LINE" >> "$TMP_FILE"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] would install/update this cron job:" >&2
  tail -n 1 "$TMP_FILE"
  echo "\n[dry-run] resulting crontab:" >&2
  cat "$TMP_FILE"
  exit 0
fi

crontab "$TMP_FILE"
echo "Installed/updated cron job:" >&2
echo "$CRON_LINE"
