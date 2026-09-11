# Target geometry — outer ring is always at SVG radius R
R         = 150.0
VB        = 175.0   # viewbox half-size (R + 25 padding)
MAXV      = 200.0   # maximum wind / elevation dial value

# Shot-marker geometry, in SVG units at zoom 1.  Markers are drawn at this
# size regardless of zoom — see the marker-scale helpers in the target and
# analysis views — so zooming in separates a tight group instead of magnifying
# it into the same blob.
SHOT_R     = 6.5   # marker radius
SHOT_V_R   = 9.5   # radius of the ring drawn around a V-bull
SHOT_LBL_U = 6     # shot-number label size
SHOT_SEL_R = 13.0  # halo drawn around the shot selected in the score table

# Canvas dimensions — sized to sit comfortably on a modern tablet screen
CANVAS_PX = 480
SCALE     = CANVAS_PX / (VB * 2)   # pixels per SVG unit
CX        = CANVAS_PX / 2          # canvas centre x
CY        = CANVAS_PX / 2          # canvas centre y

# Colour palette
COL: dict[str, str] = {
    "bg":         "#f7f2e8",
    "bg2":        "#f7f2e8",
    "text":       "#111827",
    "text2":      "#6b7280",
    "border":     "#e5e7eb",
    "border2":    "#d1d5db",
    "accent":     "#BA7517",
    "red_shot":   "#E24B4A",
    "gray_shot":  "#9eaab5",
    "gold_ring":  "#EF9F27",
    "gray_ring":  "#b5c0c7",
    "target_bg":  "#f7f2e8",
    "target_ink": "#1a1a1a",
    "rec_bg":     "#fefbf0",
    "nav_bg":     "#ede8dc",
    "skeleton":   "#c3c9d0",   # outline for shots muted by a selection
    "aim_mark":   "#e3d7bf",   # the black aiming mark, as a tint the grid reads over
    "off_target": "#d8d6cf",   # canvas beyond the target frame
    "frame":      "#8a8171",   # edge of the frame, i.e. of the 1-point Hit area
}
