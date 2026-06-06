# Education Articles + Library "Read" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bundled psychoeducation articles rendered via flutter_markdown, surfaced as a "Read" section in the Library tab.

**Architecture:** A pure article model + parser over a bundled `articles.json` asset (mirrors the Phase 4 session catalog), an `ArticleCatalog` provider loaded at startup, a markdown reader page, and a "Read" section added to the existing Library tab.

**Tech Stack:** Flutter, Riverpod, flutter_markdown (already a dep), flutter_test.

---

## Conventions

- Branch `education-articles` (off `main`). Each task ends with a **Checkpoint**: `flutter analyze` ("No issues found!") + `flutter test` (all pass), then a commit.
- **TDD for pure logic** (Task 1). Straight ASCII quotes for Dart string delimiters.
- Design system + theme tokens as elsewhere.
- **Article prose** (`articles.json`) is authored by the controller during execution (Task 2) — calm psychoeducation, no medical claims; it is content, not code to transcribe.

---

## File structure

Created:
- `lib/features/library/logic/article.dart`
- `lib/features/library/logic/article_parser.dart`
- `lib/features/library/article_catalog.dart`
- `lib/features/library/pages/article_reader_page.dart`
- `assets/content/articles.json`
- Tests: `test/library/article_parser_test.dart`, `test/library/article_reader_test.dart`.

Modified:
- `pubspec.yaml` — register `assets/content/articles.json`.
- `lib/main.dart` — load article catalog + override.
- `lib/features/home/tabs/library_page.dart` — add "Read" section.
- `test/library/library_widget_test.dart` — assert the Read section renders.
- `docs/CHANGELOG.md` — entry.

---

## Task 1: Article model + parser (TDD)

**Files:**
- Create: `lib/features/library/logic/article.dart`
- Create: `lib/features/library/logic/article_parser.dart`
- Test: `test/library/article_parser_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/library/article_parser_test.dart
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
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/library/article_parser_test.dart`
Expected: FAIL — `parseArticles` not defined.

- [ ] **Step 3: Implement the model**

```dart
// lib/features/library/logic/article.dart
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
```

- [ ] **Step 4: Implement the parser**

```dart
// lib/features/library/logic/article_parser.dart
import 'dart:convert';

import 'article.dart';

/// Parses the bundled articles JSON array into Article models.
List<Article> parseArticles(String jsonStr) {
  final raw = json.decode(jsonStr) as List;
  return raw
      .map((e) => Article.fromJson(e as Map))
      .toList(growable: false);
}
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/library/article_parser_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Checkpoint + commit**

```bash
git add lib/features/library/logic/article.dart lib/features/library/logic/article_parser.dart test/library/article_parser_test.dart
git commit -m "Articles Task 1: article model + parser (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Content asset + catalog loader

**Files:**
- Create: `assets/content/articles.json`
- Create: `lib/features/library/article_catalog.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Author the content asset**

Create `assets/content/articles.json` — a JSON array of 6 articles with fields `slug`, `title`, `category`, `readMinutes`, `body` (markdown). The controller authors the prose (300–500 words each, calm psychoeducation, no medical claims, ending each with a one-line "general education, not medical advice" note). Titles/categories:
1. `how-your-pelvic-floor-works` — "How your pelvic floor works" — Anatomy
2. `kegels-and-reverse-kegels` — "Kegels and reverse Kegels, simply" — Training
3. `breathing-and-arousal` — "Breathing and arousal" — Mind & body
4. `the-brain-erection-connection` — "The brain–erection connection" — Mind & body
5. `porn-dopamine-and-rebalancing` — "Porn, dopamine, and rebalancing" — Mind & body
6. `performance-anxiety` — "Performance anxiety, and why it eases" — Mind & body

The JSON must be valid UTF-8; markdown uses `\n` for newlines inside the `body` string. Validate with `python3 -c "import json; json.load(open('assets/content/articles.json'))"`.

- [ ] **Step 2: Register the asset**

In `pubspec.yaml`, under the existing `flutter: assets:` block (which already lists `assets/content/sessions.json`), add:
```yaml
    - assets/content/articles.json
```
Run `flutter pub get`.

- [ ] **Step 3: Implement the catalog loader**

```dart
// lib/features/library/article_catalog.dart
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
```

- [ ] **Step 4: Checkpoint + commit**

Run `flutter analyze` (clean) + `flutter test` (all pass). Add a temporary File-based parse check of the real asset if you like, but do not commit it (rootBundle isn't available in plain unit tests).

```bash
git add assets/content/articles.json lib/features/library/article_catalog.dart pubspec.yaml pubspec.lock
git commit -m "Articles Task 2: content asset + catalog loader

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: main.dart wiring

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Load the article catalog + override**

Read `lib/main.dart`. Add import:
```dart
import 'features/library/article_catalog.dart';
```
After the session catalog load (`final catalog = await SessionCatalog.load();`), add:
```dart
  final articleCatalog = await ArticleCatalog.load();
```
Add the override to the `ProviderScope.overrides` list:
```dart
        articleCatalogProvider.overrideWithValue(articleCatalog),
```

- [ ] **Step 2: Checkpoint + commit**

Run `flutter analyze` (clean) + `flutter test` (all pass — existing tests pump SahajApp without this override; `articleCatalogProvider` is only read by the Library tab, which guards it in try/catch per Task 4).

