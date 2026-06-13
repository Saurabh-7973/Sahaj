import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../../library/article_catalog.dart';
import '../../library/logic/article.dart';
import '../../library/logic/library_logic.dart';
import '../../library/pages/article_reader_page.dart';
import '../../library/pages/preview_sheet.dart';
import '../../library/widgets/library_widgets.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
import '../../sessions/session_audio.dart';
import '../../sessions/session_catalog.dart';
import '../../subscription/logic/feature_gate.dart';
import '../../subscription/soft_paywall.dart';
import '../../subscription/subscription_controller.dart';

/// M5 — the Library: a study, not a feed. Reading first, then collapsible
/// practice groups. One lock type (Pro); free rows sort first; no week-gates.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _searchController = TextEditingController();
  String _query = '';
  SessionType? _openGroup; // one group expanded at a time

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;

    SessionCatalog? catalog;
    try {
      catalog = ref.watch(sessionCatalogProvider);
    } catch (_) {
      catalog = null;
    }
    ArticleCatalog? articleCatalog;
    try {
      articleCatalog = ref.watch(articleCatalogProvider);
    } catch (_) {
      articleCatalog = null;
    }
    final isPro = ref.watch(subscriptionControllerProvider).isPro;
    final logs = ref.watch(progressControllerProvider).logs();

    final groups = catalog == null
        ? const <LibraryGroup>[]
        : buildGroups(
            catalog: catalog,
            isPro: isPro,
            doneTags: completedTags(logs),
          );
    final articles = articleCatalog?.articles ?? const <Article>[];
    final searching = _query.trim().isNotEmpty;
    final matches = searching ? searchLibrary(groups, _query) : const <SearchMatch>[];

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Library',
                          style: theme.textTheme.displaySmall?.copyWith(fontSize: 27)),
                      const SizedBox(height: AppSpacing.md),
                      _SearchBar(
                        controller: _searchController,
                        active: searching,
                        onChanged: (v) => setState(() => _query = v),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (searching)
                _searchResults(theme, lamp, matches)
              else
                _browse(theme, lamp, articles, groups, isPro),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search results ──────────────────────────────────────────────────────
  Widget _searchResults(ThemeData theme, LamplightTokens lamp,
      List<SearchMatch> matches) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${matches.length} match${matches.length == 1 ? '' : 'es'}',
                style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint)),
            const SizedBox(height: AppSpacing.md),
            if (matches.isNotEmpty) ...[
              const OnbLikeEyebrow('Practice'),
              const SizedBox(height: AppSpacing.sm),
              _RowCard(
                child: Column(
                  children: [
                    for (var i = 0; i < matches.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: lamp.hairline),
                      _PracticeRow(
                        row: matches[i].row,
                        highlight: (matches[i].start, matches[i].end),
                        onTap: () => _onRowTap(matches[i].row),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Browse (reading first, then practice groups) ────────────────────────
  Widget _browse(ThemeData theme, LamplightTokens lamp, List<Article> articles,
      List<LibraryGroup> groups, bool isPro) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (articles.isNotEmpty) ...[
              const OnbLikeEyebrow('Read'),
              const SizedBox(height: AppSpacing.sm),
              for (final (index, article) in articles.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ArticleCard(
                    article: article,
                    locked: isArticleLocked(index, isPro: isPro),
                    onTap: () {
                      if (isArticleLocked(index, isPro: isPro)) {
                        showSoftPaywall(context, source: 'library_article');
                      } else {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ArticleReaderPage(
                            article: article,
                            nextArticle: index + 1 < articles.length
                                ? articles[index + 1]
                                : null,
                          ),
                        ));
                      }
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (groups.isEmpty)
              _RowCard(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('Sessions will appear here.',
                      style: theme.textTheme.bodyMedium),
                ),
              )
            else ...[
              OnbLikeEyebrow('Practice · ${totalSessions(groups)} sessions'),
              const SizedBox(height: AppSpacing.sm),
              for (final group in groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _GroupCard(
                    group: group,
                    expanded: _openGroup == group.type,
                    onToggle: () => setState(() =>
                        _openGroup = _openGroup == group.type ? null : group.type),
                    onRowTap: _onRowTap,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _onRowTap(LibraryRow row) {
    if (row.locked) {
      showPreviewSheet(context, row).then((seePro) {
        if (seePro == true && mounted) {
          showSoftPaywall(context, source: 'library_preview');
        }
      });
    } else {
      _practise(row.session);
    }
  }

  // Free practice → the player directly (no mood sheet; it isn't the
  // prescribed session). Logs activity but never advances the plan day.
  Future<void> _practise(SessionDef session) async {
    final startedAt = DateTime.now();
    var completion = 0.0;
    var holdSeconds = 0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPlayerPage(
          session: session,
          audio: ref.read(sessionAudioFactoryProvider)(),
          onHoldSeconds: (s) => holdSeconds = s,
          onComplete: (pct) {
            completion = pct;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (completion == 0.0 || !mounted) return;
    ref.read(progressControllerProvider).logPractice(
          SessionLog(
            id: startedAt.microsecondsSinceEpoch.toString(),
            sessionTag: session.tag,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            completionPct: completion,
            moodBefore: const [],
            holdSeconds: holdSeconds,
          ),
        );
  }
}

/// Section eyebrow used on the library tab.
class OnbLikeEyebrow extends StatelessWidget {
  const OnbLikeEyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Text(text,
        style: AppTypography.eyebrow(lamp.ochre.withValues(alpha: 0.92)));
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.active,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool active;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
      decoration: BoxDecoration(
        color: lamp.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? lamp.ochre.withValues(alpha: 0.5) : lamp.hairline,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16,
              color: active ? lamp.gold : lamp.faint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
              cursorColor: lamp.gold,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search reading & practice',
                hintStyle: theme.textTheme.bodySmall?.copyWith(color: lamp.faint),
              ),
            ),
          ),
          if (active)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: lamp.faint),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2419), Color(0xFF221C15)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lamp.hairline),
      ),
      child: child,
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.locked,
    required this.onTap,
  });

  final Article article;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: _RowCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeMedallion(
                icon: article.isHeritage
                    ? Icons.menu_book_outlined
                    : Icons.health_and_safety_outlined,
                tint: article.isHeritage ? lamp.turmeric : lamp.moss,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: AppTypography.display,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (locked)
                          const LockChip()
                        else if (article.isHeritage)
                          HeritageChip(label: article.eraTag == null
                              ? 'heritage'
                              : 'heritage · ${_year(article.eraTag!)}')
                        else
                          DoctorBadge(state: article.reviewState, compact: true),
                        Text('${article.readMinutes} min',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: lamp.faint)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _year(String eraTag) {
    final m = RegExp(r'(\d{4})').firstMatch(eraTag);
    return m?.group(1) ?? eraTag;
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.onRowTap,
  });

  final LibraryGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<LibraryRow> onRowTap;

  static const _icons = {
    SessionType.kegel: Icons.adjust,
    SessionType.reverseKegel: Icons.unfold_more,
    SessionType.breathwork: Icons.air,
    SessionType.sensate: Icons.favorite_border,
    SessionType.mindset: Icons.self_improvement,
    SessionType.education: Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final tint = sessionTypeTint(lamp, group.type.name);

    return _RowCard(
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  TypeMedallion(icon: _icons[group.type]!, tint: tint),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(group.label, style: theme.textTheme.titleLarge),
                  ),
                  Text('${group.count}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 6),
                  Icon(expanded ? Icons.expand_less : Icons.chevron_right,
                      size: 20, color: lamp.faint),
                ],
              ),
            ),
          ),
          if (expanded)
            for (final row in group.rows) ...[
              Divider(height: 1, color: lamp.hairline),
              _PracticeRow(row: row, onTap: () => onRowTap(row)),
            ],
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.row,
    required this.onTap,
    this.highlight,
  });

  final LibraryRow row;
  final VoidCallback onTap;
  final (int, int)? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (highlight != null)
                    HighlightedTitle(
                      text: row.session.title,
                      start: highlight!.$1,
                      end: highlight!.$2,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
                    )
                  else
                    Text(row.session.title,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 6),
                  Text(row.context,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: lamp.faint)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(label: '${row.minutes} min'),
            if (row.doneBefore) ...[
              const SizedBox(width: AppSpacing.sm),
              const DoneTick(),
            ],
            if (row.locked) ...[
              const SizedBox(width: AppSpacing.sm),
              const LockChip(),
            ],
          ],
        ),
      ),
    );
  }
}
