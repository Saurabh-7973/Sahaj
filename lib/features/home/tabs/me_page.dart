import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../me/me_dashboard.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../sessions/progress_controller.dart';
import '../../settings/settings_page.dart';

/// Me tab — progress dashboard, settings, subscription (later phases).
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Me',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProgressDashboard(),
          const SizedBox(height: AppSpacing.xl),
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  ),
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.palette_outlined,
                  title: 'Design system (dev)',
                  subtitle: 'Review Phase 1 widgets',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(Routes.showcase),
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.restart_alt,
                  title: 'Reset onboarding (dev)',
                  subtitle: 'Clear answers and replay the intake',
                  onTap: () {
                    ref.read(onboardingControllerProvider).reset();
                    ref.read(progressControllerProvider).reset();
                    context.go(Routes.onboarding);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
