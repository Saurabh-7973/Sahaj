import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The analytics seam. Everything depends on this, not on Firebase directly,
/// so the pure logic layer stays Firebase-free and tests use a fake.
abstract class Analytics {
  void logEvent(String name, [Map<String, Object>? params]);
  void setUserProperty(String name, String? value);
}

/// Default no-op implementation — used in tests and any un-overridden read,
/// so nothing reaches Firebase unless explicitly wired in main().
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void logEvent(String name, [Map<String, Object>? params]) {}

  @override
  void setUserProperty(String name, String? value) {}
}

/// Overridden in main() with FirebaseAnalyticsService.
final analyticsProvider = Provider<Analytics>((ref) => const NoopAnalytics());
