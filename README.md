# Crop Guide Overlay

A tiny macOS menu bar app that draws click-through crop guides on your screen while hiding those guides from screen capture.

It is built for recording horizontal screen/camera content in OBS while composing for vertical output later. You can see the guides on your Mac, but the overlay window uses `NSWindow.sharingType = .none`, so macOS screen capture APIs should omit it.

## Features

- Always-on-top crop guides
- Click-through overlay, so it does not block your mouse
- Hidden from macOS screen capture APIs
- Menu bar controls
- Presets for `9:16`, `1:1`, and `4:5`
- Optional LaunchAgent for auto-start / keep-alive

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

Do a short test recording before a production take. macOS screenshots exclude this overlay in testing, and OBS should do the same when using macOS screen capture APIs.

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
