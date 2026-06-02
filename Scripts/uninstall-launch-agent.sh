#!/usr/bin/env bash
set -euo pipefail

PLIST_DST="$HOME/Library/LaunchAgents/com.10xoss.crop-guide-overlay.plist"

launchctl bootout "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || true
rm -f "$PLIST_DST"
echo "Removed LaunchAgent: $PLIST_DST"
