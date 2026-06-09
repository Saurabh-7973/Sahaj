import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';

/// Typed, centralized event helpers. Names + params live here once so call
/// sites stay clean and consistent. Firebase requires snake_case names <=40
/// chars and primitive param values, so list params are comma-joined.
class AppEvents {
  const AppEvents(this._a);

  final Analytics _a;

  void appOpened() => _a.logEvent('app_opened');

  void personaSelected(String persona) =>
      _a.logEvent('persona_selected', {'persona': persona});

  void goalSelected(List<String> goals) =>
      _a.logEvent('goal_selected', {'goals': goals.join(',')});

  void planGenerated(String persona, int goalCount) =>
      _a.logEvent('plan_generated', {'persona': persona, 'goalCount': goalCount});

  void onboardingCompleted() => _a.logEvent('onboarding_completed');

  void redFlagFired(String flagType) =>
      _a.logEvent('health_screen_red_flag_fired', {'flagType': flagType});

  void sessionStarted(String sessionType, int week, int day) =>
      _a.logEvent('session_started',
          {'sessionType': sessionType, 'week': week, 'day': day});

  void sessionCompleted(String sessionType, double completionPct) =>
      _a.logEvent('session_completed',
          {'sessionType': sessionType, 'completionPct': completionPct});

  void moodCheckin(List<String> moods) =>
      _a.logEvent('mood_checkin_completed', {'moods': moods.join(',')});

  void biometricLockEnabled() => _a.logEvent('biometric_lock_enabled');

  void dataExported() => _a.logEvent('data_exported');

  void accountDeleted() => _a.logEvent('account_deleted');

  // Subscription (Phase 6)
  void paywallViewed(String source) =>
      _a.logEvent('paywall_viewed', {'source': source});

  void paywallTierSelected(String tier) =>
      _a.logEvent('paywall_tier_selected', {'tier': tier});

  void subscriptionStarted(String tier) =>
      _a.logEvent('subscription_started', {'tier': tier});

  void subscriptionRestored() => _a.logEvent('subscription_restored');
}

/// Reads the active Analytics (Noop by default, Firebase in main()).
final appEventsProvider =
    Provider<AppEvents>((ref) => AppEvents(ref.watch(analyticsProvider)));
