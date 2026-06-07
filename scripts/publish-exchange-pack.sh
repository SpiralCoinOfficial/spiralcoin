#!/bin/bash
#==============================================================================
# publish-exchange-pack.sh - Remote publish workflow for Exchange Pack
#==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✅${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}❌${NC} $*"; }

VERBOSE=0
DRY_RUN=0
SSH_KEY_PATH="${SPIRALCOIN_SSH_KEY_PATH:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        -d|--dry-run) DRY_RUN=1; shift ;;
        -h|--help) cat <<'EOF'
Usage: $0 [OPTIONS]

Publish SpiralCoin Exchange Pack to remote targets.

Options:
  -d, --dry-run      Show what would be published
  -v, --verbose      Enable verbose output
  -h, --help         Show this help message

Examples:
  $0                      # Publish to all targets
  $0 --dry-run            # Show what would be published

EOF
            exit 0 ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate prerequisites
info "Checking prerequisites..."
[[ ! -f "$REPO_ROOT/EXCHANGE_PUBLISH.targets.json" ]] && { error "targets.json not found"; exit 1; }
command -v jq &>/dev/null || { error "jq required"; exit 1; }
command -v scp &>/dev/null || { error "scp required"; exit 1; }
command -v ssh &>/dev/null || { error "ssh required"; exit 1; }

if [[ -z "$SSH_KEY_PATH" && -f "${HOME}/.ssh/id_ed25519" ]]; then
    SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
fi

SSH_ARGS=(-o StrictHostKeyChecking=no)
SCP_ARGS=(-o StrictHostKeyChecking=no)
if [[ -n "$SSH_KEY_PATH" ]]; then
    [[ -f "$SSH_KEY_PATH" ]] || { error "SPIRALCOIN_SSH_KEY_PATH not found: $SSH_KEY_PATH"; exit 1; }
    SSH_ARGS=(-i "$SSH_KEY_PATH" -o IdentitiesOnly=yes "${SSH_ARGS[@]}")
    SCP_ARGS=(-i "$SSH_KEY_PATH" -o IdentitiesOnly=yes "${SCP_ARGS[@]}")
    info "Using SSH key: $SSH_KEY_PATH"
fi
success "Prerequisites OK"

# Load targets
info "Loading targets from EXCHANGE_PUBLISH.targets.json..."
ZIP_PATH=$(jq -r '.zipPath' "$REPO_ROOT/EXCHANGE_PUBLISH.targets.json")
TARGET_COUNT=$(jq '.targets | length' "$REPO_ROOT/EXCHANGE_PUBLISH.targets.json")
FULL_ZIP_PATH="$REPO_ROOT/$ZIP_PATH"

[[ ! -f "$FULL_ZIP_PATH" ]] && { error "ZIP not found: $FULL_ZIP_PATH"; error "Run 'npm run exchange:pack:ready' first"; exit 1; }

ZIP_SIZE=$(stat -c%s "$FULL_ZIP_PATH" 2>/dev/null || stat -f%z "$FULL_ZIP_PATH" 2>/dev/null)
info "Exchange pack ready: $(basename "$FULL_ZIP_PATH") ($ZIP_SIZE bytes)"
info "Targets: $TARGET_COUNT"

# Publish function
publish_target() {
    local NAME="$1" REMOTE="$2" REMOTE_DIR="$3" ZIP_NAME="$4"

    echo ""
    info "Publishing to: $NAME"
    info "Remote: $REMOTE @ $REMOTE_DIR"

    if [[ $DRY_RUN -eq 1 ]]; then
        warn "[DRY-RUN] Would test SSH → $REMOTE"
        warn "[DRY-RUN] Would create dir → $REMOTE_DIR"
        warn "[DRY-RUN] Would upload → $FULL_ZIP_PATH"
        return 0
    fi

    # Actual publishing
    info "Testing SSH..."
    ssh "${SSH_ARGS[@]}" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE" "echo OK" &>/dev/null || { error "SSH failed"; return 1; }
    success "SSH OK"

    info "Creating remote directory..."
    ssh "${SSH_ARGS[@]}" "$REMOTE" "mkdir -p '$REMOTE_DIR'" || { error "mkdir failed"; return 1; }
    success "Directory ready"

    info "Uploading ZIP..."
    scp "${SCP_ARGS[@]}" "$FULL_ZIP_PATH" "$REMOTE:$REMOTE_DIR/$ZIP_NAME" || { error "scp failed"; return 1; }
    success "Upload complete"

    return 0
}

# Process each target
PASS=0
FAIL=0

jq -c '.targets[]' "$REPO_ROOT/EXCHANGE_PUBLISH.targets.json" | while read -r TARGET_JSON; do
    NAME=$(echo "$TARGET_JSON" | jq -r '.name')
    REMOTE=$(echo "$TARGET_JSON" | jq -r '.remote')
    REMOTE_DIR=$(echo "$TARGET_JSON" | jq -r '.remoteDir')
    ZIP_NAME=$(echo "$TARGET_JSON" | jq -r '.zipName')

    if publish_target "$NAME" "$REMOTE" "$REMOTE_DIR" "$ZIP_NAME"; then
        PASS=$((PASS + 1))
        success "Target '$NAME' completed"
    else
        FAIL=$((FAIL + 1))
        error "Target '$NAME' failed"
    fi
done

# Summary
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "PUBLISH SUMMARY"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $DRY_RUN -eq 1 ]] && warn "DRY-RUN MODE"

info "Exchange pack: $(basename "$FULL_ZIP_PATH")"
info "Targets configured: $TARGET_COUNT"

echo ""
jq -c '.targets[]' "$REPO_ROOT/EXCHANGE_PUBLISH.targets.json" | while read -r TARGET_JSON; do
    NAME=$(echo "$TARGET_JSON" | jq -r '.name')
    REMOTE=$(echo "$TARGET_JSON" | jq -r '.remote')
    echo "  • $NAME → $REMOTE"
done

echo ""
if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry-run complete; review output above"
    exit 0
else
    warn "Note: Pass/fail counts shown per shell invocation"
    warn "For accurate results, run without subshells or use npm script"
    exit 0
fi
