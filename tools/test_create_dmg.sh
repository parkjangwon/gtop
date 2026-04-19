#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/tools/create_dmg.sh"

tmp_dir="$(mktemp -d)"
mount_point=""

cleanup() {
  if [[ -n "$mount_point" && -d "$mount_point" ]]; then
    hdiutil detach "$mount_point" -quiet || true
  fi
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

fake_app="$tmp_dir/Fake.app"
mkdir -p "$fake_app/Contents/MacOS"
printf '#!/bin/sh\necho fake\n' > "$fake_app/Contents/MacOS/fake"
chmod +x "$fake_app/Contents/MacOS/fake"

output_dmg="$tmp_dir/Fake.dmg"

bash "$SCRIPT_PATH" "$fake_app" "$output_dmg" "Fake"

if [[ ! -f "$output_dmg" ]]; then
  echo "Expected DMG to be created at $output_dmg" >&2
  exit 1
fi

attach_output="$(hdiutil attach "$output_dmg" -nobrowse -readonly)"
mount_point="$(printf '%s\n' "$attach_output" | tail -n 1 | awk '{print $NF}')"

if [[ ! -d "$mount_point/Fake.app" ]]; then
  echo "Expected Fake.app inside mounted DMG" >&2
  exit 1
fi

if [[ ! -L "$mount_point/Applications" ]]; then
  echo "Expected Applications symlink inside mounted DMG" >&2
  exit 1
fi

if [[ "$(readlink "$mount_point/Applications")" != "/Applications" ]]; then
  echo "Expected Applications symlink to point to /Applications" >&2
  exit 1
fi

echo "DMG packaging test passed"