```bash
git add lib/main.dart
git commit -m "Articles Task 3: wire article catalog override

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Reader page + Library "Read" section

**Files:**
- Create: `lib/features/library/pages/article_reader_page.dart`
- Modify: `lib/features/home/tabs/library_page.dart`
- Test: `test/library/article_reader_test.dart`
- Modify: `test/library/library_widget_test.dart`

- [ ] **Step 1: Create the reader page**

```dart
// lib/features/library/pages/article_reader_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/article.dart';

/// Renders a single article's markdown body.
class ArticleReaderPage extends StatelessWidget {
  const ArticleReaderPage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: article.title,
      leading: const BackButton(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${article.category} - ~${article.readMinutes} min read',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MarkdownBody(data: article.body),
        ],
      ),
    );
  }
}
```

> If `MarkdownBody` is not found, confirm the import path for the installed `flutter_markdown` version (`package:flutter_markdown/flutter_markdown.dart`) and that the dep resolved. `MarkdownBody(data:)` is stable across 0.7.x.

- [ ] **Step 2: Add the "Read" section to the Library tab**

In `lib/features/home/tabs/library_page.dart`, add imports:
```dart
import '../../library/article_catalog.dart';
import '../../library/pages/article_reader_page.dart';
```
In `build`, after reading the session catalog and before the `return AppScaffold(...)`, add a guarded article-catalog read:
```dart
    ArticleCatalog? articleCatalog;
    try {
      articleCatalog = ref.watch(articleCatalogProvider);
    } catch (_) {
      articleCatalog = null;
    }
    final articles = articleCatalog?.articles ?? const [];
```
Then, in the `Column` children, insert a Read section immediately AFTER the intro `Text(...)` + its `SizedBox(height: AppSpacing.xl)` and BEFORE the `if (groups.isEmpty)` line:
```dart
          if (articles.isNotEmpty) ...[
            Text('Read', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final article in articles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ArticleReaderPage(article: article),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.title,
                                style: theme.textTheme.titleSmall),
                            Text(
                              '${article.category} - ~${article.readMinutes} min read',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.menu_book_outlined),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
```

- [ ] **Step 3: Reader widget test**

```dart
// test/library/article_reader_test.dart
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
```

- [ ] **Step 4: Extend the Library widget test for the Read section**

In `test/library/library_widget_test.dart`, override `articleCatalogProvider` with a stub catalog and assert the Read section renders. Add imports:
```dart
import 'package:sahaj/features/library/article_catalog.dart';
import 'package:sahaj/features/library/logic/article.dart';
```
Add the override to the existing `ProviderScope(overrides: [...])` in the test:
```dart
          articleCatalogProvider.overrideWithValue(
            const ArticleCatalog([
              Article(
                slug: 'a',
                title: 'How your pelvic floor works',
                category: 'Anatomy',
                readMinutes: 3,
                body: 'body',
              ),
            ]),
          ),
```
And add assertions after `pumpAndSettle`:
```dart
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('How your pelvic floor works'), findsOneWidget);
```

- [ ] **Step 5: Run tests + full suite**

Run: `flutter test test/library/article_reader_test.dart test/library/library_widget_test.dart`, then `flutter test`.
Expected: pass.

- [ ] **Step 6: Checkpoint + commit**

Run `flutter analyze` (clean).

```bash
git add lib/features/library/pages/article_reader_page.dart lib/features/home/tabs/library_page.dart test/library/article_reader_test.dart test/library/library_widget_test.dart
git commit -m "Articles Task 4: reader page + Library Read section

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: CHANGELOG + final checkpoint

**Files:**
- Modify: `docs/CHANGELOG.md`

- [ ] **Step 1: CHANGELOG entry**

Append (matching style) a `## Education articles — Library Read section — 2026-06-06` section: bundled `articles.json` (6 psychoeducation articles), `Article` model + `parseArticles`, `ArticleCatalog` provider loaded at startup, `ArticleReaderPage` (flutter_markdown), "Read" section in the Library tab. Deferred: Firestore article sync, search, tags/bookmarks, Hindi, CMS.

- [ ] **Step 2: Final checkpoint + commit**

Run: `flutter analyze` ("No issues found!") + `flutter test` (all pass).

```bash
git add docs/CHANGELOG.md
git commit -m "Articles Task 5: CHANGELOG entry

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-review notes

- **Spec coverage:** model+parser (T1), content asset + catalog (T2), startup wiring (T3), reader + Library Read section (T4), CHANGELOG (T5). All spec sections mapped.
- **Type consistency:** `Article` (slug/title/category/readMinutes/body), `parseArticles`, `ArticleCatalog.articles`, `articleCatalogProvider`, `ArticleReaderPage(article:)` match across catalog, reader, Library, main, and tests.
- **Test-mode guard:** the Library tab guards `ref.watch(articleCatalogProvider)` in try/catch (mirrors the session-catalog guard) so widget tests/shell without the override render an empty Read section. The Library widget test adds the override to assert the section.
- **Content caveat (T2):** article prose authored at execution time, calm psychoeducation, no diagnosis/medical claims; each article carries a one-line "general education, not medical advice" note.
- **Deferred (per spec):** Firestore sync, search, tags/bookmarks, Hindi, CMS.
```
