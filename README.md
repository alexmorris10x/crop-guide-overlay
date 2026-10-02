# Crop Guide Overlay

A tiny macOS menu bar app that draws click-through crop guides on your screen.

It is built for recording horizontal screen/camera content in OBS while composing for vertical output later. Capture behavior depends on the recorder and source. Do not rely on overlay window flags to hide guides from recordings.

## Features

- Always-on-top crop guides
- Click-through overlay, so it does not block your mouse
- A visible capture-compatibility note and Hide Guides command
- Menu bar controls
- Presets for `9:16`, `1:1`, and `4:5`
- Saved preset, display selection, color and opacity
- Optional login startup that respects Quit

## Build

```bash
make app
```

The app bundle is created at:

```text
.build/Crop Guide Overlay.app
```

## Run

```bash
make run
```

Or double-click the app bundle.

## Package

```bash
make package
```

The distributable zip is created at:

```text
.build/CropGuideOverlay-macOS.zip
```

GitHub Releases are built automatically when a tag matching `v*` is pushed.

## Auto-start

```bash
make install-agent
```

Remove the LaunchAgent:

```bash
make uninstall-agent
```

## OBS Note

Apple documents `NSWindow.sharingType.none` as a legacy constant macOS no longer uses. Full-display recordings may contain the guides. Use recorder-side application/window exclusion when available, then inspect an exported test. Otherwise hide guides before recording. No capture path has current acceptance evidence.

| Capture path | Acceptance status | Required check |
|---|---|---|
| OBS display capture | Unverified; guides may be visible | Record OS/OBS version and exact source; inspect export |
| OBS application/window capture or exclusion | Unverified | Confirm Crop Guide is outside the selected content |
| macOS screenshot/recording toolbar | Unverified; no exclusion guarantee | Inspect a short export or hide guides |

Record results with OS version, recorder version, source configuration, and exported artifact before calling a combination supported. See [Apple’s window-sharing documentation](https://developer.apple.com/documentation/appkit/nswindow/sharingtype-swift.enum).

## Requirements

- macOS 13 or newer
- Xcode command line tools

## Contributing and support

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing changes.
- Use [GitHub Issues](https://github.com/alexmorris10x/crop-guide-overlay/issues) for reproducible bugs and focused feature requests.
- Read [SECURITY.md](SECURITY.md) before reporting a vulnerability.
- Support is best-effort; see [SUPPORT.md](SUPPORT.md).

## License

MIT. See [LICENSE](LICENSE). The original copyright notice is retained.

## Controls and verification

Use **Displays** to choose screens, **Guide Appearance** to change contrast/opacity, and the checked preset to set the crop. Selection uses persistent display UUIDs; screen changes rebuild only the affected windows. Redraws follow settings/display/Space changes instead of a repeating one-second timer.

The menu’s **Launch at Login** uses the macOS login-item service. Switching off a legacy LaunchAgent disables and removes it without closing the app; a later toggle enables the modern login item. Existing manually installed agents should be reinstalled once with `make install-agent` to remove their old KeepAlive setting. Quit then remains quit until the next login or manual launch.

`make test` covers all aspect ratios on landscape, portrait, square and ultrawide fixtures at 1×/2× scales. `make app` pins macOS 13.0. Builds use the host architecture; `ARCH=arm64` or `ARCH=x86_64` selects another target. Test old-OS runtime behavior and actual recorders separately.
