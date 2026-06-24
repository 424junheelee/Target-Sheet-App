import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import '../data/scorecard_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

final class ShootSessionState {
  const ShootSessionState({
    required this.shots,
    required this.windMoa,
    required this.elevMoa,
    required this.conversion,
    required this.conversionChosen,
    required this.faceId,
    this.shootLen = 10,
    this.undoStack = const [],
  });

  final List<ScoredShot> shots;
  final double windMoa;
  final double elevMoa;
  final Conversion conversion;
  final bool conversionChosen;
  final String faceId;
  final int shootLen;
  final List<List<ScoredShot>> undoStack;

  TargetFace get face => kTargetFaces[faceId]!;
  double get moaMm => moaSizeAtYards(face.effectiveYards);

  ShotType? get nextType =>
      nextShotType(shots, conversion, shootLen);

  ShootSessionState copyWith({
    List<ScoredShot>? shots,
    double? windMoa,
    double? elevMoa,
    Conversion? conversion,
    bool? conversionChosen,
    String? faceId,
    int? shootLen,
    List<List<ScoredShot>>? undoStack,
  }) => ShootSessionState(
        shots: shots ?? this.shots,
        windMoa: windMoa ?? this.windMoa,
        elevMoa: elevMoa ?? this.elevMoa,
        conversion: conversion ?? this.conversion,
        conversionChosen: conversionChosen ?? this.conversionChosen,
        faceId: faceId ?? this.faceId,
        shootLen: shootLen ?? this.shootLen,
        undoStack: undoStack ?? this.undoStack,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ShootSessionNotifier extends Notifier<ShootSessionState> {
  @override
  ShootSessionState build() => const ShootSessionState(
        shots: [],
        windMoa: 0,
        elevMoa: 0,
        conversion: Conversion.none,
        conversionChosen: false,
        faceId: '300y-nra',
      );

  void addShot(ModelPoint point) {
    final s = state;
    final type = s.nextType;
    if (type == null) return; // string complete

    if (type == ShotType.scored && !s.conversionChosen) {
      state = s.copyWith(conversionChosen: true);
    }

    final ring = scoreShot(point, s.face.rings, scoringMode: s.face.scoringMode);
    final shot = ScoredShot(
      point: point,
      type: type,
      ring: ring,
      windMoa: s.windMoa,
      elevMoa: s.elevMoa,
    );

    final newShots = [...s.shots, shot];
    state = state.copyWith(
      shots: newShots,
      undoStack: [...s.undoStack, s.shots],
    );
    _persistDraft();
  }

  void _persistDraft() {
    final s = state;
    ref.read(scorecardRepositoryProvider).saveDraft(
      faceId: s.faceId,
      shots: s.shots,
      conversion: s.conversion,
      shootLen: s.shootLen,
      windMoa: s.windMoa,
      elevMoa: s.elevMoa,
    );
  }

  void undo() {
    final s = state;
    if (s.undoStack.isEmpty) return;
    final prev = s.undoStack.last;
    final newStack = s.undoStack.sublist(0, s.undoStack.length - 1);
    state = s.copyWith(
      shots: prev,
      undoStack: newStack,
      conversionChosen: prev.length >= 2 ? s.conversionChosen : false,
      conversion: prev.length >= 2 ? s.conversion : Conversion.none,
    );
  }

  void setConversion(Conversion cv) {
    state = state.copyWith(conversion: cv, conversionChosen: true);
  }

  void setCall(String? call) {
    final s = state;
    if (s.shots.isEmpty) return;
    final last = s.shots.last;
    final updated = ScoredShot(
      point: last.point,
      type: last.type,
      ring: last.ring,
      windMoa: last.windMoa,
      elevMoa: last.elevMoa,
      call: last.call == call ? null : call, // toggle
    );
    state = s.copyWith(shots: [...s.shots.sublist(0, s.shots.length - 1), updated]);
  }

  void adjustWind(int direction) {
    state = state.copyWith(
      windMoa: clamp(snap(state.windMoa + direction * 0.25)),
    );
  }

  void adjustElev(int direction) {
    state = state.copyWith(
      elevMoa: clamp(snap(state.elevMoa + direction * 0.25)),
    );
  }

  void setFace(String faceId) {
    if (!kTargetFaces.containsKey(faceId)) return;
    state = state.copyWith(faceId: faceId);
  }

  void restoreFromDraft({
    required String faceId,
    required List<ScoredShot> shots,
    required Conversion conversion,
    required int shootLen,
    required double windMoa,
    required double elevMoa,
  }) {
    state = ShootSessionState(
      shots: shots,
      windMoa: windMoa,
      elevMoa: elevMoa,
      conversion: conversion,
      conversionChosen: shots.length >= 2,
      faceId: faceId,
      shootLen: shootLen,
    );
  }

  void setShootLen(int len) {
    assert(len == 10 || len == 15);
    state = state.copyWith(shootLen: len);
  }

  void discard() {
    state = build();
    ref.read(scorecardRepositoryProvider).clearDraft();
  }

  Future<void> commitString({String targetNumber = ''}) async {
    final s = state;
    if (s.shots.isEmpty) return;
    final repo = ref.read(scorecardRepositoryProvider);
    await repo.saveScorecard(
      faceId: s.faceId,
      shots: s.shots,
      conversion: s.conversion,
      shootLen: s.shootLen,
      targetNumber: targetNumber,
    );
    await repo.clearDraft();
    state = build();
  }

  ScoreTotal get total =>
      calcTotal(state.shots, state.conversion, state.shootLen);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final sessionProvider =
    NotifierProvider<ShootSessionNotifier, ShootSessionState>(
  ShootSessionNotifier.new,
);
