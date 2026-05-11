#!/usr/bin/env bash
# Cut a release: build, zip, create GitHub Release, update the cask, commit, push.
#
# Usage: ./release.sh 0.0.2
#
# Requires: gh (GitHub CLI), authenticated against this repo's remote.
#
# What it does:
#   1. Builds release .app
#   2. Zips it (ditto, preserves macOS metadata)
#   3. Computes SHA256
#   4. Rewrites browserpick.rb with new version + sha256
#   5. Creates git tag vX.Y.Z and pushes it
#   6. Creates GitHub Release vX.Y.Z and uploads the zip as an asset
#   7. Commits the cask change and pushes main
#
# After this runs, `brew install --cask <raw-url>` will fetch and verify the new zip.
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version>   e.g. $0 0.0.2" >&2
    exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
APP_NAME="BrowserPick"
APP_BUNDLE=".build/${APP_NAME}.app"
ZIP_PATH=".build/${APP_NAME}.zip"
CASK_FILE="browserpick.rb"

command -v gh >/dev/null || { echo "gh CLI not found. brew install gh && gh auth login" >&2; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree has uncommitted changes. Commit or stash first." >&2
    git status --short >&2
    exit 1
fi

if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "Tag ${TAG} already exists locally." >&2
    exit 1
fi

echo "==> Building release"
./build.sh release

echo "==> Zipping ${APP_BUNDLE} -> ${ZIP_PATH}"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

SHA256="$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"
SIZE="$(du -h "${ZIP_PATH}" | awk '{print $1}')"
echo "==> ${ZIP_PATH}  (${SIZE}, sha256: ${SHA256})"

echo "==> Rewriting ${CASK_FILE}"
# Use a temp file so a failed sed never half-writes the cask.
TMP="$(mktemp)"
sed -E \
    -e "s/^([[:space:]]*version )\"[^\"]*\"/\\1\"${VERSION}\"/" \
    -e "s/^([[:space:]]*sha256 ).*/\\1\"${SHA256}\"/" \
    "${CASK_FILE}" > "${TMP}"
mv "${TMP}" "${CASK_FILE}"

echo "==> Tagging ${TAG} and pushing tag"
git tag "${TAG}"
git push origin "${TAG}"

echo "==> Creating GitHub Release ${TAG} with ${ZIP_PATH}"
gh release create "${TAG}" "${ZIP_PATH}" \
    --title "${TAG}" \
    --notes "Release ${TAG}"

echo "==> Committing cask bump"
git add "${CASK_FILE}"
git commit -m "Release ${TAG}"
git push origin HEAD

echo ""
echo "Done. Install with:"
echo "  brew install --cask https://raw.githubusercontent.com/cvladan/browser-pick/main/${CASK_FILE}"
