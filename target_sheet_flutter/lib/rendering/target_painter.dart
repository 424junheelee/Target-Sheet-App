import 'package:flutter/rendering.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import 'view_transform.dart';

// Colour palette from constants.py
const Color _colTargetBg  = Color(0xFFF7F2E8);
const Color _colTargetInk = Color(0xFF1A1A1A);
const Color _colGrid0     = Color(0xFF555555); // centre crosshair
const Color _colGridOuter = Color(0xFF999999); // outer-ring highlight
const Color _colGridNorm  = Color(0xFFCCCCCC); // normal grid
const Color _colBorderBox = Color(0xFF555555);
const Color _colDiag      = Color(0xFFBBBBBB);
const Color _colLabel     = Color(0xFFAAAAAA);

// VB SVG units = viewbox half-size from constants.py
const double _svgVb = 175.0;
// Aiming mark at 104 SVG units from constants.py (dart/loupe cross)
const double _svgAimMark = 104.0;

/// Static CustomPainter for the target face, MOA grid, and aiming mark.
/// Does not paint shots — wrap in a RepaintBoundary for performance.
class TargetFacePainter extends CustomPainter {
  const TargetFacePainter({
    required this.face,
    required this.moaMm,
    required this.transform,
  });

  final TargetFace face;

  /// Physical mm per MOA at this distance.
  final double moaMm;

  final ViewTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _colTargetBg,
    );

    _drawGrid(canvas, size);
    _drawAimingCross(canvas, size);
    _drawRings(canvas);
    _drawBorderAndLabel(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final outerMm = face.outerRing.radiusMm;

    // Number of MOA grid lines visible: from -VB to +VB SVG units → ±VB*outerMm/150 mm
    final halfExtentMm = _svgVb * outerMm / 150.0;
    final nSide = (halfExtentMm / moaMm).ceil() + 1;

    // Which grid line coincides with the outer ring?
    final outerRingMoa = (outerMm / moaMm).round();

    for (var i = -nSide; i <= nSide; i++) {
      final mm = i * moaMm;
      final px = transform.centrePixel.dx + mm * transform.pxPerMm;
      final py = transform.centrePixel.dy - mm * transform.pxPerMm; // y flipped

      Paint linePaint;
      if (i == 0) {
        linePaint = Paint()
          ..color = _colGrid0
          ..strokeWidth = 0.8;
      } else if (i.abs() == outerRingMoa) {
        linePaint = Paint()
          ..color = _colGridOuter
          ..strokeWidth = 0.6;
      } else {
        linePaint = Paint()
          ..color = _colGridNorm
          ..strokeWidth = 0.4;
      }

      // Horizontal line at y = py
      canvas.drawLine(Offset(0, py), Offset(size.width, py), linePaint);
      // Vertical line at x = px
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), linePaint);
    }
  }

  void _drawAimingCross(Canvas canvas, Size size) {
    final outerMm = face.outerRing.radiusMm;
    // VB extent in pixels
    final extPx = _svgVb * outerMm / 150.0 * transform.pxPerMm;
    // Aim mark extent (104/175 of VB in SVG = same ratio in mm)
    final aimPx = _svgAimMark * outerMm / 150.0 * transform.pxPerMm;
    final cx = transform.centrePixel.dx;
    final cy = transform.centrePixel.dy;

    final diagPaint = Paint()
      ..color = _colDiag
      ..strokeWidth = 1.0;
    final aimPaint = Paint()
      ..color = _colDiag
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      // Dash via shader trick not supported natively; use solid thin line
      ;

    // Full diagonal cross (corner to corner)
    canvas.drawLine(Offset(cx - extPx, cy - extPx), Offset(cx + extPx, cy + extPx), diagPaint);
    canvas.drawLine(Offset(cx + extPx, cy - extPx), Offset(cx - extPx, cy + extPx), diagPaint);

    // Aiming mark diagonals (shorter dashed-style cross)
    canvas.drawLine(Offset(cx - aimPx, cy - aimPx), Offset(cx + aimPx, cy + aimPx), aimPaint);
    canvas.drawLine(Offset(cx + aimPx, cy - aimPx), Offset(cx - aimPx, cy + aimPx), aimPaint);
  }

  void _drawRings(Canvas canvas) {
    final ringPaint = Paint()
      ..color = _colTargetInk
      ..style = PaintingStyle.stroke;

    for (var i = face.rings.length - 1; i >= 0; i--) {
      final ring = face.rings[i];
      final rPx = ring.radiusMm * transform.pxPerMm;
      // Thicker line for rings >= 14% of outer radius (matches Python lw logic)
      ringPaint.strokeWidth =
          ring.radiusMm >= face.outerRing.radiusMm * 0.14 ? 1.8 : 1.2;
      canvas.drawCircle(transform.centrePixel, rPx, ringPaint);
    }
  }

  void _drawBorderAndLabel(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = _colBorderBox
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '1 MOA · ${face.id}',
        style: const TextStyle(
          color: _colLabel,
          fontSize: 7,
          fontFamily: 'Courier',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(6, 5));
  }

  @override
  bool shouldRepaint(TargetFacePainter old) =>
      old.face != face || old.moaMm != moaMm || old.transform != transform;
}
