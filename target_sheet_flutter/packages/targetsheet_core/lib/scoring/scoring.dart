import '../disciplines/ring.dart';
import '../disciplines/target_face.dart';
import '../geometry/coordinate_system.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ShotType { sighterA, sighterB, scored }

enum Conversion {
  none, // neither sighter counts toward the total
  b,    // sighter B counts as shot 1
  ab,   // sighters A and B count as shots 1 and 2
}

// ── Ring containment (inward gauging) ─────────────────────────────────────────

/// Returns the innermost [Ring] whose radius contains [point], or null (miss).
/// For [ScoringMode.decimal] faces, computes the decimal score when the shot
/// lands in the 10-ring (inner-10 = 10.9, −0.1 per 0.25 mm outward).
Ring? scoreShot(
  ModelPoint point,
  List<Ring> rings, {
  ScoringMode scoringMode = ScoringMode.integer,
}) {
  final d = point.magnitude;
  for (final ring in rings) {
    if (d <= ring.radiusMm) {
      if (scoringMode == ScoringMode.decimal && ring.score >= 10.0) {
        // Decimal formula: 10.9 − floor(d / 0.25) × 0.1, clamped to [10.0, 10.9].
        const inner10 = 10.9;
        final steps = (d / 0.25).floor();
        final raw = inner10 - steps * 0.1;
        final clamped = raw.clamp(10.0, inner10);
        final rounded = (clamped * 10).roundToDouble() / 10;
        return Ring(
          score: rounded,
          isVbull: ring.isVbull,
          label: rounded.toStringAsFixed(1),
          radiusMm: ring.radiusMm,
        );
      }
      return ring;
    }
  }
  return null;
}

// ── Snap / clamp ──────────────────────────────────────────────────────────────

/// Snap [v] to the nearest 0.25 increment (from scoring.py snap()).
double snap(double v) => (v * 4).roundToDouble() / 4;

/// Clamp [v] to [−200, +200] (from constants.py MAXV = 200).
double clamp(double v, {double lo = -200, double hi = 200}) =>
    v < lo ? lo : (v > hi ? hi : v);

// ── Shot & total types ────────────────────────────────────────────────────────

final class ScoredShot {
  const ScoredShot({
    required this.point,
    required this.type,
    required this.ring,     // null = miss
    required this.windMoa,
    required this.elevMoa,
    this.call,
  });

  final ModelPoint point;
  final ShotType type;
  final Ring? ring;
  final double windMoa;
  final double elevMoa;
  final String? call;

  double get score => ring?.score ?? 0.0;
  bool get isVbull => ring?.isVbull ?? false;
  String get label => ring?.label ?? 'M';
}

final class ScoreTotal {
  const ScoreTotal({required this.tot, required this.v, required this.n});

  final double tot;
  final int v;
  final int n;
}

// ── Total calculation (from app.py _calc_total) ───────────────────────────────

/// Compute the running total for [shots] under [conversion].
/// [shootLen] is the match length (10 or 15 scored shots).
ScoreTotal calcTotal(
  List<ScoredShot> shots,
  Conversion conversion,
  int shootLen,
) {
  final converted = switch (conversion) {
    Conversion.none => 0,
    Conversion.b    => 1,
    Conversion.ab   => 2,
  };
  final maxSc = shootLen - converted;

  final scoredShots =
      shots.where((s) => s.type == ShotType.scored).take(maxSc).toList();

  final extra = <ScoredShot>[];
  if (conversion == Conversion.b || conversion == Conversion.ab) {
    final b = shots.where((s) => s.type == ShotType.sighterB).firstOrNull;
    if (b != null) extra.add(b);
  }
  if (conversion == Conversion.ab) {
    final a = shots.where((s) => s.type == ShotType.sighterA).firstOrNull;
    if (a != null) extra.insert(0, a);
  }

  final all = [...extra, ...scoredShots];
  return ScoreTotal(
    tot: all.fold(0.0, (sum, s) => sum + s.score),
    v: all.where((s) => s.isVbull).length,
    n: all.length,
  );
}

// ── Shot phase (from app.py _get_phase) ──────────────────────────────────────

/// What type of shot comes next.
ShotType? nextShotType(
  List<ScoredShot> shots,
  Conversion conversion,
  int shootLen,
) {
  final n = shots.length;
  if (n == 0) return ShotType.sighterA;
  if (n == 1) return ShotType.sighterB;
  final scCount = shots.where((s) => s.type == ShotType.scored).length;
  final converted = switch (conversion) {
    Conversion.none => 0,
    Conversion.b    => 1,
    Conversion.ab   => 2,
  };
  final maxSc = shootLen - converted;
  if (scCount >= maxSc) return null; // string complete
  return ShotType.scored;
}

// ── Shot display labels (from app.py _compute_labels) ────────────────────────

/// Display label for each shot (e.g. "A", "B", "1", "2"…) under [conversion].
List<String> shotDisplayLabels(List<ScoredShot> shots, Conversion conversion) {
  final out = <String>[];
  var scIdx = 0;
  final offset = switch (conversion) {
    Conversion.none => 1,
    Conversion.b    => 2,
    Conversion.ab   => 3,
  };
  for (final s in shots) {
    switch (s.type) {
      case ShotType.sighterA:
        out.add(conversion == Conversion.ab ? '1' : 'A');
      case ShotType.sighterB:
        out.add(
          conversion == Conversion.b
              ? '1'
              : conversion == Conversion.ab
                  ? '2'
                  : 'B',
        );
      case ShotType.scored:
        out.add('${scIdx + offset}');
        scIdx++;
    }
  }
  return out;
}

// ── Dial-to recommendation (from app.py _compute_recommendation, y=UP) ───────

/// Returns dial-to recommendation in MOA given the current group mean.
/// [meanPoint] is in model space (mm, y=UP).
/// [moaMm] is physical mm per MOA at this distance.
/// [currentWind] and [currentElev] are the currently dialled values (MOA).
({double w, double e})? dialToRecommendation({
  required List<ScoredShot> shots,
  required double moaMm,
  required double currentWind,
  required double currentElev,
}) {
  if (shots.isEmpty) return null;
  final n = shots.length.toDouble();
  final meanX = shots.fold(0.0, (s, p) => s + p.point.xMm) / n;
  final meanY = shots.fold(0.0, (s, p) => s + p.point.yMm) / n;
  return (
    w: clamp(snap(currentWind - meanX / moaMm)),
    e: clamp(snap(currentElev - meanY / moaMm)), // y=UP: minus (not plus as in SVG)
  );
}
