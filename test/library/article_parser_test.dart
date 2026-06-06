import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/library/logic/article_parser.dart';

const _json = '''
[
  {
    "slug": "how-it-works",
    "title": "How it works",
    "category": "Anatomy",
    "readMinutes": 3,
    "body": "## Heading\\n\\nA paragraph.\\n\\n- a bullet"
  },
  {
    "slug": "breathing",
    "title": "Breathing",
    "category": "Mind & body",
    "readMinutes": 2,
    "body": "Breathe."
  }
]
''';

void main() {
  test('parseArticles decodes the array into Articles', () {
    final articles = parseArticles(_json);
    expect(articles.length, 2);
    expect(articles.first.slug, 'how-it-works');
    expect(articles.first.title, 'How it works');
    expect(articles.first.category, 'Anatomy');
    expect(articles.first.readMinutes, 3);
    expect(articles.first.body, contains('## Heading'));
    expect(articles.first.body, contains('- a bullet'));
    expect(articles[1].category, 'Mind & body');
  });

  test('readMinutes parses from num', () {
    final articles = parseArticles(_json);
    expect(articles[1].readMinutes, 2);
  });
}
