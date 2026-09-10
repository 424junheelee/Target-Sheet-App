"""Ballistic-graph geometry and axis labelling."""
import pytest

import graphs
from graphs import _label_every, suggested


# -- suggested correction per shot --------------------------------------------

def test_suggested_undoes_the_shot_offset(mkshot):
    mu = 20.0
    shot = mkshot(mu * 2, mu * 3, "sc", w=1.0, e=0.5)
    w, e = suggested(shot, mu)
    assert w == pytest.approx(1.0 - 2)     # right of centre -> less right wind
    assert e == pytest.approx(0.5 + 3)     # low on the face -> more elevation


def test_a_centred_shot_suggests_no_change(mkshot):
    assert suggested(mkshot(0, 0, "sc", w=2.5, e=-1.0), 20.0) == (2.5, -1.0)


# -- axis label thinning ------------------------------------------------------
#
# A 15-shot match packs 17 columns into a strip a little wider than the
# target's margin.  Labelling every one produced an illegible smudge, so the
# numbering thins out while the gridlines stay.

def test_every_shot_is_labelled_when_there_is_room():
    assert _label_every(span_px=400, count=12, need_px=18) == 1


def test_labels_thin_out_when_columns_get_tight():
    assert _label_every(span_px=120, count=17, need_px=18) > 1


def test_thinning_keeps_labels_at_least_need_px_apart():
    for count in (12, 17):
        for span in range(60, 501, 20):
            every = _label_every(span, count, 18)
            spacing = span / (count - 1) * every
            assert spacing >= 18 or every == 10


def test_chosen_steps_are_round_numbers():
    for span in range(40, 601, 10):
        assert _label_every(span, 17, 18) in (1, 2, 5, 10)


def test_a_single_shot_axis_does_not_divide_by_zero():
    assert _label_every(span_px=100, count=1, need_px=18) == 1
    assert _label_every(span_px=100, count=0, need_px=18) == 1


def test_labelled_indices_always_include_the_first_shot():
    every = _label_every(120, 17, 18)
    assert 0 % every == 0


# -- drawing ------------------------------------------------------------------

def _items(canvas):
    return len(canvas.find_all())


def test_graphs_draw_at_the_live_target_strip_sizes(app, mkshot):
    from views.target import ELEV_GRAPH_W, WIND_GRAPH_H
    shots = [mkshot(i * 2, -i, "sc") for i in range(12)]
    graphs.draw_elev_graph(app._elev_graph, shots, app.active_mu, 12,
                           ELEV_GRAPH_W, 480)
    graphs.draw_wind_graph(app._wind_graph, shots, app.active_mu, 12,
                           480, WIND_GRAPH_H)
    assert _items(app._elev_graph) > 0
    assert _items(app._wind_graph) > 0


def test_graphs_survive_a_fifteen_shot_match(app, mkshot):
    shots = [mkshot(i, i, "sc") for i in range(17)]
    graphs.draw_elev_graph(app._elev_graph, shots, app.active_mu, 17, 152, 480)
    graphs.draw_wind_graph(app._wind_graph, shots, app.active_mu, 17, 480, 132)


def test_graphs_survive_a_tiny_canvas(app, mkshot):
    """Fallback dimensions apply before layout has settled."""
    shots = [mkshot(0, 0, "sc")]
    graphs.draw_elev_graph(app._elev_graph, shots, app.active_mu, 12, 40, 40)
    graphs.draw_wind_graph(app._wind_graph, shots, app.active_mu, 12, 40, 40)


def test_empty_string_still_draws_the_axes(app):
    graphs.draw_elev_graph(app._elev_graph, [], app.active_mu, 12, 152, 480)
    assert _items(app._elev_graph) > 0


def test_shot_markers_stay_inside_the_plot_area(app, mkshot):
    """A wild flyer is clamped to the axis rather than drawn off-canvas."""
    fb_h = 480
    c = app._elev_graph
    shots = [mkshot(0, 0, "sc"), mkshot(0, 4000, "sc")]   # second is way low
    graphs.draw_elev_graph(c, shots, app.active_mu, 12, 152, fb_h)

    markers = [i for i in c.find_all() if c.type(i) == "oval"]
    assert markers, "expected a marker per shot"
    for item in markers:
        _, y_top, _, y_bot = c.coords(item)
        assert 0 <= y_top and y_bot <= fb_h
