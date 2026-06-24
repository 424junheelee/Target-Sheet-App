import 'package:targetsheet_core/disciplines/ring.dart';
import 'package:targetsheet_core/disciplines/target_face.dart';
import 'package:targetsheet_core/disciplines/target_faces.dart';
import 'package:targetsheet_core/geometry/coordinate_system.dart';
import 'package:targetsheet_core/geometry/moa_calculator.dart';
import 'package:targetsheet_core/scoring/scoring.dart';
import 'package:test/test.dart';

List<Ring> get _nra300yRings => kTargetFaces['300y-nra']!.rings;

ScoredShot _shot(
  double xMm,
  double yMm,
  List<Ring> rings, {
  ShotType type = ShotType.scored,
}) {
  final p = ModelPoint(xMm, yMm);
  final ring = scoreShot(p, rings);
  return ScoredShot(
    point: p,
    type: type,
    ring: ring,
    windMoa: 0,
    elevMoa: 0,
  );
}

void main() {
  final rings = _nra300yRings;
  // NRA 300y: V=25.4mm, 5=76.2mm, 4=152.4mm, 3=304.8mm, 2=558.8mm

  group('scoreShot — ring containment (inward gauging)', () {
    test('centre (0,0) scores V', () {
      expect(scoreShot(ModelPoint.zero, rings)!.label, 'V');
    });

    test('touching V-ring edge scores V (d == V radius)', () {
      final vRadius = rings.first.radiusMm;
      expect(scoreShot(ModelPoint(vRadius, 0), rings)!.label, 'V');
    });

    test('just outside V scores 5', () {
      final vRadius = rings.first.radiusMm;
      expect(scoreShot(ModelPoint(vRadius + 0.001, 0), rings)!.label, '5');
    });

    test('touching 5-ring edge scores 5', () {
      final r5 = rings[1].radiusMm;
      expect(scoreShot(ModelPoint(r5, 0), rings)!.label, '5');
    });

    test('just outside 2-ring is a miss', () {
      final outer = rings.last.radiusMm;
      expect(scoreShot(ModelPoint(outer + 0.001, 0), rings), isNull);
    });

    test('touching outer ring scores 2', () {
      final outer = rings.last.radiusMm;
      expect(scoreShot(ModelPoint(outer, 0), rings)!.label, '2');
    });

    test('diagonal (3-4-5 triangle) scores correctly', () {
      // (3, 4) has magnitude 5; 5mm is inside V (25.4mm radius) → V
      expect(scoreShot(const ModelPoint(3, 4), rings)!.label, 'V');
    });
  });

  group('snap', () {
    test('0.0 → 0.0', () => expect(snap(0.0), 0.0));
    test('0.1 → 0.0', () => expect(snap(0.1), 0.0));
    test('0.13 → 0.25', () => expect(snap(0.13), 0.25));
    test('0.5 → 0.5', () => expect(snap(0.5), 0.5));
    test('1.37 → 1.25', () => expect(snap(1.37), 1.25));
    test('−0.5 → −0.5', () => expect(snap(-0.5), -0.5));
    test('−1.2 → −1.25', () => expect(snap(-1.2), -1.25));
  });

  group('clamp', () {
    test('0 passes through', () => expect(clamp(0), 0));
    test('200 passes through', () => expect(clamp(200), 200));
    test('201 clamped to 200', () => expect(clamp(201), 200));
    test('−201 clamped to −200', () => expect(clamp(-201), -200));
  });

  // NRA 300y ring radii: V=25.4mm, 5=76.2mm, 4=152.4mm, 3=304.8mm, 2=558.8mm
  group('calcTotal — conversion=none', () {
    final s = [
      _shot(0, 0, rings, type: ShotType.sighterA),  // V (not counted)
      _shot(0, 0, rings, type: ShotType.sighterB),  // V (not counted)
      _shot(0, 0, rings),   // V → 5V
      _shot(50, 0, rings),  // inside 5-ring (76.2mm) → 5
      _shot(100, 0, rings), // inside 4-ring (152.4mm) → 4
    ];
    final t = calcTotal(s, Conversion.none, 10);
    test('only scored shots counted', () => expect(t.n, 3));
    test('total = 5+5+4 = 14', () => expect(t.tot, 14.0));
    test('V count = 1', () => expect(t.v, 1));
  });

  group('calcTotal — conversion=b', () {
    final s = [
      _shot(0, 0, rings, type: ShotType.sighterA),
      _shot(0, 0, rings, type: ShotType.sighterB), // V → becomes shot 1
      _shot(50, 0, rings),  // 5 → shot 2
      _shot(50, 0, rings),  // 5 → shot 3
    ];
    final t = calcTotal(s, Conversion.b, 10);
    test('n = 3 (B + 2 scored)', () => expect(t.n, 3));
    test('total = V(5)+5+5 = 15', () => expect(t.tot, 15.0));
    test('V count = 1', () => expect(t.v, 1));
  });

  group('calcTotal — conversion=ab', () {
    final s = [
      _shot(0, 0, rings, type: ShotType.sighterA),  // V → shot 1
      _shot(0, 0, rings, type: ShotType.sighterB),  // V → shot 2
      _shot(50, 0, rings),  // 5 → shot 3
    ];
    final t = calcTotal(s, Conversion.ab, 10);
    test('n = 3 (A + B + 1 scored)', () => expect(t.n, 3));
    test('total = V+V+5 = 15', () => expect(t.tot, 15.0));
    test('V count = 2', () => expect(t.v, 2));
  });

  group('calcTotal — respects shootLen cap', () {
    // If conversion=b (maxSc=9), and 10 scored shots exist, only 9 count.
    final shots = [
      _shot(0, 0, rings, type: ShotType.sighterA),
      _shot(0, 0, rings, type: ShotType.sighterB),
      ...[for (var i = 0; i < 10; i++) _shot(200, 0, rings)],
    ];
    final t = calcTotal(shots, Conversion.b, 10);
    test('caps at 10 total (B + 9 scored)', () => expect(t.n, 10));
  });

  group('nextShotType', () {
    test('no shots → sighterA', () {
      expect(nextShotType([], Conversion.none, 10), ShotType.sighterA);
    });
    test('1 shot → sighterB', () {
      final s = [_shot(0, 0, rings, type: ShotType.sighterA)];
      expect(nextShotType(s, Conversion.none, 10), ShotType.sighterB);
    });
    test('A+B → scored', () {
      final s = [
        _shot(0, 0, rings, type: ShotType.sighterA),
        _shot(0, 0, rings, type: ShotType.sighterB),
      ];
      expect(nextShotType(s, Conversion.none, 10), ShotType.scored);
    });
    test('string complete → null', () {
      final shots = [
        _shot(0, 0, rings, type: ShotType.sighterA),
        _shot(0, 0, rings, type: ShotType.sighterB),
        ...[for (var i = 0; i < 10; i++) _shot(200, 0, rings)],
      ];
      expect(nextShotType(shots, Conversion.none, 10), isNull);
    });
  });

  group('dialToRecommendation (y=UP)', () {
    final moaMm = moaSizeAtYards(300); // ~79.78 mm

    test('all shots at centre → recommend current dials', () {
      final shots = [_shot(0, 0, rings), _shot(0, 0, rings)];
      final r = dialToRecommendation(
        shots: shots,
        moaMm: moaMm,
        currentWind: 2.0,
        currentElev: 1.0,
      )!;
      expect(r.w, closeTo(2.0, 0.001));
      expect(r.e, closeTo(1.0, 0.001));
    });

    test('group right of centre → reduce wind', () {
      // Mean x = moaMm (one MOA right), so rec = current - 1 MOA
      final shots = [_shot(moaMm, 0, rings)];
      final r = dialToRecommendation(
        shots: shots,
        moaMm: moaMm,
        currentWind: 3.0,
        currentElev: 0.0,
      )!;
      expect(r.w, closeTo(2.0, 0.001));
    });

    test('group above centre → reduce elevation (y=UP)', () {
      // Mean y = moaMm (one MOA up), so elev rec = current - 1 MOA
      final shots = [_shot(0, moaMm, rings)];
      final r = dialToRecommendation(
        shots: shots,
        moaMm: moaMm,
        currentWind: 0.0,
        currentElev: 3.0,
      )!;
      expect(r.e, closeTo(2.0, 0.001));
    });
  });

  group('decimal scoring (ISSF 10m)', () {
    final issf = kTargetFaces['10m-issf']!;

    test('shot at centre scores 10.9 (inner-10)', () {
      const p = ModelPoint(0, 0);
      final ring = scoreShot(p, issf.rings, scoringMode: ScoringMode.decimal);
      expect(ring?.score, closeTo(10.9, 0.001));
      expect(ring?.isVbull, isTrue);
    });

    test('shot at radius 0.5 mm scores 10.7', () {
      const p = ModelPoint(0.5, 0); // d = 0.5, steps = floor(0.5/0.25) = 2
      final ring = scoreShot(p, issf.rings, scoringMode: ScoringMode.decimal);
      expect(ring?.score, closeTo(10.7, 0.001));
    });

    test('shot at radius 2.75 mm scores 10.0 (outer edge of 10-ring)', () {
      const p = ModelPoint(2.75, 0); // d = 2.75, steps = floor(2.75/0.25) = 11
      // 10.9 - 0.9 = 10.0 (minimum for 10-ring)
      final ring = scoreShot(p, issf.rings, scoringMode: ScoringMode.decimal);
      expect(ring?.score, closeTo(10.0, 0.001));
    });

    test('shot at radius 3.0 mm is in 9-ring, scores 9.0 (not decimal-adjusted)', () {
      const p = ModelPoint(3.0, 0); // beyond 10-ring radius 2.75
      final ring = scoreShot(p, issf.rings, scoringMode: ScoringMode.decimal);
      expect(ring?.score, closeTo(9.0, 0.001));
    });

    test('miss outside all rings returns null', () {
      const p = ModelPoint(25.0, 0); // beyond 22.75 mm outer ring
      final ring = scoreShot(p, issf.rings, scoringMode: ScoringMode.decimal);
      expect(ring, isNull);
    });

    test('integer mode ignores decimal refinement', () {
      // d=0.5 > inner-10 radius (0.25), so the 10-ring (score 10.0) is matched.
      // Integer mode returns the ring as-is without decimal adjustment.
      const p = ModelPoint(0.5, 0);
      final ring = scoreShot(p, issf.rings); // no scoringMode param
      expect(ring?.score, closeTo(10.0, 0.001));
    });
  });
}
