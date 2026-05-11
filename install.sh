#!/usr/bin/env bash
# Build, install to /Applications, register with Launch Services, and launch.
# This is what you run during development to actually test the app —
# BrowserPick can only be a default browser candidate when it lives in
# a Launch-Services-indexed location like /Applications.
set -euo pipefail

CONFIG="${1:-debug}"

./build.sh "${CONFIG}"

echo "==> Killing any running instance"
killall BrowserPick 2>/dev/null || true

echo "==> Installing to /Applications/BrowserPick.app"
rm -rf /Applications/BrowserPick.app
cp -R .build/BrowserPick.app /Applications/

echo "==> Launching"
# `open` triggers Launch Services to discover the bundle; no explicit lsregister needed.
open /Applications/BrowserPick.app

echo ""
echo "Done. BrowserPick is in /Applications and running."
