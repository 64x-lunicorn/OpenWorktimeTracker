#!/bin/bash
set -euo pipefail

# Create DMG from built app
# Usage: ./scripts/create-dmg.sh [app_path] [output_path]

APP_NAME="OpenWorktimeTracker"
APP_PATH="${1:-build/Build/Products/Release/${APP_NAME}.app}"
VERSION=$(defaults read "${APP_PATH}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "dev")
DMG_PATH="${2:-build/${APP_NAME}-${VERSION}.dmg}"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    echo "Run 'make build' first."
    exit 1
fi

echo "Creating DMG from $APP_PATH..."

# Try create-dmg first (prettier)
if command -v create-dmg &>/dev/null; then
    if create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 175 190 \
        --app-drop-link 425 190 \
        --hide-extension "${APP_NAME}.app" \
        "$DMG_PATH" \
        "$APP_PATH"; then
        echo "DMG created with create-dmg"
    else
        echo "Warning: create-dmg failed, falling back to hdiutil..."
        rm -f "$DMG_PATH"
    fi
fi

# Fallback to hdiutil
if [ ! -f "$DMG_PATH" ]; then
    echo "Using hdiutil..."
    if ! hdiutil create -volname "$APP_NAME" \
        -srcfolder "$APP_PATH" \
        -ov -format UDZO \
        "$DMG_PATH"; then
        echo "Error: Failed to create DMG"
        exit 1
    fi
fi

echo "DMG created: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
