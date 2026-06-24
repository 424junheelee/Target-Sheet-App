TargetSheet — Complete Product Roadmap & Implementation Plan
A top-to-bottom plan to take TargetSheet from a single-user Python proof-of-concept to a multi-user, offline-first fullbore target-rifle platform with digital scorecards, register-keeping, squadding, and results — purpose-built for Bisley-style fullbore.

0. Document status & how to use this
Audience: the developer/owner and any coding agent that implements the work.
Authority of the existing repo: the current Python app (Target-Sheet-App, branch feature/persistent-local-storage) is the source of truth for the exact geometry constants, scoring ladder, sighter/conversion behaviour, and dial-to maths that ship today. This document was assembled from the repo's README, a photo of a DCRA 300 m score sheet, governing-body dimension specs (ICFRA / NRA UK / ISSF), and a tournament research brief. Wherever this plan states a constant or an internal behaviour, the coding agent must diff it against the actual source and prefer the repo, reporting any mismatch. (The source files could not be opened directly during planning; treat §15 dimension tables as a cross-check, not gospel.)
How to consume: §1–§5 are orientation (vision, scope, architecture, the phase map). §6–§12 are the phases in execution order, each with its own checklist. §13–§17 are shared reference (data model, tournament domain rules, dimension tables, testing, ops). §18 is the consolidated risk/assumptions/open-questions register.
Phases are independently shippable. A later agent may resequence; the dependencies are called out so that's safe.
1. Product vision & scope decision
Vision. A shooter plots and scores their string on a regulation target on their phone/tablet; a squadded neighbour keeps their card digitally with a proper signature chain; a match organiser squadds the detail, collects the cards, and publishes rankings — all working with no connectivity on the mound and syncing when back in range of wifi.

The niche (why this is worth building). General match-management tools (PractiScore for practical, ScoresR/Scopos for clays, etc.) are mature and offline-first, but none natively model Bisley-style fullbore: convertible sighters, V-bull tiebreaks, the pass-right mutual register-keeping rotation, the team-separation squadding constraint, and DCRA/NRA tie & countback rules. That is a genuinely open lane. TargetSheet's defensible core is the digital scorecard + register-keeping + squadding + stats layer for fullbore ranges that still shoot paper + butt markers (the majority of club/regional DCRA & NRA shoots), and a useful admin layer even where electronic targets exist.

Scope decision (confirmed with the shooting contact):

Primary discipline: fullbore Target Rifle — ICFRA TR / NRA (UK Bisley) / DCRA, yards and metres, 300–1000. This is the whole point of the app.
F-Class is fullbore-adjacent (same ranges/association, ICFRA F-class scoring) and is treated as a low-cost in-family addition, not a priority.
Secondary discipline: ISSF 10 m air rifle — the one "different" discipline we commit to, because it's small-footprint, indoor, junior-friendly, and exercises decimal scoring. Added in Phase 2, not before.
Explicitly out of scope (for now): smallbore, ISSF 50 m, benchrest, 3-position, silhouette, pistol. Other disciplines have materially different tournament logistics; trying to generalise tournament mode across all of them is where complexity explodes.
Tournament features are fullbore-only. Air rifle gets the plotting/scoring/coaching surface but not (initially) the squadding/register-keeping machinery, whose rules are fullbore-specific.
One app or separate organiser tool? Build one Flutter app with role-based UI (shooter / register-keeper / coach / organiser) on top of a shared backend. The backend (Supabase) is the API, so a separate organiser web dashboard or third-party integration can be added later against the same data without a bespoke API server. Don't build a standalone TO app or a custom API service yet — extract one only if/when an organiser web product justifies it (revisit at Phase 5).

2. Current state (the proof-of-concept)
The Python/Tkinter app already implements, for fullbore TR:

