"""
Target faces for every supported standard and distance.

Each face is transcribed from the current rule book of its standard:

  NRA   - NRA UK Handbook 2026 ("the Bisley Bible"), Appendix V: Bisley Target
          Rifle targets.  Dimensions changed on 1 January 2025.
  ICFRA - ICFRA Technical Rules for TR Shooting, 2024 edition, Annex T/D.
  DCRA  - DCRA Rulebook 2024, rule 3.01, Table A (yards) and Table B (metres).

Every face records, in millimetres:

  rings_mm : DIAMETERS of the V-bull, Bull (5), Inner (4), Magpie (3), Outer (2)
  aim_mm   : DIAMETER of the black aiming mark
  hit_mm   : (width, height) of the 1-point "Hit" area.  A shot inside it but
             outside the Outer ring scores 1; a shot outside it is a miss, even
             where a ring's circle extends past it.

DCRA publishes inches; those are converted exactly here.
tests/test_target_specs.py checks every number against an independent
transcription of the same tables.
"""
import math

from constants import R

# Ring metadata - score, V-flag, display label.  Radii are computed per target.
RING_DEFS: list[dict] = [
    {"sc": 5, "iv": True,  "lb": "V"},
    {"sc": 5, "iv": False, "lb": "5"},
    {"sc": 4, "iv": False, "lb": "4"},
    {"sc": 3, "iv": False, "lb": "3"},
    {"sc": 2, "iv": False, "lb": "2"},
]

MM_PER_INCH     = 25.4
YARDS_PER_METRE = 1 / 0.9144          # exact: the yard is defined as 0.9144 m

# Bumped whenever face geometry changes, and stamped on every saved string, so
# strings plotted on an earlier face can be recognised and drawn on it.
FACE_REV = 2

STANDARD_NAMES = {"nra": "NRA UK", "icfra": "ICFRA", "dcra": "DCRA"}

# Key format: "<dist>-<standard>", e.g. "600y-nra", "700m-icfra", "900y-dcra".
TARGET_CONFIGS: dict[str, dict] = {}

# Menu order: (section title, [config keys]).  Used by the distance picker and
# the presets screen so the two always list the same faces.
SECTIONS: list[tuple[str, list[str]]] = []


def _face(std: str, dist: str, aim, rings, hit, source: str) -> str:
    unit = "metres" if dist.endswith("m") else "yards"
    key = f"{dist}-{std}"
    TARGET_CONFIGS[key] = {
        unit: int(dist[:-1]),
        "dist": dist, "standard": std,
        "label": f"{dist}  —  {STANDARD_NAMES[std]}",
        "rings_mm": tuple(float(d) for d in rings),
        "aim_mm": float(aim),
        "hit_mm": (float(hit[0]), float(hit[1])),
        "source": source,
    }
    return key


def _section(title: str, std: str, faces, source: str):
    SECTIONS.append((title, [_face(std, dist, *spec, source=source)
                             for dist, spec in faces]))


# -- NRA UK: Bisley Target Rifle targets (from 1 January 2025) ----------------
# (aim, (V, Bull, Inner, Magpie, Outer), (Hit width, Hit height)), all mm.
# Bisley has no TR target at 700 yd, so none is offered.

_NRA_LR = (1120, (351, 585, 1120, 1830, 2440), (2997, 1778))
_NRA = [
    ("300y", (560, (78, 130, 260, 390, 560), (900, 920))),
    # The Hit cell is printed once across the 600 and 500 yd columns, which
    # share the same 1320 mm Outer.
    ("500y", (990, (150, 250, 660, 990, 1320), (1778, 1524))),
    ("600y", (990, (192, 320, 660, 990, 1320), (1778, 1524))),
    ("800y", _NRA_LR), ("900y", _NRA_LR), ("1000y", _NRA_LR),
]

# -- ICFRA International Match Targets (TR Technical Rules 2024, Annex T/D) ---
# Hit is the rest of the target inside the frame (D1.2): 1.2 x 1.2 m at 300,
# 1.8 x 1.8 m from 400 m to 700 yds, and 2.4 m wide x 1.8 m high at long range.
# The long-range face covers "700m - 1000 yds"; 1000 m lies beyond it.

