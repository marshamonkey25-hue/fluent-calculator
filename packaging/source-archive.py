#!/usr/bin/env python3
"""Archive the current release source, excluding build state and local tickets."""
import argparse
from pathlib import Path
import re
import subprocess
import tarfile

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('dist'))
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
version = re.search(r'project\(FluentCalculator VERSION ([0-9.]+)',
                    (repo / 'CMakeLists.txt').read_text())[1]
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
archive = output / f'fluent-calculator-{version}-source.tar.gz'
names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=repo).split(b'\0')
with tarfile.open(archive, 'w:gz') as bundle:
    for raw in sorted(set(names)):
        if not raw:
            continue
        name = raw.decode()
        if name.startswith(('.build', '.scratch/', '.pi/', 'dist/')):
            continue
        path = repo / name
        if path.is_file() and path.resolve() != archive:
            bundle.add(path, arcname=f'fluent-calculator-{version}/{name}', recursive=False)
print(archive)
