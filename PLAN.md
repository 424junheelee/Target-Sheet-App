# TargetSheet Phase 1 — Implementation Plan

Source inventory and open-question resolutions compiled from reading the Python source
(`/TargetSheet/`) directly. Per the brief, the source overrides this document wherever
they conflict.

---

## 1. Source Inventory

### Screens / navigation

| Screen key   | Mixin / file         | Purpose |
|--------------|----------------------|---------|
| `menu`       | `views/menu.py`      | Main menu; resume banner when session active |
| `dist_select`| `views/menu.py`      | Distance + standard picker; match length 10/15 |
| `target`     | `views/target.py`    | Live target canvas; wind/elev dials; shot table; graphs |
| `scorecard`  | `views/scorecard.py` | Per-string cards + aggregate total |
| `analysis`   | `views/analysis.py`  | Interactive target replay + stats per string |
| `options`    | `views/settings.py`  | Toggle recommendation / graphs |
| `presets`    | `views/settings.py`  | Aperture + elevation per distance-config |

### Shot schema (Python source)

```
x, y : float  — SVG canvas coordinates (origin=centre, x=right, y=DOWN)
sc   : int    — score 0–5
iv   : bool   — True if V-bull
lb   : str    — "V" | "5" | "4" | "3" | "2" | "M"
tp   : str    — "A" | "B" | "sc"
w, e : float  — wind / elevation dialled at shot time (MOA, snapped to 0.25)
cl   : str|None — "pull-high" | "pull-low" | "pull-left" | "pull-right" | "good" | "bad" | None
```

### String schema (Python source)

```
shots        : list[shot]
cv           : "none" | "b" | "ab"
dist         : str  — distance-config key e.g. "600y-nra"
mu           : float — SVG units per MOA at this distance
shoot_len    : 10 | 15
target_number: str
saved_at     : ISO-8601 string
```

### Session schema (Python source)

```
shots, conv, conv_chosen, active_dist, wind_val, elev_val, target_number
```

### Settings schema (Python source)

```
show_rec, show_graphs, shoot_len, active_dist
```

### Presets schema (Python source)

```
{ dist_key: { aperture: str, elevation: str } }
```

---

## 2. Ring Constants (extracted from source — authoritative)

Internal unit: inch radii, converted to mm radii for the Flutter model (× 25.4).

### NRA (UK Bisley) — inch radii [V, 5, 4, 3, 2]

