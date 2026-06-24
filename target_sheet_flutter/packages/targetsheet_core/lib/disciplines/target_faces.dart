import 'ring.dart';
import 'target_face.dart';

// Ring radii are sourced from targets.py (authoritative).
// All conversions: inches × 25.4 = mm.

const double _in = 25.4; // mm per inch

List<Ring> _rings(List<double> radiiInches) => [
  Ring(score: 5.0, isVbull: true,  label: 'V', radiusMm: radiiInches[0] * _in),
  Ring(score: 5.0, isVbull: false, label: '5', radiusMm: radiiInches[1] * _in),
  Ring(score: 4.0, isVbull: false, label: '4', radiusMm: radiiInches[2] * _in),
  Ring(score: 3.0, isVbull: false, label: '3', radiusMm: radiiInches[3] * _in),
  Ring(score: 2.0, isVbull: false, label: '2', radiusMm: radiiInches[4] * _in),
];

// ── ICFRA TR face radii (inches) from targets.py ──────────────────────────────
const List<double> _srIn = [1.378,  2.756,  5.512,  8.268, 11.811]; // ~300 m SR
const List<double> _mrIn = [3.150,  6.299, 12.992, 19.685, 25.984]; // ~500–600 m MR
const List<double> _lrIn = [5.020, 10.039, 16.043, 22.047, 36.024]; // ~700 m+ LR

// ── NRA / Bisley yard faces (targets.py NRA block) ───────────────────────────
// 300y: NRA Figure 11 (44" outer diameter, 22" outer radius).
// 500–1000y: NRA TR Figure 12 (72" outer diameter, 36" outer radius) — same face.

const List<double> _nra300yIn  = [1.0,  3.0,  6.0, 12.0, 22.0];
const List<double> _nra500to1000yIn = [2.5, 7.5, 15.0, 24.0, 36.0];

TargetFace _nra(String dist, int yards, List<double> radiiIn) => TargetFace(
  id: '$dist-nra',
  label: '$dist  —  NRA / Bisley',
  distanceLabel: dist,
  standard: 'NRA',
  yards: yards,
  rings: _rings(radiiIn),
);

TargetFace _dcraYards(String dist, int yards, List<double> radiiIn) => TargetFace(
  id: '$dist-dcra',
  label: '$dist  —  DCRA (ICFRA)',
  distanceLabel: dist,
  standard: 'DCRA',
  yards: yards,
  rings: _rings(radiiIn),
);

TargetFace _dcraMetric(String dist, int metres, List<double> radiiIn) => TargetFace(
  id: '$dist-dcra',
  label: '$dist  —  DCRA (ICFRA metric)',
  distanceLabel: dist,
  standard: 'DCRA',
  metres: metres,
  rings: _rings(radiiIn),
);

// ── ISSF 10 m Air Rifle ──────────────────────────────────────────────────────
// Radii from ISSF technical specifications.
// Scoring: decimal, inner-10 = 10.9, decrements 0.1 per 0.25 mm outward.
// Face total Ø = 45.5 mm; inner-10 Ø = 0.5 mm.
const TargetFace _issf10m = TargetFace(
  id: '10m-issf',
  label: '10 m  —  ISSF Air Rifle',
  distanceLabel: '10m',
  standard: 'ISSF',
  metres: 10,
  scoringMode: ScoringMode.decimal,
  defaultShotCount: 60,
  unlimitedSighters: true,
  rings: [
    Ring(score: 10.9, isVbull: true,  label: 'X',  radiusMm: 0.25),
    Ring(score: 10.0, isVbull: false, label: '10', radiusMm: 2.75),
    Ring(score:  9.0, isVbull: false, label: '9',  radiusMm: 5.25),
    Ring(score:  8.0, isVbull: false, label: '8',  radiusMm: 7.75),
    Ring(score:  7.0, isVbull: false, label: '7',  radiusMm: 10.25),
    Ring(score:  6.0, isVbull: false, label: '6',  radiusMm: 12.75),
    Ring(score:  5.0, isVbull: false, label: '5',  radiusMm: 15.25),
    Ring(score:  4.0, isVbull: false, label: '4',  radiusMm: 17.75),
    Ring(score:  3.0, isVbull: false, label: '3',  radiusMm: 20.25),
    Ring(score:  2.0, isVbull: false, label: '2',  radiusMm: 22.75),
  ],
);

/// All seeded target faces, keyed by [TargetFace.id].
final Map<String, TargetFace> kTargetFaces = Map.unmodifiable({
  for (final f in _allFaces) f.id: f,
});

final List<TargetFace> _allFaces = [
  // NRA
  _nra('300y',  300,  _nra300yIn),
  _nra('500y',  500,  _nra500to1000yIn),
  _nra('600y',  600,  _nra500to1000yIn),
  _nra('700y',  700,  _nra500to1000yIn),
  _nra('800y',  800,  _nra500to1000yIn),
  _nra('900y',  900,  _nra500to1000yIn),
  _nra('1000y', 1000, _nra500to1000yIn),
  // DCRA yards
  _dcraYards('300y',  300,  _srIn),
  _dcraYards('500y',  500,  _mrIn),
  _dcraYards('600y',  600,  _mrIn),
  _dcraYards('700y',  700,  _lrIn),
  _dcraYards('800y',  800,  _lrIn),
  _dcraYards('900y',  900,  _lrIn),
  _dcraYards('1000y', 1000, _lrIn),
  // DCRA metric
  _dcraMetric('300m',  300,  _srIn),
  _dcraMetric('500m',  500,  _mrIn),
  _dcraMetric('600m',  600,  _mrIn),
  _dcraMetric('700m',  700,  _lrIn),
  _dcraMetric('800m',  800,  _lrIn),
  _dcraMetric('900m',  900,  _lrIn),
  _dcraMetric('1000m', 1000, _lrIn),
  // ISSF
  _issf10m,
];
