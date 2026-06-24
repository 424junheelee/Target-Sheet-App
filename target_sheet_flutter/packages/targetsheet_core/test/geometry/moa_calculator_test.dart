import 'package:targetsheet_core/geometry/moa_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('moaSizeAtYards', () {
    // Formula: yards × 0.01047 × 25.4
    // 300 × 0.01047 × 25.4 = 79.7814
    test('300y → ~79.78 mm', () {
      expect(moaSizeAtYards(300), closeTo(79.78, 0.01));
    });

    // 1000 × 0.01047 × 25.4 = 265.938
    test('1000y → ~265.94 mm', () {
      expect(moaSizeAtYards(1000), closeTo(265.94, 0.01));
    });

    test('scales linearly', () {
      expect(moaSizeAtYards(600), closeTo(moaSizeAtYards(300) * 2, 1e-9));
    });
  });

  group('moaSizeAtMetres', () {
    // Formula: metres × 1.09361 × 0.01047 × 25.4
    test('300m → ~87.25 mm', () {
      expect(moaSizeAtMetres(300), closeTo(87.25, 0.05));
    });

    test('metres > yards equivalent for same numeric distance', () {
      // 300m > 300y because metres are longer than yards
      expect(moaSizeAtMetres(300), greaterThan(moaSizeAtYards(300)));
    });

    test('300m ≈ 328.08y equivalent', () {
      // 300 × 1.09361 = 328.083 yards
      expect(moaSizeAtMetres(300), closeTo(moaSizeAtYards(300 * 1.09361), 1e-6));
    });
  });

  group('NRA outer ring sanity', () {
    // NRA 300y outer ring = 22.0 in = 558.8 mm radius
    // At 300y, 1 MOA ≈ 79.84mm; outer ring spans ~7 MOA
    test('NRA 300y outer ring is 22 inches = 558.8 mm', () {
      expect(22.0 * 25.4, closeTo(558.8, 0.01));
    });
  });
}
