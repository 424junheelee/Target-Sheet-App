"""
Target configurations for all supported Bisley fullbore distances.

Ring sizes come from:
  - NRA (UK) TR Figure 11 / Figure 12
  - ICFRA TR Technical Rules (2019)
  - NRAA targets & scoring document (Cessnock RC)
"""
from constants import R

# Ring metadata — score, V-flag, display label.  Radii are computed per target.
RING_DEFS: list[dict] = [
    {"sc": 5, "iv": True,  "lb": "V"},
    {"sc": 5, "iv": False, "lb": "5"},
    {"sc": 4, "iv": False, "lb": "4"},
    {"sc": 3, "iv": False, "lb": "3"},
    {"sc": 2, "iv": False, "lb": "2"},
]

# ── ICFRA TR target faces (ring radii in inches, V → outer) ──────────────────
# Short range (~300 m):   diameters mm V=70  5=140  4=280  3=420  2=600
# Mid range  (~500–600 m): diam mm V=160 5=320  4=660  3=1000 2=1320
# Long range (~700 m+):   diam mm V=255 5=510  4=815  3=1120 2=1830
_SR = [1.378,  2.756,  5.512,  8.268, 11.811]
_MR = [3.150,  6.299, 12.992, 19.685, 25.984]
_LR = [5.020, 10.039, 16.043, 22.047, 36.024]

BISLEY_DISTANCES     = ("300y", "500y", "600y", "700y", "800y", "900y", "1000y")
DCRA_METRIC_DISTANCES = ("300m", "500m", "600m", "700m", "800m", "900m", "1000m")

# ── Target configuration table ────────────────────────────────────────────────
# Key format: "<dist>-<standard>"  e.g. "600y-nra", "700m-dcra"
# Each entry contains:
#   rings_r_in : list[float]  — physical ring radii in inches (V → outer)
#   yards      : int          — firing distance in yards  (exclusive with metres)
#   metres     : int          — firing distance in metres (exclusive with yards)
#   dist       : str          — base distance label
#   standard   : str          — "NRA" or "DCRA"
#   label      : str          — human-readable display label
TARGET_CONFIGS: dict[str, dict] = {}

# NRA / Bisley yard targets
# 300y: NRA Figure 11 short-range (44" outer diameter)
# 500-1000y: NRA TR Figure 12 — same 72" outer face at all distances
for _dist, _yards, _r in [
    ("300y",  300,  [1.0,  3.0,  6.0,  12.0,  22.0]),
    ("500y",  500,  [2.5,  7.5,  15.0, 24.0,  36.0]),
    ("600y",  600,  [2.5,  7.5,  15.0, 24.0,  36.0]),
    ("700y",  700,  [2.5,  7.5,  15.0, 24.0,  36.0]),
    ("800y",  800,  [2.5,  7.5,  15.0, 24.0,  36.0]),
    ("900y",  900,  [2.5,  7.5,  15.0, 24.0,  36.0]),
    ("1000y", 1000, [2.5,  7.5,  15.0, 24.0,  36.0]),
]:
    TARGET_CONFIGS[f"{_dist}-nra"] = {
        "yards": _yards, "rings_r_in": _r,
        "dist": _dist, "standard": "NRA",
        "label": f"{_dist}  —  NRA / Bisley",
    }

# DCRA yard targets — ICFRA faces applied to Bisley yard distances
# 300y → short-range face; 500–600y → mid-range; 700–1000y → long-range
for _dist, _yards, _r in [
    ("300y",  300,  _SR),
    ("500y",  500,  _MR),
    ("600y",  600,  _MR),
    ("700y",  700,  _LR),
    ("800y",  800,  _LR),
    ("900y",  900,  _LR),
    ("1000y", 1000, _LR),
]:
    TARGET_CONFIGS[f"{_dist}-dcra"] = {
        "yards": _yards, "rings_r_in": _r,
        "dist": _dist, "standard": "DCRA",
        "label": f"{_dist}  —  DCRA (ICFRA)",
    }

# DCRA metric targets — ICFRA faces at DCRA domestic (Connaught) distances
# 300m → short-range; 500–600m → mid-range; 700–1000m → long-range
for _dist, _metres, _r in [
    ("300m",  300,  _SR),
    ("500m",  500,  _MR),
    ("600m",  600,  _MR),
    ("700m",  700,  _LR),
    ("800m",  800,  _LR),
    ("900m",  900,  _LR),
    ("1000m", 1000, _LR),
]:
    TARGET_CONFIGS[f"{_dist}-dcra"] = {
        "metres": _metres, "rings_r_in": _r,
        "dist": _dist, "standard": "DCRA",
        "label": f"{_dist}  —  DCRA (ICFRA metric)",
    }


def build_dist_config(dist_key: str) -> tuple[list[dict], float]:
    """
    Return (rings_list, mu) for the given distance key.

    rings_list — ring dicts with SVG radius 'r' added
    mu         — SVG units per MOA at this distance

    1 MOA at d yards  = d * 0.01047 inches
    1 MOA at d metres = d * 1.09361 yards * 0.01047 in  (= d * 0.01145 in)
    """
    cfg      = TARGET_CONFIGS[dist_key]
    radii_in = cfg["rings_r_in"]
    outer_r  = radii_in[-1]
    yards    = cfg["metres"] * 1.09361 if "metres" in cfg else cfg["yards"]
    mu       = R / (outer_r / (yards * 0.01047))
    rings    = [dict(d, r=R * ri / outer_r) for d, ri in zip(RING_DEFS, radii_in)]
    return rings, mu
