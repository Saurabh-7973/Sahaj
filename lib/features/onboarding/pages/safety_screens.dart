import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../widgets/onb_chrome.dart';
import '../widgets/selectable_option.dart';

/// Emergency carve-out screen (safety pack §3). Shown when an emergency
/// question is answered "Yes" — priapism or saddle/leg neuro signs. Highest
/// urgency after the crisis screen: a clear urgent-care message and a one-tap
/// call to 112. Not diagnosis, and not a hard block — a quiet Continue returns
/// to the flow, but the message leads.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  Future<void> _dial(String number) async {
    try {
      await launchUrl(
        Uri.parse('tel:$number'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Swallow — the number is on screen to dial by hand.
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
                  'This is worth a doctor today — not later.',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontSize: 31, height: 39 / 31),
                ),
                const SizedBox(height: 14),
                Text(
                  'From your answer, this can need urgent medical attention. '
                  'Please contact a doctor or emergency services now. It may '
                  'be nothing — getting it checked is still the right move.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16.5, height: 25 / 16.5, color: lamp.inkMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                DialCard(
                  name: 'Emergency · 112',
                  availability: 'India · 24/7',
                  onCall: () => _dial('112'),
                ),
                const Spacer(),
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

/// Down-training advisory (safety pack §2). Shown when the hypertonic screen
/// suggests a likely-tight floor (two or more "yes"). Explains why
/// strengthen-first could be the wrong start and that the plan now leads with
/// gentle relaxation work — and asks them to get it checked when they can.
/// Free articles stay open regardless. Conservative, never a diagnosis.
class TensionAdvisoryScreen extends StatelessWidget {
  const TensionAdvisoryScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbScaffold(
      onBack: onBack,
      actions: [
        AppButton(
          label: 'Start with the gentler plan',
          onPressed: onContinue,
        ),
      ],
      children: [
        const SizedBox(height: AppSpacing.md),
        const OnbEyebrow('Care'),
        const SizedBox(height: 10),
        Text('A gentler starting point', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.lg),
        const OnbStrip(
          'From your answers, your pelvic floor may be more tight than weak. '
          'Starting with strengthening could make that worse.',
          turmeric: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'So we\'ve put you on a relaxation-first version of the plan — gentle '
          'down-training leads, strengthening comes later. The better first '
          'step is to have this looked at by a doctor or a pelvic-floor '
          'physiotherapist when you can. The free articles stay open either '
          'way.',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// Must-accept health disclaimer (safety pack §1a). Shown once before the
/// first session; cannot proceed without ticking the single acknowledgement.
/// Acceptance + version/date are stored on the onboarding state.
class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({
    super.key,
    required this.onAccept,
    required this.onBack,
  });

  final VoidCallback onAccept;
  final VoidCallback onBack;

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _agreed = false;

  static const _points = [
    'These are general exercises, not personal medical advice. You do them at '
        'your own risk.',
    'Check with a doctor or a pelvic-floor physiotherapist before you start — '
        'especially with pain, a medical condition, or past pelvic surgery, '
        'injury, or a neurological condition.',
    'Stop immediately if anything hurts. Pain is a signal to ease off and get '
        'it checked, never to push harder.',
    'If you notice a warning sign, or things don\'t improve with consistent '
        'practice, see a doctor.',
    'In an emergency, call 112 (India).',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    return OnbScaffold(
      onBack: widget.onBack,
      actions: [
        SelectableOption(
          label: 'I understand and agree.',
          selected: _agreed,
          multi: true,
          onTap: () => setState(() => _agreed = !_agreed),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Begin',
          onPressed: _agreed ? widget.onAccept : null,
        ),
      ],
      children: [
        const SizedBox(height: AppSpacing.md),
        const OnbEyebrow('Before you start'),
        const SizedBox(height: 10),
        Text('Please read this first', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sahaj is an educational and training tool, not medical care. It '
          'doesn\'t diagnose anything, it isn\'t a substitute for a doctor, '
          'and using it doesn\'t create a doctor–patient relationship.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final p in _points)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Icon(Icons.circle, size: 5, color: lamp.inkMuted),
                ),
                Expanded(
                  child: Text(p,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: lamp.inkMuted, height: 1.45)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
