import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../logic/article.dart';

/// B2 `DoctorBadge` — both states honest, both shippable. Heritage articles
/// never get this badge (M5 law 1); they carry [HeritageChip] instead.
class DoctorBadge extends StatelessWidget {
  const DoctorBadge({super.key, required this.state, this.compact = false});

  final ReviewState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final reviewed = state == ReviewState.reviewed;
    final color = reviewed ? lamp.mossBright : lamp.turmeric;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        reviewed ? '✓ Doctor-reviewed' : 'Review pending',
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: compact ? 10 : 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Heritage era chip (sand) — "heritage · 1885". Never a review badge.
class HeritageChip extends StatelessWidget {
  const HeritageChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: lamp.sand.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: lamp.sand.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: lamp.sand,
        ),
      ),
    );
  }
}

/// B1 `LockChip` — "Pro", sand outline, no padlock glyph (M5 don'ts).
class LockChip extends StatelessWidget {
  const LockChip({super.key});

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: lamp.sand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: lamp.gold.withValues(alpha: 0.45)),
      ),
      child: Text(
        'Pro',
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: lamp.gold,
        ),
      ),
    );
  }
}

/// Faint moss ✓ — a session done at least once ("redo what worked").
class DoneTick extends StatelessWidget {
  const DoneTick({super.key});

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Semantics(
      label: 'done before',
      child: Icon(Icons.check, size: 15, color: lamp.moss.withValues(alpha: 0.7)),
    );
  }
}

/// Group-header type medallion (mock `14`) — wayfinding, not decoration.
class TypeMedallion extends StatelessWidget {
  const TypeMedallion({super.key, required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.18), tint.withValues(alpha: 0.07)],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

/// Title text with the search-match substring tinted ochre.
class HighlightedTitle extends StatelessWidget {
  const HighlightedTitle({
    super.key,
    required this.text,
    required this.start,
    required this.end,
    this.style,
  });

  final String text;
  final int start;
  final int end;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: base?.copyWith(color: lamp.gold, fontWeight: FontWeight.w700),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

/// B2 `SourcesBlock` — collapsed "Sources (n)" → citation rows.
class SourcesBlock extends StatefulWidget {
  const SourcesBlock({super.key, required this.sources});
  final List<Citation> sources;

  @override
  State<SourcesBlock> createState() => _SourcesBlockState();
}

class _SourcesBlockState extends State<SourcesBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    if (widget.sources.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2419), Color(0xFF221C15)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lamp.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sources (${widget.sources.length})',
                      style: theme.textTheme.labelMedium),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: lamp.faint),
                ],
              ),
            ),
          ),
          if (_open)
            for (final c in widget.sources)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: lamp.hairline)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: lamp.ink)),
                    const SizedBox(height: 6),
                    Text(c.finding,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: lamp.faint)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// B2 `PullQuote` — heritage pieces. Oversized Fraunces quote mark, pothi
/// rules above/below (drawn by the caller), era tag in small caps.
class PullQuote extends StatelessWidget {
  const PullQuote({super.key, required this.quote, required this.eraTag});
  final String quote;
  final String eraTag;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -26,
            left: -4,
            child: Text(
              '"',
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontSize: 96,
                height: 1,
                color: lamp.ochre.withValues(alpha: 0.16),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote,
                style: AppTypography.italic(21, lamp.sand, height: 30 / 21),
              ),
              const SizedBox(height: 8),
              Text(
                eraTag.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: lamp.faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
