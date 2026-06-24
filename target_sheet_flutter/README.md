# TargetSheet — Flutter

Flutter rewrite of the TargetSheet fullbore target-rifle scoring app.
See the [root README](../README.md) for project overview and migration status.

## Getting started

```bash
flutter pub get
flutter run -d windows   # or macos / linux / chrome
```

Supabase credentials live in `lib/main.dart`. The app works fully offline — choose "Use offline" at first launch to skip auth.

## Project structure

```
lib/
├── auth/
│   └── auth_provider.dart         AuthNotifier, AppAuthState, prefs helpers
├── data/
│   ├── database.dart              drift schema (Scorecards, SightPresets) — schema v4
│   ├── database.g.dart            drift generated
│   ├── scorecard_repository.dart  CRUD + draft save/restore + JSON serialisation
│   └── sight_preset_repository.dart
├── providers/
│   ├── session_provider.dart      ShootSessionNotifier — shots, dials, undo, commit
│   └── options_provider.dart      OptionsNotifier — showRec, showGraphs, shootLen
├── rendering/
│   ├── target_painter.dart        rings, aiming mark, MOA grid
│   ├── shot_painter.dart          shot markers + labels
│   ├── graph_painter.dart         ElevGraphPainter + WindGraphPainter
│   └── view_controller.dart       zoom/pan Matrix4 state
├── screens/
│   ├── auth/
│   │   ├── first_run_screen.dart  first-launch choice (sign in / offline)
│   │   ├── sign_in_screen.dart
│   │   └── sign_up_screen.dart
│   ├── menu/menu_screen.dart      main menu + resume draft
│   ├── options/options_screen.dart  options + sight presets + account section
│   ├── scorecard_list/scorecard_list_screen.dart  list + full analysis view
│   ├── select/select_screen.dart  distance / standard picker
│   └── shoot/
│       ├── shoot_screen.dart      wide/narrow layouts, control panel, dial-to row
│       └── target_canvas.dart     interactive shot-placement canvas
├── router.dart                    go_router + async first-run redirect
└── main.dart                      Supabase.initialize + ProviderScope

packages/targetsheet_core/lib/
├── geometry/
│   └── moa_calculator.dart        moaSizeAtYards(), moaSizeAtMetres()
├── disciplines/
│   ├── ring.dart                  Ring model (score: double, isVbull, label, radiusMm)
│   ├── target_face.dart           TargetFace model + ScoringMode enum
│   └── target_faces.dart          kTargetFaces — 22 faces (NRA, DCRA yd/m, ISSF 10m)
├── scoring/
│   └── scoring.dart               scoreShot(), calcTotal(), nextShotType(),
│                                  shotDisplayLabels(), dialToRecommendation()
└── analysis/
    └── analysis.dart              computeGroupStats(), callBreakdown(),
                                   graphSeries(), windLabel(), elevLabel()
```

## Database schema (drift, SQLite)

Schema version 4. File: `<documents>/targetsheet.db`

| Table | Key columns |
|---|---|
| `scorecards` | `id` TEXT PK (UUID), `face_id`, `conversion`, `shoot_len`, `target_number`, `shots_json`, `owner_id` TEXT nullable |
| `sight_presets` | `id` TEXT PK (UUID), `face_id`, `wind_moa`, `elev_moa`, `label`, `aperture`, `owner_id` TEXT nullable |

All rows carry `created_at`, `updated_at`, `format_version` (sync-ready per PLAN.md §invariant).

## Auth flow

1. **First launch** → `FirstRunScreen` → user chooses "Sign in / Create account" or "Use offline"
2. **Offline chosen** → `auth_offline_mode = true` stored; app continues; no Supabase calls
3. **Sign in / Sign up** → Supabase email+password; `auth_first_run_done = true`, `auth_offline_mode = false`
4. **Sign in later** → Options screen → ACCOUNT section → "Sign in / Create account" button
5. **Sign out** → Options screen → ACCOUNT section → "Sign out"; returns to `signedOut` state; no first-run repeat
6. **App restart** — active Supabase session wins over stale offline preference (auto-corrects pref)

## Supabase setup (required for cloud sync)

Run once in Supabase SQL Editor — see the setup SQL block in the project for the full schema (tables: `scorecards`, `sight_presets`, `shooter_profiles`; RLS policies; `handle_new_user` trigger). PowerSync integration is the next step (Phase 2C).

## Tests

```bash
# Core unit tests (109 tests)
cd packages/targetsheet_core && dart test

# App widget tests
flutter test
```

## Architecture invariants

- **Core/app boundary**: everything that is pure logic lives in `packages/targetsheet_core/` with no Flutter or I/O imports.
- **Coordinate system**: model space = mm, origin = target centre, x = right, y = UP. The y-flip is applied only at paint time via `Matrix4`.
- **Scoring mode**: `ScoringMode.integer` for fullbore (score is a `double` with `.0` fractional part); `ScoringMode.decimal` for ISSF air rifle (score is 10.9 → 10.0 in 0.1 steps).
- **No speculative features**: nothing beyond the current phase scope is added. Phase 3+ items (register-keeping, squadding, dual attestation) are not stubbed in.
