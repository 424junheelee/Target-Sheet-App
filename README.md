# TargetSheet

**A fullbore target-rifle scoring and analysis app for DCRA / NRA shooters.**

---

## Migration status

The original Python/Tkinter proof-of-concept has been fully ported to Flutter.
The Flutter app is now the primary development target.

| Phase | Status | Notes |
|---|---|---|
| Phase 1 — Local-first core (Flutter port) | **Complete** | Full feature parity with Tkinter + extras |
| Phase 2A — Decimal scoring (ISSF 10 m) | **Complete** | Air rifle face, inner-10 decimal algorithm |
| Phase 2B — Supabase auth + account sync | **Complete** | Auth screens, offline mode, Settings sign-in |
| Phase 2C — PowerSync offline sync | Pending | Local DB is sync-ready; PowerSync not yet wired |
| Phase 3+ — Shared scorecard / register-keeping | Planned | See ROADMAP.md |

---

## Flutter app (`target_sheet_flutter/`)

The primary app. Cross-platform (Windows, macOS, Linux, iOS, Android, web).

### What's built

- **Live target canvas** — plot shots on any regulation face; zoom and pan with pinch/scroll; drag-to-place with real-time scoring
- **22 target faces** — NRA (UK Bisley) Fig 11/12, ICFRA TR (DCRA) in yards and metres at 300–1000, plus ISSF 10 m air rifle
- **Decimal scoring** — ISSF inner-10 mode (10.9 at centre, −0.1 per 0.25 mm out) for the air rifle face
- **Sighters with conversion** — A/B sighters; convert none/B/A+B into scored count; labels and totals update automatically
- **Dial-to recommendation** — computes the wind/elevation that would centre your group; one-tap apply
- **Wind & elevation graphs** — per-shot suggested-correction graphs, live during shooting and in the analysis view
- **Shot calls** — annotate each shot (↑↓←→ ✓✕)
- **Draft auto-save** — in-progress string survives an app restart
- **Scorecard list** — saved strings with score totals and V-bull counts; tap to open analysis
- **Analysis view** — interactive zoom/pan target canvas, extreme spread, mean radius (both in MOA), call breakdown, shot table, and ballistic graphs per saved string
- **Sight presets** — save wind/elevation/aperture per target face; one-tap apply
- **Options** — default match length (10/15), show/hide dial-to and graphs toggles
- **Auth / sync** — Supabase Auth integration; sign up, sign in, offline mode; "Sign in later" from Options; `owner_id` on all rows for future PowerSync sync

### Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.44.3 / Dart 3.12.2 |
| State | Riverpod 2 (`AsyncNotifier` / `ConsumerWidget`) |
| Routing | go_router |
| Local DB | drift + SQLite (`targetsheet.db`) |
| Auth | supabase_flutter 2.15 |
| Offline flag | shared_preferences |
| Core logic | `packages/targetsheet_core/` (pure Dart, no Flutter) |

### Repository layout

```
target_sheet_flutter/
├── lib/
│   ├── auth/              auth provider + prefs helpers
│   ├── data/              drift database, scorecard & preset repositories
│   ├── providers/         session state, options state
│   ├── rendering/         target painter, shot painter, graph painter, view controller
│   ├── screens/
│   │   ├── auth/          first-run, sign-in, sign-up screens
│   │   ├── menu/          main menu
│   │   ├── options/       options + sight presets
│   │   ├── scorecard_list/ list + analysis view
│   │   ├── select/        distance / standard picker
│   │   └── shoot/         live shoot screen + target canvas
│   ├── router.dart        go_router config with auth redirect
│   └── main.dart          Supabase.initialize + ProviderScope
└── packages/
    └── targetsheet_core/  pure Dart — scoring, geometry, analysis, disciplines
        ├── geometry/       MOA math, model ↔ screen transforms
        ├── disciplines/    TargetFace models + all 22 face definitions
        ├── scoring/        ring scoring, sighter conversion, dial-to
        └── analysis/       group stats, graph series, windLabel/elevLabel
```

### Running locally

```bash
cd target_sheet_flutter
flutter pub get
flutter run -d windows   # or macos / linux / chrome
```

Supabase credentials are in `lib/main.dart`. The app works fully offline — first-run offers "Use offline" which skips auth entirely. Supabase is only required for cross-device sync.

### Tests

```bash
cd target_sheet_flutter
flutter test                               # widget tests
cd packages/targetsheet_core
dart test                                  # 109 unit tests
```

### Coordinate system (invariant)

- **Model space:** real-world millimetres, origin = target centre, x = right (windage), y = UP (elevation).
- **Screen space:** `Matrix4` transform applied at paint time flips y and applies scale + pan.
- Units (yd/m, inch, MOA) are display-only converters. Stored values are always mm.

---

## Python reference app (`TargetSheet/`)

The original Tkinter proof-of-concept. **Do not modify.** It remains in the repository as the authoritative reference for ring geometry constants, scoring edge cases, and algorithm behaviour. The CLAUDE.md invariant applies: _the Python source wins over ROADMAP §15 and this file for any constant or algorithm_.

### Running

```bash
python TargetSheet/target_sheet.py
```

Requires Python 3.8+ with Tkinter (included in the standard library on Windows and macOS).

---

## Key documents

| File | Purpose |
|---|---|
| `CLAUDE.md` | Coding principles and conventions for all agents and contributors |
| `ROADMAP.md` | Full product vision and phase map (Phases 1–6 + Coaching) |
| `PLAN.md` | Phase 1 source inventory, ring constants, algorithm details, increment ladder |

---

## License

No license has been specified for this project.
