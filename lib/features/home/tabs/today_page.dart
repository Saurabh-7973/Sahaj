import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/events.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../settings/preferences_controller.dart';
import '../../subscription/logic/feature_gate.dart';
import '../../subscription/soft_paywall.dart';
import '../../subscription/subscription_controller.dart';
import '../../sessions/logic/face_down_sensor.dart';
import '../../sessions/logic/haptic_cues.dart';
import '../../sessions/logic/scheduler.dart';
import '../../sessions/pages/completion_page.dart';
import '../../sessions/pages/face_down_coach.dart';
import '../../sessions/pages/mood_checkin_sheet.dart';
import '../../sessions/pages/reflection_page.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
import '../../sessions/session_audio.dart';
import '../../sessions/session_catalog.dart';

/// Today tab — derives today's session from the plan + progress and runs the
/// mood -> player -> reflection loop.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(onboardingControllerProvider).plan;
    final progress = ref.watch(progressControllerProvider);
    final hideStreak = ref.watch(preferencesControllerProvider).hideStreak;
    final isPro = ref.watch(subscriptionControllerProvider).isPro;

    // Catalog may be unoverridden in widget tests; guard it.
    SessionCatalog? catalog;
    try {
      catalog = ref.watch(sessionCatalogProvider);
    } catch (_) {
      catalog = null;
    }

    final week = progress.state.currentWeek;
    final day = progress.state.currentDay;
    final session = (plan == null || catalog == null)
        ? null
        : todaysSession(
            plan: plan, week: week, day: day, catalog: catalog.byTag);

    return AppScaffold(
      title: 'Today',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan == null
                ? 'Finish onboarding to get your plan'
                : 'Week $week of 12 — ${plan.weeks[(week - 1).clamp(0, plan.weeks.length - 1)].phase}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!hideStreak && progress.state.streak > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('🔥 ${progress.state.streak}-day streak',
                style: theme.textTheme.labelMedium),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (isPlanWeekLocked(week, isPro: isPro))
            _ProWeekLock(theme: theme, week: week)
          else
            _body(context, ref, theme, plan, session, progress, hideStreak),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Plan? plan,
    SessionDef? session,
    ProgressController progress,
    bool hideStreak,
  ) {
    if (plan == null) {
      return AppCard(
        child: Text('Your plan appears once onboarding is complete.',
            style: theme.textTheme.bodyMedium),
      );
    }
    if (progress.isDoneToday) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Done for today', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
                hideStreak
                    ? 'Come back tomorrow for the next session.'
                    : 'Come back tomorrow to keep the streak going.',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }
    if (session == null) {
      return AppCard(
        child: Text('A rest day — nothing scheduled. Breathe easy.',
            style: theme.textTheme.bodyMedium),
      );
    }
    final minutes = (session.totalSeconds / 60).ceil();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('${session.type.name} · ~$minutes min',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Start session',
            onPressed: () => _startFlow(context, ref, session),
          ),
        ],
      ),
    );
  }

  /// The M1 session loop: mood check-in + echo → (one-time face-down coach)
  /// → player → reflection → completion moment → Today's done state.
  Future<void> _startFlow(
    BuildContext context,
    WidgetRef ref,
    SessionDef session,
  ) async {
    final checkin = await showMoodCheckin(context, session: session);
    if (checkin == null || !context.mounted) return;

    final playSession = checkin.calibrated.session;
    final events = ref.read(appEventsProvider);
    final prefs = ref.read(preferencesControllerProvider);
    final progress = ref.read(progressControllerProvider);
    final stateBefore = progress.state;
    final moodKeys = [for (final m in checkin.moods) m.name];

    if (moodKeys.isNotEmpty) events.moodCheckin(moodKeys);
    events.sessionStarted(
      playSession.type.name,
      stateBefore.currentWeek,
      stateBefore.currentDay,
    );

    // One-time coach: the cue language, taught once (M1·4a).
    var startInEmber = false;
    if (!prefs.faceDownCoachSeen) {
      final tryIt = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const FaceDownCoachPage(),
        ),
      );
      prefs.markFaceDownCoachSeen();
      startInEmber = tryIt ?? false;
      if (!context.mounted) return;
    }

    // First audio session: earphones prompt, asked once and remembered.
    if (playSession.audioRef != null &&
        !prefs.earphonePromptSeen &&
        prefs.voiceEnabled) {
      final keepVoice = await _earphonePrompt(context);
      prefs.markEarphonePromptSeen();
      if (keepVoice == false) prefs.setVoiceEnabled(false);
      if (!context.mounted) return;
    }

    final startedAt = DateTime.now();
    var completion = 0.0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPlayerPage(
          session: playSession,
          audio: ref.read(sessionAudioFactoryProvider)(),
          haptics: prefs.hapticsEnabled
              ? ref.read(hapticCuesProvider)
              : const NoopHapticCues(),
          hapticsEnabled: prefs.hapticsEnabled,
          voiceEnabled: prefs.voiceEnabled,
          onVoiceChanged: prefs.setVoiceEnabled,
          faceDownSensor: ref.read(faceDownSensorProvider),
          startInEmber: startInEmber,
          onComplete: (pct) {
            completion = pct;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (completion == 0.0 || !context.mounted) return; // abandoned

    final sessionNumber = progress.logs().length + 1;
    final reflection = await Navigator.of(context).push<ReflectionResult>(
      MaterialPageRoute<ReflectionResult>(
        builder: (_) => ReflectionPage(
          sessionTitle: playSession.title,
          sessionNumber: sessionNumber,
        ),
      ),
    );
    if (!context.mounted) return;

    events.sessionCompleted(playSession.type.name, completion);

    // Completing day 7 of week 4/8/12 is the milestone moment.
    final milestone = !progress.isDoneToday &&
        stateBefore.currentDay == 7 &&
        const {4, 8, 12}.contains(stateBefore.currentWeek)
        ? stateBefore.currentWeek
        : null;
    final nthThisWeek = stateBefore.currentDay;

    progress.completeToday(
      SessionLog(
        id: startedAt.microsecondsSinceEpoch.toString(),
        sessionTag: playSession.tag,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        completionPct: completion,
        moodBefore: moodKeys,
        perceivedDifficulty: reflection?.difficulty,
        journalNote: reflection?.note,
      ),
    );

    // Tomorrow's preview from the advanced plan position.
    SessionDef? tomorrow;
    final plan = ref.read(onboardingControllerProvider).plan;
    SessionCatalog? catalog;
    try {
      catalog = ref.read(sessionCatalogProvider);
    } catch (_) {
      catalog = null;
    }
    if (plan != null && catalog != null) {
      tomorrow = todaysSession(
        plan: plan,
        week: progress.state.currentWeek,
        day: progress.state.currentDay,
        catalog: catalog.byTag,
      );
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<CompletionAction>(
      MaterialPageRoute<CompletionAction>(
        builder: (_) => CompletionPage(
          sessionNumber: sessionNumber,
          nthThisWeek: nthThisWeek,
          tomorrowTitle: tomorrow?.title,
          tomorrowMinutes:
              tomorrow == null ? null : (tomorrow.totalSeconds / 60).ceil(),
          milestoneWeek: milestone,
          currentWeek: stateBefore.currentWeek,
        ),
      ),
    );
    // M3 wires `takeCheckin` to the check-in instrument; until then every
    // path lands on Today's done state (the check-in waits indefinitely).
  }

  /// "Voice guidance — best with earphones. You can also mute and follow the
  /// haptics." Ask once, remember (Part K flag 5 — shared-wall reality).
  Future<bool?> _earphonePrompt(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voice guidance', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Best with earphones. You can also mute and follow the haptics.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Keep voice on',
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              AppButton(
                label: 'Mute for now',
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shown on Today when a free user has finished the 4-week Foundation and the
/// plan moves into Pro weeks. Soft — invites, never traps.
class _ProWeekLock extends StatelessWidget {
  const _ProWeekLock({required this.theme, required this.week});

  final ThemeData theme;
  final int week;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Foundation complete', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You finished the 4-week Foundation — real progress. Weeks 5–12, '
            'the rest of the 12-week protocol, are part of Pro.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'See Pro options',
            onPressed: () => showSoftPaywall(context, source: 'today_week_lock'),
          ),
        ],
      ),
    );
  }
}
