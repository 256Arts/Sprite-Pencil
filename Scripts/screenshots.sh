#!/bin/bash
#
# Captures App Store screenshots. A thin wrapper: the runner is shared across every app, and this
# app's part is `.screenshots.conf` plus "<App> UITests/ScreenshotTests.swift".
#
#   Scripts/screenshots.sh              # every platform the project builds for
#   Scripts/screenshots.sh mac iphone   # only the named ones
#   Scripts/screenshots.sh --upload     # capture, then send the results to App Store Connect
#
# Every shot is generated from one pinned seed (see ScreenshotMode).

set -euo pipefail
cd "$(dirname "$0")/.."

# Where the shared runner is, derived from this checkout rather than written down. Every repo lives
# in one folder, so the runner is in the `Scripts` repo beside this one — and asking git for the
# repo's real location gets there from a Conductor worktree too, whose own parent is the workspace
# folder and not that one.
#
# Nothing here falls back to a second path. The folder has been renamed once already (Apps ->
# Repos), and a wrapper that quietly tries yesterday's name is how a run ends up writing its shots
# somewhere nobody is looking.
REPO_ROOT="$PWD"
GIT_COMMON=$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
MAIN_CHECKOUT=$(dirname "${GIT_COMMON:-$REPO_ROOT/.git}")
SHARED="${APP_SCRIPTS_DIR:-$(dirname "$MAIN_CHECKOUT")/Scripts}"

if [ ! -x "$SHARED/screenshots" ]; then
    echo "no shared runner at $SHARED/screenshots" >&2
    echo "(it lives in the Scripts repo beside this one — set APP_SCRIPTS_DIR if yours is elsewhere)" >&2
    exit 2
fi

exec "$SHARED/screenshots" "$@"
