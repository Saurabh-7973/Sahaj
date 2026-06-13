import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../../me/me_dashboard.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../sessions/progress_controller.dart';
import '../../settings/settings_page.dart';
import '../../subscription/pages/subscription_page.dart';
import '../../subscription/subscription_controller.dart';

/// Me tab — the progress dashboard (M3) plus the privacy/subscription tiles.
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final isPro = ref.watch(subscriptionControllerProvider).isPro;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Me',
                            style: AppTypography.eyebrow(
                              lamp.inkMuted.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your progress',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _GearButton(lamp: lamp),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const ProgressDashboard(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _MeTile(
                        icon: Icons.lock_outline,
                        label: 'Privacy',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MeTile(
                        icon: Icons.workspace_premium_outlined,
                        label: isPro ? 'Sahaj Pro' : 'Subscription',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SubscriptionPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Dev affordances — out of the way at the bottom.
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    children: [
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
          ),
        ),
      ),
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({required this.lamp});

  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Settings',
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                lamp.ochre.withValues(alpha: 0.18),
                lamp.ochre.withValues(alpha: 0.07),
              ],
            ),
            border: Border.all(color: lamp.ochre.withValues(alpha: 0.26)),
          ),
          child: Icon(Icons.settings_outlined, size: 19, color: lamp.gold),
        ),
      ),
    );
  }
}

class _MeTile extends StatelessWidget {
  const _MeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C2419), Color(0xFF221C15)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: lamp.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: lamp.sand.withValues(alpha: 0.1),
                border: Border.all(color: lamp.sand.withValues(alpha: 0.24)),
              ),
              child: Icon(icon, size: 15, color: lamp.sand),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
