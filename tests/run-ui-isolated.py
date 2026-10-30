#!/usr/bin/env python3
"""Run a test without access to the desktop, inherited IME, or session bus.

The environment contract follows the tested run-ui-isolated.sh handoff. Linux
adds a private D-Bus socket/config with no host service activation directories.
"""
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
from xml.sax.saxutils import escape


def main():
    if len(sys.argv) < 2:
        print("Usage: run-ui-isolated.py <test command> [args...]", file=sys.stderr)
        return 2
    linux = sys.platform.startswith("linux")
    dbus = shutil.which("dbus-run-session") if linux else None
    if linux and not dbus:
        print("Linux UI tests require dbus-run-session; refusing to use the host bus.", file=sys.stderr)
        return 2
    # A short path is necessary for the Linux Unix-domain socket length limit.
    with tempfile.TemporaryDirectory(prefix="calc-ui-", dir="/tmp" if linux else None) as temporary:
        root = Path(temporary)
        environment = os.environ.copy()
        for key in ("DISPLAY", "WAYLAND_DISPLAY", "INPUT_METHOD", "XMODIFIERS", "GTK_IM_MODULE",
                    "QT_IM_MODULES", "DBUS_SESSION_BUS_ADDRESS", "DBUS_SESSION_BUS_PID",
                    "DBUS_STARTER_ADDRESS", "DBUS_STARTER_BUS_TYPE", "AT_SPI_BUS_ADDRESS",
                    "QT_LINUX_ACCESSIBILITY_ALWAYS_ON", "QT_STYLE_OVERRIDE", "QT_QUICK_CONTROLS_CONF"):
            environment.pop(key, None)
        for key, directory in (("XDG_RUNTIME_DIR", "runtime"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache")):
            path = root / directory
            path.mkdir(mode=0o700)
            environment[key] = str(path)
        environment.update({"QT_IM_MODULE": "compose", "QT_QPA_PLATFORM": "offscreen",
                            "QT_QPA_PLATFORMTHEME": "generic", "QT_QUICK_CONTROLS_STYLE": "FluentWinUI3",
                            "QT_QUICK_BACKEND": "software", "QSG_RHI_BACKEND": "software",
                            "NO_AT_BRIDGE": "1", "CALCULATOR_TEST_ISOLATION_ROOT": str(root),
                            "DBUS_SYSTEM_BUS_ADDRESS": "unix:path=" + str(root / "runtime" / "no-system-bus")})
        if os.name == "nt":
            environment.update({"APPDATA": str(root / "data"), "LOCALAPPDATA": str(root / "cache")})
        command = sys.argv[1:]
        if linux:
            config = root / "bus.conf"
            config.write_text("<busconfig><type>session</type><listen>unix:path="
                              + escape(str(root / "runtime" / "bus"))
                              + "</listen><auth>EXTERNAL</auth><policy context=\"default\">"
                                "<allow send_destination=\"*\"/><allow receive_sender=\"*\"/>"
                                "<allow own=\"*\"/></policy></busconfig>", encoding="utf-8")
            command = [dbus, "--config-file=" + str(config), "--"] + command
        else:
            environment["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=" + str(root / "runtime" / "no-session-bus")
        child = subprocess.Popen(command, env=environment)
        def forward(signum, _frame):
            if child.poll() is None:
                child.send_signal(signum)
        for signum in (signal.SIGINT, signal.SIGTERM):
            signal.signal(signum, forward)
        result = child.wait()
        return result if result >= 0 else 128 - result


if __name__ == "__main__":
    sys.exit(main())
