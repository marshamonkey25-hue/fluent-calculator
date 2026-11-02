# Installer validation record

This record supplements the application-level delivery report; it does not
claim that a workflow file alone proves native Windows/macOS support.

## Linux artifacts actually produced

- `dist/fluent-calculator-0.1.0-debian13-x86_64.deb`: built in Debian 13 with
  official Qt 6.8.3, private runtime under `/opt/fluent-calculator`.
- `dist/fluent-calculator-0.1.0-fedora43-x86_64.rpm`: built in Fedora 43 with
  its distribution Qt.
- The earlier Arch `dist/fluent-calculator-0.1.0-1-x86_64.pkg.tar.zst` remains
  available with its original matching `fluent-calculator-0.1.0.tar.gz`.
- `dist/fluent-calculator-0.1.0-source.tar.gz` is the current release-source
  snapshot with the new multi-platform packaging configuration.

Debian and Fedora each passed all four integrated-delivery configurations
(English/Chinese × Light/Dark), exercising all 18 modes. Final runs took
121.36 s and 121.34 s respectively. See `dist/*-tests.log`. Each actual package
was installed in its target container and its installed executable ran for
four seconds under the isolated launcher before task-owned cleanup. Debian
was additionally tested with the original SDK directory renamed/unavailable.
The desktop entry/icons and distribution runtime dependencies are packaged.
No installer was installed on the host, and no host desktop/IME/bus was used.

Debian's offscreen plugin emits the known `propagateSizeHints` capability
warning; it does not emit a missing-QML/module/library error. Fedora's smoke
log is empty. See `dist/*-validation.json` and `dist/SHA256SUMS`.

## Compatibility correction and regression

The first real Qt 6.8 integrated run exposed `ComboBox.currentValue` being
read-only in that version. Both converter selections now bind `currentIndex`
through the existing unit-ID catalog instead; the read-only `currentValue`
continues to supply the user-activated selection. No arithmetic changed.
Debian's final four configurations pass after this correction.

The host Qt 6.12 build and QML lint pass. The affected Length, Data and Currency
matrix passed 7/9 entries initially; two Currency configurations exceeded their
unchanged 180-second deadlines during concurrent container work, without
assertion failures. Serial reruns of those two complete Currency suites each
passed 63 outcomes with zero failures/skips in 106.59 s and 107.75 s. This is
passing coverage across the run and reruns, not one all-green nine-entry run.
Evidence remains in `.build-release-packages/qt612-selection-regression.log`
and `.build-release-packages/currency-serial/`.

## GitHub/native platforms — verified 2026-11-02

Repository: https://github.com/marshamonkey25-hue/fluent-calculator . The complete
manual run [41385170513](https://github.com/marshamonkey25-hue/fluent-calculator/actions/runs/41385170513)
passed on source commit `908526a2ab10bbe3299841d8dfa290edafe5689a`. All four
platform jobs and the combined-artifact job succeeded. This is executed CI
evidence, not a configuration-only claim.

- Windows Server 2022 runner / MSVC: the native x86_64 build, isolation bootstrap,
  menu/clipboard regressions and four integrated mode configurations pass. Qt
  deployment and runtime DLL checks pass. The NSIS installer was actually
  installed silently into a temporary directory, the installed program started
  with SDK search paths removed, and its uninstaller was invoked. Both `.exe`
  and deployed `.zip` were produced.
- macOS 15 Apple Silicon runner: native universal build, bootstrap/clipboard
  regressions and all four mode configurations pass. `lipo` verifies arm64 and
  x86_64 slices. Deployment, strict ad-hoc signature verification, staged app
  startup, DMG generation, read-only image mounting and startup from the actual
  image all pass. Execution was on arm64; Intel execution and hardware/native
  desktop rendering are not claimed.
- Debian 13 and Fedora 43 jobs also passed their four configurations, native
  package installation and isolated installed-program smoke checks in this run.
- The `release-all-platforms` artifact contains `.deb`, `.rpm`, `.exe`, `.zip`,
  `.dmg`, the matching source archive, validation JSON/logs and `SHA256SUMS`.
  The local download directory is `dist/release-0.1.0/`.

Real native runs found and fixed missing MSVC SAL/iterator headers, Windows
path-separator validation and recursive test-launch behavior, and macOS menu
focus/clipboard routing. The menus use application-window popups, editable
text retains its own clipboard commands, and navigation restores input focus.
Tests query actual platform key bindings rather than assuming Ctrl+Insert is
available everywhere. The isolation guard fails closed after one unsuccessful
repair launch. Regression assertions were retained, not skipped.

Qt 6.8 deployment scripts do not quote a spaced app filename, so the physical
bundle is `FluentCalculator.app` while its display name remains Fluent
Calculator. The architecture check uses `lipo <binary> -verify_arch arm64 x86_64`.
DMG notices remain inside the app instead of an interactive disk-image SLA.

`actionlint` v1.7.12 and source syntax/whitespace checks pass; external Actions
are pinned to verified commits. All GUI checks remain offscreen/Compose with
isolated data and no user-desktop/IME interaction. Linux uses private D-Bus;
Linux-only D-Bus checks are not imposed on macOS/Windows.

That manual run did not create a tag or GitHub Release. Windows remains
unsigned, and macOS is ad-hoc signed rather than Developer ID signed/notarized.
A project-wide license has not been assigned on the owner's behalf.

## Tag-triggered publication — v0.1.0

The user subsequently authorized automatic publication from version tags.
Annotated tag `v0.1.0` points to commit
`dffc60e2f42ade8249c63bc48533539a83ec347b` and triggered
[workflow 41392805235](https://github.com/marshamonkey25-hue/fluent-calculator/actions/runs/41392805235).
Every platform build, integrated check, installer verification and final release
job passed. The Release was automatically published by `github-actions[bot]` at
2026-11-02 05:21:32 UTC:

https://github.com/marshamonkey25-hue/fluent-calculator/releases/tag/v0.1.0

The API confirms `draft=false`, `prerelease=false` and that this is the latest
Release. Its 15 assets include the five installer/distribution formats, matching
source, `SHA256SUMS` and eight validation reports/logs. The six binary/source
entries in the published `SHA256SUMS` were checked against GitHub's uploaded
asset SHA256 digests; all match and every asset state is `uploaded`.

Publication requires a pushed version tag matching CMake and successful platform
and checksum checks. Manual dispatch never publishes. A rerun may finish an
interrupted draft, but leaves already-published releases and assets unchanged.
The release/tag retains its original build commit; later validation-document
updates on `main` do not move the tag or replace its assets.