Live target face with MOA grid, scoring rings, shot markers; zoom & pan.
Two standards — NRA (UK Bisley) Fig 11/12 and ICFRA TR (DCRA) — in yards and metres, 300–1000, with correct ring sizes per distance.
Sighters A/B with conversion (none / B / A+B), auto-adjusting counts and totals.
Auto-scoring by ring (V/5/4/3/2/M); V-bull tracked separately.
Dial-to recommendation (wind/elevation to centre the group) with apply.
Per-shot wind & elevation graphs (live + finished).
Shot calls (pull high/low/left/right, good, bad).
Scorecard view (saved strings, aggregate totals, V-counts), Analysis replay with stats, sight presets per distance, match length 10/15, options.
feature/persistent-local-storage adds durable local storage (survives restart).
It is single-user, single-device, one discipline family, and the target sheet is the scorecard. The roadmap breaks each of those assumptions deliberately.

3. Target architecture
Layer	Choice	Rationale
Client	Flutter (Dart 3)	The app is fundamentally a custom-drawing app (plot shots on a face, zoom/pan, graphs); Flutter's CustomPainter/Impeller is the natural successor to the Tkinter canvas and is strongest exactly at canvas/animation workloads. One codebase → iOS + Android (+ web/desktop for an organiser dashboard later).
Shared logic	targetsheet_core pure-Dart package	All geometry, scoring, sighter/conversion, dial-to, squadding, ties/countback live UI-free and fully unit-tested — reused by the app, the backend validation, and any future web client.
State	Riverpod 2	Testable, BuildContext-free; one session state shared across plot/card/graphs.
Models	freezed + json_serializable	Immutable value types; the JSON form doubles as the sync/export schema.
Local DB	drift (SQLite)	Relational (matches card/shot/detail), and it's the same engine PowerSync uses — so the Phase-1 local store is the offline-sync store. No later migration.
Backend	Supabase (Postgres + Auth + Storage + RLS + Realtime + Edge Functions)	Relational fits scorecards/details/rankings; open-source, you own the data (portable Postgres); generous free tier; scales without a rewrite. Acts as the API.
Offline sync	PowerSync on Supabase	True offline-first: local SQLite ⇄ Postgres, upload queue, conflict resolution, sync rules controlling who-syncs-what. Ranges are offline; this is non-negotiable, and PractiScore proves the "works with no internet, syncs on wifi" model is the right one.
Identity/roles	Supabase Auth + RLS + PowerSync sync rules	One person can be shooter, register-keeper, coach, organiser; RLS expresses the privacy/custody model.
Three architectural invariants set in Phase 1 that make everything later additive:

Model space is real-world millimetres on the target face (origin centre, x=right, y=up). Pixels are a render-time projection only. Scoring is resolution-independent.
Every persisted row has a UUID id, created_at/updated_at, and format_version. Sync, sharing, and tamper-evidence all depend on this existing from day one.
The Scorecard is a distinct entity from the Target Sheet (plot). Even in single-user Phase 1 they are separate records linked by id — because in real matches the scorecard is a separate, organiser-issued, dual-signed document (see §14).
4. Cross-cutting foundations (build once, rely on everywhere)
Coordinate system & MOA math (Phase 1): mm-truth model; screen = model × scale × zoom + pan via one Matrix4 shared by painter and hit-testing; 1 MOA ≈ 29.1 mm/100 m (≈ 1.047″/100 yd) stored per distance, driving the MOA grid and all dial-to/correction conversions.
Discipline / TargetFace registry (Phase 1, extended Phase 2): targets are data ({radius_mm, value, label, isTiebreak} per ring + aiming-mark diameter + bounds + scoring mode + tiebreak token + course-of-fire), never hard-coded. Fullbore seeds ship in Phase 1; air rifle (decimal mode) is a data + small-code add in Phase 2.
Offline-first (from Phase 2): reads/writes hit local SQLite first; background sync; deterministic conflict resolution — critical for the two-device register-keeping flow.
Identity & RLS roles (from Phase 2): owner-only at first; sharing/custody policies layered in Phase 3+.
Shot provenance (Phase 1 base, Phase 3 extension): every shot stores not just a value but role (sighter A/B / scored), converted-or-not, and — added for tournaments — challenged-or-not and irregular-or-not. The card never silently averages an anomaly; it flags it.
5. Phase map (the whole roadmap at a glance)
Phase	Title	Goal	Depends on	Multi-user?
0	Identity & schema hardening	UUIDs, format_version, mm-truth model, Scorecard-as-entity — folded into Phase 1	—	no
1	Local-first core rebuild	Flutter port of today's app, feature parity + zoom + drag-and-drop, fullbore TR (NRA+ICFRA)	0	no
2	Infrastructure & accounts	Supabase + PowerSync + Auth; cloud backup; air rifle discipline	1	accounts, single-user data
3	Shared scorecard & register-keeping	Two-device firer+scorer, dual attestation + custody chain, pass-right rotation	2	yes (smallest tournament primitive)
4	Squadding engine & match setup	Competitor list → squadding lists; team-separation constraint solver; reflow	3	yes
5	Stats, results, ties/countback	Auto-aggregate across stages; DCRA/NRA tie rules; live results board	4	yes
6	Registration, entries, fees (optional)	Entry, cashiering, classification admin	5	yes
C	Coaching (parallel mini-phase)	Coach roster + cross-session analytics; can start any time after Phase 2	2	yes
Critical path for the niche is 3 → 4 → 5 (the register-keeping → squadding → stats chain no existing tool does for fullbore). Phases 1–2 are the foundation; Phase 6 and C are optional/parallel.

