#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$BUILD_DIR/Crop Guide Overlay.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE="$MACOS_DIR/CropGuideOverlay"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swiftc \
  -framework Cocoa \
  "$ROOT_DIR/Sources/CropGuideOverlay/main.swift" \
  -o "$EXECUTABLE"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CropGuideOverlay</string>
  <key>CFBundleIdentifier</key>
  <string>com.10xoss.crop-guide-overlay</string>
  <key>CFBundleName</key>
  <string>Crop Guide Overlay</string>
  <key>CFBundleDisplayName</key>
  <string>Crop Guide Overlay</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP_DIR" >/dev/null
echo "$APP_DIR"
