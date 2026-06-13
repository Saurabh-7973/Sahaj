import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../widgets/onb_chrome.dart';

/// M4·03 — interrupted onboarding. Return lands here, not at screen 1: a
/// plain statement of where he was and where his answers live. Continuing
/// costs nothing; Start over wipes onboarding answers only.
class ResumeScreen extends StatelessWidget {
  const ResumeScreen({
    super.key,
    required this.whereLine,
    required this.orientation,
    required this.onContinue,
    required this.onStartOver,
  });

  /// "You were on the health check."
  final String whereLine;

  /// "Question 4 of 9" — the one place a numeral is allowed (orientation).
  final String? orientation;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
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
                  child: Icon(Icons.bookmark_outline, size: 34, color: lamp.gold),
                ),
                const SizedBox(height: AppSpacing.xl),
                const OnbEyebrow('Picking up', center: true),
                const SizedBox(height: 10),
                Text(whereLine,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(fontSize: 28)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  orientation == null
                      ? 'Your answers are saved on this phone, nowhere else.'
                      : '$orientation — your answers are saved on this phone, '
                          'nowhere else.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: lamp.inkMuted),
                ),
                const Spacer(),
                AppButton(label: 'Continue', onPressed: onContinue),
                AppButton(
                  label: 'Start over',
                  variant: AppButtonVariant.text,
                  onPressed: onStartOver,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
