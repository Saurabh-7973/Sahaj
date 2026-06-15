import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/library/logic/article.dart';
import 'package:sahaj/features/library/pages/article_reader_page.dart';
import 'package:sahaj/features/library/widgets/library_widgets.dart';

void main() {
  testWidgets('evidence article: eyebrow, title, doctor badge, drop cap',
      (tester) async {
    const article = Article(
      slug: 's',
      title: 'How your pelvic floor works',
      category: 'Anatomy',
      readMinutes: 3,
      body: 'The pelvic floor is a hammock of muscles.',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const ArticleReaderPage(article: article),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read · evidence-based'), findsOneWidget);
    expect(find.text('How your pelvic floor works'), findsOneWidget);
    expect(find.text('3 min'), findsWidgets);
    // Default review state is honest "pending".
    expect(find.byType(DoctorBadge), findsWidgets);
  });

  testWidgets('read→do bridge shows the paired training when set (#16)',
      (tester) async {
    const article = Article(
      slug: 's',
      title: 'How your pelvic floor works',
      category: 'Anatomy',
      readMinutes: 3,
      body: 'The pelvic floor is a hammock of muscles.',
      relatedSessionTag: 'pfmt_identify',
      relatedSessionLabel: 'Finding the muscles',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const ArticleReaderPage(article: article),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Put it into practice'), findsOneWidget);
    expect(find.textContaining('Finding the muscles'), findsOneWidget);
  });

  testWidgets('no bridge when the article has no paired session', (tester) async {
    const article = Article(
      slug: 's',
      title: 'Warning signs',
      category: 'Health',
      readMinutes: 2,
      body: 'Some things are a doctor’s job, not more training.',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const ArticleReaderPage(article: article),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Put it into practice'), findsNothing);
  });

  testWidgets('heritage article: heritage eyebrow + canon line, no badge',
      (tester) async {
    const article = Article(
      slug: 'h',
      title: 'What the Ananga Ranga says about pacing',
      category: 'Heritage',
      readMinutes: 8,
      body: 'Centuries before Western sexology existed…\n\n'
          '> A measured pace is itself a discipline of the art.\n\n'
          'What the old text frames as artistry, modern training frames as '
          'arousal regulation.',
      register: ArticleRegister.heritage,
      eraTag: 'Ananga Ranga · Burton tr., 1885 — language of its time',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const ArticleReaderPage(article: article),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read · heritage'), findsOneWidget);
    expect(find.text('Heritage, not instruction — and never medicine.'),
        findsOneWidget);
    expect(find.byType(PullQuote), findsOneWidget);
    // A culture piece never wears a review badge.
    expect(find.byType(DoctorBadge), findsNothing);
  });
}
