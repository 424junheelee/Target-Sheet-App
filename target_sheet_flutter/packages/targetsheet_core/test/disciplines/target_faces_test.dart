import 'package:targetsheet_core/disciplines/target_face.dart';
import 'package:targetsheet_core/disciplines/target_faces.dart';
import 'package:test/test.dart';

// Expected mm radii from targets.py (authoritative).  All = inches × 25.4.

void main() {
  group('NRA 300y face', () {
    final f = kTargetFaces['300y-nra']!;

    test('5 rings total', () => expect(f.rings.length, 5));
    test('V-bull radiusMm ≈ 1.0 × 25.4 = 25.4', () {
      expect(f.vRing.radiusMm, closeTo(1.0 * 25.4, 1e-6));
    });
    test('5-ring radiusMm ≈ 3.0 × 25.4 = 76.2', () {
      expect(f.rings[1].radiusMm, closeTo(3.0 * 25.4, 1e-6));
    });
    test('outer ring radiusMm ≈ 22.0 × 25.4 = 558.8', () {
      expect(f.outerRing.radiusMm, closeTo(22.0 * 25.4, 1e-6));
    });
    test('V/5 ratio = 1.0/3.0 ≈ 0.333', () {
      expect(f.vRing.radiusMm / f.rings[1].radiusMm, closeTo(1.0 / 3.0, 1e-6));
    });
    test('yards = 300', () => expect(f.yards, 300));
    test('metres is null', () => expect(f.metres, isNull));
  });

  group('NRA 500y–1000y same face', () {
    // All share the Fig 12 face: outer = 36.0 in
    for (final dist in ['500y', '600y', '700y', '800y', '900y', '1000y']) {
      test('$dist-nra outer = 36.0 in', () {
        expect(
          kTargetFaces['$dist-nra']!.outerRing.radiusMm,
          closeTo(36.0 * 25.4, 1e-6),
        );
      });
    }
  });

  group('DCRA SR face (300y-dcra, 300m-dcra)', () {
    test('300y-dcra V radiusMm ≈ 1.378 × 25.4', () {
      expect(
        kTargetFaces['300y-dcra']!.vRing.radiusMm,
        closeTo(1.378 * 25.4, 1e-6),
      );
    });
    test('300m-dcra outer radiusMm ≈ 11.811 × 25.4', () {
      expect(
        kTargetFaces['300m-dcra']!.outerRing.radiusMm,
        closeTo(11.811 * 25.4, 1e-6),
      );
    });
    test('300m-dcra uses metres, not yards', () {
      final f = kTargetFaces['300m-dcra']!;
      expect(f.metres, 300);
      expect(f.yards, isNull);
    });
  });

  group('DCRA MR face (500-600)', () {
    test('500y-dcra outer = 25.984 in', () {
      expect(
        kTargetFaces['500y-dcra']!.outerRing.radiusMm,
        closeTo(25.984 * 25.4, 1e-6),
      );
    });
    test('600m-dcra same outer as 500m-dcra', () {
      expect(
        kTargetFaces['600m-dcra']!.outerRing.radiusMm,
        closeTo(kTargetFaces['500m-dcra']!.outerRing.radiusMm, 1e-9),
      );
    });
  });

  group('DCRA LR face (700-1000)', () {
    test('1000y-dcra outer = 36.024 in', () {
      expect(
        kTargetFaces['1000y-dcra']!.outerRing.radiusMm,
        closeTo(36.024 * 25.4, 1e-6),
      );
    });
  });

  group('effectiveYards', () {
    test('yards face returns yards as double', () {
      expect(kTargetFaces['300y-nra']!.effectiveYards, closeTo(300.0, 1e-9));
    });
    test('metric face converts metres to yards', () {
      // 300 × 1.09361 = 328.083
      expect(
        kTargetFaces['300m-dcra']!.effectiveYards,
        closeTo(300 * 1.09361, 1e-9),
      );
    });
  });

  group('kTargetFaces coverage', () {
    test('has 22 faces total (7 NRA + 7 DCRA yards + 7 DCRA metric + 1 ISSF)', () {
      expect(kTargetFaces.length, 22);
    });
  });

  group('ISSF 10m Air Rifle face', () {
    final f = kTargetFaces['10m-issf']!;

    test('10 rings total', () => expect(f.rings.length, 10));
    test('scoringMode is decimal', () {
      expect(f.scoringMode, ScoringMode.decimal);
    });
    test('defaultShotCount is 60', () => expect(f.defaultShotCount, 60));
    test('unlimitedSighters is true', () => expect(f.unlimitedSighters, isTrue));
    test('metres = 10', () => expect(f.metres, 10));
    test('yards is null', () => expect(f.yards, isNull));
    test('inner-10 (X) radius = 0.25 mm', () {
      expect(f.vRing.radiusMm, closeTo(0.25, 1e-9));
    });
    test('inner-10 score = 10.9', () {
      expect(f.vRing.score, closeTo(10.9, 1e-9));
    });
    test('outer ring radius = 22.75 mm', () {
      expect(f.outerRing.radiusMm, closeTo(22.75, 1e-9));
    });
    test('outer ring score = 2.0', () {
      expect(f.outerRing.score, closeTo(2.0, 1e-9));
    });
  });
}
