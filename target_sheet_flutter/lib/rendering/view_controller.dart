import 'package:flutter/painting.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import 'view_transform.dart';

const double _minZoom = 0.5;
const double _maxZoom = 8.0;

/// Manages zoom and pan state for the target canvas.
/// Converts between canvas pixels and model mm via [buildTransform].
class ViewController {
  ViewController();

  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  double get zoom => _zoom;
  Offset get pan => _pan;

  /// Build the current [ViewTransform] for [canvasSize] and [face].
  ViewTransform buildTransform(Size canvasSize, TargetFace face) =>
      ViewTransform.fitWithZoom(canvasSize, face, _zoom, _pan);

  void reset() {
    _zoom = 1.0;
    _pan = Offset.zero;
  }

  /// Apply focal-point zoom centred on [focalPixel] (canvas coordinates).
  /// [factor] > 1 zooms in, < 1 zooms out.
  void applyFocalZoom(Offset focalPixel, Size canvasSize, double factor) {
    final newZoom = (_zoom * factor).clamp(_minZoom, _maxZoom);
    final actualFactor = newZoom / _zoom;
    final centre = Offset(canvasSize.width / 2, canvasSize.height / 2);
    // Adjust pan so the focal point stays fixed on screen
    _pan = focalPixel - centre - (focalPixel - centre - _pan) * actualFactor;
    _zoom = newZoom;
  }

  void applyPanDelta(Offset delta) {
    _pan += delta;
  }
}
