#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app='build/direct/Mac Duo Effect.app'
if [[ ! -d "$app" ]]; then
    echo 'Build the app first: scripts/build.sh' >&2
    exit 1
fi
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
name="${1:-Mac-Duo-Effect-$version}"
staging='build/dmg'
rm -rf "$staging"
mkdir -p "$staging" dist
cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"
dmg="dist/$name.dmg"
rm -f "$dmg" "$dmg.sha256"
hdiutil create -volname 'Mac Duo Effect' -srcfolder "$staging" -ov -format UDZO "$dmg" >/dev/null
shasum -a 256 "$dmg" > "$dmg.sha256"
rm -rf "$staging"
echo "$PWD/$dmg"
