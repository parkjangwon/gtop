#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <path-to-app> <output-dmg> [volume-name]" >&2
  exit 1
fi

app_path="$1"
output_dmg="$2"
volume_name="${3:-$(basename "$app_path" .app)}"

if [[ ! -d "$app_path" || "${app_path##*.}" != "app" ]]; then
  echo "Expected a .app bundle at: $app_path" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
staging_dir="$tmp_dir/staging"
rw_dmg="$tmp_dir/temp.dmg"

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

mkdir -p "$staging_dir"

app_name="$(basename "$app_path")"
ditto "$app_path" "$staging_dir/$app_name"
ln -s /Applications "$staging_dir/Applications"

mkdir -p "$(dirname "$output_dmg")"
rm -f "$output_dmg"

hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging_dir" \
  -fs HFS+ \
  -format UDRW \
  "$rw_dmg" \
  >/dev/null

hdiutil convert \
  "$rw_dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$output_dmg" \
  >/dev/null

if [[ ! -f "$output_dmg" && -f "${output_dmg}.dmg" ]]; then
  mv "${output_dmg}.dmg" "$output_dmg"
fi

echo "Created DMG: $output_dmg"
