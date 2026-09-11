"""Sighter conversion, phase progression, totals and the dial recommendation."""
import pytest


# ── shot numbering under each conversion ──────────────────────────────────────

def test_labels_no_conversion(app, mkshot):
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B"),
             mkshot(0, 0, "sc"), mkshot(0, 0, "sc")]
    assert app._compute_labels(shots, "none") == ["A", "B", "1", "2"]


def test_labels_convert_b_only(app, mkshot):
    """B becomes scoring shot 1, so the first real scorer becomes 2."""
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B"),
             mkshot(0, 0, "sc"), mkshot(0, 0, "sc")]
    assert app._compute_labels(shots, "b") == ["A", "1", "2", "3"]


def test_labels_convert_a_and_b(app, mkshot):
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B"),
             mkshot(0, 0, "sc"), mkshot(0, 0, "sc")]
    assert app._compute_labels(shots, "ab") == ["1", "2", "3", "4"]


def test_labels_handle_a_only_string(app, mkshot):
    assert app._compute_labels([mkshot(0, 0, "A")], "ab") == ["1"]


# ── phase progression ─────────────────────────────────────────────────────────

def test_phase_starts_at_sighter_a(app):
    app.shots = []
    assert app._get_phase()["tp"] == "A"


def test_phase_second_shot_is_sighter_b(app, mkshot):
    app.shots = [mkshot(0, 0, "A")]
    assert app._get_phase()["tp"] == "B"


def test_phase_third_shot_is_scored(app, mkshot):
    app.shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B")]
    ph = app._get_phase()
    assert ph["tp"] == "sc" and ph["lb"] == "Shot 1"


def test_phase_completes_after_ten_scored_shots(app, mkshot):
    app.shoot_len, app.conv = 10, "none"
    app.shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B")] + \
                [mkshot(0, 0, "sc") for _ in range(10)]
    assert app._get_phase()["tp"] == "done"


def test_converting_sighters_shortens_the_string(app, mkshot):
    """With A+B converted, only 8 more scored shots are needed for a 10-shot match."""
    app.shoot_len, app.conv = 10, "ab"
    app.shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B")] + \
                [mkshot(0, 0, "sc") for _ in range(8)]
    assert app._get_phase()["tp"] == "done"


def test_fifteen_shot_match_needs_fifteen_scorers(app, mkshot):
    app.shoot_len, app.conv = 15, "none"
    app.shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B")] + \
                [mkshot(0, 0, "sc") for _ in range(14)]
    assert app._get_phase()["tp"] == "sc"
    app.shots.append(mkshot(0, 0, "sc"))
    assert app._get_phase()["tp"] == "done"


# ── totals ────────────────────────────────────────────────────────────────────

def test_total_ignores_unconverted_sighters(app, mkshot):
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B"), mkshot(0, 0, "sc")]
    t = app._calc_total(shots, "none")
    assert (t["tot"], t["v"], t["n"]) == (5, 1, 1)


def test_total_counts_converted_b(app, mkshot):
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B"), mkshot(0, 0, "sc")]
    t = app._calc_total(shots, "b")
    assert (t["tot"], t["v"], t["n"]) == (10, 2, 2)


def test_total_counts_converted_a_and_b(app, mkshot):
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B"), mkshot(0, 0, "sc")]
    t = app._calc_total(shots, "ab")
    assert (t["tot"], t["v"], t["n"]) == (15, 3, 3)


def test_total_caps_at_the_match_length(app, mkshot):
    """Extra scored shots beyond the match length must not inflate the score."""
    app.shoot_len = 10
    shots = [mkshot(0, 0, "sc") for _ in range(14)]
    assert app._calc_total(shots, "none")["n"] == 10


def test_converted_sighters_displace_scored_shots_in_the_total(app, mkshot):
    app.shoot_len = 10
    shots = [mkshot(0, 0, "A"), mkshot(0, 0, "B")] + \
            [mkshot(0, 0, "sc") for _ in range(10)]
    assert app._calc_total(shots, "ab")["n"] == 10   # 2 sighters + 8 scorers


def test_total_uses_explicit_shoot_len_when_given(app, mkshot):
    app.shoot_len = 10
    shots = [mkshot(0, 0, "sc") for _ in range(15)]
    assert app._calc_total(shots, "none", 15)["n"] == 15


def test_misses_score_zero_but_still_count(app, mkshot):
    from constants import R
    shots = [mkshot(R + 10, 0, "sc"), mkshot(0, 0, "sc")]
    t = app._calc_total(shots, "none")
    assert (t["tot"], t["n"]) == (5, 2)


def test_empty_string_totals_zero(app):
    assert app._calc_total([], "none") == {"tot": 0, "v": 0, "n": 0}


# ── dial recommendation ───────────────────────────────────────────────────────

def test_no_recommendation_without_shots(app):
    app.shots = []
    assert app._compute_recommendation() is None


def test_shot_right_of_centre_recommends_less_right_wind(app, mkshot):
    app.shots = [mkshot(app.active_mu * 2, 0, "sc", w=0.0)]
    assert app._compute_recommendation()["w"] == pytest.approx(-2.0)


def test_shot_low_recommends_more_elevation(app, mkshot):
    """SVG +y is physically low on the target, so elevation must go up."""
    app.shots = [mkshot(0, app.active_mu * 2, "sc", e=0.0)]
    assert app._compute_recommendation()["e"] == pytest.approx(2.0)


def test_recommendation_is_relative_to_the_dialled_value(app, mkshot):
    app.wind_val = 3.0
    app.shots = [mkshot(app.active_mu * 1, 0, "sc", w=3.0)]
    assert app._compute_recommendation()["w"] == pytest.approx(2.0)


def test_recommendation_averages_the_group(app, mkshot):
    mu = app.active_mu
    app.shots = [mkshot(mu * 2, 0, "sc"), mkshot(mu * 4, 0, "sc")]
    r = app._compute_recommendation()
    assert r["w"] == pytest.approx(-3.0)
    assert r["n"] == 2


def test_recommendation_is_snapped_to_quarter_moa(app, mkshot):
    app.shots = [mkshot(app.active_mu * 1.31, 0, "sc")]
    w = app._compute_recommendation()["w"]
    assert abs(w * 4 - round(w * 4)) < 1e-9


def test_recommendation_is_clamped_to_the_dial_range(app, mkshot):
    from constants import MAXV
    app.wind_val = MAXV
    app.shots = [mkshot(-app.active_mu * 500, 0, "sc", w=MAXV)]
    assert app._compute_recommendation()["w"] == MAXV


def test_apply_rec_moves_the_dials(app, mkshot):
    app.shots = [mkshot(app.active_mu * 2, 0, "sc", w=0.0)]
    app.apply_rec()
    assert app.wind_val == pytest.approx(-2.0)
