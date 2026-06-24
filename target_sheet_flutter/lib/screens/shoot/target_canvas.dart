import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import '../../providers/session_provider.dart';
import '../../rendering/shot_painter.dart';
import '../../rendering/target_painter.dart';
import '../../rendering/view_controller.dart';

const double _loupeRadius = 56.0;
const double _loupeZoom   = 2.5;
// Loupe is offset this many pixels above the touch point
const double _loupeOffsetY = 110.0;

/// Zoomable, pannable target canvas with shot placement, loupe, and undo.
class TargetCanvas extends ConsumerStatefulWidget {
  const TargetCanvas({super.key});

  @override
  ConsumerState<TargetCanvas> createState() => _TargetCanvasState();
}

class _TargetCanvasState extends ConsumerState<TargetCanvas> {
  final _vc = ViewController();

  // Drag state
  Offset? _provisional;     // canvas-pixel position while finger is down
  bool _isDragging = false;

  Size _lastSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final face    = session.face;
    final moaMm   = session.moaMm;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _lastSize = size;
        final transform = _vc.buildTransform(size, face);
        final labels = shotDisplayLabels(session.shots, session.conversion);

        return GestureDetector(
          // Single-finger: place shot
          onPanStart: (d) {
            setState(() {
              _isDragging = true;
              _provisional = d.localPosition;
            });
          },
          onPanUpdate: (d) {
            setState(() => _provisional = d.localPosition);
          },
          onPanEnd: (_) {
            if (_provisional != null) {
              final point = transform.fromCanvas(_provisional!);
              ref.read(sessionProvider.notifier).addShot(point);
            }
            setState(() {
              _provisional = null;
              _isDragging = false;
            });
          },
          child: Stack(
            children: [
              // Static face layer
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: TargetFacePainter(
                      face: face,
                      moaMm: moaMm,
                      transform: transform,
                    ),
                  ),
                ),
              ),
              // Dynamic shot layer
              Positioned.fill(
                child: CustomPaint(
                  painter: ShotPainter(
                    shots: session.shots,
                    labels: labels,
                    transform: transform,
                    outerRingMm: face.outerRing.radiusMm,
                    provisional: _provisional,
                    conversion: session.conversion,
                  ),
                ),
              ),
              // Loupe overlay while dragging
              if (_isDragging && _provisional != null)
                _buildLoupe(_provisional!, transform, face, moaMm, session, labels),
              // Reset-view button
              Positioned(
                right: 8,
                top: 8,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFFFF).withAlpha(204),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => setState(() => _vc.reset()),
                  child: const Text('Reset view'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoupe(
    Offset touchPx,
    dynamic transform,  // ViewTransform
    TargetFace face,
    double moaMm,
    ShootSessionState session,
    List<String> labels,
  ) {
    // Centre of loupe on screen
    final loupeCx = touchPx.dx.clamp(_loupeRadius, _lastSize.width - _loupeRadius);
    final loupeCy = (touchPx.dy - _loupeOffsetY).clamp(_loupeRadius, _lastSize.height - _loupeRadius);
    final loupeCenter = Offset(loupeCx, loupeCy);

    // Build a magnified transform centred on the touch point
    final loupeTransform = _vc.buildTransform(_lastSize, face);

    return Positioned(
      left: loupeCenter.dx - _loupeRadius,
      top:  loupeCenter.dy - _loupeRadius,
      width:  _loupeRadius * 2,
      height: _loupeRadius * 2,
      child: ClipOval(
        child: Transform.translate(
          offset: Offset(
            _loupeRadius - touchPx.dx * _loupeZoom,
            _loupeRadius - touchPx.dy * _loupeZoom,
          ),
          child: Transform.scale(
            scale: _loupeZoom,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _lastSize.width,
              height: _lastSize.height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: _lastSize,
                    painter: TargetFacePainter(
                      face: face,
                      moaMm: moaMm,
                      transform: loupeTransform,
                    ),
                  ),
                  CustomPaint(
                    size: _lastSize,
                    painter: ShotPainter(
                      shots: session.shots,
                      labels: labels,
                      transform: loupeTransform,
                      outerRingMm: face.outerRing.radiusMm,
                      provisional: touchPx,
                      conversion: session.conversion,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
