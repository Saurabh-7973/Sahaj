import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/onboarding_controller.dart';

/// Today tab — daily session + mood check-in (content lands in later phases).
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(onboardingControllerProvider).plan;
    final subtitle = plan == null
        ? 'Your plan is ready'
        : 'Week 1 of ${plan.weeks.length} — ${plan.weeks.first.phase}';

    return AppScaffold(
      title: 'Today',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your session', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Mood check-in and today’s 7-minute practice arrive here.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Start session', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
