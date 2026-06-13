import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/analytics.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';
import 'package:sahaj/features/onboarding/widgets/selectable_option.dart';
import 'package:sahaj/shared/widgets/widgets.dart';

import '../support/fake_analytics.dart';

void main() {
  testWidgets('completing onboarding logs completion + plan_generated',
      (tester) async {
    final fake = FakeAnalytics();
    final controller = OnboardingController()
      ..setPersona(Persona.singleInexperienced);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(fake),
          onboardingControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(home: OnboardingFlow()),
      ),
    );
    await tester.pumpAndSettle();

    // Walk the flow: tap an enabled primary CTA when present (Begin / Next /
    // Continue / Done / Start now), otherwise tap the first option — which
    // covers auto-advancing health questions and unlocks the disabled
    // Continue on persona/goals.
    for (var i = 0; i < 60; i++) {
      if (controller.complete) break;
      final cta = find.byWidgetPredicate(
        (w) =>
            w is AppButton &&
            (w.variant == AppButtonVariant.filled ||
                w.variant == AppButtonVariant.outlined) &&
            w.onPressed != null,
      );
      if (cta.evaluate().isNotEmpty) {
        await tester.tap(cta.first);
      } else {
        final opt = find.byType(SelectableOption);
        if (opt.evaluate().isEmpty) break;
        await tester.tap(opt.first);
      }
      await tester.pumpAndSettle();
    }

    expect(controller.complete, isTrue);
    expect(fake.last('onboarding_completed'), isNotNull);
    expect(fake.last('plan_generated'), isNotNull);
  });
}
