# Arch / Omarchy installation package

The local x86_64 package is `dist/fluent-calculator-0.1.0-1-x86_64.pkg.tar.zst`.
It installs the `fluent-calculator` command, an English/Chinese desktop menu
entry, PNG/SVG icons, documentation and the applicable Microsoft notices.
It dynamically links the system Qt installation rather than bundling Qt.

## Install and remove

From the checkout root:

```sh
sudo pacman -U ./dist/fluent-calculator-0.1.0-1-x86_64.pkg.tar.zst
fluent-calculator
```

The application also appears as **Fluent Calculator / Fluent 计算器** in the
system application menu. System hooks update the desktop/icon caches when
pacman installs the package. Installing it is separate from building it;
the packaging script never invokes sudo, installs dependencies or modifies
the system package database.

To remove it:

```sh
sudo pacman -R fluent-calculator
```

Application preferences and exchange-rate cache remain in the user's usual
Qt settings/data locations. Removing the package does not erase user data.

## Build a new local package

Required tools: Arch `base-devel`, `cmake`, `qt6-base`, `qt6-declarative`,
`pkgconf`, `python` and Git. Qt must be at least 6.8 and provide FluentWinUI3.

```sh
bash packaging/arch/build-package.sh
```

The script snapshots the current source, including intentional uncommitted
files, into a local source archive; build trees, Git internals, ticket files
and previous package artifacts are excluded. It generates a checksummed
PKGBUILD, builds from that archive with testing disabled, and writes the
native package, matching source archive, PKGBUILD and `SHA256SUMS` to `dist/`.
The dedicated workspace is `.build-arch-package/`. No network source fetch
is required. Existing build dependencies must already be installed.

The package's Qt runtime requirements are recorded from the actual Qt release
used to compile it. A binary built against Qt 6.12 is not advertised as
compatible with a machine still on Qt 6.8. Arch is a rolling distribution;
rebuild after incompatible system ABI changes rather than copying the binary
to unrelated Linux distributions. This is not an AppImage, Debian package,
Windows installer or macOS application bundle.

## Packaging validation

Validate the desktop entry, inspect metadata and extract into a temporary
staging directory without installing:

```sh
desktop-file-validate packaging/linux/fluent-calculator.desktop
pacman -Qip dist/fluent-calculator-0.1.0-1-x86_64.pkg.tar.zst
pacman -Qlp dist/fluent-calculator-0.1.0-1-x86_64.pkg.tar.zst
cd dist && sha256sum -c SHA256SUMS
```

A packaged executable must be smoke-tested through the repository's
`tests/run-ui-isolated.py`, which isolates the desktop, IME, session bus and
application data. Do not launch test windows on the active desktop. A bounded
smoke verifies startup with the binary extracted from the final package;
it is separate from the full source application's behavior test suite.

## License metadata

The PKGBUILD records `MIT` for the reused Microsoft material and
`LicenseRef-Project-Unspecified` for project-authored material that has no
separate project-wide license declaration. The packaging work does not assign
a new license on the owner's behalf. The package is a local installation
artifact; its matching source snapshot is supplied. Qt and system libraries
remain subject to their system packages' separate terms. See the shipped
license status, Microsoft notices and currency-source documentation.
