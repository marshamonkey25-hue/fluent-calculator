## Changes

- Keep the complete programmer keypad visible in compact windows, including 320×460 and 402×632.
- Combine keypad/bit view, word width and memory actions into one compact toolbar.
- Balance display, radix and keypad regions using the reference layout's proportions.
- Retain equal keypad cells and add full-visibility/toolbar bounds regressions.

## Installers

- Arch Linux / Omarchy x86_64: `.pkg.tar.zst` and the matching PKGBUILD.
- Debian 13 x86_64: `.deb`, with private Qt 6.8.3 libraries and FluentWinUI3 under `/opt/fluent-calculator`.
- Fedora 43 x86_64: `.rpm`, using Fedora's Qt packages.
- Windows x86_64: NSIS `.exe` installer and deployed portable `.zip`.
- macOS: `.dmg` containing a universal arm64/x86_64 application bundle.

Each installer is built on its native operating system or target Linux distribution.
The source archive matches this tag; `SHA256SUMS` covers the installer/source files.
Build/install smoke reports accompany the artifacts. UI validation runs offscreen
with Compose input and isolated settings/session buses.

The Windows installer is unsigned. The macOS application has an ad-hoc signature,
not an Apple Developer ID signature or notarization. This release is automatically
published after the matching version tag passes all platform builds, installer
checks and checksum validation.

Graphing covers explicit `y=f(x)` functions. Currency conversion uses independent
daily reference data and cached observations, not real-time transaction quotes.
See the bundled notices and source documentation. Project-authored code currently
has no separately declared project-wide distribution license. Publishing this
release does not assign one; dependency notices remain independently applicable.
