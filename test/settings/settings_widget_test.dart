import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';
import 'package:sahaj/features/settings/settings_page.dart';

void main() {
  testWidgets('renders sections and toggling Book Mode writes the pref',
      (tester) async {
    final prefs = PreferencesController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider
              .overrideWith((ref) => OnboardingController()),
          preferencesControllerProvider.overrideWith((ref) => prefs),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biometric lock'), findsOneWidget);
    expect(find.text('Book Mode'), findsOneWidget);
    expect(find.text('Export my data'), findsOneWidget);
    expect(find.text('Delete everything'), findsOneWidget);

    expect(prefs.bookMode, isFalse);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Book Mode'));
    await tester.pumpAndSettle();
    expect(prefs.bookMode, isTrue);
  });
}
