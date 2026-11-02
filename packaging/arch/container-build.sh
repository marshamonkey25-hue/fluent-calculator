#!/usr/bin/env bash
# Container entry: package as a regular user, install only inside this container.
set -euo pipefail
install -d -o builder -g builder /build
cp /input/PKGBUILD /input/*-source.tar.gz /input/source-metadata.json /build/
chown builder:builder /build/*
runuser -u builder -- bash -c 'cd /build && MAKEFLAGS=-j2 makepkg --force --cleanbuild --noconfirm'
shopt -s nullglob
calc_packages=(/build/*.pkg.tar.zst)
(( ${#calc_packages[@]} == 1 )) || { echo 'Expected one Arch package' >&2; exit 1; }
calc_package=${calc_packages[0]}
pacman -Qip "$calc_package"
pacman -Qlp "$calc_package"
pacman -U --noconfirm "$calc_package"
calc_version=$(python3 -c 'import json; print(json.load(open("/build/source-metadata.json"))["version"])')
calc_source="/build/src/fluent-calculator-$calc_version"
cd /tmp
python3 "$calc_source/packaging/smoke-installed.py" --binary /usr/bin/fluent-calculator \
    --report /out/archlinux-x86_64-validation.json
cp "$calc_package" /out/
cp /build/PKGBUILD "/out/fluent-calculator-$calc_version-arch-PKGBUILD"
cp /input/*-source.tar.gz /out/
cp /build/src/arch-tests.log /out/archlinux-x86_64-tests.log
cp /input/source-metadata.json /out/archlinux-source-metadata.json
if [[ -n ${CALCULATOR_OUTPUT_UID:-} && -n ${CALCULATOR_OUTPUT_GID:-} ]]; then
    chown "$CALCULATOR_OUTPUT_UID:$CALCULATOR_OUTPUT_GID" /out/*
fi
