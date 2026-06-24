import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:targetsheet_core/targetsheet_core.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

// ── JSON serialisation for ScoredShot ─────────────────────────────────────────

Map<String, dynamic> _shotToJson(ScoredShot s) => {
      'xMm': s.point.xMm,
      'yMm': s.point.yMm,
      'type': s.type.name,
      'score': s.score,
      'isVbull': s.isVbull,
      'label': s.label,
      'windMoa': s.windMoa,
      'elevMoa': s.elevMoa,
      'call': s.call,
    };

ScoredShot _shotFromJson(Map<String, dynamic> j, List<Ring> rings) {
  final p = ModelPoint(
    (j['xMm'] as num).toDouble(),
    (j['yMm'] as num).toDouble(),
  );
  final type = ShotType.values.byName(j['type'] as String);
  var ring = scoreShot(p, rings);
  // Restore exact saved score for decimal faces (avoids re-derivation drift).
  final savedScore = (j['score'] as num?)?.toDouble();
  if (savedScore != null && ring != null && savedScore != ring.score) {
    ring = Ring(
      score: savedScore,
      isVbull: ring.isVbull,
      label: savedScore == savedScore.truncateToDouble()
          ? savedScore.toInt().toString()
          : savedScore.toStringAsFixed(1),
      radiusMm: ring.radiusMm,
    );
  }
  return ScoredShot(
    point: p,
    type: type,
    ring: ring,
    windMoa: (j['windMoa'] as num).toDouble(),
    elevMoa: (j['elevMoa'] as num).toDouble(),
    call: j['call'] as String?,
  );
}

// ── Repository ────────────────────────────────────────────────────────────────

class ScorecardRepository {
  ScorecardRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  static const _draftId = '__draft__';

  Future<List<Scorecard>> allScorecards() =>
      (_db.select(_db.scorecards)
            ..where((t) => t.id.isNotValue(_draftId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // ── Draft (in-progress session) ───────────────────────────────────────────

  Future<void> saveDraft({
    required String faceId,
    required List<ScoredShot> shots,
    required Conversion conversion,
    required int shootLen,
    required double windMoa,
    required double elevMoa,
  }) async {
    if (shots.isEmpty) {
      await clearDraft();
      return;
    }
    final now = DateTime.now();
    final meta = jsonEncode({'w': windMoa, 'e': elevMoa});
    final shotsJson = jsonEncode(shots.map(_shotToJson).toList());
    await _db.into(_db.scorecards).insertOnConflictUpdate(
          ScorecardsCompanion.insert(
            id: _draftId,
            createdAt: now,
            updatedAt: now,
            faceId: faceId,
            conversion: conversion.name,
            shootLen: shootLen,
            targetNumber: Value(meta),
            savedAt: now.toIso8601String(),
            shotsJson: shotsJson,
          ),
        );
  }

  Future<void> clearDraft() async {
    await (_db.delete(_db.scorecards)
          ..where((t) => t.id.equals(_draftId)))
        .go();
  }

  /// Returns a draft if one exists, decoded into session fields.
  Future<({String faceId, List<ScoredShot> shots, Conversion conversion, int shootLen, double windMoa, double elevMoa})?> loadDraft() async {
    final row = await (_db.select(_db.scorecards)
          ..where((t) => t.id.equals(_draftId)))
        .getSingleOrNull();
    if (row == null) return null;
    final face = kTargetFaces[row.faceId];
    if (face == null) return null;
    final shots = decodeShotsFromRow(row);
    double w = 0, e = 0;
    try {
      final meta = jsonDecode(row.targetNumber) as Map<String, dynamic>;
      w = (meta['w'] as num?)?.toDouble() ?? 0;
      e = (meta['e'] as num?)?.toDouble() ?? 0;
    } catch (_) {}
    return (
      faceId: row.faceId,
      shots: shots,
      conversion: Conversion.values.byName(row.conversion),
      shootLen: row.shootLen,
      windMoa: w,
      elevMoa: e,
    );
  }

  Future<String> saveScorecard({
    required String faceId,
    required List<ScoredShot> shots,
    required Conversion conversion,
    required int shootLen,
    required String targetNumber,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    final shotsJson = jsonEncode(shots.map(_shotToJson).toList());

    await _db.into(_db.scorecards).insert(
          ScorecardsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            faceId: faceId,
            conversion: conversion.name,
            shootLen: shootLen,
            targetNumber: Value(targetNumber),
            savedAt: now.toIso8601String(),
            shotsJson: shotsJson,
          ),
        );
    return id;
  }

  Future<void> deleteScorecard(String id) async {
    await (_db.delete(_db.scorecards)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  List<ScoredShot> decodeShotsFromRow(Scorecard row) {
    final face  = kTargetFaces[row.faceId]!;
    final jList = jsonDecode(row.shotsJson) as List<dynamic>;
    return [
      for (final j in jList)
        _shotFromJson(j as Map<String, dynamic>, face.rings),
    ];
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final scorecardRepositoryProvider = Provider<ScorecardRepository>((ref) =>
    ScorecardRepository(ref.watch(databaseProvider)));
