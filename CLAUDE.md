# TargetSheet — CLAUDE.md

Coding principles and project conventions for all agents working in this repo.

---

## Karpathy Principles (non-negotiable)

### 1. Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.
- State assumptions explicitly before implementing.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so.
- If something is unclear, stop, name what's confusing, and ask.

### 2. Simplicity First
Minimum code that solves the problem. Nothing speculative.
- No features beyond the current phase.
- No abstractions for single-use code.
- No "flexibility" or "configurability" nobody asked for.
- No error handling for impossible states.
- If you write 200 lines and it could be 50, rewrite it.

Exception: the required scaffolding explicitly called out in the ROADMAP §6 (UUIDs,
format_version, data-driven TargetFace, decimal-mode enum seams) is Phase 1 work,
not speculation.

### 3. Surgical Changes
Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting.
- Match existing style within a file even if you'd do it differently.
- Remove only orphans YOUR change created.
- Never leave dead/commented-out code.

### 4. Goal-Driven Execution
Define success criteria. Loop until verified.
- Every increment has a verifiable check (test or observable).
- `flutter analyze` and `flutter test` must be green before moving to the next increment.
- Never declare done until the check passes.

---

## Project Conventions

### Repository layout
```
Target-Sheet-App/
├─ TargetSheet/              # Python/Tkinter source — reference only, do not modify
├─ target_sheet_flutter/     # Flutter monorepo root
│  ├─ packages/
│  │  └─ targetsheet_core/   # Pure Dart — NO Flutter import, NO I/O
│  ├─ lib/                   # Flutter app (rendering, screens, state, data)
│  ├─ test/                  # App widget + golden tests
│  └─ pubspec.yaml
├─ ROADMAP.md                # Authoritative product plan
├─ PLAN.md                   # Source inventory + §8 resolutions (this build)
└─ CLAUDE.md                 # This file
```

### Coordinate system (invariant)
- **Model space:** real-world millimetres, origin = target centre, x = right (windage), y = UP (elevation).
- **Screen space:** painter applies `Matrix4` transform that flips y and applies scale + pan. y is never
  stored flipped — only flipped at paint time.
- Units (yd/m, inch, MOA) are display-only converters. Never store converted values.

### Core vs app boundary (invariant)
Everything that is pure logic — geometry, scoring, sighter/conversion, dial-to, graph series, models — lives
in `packages/targetsheet_core/` with no Flutter or I/O imports.
The app package (`lib/`) owns rendering, interaction, state (Riverpod), screens, and data (drift).

### Sync-ready persistence (invariant from day one)
Every persisted row carries: `id` (UUID v4), `createdAt`, `updatedAt`, `formatVersion`.
Local store is drift/SQLite — the same engine PowerSync will use for Phase 2 offline sync.

### TargetFace is data, not code (invariant)
Ring geometry is a `TargetFace` value object seeded from `packages/targetsheet_core/lib/disciplines/`.
No hard-coded ring values in painters or scoring logic.

### Phase 1 scope guard
Do **not** add: backend, Supabase, PowerSync, auth, sharing, tournaments, squadding, air rifle /
decimal scoring, F-Class, register-keeping. If you find yourself wanting a dep for any of these,
you have left Phase 1 — stop and flag it.

### Toolchain
- Flutter stable 3.44.3 / Dart 3.12.2
- State: flutter_riverpod ^2.x (ProviderScope at root)
- Routing: go_router
- Models: freezed + json_serializable (added in Increment 3+)
- DB: drift (added in Increment 12)
- Lints: flutter_lints / lints; warnings treated as errors in CI

### Source of truth for behaviour
`/TargetSheet/` Python source wins over ROADMAP §15 and this file for any constant or algorithm.
Document any discrepancy in PLAN.md §3 before coding the Flutter version.
