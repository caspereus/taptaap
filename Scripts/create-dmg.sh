#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Meecanico"
APP_NAME="Meecanico"
DERIVED_DATA="$ROOT/build/DerivedData"
BUILD_PRODUCTS="$DERIVED_DATA/Build/Products/Release"
VOLUME_NAME="$APP_NAME"
BACKGROUND_IMAGE="$ROOT/Scripts/dmg/installation-background.png"
DMG_RW="$ROOT/build/${APP_NAME}-rw.dmg"

# Finder window layout (matches 1024×1024 background)
WINDOW_X=100
WINDOW_Y=100
WINDOW_WIDTH=1024
WINDOW_HEIGHT=1024
ICON_SIZE=128
APP_ICON_X=260
APP_ICON_Y=380
APPS_LINK_X=700
APPS_LINK_Y=380

cd "$ROOT"

if [[ ! -f "$BACKGROUND_IMAGE" ]]; then
  echo "error: missing DMG background at ${BACKGROUND_IMAGE}" >&2
  exit 1
fi

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

PLIST="$APP_PATH/Contents/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")
DMG_PATH="$ROOT/build/${APP_NAME}-${VERSION}.dmg"

echo "Packaging ${APP_NAME} ${VERSION} (${BUILD})..."

STAGING="$ROOT/build/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto "$APP_PATH" "$STAGING/${APP_NAME}.app"
ln -s /Applications "$STAGING/Applications"

APP_SIZE_KB=$(du -sk "$STAGING" | awk '{print $1}')
DMG_SIZE_MB=$(( APP_SIZE_KB / 1024 + 50 ))

mkdir -p "$ROOT/build"
rm -f "$DMG_RW" "$DMG_PATH" "$ROOT/build/${APP_NAME}.dmg"

echo "Creating read-write DMG..."
hdiutil create -size "${DMG_SIZE_MB}m" -fs HFS+J -volname "$VOLUME_NAME" -ov "$DMG_RW"

echo "Mounting DMG..."
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW")
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | awk '/\/Volumes\// {print $3; exit}')
if [[ -z "$MOUNT_DIR" ]]; then
  echo "error: failed to mount DMG" >&2
  exit 1
fi

cleanup() {
  if [[ -n "${MOUNT_DIR:-}" ]] && mount | grep -q "$MOUNT_DIR"; then
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "Copying app bundle..."
ditto "$APP_PATH" "$MOUNT_DIR/${APP_NAME}.app"
ln -sf /Applications "$MOUNT_DIR/Applications"

echo "Applying installer background..."
mkdir -p "$MOUNT_DIR/.background"
cp "$BACKGROUND_IMAGE" "$MOUNT_DIR/.background/installation-background.png"
chflags hidden "$MOUNT_DIR/.background"
if command -v SetFile >/dev/null 2>&1; then
  SetFile -a V "$MOUNT_DIR/.background"
fi

echo "Configuring Finder window layout..."
osascript <<EOF
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {$WINDOW_X, $WINDOW_Y, $((WINDOW_X + WINDOW_WIDTH)), $((WINDOW_Y + WINDOW_HEIGHT))}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to $ICON_SIZE
    set background picture of viewOptions to file ".background:installation-background.png"
    set position of item "${APP_NAME}.app" of container window to {$APP_ICON_X, $APP_ICON_Y}
    set position of item "Applications" of container window to {$APPS_LINK_X, $APPS_LINK_Y}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

sync

echo "Unmounting DMG..."
hdiutil detach "$MOUNT_DIR"
MOUNT_DIR=""
trap - EXIT

echo "Compressing ${DMG_PATH}..."
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$DMG_RW"
rm -rf "$STAGING"

echo "Done. Open the DMG and drag ${APP_NAME} to Applications:"
echo "  open \"$DMG_PATH\""
