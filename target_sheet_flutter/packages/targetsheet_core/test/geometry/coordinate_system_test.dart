import 'package:targetsheet_core/geometry/coordinate_system.dart';
import 'package:test/test.dart';

void main() {
  group('ModelPoint.fromSvg', () {
    // NRA 300y outer ring: 22.0 in × 25.4 = 558.8 mm
    const outerMm = 22.0 * 25.4; // 558.8

    test('origin maps to zero', () {
      final p = ModelPoint.fromSvg(0, 0, outerMm);
      expect(p.xMm, closeTo(0.0, 1e-9));
      expect(p.yMm, closeTo(0.0, 1e-9));
    });

    test('positive SVG-x maps to positive model-x', () {
      final p = ModelPoint.fromSvg(150, 0, outerMm);
      expect(p.xMm, closeTo(outerMm, 1e-6)); // outer edge rightward
    });

    test('SVG y=DOWN flips to model y=UP', () {
      final p = ModelPoint.fromSvg(0, 150, outerMm);
      expect(p.yMm, closeTo(-outerMm, 1e-6)); // SVG bottom → model below centre
    });

    test('scale factor is outerRadiusMm / 150', () {
      const outerMm2 = 100.0;
      final p = ModelPoint.fromSvg(75, 0, outerMm2);
      expect(p.xMm, closeTo(50.0, 1e-9)); // 75 × (100/150) = 50
    });
  });

  group('ModelPoint.toSvg round-trip', () {
    test('fromSvg → toSvg returns original coordinates', () {
      const outerMm = 558.8;
      const svgX = 42.5;
      const svgY = -18.0;
      final p = ModelPoint.fromSvg(svgX, svgY, outerMm);
      final (rx, ry) = p.toSvg(outerMm);
      expect(rx, closeTo(svgX, 1e-9));
      expect(ry, closeTo(svgY, 1e-9));
    });
  });

  group('ModelPoint arithmetic', () {
    test('addition', () {
      const a = ModelPoint(1, 2);
      const b = ModelPoint(3, -1);
      expect(a + b, equals(const ModelPoint(4, 1)));
    });

    test('subtraction', () {
      const a = ModelPoint(5, 3);
      const b = ModelPoint(2, 4);
      expect(a - b, equals(const ModelPoint(3, -1)));
    });

    test('scale', () {
      const p = ModelPoint(4, -2);
      expect(p.scale(0.5), equals(const ModelPoint(2, -1)));
    });

    test('magnitude of (3, 4) is 5', () {
      const p = ModelPoint(3, 4);
      expect(p.magnitude, closeTo(5.0, 1e-9));
    });

    test('distanceTo', () {
      const a = ModelPoint(0, 0);
      const b = ModelPoint(3, 4);
      expect(a.distanceTo(b), closeTo(5.0, 1e-9));
    });
  });
}