_ICFRA_LR = (1120, (255, 510, 815, 1120, 1830), (2400, 1800))
_ICFRA_YARDS = [
    ("300y", (560, (65, 130, 260, 390, 560), (1200, 1200))),
    ("500y", (915, (130, 260, 600, 915, 1320), (1800, 1800))),
    ("600y", (915, (145, 290, 600, 915, 1320), (1800, 1800))),
    ("700y", (1000, (160, 320, 660, 1000, 1320), (1800, 1800))),   # the 600 m face
    ("800y", _ICFRA_LR), ("900y", _ICFRA_LR), ("1000y", _ICFRA_LR),
]
_ICFRA_METRES = [
    ("300m", (600, (70, 140, 280, 420, 600), (1200, 1200))),
    ("500m", (1000, (145, 290, 660, 1000, 1320), (1800, 1800))),
    ("600m", (1000, (160, 320, 660, 1000, 1320), (1800, 1800))),
    ("700m", _ICFRA_LR), ("800m", _ICFRA_LR), ("900m", _ICFRA_LR),
]


# -- DCRA targets (Rulebook 2024, rule 3.01) ----------------------------------
# Published in inches.  Hit is the rest of the target "less a 1-inch border all
# around the edge"; target sizes are width x height in feet.  Table A has no
# 700 yd column (long range is 800 yd and more) and Table B's long range is
# 700 to 900 m, so neither 700 yd nor 1000 m is offered.

def _dcra(aim_in, rings_in, frame_ft):
    w_ft, h_ft = frame_ft
    return (aim_in * MM_PER_INCH,
            tuple(r * MM_PER_INCH for r in rings_in),
            ((w_ft * 12 - 2) * MM_PER_INCH, (h_ft * 12 - 2) * MM_PER_INCH))


_DCRA_LR = _dcra(48, (12, 24, 48, 72, 96), (8, 6))      # 8 ft wide x 6 ft high
_DCRA_YARDS = [
    ("300y", _dcra(22, (2.75, 5.5, 11, 16.5, 22), (4, 4))),
    ("500y", _dcra(39, (5.25, 10.5, 26, 39, 52), (6, 6))),
    ("600y", _dcra(39, (6.5, 13, 26, 39, 52), (6, 6))),
    ("800y", _DCRA_LR), ("900y", _DCRA_LR), ("1000y", _DCRA_LR),
]
_DCRA_METRES = [
    ("300m", _dcra(22, (3.125, 6.25, 11.25, 16.5, 22), (4, 4))),
    ("500m", _dcra(39, (5.875, 11.75, 26, 39, 52), (6, 6))),
    ("600m", _dcra(39, (7.25, 14.5, 26, 39, 52), (6, 6))),
    ("700m", _DCRA_LR), ("800m", _DCRA_LR), ("900m", _DCRA_LR),
]

_section("NRA UK  —  Bisley targets from 1 Jan 2025", "nra", _NRA,
         "NRA UK Handbook 2026, Appendix V")
_section("ICFRA  —  yards", "icfra", _ICFRA_YARDS,
         "ICFRA TR Technical Rules 2024, Annex T/D")
_section("ICFRA  —  metres", "icfra", _ICFRA_METRES,
         "ICFRA TR Technical Rules 2024, Annex T/D")
_section("DCRA  —  yards", "dcra", _DCRA_YARDS,
         "DCRA Rulebook 2024, rule 3.01 Table A")
_section("DCRA  —  metres", "dcra", _DCRA_METRES,
         "DCRA Rulebook 2024, rule 3.01 Table B")


# -- Faces from before the rule-book audit ------------------------------------
# These were the app's faces before FACE_REV 2.  Most matched no rule book, but
# a string is only meaningful on the face it was plotted on, so they are kept
# for drawing strings saved back then - never offered for new ones.

LEGACY_PREFIX = "legacy-"
LEGACY_CONFIGS: dict[str, dict] = {}


def _legacy(old_key: str, radii_in):
    dist = old_key.split("-")[0]
    unit = "metres" if dist.endswith("m") else "yards"
    LEGACY_CONFIGS[LEGACY_PREFIX + old_key] = {
        unit: int(dist[:-1]), "dist": dist,
        "standard": old_key.split("-")[1],
        "label": f"{dist}  —  old face",
        "rings_mm": tuple(2 * r * MM_PER_INCH for r in radii_in),
        "aim_mm": None, "hit_mm": None,
        "source": "TargetSheet faces before FACE_REV 2",
    }


