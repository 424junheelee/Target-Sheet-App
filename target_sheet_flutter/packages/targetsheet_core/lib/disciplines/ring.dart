/// A single scoring ring on a target face.
/// [radiusMm] is the physical radius of this ring in mm (inward-gauging: shot
/// touching the line scores the higher value).
/// Rings are listed V → outer in a [TargetFace.rings] list.
final class Ring {
  const Ring({
    required this.score,
    required this.isVbull,
    required this.label,
    required this.radiusMm,
  });

  final double score;
  final bool isVbull;
  final String label;
  final double radiusMm;
}
