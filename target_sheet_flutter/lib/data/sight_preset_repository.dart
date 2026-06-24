import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'scorecard_repository.dart' show databaseProvider;

class SightPresetRepository {
  SightPresetRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<List<SightPreset>> presetsForFace(String faceId) =>
      (_db.select(_db.sightPresets)
            ..where((t) => t.faceId.equals(faceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<void> savePreset({
    required String faceId,
    required double windMoa,
    required double elevMoa,
    required String label,
    String aperture = '',
  }) async {
    final now = DateTime.now();
    await _db.into(_db.sightPresets).insertOnConflictUpdate(
          SightPresetsCompanion.insert(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            faceId: faceId,
            windMoa: windMoa,
            elevMoa: elevMoa,
            label: Value(label),
            aperture: Value(aperture),
          ),
        );
  }

  Future<void> deletePreset(String id) async {
    await (_db.delete(_db.sightPresets)..where((t) => t.id.equals(id))).go();
  }
}

final sightPresetRepositoryProvider = Provider<SightPresetRepository>((ref) =>
    SightPresetRepository(ref.watch(databaseProvider)));
