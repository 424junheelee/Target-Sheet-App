import 'dart:math' as math;

import '../geometry/coordinate_system.dart';
import '../scoring/scoring.dart';

// ── Graph series (from graphs.py suggested()) ─────────────────────────────────

/// The wind/elevation that would have centred an individual [shot].
/// [moaMm] — physical mm per MOA at this distance.
/// Returns (suggestedWind, suggestedElev) in MOA.
/// Formula (y=UP): sugW = windMoa - x/moaMm; sugE = elevMoa - y/moaMm
({double wind, double elev}) suggestedCorrection(
  ScoredShot shot,
  double moaMm,
) => (
  wind: shot.windMoa - shot.point.xMm / moaMm,
  elev: shot.elevMoa - shot.point.yMm / moaMm,
);

/// Suggested-correction series for a list of shots.
List<({double wind, double elev})> graphSeries(
  List<ScoredShot> shots,
  double moaMm,
) => [for (final s in shots) suggestedCorrection(s, moaMm)];

// ── Group statistics (from views/analysis.py) ─────────────────────────────────

final class GroupStats {
  const GroupStats({
    required this.meanPoint,
    required this.extremeSpreadMoa,
    required this.meanRadiusMoa,
    required this.shotCount,
  });

  final ModelPoint? meanPoint;
  final double? extremeSpreadMoa;
  final double? meanRadiusMoa;
  final int shotCount;
}

/// Compute group statistics for [shots] (non-miss, non-sighter-unless-converted).
/// Pass only the shots you want to include (i.e., pre-filter for conversion).
GroupStats computeGroupStats(List<ScoredShot> shots, double moaMm) {
  final inTarget = shots.where((s) => s.ring != null).toList();
  if (inTarget.isEmpty) {
    return const GroupStats(
      meanPoint: null,
      extremeSpreadMoa: null,
      meanRadiusMoa: null,
      shotCount: 0,
    );
  }

  final n = inTarget.length;
  final meanX = inTarget.fold(0.0, (s, p) => s + p.point.xMm) / n;
  final meanY = inTarget.fold(0.0, (s, p) => s + p.point.yMm) / n;
  final mpi = ModelPoint(meanX, meanY);

  // Extreme spread: max pairwise distance
  double? es;
  if (n >= 2) {
    var maxD = 0.0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = inTarget[i].point.distanceTo(inTarget[j].point);
        if (d > maxD) maxD = d;
      }
    }
    es = maxD / moaMm;
  }

  // Mean radius: average distance from MPI
  final mr = inTarget.fold(0.0, (s, p) => s + p.point.distanceTo(mpi)) /
      n /
      moaMm;

  return GroupStats(
    meanPoint: mpi,
    extremeSpreadMoa: es,
    meanRadiusMoa: mr,
    shotCount: n,
  );
}

// ── Call breakdown ─────────────────────────────────────────────────────────────

final class CallBreakdown {
  const CallBreakdown({
    required this.good,
    required this.pull,
    required this.bad,
  });

  final int good;
  final int pull;
  final int bad;

  int get total => good + pull + bad;
}

CallBreakdown callBreakdown(List<ScoredShot> shots) {
  var good = 0;
  var pull = 0;
  var bad = 0;
  for (final s in shots) {
    if (s.call == null) continue;
    if (s.call == 'good') {
      good++;
    } else if (s.call!.startsWith('pull')) {
      pull++;
    } else if (s.call == 'bad') {
      bad++;
    }
  }
  return CallBreakdown(good: good, pull: pull, bad: bad);
}

// ── Wind/elevation label formatting (from scoring.py) ────────────────────────

/// Format a wind value: 2.5 → '2.5R', -1.25 → '1.25L', 0 → 'calm'.
String windLabel(double v) {
  if (v == 0) return 'calm';
  final mag = v.abs();
  final magStr = mag == mag.truncateToDouble()
      ? mag.toStringAsFixed(0)
      : mag.toString();
  return '$magStr${v < 0 ? 'L' : 'R'}';
}

/// Format an elevation value: 1.5 → '+1.5', -0.25 → '-0.25', 0 → '0'.
String elevLabel(double v) {
  if (v == 0) return '0';
  final mag = v.abs();
  final magStr = mag == mag.truncateToDouble()
      ? mag.toStringAsFixed(0)
      : mag.toString();
  return v > 0 ? '+$magStr' : '-$magStr';
}

// ── Extreme spread helper exposed for tests ───────────────────────────────────

/// Euclidean distance between two points (mm).
double distanceMm(ModelPoint a, ModelPoint b) => math.sqrt(
  (a.xMm - b.xMm) * (a.xMm - b.xMm) + (a.yMm - b.yMm) * (a.yMm - b.yMm),
);
