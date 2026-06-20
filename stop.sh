#!/bin/zsh
clear
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Stopping Espaste instances..."
killall -9 Espaste 2>/dev/null || true
pkill -9 -f "DerivedData/Espaste.*/Espaste.app" 2>/dev/null || true
killall -9 debugserver 2>/dev/null || true

sleep 1

echo "Starting Supaste..."
if ! open -a Supaste 2>/dev/null; then
  echo "Supaste could not be launched. Make sure the app is installed."
  exit 1
fi

echo "Supaste launched."
exit 0
