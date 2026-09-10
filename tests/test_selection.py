"""Selecting a shot from the score table highlights it and skeletonizes the rest.

Selection is driven from the shot table, never from the target face, so the
canvas keeps placing shots exactly as before.
"""
import types

import pytest


def click(app, svg_x, svg_y):
    px, py = app._to_canvas(svg_x, svg_y)
    app._on_shot_release(types.SimpleNamespace(x=px, y=py))
    app.root.update_idletasks()


def place(app, n):
    """Fire n shots, spread out enough to be individually visible."""
    app.show_screen("target")
    for i in range(n):
        click(app, 10 + i * 6, -8 + i * 3)


def shot_items(app):
    """Canvas items making up the shot markers, in draw order."""
    c = app._canvas
    return [(c.type(i), i) for i in c.find_withtag("shot")]


def discs(app):
    """Filled marker discs currently drawn."""
    c = app._canvas
    return [i for t, i in shot_items(app)
            if t == "oval" and c.itemcget(i, "fill")]


def rings(app):
    """Unfilled outline rings currently drawn."""
    c = app._canvas
    return [i for t, i in shot_items(app)
            if t == "oval" and not c.itemcget(i, "fill")]


def numbers(app):
    c = app._canvas
    return [c.itemcget(i, "text") for t, i in shot_items(app) if t == "text"]


def rows(app):
    return app._shot_tree.get_children()


# -- selecting from the table -------------------------------------------------

def test_no_selection_by_default(app):
    place(app, 3)
    assert app.selected_shot is None


def test_clicking_a_row_selects_that_shot(app):
    place(app, 4)
    app.select_shot(2)
    assert app.selected_shot == 2


def test_the_table_row_drives_the_selection(app):
    place(app, 4)
    app._shot_tree.selection_set(rows(app)[1])
    app.root.update()   # <<TreeviewSelect>> is queued, not delivered inline
    assert app.selected_shot == 1


def test_selecting_the_same_shot_again_clears_it(app):
    place(app, 3)
    app.select_shot(1)
    app.select_shot(1)
    assert app.selected_shot is None


def test_selecting_a_different_shot_moves_the_highlight(app):
    place(app, 3)
    app.select_shot(0)
    app.select_shot(2)
    assert app.selected_shot == 2


def test_out_of_range_selection_is_ignored(app):
    place(app, 2)
    app.select_shot(9)
    assert app.selected_shot is None


# -- deselecting --------------------------------------------------------------

def test_tapping_the_target_face_deselects(app):
    place(app, 3)
    app.select_shot(1)
    app._on_shot_press(types.SimpleNamespace(x=100, y=100))
    assert app.selected_shot is None


def test_tapping_the_face_still_places_a_shot(app):
    """Deselecting must not swallow the tap that places the next shot."""
    place(app, 3)
    app.select_shot(1)
    before = len(app.shots)
    click(app, 40, 20)
    assert len(app.shots) == before + 1
    assert app.selected_shot is None


def test_escape_deselects(app):
    place(app, 3)
    app.select_shot(1)
    app._on_escape()
    assert app.selected_shot is None


# -- invalidation -------------------------------------------------------------

def test_undoing_the_selected_shot_clears_the_selection(app):
    place(app, 3)
    app.select_shot(2)
    app.undo_shot()
    assert app.selected_shot is None


def test_undoing_an_earlier_shot_leaves_a_valid_selection(app):
    place(app, 4)
    app.select_shot(1)
    app.undo_shot()
    assert app.selected_shot in (1, None)
    if app.selected_shot is not None:
        assert app.selected_shot < len(app.shots)


def test_committing_clears_the_selection(app):
    place(app, 3)
    app.select_shot(1)
    app.commit_string()
    assert app.selected_shot is None


def test_discarding_clears_the_selection(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    place(app, 3)
    app.select_shot(1)
    app._discard_current()
    assert app.selected_shot is None


def test_selection_survives_a_table_refresh(app):
    """set_call rebuilds every row — the highlight must not silently drop."""
    place(app, 3)
    app.select_shot(1)
    app.set_call("good")
    assert app.selected_shot == 1
    assert app._shot_tree.selection(), "the row should still look selected"


# -- what gets drawn ----------------------------------------------------------

def test_without_a_selection_every_shot_is_drawn_normally(app):
    place(app, 3)
    app._draw_shots()
    assert len(discs(app)) == 3
    assert len(numbers(app)) == 3


def test_selecting_skeletonizes_the_others(app):
    place(app, 4)
    app.select_shot(1)
    app._draw_shots()
    assert len(discs(app)) == 1, "only the selected shot keeps its fill"
    assert len(rings(app)) >= 3, "the rest become hollow rings"


def test_skeletonized_shots_lose_their_numbers(app):
    place(app, 4)
    app.select_shot(1)
    app._draw_shots()
    expected = app._compute_labels(app.shots, app.conv)[1]
    assert numbers(app) == [expected], "only the selected shot keeps its number"


def test_the_selected_shot_gets_a_halo(app):
    place(app, 3)
    app._draw_shots()
    plain = len(rings(app))
    app.select_shot(0)
    app._draw_shots()
    from constants import COL
    c = app._canvas
    halo = [i for i in rings(app)
            if c.itemcget(i, "outline") == COL["accent"]]
    assert len(halo) == 1
    assert len(rings(app)) > plain


def test_deselecting_restores_the_normal_drawing(app):
    place(app, 3)
    app.select_shot(1)
    app._draw_shots()
    app.clear_shot_selection()
    app._draw_shots()
    assert len(discs(app)) == 3
    assert len(numbers(app)) == 3


# -- the analysis view behaves the same ---------------------------------------

def analysis_face(widget):
    import tkinter as tk
    if isinstance(widget, tk.Canvas) and str(widget.cget("cursor")) == "fleur":
        return widget
    for child in widget.winfo_children():
        found = analysis_face(child)
        if found is not None:
            return found
    return None


def saved_series(app, mkshot, n=4):
    app.strings = [{"shots": [mkshot(10 + i * 6, -8 + i * 3, "sc")
                              for i in range(n)],
                    "cv": "none", "dist": "300y-nra", "mu": 21.4,
                    "shoot_len": 10}]
    app.set_analysis(0)
    app.root.update_idletasks()


def test_analysis_starts_with_nothing_selected(app, mkshot):
    saved_series(app, mkshot)
    assert app.analysis_selected is None


def test_analysis_row_selects_a_shot(app, mkshot):
    saved_series(app, mkshot)
    app.select_analysis_shot(2)
    assert app.analysis_selected == 2


def test_analysis_selection_skeletonizes_the_face(app, mkshot):
    saved_series(app, mkshot)
    face = analysis_face(app._ac_inner)
    assert face is not None

    def texts():
        return [face.itemcget(i, "text") for i in face.find_all()
                if face.type(i) == "text"]

    app.select_analysis_shot(1)
    app.root.update_idletasks()
    shot_numbers = [t for t in texts() if t in ("1", "2", "3", "4")]
    assert shot_numbers == ["2"]


def test_analysis_selection_clears_when_switching_series(app, mkshot):
    saved_series(app, mkshot)
    app.select_analysis_shot(1)
    app.strings.append({"shots": [mkshot(0, 0, "sc")], "cv": "none",
                        "dist": "300y-nra", "mu": 21.4, "shoot_len": 10})
    app.set_analysis(1)
    app.root.update_idletasks()
    assert app.analysis_selected is None


def test_analysis_escape_deselects(app, mkshot):
    saved_series(app, mkshot)
    app.select_analysis_shot(1)
    app._on_escape()
    assert app.analysis_selected is None
