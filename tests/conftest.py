r"""Shared test fixtures.

Storage is redirected to a temporary directory *before* the app package is
imported so tests never read or write the real %APPDATA%\TargetSheet data.

Tk cannot sustain a fresh root per test (the interpreter runs out of resources
after a few dozen), so one app instance is built for the whole session and its
mutable state is reset between tests.  Tests that need to observe construction
itself use the `build_app` factory, which builds and tears down its own root.
"""
import os
import pathlib
import sys
import tempfile

import pytest

SRC = pathlib.Path(__file__).resolve().parent.parent / "TargetSheet"
sys.path.insert(0, str(SRC))

# Redirect the data dir before `storage` is imported anywhere.
_SESSION_TMP = tempfile.mkdtemp(prefix="targetsheet_tests_")
os.environ["APPDATA"] = _SESSION_TMP
os.environ["XDG_DATA_HOME"] = _SESSION_TMP


def _require_tk():
    import tkinter as tk
    try:
        probe = tk.Tk()
        probe.destroy()
    except Exception as exc:                      # pragma: no cover
        pytest.skip(f"no usable Tk display: {exc}")


@pytest.fixture
def data_dir(tmp_path, monkeypatch):
    """Point storage at a fresh per-test directory."""
    monkeypatch.setenv("APPDATA", str(tmp_path))
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))
    return tmp_path / "TargetSheet"


@pytest.fixture(scope="session")
def _session_app():
    """One app instance for the whole session (Tk roots are expensive)."""
    import tkinter as tk
    _require_tk()
    original = tk.Tk.mainloop
    tk.Tk.mainloop = lambda self: None
    try:
        from app import TargetSheetApp
        instance = TargetSheetApp()
        instance.root.update_idletasks()
        yield instance
        try:
            instance.root.destroy()
        except Exception:
            pass
    finally:
        tk.Tk.mainloop = original


@pytest.fixture
def app(_session_app, monkeypatch, tmp_path):
    """The shared app with all mutable state reset to a clean start."""
    monkeypatch.setenv("APPDATA", str(tmp_path))
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))

    a = _session_app
    a.shots = []
    a.strings = []
    a.wind_val = 0.0
    a.elev_val = 0.0
    a.conv = "none"
    a.conv_chosen = False
    a.analysis_idx = None
    a.shoot_len = 10
    a.show_rec = True
    a.show_graphs = True
    a.target_number = ""
    a._zoom, a._pan = 1.0, [0.0, 0.0]
    a._a_zoom, a._a_pan = 1.0, [0.0, 0.0]
    a.root.geometry("1080x720")   # a resize test must not leak into the next
    a._select_distance("300y-nra")
    a.show_screen("menu")
    a.root.update_idletasks()
    return a


_PHASE_PRELUDE = f"""
import os, sys, types
sys.path.insert(0, {str(SRC)!r})
import tkinter as tk
tk.Tk.mainloop = lambda self: None
import storage
from app import TargetSheetApp

def click(app, svg_x, svg_y):
    px, py = app._to_canvas(svg_x, svg_y)
    app._on_shot_release(types.SimpleNamespace(x=px, y=py))
    app.root.update_idletasks()

app = TargetSheetApp()
app.root.update_idletasks()
"""


@pytest.fixture
def run_phase():
    r"""Run a block of test code against a freshly started app, in its own
    interpreter.

    Tk cannot reliably create more than a couple of roots per process on some
    Python builds, so anything that needs a *real* startup — restoring saved
    state, recovering from a corrupt file — runs as a subprocess.  `app`,
    `storage` and `click` are in scope inside the block, and the data
    directory is whatever `data_root` you pass.
    """
    import subprocess
    import textwrap

    def _run(body: str, data_root):
        code = _PHASE_PRELUDE + textwrap.dedent(body) + "\nprint('PHASE OK')\n"
        env = dict(os.environ,
                   APPDATA=str(data_root), XDG_DATA_HOME=str(data_root))
        proc = subprocess.run([sys.executable, "-c", code],
                              capture_output=True, text=True, env=env,
                              timeout=120)
        if proc.returncode != 0 or "PHASE OK" not in proc.stdout:
            if "usable init.tcl" in proc.stderr or "TclError" in proc.stderr:
                pytest.skip("no usable Tk display in the subprocess")
            pytest.fail(f"phase failed (rc={proc.returncode})\n"
                        f"--- stdout ---\n{proc.stdout}\n"
                        f"--- stderr ---\n{proc.stderr}")
        return proc

    return _run


@pytest.fixture
def mkshot():
    """Build a shot dict scored against a given distance config."""
    from scoring import score_shot
    from targets import build_dist_config

    def _make(x, y, tp="sc", w=0.0, e=0.0, cl=None, dist="300y-nra"):
        rings, _ = build_dist_config(dist)
        r = score_shot(x, y, rings)
        return {"x": float(x), "y": float(y), "sc": r["sc"], "iv": r["iv"],
                "lb": r["lb"], "tp": tp, "w": w, "e": e, "cl": cl}
    return _make
