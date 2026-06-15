import 'package:flutter/foundation.dart';

/// Which register an article belongs to (M5 law 1 — never blended). Evidence
/// pieces carry a doctor badge and may make health claims; heritage pieces
/// carry an era chip, an anti-shame frame, and zero health claims.
enum ArticleRegister { evidence, heritage }

/// The doctor-gate state of an evidence article. Heritage pieces never carry
/// a review badge in any state (a badge on a culture piece blurs the gate).
enum ReviewState { reviewed, pending }

/// One citation row in the trust footer.
@immutable
class Citation {
  const Citation({
    required this.name,
    required this.finding,
  });

  /// "Dorey et al., 2005 — BJU International".
  final String name;

  /// One plain line on what it showed.
  final String finding;

  factory Citation.fromJson(Map json) => Citation(
        name: json['name'] as String,
        finding: json['finding'] as String,
      );
}

/// A bundled psychoeducation or heritage article (markdown body).
@immutable
class Article {
  const Article({
    required this.slug,
    required this.title,
    required this.category,
    required this.readMinutes,
    required this.body,
    this.register = ArticleRegister.evidence,
    this.reviewState = ReviewState.pending,
    this.reviewedDate,
    this.sources = const [],
    this.eraTag,
    this.relatedSessionTag,
    this.relatedSessionLabel,
  });

  final String slug;
  final String title;
  final String category;
  final int readMinutes;
  final String body; // markdown

  final ArticleRegister register;

  /// Only meaningful for evidence articles.
  final ReviewState reviewState;

  /// e.g. "May 2026" — shown beside a reviewed badge.
  final String? reviewedDate;

  final List<Citation> sources;

  /// Heritage only — "Ananga Ranga · Burton tr., 1885 — language of its time".
  final String? eraTag;

  /// Read→do bridge (decision #16): the training session this article pairs
  /// with. [relatedSessionTag] is the catalog tag (for any future deep-link);
  /// [relatedSessionLabel] is the human title shown in the reader footer.
  /// Both null for pieces with no honest training pairing (e.g. warning-signs).
  final String? relatedSessionTag;
  final String? relatedSessionLabel;

  bool get isHeritage => register == ArticleRegister.heritage;

  factory Article.fromJson(Map json) => Article(
        slug: json['slug'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        readMinutes: (json['readMinutes'] as num).toInt(),
        body: json['body'] as String,
        register: (json['register'] as String?) == 'heritage'
            ? ArticleRegister.heritage
            : ArticleRegister.evidence,
        reviewState: (json['reviewState'] as String?) == 'reviewed'
            ? ReviewState.reviewed
            : ReviewState.pending,
        reviewedDate: json['reviewedDate'] as String?,
        sources: ((json['sources'] as List?) ?? const [])
            .map((e) => Citation.fromJson(e as Map))
            .toList(growable: false),
        eraTag: json['eraTag'] as String?,
        relatedSessionTag: json['relatedSessionTag'] as String?,
        relatedSessionLabel: json['relatedSessionLabel'] as String?,
      );
}
