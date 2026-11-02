#!/usr/bin/env bash
# Run distribution-native builds without installing packages on the host.
set -euo pipefail
calc_format=${1:?Usage: bash packaging/linux/build-package.sh deb|rpm}
case "$calc_format" in deb|rpm) ;; *) echo 'Expected deb or rpm' >&2; exit 2 ;; esac
calc_repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
calc_output="$calc_repo/dist"
mkdir -p "$calc_output"
docker build --file "$calc_repo/packaging/linux/Dockerfile.$calc_format" \
    --tag "fluent-calculator-builder:$calc_format" "$calc_repo/packaging/linux"
docker run --rm --network=none \
    --mount "type=bind,source=$calc_repo,target=/source,readonly" \
    --mount "type=bind,source=$calc_output,target=/out" \
    --env "CALCULATOR_OUTPUT_UID=$(id -u)" --env "CALCULATOR_OUTPUT_GID=$(id -g)" \
    "fluent-calculator-builder:$calc_format" \
    bash /source/packaging/linux/container-build.sh "$calc_format"
python3 "$calc_repo/packaging/checksums.py" "$calc_output"
