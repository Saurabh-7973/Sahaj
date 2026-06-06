import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/home/tabs/today_page.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

void main() {
  testWidgets('Today shows the session card from plan + catalog', (tester) async {
    final controller = OnboardingController()
      ..setPersona(Persona.singleInexperienced)
      ..finish(); // builds a solo plan; week 1 tags include 'anatomy'

    final catalog = SessionCatalog({
      'anatomy': const SessionDef(
        tag: 'anatomy',
        title: 'Know the ground',
        type: SessionType.education,
        steps: [SessionStep(title: 's', seconds: 60, guidance: 'g')],
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref) => controller),
          sessionCatalogProvider.overrideWithValue(catalog),
        ],
        child: const MaterialApp(home: TodayPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Know the ground'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);
  });
}
