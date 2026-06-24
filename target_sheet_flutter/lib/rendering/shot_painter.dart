import 'package:flutter/rendering.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import 'view_transform.dart';

// Colour palette from constants.py
const Color _colRedShot  = Color(0xFFE24B4A);
const Color _colGrayShot = Color(0xFF9EAAB5);
const Color _colGoldRing = Color(0xFFEF9F27);
const Color _colGrayRing = Color(0xFFB5C0C7);
const Color _colAccent   = Color(0xFFBA7517);

// Shot radius = 6.5 SVG units × scale; V-bull outer ring = 9.5 SVG units × scale.
// In model space: 6.5 SVG × (outerMm/150) mm = shotRadiusMm.
// We express these as fractions of the outer-ring radius.
const double _shotRadiusFraction  = 6.5 / 150.0;
const double _vRingRadiusFraction = 9.5 / 150.0;

/// Dynamic CustomPainter for committed shots and the drag-preview marker.
/// Placed above the static [TargetFacePainter] layer.
class ShotPainter extends CustomPainter {
  const ShotPainter({
    required this.shots,
    required this.labels,
    required this.transform,
    required this.outerRingMm,
    this.provisional,
    this.conversion = Conversion.none,
  });

  final List<ScoredShot> shots;
  final List<String> labels;
  final ViewTransform transform;
  final double outerRingMm;

  /// Canvas pixel under the finger while dragging; null when not dragging.
  final Offset? provisional;

  final Conversion conversion;

  @override
  void paint(Canvas canvas, Size size) {
    final shotRadiusPx = outerRingMm * transform.pxPerMm * _shotRadiusFraction;
    final vRingPx      = outerRingMm * transform.pxPerMm * _vRingRadiusFraction;

    for (var i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final lbl  = labels[i];
      final centre = transform.toCanvas(shot.point);

      final isSighter  = shot.type == ShotType.sighterA ||
                         shot.type == ShotType.sighterB;
      final isConverted =
          (shot.type == ShotType.sighterB &&
              (conversion == Conversion.b || conversion == Conversion.ab)) ||
          (shot.type == ShotType.sighterA && conversion == Conversion.ab);

      final fillCol = (isSighter && !isConverted) ? _colGrayShot : _colRedShot;
      final ringCol = (isSighter && !isConverted) ? _colGrayRing : _colGoldRing;

      // V-bull outer ring
      if (shot.isVbull) {
        canvas.drawCircle(
          centre, vRingPx,
          Paint()
            ..color = ringCol
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // Shot dot
      canvas.drawCircle(centre, shotRadiusPx, Paint()..color = fillCol);

      // Label
      final textColor =
          (isSighter && !isConverted) ? const Color(0xFF374151) : const Color(0xFFFFFFFF);
      final tp = TextPainter(
        text: TextSpan(
          text: lbl,
          style: TextStyle(
            color: textColor,
            fontSize: (shotRadiusPx * 1.2).clamp(6.0, 14.0),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        centre - Offset(tp.width / 2, tp.height / 2),
      );
    }

    // Drag-preview marker (dashed circle + crosshair)
    if (provisional != null) {
      final r = shotRadiusPx;
      final previewPaint = Paint()
        ..color = _colAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(provisional!, r, previewPaint);
      canvas.drawLine(
        Offset(provisional!.dx - r * 1.6, provisional!.dy),
        Offset(provisional!.dx + r * 1.6, provisional!.dy),
        previewPaint..strokeWidth = 1.0,
      );
      canvas.drawLine(
        Offset(provisional!.dx, provisional!.dy - r * 1.6),
        Offset(provisional!.dx, provisional!.dy + r * 1.6),
        previewPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ShotPainter old) =>
      old.shots != shots ||
      old.provisional != provisional ||
      old.labels != labels ||
      old.transform != transform ||
      old.conversion != conversion;
}

