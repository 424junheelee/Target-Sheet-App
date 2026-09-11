"""Analysis-view layout: the target face sizes itself to the window."""
import pytest

from views.analysis import FACE_MIN, FACE_MAX, fit_face_size


def test_face_grows_when_the_window_has_room():
    assert fit_face_size(1400, 640) == 640


def test_face_never_shrinks_below_its_original_fixed_size():
    """A small window must be no worse off than before the face was made
    responsive — it used to be pinned at FACE_MIN."""
    assert fit_face_size(300, 200) == FACE_MIN
    assert fit_face_size(FACE_MIN - 1, FACE_MIN - 1) == FACE_MIN


def test_face_is_capped_so_the_statistics_stay_reachable():
    assert fit_face_size(4000, 4000) == FACE_MAX


def test_the_tighter_dimension_wins():
    assert fit_face_size(600, 4000) == 600
    assert fit_face_size(4000, 600) == 600


def test_result_is_always_a_whole_number_of_pixels():
    assert isinstance(fit_face_size(733.7, 802.2), int)


@pytest.mark.parametrize("w,h", [(0, 0), (-50, 900), (1e6, 1e6)])
def test_degenerate_room_still_yields_a_usable_size(w, h):
    assert FACE_MIN <= fit_face_size(w, h) <= FACE_MAX


def test_growth_is_monotonic_in_available_room():
    sizes = [fit_face_size(r, r) for r in range(200, 1200, 50)]
    assert sizes == sorted(sizes)


def test_analysis_still_renders_after_a_window_resize(app, mkshot):
    app.strings = [{"shots": [mkshot(i, -i, "sc") for i in range(6)],
                    "cv": "none", "dist": "600y-nra", "mu": 12.5,
                    "shoot_len": 10}]
    app.set_analysis(0)
    app.root.update_idletasks()
    app.root.geometry("1400x900")
    app.root.update_idletasks()
    app._render_analysis()
    app.root.update_idletasks()
    assert app.current_screen == "analysis"
