#!/bin/bash
# Packages dist/Tuck.app into dist/Tuck-<version>.dmg with a drag-to-install
# /Applications symlink. Uses plain hdiutil (offline, deterministic);
# create-dmg could prettify this later with background art.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Packaging/Info.plist)"
APP="dist/Tuck.app"
DMG="dist/Tuck-$VERSION.dmg"

if [[ ! -d "$APP" ]]; then
  echo "error: $APP not found — run scripts/build-app.sh first" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "Tuck $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
echo "==> Done: $DMG"
shasum -a 256 "$DMG"
