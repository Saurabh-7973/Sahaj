import 'package:flutter/foundation.dart';

/// A bundled psychoeducation article (markdown body).
@immutable
class Article {
  const Article({
    required this.slug,
    required this.title,
    required this.category,
    required this.readMinutes,
    required this.body,
  });

  final String slug;
  final String title;
  final String category;
  final int readMinutes;
  final String body; // markdown

  factory Article.fromJson(Map json) => Article(
        slug: json['slug'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        readMinutes: (json['readMinutes'] as num).toInt(),
        body: json['body'] as String,
      );
}
