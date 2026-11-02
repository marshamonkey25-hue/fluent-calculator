"""Behavioral checks at the isolated launcher's child-process boundary."""
import json
import os
from pathlib import Path
import socket
import stat
import subprocess
import sys
import tempfile
import unittest

LAUNCHER = Path(__file__).with_name("run-ui-isolated.py")
TEST_EXECUTABLE = None
if "--test-executable" in sys.argv:
    option = sys.argv.index("--test-executable")
    TEST_EXECUTABLE = str(Path(sys.argv[option + 1]).resolve())
    del sys.argv[option:option + 2]
REMOVED = ("DISPLAY", "WAYLAND_DISPLAY", "INPUT_METHOD", "XMODIFIERS",
           "GTK_IM_MODULE", "QT_IM_MODULES", "DBUS_SESSION_BUS_PID",
           "DBUS_STARTER_ADDRESS", "DBUS_STARTER_BUS_TYPE", "AT_SPI_BUS_ADDRESS",
           "QT_LINUX_ACCESSIBILITY_ALWAYS_ON", "QT_STYLE_OVERRIDE", "QT_QUICK_CONTROLS_CONF")


def probe():
    root = Path(os.environ["CALCULATOR_TEST_ISOLATION_ROOT"])
    for key, directory in (("XDG_RUNTIME_DIR", "runtime"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache")):
        path = Path(os.environ[key])
        assert path == root / directory, (key, path)
        if os.name == "posix":
            assert stat.S_IMODE(path.stat().st_mode) == 0o700
    for key in REMOVED:
        assert key not in os.environ, key
    assert os.environ["QT_IM_MODULE"] == "compose"
    assert os.environ["QT_QPA_PLATFORM"] == "offscreen"
    assert os.environ["QT_QUICK_BACKEND"] == "software"
    assert os.environ["QSG_RHI_BACKEND"] == "software"
    assert os.environ["DBUS_SYSTEM_BUS_ADDRESS"] == "unix:path=" + str(root / "runtime" / "no-system-bus")
    if sys.platform.startswith("linux"):
        address = os.environ["DBUS_SESSION_BUS_ADDRESS"]
        assert address.startswith("unix:path=" + str(root / "runtime" / "bus")), address
        # Authenticate only the launcher's private socket. Never query the host bus.
        with socket.socket(socket.AF_UNIX) as connection:
            connection.settimeout(5)
            connection.connect(str(root / "runtime" / "bus"))
            connection.sendall(b"\0AUTH EXTERNAL " + str(os.getuid()).encode().hex().encode() + b"\r\n")
            assert connection.recv(512).startswith(b"OK ")
    print(json.dumps({"root": str(root), "data": os.environ.get("CALCULATOR_TEST_DATA_ROOT"),
                      "bus": os.environ.get("DBUS_SESSION_BUS_ADDRESS")}))


class UiIsolation(unittest.TestCase):
    def test_direct_quicktest_relaunches_before_creating_the_gui(self):
        self.assertIsNotNone(TEST_EXECUTABLE, "Supply --test-executable for the direct-run isolation check")
        # The first red run remains safely under the outer launcher. Only after
        # that succeeds do we deliberately provide invalid inherited settings.
        for contaminated in (False, True):
            environment = os.environ.copy()
            environment.pop("CALCULATOR_TEST_ISOLATION_ROOT", None)
            if contaminated:
                environment.update({key: "not-a-real-host-endpoint" for key in REMOVED})
                environment.update({"QT_IM_MODULE": "inherited-ime", "QT_QPA_PLATFORM": "wayland",
                                    "DBUS_SESSION_BUS_ADDRESS": "unix:path=/nonexistent/calculator-host-bus"})
            child = subprocess.run([TEST_EXECUTABLE, "--isolation-probe"], env=environment,
                                   text=True, capture_output=True, timeout=20)
            self.assertEqual(child.returncode, 0, child.stdout + child.stderr)
            state = json.loads(child.stdout)
            self.assertEqual(state["platform"], "offscreen")
            self.assertEqual(state["ime"], "compose")
            self.assertTrue(state["desktopVariablesRemoved"])
            self.assertNotEqual(state["root"], os.environ["CALCULATOR_TEST_ISOLATION_ROOT"])
            if sys.platform.startswith("linux"):
                self.assertTrue(state["bus"].startswith("unix:path=" + state["root"] + "/runtime/bus"))

    @unittest.skipUnless(sys.platform.startswith("linux"), "Private D-Bus is a Linux launcher requirement")
    def test_missing_dbus_refuses_to_launch_the_child(self):
        with tempfile.TemporaryDirectory(prefix="missing-bus-fixture-", dir=Path.cwd()) as fixture:
            environment = os.environ.copy()
            environment["PATH"] = fixture
            sentinel = Path(fixture) / "child-was-launched"
            child = subprocess.run([sys.executable, str(LAUNCHER), sys.executable, "-c",
                                    "import pathlib,sys; pathlib.Path(sys.argv[1]).touch()", str(sentinel)],
                                   env=environment, text=True, capture_output=True, timeout=10)
            self.assertEqual(child.returncode, 2)
            self.assertIn("require dbus-run-session", child.stderr)
            self.assertFalse(sentinel.exists(), "Missing isolation must never fall back to launching the child")

    def test_child_gets_private_storage_compose_and_a_fresh_usable_bus(self):
        with tempfile.TemporaryDirectory(prefix="isolation-host-fixture-", dir=Path.cwd()) as fixture:
            environment = os.environ.copy()
            environment.update({key: "inherited-value-must-not-reach-child" for key in REMOVED})
            environment.update({"QT_IM_MODULE": "inherited-ime", "QT_QPA_PLATFORM": "wayland",
                                "QT_QUICK_BACKEND": "inherited-backend", "QSG_RHI_BACKEND": "vulkan",
                                "DBUS_SESSION_BUS_ADDRESS": "unix:path=" + fixture + "/host-bus",
                                "XDG_RUNTIME_DIR": fixture, "XDG_CONFIG_HOME": fixture,
                                "XDG_DATA_HOME": fixture, "XDG_CACHE_HOME": fixture,
                                "CALCULATOR_TEST_DATA_ROOT": fixture + "/restart-data"})
            child = subprocess.run([sys.executable, str(LAUNCHER), sys.executable,
                                    str(Path(__file__).resolve()), "--probe"],
                                   env=environment, text=True, capture_output=True, timeout=20)
            self.assertEqual(child.returncode, 0, child.stdout + child.stderr)
            state = json.loads(child.stdout)
            self.assertNotEqual(state["root"], fixture)
            self.assertFalse(Path(state["root"]).exists(), "Launcher removes private roots after exit")
            self.assertEqual(state["data"], fixture + "/restart-data", "Restart fixture root survives child launches")
            if sys.platform.startswith("linux"):
                self.assertNotEqual(state["bus"], environment["DBUS_SESSION_BUS_ADDRESS"])


if __name__ == "__main__":
    if sys.argv[1:] == ["--probe"]:
        probe()
    else:
        unittest.main()
