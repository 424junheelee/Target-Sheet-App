import math
from constants import MAXV

CALL_GLYPHS: dict[str, str] = {
    "pull-high":  "↑",
    "pull-low":   "↓",
    "pull-left":  "←",
    "pull-right": "→",
    "good":       "✓",
    "bad":        "✕",
}
CALL_COLOURS: dict[str, str] = {
    "good": "#3B6D11",
    "bad":  "#A32D2D",
}


def score_shot(x: float, y: float, rings: list[dict]) -> dict:
    """Return the innermost ring dict that contains (x, y), or a miss dict."""
    d = math.hypot(x, y)
    for ring in rings:
        if d <= ring["r"]:
            return ring
    return {"sc": 0, "iv": False, "lb": "M"}


def wind_label(v: float) -> str:
    """Format a wind value: 2.5 → '2.5R', -1.25 → '1.25L', 0 → 'calm'."""
    if v == 0:
        return "calm"
    mag = abs(v)
    mag_str = str(int(mag)) if mag == int(mag) else str(mag)
    return f"{mag_str}{'L' if v < 0 else 'R'}"


def elev_label(v: float) -> str:
    """Format an elevation value: 1.5 → '+1.5', -0.25 → '-0.25', 0 → '0'."""
    if v == 0:
        return "0"
    mag_str = str(int(abs(v))) if abs(v) == int(abs(v)) else str(abs(v))
    return f"+{mag_str}" if v > 0 else f"-{mag_str}"


def snap(v: float) -> float:
    """Snap v to the nearest 0.25 increment."""
    return round(v * 4) / 4


def clamp(v: float, lo: float = -MAXV, hi: float = MAXV) -> float:
    """Clamp v to [lo, hi]."""
    return max(lo, min(hi, v))
