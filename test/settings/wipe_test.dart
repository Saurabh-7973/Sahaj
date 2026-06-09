import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/onboarding_store.dart';
import 'package:sahaj/data/preferences_store.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/data/subscription_store.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/settings/account.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_wipe_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('wipeAllData clears onboarding, progress, logs, preferences, and subscription',
      () async {
    final onboardingStore = await OnboardingStore.open();
    final progressStore = await ProgressStore.open();
    final logStore = await SessionLogStore.open();
    final prefsStore = await PreferencesStore.open();
    final subStore = await SubscriptionStore.open();

    final onboarding = OnboardingController(onboardingStore)
      ..setPersona(Persona.singleInexperienced)
      ..finish();
    final progress = ProgressController(progressStore, logStore)
      ..completeToday(SessionLog(
        id: 'x',
        sessionTag: 'anatomy',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        completionPct: 1.0,
        moodBefore: const [],
      ));
    final prefs = PreferencesController(prefsStore)..setBookMode(true);
    final subscription =
        SubscriptionController(const NoopSubscriptionRepository(), subStore);
    await subscription.choose(PricingTier.free); // grant Pro locally
    await Future<void>.delayed(Duration.zero);

    expect(onboardingStore.load(), isNotNull);
    expect(logStore.all(), isNotEmpty);
    expect(subStore.load(), isNotNull);

    wipeAllData(
      onboarding: onboarding,
      progress: progress,
      preferences: prefs,
      subscription: subscription,
    );
    await Future<void>.delayed(Duration.zero);

    expect(onboardingStore.load(), isNull);
    expect(progressStore.load(), isNull);
    expect(logStore.all(), isEmpty);
    expect(prefsStore.load(), isNull);
    expect(subStore.load(), isNull);
    expect(onboarding.complete, isFalse);
    expect(progress.state.currentDay, 1);
    expect(prefs.bookMode, isFalse);
    expect(subscription.isPro, isFalse);
  });
}
