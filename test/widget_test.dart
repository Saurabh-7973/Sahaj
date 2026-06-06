import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sahaj/app.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  testWidgets('Onboarding shows welcome, then advances on Begin', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SahajApp()));
    await tester.pumpAndSettle();

    // Screen 1 — welcome.
    expect(find.text('Sahaj'), findsOneWidget);
    expect(find.text('Train steady.'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);

    // Advance to screen 2 — the promise.
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    expect(find.text('A few promises'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Completing onboarding lands on the tab shell; tabs switch', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SahajApp()));
    await tester.pumpAndSettle();

    // Clear the gate directly (no need to tap through 21 screens).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SahajApp)),
    );
    container.read(onboardingControllerProvider).finish();
    await tester.pumpAndSettle();

    // Redirect cleared onboarding → landed on the Today tab inside the shell.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Your session'), findsOneWidget);

    // Switch to Library tab via its destination icon.
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Pelvic floor exercises'), findsOneWidget);

    // Switch to Me tab.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Privacy & discreet mode'), findsOneWidget);
  });
}
