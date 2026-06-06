import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/progress_store.dart';
import '../../data/session_log_store.dart';
import 'logic/models/session_models.dart';
import 'logic/progress_logic.dart' as logic;

export 'logic/models/session_models.dart';

/// Holds and persists the user's plan position + streak. Writes session logs.
class ProgressController extends ChangeNotifier {
  ProgressController([this._store, this._logStore]);

  final ProgressStore? _store;
  final SessionLogStore? _logStore;

  ProgressState state = const ProgressState();

  bool get isDoneToday => logic.isDoneToday(state, DateTime.now());

  void loadFrom(Map<String, dynamic> json) {
    state = ProgressState.fromJson(json);
    notifyListeners();
  }

  void completeToday(SessionLog log) {
    _logStore?.append(log.toJson());
    state = logic.advanceAfterCompletion(state, DateTime.now());
    _store?.save(state.toJson());
    notifyListeners();
  }

  /// All stored session logs, decoded (empty when no log store).
  List<SessionLog> logs() =>
      (_logStore?.all() ?? const <Map<String, dynamic>>[])
          .map(SessionLog.fromJson)
          .toList();

  /// Records a free-practice session: logs it but does NOT advance the plan
  /// day (practice counts as activity, but never consumes a scheduled day).
  void logPractice(SessionLog log) {
    _logStore?.append(log.toJson());
    notifyListeners();
  }

  void reset() {
    state = const ProgressState();
    _store?.clear();
    _logStore?.clear();
    notifyListeners();
  }
}

/// Overridden in main() with the persisted controller.
final progressControllerProvider =
    ChangeNotifierProvider<ProgressController>((ref) => ProgressController());
