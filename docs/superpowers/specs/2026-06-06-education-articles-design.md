# Education articles + Library "Read" — design

**Date:** 2026-06-06
**Status:** Approved-by-delegation (user asked me to choose + build autonomously) — pending spec review

## Goal

Put real psychoeducation content in the Library — the "teach, don't shame" backbone of the product. Bundled markdown articles, a reader screen, surfaced as a "Read" section in the Library tab. Content authored in-repo; no external input, no backend.

## Why

Synthesis frames Sahaj as education-first ("teach the man what's happening in his body and mind, calmly"). The Library "Learn" grouping currently shows education-*type sessions*, not articles. Real articles deliver the educational value directly, use `flutter_markdown` (already a dependency), and need no API key or device.

## Non-goals (deferred)

Remote/Firestore article sync + `content_pack_v` invalidation; full-text search; tags / bookmarks / reading history; per-locale (Hindi is Phase 2); a CMS. The article *bodies* are bundled now; expanding/refining the library is iterative.

## Architecture (mirrors the Phase 4 session-catalog pattern)

### 1. Content asset
`assets/content/articles.json` — a JSON array of article objects:

```json
[
  {
    "slug": "how-your-pelvic-floor-works",
    "title": "How your pelvic floor works",
    "category": "Anatomy",
    "readMinutes": 3,
    "body": "Markdown body with ## headings, paragraphs, and - bullets."
  }
]
```

Registered under `flutter: assets:` in `pubspec.yaml` (the `assets:` block already exists from Phase 4).

### 2. Model — `lib/features/library/logic/article.dart`
```text
@immutable
class Article {
  final String slug;
  final String title;
  final String category;
  final int readMinutes;
  final String body;          // markdown
  factory Article.fromJson(Map json);
}
```
Pure, no Flutter import beyond `@immutable` (`package:flutter/foundation.dart`).

### 3. Parser — `lib/features/library/logic/article_parser.dart`
`List<Article> parseArticles(String jsonStr)` — decodes the array into `Article`s. Pure, TDD.

### 4. Catalog + provider — `lib/features/library/article_catalog.dart`
```text
class ArticleCatalog {
  const ArticleCatalog(this.articles);          // List<Article>
  final List<Article> articles;
  static Future<ArticleCatalog> load();          // rootBundle -> parseArticles
}
final articleCatalogProvider = Provider<ArticleCatalog>(
  (ref) => throw UnimplementedError('not overridden'),
);
```
Loaded at startup in `main.dart` and injected via override (same as `sessionCatalogProvider`).

### 5. Reader — `lib/features/library/pages/article_reader_page.dart`
`ArticleReaderPage(article)` — `AppScaffold(title: article.title, leading: BackButton, scrollable: true)` rendering `MarkdownBody(data: article.body)` (flutter_markdown). A small header line: `category · ~N min read`.

### 6. Library wiring — `lib/features/home/tabs/library_page.dart` (modify)
Add a **"Read"** section at the top of the Library tab (above the session groups): article cards grouped by category (title, `category · ~N min read`), each tap → `Navigator.push(ArticleReaderPage(article))`. The catalog read is guarded in try/catch (mirrors the session-catalog guard already there) so widget tests without the override still render. Sessions remain below unchanged.

## Content (authored in-repo)

~6 starter articles, 300–500 words each, markdown. Tone per synthesis: calm, warm, masculine-without-aggression, agency over shame, **no fear framing, no red/urgency**. Educational only — each ends with a one-line, non-alarming "this is general education, not medical advice; see a doctor for persistent concerns" note. Titles:

1. **How your pelvic floor works** (Anatomy)
2. **Kegels and reverse Kegels, simply** (Training)
3. **Breathing and arousal** (Mind & body)
4. **The brain–erection connection** (Mind & body)
5. **Porn, dopamine, and rebalancing** (Mind & body)
6. **Performance anxiety, and why it eases** (Mind & body)

No diagnosis, no dosages, no treatment claims — widely-published psychoeducation framed in the app's voice.

## Testing

- `parseArticles` (pure, TDD) — count, fields, `readMinutes` int, markdown body preserved verbatim.
- `Article.fromJson` covered via the parser test.
- Library widget — with a stubbed `articleCatalogProvider`, the "Read" section + an article card render; session groups still render.
- Reader widget — renders the title and body text (find a known substring of the markdown).
- Catalog provider guarded for tests.

## File structure

Created:
- `assets/content/articles.json`
- `lib/features/library/logic/article.dart`
- `lib/features/library/logic/article_parser.dart`
- `lib/features/library/article_catalog.dart`
- `lib/features/library/pages/article_reader_page.dart`
- Tests: `test/library/article_parser_test.dart`, `test/library/article_reader_test.dart` (+ Library widget assertions for the Read section).

Modified:
- `pubspec.yaml` — register `assets/content/articles.json`.
- `lib/main.dart` — load the article catalog, add provider override.
- `lib/features/home/tabs/library_page.dart` — add the "Read" section.
- `docs/CHANGELOG.md` — entry.

## Open defaults (locked unless changed)

- Articles bundled as one JSON asset (consistent with `sessions.json`).
- Surfaced as a "Read" section inside the existing Library tab (no new route/tab).
- 6 starter articles authored now; refinement is iterative.
- English only; Hindi deferred.
