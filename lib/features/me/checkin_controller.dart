import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/checkin_store.dart';

/// One completed check-in instrument (week 4/8/12). Scores are stored raw
/// (answer index 0–3 per question id); deltas are computed at render, never
/// stored (M3 spec §3 data rule).
@immutable
class CheckinRecord {
  const CheckinRecord({
    required this.week,
    required this.scores,
    required this.completedAt,
  });

  final int week;
  final Map<String, int> scores;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'week': week,
        'scores': scores,
        'completedAt': completedAt.toIso8601String(),
      };

  factory CheckinRecord.fromJson(Map json) => CheckinRecord(
        week: (json['week'] as num).toInt(),
        scores: Map<String, int>.from(
          (json['scores'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
        ),
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}

/// Holds + persists completed check-ins and the deferred ("Tomorrow")
/// pending marker. The pending check-in re-surfaces at the next session
/// completion only — never on Today, never via notification.
class CheckinController extends ChangeNotifier {
  CheckinController([this._store]) {
    if (_store != null) {
      records = _store.records().map(CheckinRecord.fromJson).toList();
      pendingWeek = _store.pendingWeek();
    }
  }

  final CheckinStore? _store;

  List<CheckinRecord> records = [];

  /// Milestone week whose check-in was deferred and is still owed.
  int? pendingWeek;

  bool hasCompleted(int week) => records.any((r) => r.week == week);

  void complete(CheckinRecord record) {
    records = [...records, record];
    if (pendingWeek == record.week) pendingWeek = null;
    _store?.append(record.toJson());
    _store?.setPendingWeek(pendingWeek);
    notifyListeners();
  }

  void defer(int week) {
    pendingWeek = week;
    _store?.setPendingWeek(week);
    notifyListeners();
  }

  void reset() {
    records = [];
    pendingWeek = null;
    _store?.clear();
    notifyListeners();
  }
}

/// Overridden in main() with the persisted controller.
final checkinControllerProvider =
    ChangeNotifierProvider<CheckinController>((ref) => CheckinController());
