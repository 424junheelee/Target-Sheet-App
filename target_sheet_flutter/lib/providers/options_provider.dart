import 'package:flutter_riverpod/flutter_riverpod.dart';

final class OptionsState {
  const OptionsState({
    this.defaultShootLen = 10,
    this.showRec = true,
    this.showGraphs = true,
  });

  final int defaultShootLen;
  final bool showRec;
  final bool showGraphs;

  OptionsState copyWith({
    int? defaultShootLen,
    bool? showRec,
    bool? showGraphs,
  }) => OptionsState(
        defaultShootLen: defaultShootLen ?? this.defaultShootLen,
        showRec: showRec ?? this.showRec,
        showGraphs: showGraphs ?? this.showGraphs,
      );
}

class OptionsNotifier extends Notifier<OptionsState> {
  @override
  OptionsState build() => const OptionsState();

  void setDefaultShootLen(int len) {
    assert(len == 10 || len == 15);
    state = state.copyWith(defaultShootLen: len);
  }

  void setShowRec(bool v) => state = state.copyWith(showRec: v);

  void setShowGraphs(bool v) => state = state.copyWith(showGraphs: v);
}

final optionsProvider =
    NotifierProvider<OptionsNotifier, OptionsState>(OptionsNotifier.new);
