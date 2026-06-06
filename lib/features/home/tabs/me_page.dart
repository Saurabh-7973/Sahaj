import 'package:flutter/material.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

/// Me tab — progress dashboard, settings, subscription (later phases).
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Me',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress, settings, and your plan live here.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                AppListTile(
                  leadingIcon: Icons.insights_outlined,
                  title: 'Progress',
                  subtitle: 'Strength, control, consistency',
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.lock_outline,
                  title: 'Privacy & discreet mode',
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.palette_outlined,
                  title: 'Design system (dev)',
                  subtitle: 'Review Phase 1 widgets',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(Routes.showcase),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
