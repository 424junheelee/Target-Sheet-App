import 'package:flutter/painting.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

// VB = 175.0 (viewbox half-size from constants.py; outer ring R=150, padding=25).
const double _svgVb = 175.0;

/// Immutable view transform: maps model coordinates (mm) to canvas pixels.
///
/// Model origin (target centre) maps to [centrePixel].
/// [pxPerMm] grows with zoom.
final class ViewTransform {
  const ViewTransform({
    required this.pxPerMm,
    required this.centrePixel,
  });

  /// Build a fit-to-canvas transform (zoom=1, no pan) for a given canvas size.
  /// The full target viewbox (outer ring + padding = VB*2 SVG units) is scaled
  /// to fit the shorter canvas dimension.
  factory ViewTransform.fit(Size canvasSize, TargetFace face) {
    final outerMm = face.outerRing.radiusMm;
    // VB * 2 SVG units = VB * 2 * (outerMm/150) mm total viewbox extent
    final viewboxMm = _svgVb * 2 * outerMm / 150.0;
    final pxPerMm = canvasSize.shortestSide / viewboxMm;
    return ViewTransform(
      pxPerMm: pxPerMm,
      centrePixel: Offset(canvasSize.width / 2, canvasSize.height / 2),
    );
  }

  factory ViewTransform.fitWithZoom(
    Size canvasSize,
    TargetFace face,
    double zoom,
    Offset pan,
  ) {
    final base = ViewTransform.fit(canvasSize, face);
    return ViewTransform(
      pxPerMm: base.pxPerMm * zoom,
      centrePixel: base.centrePixel + pan,
    );
  }

  final double pxPerMm;

  /// Canvas pixel position of the model origin (target centre).
  final Offset centrePixel;

  /// Model point → canvas pixel.
  Offset toCanvas(ModelPoint p) => Offset(
        centrePixel.dx + p.xMm * pxPerMm,
        centrePixel.dy - p.yMm * pxPerMm, // y=UP in model → flip to y=DOWN on canvas
      );

  /// Canvas pixel → model point.
  ModelPoint fromCanvas(Offset px) => ModelPoint(
        (px.dx - centrePixel.dx) / pxPerMm,
        -(px.dy - centrePixel.dy) / pxPerMm, // flip y back to y=UP
      );
}
