import 'dart:convert';

/// Assembles all of a user's local data into one pretty-printed JSON string
/// for a user-initiated export. Pure — delivery (share sheet) is the caller's job.
String assembleExportJson({
  required Map<String, dynamic>? onboarding,
  required Map<String, dynamic> progress,
  required List<Map<String, dynamic>> logs,
  required Map<String, dynamic> preferences,
  required DateTime exportedAt,
  List<Map<String, dynamic>> checkins = const [],
}) {
  final payload = <String, dynamic>{
    'exportedAt': exportedAt.toIso8601String(),
    'onboarding': onboarding,
    'progress': progress,
    'sessionLogs': logs,
    'checkins': checkins,
    'preferences': preferences,
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}
