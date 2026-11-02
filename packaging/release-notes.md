## Installers

- Debian 13 x86_64: `.deb`, with private Qt 6.8.3 libraries and FluentWinUI3 under `/opt/fluent-calculator`.
- Fedora 43 x86_64: `.rpm`, using Fedora's Qt packages.
- Windows x86_64: NSIS `.exe` installer and deployed portable `.zip`.
- macOS: `.dmg` containing a universal arm64/x86_64 application bundle.

Each installer is built on its native operating system or target Linux distribution.
The source archive matches this tag; `SHA256SUMS` covers the installer/source files.
Build/install smoke reports accompany the artifacts. UI validation runs offscreen
with Compose input and isolated settings/session buses.

The Windows installer is unsigned. The macOS application has an ad-hoc signature,
not an Apple Developer ID signature or notarization. A draft release is created
for review; this workflow does not publish it automatically.

Graphing covers explicit `y=f(x)` functions. Currency conversion uses independent
daily reference data and cached observations, not real-time transaction quotes.
See the bundled notices and source documentation. Project-authored code currently
has no separately declared project-wide distribution license; select and record
that license before publishing the draft as an open-source release.
