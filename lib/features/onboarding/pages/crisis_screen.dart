import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

/// Shown immediately when the self-harm question is answered above
/// "Not at all". Calm, non-clinical, India crisis resources. Not a gate —
/// the user can return to onboarding via "I'm safe, continue".
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const _lines = [
    ('Tele-MANAS', '14416'),
    ('iCall', '9152987821'),
    ('AASRA', '9820466726'),
  ];

  /// Opens the dialer for [number]. Best-effort and never throws — a crisis
  /// screen must not crash if no dialer is available (e.g. a tablet).
  Future<void> _dial(String number) async {
    try {
      await launchUrl(
        Uri.parse('tel:$number'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Swallow: the number is also shown on screen to dial manually.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('You deserve support', style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Thank you for being honest. What you’re feeling matters, and you '
            'don’t have to carry it alone. Talking to someone trained can help '
            'right now — these lines are free and confidential.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                onTap: () => _dial(line.$2),
                child: Row(
                  children: [
                    Icon(Icons.call_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.$1, style: theme.textTheme.titleMedium),
                          Text(line.$2, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'I’m safe, continue',
            variant: AppButtonVariant.outlined,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
