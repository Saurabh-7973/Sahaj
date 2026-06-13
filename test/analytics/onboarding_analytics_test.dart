import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/analytics.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';
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

    for (var i = 0; i < 25; i++) {
      if (controller.complete) break;
      final cta = find.byWidgetPredicate(
        (w) =>
            w is AppButton &&
            w.variant == AppButtonVariant.filled &&
            w.onPressed != null,
      );
      if (cta.evaluate().isEmpty) break;
      await tester.tap(cta.first);
      await tester.pumpAndSettle();
    }

    expect(controller.complete, isTrue);
    expect(fake.last('onboarding_completed'), isNotNull);
    expect(fake.last('plan_generated'), isNotNull);
  });
}
