"""Shot-marker drawing — shared by the live target and the analysis view.

Both screens draw the same markers on the same kind of face, so the rendering
lives here and neither view can drift from the other.

Marker size is passed in as *ms* (pixels per SVG unit with zoom divided out),
which is what keeps a marker the same size on screen however far the face is
zoomed — see the marker-scale helpers in the two views.
"""
from constants import COL, SHOT_R, SHOT_V_R, SHOT_LBL_U, SHOT_SEL_R


def _palette(shot: dict, conv: str) -> tuple[str, str, str]:
    """(fill, ring, text) colours — sighters stay muted unless converted."""
    sighter   = shot["tp"] in ("A", "B")
    converted = ((shot["tp"] == "A" and conv == "ab") or
                 (shot["tp"] == "B" and conv in ("b", "ab")))
    if sighter and not converted:
        return COL["gray_shot"], COL["gray_ring"], "#374151"
    return COL["red_shot"], COL["gold_ring"], "white"


def draw_shots(canvas, shots, labels, conv, to_canvas, ms,
               selected=None, tags=()):
    """Draw every shot of a string onto *canvas*.

    to_canvas : callable mapping SVG (x, y) to canvas pixels
    ms        : marker scale — pixels per SVG unit, independent of zoom
    selected  : index of the shot to pick out, or None to draw all normally

    With a shot selected, the others are skeletonized to a bare outline with no
    fill and no number, and the selected one gains an accent halo, so a single
    shot can be read out of a tight group.
    """
    r_px    = SHOT_R * ms
    font_sz = max(6, int(SHOT_LBL_U * ms))

    for i, (shot, lbl) in enumerate(zip(shots, labels)):
        px, py = to_canvas(shot["x"], shot["y"])

        if selected is not None and i != selected:
            canvas.create_oval(px - r_px, py - r_px, px + r_px, py + r_px,
                               outline=COL["skeleton"], fill="", width=1.5,
                               tags=tags)
            continue

        fill_col, ring_col, text_col = _palette(shot, conv)

        if selected is not None:
            hr = SHOT_SEL_R * ms
            canvas.create_oval(px - hr, py - hr, px + hr, py + hr,
                               outline=COL["accent"], fill="", width=2,
                               tags=tags)
        if shot["iv"]:
            vr = SHOT_V_R * ms
            canvas.create_oval(px - vr, py - vr, px + vr, py + vr,
                               outline=ring_col, width=2, tags=tags)
        canvas.create_oval(px - r_px, py - r_px, px + r_px, py + r_px,
                           fill=fill_col, outline="", tags=tags)
        canvas.create_text(px, py, text=lbl, fill=text_col,
                           font=("Courier", font_sz, "bold"), tags=tags)
