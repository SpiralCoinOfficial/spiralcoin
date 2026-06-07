#!/usr/bin/env bash
# Remove the SpiralCoin production watchdog cron entry.
set -euo pipefail

IDENT="# spiralcoin-health-watchdog"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: bash scripts/remove-health-cron.sh [--dry-run]

Options:
  --dry-run   Print resulting crontab without applying it.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
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

if [[ "$DRY_RUN" -eq 0 ]] && ! command -v crontab >/dev/null 2>&1; then
  echo "ERROR: 'crontab' command not found. Install cron (e.g., 'cron' package) before using this script without --dry-run." >&2
  exit 1
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

(crontab -l 2>/dev/null || true) | awk -v ident="$IDENT" 'index($0, ident)==0' > "$TMP_FILE"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] resulting crontab after removing '$IDENT':" >&2
  cat "$TMP_FILE"
  exit 0
fi

if [[ -s "$TMP_FILE" ]]; then
  crontab "$TMP_FILE"
else
  # Clear crontab if nothing remains.
  crontab -r 2>/dev/null || true
fi

echo "Removed cron entries tagged with: $IDENT"
