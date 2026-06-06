import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/onboarding_store.dart';
import 'data/preferences_store.dart';
import 'data/progress_store.dart';
import 'data/session_log_store.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/sessions/progress_controller.dart';
import 'features/sessions/session_catalog.dart';
import 'features/settings/preferences_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  // Privacy / Settings (Privacy Task 4)
  final prefsStore = await PreferencesStore.open();
  final preferences = PreferencesController(prefsStore);
  final savedPrefs = prefsStore.load();
  if (savedPrefs != null) preferences.loadFrom(savedPrefs);

  runApp(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => controller),
        progressControllerProvider.overrideWith((ref) => progress),
        sessionCatalogProvider.overrideWithValue(catalog),
        preferencesControllerProvider.overrideWith((ref) => preferences),
      ],
      child: const SahajApp(),
    ),
  );
}
