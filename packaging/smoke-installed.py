#!/usr/bin/env python3
"""Smoke-check an installed executable with no SDK search paths or desktop access."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


def run_child(executable, qt_root):
    environment = os.environ.copy()
    for name in ('QML_IMPORT_PATH', 'QML2_IMPORT_PATH', 'QT_PLUGIN_PATH', 'QT_QPA_PLATFORM_PLUGIN_PATH',
                 'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH', 'DYLD_FRAMEWORK_PATH'):
        environment.pop(name, None)
    if qt_root:
        root = os.path.normcase(os.path.abspath(qt_root))
        environment['PATH'] = os.pathsep.join(
            part for part in environment.get('PATH', '').split(os.pathsep)
            if not os.path.normcase(os.path.abspath(part)).startswith(root + os.sep))
    child = subprocess.Popen([str(executable)], env=environment, cwd=executable.parent,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        output, errors = child.communicate(timeout=4)
        raise RuntimeError(f'Installed application exited early ({child.returncode}): '
                           + errors.decode(errors='replace'))
    except subprocess.TimeoutExpired:
        child.terminate()
        output, errors = child.communicate(timeout=10)
    diagnostics = (output + errors).decode(errors='replace')
    fatal_markers = ('failed to load', 'module "', 'Cannot load', 'not found', 'QQmlApplicationEngine failed')
    if any(marker in diagnostics for marker in fatal_markers):
        raise RuntimeError('Installed application diagnostics: ' + diagnostics)
    return {'binary': str(executable), 'startup': 'running after four seconds',
            'diagnostics': diagnostics, 'isolation': 'offscreen/compose/private data and bus',
            'sdk_search_paths': 'removed', 'termination': 'task-owned child only'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--binary', required=True, type=Path)
    parser.add_argument('--qt-root', default='')
    parser.add_argument('--report', type=Path)
    parser.add_argument('--inside-isolation', action='store_true')
    args = parser.parse_args()
    binary = args.binary.resolve(strict=True)
    if args.qt_root and sys.platform == 'win32':
        for filename in ('Qt6Core.dll', 'Qt6Gui.dll', 'Qt6Qml.dll', 'vcruntime140.dll', 'msvcp140.dll'):
            if not (binary.parent / filename).is_file():
                raise RuntimeError('Deployed Windows runtime is missing: ' + filename)
    if args.qt_root and sys.platform == 'darwin':
        if not (binary.parents[1] / 'Frameworks/QtCore.framework').is_dir():
            raise RuntimeError('Deployed macOS Qt framework is missing')
    if args.inside_isolation:
        if os.environ.get('QT_QPA_PLATFORM') != 'offscreen' or os.environ.get('QT_IM_MODULE') != 'compose':
            raise RuntimeError('Refusing non-isolated GUI validation')
        result = run_child(binary, args.qt_root)
        text = json.dumps(result, indent=2)
        print(text)
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(text + '\n')
        return 0
    launcher = Path(__file__).resolve().parents[1] / 'tests/run-ui-isolated.py'
    command = [sys.executable, str(launcher), sys.executable, str(Path(__file__).resolve()),
               '--inside-isolation', '--binary', str(binary), '--qt-root', args.qt_root]
    if args.report:
        command += ['--report', str(args.report.resolve())]
    return subprocess.call(command, cwd=binary.parent)


if __name__ == '__main__':
    sys.exit(main())