6. Phase 1 — Local-first core rebuild (the foundation)
Rebuild today's app as a Flutter app, local-only, feature-parity + zoom + drag-and-drop, fullbore TR only. This is the largest single phase.

6.1 Scope
In: live target face (rings, black aiming mark, MOA grid, markers, group); zoom+pan; drag-and-drop placement w/ magnifier; sighters A/B + conversion; auto-scoring + V-bull; shot calls; dial-to; wind/elev graphs; scorecard panel (the right-hand table from the DCRA sheet: SHOT/ELEV/WIND L-R/CALL/SCORE, rows A,B,1..N, TOTAL, V-count); scorecard list; analysis/replay; sight presets; options (10/15, toggles); local persistence; NRA + ICFRA TR standards, yd+m, 300–1000. Out (→ later): accounts, cloud, sharing, tournaments, air rifle, decimal scoring.

6.2 Project structure (monorepo, sync-ready)
targetsheet/
├─ packages/targetsheet_core/        # PURE DART, no Flutter/IO
│  ├─ geometry/      coordinate system, MOA math
│  ├─ disciplines/   Discipline/TargetFace/Distance/Ring + seed JSON
│  ├─ scoring/       ring-containment, sighters/conversion, V-bull
│  ├─ analysis/      group mean, dial-to, graph series
│  └─ models/        Shot, Series(String), Scorecard, ShotCall, SightPreset
├─ app/
│  ├─ rendering/     CustomPainters (target, grid, markers, graphs, loupe)
│  ├─ interaction/   zoom/pan, drag-place, undo stack
│  ├─ screens/       menu, distance-select, shoot, card-list, analysis, options
│  ├─ state/         Riverpod providers
│  └─ data/          drift DB, repositories, JSON import/export
└─ test/ + golden/
6.3 Coordinate system (do first)
Model = mm on the face, origin centre, x=right (windage), y=up (elevation). Projection via one shared transform; y flipped for screen. Units (yd/m, inch, MOA) are display-only converters; never stored.

6.4 Rendering (CustomPainter)
Draw order: scoring-area bounds → black aiming mark → scoring rings (real line widths) → MOA grid + centre cross → group/mean → shot markers (scored numbered, sighters A/B styled, selected highlighted) → loupe layer. Two painters with RepaintBoundary: static (face+grid, repaints on zoom/distance change only) and dynamic (markers/group/loupe). Painter consumes a TargetFace value object — never hard-coded numbers.

