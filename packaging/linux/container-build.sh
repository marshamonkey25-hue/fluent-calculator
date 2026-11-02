#!/usr/bin/env bash
# Container-only: build and actually install the native package for validation.
set -euo pipefail
calc_format=${1:?Expected deb or rpm}
case "$calc_format" in
    deb) calc_generator=DEB; calc_platform=debian13-x86_64; calc_prefix=/opt/fluent-calculator; calc_bundle=ON ;;
    rpm) calc_generator=RPM; calc_platform=fedora43-x86_64; calc_prefix=/usr; calc_bundle=OFF ;;
    *) echo 'Expected deb or rpm' >&2; exit 2 ;;
esac
cmake -S /source -B /build/calculator -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
    -DCMAKE_INSTALL_PREFIX="$calc_prefix" -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_DOCDIR=share/doc/fluent-calculator \
    -DCALCULATOR_BUNDLE_QT="$calc_bundle" \
    -DCALCULATOR_PACKAGE_PLATFORM="$calc_platform"
cmake --build /build/calculator --parallel 2
ctest --test-dir /build/calculator -R '^calculator-integrated-delivery-' --show-only=json-v1 > /build/release-tests.json
python3 -c 'import json; assert len(json.load(open("/build/release-tests.json"))["tests"]) == 4'
ctest --test-dir /build/calculator -R '^calculator-integrated-delivery-' --output-on-failure -j2 \
    | tee "/out/${calc_platform}-tests.log"
cpack --config /build/calculator/CPackConfig.cmake -G "$calc_generator" -B /packages
shopt -s nullglob
calc_packages=(/packages/*."$calc_format")
(( ${#calc_packages[@]} == 1 )) || { echo 'Expected exactly one native package' >&2; exit 1; }
calc_package=${calc_packages[0]}
if [[ $calc_format == deb ]]; then
    dpkg-deb --info "$calc_package"
    dpkg-deb --contents "$calc_package"
    dpkg -i "$calc_package"
else
    rpm -qip "$calc_package"
    rpm -qlp "$calc_package"
    rpm -Uvh "$calc_package"
fi
# The installed app must not depend on the build's working directory or SDK.
if [[ $calc_format == deb ]]; then
    mv /opt/Qt /opt/Qt-sdk-unavailable-during-validation
fi
cd /tmp
python3 /source/packaging/smoke-installed.py --binary /usr/bin/fluent-calculator \
    --report "/out/${calc_platform}-validation.json"
cp "$calc_package" /out/
if [[ -n ${CALCULATOR_OUTPUT_UID:-} && -n ${CALCULATOR_OUTPUT_GID:-} ]]; then
    chown "$CALCULATOR_OUTPUT_UID:$CALCULATOR_OUTPUT_GID" \
        "/out/$(basename -- "$calc_package")" "/out/${calc_platform}-validation.json" \
        "/out/${calc_platform}-tests.log"
fi