| Distance | V (in) | 5 (in) | 4 (in) | 3 (in) | 2 (in) | V/5 ratio | Face |
|----------|--------|--------|--------|--------|--------|-----------|------|
| 300y     | 1.0    | 3.0    | 6.0    | 12.0   | 22.0   | 0.333     | Fig 11 (44" outer) |
| 500-1000y| 2.5    | 7.5    | 15.0   | 24.0   | 36.0   | 0.333     | Fig 12 (72" outer) |

### DCRA / ICFRA TR — inch radii [V, 5, 4, 3, 2]

| Band | Distance range | V (in) | 5 (in) | 4 (in) | 3 (in) | 2 (in) | V/5 ratio |
|------|---------------|--------|--------|--------|--------|--------|-----------|
| SR   | 300y, 300m    | 1.378  | 2.756  | 5.512  | 8.268  | 11.811 | 0.500 |
| MR   | 500-600y/m    | 3.150  | 6.299  | 12.992 | 19.685 | 25.984 | 0.500 |
| LR   | 700-1000y/m   | 5.020  | 10.039 | 16.043 | 22.047 | 36.024 | 0.500 |

### Converted to mm radii (× 25.4) for Flutter model

| Face | V (mm) | 5 (mm) | 4 (mm) | 3 (mm) | 2 (mm) |
|------|--------|--------|--------|--------|--------|
| NRA 300y | 25.40 | 76.20 | 152.40 | 304.80 | 558.80 |
| NRA 500-1000y | 63.50 | 190.50 | 381.00 | 609.60 | 914.40 |
| DCRA SR | 35.00 | 70.00 | 140.00 | 210.00 | 300.00 |
| DCRA MR | 80.01 | 160.00 | 329.97 | 499.99 | 659.99 |
| DCRA LR | 127.51 | 254.99 | 407.49 | 559.99 | 914.41 |

---

## 3. Discrepancies: Source vs ROADMAP §15

**Flag for the record — source wins.**

| Item | ROADMAP §15 says | Source says | Resolution |
|------|-----------------|-------------|------------|
| NRA 300y 5-ring diameter | 78mm | 152.4mm (3.0" × 2 × 25.4) | Source: much larger (Figure 11/12 faces) |
| NRA 300y outer diameter | 560mm | 1117.6mm (22" × 2 × 25.4) | Source wins |
| NRA V-bull ratio | 0.6 × 5-ring | 0.333 × 5-ring (1.0/3.0) | Source wins |
| DCRA SR 300m outer diameter | 420mm (if radii) / 840mm (if diameters) | 600mm (11.811" × 2 × 25.4) | Source wins |
| 400y/400m distance | "derive as 4/3 × 300" | Not in source | Gap — defer, source ships without 400y/m |

---

## 4. Coordinate System

**Python source:** Origin=centre, x=right (windage), y=DOWN (SVG/canvas convention).
Scale factor `mu` = SVG units per MOA; all coordinates in SVG units.

**Flutter model (per ROADMAP §3):** Origin=centre, x=right (windage), y=UP (mathematical).
All coordinates in **millimetres**. y is flipped for screen painting only.

**Impact on importer:** legacy SVG x,y must be converted to mm and y flipped:
```
x_mm = svgX * (outerRadiusMm / svgR)   // svgR = 150.0 in source
y_mm = -svgY * (outerRadiusMm / svgR)  // flip y
```

**MOA size at distance (mm):**
```
// yards distance
moaSizeMm = yards * 0.01047 * 25.4  = yards * 0.26594 mm/MOA
// metres distance (convert to yards first)
moaSizeMm = metres * 1.09361 * 0.01047 * 25.4 = metres * 0.29096 mm/MOA
```

---

## 5. Scoring Function

```python
def score_shot(x, y, rings):
    d = math.hypot(x, y)  # distance from centre in SVG units
    for ring in rings:     # rings ordered V→5→4→3→2 (innermost first)
        if d <= ring["r"]:
            return ring
    return {"sc": 0, "iv": False, "lb": "M"}  # miss
```

Edge rule: `d <= ring["r"]` — touching the line awards the higher value (inward gauging).
No separate gauge tolerance in source (default 0 per ROADMAP).

---

## 6. Sighter Conversion Logic

Sequence always: sighter A → sighter B → scored shots (tp="A", "B", "sc").

| conv | B counts? | A counts? | max scored shots | shot label offset |
|------|-----------|-----------|-----------------|-------------------|
| "none" | no | no | shoot_len | 1 |
| "b" | yes (shot 1) | no | shoot_len − 1 | 2 |
| "ab" | yes (shot 2) | yes (shot 1) | shoot_len − 2 | 3 |

**Phase detection** (what shot comes next):
```python
if n == 0: next = "A"
if n == 1: next = "B"
else:
    sc_count = count(tp=="sc")
    converted = 0|1|2 per conv
    max_sc = shoot_len - converted
    if sc_count >= max_sc: done
    else: next scored shot
```

**Total calculation:**
- scoring = first `max_sc` shots with tp=="sc"
- extra = B (if conv in b/ab) prepended, then A (if conv==ab) at front
- total = sum(sc for all_shots); V = count(iv for all_shots)

Conversion becomes available after 2 shots are placed and before the 3rd is placed.
`conv_chosen = True` locks the conversion (first scored shot triggers lock).

---

## 7. Dial-To Formula

```python
mean_x = mean(shot["x"] for all shots in current string)
mean_y = mean(shot["y"] for all shots)   # y=DOWN in source
w_rec = clamp(snap(wind_val - mean_x / mu))
e_rec = clamp(snap(elev_val + mean_y / mu))  # +y/mu because y=DOWN
```

**Flutter equivalent** (y=UP, mm model):
```dart
final meanXmm = shots.map((s) => s.xMm).average();
final meanYmm = shots.map((s) => s.yMm).average();  // y=UP
final wRec = clamp(snap(windVal - meanXmm / moaSizeMm));
final eRec = clamp(snap(elevVal - meanYmm / moaSizeMm));  // minus, not plus
```

Uses ALL shots (sighters + scored), not just scored shots.
snap = round to nearest 0.25; clamp = ±200.

---

## 8. Graph Series Formula

Per-shot suggested correction (Python):
```python
# y=DOWN in source → e + y/mu increases elev when shot is low (y>0 canvas)
wind_sug = shot["w"] - shot["x"] / mu
elev_sug = shot["e"] + shot["y"] / mu
```

**Flutter equivalent** (y=UP):
```dart
windSug = shot.dialedWind - shot.xMm / moaSizeMm;
elevSug = shot.dialedElev - shot.yMm / moaSizeMm;  // minus because y=UP
```

Graph: elevation graph shows shots left→right, elev on vertical axis. Wind graph shows shots top→bottom, wind on horizontal axis. Both centred on shot 1's suggested value.

---

## 9. §8 Open Question Resolutions

1. **Ring constants:** Use source inch radii converted to mm. ROADMAP §15 values are cross-references only and are inaccurate for NRA; source wins.

2. **Distance list:** NRA: 300y, 500–1000y. DCRA yards: 300y, 500–1000y. DCRA metric: 300m, 500–1000m. **No 400y/m in source.** ROADMAP mentions deriving 400 as 4/3×300 but source doesn't implement it — deferred.

3. **Internal unit in source:** SVG units (not mm). Flutter model uses mm. Importer converts via `× (outerRadiusMm / 150.0)` on x, and flips y.

4. **Legacy persistence shape:**
   - `scorecards.json`: `[{shots, cv, dist, mu, shoot_len, target_number, saved_at}]`
   - `session.json`: `{shots, conv, conv_chosen, active_dist, wind_val, elev_val, target_number}`
   - `settings.json`: `{show_rec, show_graphs, shoot_len, active_dist}`
   - `presets.json`: `{dist_key: {aperture, elevation}}`
   - Shot fields: `x, y, sc, iv, lb, tp, w, e, cl`

5. **Drag-and-drop flavour:** Finger-down = provisional marker (immediately draggable), finger-up = commit to current position. While dragging: magnifier loupe with crosshair offset above fingertip. Long-press existing marker = re-drag. Tap-only fallback (no drag needed, commit on tap-up). Undo/redo stack for place/move/delete/convert.

6. **Dial-to formula:** Documented above (§7). y-flip required vs source because model is y=UP.

---

## 10. Increment Ladder

**Phase 1 status: COMPLETE.** All 16 increments shipped. `flutter analyze` clean; 110 tests passing (1 widget + 109 core).

Each increment: implement → `flutter analyze` clean → `flutter test` green → visual check (if UI) → commit.

| # | Increment | Status |
|---|-----------|--------|
| 1 | Scaffold monorepo; CLAUDE.md; CI | ✅ |
| 2 | Core: coordinate system + MOA math | ✅ |
| 3 | Core: TargetFace / Ring models; seed NRA + DCRA (21 faces) | ✅ |
| 4 | Core: scoring + sighters + V-bull | ✅ |
| 5 | Core: group mean, dial-to, graph series | ✅ |
| 6 | App: static target painter | ✅ |
| 7 | App: zoom/pan controller | ✅ |
| 8 | App: dynamic painter + shot placement + undo | ✅ |
| 9 | App: shot-call entry, dial state + snap, apply | ✅ |
| 10 | App: live scorecard panel + totals/V-count | ✅ |
| 11 | App: wind + elevation graphs | ✅ |
| 12 | Data: drift schema v1–v4 + repositories + draft save/restore | ✅ |
| 13 | App: scorecard list + analysis view (canvas, ES/MR, call breakdown, graphs, shot table) | ✅ |
| 14 | App: options (toggles, shoot length) + sight presets (save/apply/delete, aperture field) | ✅ |
| 15 | App: distance/standard select + menu (resume draft) + responsive layout | ✅ |
| 16 | Target number prompt on commit; show/hide rec & graphs toggles; autoDispose scorecards provider | ✅ |

**Phase 2 additions (beyond Phase 1 scope):**

| Item | Status |
|---|---|
| `Ring.score` → `double`; `ScoringMode` enum seam | ✅ |
| ISSF 10 m air rifle face (22nd face); decimal scoring algorithm (10.9 inner-10) | ✅ |
| DB schema v3: `aperture` on `sight_presets` | ✅ |
| DB schema v4: `owner_id` on both tables | ✅ |
| Supabase auth: `AuthNotifier`, `AppAuthState`, `AuthStatus` | ✅ |
| First-run screen, sign-in screen, sign-up screen | ✅ |
| go_router async redirect guard | ✅ |
| Options ACCOUNT section (sign in / sign out from settings) | ✅ |
| Menu screen auth status display | ✅ |
| PowerSync offline sync | ⏳ next |

---

## 11. Architecture Decisions (locked)

- Monorepo: `packages/targetsheet_core/` (pure Dart) + `target_sheet_flutter/lib/` (Flutter app)
- Model space: mm, origin centre, x=right, y=UP. Screen = model × transform (y flipped).
- State: Riverpod 2 (ProviderScope at root)
- Routing: go_router
- Models: freezed + json_serializable (add in Increment 3+)
- Local DB: drift (add in Increment 12)
- Every persisted row: UUID + created_at + updated_at + format_version (add in Increment 12)
- Scorecard is a separate entity from the target-sheet plot (even in Phase 1)
- TargetFace is data ({radiusMm, value, label, isTiebreak} per ring + aimingMarkRadiusMm + scoringMode)
- Decimal scoring mode + X/inner-ten tiebreak exist as typed enum seams (unimplemented branches)
- No backend / auth / tournament / coaching code or dependencies added in Phase 1
