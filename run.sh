#!/bin/zsh
clear
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/.build/Build/Products/Debug/Espaste.app"
BINARY="$APP/Contents/MacOS/Espaste"
PGREP_PATTERN="Espaste.app/Contents/MacOS/Espaste"

is_running() {
  pgrep -f "$PGREP_PATTERN" >/dev/null
}

echo "Stopping Espaste instances..."
killall -9 Espaste 2>/dev/null || true
pkill -9 -f "DerivedData/Espaste.*/Espaste.app" 2>/dev/null || true
killall -9 debugserver 2>/dev/null || true

echo "Stopping Supaste instances..."
killall -9 Supaste 2>/dev/null || true

sleep 1

if is_running; then
  echo "Espaste is still running. Stop debugging in Xcode (⏹), then run this script again."
  pgrep -lf "$PGREP_PATTERN"
  exit 1
fi

echo "Building..."
(cd "$ROOT" && xcodebuild -scheme Espaste -configuration Debug -derivedDataPath .build \
  -allowProvisioningUpdates ENABLE_DEBUG_DYLIB=NO ENABLE_PREVIEWS=NO build -quiet)

echo "Refreshing app registration..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted "$APP" >/dev/null
touch "$APP"

echo "Launching..."
if ! open "$APP" 2>/dev/null; then
  "$BINARY" >/dev/null 2>&1 &
fi

for _ in {1..10}; do
  if is_running; then
    echo "Espaste is running."
    pgrep -lf "$PGREP_PATTERN"
    exit 0
  fi
  sleep 1
done

echo "Espaste failed to start."
echo "Try launching manually: $BINARY"
exit 1