_OLD_SR = (1.378, 2.756, 5.512, 8.268, 11.811)       # radii, inches
_OLD_MR = (3.150, 6.299, 12.992, 19.685, 25.984)
_OLD_LR = (5.020, 10.039, 16.043, 22.047, 36.024)
_legacy("300y-nra", (1.0, 3.0, 6.0, 12.0, 22.0))
for _d in ("500y", "600y", "700y", "800y", "900y", "1000y"):
    _legacy(f"{_d}-nra", (2.5, 7.5, 15.0, 24.0, 36.0))
for _d, _r in (("300y", _OLD_SR), ("500y", _OLD_MR), ("600y", _OLD_MR),
               ("700y", _OLD_LR), ("800y", _OLD_LR), ("900y", _OLD_LR),
               ("1000y", _OLD_LR), ("300m", _OLD_SR), ("500m", _OLD_MR),
               ("600m", _OLD_MR), ("700m", _OLD_LR), ("800m", _OLD_LR),
               ("900m", _OLD_LR), ("1000m", _OLD_LR)):
    _legacy(f"{_d}-dcra", _r)


# -- Lookups --------------------------------------------------------------------

def _config(dist_key: str) -> dict:
    """Config for a current or preserved face; KeyError for anything else."""
    if dist_key in TARGET_CONFIGS:
        return TARGET_CONFIGS[dist_key]
    return LEGACY_CONFIGS[dist_key]


def is_known(dist_key: str) -> bool:
    return dist_key in TARGET_CONFIGS or dist_key in LEGACY_CONFIGS


def migrate_legacy(dist_key: str) -> str:
    """Map a key saved before FACE_REV 2 to the face it was plotted on."""
    if dist_key in LEGACY_CONFIGS:
        return dist_key
    legacy = LEGACY_PREFIX + dist_key
    return legacy if legacy in LEGACY_CONFIGS else dist_key


def display_name(dist_key: str) -> str:
    """Name shown to the user - preserved faces are marked as old."""
    if dist_key in LEGACY_CONFIGS:
        return f"{dist_key[len(LEGACY_PREFIX):]} (old face)"
    return dist_key


def range_yards(dist_key: str) -> float:
    cfg = _config(dist_key)
    if "metres" in cfg:
        return cfg["metres"] * YARDS_PER_METRE
    return float(cfg["yards"])


def inches_per_moa(yards: float) -> float:
    """Size of one minute of angle, in inches, at *yards*."""
    return yards * 36 * math.tan(math.radians(1 / 60))


def build_dist_config(dist_key: str) -> tuple[list[dict], float]:
    """
    Return (rings_list, mu) for the given face.

    rings_list - ring dicts with SVG radius 'r' added; the Outer is always R
    mu         - SVG units per MOA at this face's distance
    """
    cfg = _config(dist_key)
    mm = cfg["rings_mm"]
    outer_radius_in = mm[-1] / 2 / MM_PER_INCH
    mu = R * inches_per_moa(range_yards(dist_key)) / outer_radius_in
    rings = [dict(d, r=R * dia / mm[-1]) for d, dia in zip(RING_DEFS, mm)]
    return rings, mu


def hit_area(dist_key: str) -> tuple[float, float] | None:
    """(half_width, half_height) of the 1-point Hit area in SVG units, or None
    for a preserved old face, which had no Hit zone."""
    cfg = _config(dist_key)
    if not cfg["hit_mm"]:
        return None
    outer = cfg["rings_mm"][-1]
    return R * cfg["hit_mm"][0] / outer, R * cfg["hit_mm"][1] / outer


def aim_radius(dist_key: str) -> float | None:
    """Radius of the black aiming mark in SVG units, or None."""
    cfg = _config(dist_key)
    if not cfg["aim_mm"]:
        return None
    return R * cfg["aim_mm"] / cfg["rings_mm"][-1]


def moa_diameters(dist_key: str) -> list[float]:
    """Each ring's diameter in minutes of angle, V-bull to Outer."""
    rings, mu = build_dist_config(dist_key)
    return [2 * ring["r"] / mu for ring in rings]
