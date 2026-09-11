"""Every target face checked against its rule book.

The expected values below are transcribed independently of targets.py, straight
from the published tables, so a typo in either place shows up as a mismatch.

  NRA   - NRA UK Handbook 2026, Appendix V: Bisley Target Rifle targets,
          dimensions effective 1 January 2025.  Diameters in mm; "Hit" is a
          w x h rectangle.  The 500 yd Hit cell is printed once across the
          600/500 columns, which share the same Outer ring.
  ICFRA - ICFRA Technical Rules for TR Shooting, 2024 edition, Annex T/D.
          Diameters in mm; Hit is the rest of the target inside the frame
          (D1.2: 1.2 x 1.2 m at 300, 1.8 x 1.8 m from 400 m to 700 yds, and
          2.4 m wide x 1.8 m high at long range).
  DCRA  - DCRA Rulebook 2024, rule 3.01, Tables A and B.  Diameters in
          inches; Hit is the rest of the target less a 1-inch border.
"""
import pytest

from constants import R
from targets import (TARGET_CONFIGS, SECTIONS, build_dist_config, hit_area,
                     aim_radius, range_yards)

IN = 25.4

_NRA_LR = dict(aim=1120, rings=(351, 585, 1120, 1830, 2440), hit=(2997, 1778))
NRA_2025 = {
    "300y": dict(aim=560, rings=(78, 130, 260, 390, 560), hit=(900, 920)),
    "500y": dict(aim=990, rings=(150, 250, 660, 990, 1320), hit=(1778, 1524)),
    "600y": dict(aim=990, rings=(192, 320, 660, 990, 1320), hit=(1778, 1524)),
    "800y": _NRA_LR, "900y": _NRA_LR, "1000y": _NRA_LR,
}

_ICFRA_LR = dict(aim=1120, rings=(255, 510, 815, 1120, 1830), hit=(2400, 1800))
ICFRA_2024 = {
    "300y": dict(aim=560, rings=(65, 130, 260, 390, 560), hit=(1200, 1200)),
    "500y": dict(aim=915, rings=(130, 260, 600, 915, 1320), hit=(1800, 1800)),
    "600y": dict(aim=915, rings=(145, 290, 600, 915, 1320), hit=(1800, 1800)),
    # "600m* - * And 700 yds": 700 yards is shot on the 600 m face.
    "700y": dict(aim=1000, rings=(160, 320, 660, 1000, 1320), hit=(1800, 1800)),
    "800y": _ICFRA_LR, "900y": _ICFRA_LR, "1000y": _ICFRA_LR,
    "300m": dict(aim=600, rings=(70, 140, 280, 420, 600), hit=(1200, 1200)),
    "500m": dict(aim=1000, rings=(145, 290, 660, 1000, 1320), hit=(1800, 1800)),
    "600m": dict(aim=1000, rings=(160, 320, 660, 1000, 1320), hit=(1800, 1800)),
    "700m": _ICFRA_LR, "800m": _ICFRA_LR, "900m": _ICFRA_LR,
}


def _dcra(aim, rings, frame_ft):
    w, h = frame_ft
    return dict(aim=aim * IN, rings=tuple(r * IN for r in rings),
                hit=((w * 12 - 2) * IN, (h * 12 - 2) * IN))


_DCRA_LR = _dcra(48, (12, 24, 48, 72, 96), (8, 6))       # 8 wide x 6 high
DCRA_2024 = {
    "300y": _dcra(22, (2.75, 5.5, 11, 16.5, 22), (4, 4)),
    "500y": _dcra(39, (5.25, 10.5, 26, 39, 52), (6, 6)),
    "600y": _dcra(39, (6.5, 13, 26, 39, 52), (6, 6)),
    "800y": _DCRA_LR, "900y": _DCRA_LR, "1000y": _DCRA_LR,   # long range: 800 yd+
    "300m": _dcra(22, (3.125, 6.25, 11.25, 16.5, 22), (4, 4)),
    "500m": _dcra(39, (5.875, 11.75, 26, 39, 52), (6, 6)),
    "600m": _dcra(39, (7.25, 14.5, 26, 39, 52), (6, 6)),
    "700m": _DCRA_LR, "800m": _DCRA_LR, "900m": _DCRA_LR,     # long range: 700-900 m
}

RULEBOOKS = {"nra": NRA_2025, "icfra": ICFRA_2024, "dcra": DCRA_2024}
ALL_FACES = [(std, dist, spec) for std, table in RULEBOOKS.items()
             for dist, spec in table.items()]


# -- which faces exist --------------------------------------------------------

def test_the_app_offers_exactly_the_rulebook_faces():
    expected = {f"{dist}-{std}" for std, dist, _ in ALL_FACES}
    assert set(TARGET_CONFIGS) == expected


