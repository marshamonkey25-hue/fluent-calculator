#!/usr/bin/env bash
# Build a local Arch package without installing anything or using sudo.
set -euo pipefail
calc_repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
calc_output="$calc_repo/dist"
calc_workspace="$calc_repo/.build-arch-package"
for calc_tool in python3 git makepkg cmake make pkg-config; do
    command -v "$calc_tool" >/dev/null || { echo "Missing build tool: $calc_tool" >&2; exit 1; }
done
mkdir -p "$calc_output" "$calc_workspace"
python3 "$calc_repo/packaging/arch/prepare-source.py" --workspace "$calc_workspace"
(
    cd "$calc_workspace"
    PKGDEST="$calc_output" MAKEFLAGS=-j2 makepkg --force --cleanbuild --noconfirm
)
python3 - "$calc_workspace" "$calc_output" <<'PY'
from pathlib import Path
import json
import shutil
import sys
workspace, output = map(Path, sys.argv[1:])
metadata = json.loads((workspace / 'source-metadata.json').read_text())
shutil.copy2(workspace / 'PKGBUILD', output / 'PKGBUILD')
shutil.copy2(workspace / metadata['archive'], output / metadata['archive'])
PY
python3 "$calc_repo/packaging/checksums.py" "$calc_output"
