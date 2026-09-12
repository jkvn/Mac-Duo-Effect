#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app='build/direct/Mac Duo Effect.app'
profile="${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool keychain profile}"
if ! codesign -dvv "$app" 2>&1 | /usr/bin/grep -q 'Authority=Developer ID Application:'; then
    echo 'Build with a Developer ID Application certificate before packaging a public release.' >&2
    exit 1
fi
codesign --verify --deep --strict "$app"
mkdir -p dist
upload="dist/Mac-Duo-Effect-notary.zip"
ditto -c -k --keepParent "$app" "$upload"
xcrun notarytool submit "$upload" --keychain-profile "$profile" --wait
xcrun stapler staple "$app"
xcrun stapler validate "$app"
spctl --assess --type execute --verbose=2 "$app"
ditto -c -k --keepParent "$app" dist/Mac-Duo-Effect-0.1.0.zip
shasum -a 256 dist/Mac-Duo-Effect-0.1.0.zip > dist/SHA256SUMS