6.5 Core maths the package owns (each a pure, unit-tested function)
MOA linear size at range (grid + corrections).
Scoring: point→radius→innermost containing ring; edge-touch → higher value (inward gauging; tolerance param, default 0); outside 2-ring = M; V-bull/X flagged separately.
Sighters & conversion: none/B/A+B promote sighters into the scored sequence, renumbering and recomputing total + V-count (mirror the repo exactly).
Group mean & dial-to: mean of scored positions; correction = −mean / MOA-size, snapped to 0.25 MOA; "apply" shifts dial state, not the plotted shots.
Graph series: per shot, the wind & elevation correction (MOA) that would have centred that shot — two ordered series the graph painter consumes.
6.6 Interaction (the two explicit upgrades)
Zoom/pan: pinch + two-finger pan; double-tap zoom; on-screen +/−/fit; focal-point zoom; clamp zoom to [fit … N×] and clamp pan so the scoring area stays in view. Drag-and-drop placement (the finger-occludes-the-target problem):

Tap drops a provisional marker that's immediately draggable; not committed until confirm/next-shot, so always adjustable.
While dragging show a magnifier loupe and place the actual point at a fixed offset above the fingertip with a crosshair — essential where the V-bull is a few px wide.
Long-press a placed marker to grab/move; live re-score on move.
Tap a marker → edit (value auto, call, delete).
Undo/redo stack for place/move/delete/convert.
Keep tap-only as an accessibility fallback. Dials snap to 0.25.
6.7 Screens (mirroring the paper sheet)
Main menu → distance/standard select → Shoot view (target canvas + live scorecard panel + wind/elev graphs, sighter/conversion/dial-to/call/save controls) → scorecard list → analysis/replay → options/presets. Phone = tabbed; tablet = side-by-side paper-sheet layout.

6.8 Persistence (local, sync-ready) — see consolidated schema §13.
Drift/SQLite; every row UUID + timestamps + format_version. JSON export/import of a string now (backup + the exact artifact Phase 3 sharing will move). Import the repo's existing persisted shape if present (one-time importer) so current users' data carries over.

6.9 Testing — see §16. Scoring unit tests vs §15 tables are where correctness lives;
golden tests lock geometry.

6.10 Phase 1 build checklist (ordered)
Scaffold monorepo; targetsheet_core + app; CI (analyze + test).
Core: coordinates + MOA math + tests.
Core: Discipline/TargetFace/Distance/Ring models; seed ICFRA TR + NRA TR (§15, reconciled with repo).
Core: scoring + sighters/conversion + V-bull; full tests vs §15.
Core: group mean, dial-to, graph series + tests.
App: static target painter + golden tests.
App: zoom/pan controller (focal zoom, clamping, fit/+/−).
App: dynamic painter + drag-and-drop + loupe + undo/redo.
App: shot-call entry, dial state + 0.25 snap, dial-to apply.
App: live scorecard panel + running total/V-count.
App: wind & elevation graphs (live).
Data: drift schema + repositories + persistence; resume-in-progress; legacy import.
App: scorecard list + analysis/replay (finished graphs + stats).
App: options + sight presets.
App: distance/standard select + menu; responsive layouts.
JSON export/import; accessibility (tap-only, large-touch); polish; store-readiness.
Demo-able MVP cut: steps 1–10 (plot a string on a correct face with zoom+drag and a live card) is already a better-than-Python app.

7. Phase 2 — Infrastructure & accounts (the "spin up the backend" phase)
Two parallel tracks, both additive on Phase 1.

7.1 Track A — air rifle discipline (data + small code)
Add ISSF 10 m air rifle: total Ø 45.5 mm, rings 1–10 at 2.5 mm radial spacing, 10-ring Ø 0.5 mm, 9-ring Ø 5.5 mm, black aiming area (4-ring) Ø 30.5 mm; decimal scoring (inner-10 dot radius 0.25 mm; 10.9 max; −0.1 per 0.25 mm from centre) and an X/inner-ten tiebreak. This turns on the decimal mode + tiebreak enums stubbed in Phase 1; new TargetFace + golden test, no engine rewrite. (F-Class can be added here too as an in-family TargetFace over ICFRA geometry with the F-Standard ladder if desired.) Generalise "course of fire" (air rifle = 60 shots, unlimited sighters) since it differs from TR's 10/15.

