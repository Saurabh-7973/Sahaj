import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/library/article_catalog.dart';
import 'package:sahaj/features/library/logic/article_parser.dart';
import 'package:sahaj/features/library/pages/article_reader_page.dart';
import 'package:sahaj/features/onboarding/health_questions.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';
import 'package:sahaj/features/onboarding/widgets/selectable_option.dart';

void main() {
  testWidgets('triage "How to bring this up with a doctor" opens warning-signs',
      (tester) async {
    final catalog = ArticleCatalog(
        parseArticles(File('assets/content/articles.json').readAsStringSync()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider
              .overrideWith((ref) => OnboardingController()),
          articleCatalogProvider.overrideWithValue(catalog),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const OnboardingFlow()),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapFirst() async {
      await tester.tap(find.byType(SelectableOption).first);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sounds fair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tapFirst(); // goals
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tapFirst(); // persona
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start the check'));
    await tester.pumpAndSettle();

    // Health questions: benign first option, except chest_breath (index 4),
    // where "Sometimes" (index 1) raises a cardiac flag → triage appears.
    const chestBreath = 4;
    for (var i = 0; i < kHealthQuestions.length; i++) {
      final idx = i == chestBreath ? 1 : 0;
      await tester.tap(find.byType(SelectableOption).at(idx));
      await tester.pumpAndSettle();
    }

    // Emergency carve-out questions (both "No") sit before triage.
    await tapFirst();
    await tapFirst();

    // Triage screen → tap the doctor-conversation affordance.
    expect(find.text('How to bring this up with a doctor'), findsOneWidget);
    await tester.tap(find.text('How to bring this up with a doctor'));
    await tester.pumpAndSettle();

    expect(find.byType(ArticleReaderPage), findsOneWidget);
  });
}
