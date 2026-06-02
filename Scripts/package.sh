#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$("$ROOT_DIR/Scripts/build-app.sh")"
ZIP_PATH="$ROOT_DIR/.build/CropGuideOverlay-macOS.zip"

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "$ZIP_PATH"
