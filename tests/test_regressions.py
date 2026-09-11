"""Regression tests for defects found while auditing the app."""
import types

import pytest

from scoring import score_shot
from targets import build_dist_config


def click(app, svg_x, svg_y):
    px, py = app._to_canvas(svg_x, svg_y)
    app._on_shot_release(types.SimpleNamespace(x=px, y=py))
    app.root.update_idletasks()


# -- the dial readout must always match the dialled value ---------------------
#
# The wind/elevation labels were initialised to "calm"/"0" at build time and
# only refreshed by the +/- buttons, so a session restored from disk showed
# calm while the app was really holding the saved wind on.  The shooter then
# adjusted from a value they could not see.

def test_restored_dials_are_shown_not_just_stored(app):
    app.wind_val, app.elev_val = 2.5, -1.5   # what a restore sets
    app.show_screen("target")
    assert app._wind_var.get() == "2.5R"
    assert app._elev_var.get() == "-1.5"


def test_dial_readout_tracks_state_on_every_render(app):
    app.show_screen("target")
    app.wind_val, app.elev_val = -3.25, 4.0
    app.render()
    assert app._wind_var.get() == "3.25L"
    assert app._elev_var.get() == "+4"


def test_stepping_a_restored_dial_continues_from_the_saved_value(app):
    app.wind_val = 2.5
    app.show_screen("target")
    app.adj_wind(1)
    assert app.wind_val == 2.75
    assert app._wind_var.get() == "2.75R"


# -- changing distance mid-string must not leave stale scores -----------------
#
# Shot coordinates are stored relative to the target face, so the same point is
# a different ring on a different face.  Switching distance redrew the rings
# but kept each shot's original score, leaving shots drawn inside the V-bull
# still labelled "5" and the string total wrong.

def test_distance_change_rescores_existing_shots(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.show_screen("target")
    click(app, 7.0, 0.0)
    assert app.shots[0]["lb"] == "5"          # a 5 on the 300y NRA face

    app._select_distance("1000y-dcra")

    rings = build_dist_config("1000y-dcra")[0]
    expected = score_shot(app.shots[0]["x"], app.shots[0]["y"], rings)
    assert app.shots[0]["lb"] == expected["lb"]
    assert app.shots[0]["sc"] == expected["sc"]
    assert app.shots[0]["iv"] == expected["iv"]
    assert app.shots[0]["lb"] == "V"          # the same point is a V-bull here


def test_distance_change_keeps_the_total_consistent_with_the_face(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.show_screen("target")
    for _ in range(4):
        click(app, 7.0, 0.0)
    app._select_distance("1000y-dcra")

    rings = build_dist_config("1000y-dcra")[0]
    recomputed = sum(score_shot(s["x"], s["y"], rings)["sc"]
                     for s in app.shots if s["tp"] == "sc")
    assert app._calc_total(app.shots, app.conv)["tot"] == recomputed


def test_distance_change_can_be_declined_and_changes_nothing(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: False)
    app.show_screen("target")
    click(app, 7.0, 0.0)
    before = dict(app.shots[0])

    app._select_distance("1000y-dcra")

    assert app.active_dist == "300y-nra"
    assert app.shots[0] == before


def test_distance_change_with_no_shots_needs_no_confirmation(app, monkeypatch):
    def refuse(*a, **k):
        raise AssertionError("must not prompt when nothing is at stake")
    monkeypatch.setattr("tkinter.messagebox.askyesno", refuse)
    app.show_screen("target")
    app._select_distance("600m-dcra")
    assert app.active_dist == "600m-dcra"


def test_distance_change_updates_the_moa_scale(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app.show_screen("target")
    click(app, 7.0, 0.0)
    before_mu = app.active_mu
    app._select_distance("1000y-dcra")
    assert app.active_mu != before_mu
    assert app.active_mu == pytest.approx(build_dist_config("1000y-dcra")[1])
