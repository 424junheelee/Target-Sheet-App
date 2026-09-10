[README.md](https://github.com/user-attachments/files/28922311/README.md)
# TargetSheet

**A desktop app for recording and analysing fullbore target-rifle strings.**

TargetSheet is a [Tkinter](https://docs.python.org/3/library/tkinter.html) application for DCRA / NRA fullbore marksmanship. It lets you plot each shot on a regulation target face, track the wind and elevation you've dialled, get a "dial-to" correction that would centre your group, and review finished strings on a scorecard with per-shot wind & elevation graphs.

It covers all standard **Bisley yard distances (300–1000 y)** and **DCRA metric distances (300–1000 m)**, with correct **NRA** and **ICFRA** ring sizes for each distance.

---

## Features

- **Live target face** — plot shots on a regulation target with an MOA grid, scoring rings, and shot markers. Zoom and pan the canvas.
- **Two scoring standards** — NRA (UK, Bisley) Figure 11/12 faces and ICFRA TR faces (used by DCRA), in both yards and metres.
- **Sighters with conversion** — fire Sighter A and Sighter B, then convert none / B / A+B into your scored string, with the shot count and totals adjusting automatically.
- **Dial-to recommendation** — TargetSheet computes the wind/elevation that would have centred your current group and offers to apply it.
- **Wind & elevation graphs** — per-shot suggested-correction graphs alongside the target, both live while shooting and on the finished scorecard.
- **Shot calls** — annotate each shot (pull high/low/left/right, good, bad).
- **Scorecard** — saved strings shown as per-string cards with aggregate totals and V-bull counts; discard in-progress or delete saved strings.
- **Analysis view** — replay any saved string on an interactive target with statistics and finished graphs.
- **Sight presets** — save aperture/elevation settings per distance configuration.
- **Match length** — choose 10- or 15-shot strings.

---

## Requirements

- **Python 3.8+**
- **Tkinter** — ships with the Python standard library. It's included by default on Windows and macOS. On some Linux distributions you may need to install it separately (e.g. `sudo apt install python3-tk`).

No third-party packages are required.

---

## Running

The application code lives in the `TargetSheet/` folder. From the repository root:

```bash
python TargetSheet/target_sheet.py
```

That's the only entry point — it launches the GUI.

---

## Testing

The test suite covers scoring and target geometry, sighter conversion and
totals, the dial recommendation, persistence, and every screen's render path.
It drives a real Tk instance with the main loop suppressed, and redirects
storage to a temporary directory so your saved scorecards are never touched.

```bash
python -m pytest
```

Requires `pytest`. Tests are skipped automatically where no display is
available.

---

## Data storage

Scorecards, the in-progress session, options and sight presets are saved as
JSON in a per-user directory:

| Platform | Location |
|---|---|
| Windows | `%APPDATA%\TargetSheet\` |
| macOS | `~/Library/Application Support/TargetSheet/` |
| Linux | `$XDG_DATA_HOME/TargetSheet/` (or `~/.local/share/TargetSheet/`) |

Writes are atomic, and unreadable files fall back to defaults rather than
stopping the app from starting.

---

## Usage

1. **Main menu** — choose a distance, view the scorecard, open options, or resume an in-progress string.
2. **Select distance** — pick a distance and standard (e.g. `600y — NRA / Bisley`, `700m — DCRA (ICFRA metric)`).
3. **Shoot the string:**
   - Fire **Sighter A**, then **Sighter B**, then your scored shots.
   - Tap on the target face to place each shot; it's scored automatically by which ring it lands in.
   - Adjust the **wind** and **elevation** dials as you go (values snap to 0.25 increments).
   - Optionally choose a **conversion** (convert B, or A+B, into the scored count).
   - Use the **dial-to recommendation** to centre your group, and add **shot calls** as needed.
4. **Save to Scorecard** — commit the finished string.
5. **Scorecard** — review per-string cards and aggregate totals; tap a string to open **Analysis**.
6. **Options / Presets** — toggle the recommendation and the wind & elevation graphs, set match length, and save per-distance sight presets.

### Key concepts

- **Sighters & conversion.** Every string starts with two sighters (A, B). The *conversion* setting controls whether none, just B, or both A+B count toward your total — the scored-shot count and labels update to match.
- **Scoring.** A shot's score is the innermost ring that contains it (`V`/`5`/`4`/`3`/`2`, or `M` for a miss). `V` counts as 5 points and is tracked separately as a V-bull.
- **Dial-to recommendation.** From the mean position of your current group, TargetSheet computes the wind/elevation that would have centred it (using MOA-per-distance scaling) and can apply it to your dials.
- **Wind & elevation graphs.** Each graph plots, per shot, the *suggested* correction that would have centred that shot — a quick visual read on how your group is trending.

---

## Supported targets

Ring sizes are sourced from NRA (UK) TR Figure 11/12, the ICFRA TR Technical Rules (2019), and NRAA targets & scoring documentation.

| Standard | Distances | Target face |
|----------|-----------|-------------|
| **NRA / Bisley** | 300y (Fig 11), 500–1000y (Fig 12) | NRA TR yard faces |
| **DCRA (ICFRA)** — yards | 300y, 500–1000y | ICFRA short/mid/long-range faces on Bisley yard distances |
| **DCRA (ICFRA metric)** | 300m, 500–1000m | ICFRA faces at DCRA domestic (Connaught) distances |

Each distance maps to the correct ICFRA face band — short range (~300 m), mid range (~500–600 m), or long range (~700 m+).

---

## Project structure

TargetSheet is a single Tkinter app split into small, focused modules. The UI is composed from **mixin classes** — one per screen — that are combined into the single `TargetSheetApp`.

```
TargetSheet/
├── target_sheet.py   # Entry point — launches TargetSheetApp
├── app.py            # TargetSheetApp: state, navigation, scoring/string logic, options
├── constants.py      # Target geometry, canvas scale, colour palette
├── scoring.py        # Pure scoring/formatting helpers + shot-call glyphs
├── targets.py        # Ring specs, TARGET_CONFIGS, build_dist_config()
├── graphs.py         # Shared ballistic-graph drawing (wind / elevation)
└── views/            # Per-screen UI mixins
    ├── menu.py       # MenuMixin       — main menu + distance/match-length select
    ├── target.py     # TargetMixin     — live target face, controls, ballistic graphs
    ├── scorecard.py  # ScorecardMixin  — saved series cards, discard/delete
    ├── analysis.py   # AnalysisMixin   — per-series interactive target + finished graphs
    └── settings.py   # SettingsMixin   — options + saved presets
```

### Architecture

`TargetSheetApp` ([app.py](app.py)) inherits from all five view mixins:

```python
class TargetSheetApp(MenuMixin, TargetMixin, ScorecardMixin,
                     AnalysisMixin, SettingsMixin):
    ...
```

All **application state** lives on the `TargetSheetApp` instance; each mixin only contributes the methods that build and drive one screen, reading and writing that shared state via `self`. Every screen frame is built once at startup and shown/hidden by name through `show_screen()`.

> **Note:** because the mixins reference attributes defined on sibling mixins, a static type checker analysing one mixin in isolation will report "unknown attribute" warnings. These are expected with this composition pattern and aren't runtime errors.

### Data model

A **shot** is a dict:

| Field | Type | Meaning |
|-------|------|---------|
| `x`, `y` | float | Target (SVG) coordinates of the shot |
| `sc` | int | Score (0–5) |
| `iv` | bool | True if a V-bull |
| `lb` | str | Score label (`V`/`5`/`4`/`3`/`2`/`M`) |
| `tp` | str | Shot type: `A` \| `B` \| `sc` |
| `w`, `e` | float | Wind / elevation dialled at the time of the shot |
| `cl` | str \| None | Shot-call key, or None |

A **string** bundles its shots with the conversion setting (`cv`), distance key (`dist`), MOA scale (`mu`), and match length.

---

## Notes & limitations

- **In-memory only.** Strings, presets, and options live in memory for the current session — there is no save-to-disk persistence yet. Closing the app clears recorded strings.
- **Desktop GUI.** The window is sized for a tablet-style layout (default 1080×720, min 940×640).

---

## License

No license has been specified for this project.