7.2 Track B — backend & accounts
Supabase project: mirror the drift schema as Postgres tables; enable RLS (owner-only now).
PowerSync on top: local SQLite ⇄ Postgres, upload queue, conflict resolution; sync rules scope each user to their own data. Because Phase 1 already uses drift/SQLite, this is a connector + sync-rules add, not a data-layer rewrite.
Auth: email/OAuth; promote the local profile to a real account; first-run "use offline" path so the app fully works with no account (ranges are offline).
Ops: crash/analytics (Sentry), OTA config so new discipline definitions ship without an app-store release, app icons + store listings, Apple ($99/yr) + Google Play ($25) accounts, CI build pipeline (Codemagic/GitHub Actions).
Setup order: create project → port schema SQL → enable RLS + owner policies → stand up PowerSync (cloud or self-host) → wire Supabase Auth → add PowerSync connector → switch repositories from local-drift to PowerSync-backed (same SQLite API) → verify offline write → online sync → conflict path.

8. Phase 3 — Shared scorecard & register-keeping (smallest tournament primitive)
The defensible core begins here. This phase makes the scorecard a shared, dual-signed record with a custody chain — the single most important tournament design constraint.

8.1 What the rules require (fullbore Bisley-style)
2–3 competitors squadded on one target fire in rotation, starting with the right-hand competitor, and act as register-keepers for one another (ICFRA T13.1.2).
Pass direction: in threes, left and middle pass their cards to the right; the right-hand shooter passes to the left — every card is held by someone who is not the firer. The register keeper never scores their own card.
Independence: the register keeper should be from a different team/service (enforced at squadding, Phase 4).
Live calling: the register keeper calls every shot's value and is required to be watching through a scope/binoculars (scope compulsory while register-keeping, ICFRA T3.4). The firer/coach confirms each call.
Convertible sighters: none / 2nd / both — already modelled; the keeper strikes a converted sighter with a diagonal and copies its value into shot 1 (and 2).
Dual attestation & custody: keeper completes and is responsible for the card during firing; at the end the firer confirms the total, the keeper signs it as a true record, and many conditions require the firer's countersignature accepting the score; then the card goes to Stats. A lost card is a real, rule-governed problem (DCRA Rule 15). Mental model: scorer vouches → firer accepts → Stats, not a private note.
8.2 Build
Two-device flow: firer's device shows the plot; register-keeper's device is the system of record during firing (mirrors "the scorer holds the card"). Keeper enters each called value live → running total + V-count auto-computed.
Attestation state machine: open → attested(scorer signs) → accepted(firer countersigns) → submitted(to Stats) → queried(dispute) → finalised. Card becomes visible to Stats only at submitted.
Challenge workflow (manual targets only): flag a shot as challenged, record outcome and any fee; keep both the original and corrected value for audit — never overwrite.
Irregular-shot flags: wrong target, ricochet, simultaneous hit, out-of-turn, extra shot — flag, don't silently average (DCRA 3.03–3.06).
Offline-first: keeper's device works with no signal; syncs to the match DB on wifi. No card is ever "lost." Conflict resolution policy: the register-keeper entry is authoritative for shot values; firer countersignature is required to finalise.
RLS/sharing: a scorecard syncs to the firer and the assigned keeper (and later Stats); the firer's private plot/dial-to does not leak to the keeper — only the card does.
This phase is usable on its own as "two mates scoring for each other properly," with no full match infrastructure.

9. Phase 4 — Squadding engine & match setup
Automate the logistics where most manual labour lives today.

9.1 What the rules require (DCRA Rule 7 + 11.07–11.08)
Individual matches squad physically into four ranks; ranks are mixed so no single file contains two members of the same unit/team (as far as numbers allow).
Rank → relay number; file → target number; number pegs mark target centres.
Deliberate matches are shot single-string with the waiting relay scoring — relays rotate, repeated at every distance.
Register-keeper independence (different team) must hold.
9.2 Build — squadding as a constraint-satisfaction problem (tractable at match sizes)
Hard constraints: each firer gets exactly one target per distance; no file/target pairs two same-team members; register keeper is from a different team than firer; capacity = targets × positions per relay.
Soft preferences: balanced relay sizes; optionally keep a competitor on a similar firing point across distances; spread classifications.
Output: per-distance squadding lists + each shooter's personal schedule ("relay 2, target 14, position R @ 300; relay 1, target 14 @ 500…").
Reflow on change: late entry / scratch / no-show / shoot-off re-runs the solver touching only affected details (the killer feature vs paper).
Match setup screen: define Match → distances → course of fire → sighters-convertible → shots-to-count; import the competitor list; generate squadding; publish.
9.3 Data — the Detail table is the squadding output and carries firer_id +
register_keeper_id + position (L/C/R) + relay_no + target_no (see §13).

