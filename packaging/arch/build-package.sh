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
python3 - "$calc_repo" "$calc_workspace" <<'PY'
from pathlib import Path
import hashlib
import re
import subprocess
import sys
import tarfile

repo, workspace = map(Path, sys.argv[1:])
match = re.search(r'project\(FluentCalculator VERSION ([0-9.]+)', (repo / 'CMakeLists.txt').read_text())
if not match:
    raise SystemExit('Cannot determine project version')
version = match[1]
files = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=repo).split(b'\0')
archive = workspace / f'fluent-calculator-{version}.tar.gz'
with tarfile.open(archive, 'w:gz') as bundle:
    for raw in sorted(set(files)):
        if not raw:
            continue
        name = raw.decode()
        if name.startswith(('.scratch/', '.pi/', '.build')):
            continue
        path = repo / name
        if path.is_file():
            bundle.add(path, arcname=f'fluent-calculator-{version}/{name}', recursive=False)
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
template = (repo / 'packaging/arch/PKGBUILD.in').read_text()
(workspace / 'PKGBUILD').write_text(template.replace('@VERSION@', version).replace('@SOURCE_SHA256@', digest))
print(f'Source snapshot: {archive.name}; SHA256 {digest}', flush=True)
PY
(
    cd "$calc_workspace"
    PKGDEST="$calc_output" MAKEFLAGS=-j2 makepkg --force --cleanbuild --noconfirm
)
python3 - "$calc_workspace" "$calc_output" <<'PY'
from pathlib import Path
import hashlib
import shutil
import sys
workspace, output = map(Path, sys.argv[1:])
shutil.copy2(workspace / 'PKGBUILD', output / 'PKGBUILD')
archives = list(workspace.glob('fluent-calculator-*.tar.gz'))
for source in archives:
    shutil.copy2(source, output / source.name)
artifacts = sorted(p for p in output.iterdir() if p.name == 'PKGBUILD' or p.name.startswith('fluent-calculator-'))
(output / 'SHA256SUMS').write_text(''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n' for p in artifacts if p.is_file()))
for artifact in artifacts:
    print(f'Artifact: {artifact}')
PY
