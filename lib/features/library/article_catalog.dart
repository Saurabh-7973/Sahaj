import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/article.dart';
import 'logic/article_parser.dart';

/// Loads the bundled articles asset.
class ArticleCatalog {
  const ArticleCatalog(this.articles);

  final List<Article> articles;

  static Future<ArticleCatalog> load() async {
    final jsonStr =
        await rootBundle.loadString('assets/content/articles.json');
    return ArticleCatalog(parseArticles(jsonStr));
  }
}

/// Overridden in main() with the catalog loaded at startup.
final articleCatalogProvider = Provider<ArticleCatalog>(
  (ref) => throw UnimplementedError('articleCatalogProvider not overridden'),
);
