#!/usr/bin/env bash
# Cut a release: bump Info.plist, build, zip, GitHub Release, bump cask in tap.
#
# Usage: ./release.sh 0.0.2
#
# Requires:
#   - gh CLI, authenticated against this repo's remote.
#   - A local clone of cvladan/homebrew-tap (default: ~/dev/homebrew-tap),
#     with a clean working tree and main checked out. Override with:
#       TAP_DIR=/path/to/homebrew-tap ./release.sh 0.0.2
#
# What it does:
#   1. Bumps CFBundleShortVersionString + CFBundleVersion in Resources/Info.plist
#      and commits the bump as "Release vX.Y.Z" (so the About panel shows it).
#   2. Builds release .app
#   3. Zips it (ditto, preserves macOS metadata)
#   4. Computes SHA256
#   5. Tags vX.Y.Z, pushes main + tag
#   6. Creates GitHub Release vX.Y.Z and uploads the zip as an asset
#   7. Rewrites Casks/browserpick.rb in the tap repo with new version + sha256,
#      commits, and pushes main in the tap repo.
#
# After this runs, `brew install --cask cvladan/tap/browserpick` (or `brew upgrade`)
# fetches and verifies the new zip.
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
INFO_PLIST="Resources/Info.plist"
TAP_DIR="${TAP_DIR:-${HOME}/dev/homebrew-tap}"
CASK_FILE="${TAP_DIR}/Casks/browserpick.rb"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

command -v gh >/dev/null || { echo "gh CLI not found. brew install gh && gh auth login" >&2; exit 1; }
[[ -x "${PLIST_BUDDY}" ]] || { echo "PlistBuddy not found at ${PLIST_BUDDY}" >&2; exit 1; }

if [[ ! -f "${CASK_FILE}" ]]; then
    echo "Cask not found at ${CASK_FILE}." >&2
    echo "Clone the tap first:  git clone https://github.com/cvladan/homebrew-tap ${TAP_DIR}" >&2
    echo "Or set TAP_DIR=/path/to/homebrew-tap" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "browser-pick working tree has uncommitted changes. Commit or stash first." >&2
    git status --short >&2
    exit 1
fi

if [[ -n "$(git -C "${TAP_DIR}" status --porcelain)" ]]; then
    echo "${TAP_DIR} has uncommitted changes. Commit or stash first." >&2
    git -C "${TAP_DIR}" status --short >&2
    exit 1
fi

if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "Tag ${TAG} already exists locally." >&2
    exit 1
fi

echo "==> Pulling tap (${TAP_DIR})"
git -C "${TAP_DIR}" pull --ff-only

echo "==> Bumping ${INFO_PLIST} to ${VERSION}"
"${PLIST_BUDDY}" -c "Set :CFBundleShortVersionString ${VERSION}" "${INFO_PLIST}"
"${PLIST_BUDDY}" -c "Set :CFBundleVersion ${VERSION}" "${INFO_PLIST}"

echo "==> Committing version bump"
git add "${INFO_PLIST}"
git commit -m "Release ${TAG}"

echo "==> Building release"
./build.sh release

echo "==> Zipping ${APP_BUNDLE} -> ${ZIP_PATH}"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

SHA256="$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"
SIZE="$(du -h "${ZIP_PATH}" | awk '{print $1}')"
echo "==> ${ZIP_PATH}  (${SIZE}, sha256: ${SHA256})"

echo "==> Tagging ${TAG} and pushing main + tag"
git tag "${TAG}"
git push origin HEAD
git push origin "${TAG}"

echo "==> Creating GitHub Release ${TAG} with ${ZIP_PATH}"
gh release create "${TAG}" "${ZIP_PATH}" \
    --title "${TAG}" \
    --notes "Release ${TAG}"

echo "==> Rewriting cask in tap (${CASK_FILE})"
TMP="$(mktemp)"
sed -E \
    -e "s/^([[:space:]]*version )\"[^\"]*\"/\\1\"${VERSION}\"/" \
    -e "s/^([[:space:]]*sha256 ).*/\\1\"${SHA256}\"/" \
    "${CASK_FILE}" > "${TMP}"
mv "${TMP}" "${CASK_FILE}"

echo "==> Committing and pushing tap"
git -C "${TAP_DIR}" add Casks/browserpick.rb
git -C "${TAP_DIR}" commit -m "browserpick ${VERSION}"
git -C "${TAP_DIR}" push origin HEAD

echo ""
echo "Done. Install with:"
echo "  brew install --cask cvladan/tap/browserpick"
echo "Or upgrade an existing install:"
echo "  brew upgrade --cask browserpick"
