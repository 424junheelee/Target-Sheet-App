"""Target-face drawing — shared by the live target and the analysis view.

One function draws the whole face, so the two screens can never disagree about
what a target looks like.  Draw order matters:

  1. the face and the aiming mark ("the black").  The black is drawn as a tint
     rather than true black so the MOA grid over it stays readable — the grid
     is what the app measures corrections with.
  2. the scoring rings.
  3. everything off the target, shaded.  This goes over the rings on purpose:
     at long range the Outer ring runs off the top and bottom of the frame, and
     the rule books count nothing that is not on the target.
  4. the 1-MOA grid, over everything, so every shot — misses included — sits
     on the MOA reference.
  5. the frame edge and the label.
"""
import math

from constants import COL, R, VB
from targets import aim_radius, build_dist_config, display_name, hit_area


def draw_face(canvas, dist_key, sc, cx, cy, w, h, tags=()):
    """Draw the face for *dist_key* onto a *w* x *h* canvas.

    sc     : canvas pixels per SVG unit (zoom included)
    cx, cy : canvas position of the target centre (pan included)
    """
    rings, mu = build_dist_config(dist_key)
    hit = hit_area(dist_key)
    aim = aim_radius(dist_key)

    canvas.create_rectangle(0, 0, w, h, fill=COL["target_bg"], outline="",
                            tags=tags)

    if aim:
        a = aim * sc
        canvas.create_oval(cx - a, cy - a, cx + a, cy + a,
                           fill=COL["aim_mark"], outline="", tags=tags)

    for ring in reversed(rings):
        r_px = ring["r"] * sc
        lw = 1.8 if ring["r"] >= R * 0.14 else 1.2
        canvas.create_oval(cx - r_px, cy - r_px, cx + r_px, cy + r_px,
                           outline=COL["target_ink"], width=lw, tags=tags)

    if hit:
        fx0, fx1 = cx - hit[0] * sc, cx + hit[0] * sc
        fy0, fy1 = cy - hit[1] * sc, cy + hit[1] * sc
        _shade_off_target(canvas, fx0, fy0, fx1, fy1, w, h, tags)

    _draw_grid(canvas, mu, sc, cx, cy, w, h, tags)

    ext = VB * sc
    canvas.create_line(cx - ext, cy - ext, cx + ext, cy + ext,
                       fill="#bbb", width=1.0, tags=tags)
    canvas.create_line(cx + ext, cy - ext, cx - ext, cy + ext,
                       fill="#bbb", width=1.0, tags=tags)
    p = 104 * sc
    canvas.create_line(cx - p, cy - p, cx + p, cy + p,
                       fill="#bbb", width=0.8, dash=(6, 4), tags=tags)
    canvas.create_line(cx + p, cy - p, cx - p, cy + p,
                       fill="#bbb", width=0.8, dash=(6, 4), tags=tags)

    if hit:
        canvas.create_rectangle(fx0, fy0, fx1, fy1, outline=COL["frame"],
                                width=1.5, tags=tags)

    canvas.create_rectangle(0, 0, w, h, outline="#555", width=1, tags=tags)
    canvas.create_text(6, 5, text=f"1 MOA · {display_name(dist_key)}",
                       anchor="nw", fill="#999", font=("Courier", 8), tags=tags)


def _shade_off_target(canvas, fx0, fy0, fx1, fy1, w, h, tags):
    """Shade the four bands of canvas outside the frame rectangle."""
    shade = dict(fill=COL["off_target"], outline="", tags=tags)
    top, bottom = max(fy0, 0), min(fy1, h)
    if fy0 > 0:
        canvas.create_rectangle(0, 0, w, fy0, **shade)
    if fy1 < h:
        canvas.create_rectangle(0, fy1, w, h, **shade)
    if fx0 > 0 and bottom > top:
        canvas.create_rectangle(0, top, fx0, bottom, **shade)
    if fx1 < w and bottom > top:
        canvas.create_rectangle(fx1, top, w, bottom, **shade)


def _draw_grid(canvas, mu, sc, cx, cy, w, h, tags):
    """1-MOA grid lines across the whole visible canvas, at any zoom or pan.

    The centre lines are darkest; the line nearest the Outer ring is picked
    out so the face's size in MOA reads at a glance.
    """
    step = mu * sc
    if step <= 0:
        return
    highlight = round(R / mu)

    def style(i):
        if i == 0:
            return "#555", 0.8
        if abs(i) == highlight:
            return "#999", 0.6
        return "#ccc", 0.4

    for i in range(math.floor(-cx / step), math.ceil((w - cx) / step) + 1):
        colour, width = style(i)
        gx = cx + i * step
        canvas.create_line(gx, 0, gx, h, fill=colour, width=width, tags=tags)
    for i in range(math.floor(-cy / step), math.ceil((h - cy) / step) + 1):
        colour, width = style(i)
        gy = cy + i * step
        canvas.create_line(0, gy, w, gy, fill=colour, width=width, tags=tags)
