#!/bin/bash

set -euo pipefail

MODULE_DIR="${MODDIR:-${0%/*}}"
KAMFW_RC="${MODULE_DIR}/lib/kamfw/.kamfwrc"
PHASE="${KAM_PHASE:-install}"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

if [ ! -r "$KAMFW_RC" ]; then
    die "kamfw runtime not found: $KAMFW_RC"
fi

# shellcheck source=/dev/null
. "$KAMFW_RC" || die "failed to load kamfw runtime"

if command -v kamfw >/dev/null 2>&1; then
    kamfw run "$PHASE" -- "$@"
else
    die "kamfw command is unavailable after loading runtime"
fi
