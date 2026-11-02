#!/usr/bin/env bash
# Optional argument: an existing release source archive, otherwise committed HEAD.
set -euo pipefail
calc_repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
calc_workspace=$(mktemp -d "$calc_repo/.build-arch-input.XXXXXXXX")
trap 'rm -rf -- "$calc_workspace"' EXIT
calc_output=${CALCULATOR_ARCH_OUTPUT_DIR:-"$calc_repo/dist/arch"}
mkdir -p "$calc_output"
calc_output=$(cd -- "$calc_output" && pwd)
if (( $# )); then
    python3 "$calc_repo/packaging/arch/prepare-source.py" --workspace "$calc_workspace" --archive "$1"
else
    python3 "$calc_repo/packaging/arch/prepare-source.py" --workspace "$calc_workspace" --ref HEAD
fi
docker build --file "$calc_repo/packaging/arch/Dockerfile" \
    --tag fluent-calculator-builder:arch "$calc_repo/packaging/arch"
docker run --rm --network=none \
    --mount "type=bind,source=$calc_workspace,target=/input,readonly" \
    --mount "type=bind,source=$calc_output,target=/out" \
    --env "CALCULATOR_OUTPUT_UID=$(id -u)" --env "CALCULATOR_OUTPUT_GID=$(id -g)" \
    fluent-calculator-builder:arch bash /usr/local/bin/calculator-arch-build
python3 "$calc_repo/packaging/checksums.py" "$calc_output"
