import 'dart:math' as math;

// SVG outer radius from constants.py (R = 150.0 SVG units).
const double _svgOuterRadius = 150.0;

/// Immutable model-space point.
/// Origin = target centre; x = right (windage); y = UP (elevation); unit = mm.
/// SVG/screen coordinates use y = DOWN; convert only at the boundary.
final class ModelPoint {
  const ModelPoint(this.xMm, this.yMm);

  final double xMm;
  final double yMm;

  static const ModelPoint zero = ModelPoint(0, 0);

  /// Import from SVG space: [outerRadiusMm] is the physical outer-ring radius.
  /// Flips y (SVG y=DOWN → model y=UP).
  factory ModelPoint.fromSvg(
    double svgX,
    double svgY,
    double outerRadiusMm,
  ) {
    final double s = outerRadiusMm / _svgOuterRadius;
    return ModelPoint(svgX * s, -svgY * s);
  }

  /// Export to SVG coordinates (y flipped back, units = SVG units where outer ring = 150).
  /// Returns (svgX, svgY).
  (double, double) toSvg(double outerRadiusMm) {
    final double s = _svgOuterRadius / outerRadiusMm;
    return (xMm * s, -yMm * s);
  }

  double get magnitude => math.sqrt(xMm * xMm + yMm * yMm);

  double distanceTo(ModelPoint other) {
    final dx = xMm - other.xMm;
    final dy = yMm - other.yMm;
    return math.sqrt(dx * dx + dy * dy);
  }

  ModelPoint operator +(ModelPoint other) =>
      ModelPoint(xMm + other.xMm, yMm + other.yMm);

  ModelPoint operator -(ModelPoint other) =>
      ModelPoint(xMm - other.xMm, yMm - other.yMm);

  ModelPoint scale(double factor) => ModelPoint(xMm * factor, yMm * factor);

  @override
  bool operator ==(Object other) =>
      other is ModelPoint && other.xMm == xMm && other.yMm == yMm;

  @override
  int get hashCode => Object.hash(xMm, yMm);

  @override
  String toString() => 'ModelPoint(x=${xMm}mm, y=${yMm}mm)';
}
