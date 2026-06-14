"""
Ballistic-graph drawing — shared by the live target view and the analysis view.

A graph plots each shot's *suggested* correction (the wind/elevation that would
have centred that shot) as a connected line, on a value axis centred on shot 1.
Both canvases read their own current pixel size so they scale with the window.
"""
from constants import COL

GRAPH_PX_MOA = 24   # pixels per 1 MOA on the value axis


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


def draw_elev_graph(canvas, shots, mu, max_shots, fb_w, fb_h):
    """Vertical-value graph: elevation on the vertical axis (centred on shot 1),
    shots advancing left→right."""
    canvas.delete("all")
    w, h = _dims(canvas, fb_w, fb_h)
    x0, x1 = 22, w - 6
    y0, y1 = 18, h - 20
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
        canvas.create_text(2, y, text=str(center + off), anchor="w",
                           fill=COL["accent"] if off == 0 else COL["text2"],
                           font=("Courier", 7, "bold" if off == 0 else "normal"))

    step = (x1 - x0) / (max_shots - 1)
    for k in range(max_shots):
        x = x0 + k * step
        canvas.create_line(x, y0, x, y1, fill="#f0f0f0", width=0.4)
        canvas.create_text(x, h - 10, text=str(k + 1), angle=90,
                           fill=COL["text2"], font=("Courier", 6))

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
    x0, x1 = 26, w - 14
    y0, y1 = 16, h - 18
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
        canvas.create_text(x, h - 8, text=str(center + off), anchor="center",
                           fill=COL["accent"] if off == 0 else COL["text2"],
                           font=("Courier", 7, "bold" if off == 0 else "normal"))

    step = (y1 - y0) / (max_shots - 1)
    for k in range(max_shots):
        y = y0 + k * step
        canvas.create_line(x0, y, x1, y, fill="#f0f0f0", width=0.4)
        canvas.create_text(3, y, text=str(k + 1), anchor="w",
                           fill=COL["text2"], font=("Courier", 6))

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
