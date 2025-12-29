#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/KeyStats.xcodeproj"
SCHEME="KeyStats"
CONFIGURATION="Release"
APP_NAME="KeyStats"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
BUILD_DIR="$ROOT_DIR/build"
APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
STAGING_DIR="$BUILD_DIR/dmg-staging"
DMG_PATH="$ROOT_DIR/$APP_NAME.dmg"

echo "Building $APP_NAME..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"

echo "Creating DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

echo "DMG created at $DMG_PATH"
