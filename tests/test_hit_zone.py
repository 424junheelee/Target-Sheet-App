"""The 1-point Hit zone, and the target frame that bounds all scoring.

All three rule books score 1 for a shot on the target but outside the Outer
ring, and a miss for anything off the target - including the parts of the
long-range Outer ring that run off the top and bottom of the frame.
"""
import types

import pytest

from constants import R
from scoring import score_shot
from targets import TARGET_CONFIGS, build_dist_config, hit_area


def rings_hit(key):
    return build_dist_config(key)[0], hit_area(key)


# -- scoring ------------------------------------------------------------------

def test_inside_the_rings_scores_the_ring():
    rings, hit = rings_hit("600y-icfra")
    assert score_shot(0, 0, rings, hit)["lb"] == "V"


def test_on_the_target_outside_the_outer_ring_scores_one():
    rings, hit = rings_hit("300y-icfra")
    shot = score_shot(R + 20, 0, rings, hit)
    assert (shot["sc"], shot["lb"], shot["iv"]) == (1, "1", False)


def test_off_the_target_is_a_miss():
    rings, hit = rings_hit("300y-icfra")
    shot = score_shot(hit[0] + 1, 0, rings, hit)
    assert (shot["sc"], shot["lb"]) == (0, "M")


def test_the_frame_edge_itself_still_counts():
    rings, hit = rings_hit("300y-icfra")
    assert score_shot(hit[0], hit[1], rings, hit)["lb"] == "1"


def test_outer_ring_beyond_the_frame_is_a_miss():
    """ICFRA long range: an 1830 mm Outer on a frame only 1800 mm high."""
    rings, hit = rings_hit("1000y-icfra")
    assert hit[1] < R, "precondition: the Outer ring runs off the frame"
    y = (hit[1] + R) / 2           # inside the Outer circle, above the frame
    assert score_shot(0, y, rings, hit)["lb"] == "M"
    assert score_shot(0, hit[1] - 1, rings, hit)["lb"] == "2"


def test_dcra_long_range_border_clips_the_outer_ring_at_the_sides_too():
    """DCRA's Hit area is the 8x6 ft target less a 1-inch border: 94 in wide
    against a 96 in Outer, so even straight out to the side runs off."""
    rings, hit = rings_hit("900y-dcra")
    assert hit[0] < R
    assert score_shot(hit[0] + 0.5, 0, rings, hit)["lb"] == "M"


def test_without_a_hit_area_outside_the_rings_is_a_miss():
    """Faces from before this change have no frame, and keep the old rule."""
    rings, _ = rings_hit("300y-icfra")
    assert score_shot(R + 20, 0, rings)["lb"] == "M"


@pytest.mark.parametrize("key", sorted(TARGET_CONFIGS))
def test_every_face_has_a_hit_zone_somewhere(key):
    """Each rule book gives every face a 1-point area; check it is reachable -
    at a corner of the frame, which is never inside the Outer circle."""
    rings, hit = rings_hit(key)
    corner = score_shot(hit[0] - 0.01, hit[1] - 0.01, rings, hit)
    assert corner["lb"] == "1"


# -- in the app ---------------------------------------------------------------

def click(app, svg_x, svg_y):
    px, py = app._to_canvas(svg_x, svg_y)
    app._on_shot_release(types.SimpleNamespace(x=px, y=py))
    app.root.update_idletasks()


def test_a_shot_in_the_hit_zone_scores_one_in_the_app(app):
    app._select_distance("300y-icfra")
    app.show_screen("target")
    click(app, 0, 0)
    click(app, 0, 0)
    click(app, R + 30, 0)
    assert app.shots[-1]["lb"] == "1"
    assert app._calc_total(app.shots, app.conv)["tot"] == 1


def test_a_shot_off_the_frame_is_a_miss_in_the_app(app):
    app._select_distance("300y-icfra")
    app.show_screen("target")
    app._zoom = 0.5
    _, hit = rings_hit("300y-icfra")
    click(app, hit[0] + 10, 0)
    assert app.shots[-1]["lb"] == "M"


def test_changing_distance_rescores_into_and_out_of_the_hit_zone(app, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    app._select_distance("300y-icfra")
    app.show_screen("target")
    _, hit = rings_hit("300y-icfra")
    x = (R + hit[0]) / 2                  # in the 300 yd Hit zone
    click(app, x, 0)
    assert app.shots[0]["lb"] == "1"
    app._select_distance("900y-dcra")      # far narrower frame
    assert app.shots[0]["lb"] == "M"


# -- drawing ------------------------------------------------------------------

def _fills(canvas, tag="bg"):
    return {canvas.itemcget(i, "fill") for i in canvas.find_withtag(tag)
            if canvas.type(i) in ("rectangle", "oval")}


def test_the_aiming_mark_is_drawn(app):
    from constants import COL
    app._select_distance("600y-nra")
    app.show_screen("target")
    assert COL["aim_mark"] in _fills(app._canvas)


def test_the_area_off_the_target_is_shaded(app):
    from constants import COL
    app._select_distance("1000y-icfra")
    app.show_screen("target")
    app._zoom = 0.5
    app._redraw_target()
    assert COL["off_target"] in _fills(app._canvas)


def test_the_frame_outline_is_drawn(app):
    from constants import COL
    app._select_distance("300y-dcra")
    app.show_screen("target")
    app._zoom = 0.5
    app._redraw_target()
    c = app._canvas
    frames = [i for i in c.find_withtag("bg") if c.type(i) == "rectangle"
              and c.itemcget(i, "outline") == COL["frame"]]
    assert len(frames) == 1


def test_grid_reaches_the_canvas_edges_when_zoomed_out(app):
    app._select_distance("300y-icfra")
    app.show_screen("target")
    app._zoom = 0.5
    app._redraw_target()
    app.root.update_idletasks()
    c = app._canvas
    w, h, sc, cx, cy = app._metrics()
    xs = [c.coords(i)[0] for i in c.find_withtag("bg") if c.type(i) == "line"
          and len(c.coords(i)) == 4 and c.coords(i)[0] == c.coords(i)[2]
          and c.coords(i)[1] == 0]
    step = app.active_mu * sc
    assert min(xs) <= step and max(xs) >= w - step
