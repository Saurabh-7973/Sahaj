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

  test('read→do bridge (#16): articles pair to a session — except warning-signs',
      () {
    for (final a in articles) {
      if (a.slug == 'warning-signs') {
        // Never funnel a "see a doctor" piece into "just train more".
        expect(a.relatedSessionTag, isNull);
        expect(a.relatedSessionLabel, isNull);
      } else {
        expect(a.relatedSessionTag, isNotNull, reason: a.slug);
        expect(a.relatedSessionLabel, isNotEmpty, reason: a.slug);
      }
    }
  });

  test('every related-session tag resolves to a real catalog session', () {
    final catalog = File('assets/content/sessions.json').readAsStringSync();
    for (final a in articles) {
      final tag = a.relatedSessionTag;
      if (tag != null) {
        expect(catalog.contains('"$tag"'), isTrue, reason: '${a.slug} -> $tag');
      }
    }
  });
}
