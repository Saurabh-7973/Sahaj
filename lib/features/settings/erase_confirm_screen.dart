import 'package:flutter/material.dart';

import '../../core/theme/app_background.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/widgets.dart';

/// G1 / `22` — erase confirm. Full screen, never a dialog. `HoldToConfirm`
/// reuses the ring as its meter; releasing early resets with no penalty copy.
/// Deliberateness comes from friction and plain words — no red anywhere.
class EraseConfirmScreen extends StatelessWidget {
  const EraseConfirmScreen({
    super.key,
    required this.onErase,
    this.headline = 'Erase everything',
  });

  /// Wipes everything (incl. onboarding answers + PIN) and routes to Welcome.
  final VoidCallback onErase;
  final String headline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.chevron_left, color: lamp.inkMuted),
                  ),
                ),
                const Spacer(),
                Text(headline, style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: lamp.inkMuted, height: 1.5),
                      children: [
                        const TextSpan(
                            text:
                                'This deletes your plan, history, journal and '
                                'settings from this phone. There is '),
                        TextSpan(
                            text: 'no cloud copy',
                            style: TextStyle(color: lamp.ink)),
                        const TextSpan(text: ' — gone is gone.'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                HoldToConfirm(
                  label: 'Hold to erase',
                  onConfirm: onErase,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text('Keep holding — three seconds.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: lamp.faint)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Keep my data',
                  variant: AppButtonVariant.text,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