10. Phase 5 — Stats, results, ties & countback
Turn the digital cards into rankings automatically — the "Stats office," but instant.

Ingest completed/finalised cards; validate shot count vs course of fire, total arithmetic, status, no duplicate card per competitor/stage.
Aggregate across stages and distances; per-stage and grand-aggregate standings; class/category filters; team aggregates (sum of N members).
Ties & countback applied programmatically (DCRA 16.02–16.06): V-count first, then last-shots-first countback — deterministic, instant, auditable.
Live results board (spectator-facing screen) even on paper ranges, because the data is already digital at the point of scoring — a differentiator vs paper-only meets.
Query/dispute path: Stats can move a card to queried; resolution audited.
Optional Edge Functions compute rankings server-side; Realtime pushes the live board.
11. Phase 6 — Registration, entries & fees (optional)
The club-management surface where tools like ScoresR/Scopos live. Lower priority; build only if there's demand.

Competitor Entry (entered/scratched), fee/cashiering, classification admin, score-sheet printing, payout/compliance reporting.
This is also the natural point to consider extracting an organiser web dashboard (Flutter Web or a separate front-end on the same Supabase) and/or a public API.
12. Phase C — Coaching (parallel mini-phase, any time after Phase 2)
Async post-session review (recommended first): a coach role with an athlete roster receives finished strings (plot + card + wind/elev graphs, with consent) and sees cross-session analytics the single-shooter view can't: group-size trend, mean-POI drift, V/X conversion rate, score-by-distance, shot-call-vs-actual correlation, wind-reading accuracy over time. Reuses the Phase 3 share mechanism.
Live coaching (later, harder): athlete's plot/dial-to streams to the coach during the string (Supabase Realtime). Bigger lift; sequence after async.
Privacy/consent: junior athletes are common; consent flows + clear data ownership required (RLS handles the technical side).
13. Consolidated data model (all phases)
UUID id, created_at, updated_at, format_version on every row.

-- Phase 1 (local)
shooter_profile(id, display_name, default_units, handedness)
series/string(id, owner_id, discipline_id, standard, distance_id, match_length,
              conversion, status[in_progress|saved], linked_scorecard_id?)
shot(id, string_id, seq, role[sighterA|sighterB|scored], x_mm, y_mm, value,
     is_tiebreak, call, dialed_wind, dialed_elev,
     converted?, challenged?, irregular_flag?)        -- last 3 used from Phase 3
sight_preset(id, distance_id, standard, aperture, elevation, windage, note)
app_options(id, recommendation_on, graphs_on, default_match_length, units)

-- Phase 2 (accounts; same tables gain owner_id + sync)
account(id, email, display_name, roles[shooter|keeper|coach|organiser])

-- Phase 3 (shared card + custody)
scorecard(id, competitor_id, discipline_id, distance_id, match_id?, detail_id?,
          shots[], total, v_count,
          scorer_id, firer_confirmed, scorer_signed, firer_countersigned,
          status[open|attested|accepted|submitted|queried|finalised],
          challenges[ {shot_seq, original, corrected, fee, outcome} ],
          irregular_flags[ {shot_seq, type} ],
          linked_target_sheet_id?)

-- Phase 4 (tournaments)
competitor(id, name, team_club, classification, country_service)
match(id, name, distances[], course_of_fire, sighters_convertible, shots_to_count, date)
entry(competitor_id, match_id, fee_paid, status[entered|scratched])
detail(id, match_id, distance, relay_no, target_no, position[L|C|R],
       firer_id, register_keeper_id)    -- encodes independence + pass direction

