"""Pure scoring / formatting helpers and target geometry."""
import math

import pytest

from constants import R, MAXV
from scoring import score_shot, wind_label, elev_label, snap, clamp
from targets import TARGET_CONFIGS, RING_DEFS, build_dist_config


# ── score_shot ────────────────────────────────────────────────────────────────

def rings(dist="300y-nra"):
    return build_dist_config(dist)[0]


def test_dead_centre_is_v_bull():
    assert score_shot(0, 0, rings())["lb"] == "V"


def test_outside_outer_ring_is_a_miss():
    miss = score_shot(R + 1, 0, rings())
    assert miss == {"sc": 0, "iv": False, "lb": "M"}


def test_ring_boundary_is_inclusive_scores_the_higher_ring():
    """A shot exactly on a ring edge counts as the inner (higher) ring."""
    rs = rings()
    v_r = rs[0]["r"]
    assert score_shot(v_r, 0, rs)["lb"] == "V"
    assert score_shot(v_r + 1e-9, 0, rs)["lb"] == "5"


def test_scores_decrease_outward():
    rs = rings()
    seen = [score_shot(r["r"] - 1e-6, 0, rs)["sc"] for r in rs]
    assert seen == [5, 5, 4, 3, 2]


def test_v_flag_only_on_innermost_ring():
    rs = rings()
    assert score_shot(0, 0, rs)["iv"] is True
    assert score_shot(rs[1]["r"] - 1e-6, 0, rs)["iv"] is False


def test_scoring_is_radial_not_axis_aligned():
    rs = rings()
    r = rs[2]["r"] - 1e-6
    diag = r / math.sqrt(2)
    assert score_shot(diag, diag, rs)["sc"] == score_shot(r, 0, rs)["sc"]


# ── label formatting ──────────────────────────────────────────────────────────

@pytest.mark.parametrize("value,expected", [
    (0, "calm"), (0.0, "calm"),
    (2.5, "2.5R"), (-2.5, "2.5L"),
    (1.0, "1R"), (-1.0, "1L"),
    (0.25, "0.25R"), (-0.25, "0.25L"),
    (12.0, "12R"),
])
def test_wind_label(value, expected):
    assert wind_label(value) == expected


@pytest.mark.parametrize("value,expected", [
    (0, "0"), (0.0, "0"),
    (1.5, "+1.5"), (-1.5, "-1.5"),
    (2.0, "+2"), (-2.0, "-2"),
    (0.25, "+0.25"), (-0.25, "-0.25"),
])
def test_elev_label(value, expected):
    assert elev_label(value) == expected


# ── snap / clamp ──────────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw,expected", [
    (0.1, 0.0), (0.13, 0.25), (0.37, 0.25), (0.38, 0.5),
    (-0.13, -0.25), (1.0, 1.0), (2.6, 2.5),
])
def test_snap_to_quarter_moa(raw, expected):
    assert snap(raw) == expected


def test_snap_output_is_always_a_quarter_multiple():
    for i in range(-400, 401):
        v = snap(i * 0.037)
        assert abs(v * 4 - round(v * 4)) < 1e-9


def test_clamp_bounds():
    assert clamp(MAXV + 50) == MAXV
    assert clamp(-MAXV - 50) == -MAXV
    assert clamp(3.25) == 3.25


# ── target configuration table ────────────────────────────────────────────────

def test_all_21_configs_present():
    assert len(TARGET_CONFIGS) == 21


def test_every_config_builds():
    for key in TARGET_CONFIGS:
        ring_list, mu = build_dist_config(key)
        assert len(ring_list) == len(RING_DEFS)
        assert mu > 0


def test_radii_strictly_increase_outward_for_every_config():
    for key in TARGET_CONFIGS:
        radii = [r["r"] for r in build_dist_config(key)[0]]
        assert radii == sorted(radii), key
        assert len(set(radii)) == len(radii), key


def test_outer_ring_maps_to_canvas_radius_R():
    for key in TARGET_CONFIGS:
        assert build_dist_config(key)[0][-1]["r"] == pytest.approx(R)


def test_moa_scale_shrinks_with_distance():
    """1 MOA covers more of the face as distance grows on a fixed face size."""
    mu_300 = build_dist_config("300y-nra")[1]
    mu_1000 = build_dist_config("1000y-nra")[1]
    assert mu_1000 > mu_300


def test_metric_configs_convert_metres_to_yards():
    """300 m is a longer shot than 300 y, so 1 MOA covers more of the face."""
    assert (build_dist_config("300m-dcra")[1]
            > build_dist_config("300y-dcra")[1])


def test_unknown_distance_key_raises():
    with pytest.raises(KeyError):
        build_dist_config("450y-nra")
