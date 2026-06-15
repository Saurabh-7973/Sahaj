import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/settings/consultation_screen.dart';
import 'package:sahaj/shared/widgets/widgets.dart';

void main() {
  testWidgets('shows the optional-consultation copy and an honest "not yet" CTA',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const ConsultationScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Want to talk to a doctor?'), findsOneWidget);
    expect(find.textContaining('entirely optional'), findsOneWidget);
    expect(find.textContaining('Not available yet'), findsOneWidget);

    // The booking CTA is present but disabled (no backend, no charge).
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Book a consultation'),
    );
    expect(button.onPressed, isNull);
  });

  test('FIREWALL: no health/onboarding/triage surface links to consultation',
      () {
    // §4 ethic: the paid consultation must never be reachable from a health
    // screening result or any "see a doctor" message — only from Settings.
    final guarded = [
      'lib/features/onboarding',
      'lib/features/library/pages/article_reader_page.dart',
    ];
    for (final path in guarded) {
      final entity = FileSystemEntity.typeSync(path);
      final files = entity == FileSystemEntityType.directory
          ? Directory(path)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
          : [File(path)];
      for (final f in files) {
        final src = f.readAsStringSync();
        expect(src.contains('ConsultationScreen'), isFalse, reason: f.path);
        expect(src.contains('consultation_screen'), isFalse, reason: f.path);
      }
    }
  });
}
