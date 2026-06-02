#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-$ROOT_DIR/.build/Crop Guide Overlay.app}"
PLIST_SRC="$ROOT_DIR/LaunchAgents/com.10xoss.crop-guide-overlay.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.10xoss.crop-guide-overlay.plist"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  echo "Run: make app" >&2
  exit 1
fi

sed "s#__APP_PATH__#$APP_PATH#g" "$PLIST_SRC" > "$PLIST_DST"
launchctl bootout "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
launchctl kickstart -k "gui/$(id -u)/com.10xoss.crop-guide-overlay"
echo "Installed and started LaunchAgent: $PLIST_DST"
