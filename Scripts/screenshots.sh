#!/bin/bash
#
# Captures App Store screenshots. A thin wrapper: the runner is shared across every app, and this
# app's part is `.screenshots.conf` plus SpritePencilUITests/ScreenshotTests.swift.
#
#   Scripts/screenshots.sh              # every platform
#   Scripts/screenshots.sh mac iphone   # only the named ones

set -euo pipefail
cd "$(dirname "$0")/.."

# The repos folder was renamed from Apps to Repos; keep the old path as a fallback so a machine that
# still has the original layout works unchanged.
SHARED="${APP_SCRIPTS_DIR:-}"
if [ -z "$SHARED" ]; then
    ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    for candidate in "$ICLOUD/Repos/Scripts" "$ICLOUD/Apps/Scripts"; do
        if [ -x "$candidate/screenshots" ]; then
            SHARED="$candidate"
            break
        fi
    done
fi

if [ ! -x "${SHARED:-}/screenshots" ]; then
    echo "shared runner not found (looked in Repos/Scripts and Apps/Scripts under iCloud)" >&2
    echo "(set APP_SCRIPTS_DIR if yours is elsewhere)" >&2
    exit 2
fi

exec "$SHARED/screenshots" "$@"
