import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/library/logic/article.dart';
import 'package:sahaj/features/library/pages/article_reader_page.dart';

void main() {
  testWidgets('renders the article title, meta, and body', (tester) async {
    const article = Article(
      slug: 's',
      title: 'How your pelvic floor works',
      category: 'Anatomy',
      readMinutes: 3,
      body: 'The pelvic floor is a hammock of muscles.',
    );
    await tester.pumpWidget(
      const MaterialApp(home: ArticleReaderPage(article: article)),
    );
    await tester.pumpAndSettle();

    expect(find.text('How your pelvic floor works'), findsWidgets);
    expect(find.textContaining('min read'), findsOneWidget);
    expect(find.textContaining('hammock of muscles'), findsOneWidget);
  });
}
