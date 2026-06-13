import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

/// Shared onboarding screen frame: Lamplight ground, optional top bar
/// (back + StepDots + skip), scrolling content, and a pinned bottom action
/// area. Screens that need a bespoke layout (welcome, crisis) skip this.
class OnbScaffold extends StatelessWidget {
  const OnbScaffold({
    super.key,
    this.onBack,
    this.stepCount,
    this.stepIndex,
    this.onSkip,
    required this.children,
    required this.actions,
    this.room = LampRoom.standard,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final VoidCallback? onBack;
  final int? stepCount;
  final int? stepIndex;
  final VoidCallback? onSkip;
  final List<Widget> children;

  /// Pinned at the bottom (CTA buttons, tiny print).
  final List<Widget> actions;
  final LampRoom room;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LampBackground(
        room: room,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              children: [
                if (onBack != null || stepCount != null || onSkip != null)
                  OnbTopBar(
                    onBack: onBack,
                    stepCount: stepCount,
                    stepIndex: stepIndex,
                    onSkip: onSkip,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: crossAxisAlignment,
                      children: children,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnbTopBar extends StatelessWidget {
  const OnbTopBar({
    super.key,
    this.onBack,
    this.stepCount,
    this.stepIndex,
    this.onSkip,
  });

  final VoidCallback? onBack;
  final int? stepCount;
  final int? stepIndex;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: onBack == null
                ? null
                : _IconBtn(
                    icon: Icons.chevron_left,
                    label: 'Back',
                    onTap: onBack!,
                    lamp: lamp,
                  ),
          ),
          Expanded(
            child: stepCount == null
                ? const SizedBox.shrink()
                : StepDots(count: stepCount!, current: stepIndex ?? 0),
          ),
          SizedBox(
            width: 40,
            child: onSkip == null
                ? null
                : GestureDetector(
                    onTap: onSkip,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'skip',
                      textAlign: TextAlign.right,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: lamp.inkMuted),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.lamp,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            color: lamp.ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: lamp.hairline),
          ),
          child: Icon(icon, size: 20, color: lamp.inkMuted),
        ),
      ),
    );
  }
}

/// Tracked-out uppercase eyebrow kicker.
class OnbEyebrow extends StatelessWidget {
  const OnbEyebrow(this.text, {super.key, this.center = false, this.moss = false});

  final String text;
  final bool center;
  final bool moss;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: AppTypography.eyebrow(
        (moss ? lamp.mossBright : lamp.ochre).withValues(alpha: 0.92),
      ),
    );
  }
}

/// The calm why-strip on health-check screens (mock `.strip`).
class OnbStrip extends StatelessWidget {
  const OnbStrip(this.text, {super.key, this.turmeric = false});

  final String text;
  final bool turmeric;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final accent = turmeric ? lamp.turmeric : lamp.ochre;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.55), width: 2.5),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: lamp.inkMuted,
              height: 1.45,
            ),
      ),
    );
  }
}
