import 'package:targetsheet_core/analysis/analysis.dart';
import 'package:targetsheet_core/disciplines/target_faces.dart';
import 'package:targetsheet_core/geometry/coordinate_system.dart';
import 'package:targetsheet_core/geometry/moa_calculator.dart';
import 'package:targetsheet_core/scoring/scoring.dart';
import 'package:test/test.dart';

ScoredShot _shot(
  double xMm,
  double yMm, {
  ShotType type = ShotType.scored,
  double windMoa = 0,
  double elevMoa = 0,
  String? call,
}) {
  final rings = kTargetFaces['300y-nra']!.rings;
  final p = ModelPoint(xMm, yMm);
  final ring = p.magnitude <= rings.last.radiusMm ? rings.first : null;
  return ScoredShot(
    point: p,
    type: type,
    ring: ring,
    windMoa: windMoa,
    elevMoa: elevMoa,
    call: call,
  );
}

void main() {
  final moaMm = moaSizeAtYards(300); // ~79.78

  group('suggestedCorrection (y=UP)', () {
    test('shot at centre with wind=2 → suggest 2', () {
      final s = _shot(0, 0, windMoa: 2.0, elevMoa: 1.0);
      final r = suggestedCorrection(s, moaMm);
      expect(r.wind, closeTo(2.0, 1e-9));
      expect(r.elev, closeTo(1.0, 1e-9));
    });

    test('shot one MOA right → suggest reducing wind by 1', () {
      final s = _shot(moaMm, 0, windMoa: 3.0, elevMoa: 0.0);
      final r = suggestedCorrection(s, moaMm);
      expect(r.wind, closeTo(2.0, 1e-9));
    });

    test('shot one MOA above centre → suggest reducing elevation by 1 (y=UP)', () {
      // y=UP: shot at +moaMm means above centre, reduce elevation
      final s = _shot(0, moaMm, windMoa: 0.0, elevMoa: 3.0);
      final r = suggestedCorrection(s, moaMm);
      expect(r.elev, closeTo(2.0, 1e-9));
    });

    test('shot one MOA below centre → suggest increasing elevation by 1 (y=UP)', () {
      // y=UP: shot at -moaMm means below centre, increase elevation
      final s = _shot(0, -moaMm, windMoa: 0.0, elevMoa: 3.0);
      final r = suggestedCorrection(s, moaMm);
      expect(r.elev, closeTo(4.0, 1e-9));
    });
  });

  group('computeGroupStats', () {
    test('empty list returns no stats', () {
      final stats = computeGroupStats([], moaMm);
      expect(stats.shotCount, 0);
      expect(stats.meanPoint, isNull);
      expect(stats.extremeSpreadMoa, isNull);
    });

    test('single shot: no ES, MR = 0', () {
      final stats = computeGroupStats([_shot(10, 10)], moaMm);
      expect(stats.shotCount, 1);
      expect(stats.extremeSpreadMoa, isNull);
      expect(stats.meanRadiusMoa, closeTo(0, 1e-9));
    });

    test('two shots 2×moaMm apart → ES ≈ 2 MOA', () {
      final shots = [_shot(moaMm, 0), _shot(-moaMm, 0)];
      final stats = computeGroupStats(shots, moaMm);
      expect(stats.extremeSpreadMoa, closeTo(2.0, 1e-9));
    });

    test('symmetric group has MPI at origin', () {
      final shots = [
        _shot(moaMm, 0),
        _shot(-moaMm, 0),
        _shot(0, moaMm),
        _shot(0, -moaMm),
      ];
      final stats = computeGroupStats(shots, moaMm);
      expect(stats.meanPoint!.xMm, closeTo(0, 1e-9));
      expect(stats.meanPoint!.yMm, closeTo(0, 1e-9));
    });

    test('miss shots excluded from stats', () {
      // Create a shot outside the outer ring (should have ring=null)
      final outerMm = kTargetFaces['300y-nra']!.outerRing.radiusMm;
      final missShot = ScoredShot(
        point: ModelPoint(outerMm + 10, 0),
        type: ShotType.scored,
        ring: null,
        windMoa: 0,
        elevMoa: 0,
      );
      final stats = computeGroupStats([_shot(0, 0), missShot], moaMm);
      expect(stats.shotCount, 1);
    });
  });

  group('callBreakdown', () {
    test('counts calls correctly', () {
      final shots = [
        _shot(0, 0, call: 'good'),
        _shot(0, 0, call: 'good'),
        _shot(0, 0, call: 'pull-right'),
        _shot(0, 0, call: 'bad'),
        _shot(0, 0),               // no call
      ];
      final b = callBreakdown(shots);
      expect(b.good, 2);
      expect(b.pull, 1);
      expect(b.bad, 1);
      expect(b.total, 4);
    });
  });

  group('windLabel', () {
    test('0 → calm', () => expect(windLabel(0), 'calm'));
    test('2.5 → 2.5R', () => expect(windLabel(2.5), '2.5R'));
    test('-1.25 → 1.25L', () => expect(windLabel(-1.25), '1.25L'));
    test('3 → 3R (no decimal)', () => expect(windLabel(3.0), '3R'));
  });

  group('elevLabel', () {
    test('0 → 0', () => expect(elevLabel(0), '0'));
    test('1.5 → +1.5', () => expect(elevLabel(1.5), '+1.5'));
    test('-0.25 → -0.25', () => expect(elevLabel(-0.25), '-0.25'));
    test('2 → +2 (no decimal)', () => expect(elevLabel(2.0), '+2'));
  });
}
