#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
channel="${1:-direct}"
if [[ "$channel" != direct && "$channel" != appstore ]]; then
    echo "Usage: scripts/build.sh [direct|appstore]" >&2
    exit 1
fi
configuration="${CONFIGURATION:-release}"
swift build -c "$configuration" --arch arm64 --arch x86_64
binary_dir="$(swift build -c "$configuration" --arch arm64 --arch x86_64 --show-bin-path)"
app="build/$channel/Mac Duo Effect.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/MacDuoEffect" "$app/Contents/MacOS/MacDuoEffect"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/PrivacyInfo.xcprivacy "$app/Contents/Resources/PrivacyInfo.xcprivacy"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
signing_identity="${SIGNING_IDENTITY:--}"
signing_flags=(--force --sign "$signing_identity" --options runtime)
if [[ "$signing_identity" != - ]]; then signing_flags+=(--timestamp); fi
if [[ "$channel" == appstore ]]; then signing_flags+=(--entitlements Resources/AppStore.entitlements); fi
codesign "${signing_flags[@]}" "$app"
codesign --verify --deep --strict "$app"
echo "$PWD/$app"
