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

## GitHub/native platforms

`actionlint` v1.7.12 validates `.github/workflows/release.yml`; all external
Actions are pinned to verified full commit hashes. Bash/Python syntax checks,
desktop entry validation and Git whitespace checks pass. Windows/macOS have
no locally generated installers yet. Their jobs must actually execute on
native GitHub runners to validate compiler compatibility, deployment, NSIS/DMG
creation, signatures, actual installed/image executable startup and mode tests.

The workflow prepares draft releases only. A GitHub remote has not been
configured or pushed. Windows signing and macOS Developer ID/notarization are
not configured; macOS uses ad-hoc signing. The project owner still needs to
choose a project-wide license before publishing as open source.
