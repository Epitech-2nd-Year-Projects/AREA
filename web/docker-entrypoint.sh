#!/bin/sh
set -e

APK_SRC="/apkshare/client.apk"
APK_TARGET="/app/public/client.apk"

if [ -f "$APK_SRC" ]; then
  ln -sf "$APK_SRC" "$APK_TARGET"
  echo "Linked APK from $APK_SRC to $APK_TARGET"
else
  echo "Warning: APK not found at $APK_SRC" >&2
fi

exec "$@"
