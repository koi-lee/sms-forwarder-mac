#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
IDENTITY="-"
EXTRA=()
if [[ "${1:-}" == "--developer-id" ]]; then
  IDENTITY="Developer ID Application: ZEAN LI (4BHPD976HX)"
  security find-identity -v -p codesigning | grep -F "\"$IDENTITY\"" >/dev/null
  EXTRA=(ENABLE_HARDENED_RUNTIME=YES OTHER_CODE_SIGN_FLAGS=--timestamp)
elif [[ -n "${1:-}" ]]; then
  echo 'Usage: ./build-app.sh [--developer-id]' >&2
  exit 2
fi
xcodebuild -project "$ROOT/WIFIForwarderSerialAssistant.xcodeproj" \
  -scheme WIFIForwarderSerialAssistant -configuration Release -sdk macosx \
  -derivedDataPath "$ROOT/.build/DerivedData" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="$IDENTITY" CODE_SIGN_STYLE=Manual "${EXTRA[@]}" build
mkdir -p "$ROOT/dist"
APP="$ROOT/dist/WIFI转发宝串口助手.app"
if [[ -e "$APP" ]]; then
  mv "$APP" "$ROOT/dist/previous-$(date +%Y%m%d-%H%M%S)-$$.app"
fi
ditto "$ROOT/.build/DerivedData/Build/Products/Release/WIFI转发宝串口助手.app" "$APP"
codesign --verify --deep --strict "$APP"
if [[ "$IDENTITY" != '-' ]]; then
  SIGNATURE="$(codesign -dv --verbose=4 "$APP" 2>&1)"
  grep -F "Authority=$IDENTITY" <<< "$SIGNATURE" >/dev/null
  grep -F 'TeamIdentifier=4BHPD976HX' <<< "$SIGNATURE" >/dev/null
fi
echo "Built: $APP"
