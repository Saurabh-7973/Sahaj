import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics.dart';

/// Forwards events to Firebase Analytics. Device/Firebase only — not unit-tested.
class FirebaseAnalyticsService implements Analytics {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
      : _fa = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;

  @override
  void logEvent(String name, [Map<String, Object>? params]) {
    _fa.logEvent(name: name, parameters: params);
  }

  @override
  void setUserProperty(String name, String? value) {
    _fa.setUserProperty(name: name, value: value);
  }
}
