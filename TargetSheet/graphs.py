"""
Ballistic-graph drawing — shared by the live target view and the analysis view.

A graph plots each shot's *suggested* correction (the wind/elevation that would
have centred that shot) as a connected line, on a value axis centred on shot 1.
Both canvases read their own current pixel size so they scale with the window.
"""
from constants import COL

GRAPH_PX_MOA = 24   # pixels per 1 MOA on the value axis

# Axis type.  The shot axis is the cramped one — a 15-shot match packs 17
# columns into a strip barely wider than the target's margin — so its labels
# are thinned rather than shrunk.
VALUE_FONT   = ("Courier", 8)
SHOT_FONT    = ("Courier", 8)
_SHOT_LBL_W  = 18   # px a horizontal shot number needs before it collides
_SHOT_LBL_H  = 14   # px a stacked shot number needs before it collides


def suggested(shot: dict, mu: float) -> tuple[float, float]:
    """(wind, elevation) that would have centred this individual shot."""
    return (shot["w"] - shot["x"] / mu,
            shot["e"] + shot["y"] / mu)


def _dims(canvas, fb_w: int, fb_h: int) -> tuple[int, int]:
    w = canvas.winfo_width()
    h = canvas.winfo_height()
    if w < 5:
        w = fb_w
    if h < 5:
        h = fb_h
    return w, h


def _label_every(span_px: float, count: int, need_px: float) -> int:
    """Label every Nth shot, so numbers stay readable instead of colliding.

    Gridlines are still drawn for every shot; only the numbering is thinned.
    """
    if count < 2:
        return 1
    per = span_px / (count - 1)
    for every in (1, 2, 5, 10):
        if per * every >= need_px:
            return every
    return 10


def draw_elev_graph(canvas, shots, mu, max_shots, fb_w, fb_h):
    """Vertical-value graph: elevation on the vertical axis (centred on shot 1),
    shots advancing left→right."""
    canvas.delete("all")
    w, h = _dims(canvas, fb_w, fb_h)
    x0, x1 = 28, w - 8
    y0, y1 = 18, h - 22
    cy = (y0 + y1) / 2
    center = round(suggested(shots[0], mu)[1]) if shots else 0

    canvas.create_text(w / 2, 3, text="ELEV", anchor="n",
                       fill=COL["text2"], font=("Helvetica", 7, "bold"))

    n_side = int((cy - y0) / GRAPH_PX_MOA)
    for off in range(-n_side, n_side + 1):
        y = cy - off * GRAPH_PX_MOA
        canvas.create_line(x0, y, x1, y,
                           fill="#888" if off == 0 else "#e0e0e0",
                           width=1.0 if off == 0 else 0.5)
        canvas.create_text(3, y, text=str(center + off), anchor="w",
                           fill=COL["accent"] if off == 0 else COL["text2"],
                           font=(*VALUE_FONT, "bold") if off == 0 else VALUE_FONT)

    step = (x1 - x0) / (max_shots - 1)
    every = _label_every(x1 - x0, max_shots, _SHOT_LBL_W)
    for k in range(max_shots):
        x = x0 + k * step
        canvas.create_line(x, y0, x, y1, fill="#f0f0f0", width=0.4)
        if k % every == 0:
            canvas.create_text(x, h - 11, text=str(k + 1), anchor="center",
                               fill=COL["text2"], font=SHOT_FONT)

    pts = []
    for i, shot in enumerate(shots[:max_shots]):
        sug_e = suggested(shot, mu)[1]
        y = max(y0, min(y1, cy - (sug_e - center) * GRAPH_PX_MOA))
        pts.append((x0 + i * step, y))
    for a, b in zip(pts, pts[1:]):
        canvas.create_line(*a, *b, fill=COL["accent"], width=2)
    for x, y in pts:
        canvas.create_oval(x - 3, y - 3, x + 3, y + 3,
                           fill=COL["red_shot"], outline="")


def draw_wind_graph(canvas, shots, mu, max_shots, fb_w, fb_h):
    """Horizontal-value graph: wind on the horizontal axis (centred on shot 1),
    shots advancing top→bottom."""
    canvas.delete("all")
    w, h = _dims(canvas, fb_w, fb_h)
    x0, x1 = 30, w - 14
    y0, y1 = 16, h - 20
    cx = (x0 + x1) / 2
    center = round(suggested(shots[0], mu)[0]) if shots else 0

    canvas.create_text(3, 3, text="WIND", anchor="nw",
                       fill=COL["text2"], font=("Helvetica", 7, "bold"))

    n_side = int((cx - x0) / GRAPH_PX_MOA)
    for off in range(-n_side, n_side + 1):
        x = cx + off * GRAPH_PX_MOA
        canvas.create_line(x, y0, x, y1,
                           fill="#888" if off == 0 else "#e0e0e0",
                           width=1.0 if off == 0 else 0.5)
        canvas.create_text(x, h - 9, text=str(center + off), anchor="center",
                           fill=COL["accent"] if off == 0 else COL["text2"],
                           font=(*VALUE_FONT, "bold") if off == 0 else VALUE_FONT)

    step = (y1 - y0) / (max_shots - 1)
    every = _label_every(y1 - y0, max_shots, _SHOT_LBL_H)
    for k in range(max_shots):
        y = y0 + k * step
        canvas.create_line(x0, y, x1, y, fill="#f0f0f0", width=0.4)
        if k % every == 0:
            canvas.create_text(4, y, text=str(k + 1), anchor="w",
                               fill=COL["text2"], font=SHOT_FONT)

    pts = []
    for i, shot in enumerate(shots[:max_shots]):
        sug_w = suggested(shot, mu)[0]
        x = max(x0, min(x1, cx + (sug_w - center) * GRAPH_PX_MOA))
        pts.append((x, y0 + i * step))
    for a, b in zip(pts, pts[1:]):
        canvas.create_line(*a, *b, fill=COL["accent"], width=2)
    for x, y in pts:
        canvas.create_oval(x - 3, y - 3, x + 3, y + 3,
                           fill=COL["red_shot"], outline="")
