#!/bin/bash
# Regenerates Assets/AppIcon.icns from scripts/gen-icon.swift.
set -euo pipefail
cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Drawing 1024px master PNG"
swift scripts/gen-icon.swift "$TMP/master.png"

ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  double=$((size * 2))
  sips -z "$size" "$size" "$TMP/master.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$double" "$double" "$TMP/master.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

echo "==> Building icns"
mkdir -p Assets
iconutil -c icns "$ICONSET" -o Assets/AppIcon.icns
echo "==> Done: Assets/AppIcon.icns"
