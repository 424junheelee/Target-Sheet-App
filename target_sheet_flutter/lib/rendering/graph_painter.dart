import 'package:flutter/rendering.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

// Colour palette from constants.py
const Color _colAccent   = Color(0xFFBA7517);
const Color _colRedShot  = Color(0xFFE24B4A);
const Color _colText2    = Color(0xFF6B7280);
const Color _colGridLine = Color(0xFFE0E0E0);
const Color _colCentre   = Color(0xFF888888);
const Color _colBg       = Color(0xFFF7F2E8);

const double _pxPerMoa  = 24.0; // pixels per MOA on the value axis (GRAPH_PX_MOA)
const double _dotRadius = 3.0;

/// Elevation graph: elevation on the vertical axis, shots advancing left→right.
/// Mirrors graphs.py draw_elev_graph().
class ElevGraphPainter extends CustomPainter {
  const ElevGraphPainter({required this.series, required this.maxShots});

  /// Suggested corrections per shot, from [graphSeries].
  final List<({double wind, double elev})> series;
  final int maxShots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _colBg);

    const x0 = 22.0;
    final x1 = size.width - 6;
    const y0 = 18.0;
    final y1 = size.height - 20;
    if (x1 <= x0 || y1 <= y0) return;
    final cy = (y0 + y1) / 2;

    final center = series.isNotEmpty ? series.first.elev.roundToDouble() : 0.0;

    // Label
    _drawLabel(canvas, size.width / 2, 3, 'ELEV', anchor: TextAlign.center);

    // Horizontal grid lines
    final nSide = ((cy - y0) / _pxPerMoa).truncate();
    for (var off = -nSide; off <= nSide; off++) {
      final y = cy - off * _pxPerMoa;
      final isCenter = off == 0;
      final linePaint = Paint()
        ..color = isCenter ? _colCentre : _colGridLine
        ..strokeWidth = isCenter ? 1.0 : 0.5;
      canvas.drawLine(Offset(x0, y), Offset(x1, y), linePaint);
      _drawLabel(canvas, 2, y, '${(center + off).toInt()}',
          anchor: TextAlign.left,
          color: isCenter ? _colAccent : _colText2,
          bold: isCenter);
    }

    if (series.isEmpty || maxShots < 2) return;

    final step = (x1 - x0) / (maxShots - 1);

    // Vertical shot-index grid lines
    for (var k = 0; k < maxShots; k++) {
      final x = x0 + k * step;
      canvas.drawLine(Offset(x, y0), Offset(x, y1),
          Paint()
            ..color = const Color(0xFFF0F0F0)
            ..strokeWidth = 0.4);
      _drawLabel(canvas, x, size.height - 10, '${k + 1}',
          anchor: TextAlign.center, rotate: true);
    }

    // Plot line + dots
    final pts = <Offset>[];
    for (var i = 0; i < series.length && i < maxShots; i++) {
      final y = (cy - (series[i].elev - center) * _pxPerMoa)
          .clamp(y0, y1);
      pts.add(Offset(x0 + i * step, y));
    }
    _drawSeries(canvas, pts);
  }

  @override
  bool shouldRepaint(ElevGraphPainter old) =>
      old.series != series || old.maxShots != maxShots;
}

/// Wind graph: wind on the horizontal axis, shots advancing top→bottom.
/// Mirrors graphs.py draw_wind_graph().
class WindGraphPainter extends CustomPainter {
  const WindGraphPainter({required this.series, required this.maxShots});

  final List<({double wind, double elev})> series;
  final int maxShots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _colBg);

    const x0 = 26.0;
    final x1 = size.width - 14;
    const y0 = 16.0;
    final y1 = size.height - 18;
    if (x1 <= x0 || y1 <= y0) return;
    final cx = (x0 + x1) / 2;

    final center = series.isNotEmpty ? series.first.wind.roundToDouble() : 0.0;

    // Label
    _drawLabel(canvas, 3, 3, 'WIND', anchor: TextAlign.left);

    // Vertical grid lines
    final nSide = ((cx - x0) / _pxPerMoa).truncate();
    for (var off = -nSide; off <= nSide; off++) {
      final x = cx + off * _pxPerMoa;
      final isCenter = off == 0;
      final linePaint = Paint()
        ..color = isCenter ? _colCentre : _colGridLine
        ..strokeWidth = isCenter ? 1.0 : 0.5;
      canvas.drawLine(Offset(x, y0), Offset(x, y1), linePaint);
      _drawLabel(canvas, x, size.height - 8, '${(center + off).toInt()}',
          anchor: TextAlign.center,
          color: isCenter ? _colAccent : _colText2,
          bold: isCenter);
    }

    if (series.isEmpty || maxShots < 2) return;

    final step = (y1 - y0) / (maxShots - 1);

    // Horizontal shot-index grid lines
    for (var k = 0; k < maxShots; k++) {
      final y = y0 + k * step;
      canvas.drawLine(Offset(x0, y), Offset(x1, y),
          Paint()
            ..color = const Color(0xFFF0F0F0)
            ..strokeWidth = 0.4);
      _drawLabel(canvas, 3, y, '${k + 1}',
          anchor: TextAlign.left);
    }

    // Plot line + dots
    final pts = <Offset>[];
    for (var i = 0; i < series.length && i < maxShots; i++) {
      final x = (cx + (series[i].wind - center) * _pxPerMoa)
          .clamp(x0, x1);
      pts.append(Offset(x, y0 + i * step));
    }
    _drawSeries(canvas, pts);
  }

  @override
  bool shouldRepaint(WindGraphPainter old) =>
      old.series != series || old.maxShots != maxShots;
}

// ── Shared helpers ────────────────────────────────────────────────────────────

void _drawSeries(Canvas canvas, List<Offset> pts) {
  if (pts.length >= 2) {
    final linePaint = Paint()
      ..color = _colAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, linePaint);
  }
  for (final p in pts) {
    canvas.drawCircle(p, _dotRadius, Paint()..color = _colRedShot);
  }
}

void _drawLabel(
  Canvas canvas,
  double x,
  double y,
  String text, {
  TextAlign anchor = TextAlign.left,
  Color color = _colText2,
  bool bold = false,
  bool rotate = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 7,
        fontFamily: 'Courier',
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    textAlign: anchor,
    textDirection: TextDirection.ltr,
  )..layout();

  Offset origin;
  switch (anchor) {
    case TextAlign.center:
      origin = Offset(x - tp.width / 2, y - tp.height / 2);
    case TextAlign.right:
      origin = Offset(x - tp.width, y - tp.height / 2);
    default:
      origin = Offset(x, y - tp.height / 2);
  }

  if (rotate) {
    canvas.save();
    canvas.translate(origin.dx + tp.width / 2, origin.dy + tp.height / 2);
    canvas.rotate(-3.14159 / 2);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  } else {
    tp.paint(canvas, origin);
  }
}

extension _ListAppend<T> on List<T> {
  void append(T item) => add(item);
}
