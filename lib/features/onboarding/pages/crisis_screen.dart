import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../widgets/onb_chrome.dart';

/// C7b — the highest-care screen. Shown immediately when the self-harm item
/// is answered above "Not at all". Largest type and padding in the app; no
/// dots, no watermark, no decoration beyond warmth. Tap-to-dial is the whole
/// job. Not a gate — a quiet Continue returns to the questionnaire.
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  // Numbers as implemented (wired to real tel: intents).
  static const _lines = [
    ('Tele-MANAS · 14416', 'Free · 24/7 · Hindi & English', '14416'),
    ('iCall', 'Mon–Sat · trained counsellors', '9152987821'),
    ('AASRA', '24/7 · confidential', '9820466726'),
  ];

  /// Opens the dialer; best-effort, never throws (a crisis screen must not
  /// crash if no dialer exists). The number is also on screen to dial by hand.
  Future<void> _dial(String number) async {
    try {
      await launchUrl(
        Uri.parse('tel:$number'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Swallow.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;

    return Scaffold(
      body: LampBackground(
        room: LampRoom.deep,
        grain: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                OnbEyebrow('Right now', moss: true),
                const SizedBox(height: 10),
                Text(
                  'Pause the questionnaire — this matters more.',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontSize: 31, height: 39 / 31),
                ),
                const SizedBox(height: 14),
                Text(
                  'You mentioned thoughts of harming yourself. You deserve '
                  'real support from a person, today.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontSize: 16.5, height: 25 / 16.5, color: lamp.inkMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final line in _lines)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: DialCard(
                              name: line.$1,
                              availability: line.$2,
                              onCall: () => _dial(line.$3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Sahaj will be here whenever you come back.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                AppButton(
                  label: 'Continue',
                  variant: AppButtonVariant.text,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
