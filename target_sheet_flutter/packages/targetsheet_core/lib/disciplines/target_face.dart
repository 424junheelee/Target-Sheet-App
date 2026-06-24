import 'ring.dart';

enum ScoringMode { integer, decimal }

/// Immutable description of a target face for one distance + standard combination.
/// [rings] is ordered V → outer (innermost first).
final class TargetFace {
  const TargetFace({
    required this.id,
    required this.label,
    required this.rings,
    required this.distanceLabel,
    required this.standard,
    this.yards,
    this.metres,
    this.scoringMode = ScoringMode.integer,
    this.defaultShotCount = 10,
    this.unlimitedSighters = false,
  }) : assert(
         (yards != null) != (metres != null),
         'Exactly one of yards or metres must be set',
       );

  /// Unique key matching the Python TARGET_CONFIGS key, e.g. "300y-nra".
  final String id;
  final String label;
  final List<Ring> rings;
  final String distanceLabel;
  final String standard;

  /// Firing distance in yards. Exactly one of [yards] or [metres] is set.
  final int? yards;

  /// Firing distance in metres. Exactly one of [yards] or [metres] is set.
  final int? metres;

  final ScoringMode scoringMode;
  final int defaultShotCount;
  final bool unlimitedSighters;

  /// Outer ring (lowest score, largest radius).
  Ring get outerRing => rings.last;

  /// V-bull ring (innermost).
  Ring get vRing => rings.first;

  /// Effective yards for MOA calculations.
  double get effectiveYards =>
      yards != null ? yards!.toDouble() : metres! * 1.09361;
}
