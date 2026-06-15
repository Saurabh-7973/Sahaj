import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/library/logic/article.dart';
import 'package:sahaj/features/library/logic/article_parser.dart';

void main() {
  final articles =
      parseArticles(File('assets/content/articles.json').readAsStringSync());

  test('the seeded evidence series loads — 8 articles, all review-pending', () {
    expect(articles, hasLength(8));
    for (final a in articles) {
      expect(a.register, ArticleRegister.evidence, reason: a.slug);
      expect(a.reviewState, ReviewState.pending, reason: a.slug);
      expect(a.body, isNotEmpty, reason: a.slug);
      expect(a.title, isNotEmpty, reason: a.slug);
      expect(a.readMinutes, greaterThan(0), reason: a.slug);
    }
  });

  test('slugs are unique', () {
    final slugs = articles.map((a) => a.slug).toList();
    expect(slugs.toSet().length, slugs.length);
  });

  test('the warning-signs article is present (Week 11 references it)', () {
    expect(articles.any((a) => a.slug == 'warning-signs'), isTrue);
  });

  test('every citation has a name and a finding', () {
    for (final a in articles) {
      for (final c in a.sources) {
        expect(c.name, isNotEmpty, reason: a.slug);
        expect(c.finding, isNotEmpty, reason: a.slug);
      }
    }
  });
}
