import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// A tappable option row (mock `.opt`). Dark gradient idle → ochre border +
/// gold radio/check when selected. Calm, no fear, no urgency.
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
    final lamp = context.lamp;
    final radius = BorderRadius.circular(19);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.transition,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [const Color(0xFF3A2D14), const Color(0xFF27200F)]
                  : [const Color(0xFF272019), const Color(0xFF1F1A14)],
            ),
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? lamp.gold.withValues(alpha: 0.6)
                  : lamp.ink.withValues(alpha: 0.09),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: lamp.ochre.withValues(alpha: 0.4),
                      blurRadius: 32,
                      spreadRadius: -14,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 21 / 15,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Indicator(selected: selected, multi: multi, lamp: lamp),
            ],
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.selected,
    required this.multi,
    required this.lamp,
  });

  final bool selected;
  final bool multi;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    if (multi) {
      return Container(
        width: 21,
        height: 21,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: selected
              ? LinearGradient(colors: [lamp.gold, const Color(0xFFBA8030)])
              : null,
          border: Border.all(
            color: selected ? Colors.transparent : lamp.faint,
            width: 2,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 13, color: lamp.onOchre)
            : null,
      );
    }
    return Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? lamp.gold : lamp.faint,
          width: selected ? 6 : 2,
        ),
      ),
    );
  }
}
