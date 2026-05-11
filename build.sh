#!/usr/bin/env bash
# Build BrowserPick.app from SPM output + Info.plist.
# Usage: ./build.sh            (debug, ad-hoc signed)
#        ./build.sh release    (release, ad-hoc signed)
set -euo pipefail

CONFIG="${1:-debug}"
APP_NAME="BrowserPick"
BUILD_DIR=".build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "==> swift build (${CONFIG})"
if [[ "$CONFIG" == "release" ]]; then
    swift build -c release
    BIN_PATH=".build/release/${APP_NAME}"
else
    swift build
    BIN_PATH=".build/debug/${APP_NAME}"
fi

echo "==> Assembling ${APP_BUNDLE}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "${APP_BUNDLE}/Contents/Info.plist"
printf "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo ""
echo "Built: ${APP_BUNDLE}"
echo "Open with: open ${APP_BUNDLE}"
