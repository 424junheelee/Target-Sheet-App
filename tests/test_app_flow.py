"""End-to-end flows driven through the same entry points the UI uses."""
import types

import pytest

import storage


def click(app, svg_x, svg_y):
    """Fire a shot at SVG coordinates by driving the canvas release handler."""
    px, py = app._to_canvas(svg_x, svg_y)
    app._on_shot_release(types.SimpleNamespace(x=px, y=py))
    app.root.update_idletasks()


# -- placing shots ------------------------------------------------------------

def test_first_two_shots_are_sighters_then_scorers(app):
    app.show_screen("target")
    click(app, 0, 0)
    click(app, 5, 5)
    click(app, 10, 10)
    assert [s["tp"] for s in app.shots] == ["A", "B", "sc"]


def test_shot_records_the_dialled_wind_and_elevation(app):
    app.show_screen("target")
    app.wind_val, app.elev_val = 2.5, -1.5
    click(app, 0, 0)
    assert (app.shots[0]["w"], app.shots[0]["e"]) == (2.5, -1.5)


def test_shot_is_scored_against_the_active_face(app):
    app.show_screen("target")
    click(app, 0, 0)
    assert app.shots[0]["lb"] == "V" and app.shots[0]["sc"] == 5


def test_shots_are_refused_once_the_string_is_complete(app):
    app.show_screen("target")
    app.shoot_len = 10
    for _ in range(12):
        click(app, 0, 0)
    assert app._get_phase()["tp"] == "done"
    click(app, 0, 0)
    assert len(app.shots) == 12


def test_placing_a_scored_shot_locks_in_the_conversion_choice(app):
    app.show_screen("target")
    click(app, 0, 0)
    click(app, 0, 0)
    assert app.conv_chosen is False
    click(app, 0, 0)
    assert app.conv_chosen is True


# -- undo ---------------------------------------------------------------------

def test_undo_removes_the_last_shot(app):
    app.show_screen("target")
    click(app, 0, 0)
    click(app, 5, 5)
    app.undo_shot()
    assert len(app.shots) == 1


def test_undo_on_an_empty_string_is_a_no_op(app):
    app.show_screen("target")
    app.undo_shot()
    assert app.shots == []


def test_undoing_below_two_shots_reopens_the_conversion_choice(app):
    app.show_screen("target")
    click(app, 0, 0)
    click(app, 0, 0)
    app.set_conv("ab")
    assert app.conv_chosen is True
    app.undo_shot()
    assert app.conv_chosen is False and app.conv == "none"


# -- shot calls ---------------------------------------------------------------

def test_call_is_attached_to_the_latest_shot(app):
    app.show_screen("target")
    click(app, 0, 0)
    app.set_call("good")
    assert app.shots[-1]["cl"] == "good"


def test_setting_the_same_call_twice_clears_it(app):
    app.show_screen("target")
    click(app, 0, 0)
    app.set_call("bad")
    app.set_call("bad")
    assert app.shots[-1]["cl"] is None


def test_call_without_shots_is_a_no_op(app):
    app.show_screen("target")
    app.set_call("good")
    assert app.shots == []


# -- committing a string ------------------------------------------------------

def test_commit_moves_the_string_to_the_scorecard_and_clears_the_board(app):
    app.show_screen("target")
    for _ in range(3):
        click(app, 0, 0)
    app.commit_string()
    assert len(app.strings) == 1
    assert app.shots == []
    assert app.conv == "none" and app.conv_chosen is False


def test_commit_records_the_context_needed_to_replay_the_string(app):
    app.show_screen("target")
    app.target_number = "17"
    app._select_distance("900m-dcra")
    click(app, 0, 0)
    app.commit_string()
    saved = app.strings[0]
    assert saved["dist"] == "900m-dcra"
    assert saved["mu"] == pytest.approx(app.active_mu)
    assert saved["target_number"] == "17"
    assert saved["shoot_len"] == app.shoot_len
    assert saved["saved_at"]


def test_commit_with_no_shots_does_nothing(app):
    app.show_screen("target")
    app.commit_string()
    assert app.strings == []


def test_commit_retargets_a_live_analysis_selection(app):
    app.show_screen("target")
    click(app, 0, 0)
    app.analysis_idx = "current"
    app.commit_string()
    assert app.analysis_idx == 0


# -- discard / delete ---------------------------------------------------------

