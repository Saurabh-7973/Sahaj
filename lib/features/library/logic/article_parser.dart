import 'dart:convert';

import 'article.dart';

/// Parses the bundled articles JSON array into Article models.
List<Article> parseArticles(String jsonStr) {
  final raw = json.decode(jsonStr) as List;
  return raw
      .map((e) => Article.fromJson(e as Map))
      .toList(growable: false);
}
