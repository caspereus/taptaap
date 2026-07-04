#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Taptaap"
APP_NAME="Taptaap"
DERIVED_DATA="$ROOT/build/DerivedData"
BUILD_PRODUCTS="$DERIVED_DATA/Build/Products/Release"
STAGING="$ROOT/build/dmg-staging"
DMG_PATH="$ROOT/build/${APP_NAME}.dmg"
VOLUME_NAME="$APP_NAME"

cd "$ROOT"

echo "Building ${SCHEME} (Release)..."
xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

APP_PATH="$BUILD_PRODUCTS/${APP_NAME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: ${APP_PATH} not found" >&2
  exit 1
fi

echo "Staging DMG contents..."
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto "$APP_PATH" "$STAGING/${APP_NAME}.app"
ln -s /Applications "$STAGING/Applications"

mkdir -p "$ROOT/build"
rm -f "$DMG_PATH"

echo "Creating ${DMG_PATH}..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Done. Open the DMG and drag ${APP_NAME} to Applications:"
echo "  open \"$DMG_PATH\""
