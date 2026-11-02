#!/usr/bin/env python3
"""Generate release hashes for actual installer/source artifacts in one directory."""
from pathlib import Path
import hashlib
import sys

folder = Path(sys.argv[1]).resolve()
suffixes = ('.deb', '.rpm', '.dmg', '.exe', '.zip', '.tar.gz', '.pkg.tar.zst')
lines = []
for path in sorted(folder.iterdir()):
    if not path.is_file() or not path.name.endswith(suffixes):
        continue
    with path.open('rb') as source:
        digest = hashlib.file_digest(source, 'sha256').hexdigest() if sys.version_info >= (3, 11) else hashlib.sha256(source.read()).hexdigest()
    lines.append(f'{digest}  {path.name}\n')
if not lines:
    raise SystemExit('No installer/source artifacts found')
(folder / 'SHA256SUMS').write_text(''.join(lines), encoding='utf-8')
print(''.join(lines), end='')
