# Build installers and publish a GitHub Release

The workflow is `.github/workflows/release.yml`. It builds actual native
artifacts, verifies installed/deployed applications, uploads them as Actions
artifacts, verifies checksums and automatically publishes a GitHub Release for a
matching pushed version tag. Manual runs build/upload artifacts without creating
or publishing a Release. Failed builds or validation stop publication.
See [the actual packaging validation record](packaging-validation.md) for the
successful native run, platform coverage and installer verification evidence.
The public repository is https://github.com/marshamonkey25-hue/fluent-calculator .

## Artifact matrix

| Target | Build environment | Output | Qt runtime |
| --- | --- | --- | --- |
| Arch / Omarchy x86_64 | Arch Linux container; unprivileged `makepkg` | `.pkg.tar.zst`, matching PKGBUILD | System Qt; actual build version in dependencies |
| Debian 13 x86_64 | Debian 13 container | `.deb` | Private official Qt 6.8.3 under `/opt/fluent-calculator` |
| Fedora 43 x86_64 | Fedora 43 container | `.rpm` | Fedora Qt; ELF and QML dependencies recorded |
| Windows x86_64 | `windows-2022`, MSVC 2022 | NSIS `.exe`, portable `.zip` | Qt 6.8.3, QML/plugins and compiler runtime deployed by Qt |
| macOS arm64 + x86_64 | `macos-15`, universal build | `.dmg` containing `FluentCalculator.app` | Qt 6.8.3 frameworks/QML/plugins deployed inside the app |

A package for Debian 13 or Fedora 43 is not claimed compatible with every
Debian/RPM distribution or older glibc. Windows/macOS outputs are only real
release artifacts after their native jobs succeed; configuring those jobs on
Linux does not constitute a native build or platform verification.

Debian's system Qt 6.8 omits FluentWinUI3, so the Debian package includes a
private Qt SDK and its matching theme. `/usr/bin/fluent-calculator` links to
the private executable; the desktop entry/icons remain in the standard
application directories. It does not replace Debian's Qt. Arch/Fedora use
their complete distribution Qt installations.

## Local Linux packages

Docker must be available. These commands install build dependencies and the
resulting package **inside disposable containers**, not on the host:

```sh
bash packaging/linux/build-package.sh deb
bash packaging/linux/build-package.sh rpm
bash packaging/arch/build-in-container.sh
# Alternatively, directly on Arch with the build/check dependencies installed:
bash packaging/arch/build-package.sh
```

Artifacts, source snapshots, checksums and platform validation JSON files are
written to `dist/` (containerized Arch outputs are in `dist/arch/`). Arch runs
`makepkg` as an unprivileged build user, checks all 18 modes, then installs and
smoke-tests the package inside its disposable container. The generated Arch
PKGBUILD and source archive are included in the combined release; publication
checks that the recipe's SHA256 matches that exact archive. An absent Arch
package fails the release gate just like any other required format.

The two Dockerfiles pin the target distribution major
version; Debian also pins Qt 6.8.3 and aqtinstall 3.3.0. Native Linux packages
are installed with `dpkg`/`rpm` and smoke-tested before being copied out. The
build/validation container has no network access after dependencies/SDK have
been prepared. No host display or session sockets are mounted.

Install a matching package on its target system:

```sh
# Debian 13: apt installs the recorded system dependencies.
sudo apt install ./fluent-calculator-0.1.0-debian13-x86_64.deb
# Fedora 43:
sudo dnf install ./fluent-calculator-0.1.0-fedora43-x86_64.rpm
```

The launcher and application-menu name are `fluent-calculator` and
**Fluent Calculator / Fluent 计算器**. See the Arch-specific instructions in
[installation.md](installation.md).

All source/recipe artifacts supplied by the Arch job are kept together during
aggregation. The release job uses that archive rather than regenerating one
with a potentially different compressed checksum. Tagged recipes point to the
matching release source URL; manual build recipes use the supplied local archive.

## GitHub procedure

1. Commit the complete source and packaging files, including `.github`, and
   push them to the intended GitHub repository. This checkout's `origin` is
   https://github.com/marshamonkey25-hue/fluent-calculator ; `main` is pushed.
2. In Actions, enable **Build release installers** and run it manually first.
   Check all Debian, Fedora, Windows and macOS jobs. Download the combined
   `release-all-platforms` artifact to inspect every installer, matching source,
   validation report and `SHA256SUMS`.
3. Set the version in CMake to the intended release version. Commit it, then
   create and push the matching tag, for example `v0.1.0`. The workflow rejects
   a tag whose version does not match CMake.
4. After every platform succeeds, the tag build automatically publishes a
   GitHub Release containing all installers, the matching source archive,
   validation evidence and `SHA256SUMS`. GitHub CLI stages uploads before
   publication, so interrupted uploads can leave a recoverable draft. Rerunning
   the workflow completes an existing draft; an already published release and
   its assets are left untouched. Fix a published version with a new version/tag
   rather than moving its tag or replacing its installers.

The first automatic release is [v0.1.0](https://github.com/marshamonkey25-hue/fluent-calculator/releases/tag/v0.1.0),
published by [tag workflow 41392805235](https://github.com/marshamonkey25-hue/fluent-calculator/actions/runs/41392805235).
For the next release, first update the CMake project version to `0.1.2` and
commit/push that change, then push the matching annotated tag:

```sh
git tag -a v0.1.2 -m "Release v0.1.2"
git push origin v0.1.2
```

Use a new matching `vX.Y.Z` tag for each later release. `main` pushes alone do not
publish. Manual workflow dispatch also never publishes, even against a tag ref.

All third-party Actions are pinned to verified commit IDs. Workflow permissions
are read-only except the final release job's `contents: write`. Publication
uses the repository's standard `GITHUB_TOKEN`; no personal token is needed. If organization policy blocks write tokens or third-party Actions,
allow those specific capabilities in repository settings before running.

## Runtime and installer checks

- Each platform first runs the four integrated-delivery configurations, exercising
  all 18 modes in English/Chinese and light/dark on that platform's actual Qt.
  Linux then validates each package using the target distribution's package manager
  and launches the installed executable from a neutral directory; the Debian SDK
  is temporarily removed from its original location to verify private-runtime use.
- Windows checks a deployed staging tree and silently installs the actual
  NSIS installer into a runner-temporary directory, validates the installed
  executable and invokes its uninstaller.
- macOS checks both architectures and the app signature, then mounts the real
  DMG read-only and validates the app in that image.
- `packaging/smoke-installed.py` removes SDK plugin/library search paths and
  enters `tests/run-ui-isolated.py` before starting any GUI process. All checks
  use offscreen/software rendering, Compose input and private settings/data;
  Linux also creates a private D-Bus session. Test windows never connect to
  the user's desktop or input-method bus. Only task-owned processes are stopped.

These are installer/deployment checks, not replacements for the detailed
application regression suite. The full suite remains available through the
normal CMake/CTest configuration. No cross-platform support claim should be
made until the corresponding native build and installer jobs pass.

## Signing and release notices

The default macOS bundle is ad-hoc signed after all runtime files/notices are
installed. It is **not Developer ID signed or notarized**. The Windows installer
is **unsigned**. They can be built without signing credentials; trusted public
signatures require the owner's certificates and a separate signing/notarization
configuration. This workflow does not invent or store credentials.

Qt runtime/license texts and applicable Microsoft notices are packaged. A matching
application source archive is attached. Project-authored code has no declared
project-wide distribution license yet; this work preserves that status rather
than assigning one. Before publishing as an open-source project, select and
commit the project's license. Dependency notices remain independently applicable.
