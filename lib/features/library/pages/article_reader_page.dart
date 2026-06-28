import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/article.dart';
import '../widgets/library_widgets.dart';

/// M5 reader — two registers, never blended. Evidence: doctor badge, drop
/// cap, sources footer, claims allowed. Heritage: era chip, pull quotes,
/// anti-shame canon line, zero health claims.
class ArticleReaderPage extends StatefulWidget {
  const ArticleReaderPage({super.key, required this.article, this.nextArticle});

  final Article article;
  final Article? nextArticle;

  @override
  State<ArticleReaderPage> createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  final _scroll = ScrollController();
  double _progress = 0;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final max = _scroll.position.maxScrollExtent;
    setState(() => _progress = max <= 0 ? 1 : (_scroll.offset / max).clamp(0, 1));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final a = widget.article;
    final heritage = a.isHeritage;
    final blocks = _parseBlocks(a.body);

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Column(
            children: [
              // The only reading gamification that will ever exist.
              _ProgressBar(progress: _progress, lamp: lamp),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                child: Row(
                  children: [
                    _IconBtn(
                      icon: Icons.chevron_left,
                      label: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                      lamp: lamp,
                    ),
                    const Spacer(),
                    _IconBtn(
                      icon: _bookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      label: 'Bookmark',
                      onTap: () => setState(() => _bookmarked = !_bookmarked),
                      lamp: lamp,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heritage ? 'Read · heritage' : 'Read · evidence-based',
                        style: AppTypography.eyebrow(
                          (heritage ? lamp.turmeric : lamp.ochre)
                              .withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(a.title,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontSize: 26, height: 33 / 26)),
                      const SizedBox(height: AppSpacing.md),
                      _MetaRow(article: a, lamp: lamp, theme: theme),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: RuleDivider(),
                      ),
                      if (heritage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            'Heritage, not instruction — and never medicine.',
                            style: AppTypography.italic(13.5, lamp.sand),
                          ),
                        ),
                      ..._renderBlocks(blocks, theme, lamp, heritage),
                      const SizedBox(height: AppSpacing.lg),
                      _TrustFooter(
                        article: a,
                        next: widget.nextArticle,
                        lamp: lamp,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Split the markdown body into typed blocks. Line-based so a single
  // paragraph can be followed by a bullet list without a blank line between
  // them — headings (#/##/###), quotes (> ), and bullets (- / *) each break
  // the running paragraph; blank lines do too.
  List<_Block> _parseBlocks(String body) {
    final out = <_Block>[];
    final para = <String>[];
    void flush() {
      if (para.isEmpty) return;
      out.add(_Block(_BlockKind.para, para.join(' ').trim()));
      para.clear();
    }

    for (final rawLine in body.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flush();
      } else if (line.startsWith('### ')) {
        flush();
        out.add(_Block(_BlockKind.heading, line.substring(4).trim(), level: 3));
      } else if (line.startsWith('## ')) {
        flush();
        out.add(_Block(_BlockKind.heading, line.substring(3).trim(), level: 2));
      } else if (line.startsWith('# ')) {
        flush();
        out.add(_Block(_BlockKind.heading, line.substring(2).trim(), level: 2));
      } else if (line.startsWith('> ')) {
        flush();
        out.add(_Block(_BlockKind.quote, line.substring(2).trim()));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        flush();
        out.add(_Block(_BlockKind.bullet, line.substring(2).trim()));
      } else {
        para.add(line);
      }
    }
    flush();
    return out;
  }

  List<Widget> _renderBlocks(
      List<_Block> blocks, ThemeData theme, LamplightTokens lamp, bool heritage) {
    final widgets = <Widget>[];
    var firstPara = true;
    for (final b in blocks) {
      switch (b.kind) {
        case _BlockKind.heading:
          final isSub = b.level >= 3;
          widgets.add(Padding(
            padding: EdgeInsets.fromLTRB(0, isSub ? 16 : 18, 0, isSub ? 6 : 8),
            child: Text(
              b.text,
              style: isSub
                  ? theme.textTheme.titleLarge?.copyWith(
                      fontFamily: AppTypography.display,
                      fontSize: 18.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: lamp.sand,
                    )
                  : theme.textTheme.headlineMedium,
            ),
          ));
        case _BlockKind.bullet:
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 11, left: 2, right: 12),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration:
                        BoxDecoration(color: lamp.gold, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: Text.rich(TextSpan(
                    children: _inlineMarkdown(
                        b.text, AppTypography.reader(lamp.inkMuted)),
                  )),
                ),
              ],
            ),
          ));
        case _BlockKind.quote:
          widgets.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: RuleDivider(),
          ));
          widgets.add(PullQuote(
            quote: b.text,
            eraTag: widget.article.eraTag ?? 'language of its time',
          ));
          widgets.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: RuleDivider(),
          ));
        case _BlockKind.para:
          // Evidence opening paragraph gets the Fraunces drop cap.
          if (firstPara && !heritage) {
            widgets.add(_DropCapParagraph(text: b.text, lamp: lamp));
          } else {
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text.rich(TextSpan(
                children:
                    _inlineMarkdown(b.text, AppTypography.reader(lamp.inkMuted)),
              )),
            ));
          }
          firstPara = false;
      }
    }
    return widgets;
  }
}

