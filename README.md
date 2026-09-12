# Mac Duo Effect

A free, native macOS menu bar utility that recreates the lid animation of the new iPhone Duo on the Mac: as you move your MacBook lid, the screen gains perspective, progressive blur and dimming.

Click the laptop icon in the menu bar. There is no separate settings window or Dock icon. All controls are in English.

## Requirements

- macOS 14 or later.
- A MacBook with a compatible, built-in HID lid-angle sensor. Apple Silicon and Intel binaries are included; sensor availability varies by model.
- Screen Recording permission for the live effect.

The current build is a development version. Public GitHub release and Mac App Store submission are pending.

## Development

Open `Package.swift` in Xcode, or use the included macOS app project for app bundling and archiving.

```sh
swift test
scripts/build.sh
open 'build/direct/Mac Duo Effect.app'
```

The build script produces a universal app and signs it ad hoc by default. For stable local development permissions, use an existing Apple Development identity:

```sh
SIGNING_IDENTITY='Apple Development: YOUR NAME (IDENTIFIER)' scripts/build.sh
```

Run the hardware probe or synthetic GPU verification:

```sh
'build/direct/Mac Duo Effect.app/Contents/MacOS/MacDuoEffect' --diagnostics
'build/direct/Mac Duo Effect.app/Contents/MacOS/MacDuoEffect' --render-check build/render-check
```

Package a disk image from the current build:

```sh
scripts/make-dmg.sh
```

A sandbox build is available with `scripts/build.sh appstore`. It is not an App Store upload until signed with the correct distribution identity and provisioning configuration.

## Continuous integration

Pull requests run `swift test`, a universal build and the render check. Every push to `main` publishes a GitHub release with a `.dmg` and its SHA-256 checksum, tagged `v<version>-build.<run number>`.

These automated builds are signed ad hoc, not with a Developer ID and not notarized. macOS shows a Gatekeeper warning on first launch: open the app from Finder with right click, choose Open, then confirm.

## Implementation and provenance

SwiftUI menu bar interface, ScreenCaptureKit capture, Core Image processing on Metal, and a built-in HID sensor accessed through IOKit. No third-party runtime dependencies.

The rendering, capture, sensor handling and user interface were written for this project. No third-party source, shaders, artwork or compiled components are included.

Parts of this project were written with AI assistance (Claude Code). Every change was reviewed, built and tested by the author before it landed.

## Availability

The app is coming to the Mac App Store soon.

The owner intends to publish the app and source publicly. An open-source redistribution license has not yet been selected. Copyright © 2026 jkvn.

This project is not affiliated with or endorsed by Apple.