-- Phase C (coaching)
coach_roster(coach_id, athlete_id, consent_at)
14. Tournament domain reference (encode these carefully; verify against current rulebooks)
Scoring & notation. V-bull = 5 (marked "V"), then 5/4/3/2 outward; final written as total – V count (e.g. 50–10V); Vs are the tiebreak. Inward gauging: if the plug- gauged hole touches a higher ring's line, award the higher value.

Shot provenance (every shot): sighter A/B vs scored; converted or not; challenged or not (keep both values); irregular or not (wrong target / ricochet / simultaneous / out-of-turn / extra — flag, don't average).

Custody chain (the core constraint): register-keeper holds & completes the card during firing → firer confirms total → keeper signs → firer countersigns → submit to Stats → (optional) Stats query → finalise. Lost cards are a governed failure mode — the digital card's job is that no card is ever lost or mis-totalled.

Register-keeping rotation: Bisley-style, 2–3/target, fire from the right, mutual keeping, cards pass right (right-hand passes left); keeper independent (different team); scope compulsory; every shot called and confirmed.

Squadding constraints: four ranks; mix so no file has two same-team members; rank=relay, file=target; waiting relay scores; reflow on entry changes; keeper independence enforced here.

Ties/countback: V-count first, then last-shots-first countback (DCRA 16.02–16.06).

Rule citations to verify before encoding (editions change; match conditions can override): ICFRA TR T13.1.2 (Bisley)/T13.1.3 (SSIP)/T3.4 (scope)/T9 (convertible sighters); DCRA 3.01–3.07 (scoring/challenges/irregulars), Rule 7 + 11.07–11.08 (squadding), 11.13 (sighters), Rule 15 (score tickets/custody/lost cards), 16.02–16.06 (ties); NRA UK / CCRS cadet rules (keeper independence). Always check the current published rulebook and the specific meeting's conditions before coding a rule.

Existing-software lessons: PractiScore (offline-first, registration→squadding→scoring→ results) is the model for "match director's job made easy" and for "works with no internet, syncs on wifi." Electronic targets (KTS/CMP, Sius, Silver Mountain) remove butt-markers and challenges where installed — but are expensive fixed infrastructure; the app's niche is the paper + butt-marker ranges and the fullbore-specific rules none of these model.

15. Geometry reference — ring dimensions (validate against the repo)
Model each face as ring outer-diameters in mm at each distance + black aiming-mark diameter. Scoring = innermost ring whose boundary contains the shot; edge-touch → higher value.

ICFRA Target Rifle (DCRA) — Ø mm: V / 5(bull) / 4(inner) / 3(magpie) / 2(outer), (aim)
Metric: 300 m 35/70/140/280/420 (aim 600) · 500 m 72/145/290/660/1000 (1000) · 600 m 80/160/320/660/1000 (1000) · 700 m 127/255/510/815/1120 (1120) · 800–900 m 127/255/510/815/1120 (1120). Yards: 300 y 32/65/130/260/390 (560) · 500 y 65/130/260/600/915 · 600 y 72/145/290/600/915 · 700 y 80/160/320/660/1000 · 800–1000 y 127/255/510/815/1120. (ICFRA: 400 y/m = 4/3 × the 300 target — derive rather than store.)

NRA (UK Bisley) Target Rifle — Ø mm: 5 / 4 / 3 / 2 / scoring-edge (2019 revision)
V-bull = 0.6 × the 5-ring here (vs ICFRA's 0.5) — a per-standard parameter, not a constant. 300 y 78.0/130.0/260.0/390.0/560.0 · 500 y 156.0/260.0/660.4/990.6/1320.8 · 600 y 198.1/330.2/660.4/990.6/1320.8 · Long Range (900/1000 y) 365.8/609.6/1219.2/1828.8/2438.4. ⚠️ Two NRA sets exist (FAQ "revised" 300 yd = 78/130/260/390/560 vs working-group "proposed" = 75/125/250/375/560). Use the repo's shipped constants; treat these as a cross-check.

ISSF 10 m air rifle (Phase 2) — decimal
Total Ø 45.5 mm; rings 1–10 at 2.5 mm radial spacing; 10-ring Ø 0.5 mm; 9-ring Ø 5.5 mm; black aiming area (4-ring) Ø 30.5 mm. Decimal: inner-10 dot radius 0.25 mm; 10.9 max, −0.1 per 0.25 mm from centre. (For reference if ISSF 50 m is ever added: total Ø 154.4 mm, 10-ring Ø 10.4 mm, 9-ring Ø 26.4 mm; −0.1 per 0.8 mm.)

MOA
1 MOA ≈ range × tan(1′) ≈ 29.1 mm/100 m ≈ 1.047″/100 yd. Store per distance; drives grid spacing and all dial-to/correction math.

16. Testing & quality strategy (all phases)
Scoring unit tests — table-driven vs §15: shot at radius r, distance d, standard s scores exactly v; boundary cases just-in/just-out at every ring + V-bull + miss; decimal cases for air rifle. Correctness lives here.
Conversion tests — none/B/A+B renumber + total/V recompute.
Dial-to / MOA tests — known group → known correction at several ranges/units.
Golden tests — each TargetFace rendered at fixed zoom, image-locked; catches geometry regressions when disciplines are added.
Interaction tests — place/drag/undo; loupe offset; pan/zoom clamping.
Phase 3+: attestation state-machine tests; challenge keeps-both-values; offline→sync conflict tests (two devices); squadding CSP property tests (no constraint violated on random inputs); ties/countback golden cases from real meeting results.
17. Ops, app stores, cost
App stores: Apple Developer ~$99/yr, Google Play ~$25 once; both review. Budget a store-readiness pass (privacy policy, data-deletion flow, screenshots).
Cost trajectory: ~$0 at small scale; order-of-magnitude ~$75/mo at ~5k MAU on Supabase + PowerSync. Likely payers are clubs/organisers, not individual shooters → suggests "free for shooters, paid for matches/clubs."
Ops: Sentry (crash/analytics), OTA discipline-definition updates, CI builds, backups (Postgres is portable — no lock-in).
18. Consolidated risks, assumptions & open questions
Must-confirm (highest priority):

Repo is source of truth for geometry constants, scoring, sighter/conversion, dial-to — the source files could not be opened during planning; the agent must diff §15 and §6.5 against the actual code and prefer the repo, reporting mismatches.
Which NRA dimension set the repo ships (78/130/260/390/560 vs 75/125/250/375/560 at 300 yd).
Exact distance list implemented (is 200 y included? 400 derived or stored?).
Legacy data import — is there user data on the persistent-storage branch worth a first-launch importer, and what's its JSON shape?
Design decisions to lock: 5. Flutter vs React Native — this plan assumes Flutter (best for the canvas); switch only if reusing web/React talent matters more. 6. Drag-and-drop flavour — assumed tap-to-provisional → drag-to-refine + loupe, with tap-only fallback; confirm. 7. Units — model = mm, display yd/m·inch·MOA; confirm the repo's internal unit for the importer. 8. Is the digital scorecard official or convenience? In Phase 1–2 it's the shooter's own record; from Phase 3 the dual-signed card with custody chain is intended to be the match record for ranges using the app. Becoming the legally authoritative system pulls in full dispute/challenge/audit obligations — accept that scope consciously at Phase 3. 9. One app vs separate organiser tool/API — recommendation: one role-based app on Supabase (which is the API); revisit extracting an organiser web app at Phase 5/6.

Scope guardrails (confirmed): 10. Fullbore-first; air rifle the one secondary discipline (Phase 2); F-Class an optional in-family add; everything else out of scope. 11. Tournament features are fullbore-only — air rifle gets plotting/scoring/coaching but not the fullbore-specific squadding/register-keeping machinery. 12. Rule editions & meeting conditions change — verify every encoded rule against the current published rulebook and the specific match's conditions before relying on it.

Compiled June 2026. Sequence the niche along Phase 3 → 4 → 5; Phases 1–2 are the foundation; Phase 6 and Coaching are optional/parallel. Each phase ships independently.