enum _BlockKind { heading, quote, para, bullet }

class _Block {
  const _Block(this.kind, this.text, {this.level = 0});
  final _BlockKind kind;
  final String text;

  /// Heading depth (2 or 3); 0 for non-headings.
  final int level;
}

/// Renders inline `**bold**` and `*italic*` markers into styled spans. Anything
/// else passes through as plain text in [base]. Bold is matched before italic
/// so `**x**` never gets read as two stray asterisks.
List<InlineSpan> _inlineMarkdown(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
  var i = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > i) {
      spans.add(TextSpan(text: text.substring(i, m.start), style: base));
    }
    if (m.group(1) != null) {
      spans.add(TextSpan(
          text: m.group(1),
          style: base.copyWith(fontWeight: FontWeight.w700)));
    } else {
      spans.add(TextSpan(
          text: m.group(2),
          style: base.copyWith(fontStyle: FontStyle.italic)));
    }
    i = m.end;
  }
  if (i < text.length) {
    spans.add(TextSpan(text: text.substring(i), style: base));
  }
  return spans;
}

class _DropCapParagraph extends StatelessWidget {
  const _DropCapParagraph({required this.text, required this.lamp});
  final String text;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final cap = text.characters.first;
    final rest = text.characters.skip(1).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: cap,
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontSize: 46,
                height: 0.9,
                fontWeight: FontWeight.w600,
                color: lamp.gold,
              ),
            ),
            ..._inlineMarkdown(rest, AppTypography.reader(lamp.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.article, required this.lamp, required this.theme});
  final Article article;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (article.isHeritage)
          HeritageChip(
            label: article.eraTag == null
                ? 'heritage'
                : 'heritage · ${_year(article.eraTag!)}',
          )
        else
          DoctorBadge(state: article.reviewState),
        Text('${article.readMinutes} min',
            style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint)),
        if (!article.isHeritage && article.sources.isNotEmpty) ...[
          Text('·', style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint)),
          Text('${article.sources.length} sources',
              style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint)),
        ],
      ],
    );
  }

  String _year(String eraTag) {
    final m = RegExp(r'(\d{4})').firstMatch(eraTag);
    return m?.group(1) ?? eraTag;
  }
}

/// The trust footer (m5_02) — the clinic register's proof-of-work. Heritage
/// pieces show neither badge nor sources here.
class _TrustFooter extends StatelessWidget {
  const _TrustFooter({
    required this.article,
    required this.next,
    required this.lamp,
    required this.theme,
  });

  final Article article;
  final Article? next;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!article.isHeritage) ...[
          const RuleDivider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              DoctorBadge(state: article.reviewState),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  article.reviewState == ReviewState.reviewed
                      ? '${article.reviewedDate ?? ''} · review record on file'
                      : 'awaiting a doctor\'s sign-off',
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: lamp.faint),
                ),
              ),
            ],
          ),
          if (article.sources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SourcesBlock(sources: article.sources),
          ],
          if (article.relatedSessionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ReadDoBridge(label: article.relatedSessionLabel!, lamp: lamp),
          ],
        ],
        if (next != null) ...[
          const SizedBox(height: AppSpacing.md),
          _NextCard(next: next!, lamp: lamp, theme: theme),
        ],
      ],
    );
  }
}

/// Read→do bridge (decision #16) — an informational pairing, not a jump. The
/// daily loop plays today's scheduled session, so this names the training the
/// reading connects to rather than deep-linking an arbitrary one.
class _ReadDoBridge extends StatelessWidget {
  const _ReadDoBridge({required this.label, required this.lamp});
  final String label;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: lamp.moss.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: lamp.moss.withValues(alpha: 0.5), width: 2.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Put it into practice',
              style: AppTypography.eyebrow(
                  lamp.mossBright.withValues(alpha: 0.92))),
          const SizedBox(height: 6),
          Text(
            'This pairs with your “$label” training — it’s already part of your '
            'plan, and shows up on the days it fits.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: lamp.inkMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.next, required this.lamp, required this.theme});
  final Article next;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF332915), Color(0xFF251E14)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: lamp.ochre.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -40,
              child: LotusMark(
                  size: 130, color: lamp.ochre.withValues(alpha: 0.13)),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next',
                      style: AppTypography.eyebrow(
                          lamp.inkMuted.withValues(alpha: 0.72))),
                  const SizedBox(height: AppSpacing.sm),
                  Text(next.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: AppTypography.display,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${next.readMinutes} min read',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: lamp.faint)),
                      if (next.isHeritage)
                        HeritageChip(label: 'heritage')
                      else
                        DoctorBadge(state: next.reviewState, compact: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.lamp});
  final double progress;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.02, 1),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lamp.gold, const Color(0xFFBA8030)],
              ),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
              boxShadow: [
                BoxShadow(
                    color: lamp.ochre.withValues(alpha: 0.55), blurRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.lamp,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: lamp.ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: lamp.hairline),
          ),
          child: Icon(icon, size: 18, color: lamp.inkMuted),
        ),
      ),
    );
  }
}
