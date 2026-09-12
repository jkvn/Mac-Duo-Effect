# Mac Duo Effect

A free, native macOS menu bar utility that recreates the lid animation of the new iPhone Duo on the Mac: as you move your MacBook lid, the screen gains perspective, progressive blur and dimming.

Click the laptop icon in the menu bar. There is no separate settings window or Dock icon. All controls are in English.

## Requirements

- macOS 14 or later.
- A MacBook with a compatible, built-in HID lid-angle sensor. Apple Silicon and Intel binaries are included; sensor availability varies by model.
- Screen Recording permission for the live effect.

The current build is a development version. Public GitHub release and Mac App Store submission are pending.

## Controls

- **Depth effect:** enable or pause the effect.
- **Live rendering:** update screen content continuously, or hold the starting frame.
- **Stop when still:** end the effect after the lid stops moving.
- **Start angle / Full effect after:** choose when the effect begins and how many more degrees reach full blur and dimming.
- **Appearance:** blur radius, blur spread, dimming, dimming spread, lean back and perspective.
- **Show angle in menu bar / Launch at login:** optional convenience controls.
- **⋯ menu:** reset settings or quit the app.
- **Info (ⓘ):** about page with version, author ([jkvn](https://github.com/jkvn)) and the source repository ([Mac-Duo-Effect](https://github.com/jkvn/Mac-Duo-Effect)).

The depth effect is on by default. Without Screen Recording permission the switch is greyed out but stays on, and the effect starts by itself once permission is granted.

Only the built-in display is affected. Sleep, inactive sessions and Reduce Motion pause the effect. Capture stops after the effect is no longer needed. Screen frames are processed in memory, never saved or transmitted. The synthetic images created by the developer render check are not screenshots.

## Project layout

```
Sources/EffectCore        Settings model and effect math, shared and unit tested
Sources/MacDuoEffect/App          Entry point and menu bar scene
Sources/MacDuoEffect/Interface    Menu panel, about panel and shared controls
Sources/MacDuoEffect/Model        App state and the 30 Hz effect loop
Sources/MacDuoEffect/Capture      Lid angle sensor and screen capture
Sources/MacDuoEffect/Rendering    Core Image pipeline, overlay window, display lookup
Sources/MacDuoEffect/System       Screen Recording, launch at login, system events
Sources/MacDuoEffect/Diagnostics  Command line checks
```

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

A sandbox build is available with `scripts/build.sh appstore`. It is not an App Store upload until signed with the correct distribution identity and provisioning configuration.

## Implementation and provenance

SwiftUI menu bar interface, ScreenCaptureKit capture, Core Image processing on Metal, and a built-in HID sensor accessed through IOKit. No third-party runtime dependencies.

The rendering, capture, sensor handling and user interface were written for this project. No third-party source, shaders, artwork or compiled components are included.

Parts of this project were written with AI assistance (Claude Code). Every change was reviewed, built and tested by the author before it landed.

## Availability

The app is coming to the Mac App Store soon.

The owner intends to publish the app and source publicly. An open-source redistribution license has not yet been selected. Copyright © 2026 jkvn.

This project is not affiliated with or endorsed by Apple.