def test_discard_clears_the_in_progress_string(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.show_screen("target")
    click(app, 0, 0)
    app._discard_current()
    assert app.shots == []


def test_discard_can_be_cancelled(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: False)
    app.show_screen("target")
    click(app, 0, 0)
    app._discard_current()
    assert len(app.shots) == 1


def test_delete_removes_the_chosen_series(app, mkshot, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.strings = [
        {"shots": [mkshot(0, 0, "sc")], "cv": "none", "dist": "300y-nra",
         "mu": 21.4, "shoot_len": 10},
        {"shots": [mkshot(5, 5, "sc")], "cv": "none", "dist": "600y-nra",
         "mu": 12.5, "shoot_len": 10},
    ]
    app.show_screen("scorecard")
    app._delete_series(0)
    assert len(app.strings) == 1
    assert app.strings[0]["dist"] == "600y-nra"


def test_delete_shifts_the_analysis_selection_down(app, mkshot, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.strings = [{"shots": [mkshot(0, 0, "sc")], "cv": "none",
                    "dist": "300y-nra", "mu": 21.4, "shoot_len": 10}
                   for _ in range(3)]
    app.analysis_idx = 2
    app.show_screen("scorecard")
    app._delete_series(0)
    assert app.analysis_idx == 1


def test_deleting_the_analysed_series_clears_the_selection(app, mkshot, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.strings = [{"shots": [mkshot(0, 0, "sc")], "cv": "none",
                    "dist": "300y-nra", "mu": 21.4, "shoot_len": 10}]
    app.analysis_idx = 0
    app.show_screen("scorecard")
    app._delete_series(0)
    assert app.analysis_idx is None


def test_delete_out_of_range_is_a_no_op(app):
    app.strings = []
    app._delete_series(5)
    assert app.strings == []


# -- dial controls ------------------------------------------------------------

def test_wind_steps_by_a_quarter_moa(app):
    app.show_screen("target")
    app.adj_wind(1)
    assert app.wind_val == 0.25
    assert app._wind_var.get() == "0.25R"


def test_elevation_steps_down(app):
    app.show_screen("target")
    app.adj_elev(-1)
    assert app.elev_val == -0.25
    assert app._elev_var.get() == "-0.25"


def test_dials_are_clamped_at_the_limit(app):
    from constants import MAXV
    app.show_screen("target")
    app.wind_val = MAXV
    app.adj_wind(1)
    assert app.wind_val == MAXV


# -- views render without error in every state --------------------------------

@pytest.mark.parametrize("screen", ["menu", "dist_select", "target",
                                    "scorecard", "analysis", "options",
                                    "presets"])
def test_every_screen_renders_when_empty(app, screen):
    app.show_screen(screen)
    app.root.update_idletasks()
    assert app.current_screen == screen


def test_scorecard_renders_saved_and_in_progress_together(app, mkshot):
    app.strings = [{"shots": [mkshot(0, 0, "sc")], "cv": "none",
                    "dist": "300y-nra", "mu": 21.4, "shoot_len": 10}]
    app.shots = [mkshot(5, 5, "A")]
    app.show_screen("scorecard")
    app.root.update_idletasks()


def test_analysis_renders_a_saved_series(app, mkshot):
    app.strings = [{"shots": [mkshot(0, 0, "A"),
                              mkshot(3, 3, "sc", cl="good")],
                    "cv": "b", "dist": "900m-dcra",
                    "mu": 47.0, "shoot_len": 15}]
    app.set_analysis(0)
    app.root.update_idletasks()
    assert app.current_screen == "analysis"


def test_analysis_of_the_live_string(app):
    app.show_screen("target")
    click(app, 0, 0)
    click(app, 4, -4)
    app.set_analysis("current")
    app.root.update_idletasks()


def test_analysis_recovers_from_a_stale_index(app):
    app.strings = []
    app.analysis_idx = 7
    app.show_screen("analysis")
    assert app.analysis_idx is None


def test_analysis_handles_a_string_with_a_single_shot(app, mkshot):
    """Extreme spread needs two shots - one must not raise."""
    app.strings = [{"shots": [mkshot(0, 0, "sc")], "cv": "none",
                    "dist": "300y-nra", "mu": 21.4, "shoot_len": 10}]
    app.set_analysis(0)
    app.root.update_idletasks()


def test_analysis_handles_an_all_miss_string(app, mkshot):
    from constants import R
    app.strings = [{"shots": [mkshot(R + 20, 0, "sc"),
                              mkshot(0, R + 20, "sc")],
                    "cv": "none", "dist": "300y-nra", "mu": 21.4,
                    "shoot_len": 10}]
    app.set_analysis(0)
    app.root.update_idletasks()


def test_graphs_draw_for_empty_partial_and_full_strings(app, mkshot):
    app.show_screen("target")
    for n in (0, 1, 5, 12):
        app.shots = [mkshot(i, -i, "sc") for i in range(n)]
        app._draw_ballistic_graphs()
        app.root.update_idletasks()


def test_graphs_hidden_when_the_option_is_off(app):
    app.show_screen("target")
    app.show_graphs = False
    app._draw_ballistic_graphs()
    assert not app._elev_graph.winfo_ismapped()


# -- zoom / pan ---------------------------------------------------------------

def test_zoom_in_and_out_stays_within_bounds(app):
    app.show_screen("target")
    for _ in range(40):
        app._on_zoom(types.SimpleNamespace(x=100, y=100, delta=120))
    assert app._zoom <= 8.0
    for _ in range(80):
        app._on_zoom(types.SimpleNamespace(x=100, y=100, delta=-120))
    assert app._zoom >= 0.5


def test_reset_view_restores_the_default_framing(app):
    app.show_screen("target")
    app._zoom, app._pan = 4.0, [50.0, -30.0]
    app._reset_view()
    assert app._zoom == 1.0 and app._pan == [0.0, 0.0]


def test_canvas_and_svg_coordinates_round_trip(app):
    app.show_screen("target")
    app._zoom, app._pan = 2.5, [17.0, -9.0]
    x, y = app._to_svg(*app._to_canvas(12.5, -7.25))
    assert (x, y) == (pytest.approx(12.5), pytest.approx(-7.25))


# -- persistence across a restart ---------------------------------------------

def test_a_full_session_survives_a_restart(run_phase, tmp_path):
    """Commit a string, leave another in progress, change options and presets,
    then restart the app and confirm the whole picture came back.

    Each phase runs in its own interpreter, so this is a genuine restart rather
    than a second Tk root inside one process.
    """
    run_phase("""
        app.show_screen("target")
        click(app, 0, 0)
        click(app, 3, 3)
        app.commit_string()
        assert storage.load_session() is None, "commit must clear the session"

        app.show_screen("options")
        app._show_rec_var.set(False)
        app._toggle_show_rec()
        app._set_shoot_len(15)
        app.presets["600y-nra"]["aperture"] = "4.25"
        app._save_presets()

        app.show_screen("target")
        app._select_distance("800m-dcra")
        app.wind_val, app.elev_val = 2.5, -1.5
        click(app, 4, -4)
        app.target_number = "17"
        app._save_session()
    """, tmp_path)

    run_phase("""
        assert len(app.strings) == 1, app.strings
        assert len(app.strings[0]["shots"]) == 2
        assert app.show_rec is False
        assert app.shoot_len == 15
        assert app.presets["600y-nra"]["aperture"] == "4.25"
        assert len(app.shots) == 1
        assert app.active_dist == "800m-dcra"
        assert app.wind_val == 2.5
        assert app.elev_val == -1.5
        assert app.target_number == "17"
    """, tmp_path)


def test_a_corrupt_session_file_does_not_stop_a_real_startup(run_phase, tmp_path):
    d = tmp_path / "TargetSheet"
    d.mkdir(parents=True, exist_ok=True)
    (d / "session.json").write_text("{{{ broken", encoding="utf-8")
    run_phase("""
        assert app.shots == []
        app.show_screen("target")
    """, tmp_path)


def test_corrupt_data_files_do_not_stop_startup(app, data_dir):
    """Startup restore must survive unreadable data rather than crashing.

    This drives `_load_persisted_state` directly — the same call the
    constructor makes — because Tk cannot supply another root here.
    """
    data_dir.mkdir(parents=True, exist_ok=True)
    for name in ("session.json", "scorecards.json",
                 "settings.json", "presets.json"):
        (data_dir / name).write_text("{{{ broken", encoding="utf-8")

    app._load_persisted_state()

    assert app.shots == []
    assert app.strings == []
    assert app.shoot_len == 10
    assert app.active_dist in ("300y-nra", app.active_dist)
    assert app.presets["300y-nra"] == {"aperture": "", "elevation": ""}


def test_startup_ignores_a_distance_that_no_longer_exists(app, data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "settings.json").write_text(
        '{"show_rec": true, "show_graphs": true, "shoot_len": 10,'
        ' "active_dist": "450y-nra"}', encoding="utf-8")
    app._load_persisted_state()
    assert app.active_dist == "300y-nra"
