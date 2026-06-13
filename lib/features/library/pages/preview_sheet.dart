import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/library_logic.dart';

/// B2 `PreviewSheet` — a locked library row sells by describing, never by
/// blocking mid-task. "Maybe later" is always one tap. Pops true if the user
/// chose to see Pro.
Future<bool?> showPreviewSheet(BuildContext context, LibraryRow row) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PreviewSheet(row: row),
  );
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.row});
  final LibraryRow row;

  String get _description {
    // Real content: the session's main working step, never a fabricated pitch.
    for (final st in row.session.steps) {
      if (st.guidance.length > 30) return st.guidance;
    }
    return row.session.steps.isEmpty ? '' : row.session.steps.last.guidance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final tint = sessionTypeTint(lamp, row.session.type.name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF312818), lamp.surfaceRaised],
        ),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: lamp.ink.withValues(alpha: 0.16))),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        15,
        AppSpacing.xl,
        AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: lamp.faint.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              TypeMedallionLarge(
                  icon: Icons.spa_outlined, tint: tint),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppChip.type(
                          typeName: row.session.type.name,
                          label: libraryTypeLabel(row.session.type).toLowerCase(),
                        ),
                        AppChip(label: '${row.minutes} min'),
                        const _ProChip(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(row.session.title,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontSize: 23)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: lamp.inkMuted, height: 22 / 14)),
          const SizedBox(height: 20),
          AppButton(
            label: 'See Pro',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          AppButton(
            label: 'Maybe later',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class TypeMedallionLarge extends StatelessWidget {
  const TypeMedallionLarge({super.key, required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.18), tint.withValues(alpha: 0.07)],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: Icon(icon, size: 24, color: tint),
    );
  }
}

class _ProChip extends StatelessWidget {
  const _ProChip();

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
      child: Text('Pro',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: lamp.gold,
          )),
    );
  }
}
