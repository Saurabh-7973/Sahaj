import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// A single mood option on the scale.
class AppMood {
  const AppMood({required this.value, required this.emoji, required this.label});

  final int value;
  final String emoji;
  final String label;
}

const kDefaultMoods = [
  AppMood(value: 1, emoji: '😞', label: 'Low'),
  AppMood(value: 2, emoji: '😕', label: 'Off'),
  AppMood(value: 3, emoji: '😐', label: 'Okay'),
  AppMood(value: 4, emoji: '🙂', label: 'Good'),
  AppMood(value: 5, emoji: '😄', label: 'Great'),
];

/// Horizontal mood scale. Tap to pick — selected option scales up + accents.
class AppMoodSelector extends StatelessWidget {
  const AppMoodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.moods = kDefaultMoods,
  });

  final int? selected;
  final ValueChanged<int> onSelected;
  final List<AppMood> moods;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in moods)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(mood.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: selected == mood.value ? 1.0 : 0.88,
                duration: AppMotion.quick,
                curve: AppMotion.enter,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.quick,
                      curve: AppMotion.transition,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected == mood.value
                            ? scheme.primary.withValues(alpha: 0.18)
                            : Colors.transparent,
                      ),
                      child: Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      mood.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected == mood.value
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
