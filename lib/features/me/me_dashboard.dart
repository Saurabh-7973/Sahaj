import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import '../settings/preferences_controller.dart';
import 'logic/progress_metrics.dart';

/// Honest progress summary (synthesis section 12). Degrades to a calm empty
/// state before the first session. Streak is collapsible, never the largest
/// element (synthesis section 8: agency over shame).
class ProgressDashboard extends ConsumerStatefulWidget {
  const ProgressDashboard({super.key});

  @override
  ConsumerState<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends ConsumerState<ProgressDashboard> {
  bool _streakExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ref.watch(progressControllerProvider);
    final plan = ref.watch(onboardingControllerProvider).plan;
    final hideStreak = ref.watch(preferencesControllerProvider).hideStreak;

    final week = c.state.currentWeek;
    final phase = (plan == null || plan.weeks.isEmpty)
        ? ''
        : plan.weeks[(week - 1).clamp(0, plan.weeks.length - 1)].phase;

    final m = computeMetrics(
      logs: c.logs(),
      progress: c.state,
      phase: phase,
      now: DateTime.now(),
    );

    if (!m.hasData) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Your progress appears here after your first session.',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.phase.isEmpty
                    ? 'Week ${m.currentWeek} of 12'
                    : 'Week ${m.currentWeek} of 12 - ${m.phase}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('This week', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Icon(
                        i < m.thisWeekCount
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 14,
                        color: i < m.thisWeekCount
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('${m.totalSessions} sessions completed',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        if (!hideStreak) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => setState(() => _streakExpanded = !_streakExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Streak: ${m.currentStreak} days',
                        style: theme.textTheme.bodyMedium),
                    Icon(_streakExpanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                  ],
                ),
                if (_streakExpanded) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('Longest: ${m.longestStreak} days',
                      style: theme.textTheme.bodySmall),
                  Text('Easier ${m.easierCount} - Same ${m.sameCount} - Harder ${m.harderCount}',
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
