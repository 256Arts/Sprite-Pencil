#!/bin/bash
#
# Captures App Store screenshots. A thin wrapper: the runner is shared across every app, and this
# app's part is `.screenshots.conf` plus SpritePencilUITests/ScreenshotTests.swift.
#
#   Scripts/screenshots.sh              # every platform
#   Scripts/screenshots.sh mac iphone   # only the named ones

set -euo pipefail
cd "$(dirname "$0")/.."

SHARED="${APP_SCRIPTS_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Apps/Scripts}"

if [ ! -x "$SHARED/screenshots" ]; then
    echo "shared runner not found at $SHARED/screenshots" >&2
    echo "(it lives in iCloud; set APP_SCRIPTS_DIR if yours is elsewhere)" >&2
    exit 2
fi

exec "$SHARED/screenshots" "$@"
