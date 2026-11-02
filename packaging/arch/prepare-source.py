#!/usr/bin/env python3
"""Prepare one checksummed Arch source archive and its matching PKGBUILD."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
from urllib.parse import urlsplit

parser = argparse.ArgumentParser()
parser.add_argument('--workspace', required=True, type=Path)
parser.add_argument('--archive', type=Path)
parser.add_argument('--ref')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
workspace = args.workspace.resolve()
workspace.mkdir(parents=True, exist_ok=True)
pattern = r'project\(FluentCalculator VERSION ([0-9]+\.[0-9]+\.[0-9]+)'
if args.archive:
    with tarfile.open(args.archive, 'r:*') as source:
        candidates = [m for m in source.getmembers() if m.isfile() and m.name.count('/') == 1 and m.name.endswith('/CMakeLists.txt')]
        if len(candidates) != 1:
            raise SystemExit('Expected one top-level calculator CMakeLists.txt')
        version = re.search(pattern, source.extractfile(candidates[0]).read().decode())[1]
        if candidates[0].name != f'fluent-calculator-{version}/CMakeLists.txt':
            raise SystemExit('Unexpected source archive prefix')
else:
    cmake = subprocess.check_output(['git', 'show', f'{args.ref}:CMakeLists.txt'], cwd=repo, text=True) if args.ref else (repo / 'CMakeLists.txt').read_text()
    version = re.search(pattern, cmake)[1]
archive = workspace / f'fluent-calculator-{version}-source.tar.gz'
if args.archive:
    if args.archive.resolve() != archive:
        shutil.copy2(args.archive, archive)
elif args.ref:
    subprocess.run(['git', 'archive', '--format=tar.gz', f'--prefix=fluent-calculator-{version}/',
                    f'--output={archive}', args.ref], cwd=repo, check=True)
else:
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=repo).split(b'\0')
    with tarfile.open(archive, 'w:gz') as source:
        for raw in sorted(set(names)):
            if not raw:
                continue
            name = raw.decode()
            if name.startswith(('.scratch/', '.pi/', '.build', 'dist/')):
                continue
            path = repo / name
            if path.is_file():
                source.add(path, arcname=f'fluent-calculator-{version}/{name}', recursive=False)
source_url = os.environ.get('CALCULATOR_ARCH_SOURCE_URL', '')
if not source_url and os.environ.get('GITHUB_REF_TYPE') == 'tag':
    tag = os.environ.get('GITHUB_REF_NAME', '')
    repository = os.environ.get('GITHUB_REPOSITORY', '')
    if tag != 'v' + version or not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise SystemExit('Source tag/repository does not match the package')
    source_url = f'https://github.com/{repository}/releases/download/{tag}/{archive.name}'
if source_url:
    parsed = urlsplit(source_url)
    if parsed.scheme != 'https' or parsed.netloc != 'github.com' or any(c in source_url for c in ('"', "'", '$', '`', '\n')):
        raise SystemExit('Invalid published source URL')
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
template = (repo / 'packaging/arch/PKGBUILD.in').read_text()
recipe = template.replace('@VERSION@', version).replace('@SOURCE_SHA256@', digest).replace('@SOURCE_URL_SUFFIX@', '::' + source_url if source_url else '')
(workspace / 'PKGBUILD').write_text(recipe)
metadata = {'version': version, 'archive': archive.name, 'sha256': digest, 'source_url': source_url,
            'reference': args.ref or ('provided archive' if args.archive else 'working tree snapshot')}
(workspace / 'source-metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
print(json.dumps(metadata, indent=2))
