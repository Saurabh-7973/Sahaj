import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

/// A tappable option row for onboarding single/multi-select questions.
/// Calm accent + check when selected. No fear, no urgency.
class SelectableOption extends StatelessWidget {
  const SelectableOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Multi-select shows a square check; single-select shows a radio dot.
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);

    return AnimatedContainer(
      duration: AppMotion.quick,
      curve: AppMotion.transition,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyLarge),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  selected
                      ? (multi ? Icons.check_box : Icons.radio_button_checked)
                      : (multi
                            ? Icons.check_box_outline_blank
                            : Icons.radio_button_unchecked),
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