def test_no_700_yard_face_where_the_rules_define_none():
    assert "700y-nra" not in TARGET_CONFIGS
    assert "700y-dcra" not in TARGET_CONFIGS


def test_icfra_keeps_its_700_yard_face():
    assert "700y-icfra" in TARGET_CONFIGS


def test_no_1000_metre_face():
    assert not [k for k in TARGET_CONFIGS if k.startswith("1000m")]


def test_every_face_appears_in_exactly_one_menu_section():
    listed = [k for _, keys in SECTIONS for k in keys]
    assert sorted(listed) == sorted(TARGET_CONFIGS)
    assert len(listed) == len(set(listed))


# -- dimensions ---------------------------------------------------------------

@pytest.mark.parametrize("std,dist,spec", ALL_FACES,
                         ids=[f"{d}-{s}" for s, d, _ in ALL_FACES])
def test_ring_diameters_match_the_rulebook(std, dist, spec):
    cfg = TARGET_CONFIGS[f"{dist}-{std}"]
    assert cfg["rings_mm"] == pytest.approx(spec["rings"], abs=0.05)


@pytest.mark.parametrize("std,dist,spec", ALL_FACES,
                         ids=[f"{d}-{s}" for s, d, _ in ALL_FACES])
def test_aiming_mark_matches_the_rulebook(std, dist, spec):
    assert TARGET_CONFIGS[f"{dist}-{std}"]["aim_mm"] == pytest.approx(spec["aim"], abs=0.05)


@pytest.mark.parametrize("std,dist,spec", ALL_FACES,
                         ids=[f"{d}-{s}" for s, d, _ in ALL_FACES])
def test_hit_area_matches_the_rulebook(std, dist, spec):
    assert TARGET_CONFIGS[f"{dist}-{std}"]["hit_mm"] == pytest.approx(spec["hit"], abs=0.05)


@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_aiming_mark_edge_is_a_scoring_ring(key):
    """ICFRA D2: no scoring zone may be partly in the black and partly in the
    white, so the edge of the black must coincide with a ring."""
    cfg = TARGET_CONFIGS[key]
    assert any(abs(cfg["aim_mm"] - d) < 0.05 for d in cfg["rings_mm"])


@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_the_black_is_always_on_the_target(key):
    cfg = TARGET_CONFIGS[key]
    assert min(cfg["hit_mm"]) >= cfg["aim_mm"]


# -- the drawing scale --------------------------------------------------------

@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_outer_ring_is_drawn_at_the_canvas_radius(key):
    rings, _ = build_dist_config(key)
    assert rings[-1]["r"] == pytest.approx(R)


@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_rings_keep_their_rulebook_proportions(key):
    rings, _ = build_dist_config(key)
    mm = TARGET_CONFIGS[key]["rings_mm"]
    for ring, d in zip(rings, mm):
        assert ring["r"] / R == pytest.approx(d / mm[-1])


@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_hit_area_and_aiming_mark_share_the_ring_scale(key):
    mm = TARGET_CONFIGS[key]
    half_w, half_h = hit_area(key)
    assert half_w == pytest.approx(R * mm["hit_mm"][0] / mm["rings_mm"][-1])
    assert half_h == pytest.approx(R * mm["hit_mm"][1] / mm["rings_mm"][-1])
    assert aim_radius(key) == pytest.approx(R * mm["aim_mm"] / mm["rings_mm"][-1])


# The NRA handbook prints each ring's apparent size in minutes of angle next to
# its diameter - an independent check that the grid is scaled correctly.
NRA_PRINTED_MOA = [
    ("300y-nra", 4, 7.02), ("300y-nra", 0, 0.98), ("300y-nra", 1, 1.63),
    ("500y-nra", 4, 9.92), ("500y-nra", 0, 1.13),
    ("600y-nra", 4, 8.27), ("600y-nra", 0, 1.20), ("600y-nra", 1, 2.01),
    ("1000y-nra", 4, 9.17), ("1000y-nra", 0, 1.32), ("1000y-nra", 1, 2.20),
]


@pytest.mark.parametrize("key,ring,printed", NRA_PRINTED_MOA)
def test_grid_scale_reproduces_the_nra_handbook_moa_figures(key, ring, printed):
    rings, mu = build_dist_config(key)
    assert 2 * rings[ring]["r"] / mu == pytest.approx(printed, abs=0.011)


def test_metric_distances_are_converted_to_yards_exactly():
    assert range_yards("300m-icfra") == pytest.approx(300 / 0.9144)


@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_every_hit_area_is_reachable_by_zooming_out(key):
    """Zoom goes down to 0.5, which shows +/- 2*VB around the centre."""
    from constants import VB
    assert max(hit_area(key)) <= 2 * VB
