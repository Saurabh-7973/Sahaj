import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/analytics/analytics.dart';
import 'core/analytics/events.dart';
import 'core/analytics/firebase_analytics_service.dart';
import 'data/onboarding_store.dart';
import 'data/preferences_store.dart';
import 'data/progress_store.dart';
import 'data/session_log_store.dart';
import 'features/notifications/local_notification_service.dart';
import 'features/notifications/notification_service.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/sessions/progress_controller.dart';
import 'features/library/article_catalog.dart';
import 'features/sessions/session_catalog.dart';
import 'features/settings/preferences_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crash reporting — rides the committed Firebase config (no separate key).
  // Route both framework and async/platform errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await Hive.initFlutter();

  // Onboarding (Phase 2/3)
  final store = await OnboardingStore.open();
  final controller = OnboardingController(store);
  final saved = store.load();
  if (saved != null) controller.loadFrom(saved);

  // Sessions (Phase 4)
  final progressStore = await ProgressStore.open();
  final logStore = await SessionLogStore.open();
  final progress = ProgressController(progressStore, logStore);
  final savedProgress = progressStore.load();
  if (savedProgress != null) progress.loadFrom(savedProgress);

  final catalog = await SessionCatalog.load();
  final articleCatalog = await ArticleCatalog.load();

  // Privacy / Settings (Privacy Task 4)
  final prefsStore = await PreferencesStore.open();
  final preferences = PreferencesController(prefsStore);
  final savedPrefs = prefsStore.load();
  if (savedPrefs != null) preferences.loadFrom(savedPrefs);

  // Notifications: keep the daily reminder alive across relaunches/updates.
  // Guarded so a platform hiccup (e.g. exact-alarm denied) never blocks launch.
  final notifications = LocalNotificationService();
  try {
    await notifications.init();
    if (preferences.notificationsEnabled) {
      await notifications.scheduleDailyReminder(
        hour: preferences.reminderHour,
        minute: preferences.reminderMinute,
      );
    }
  } catch (_) {/* non-fatal — reminder simply won't be re-armed this launch */}

  final analytics = FirebaseAnalyticsService();
  AppEvents(analytics).appOpened();

  runApp(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => controller),
        progressControllerProvider.overrideWith((ref) => progress),
        sessionCatalogProvider.overrideWithValue(catalog),
        articleCatalogProvider.overrideWithValue(articleCatalog),
        preferencesControllerProvider.overrideWith((ref) => preferences),
        notificationServiceProvider.overrideWithValue(notifications),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: const SahajApp(),
    ),
  );
}
