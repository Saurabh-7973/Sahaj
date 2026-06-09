import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import '../subscription/subscription_controller.dart';
import 'preferences_controller.dart';

/// Wipes every local data store: onboarding, progress + session logs,
/// preferences, and subscription state. Each controller's reset() clears its
/// own Hive box. After this, the app is in a first-launch state and the caller
/// should route to onboarding.
void wipeAllData({
  required OnboardingController onboarding,
  required ProgressController progress,
  required PreferencesController preferences,
  required SubscriptionController subscription,
}) {
  onboarding.reset();
  progress.reset();
  preferences.reset();
  subscription.reset();
}
