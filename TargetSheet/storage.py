"""
Local persistence for TargetSheet.

All application data is stored as JSON in a platform-appropriate user directory:
  Windows  : %APPDATA%\\TargetSheet\\
  macOS    : ~/Library/Application Support/TargetSheet/
  Linux    : $XDG_DATA_HOME/TargetSheet/  (falls back to ~/.local/share/TargetSheet/)

Files
-----
scorecards.json  — list of committed string dicts
session.json     — in-progress session, or null when none is active
settings.json    — user options and last active distance
presets.json     — per-distance-config aperture / elevation presets

Writes are atomic: data is written to a .tmp sibling then renamed over the
target so a crash mid-write never leaves a half-written file.
"""

import json
import os
import pathlib
import sys

APP_NAME = "TargetSheet"

# ── Required keys for validation on load ─────────────────────────────────────

_SHOT_REQUIRED  = {"x", "y", "sc", "iv", "lb", "tp", "w", "e"}
_STRING_REQUIRED = {"shots", "cv", "dist", "mu"}
_SESSION_REQUIRED = {"shots", "conv", "conv_chosen", "active_dist",
                     "wind_val", "elev_val"}


# ── Internal helpers ──────────────────────────────────────────────────────────

def _data_dir() -> pathlib.Path:
    """Return (and create if necessary) the platform data directory."""
    if sys.platform == "win32":
        base = pathlib.Path(os.environ.get("APPDATA", "~")).expanduser()
    elif sys.platform == "darwin":
        base = pathlib.Path("~/Library/Application Support").expanduser()
    else:
        xdg = os.environ.get("XDG_DATA_HOME", "")
        base = pathlib.Path(xdg) if xdg else pathlib.Path("~/.local/share").expanduser()
    d = base / APP_NAME
    d.mkdir(parents=True, exist_ok=True)
    return d


def _load(filename: str, default):
    """Read and parse a JSON file; return *default* on any error or if absent."""
    try:
        path = _data_dir() / filename
    except Exception:
        return default
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"[TargetSheet] Warning: could not load {filename}: {exc}",
              file=sys.stderr)
        return default


def _save(filename: str, data) -> None:
    """Write *data* as JSON to *filename* atomically (tmp-then-rename).

    Raises IOError if the write fails so callers can show a toast.
    """
    try:
        d = _data_dir()
        target = d / filename
        tmp    = d / (filename + ".tmp")
        tmp.write_text(json.dumps(data, indent=2), encoding="utf-8")
        os.replace(tmp, target)
    except Exception as exc:
        raise IOError(f"Could not save {filename}: {exc}") from exc


# ── Shot / string validation ──────────────────────────────────────────────────

def _valid_shot(s) -> bool:
    return isinstance(s, dict) and _SHOT_REQUIRED.issubset(s)


def _valid_string(sd) -> bool:
    return (isinstance(sd, dict)
            and _STRING_REQUIRED.issubset(sd)
            and isinstance(sd["shots"], list)
            and all(_valid_shot(s) for s in sd["shots"]))


# ── Public API ────────────────────────────────────────────────────────────────

def load_scorecards() -> list:
    """Return the list of saved string dicts, or [] on error / first launch."""
    raw = _load("scorecards.json", [])
    if not isinstance(raw, list):
        return []
    result = []
    for sd in raw:
        if not _valid_string(sd):
            continue
        # Back-compat: older saves may lack 'cl' on shots
        for shot in sd["shots"]:
            shot.setdefault("cl", None)
        sd.setdefault("shoot_len",     10)
        sd.setdefault("target_number", "")
        sd.setdefault("saved_at",      "")
        result.append(sd)
    return result


def save_scorecards(strings: list) -> None:
    """Persist the full list of saved strings.  Raises IOError on failure."""
    _save("scorecards.json", strings)


def load_session() -> dict | None:
    """Return the in-progress session dict, or None if absent / invalid."""
    raw = _load("session.json", None)
    if raw is None:
        return None
    if not isinstance(raw, dict) or not _SESSION_REQUIRED.issubset(raw):
        return None
    if not isinstance(raw.get("shots"), list):
        return None
    for shot in raw["shots"]:
        shot.setdefault("cl", None)
    raw.setdefault("target_number", "")
    return raw


def save_session(state: dict | None) -> None:
    """Persist (or clear) the in-progress session.  Raises IOError on failure."""
    _save("session.json", state)


def load_settings() -> dict:
    """Return persisted settings, falling back to safe defaults for any missing key."""
    defaults: dict = {
        "show_rec":    True,
        "show_graphs": True,
        "shoot_len":   10,
        "active_dist": "300y-nra",
    }
    raw = _load("settings.json", {})
    if not isinstance(raw, dict):
        return defaults
    out = dict(defaults)
    if isinstance(raw.get("show_rec"),    bool): out["show_rec"]    = raw["show_rec"]
    if isinstance(raw.get("show_graphs"), bool): out["show_graphs"] = raw["show_graphs"]
    if raw.get("shoot_len") in (10, 15):         out["shoot_len"]   = raw["shoot_len"]
    if isinstance(raw.get("active_dist"), str):  out["active_dist"] = raw["active_dist"]
    return out


def save_settings(opts: dict) -> None:
    """Persist user options.  Raises IOError on failure."""
    _save("settings.json", opts)


def load_presets(all_keys: list) -> dict:
    """Return presets dict; fills in any missing config keys with empty strings."""
    default = {k: {"aperture": "", "elevation": ""} for k in all_keys}
    raw = _load("presets.json", {})
    if not isinstance(raw, dict):
        return default
    out = dict(default)
    for k in all_keys:
        if k in raw and isinstance(raw[k], dict):
            out[k] = {
                "aperture":  str(raw[k].get("aperture",  "")),
                "elevation": str(raw[k].get("elevation", "")),
            }
    return out


def save_presets(presets: dict) -> None:
    """Persist sight presets.  Raises IOError on failure."""
    _save("presets.json", presets)
