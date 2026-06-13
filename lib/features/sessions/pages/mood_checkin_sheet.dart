import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/models/session_models.dart';
import '../logic/session_calibration.dart';

/// "Tonight" from 5pm through the small hours — the training window.
bool isTonight(DateTime now) => now.hour >= 17 || now.hour < 4;

/// What the threshold ritual hands back to the caller.
class MoodCheckinResult {
  const MoodCheckinResult({required this.moods, required this.calibrated});

  /// Persisted into `SessionLog.moodBefore` (empty on skip).
  final List<ArrivalMood> moods;

  /// The session to actually play, plus the echo it was sold with.
  final CalibratedSession calibrated;
}

/// M1·1–2 — mood check-in sheet + prescription echo. Two taps from Today
/// into a calibrated session; the echo proves the pick changed something.
/// Returns null when dismissed (start aborted). Skip always works.
Future<MoodCheckinResult?> showMoodCheckin(
  BuildContext context, {
  required SessionDef session,
}) {
  return showModalBottomSheet<MoodCheckinResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoodCheckinSheet(session: session),
  );
}

class _MoodCheckinSheet extends StatefulWidget {
  const _MoodCheckinSheet({required this.session});

  final SessionDef session;

  @override
  State<_MoodCheckinSheet> createState() => _MoodCheckinSheetState();
}

class _MoodCheckinSheetState extends State<_MoodCheckinSheet> {
  final _selected = <ArrivalMood>{};
  CalibratedSession? _echo;

  void _toggle(ArrivalMood mood) {
    setState(() {
      if (!_selected.remove(mood)) _selected.add(mood);
    });
  }

  void _getSession() {
    setState(() {
      _echo = calibrateSession(
        session: widget.session,
        moods: _selected.toList(),
        tonight: isTonight(DateTime.now()),
      );
    });
  }

  void _skip() {
    Navigator.of(context).pop(
      MoodCheckinResult(
        moods: const [],
        calibrated: calibrateSession(
          session: widget.session,
          moods: const [],
          tonight: isTonight(DateTime.now()),
        ),
      ),
    );
  }

  void _start() {
    Navigator.of(context).pop(
      MoodCheckinResult(moods: _selected.toList(), calibrated: _echo!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF312818), lamp.surfaceRaised],
        ),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(
          top: BorderSide(color: lamp.ink.withValues(alpha: 0.16)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        15,
        AppSpacing.xl,
        AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: lamp.faint.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.settle,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: _echo == null ? _buildCheckin(lamp) : _buildEcho(lamp),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckin(LamplightTokens lamp) {
    final theme = Theme.of(context);
    final tonight = isTonight(DateTime.now());

    return Column(
      key: const ValueKey('checkin'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check-in',
          style: AppTypography.eyebrow(lamp.ochre.withValues(alpha: 0.92)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'How are you arriving ${tonight ? 'tonight' : 'today'}?',
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 20),
        AppMoodSelector(selected: _selected, onToggle: _toggle),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Up to three. Nothing is logged anywhere but this phone.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: "Get ${tonight ? "tonight's" : "today's"} session",
          onPressed: _selected.isEmpty ? null : _getSession,
        ),
        AppButton(
          label: 'Skip',
          variant: AppButtonVariant.text,
          onPressed: _skip,
        ),
      ],
    );
  }

  Widget _buildEcho(LamplightTokens lamp) {
    final theme = Theme.of(context);
    final echo = _echo!;
    final session = echo.session;
    final minutes = (session.totalSeconds / 60).ceil();
    final tonight = isTonight(DateTime.now());

    return Column(
      key: const ValueKey('echo'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${tonight ? "Tonight's" : "Today's"} session",
          style: AppTypography.eyebrow(lamp.ochre.withValues(alpha: 0.92)),
        ),
        if (echo.echoLine != null) ...[
          const SizedBox(height: 10),
          Text(
            echo.echoLine!,
            style: AppTypography.italic(17.5, lamp.gold, height: 25 / 17.5),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2F2614), Color(0xFF221C12)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border:
                Border.all(color: lamp.ochre.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppChip.type(
                    typeName: session.type.name,
                    label: _typeLabel(session.type),
                  ),
                  AppChip(label: '$minutes min'),
                  if (echo.gentler)
                    AppChip(
                      label: 'gentler ${tonight ? 'tonight' : 'today'}',
                      variant: AppChipVariant.ok,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(session.title, style: theme.textTheme.headlineMedium),
              if (echo.deltaLine != null) ...[
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  echo.deltaLine!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: lamp.faint),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Start', onPressed: _start),
        AppButton(
          label: 'Change how I arrived',
          variant: AppButtonVariant.text,
          onPressed: () => setState(() => _echo = null),
        ),
      ],
    );
  }
}

String _typeLabel(SessionType type) => switch (type) {
  SessionType.kegel => 'kegel',
  SessionType.reverseKegel => 'reverse kegel',
  SessionType.breathwork => 'breath',
  SessionType.sensate => 'sensate',
  SessionType.education => 'learn',
  SessionType.mindset => 'mindset',
};
