"""Shot markers keep a constant on-screen size as the target face zooms.

Zooming used to magnify a tight group without separating it, because marker
radius was multiplied by the same scale as the shot positions.  Positions must
still zoom; the markers must not.
"""
import math
import tkinter as tk

import pytest

from constants import SHOT_R, SHOT_V_R


# -- helpers ------------------------------------------------------------------

def marker_ovals(canvas, tag="shot"):
    """Radii of the filled shot discs currently drawn."""
    items = canvas.find_withtag(tag) if tag else canvas.find_all()
    out = []
    for i in items:
        if canvas.type(i) != "oval":
            continue
        x0, _, x1, _ = canvas.coords(i)
        out.append((x1 - x0) / 2)
    return out


def marker_centres(canvas, tag="shot"):
    items = canvas.find_withtag(tag) if tag else canvas.find_all()
    out = []
    for i in items:
        if canvas.type(i) != "oval":
            continue
        x0, y0, x1, y1 = canvas.coords(i)
        out.append(((x0 + x1) / 2, (y0 + y1) / 2))
    return out


def find_face_canvas(widget):
    """The analysis target face — the only canvas with a 'fleur' cursor."""
    if isinstance(widget, tk.Canvas) and str(widget.cget("cursor")) == "fleur":
        return widget
    for child in widget.winfo_children():
        found = find_face_canvas(child)
        if found is not None:
            return found
    return None


# -- the marker scale itself --------------------------------------------------

def test_marker_scale_ignores_zoom(app):
    app.show_screen("target")
    app._zoom = 1.0
    at_1 = app._marker_scale()
    for zoom in (0.5, 2.0, 4.0, 8.0):
        app._zoom = zoom
        assert app._marker_scale() == pytest.approx(at_1)


def test_canvas_scale_still_follows_zoom(app):
    """The face itself must keep zooming — only the markers are pinned."""
    app.show_screen("target")
    app._zoom = 1.0
    _, _, base, _, _ = app._metrics()
    app._zoom = 4.0
    _, _, zoomed, _, _ = app._metrics()
    assert zoomed == pytest.approx(base * 4)


def test_marker_scale_still_grows_with_the_canvas(app):
    """A bigger window should still get proportionately bigger markers."""
    app.show_screen("target")
    app.root.geometry("1080x720")
    app.root.update_idletasks()
    small = app._marker_scale()
    app.root.geometry("1600x1000")
    app.root.update_idletasks()
    assert app._marker_scale() >= small


# -- drawn markers on the live target -----------------------------------------

def place(app, *points):
    """Put shots at given SVG coordinates, bypassing the sighter phases."""
    from scoring import score_shot
    app.shots = []
    for x, y in points:
        r = score_shot(x, y, app.active_rings)
        app.shots.append({"x": float(x), "y": float(y), "sc": r["sc"],
                          "iv": r["iv"], "lb": r["lb"], "tp": "sc",
                          "w": 0.0, "e": 0.0, "cl": None})


def test_drawn_marker_radius_is_the_same_at_every_zoom(app):
    app.show_screen("target")
    place(app, (40, 0), (45, 4))          # outside the V ring: one oval each
    radii = {}
    for zoom in (1.0, 2.0, 4.0, 8.0):
        app._zoom = zoom
        app._draw_shots()
        radii[zoom] = marker_ovals(app._canvas)
    expected = SHOT_R * app._marker_scale()
    for zoom, got in radii.items():
        assert got == pytest.approx([expected] * 2), f"zoom {zoom}"


def test_zooming_pushes_shots_apart(app):
    """The whole point: a tight pair separates as the face expands."""
    app.show_screen("target")
    place(app, (40, 0), (42, 0))          # a tight non-V pair

    def gap():
        (ax, ay), (bx, by) = marker_centres(app._canvas)
        return math.hypot(bx - ax, by - ay)

    app._zoom = 1.0
    app._draw_shots()
    near, radius = gap(), marker_ovals(app._canvas)[0]
    assert near < radius * 2, "test needs a pair that starts overlapping"

    app._zoom = 8.0
    app._draw_shots()
    assert gap() == pytest.approx(near * 8)
    assert gap() > marker_ovals(app._canvas)[0] * 2, "should no longer overlap"


def test_v_bull_ring_is_pinned_too(app):
    """The highlight ring must not drift away from the disc it surrounds."""
    app.show_screen("target")
    place(app, (0, 0))                     # dead centre: a V-bull
    app._zoom = 6.0
    app._draw_shots()
    radii = sorted(marker_ovals(app._canvas))
    ms = app._marker_scale()
    assert radii == pytest.approx([SHOT_R * ms, SHOT_V_R * ms])


def test_shot_label_size_is_pinned(app):
    app.show_screen("target")
    place(app, (20, 0))

    def label_size():
        c = app._canvas
        for i in c.find_withtag("shot"):
            if c.type(i) == "text":
                return int(str(c.itemcget(i, "font")).split()[1])
        return None

    app._zoom = 1.0
    app._draw_shots()
    at_1 = label_size()
    app._zoom = 8.0
    app._draw_shots()
    assert label_size() == at_1


def test_shot_preview_matches_the_marker_it_becomes(app):
    app.show_screen("target")
    app._zoom = 3.0
    app._draw_shot_preview(100, 100)
    preview = marker_ovals(app._canvas, "preview")
    assert preview == pytest.approx([SHOT_R * app._marker_scale()])


# -- the analysis face behaves the same ---------------------------------------

def test_analysis_markers_are_pinned_across_zoom(app, mkshot):
    app.strings = [{"shots": [mkshot(40, 0, "sc"), mkshot(42, 0, "sc")],
                    "cv": "none", "dist": "300y-nra", "mu": 21.4,
                    "shoot_len": 10}]
    app.set_analysis(0)
    app.root.update_idletasks()

    def face_markers():
        face = find_face_canvas(app._ac_inner)
        assert face is not None, "analysis face canvas not found"
        rings_and_shots = marker_ovals(face, tag=None)
        # The five scoring rings are drawn first, the shot discs last.
        return rings_and_shots[-2:]

    app._a_zoom = 1.0
    app._render_analysis()
    app.root.update_idletasks()
    at_1 = face_markers()

    app._a_zoom = 6.0
    app._render_analysis()
    app.root.update_idletasks()
    assert face_markers() == pytest.approx(at_1)
