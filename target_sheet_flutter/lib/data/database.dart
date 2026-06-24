import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

/// A committed scorecard string (one series of shots at one distance).
class Scorecards extends Table {
  // Sync-ready identity (PLAN.md §invariant)
  TextColumn get id           => text()();          // UUID
  DateTimeColumn get createdAt   => dateTime()();
  DateTimeColumn get updatedAt   => dateTime()();
  IntColumn get formatVersion  => integer().withDefault(const Constant(1))();

  // Domain fields
  TextColumn get faceId       => text()();          // e.g. "300y-nra"
  TextColumn get conversion   => text()();          // "none" | "b" | "ab"
  IntColumn get shootLen      => integer()();       // 10 or 15
  TextColumn get targetNumber => text().withDefault(const Constant(''))();
  TextColumn get savedAt      => text()();          // ISO-8601
  TextColumn get shotsJson    => text()();          // JSON array of shots
  TextColumn get ownerId      => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Sight presets ─────────────────────────────────────────────────────────────

class SightPresets extends Table {
  TextColumn get id           => text()();
  DateTimeColumn get createdAt   => dateTime()();
  DateTimeColumn get updatedAt   => dateTime()();
  IntColumn get formatVersion  => integer().withDefault(const Constant(1))();

  TextColumn get faceId       => text()();
  RealColumn get windMoa      => real()();
  RealColumn get elevMoa      => real()();
  TextColumn get label        => text().withDefault(const Constant(''))();
  TextColumn get aperture     => text().withDefault(const Constant(''))();
  TextColumn get ownerId      => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Scorecards, SightPresets])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(sightPresets);
      if (from < 3) {
        await customStatement(
            "ALTER TABLE sight_presets ADD COLUMN aperture TEXT NOT NULL DEFAULT ''");
      }
      if (from < 4) {
        await customStatement(
            'ALTER TABLE scorecards ADD COLUMN owner_id TEXT');
        await customStatement(
            'ALTER TABLE sight_presets ADD COLUMN owner_id TEXT');
      }
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'targetsheet.db'));
      return NativeDatabase.createInBackground(file);
    });
