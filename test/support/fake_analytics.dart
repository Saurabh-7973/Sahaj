import 'package:sahaj/core/analytics/analytics.dart';

/// Records analytics calls for assertions in tests.
class FakeAnalytics implements Analytics {
  final List<({String name, Map<String, Object>? params})> events = [];
  final Map<String, String?> userProps = {};

  @override
  void logEvent(String name, [Map<String, Object>? params]) =>
      events.add((name: name, params: params));

  @override
  void setUserProperty(String name, String? value) => userProps[name] = value;

  ({String name, Map<String, Object>? params})? last(String name) {
    for (final e in events.reversed) {
      if (e.name == name) return e;
    }
    return null;
  }
}
