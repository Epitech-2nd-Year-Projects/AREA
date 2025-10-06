#!/bin/sh
set -e

APK_SRC="/app/client.apk"
APK_DEST="/apkshare/client.apk"

if [ ! -f "$APK_SRC" ]; then
  echo "Expected APK at $APK_SRC but none found" >&2
  exit 1
fi

mkdir -p "$(dirname "$APK_DEST")"
cp -f "$APK_SRC" "$APK_DEST"

echo "APK placed in shared volume at $APK_DEST"

exec tail -f /dev/null
