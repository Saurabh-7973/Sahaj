import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/events.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../../me/checkin_controller.dart';
import '../../me/pages/checkin_flow.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../settings/preferences_controller.dart';
import '../../subscription/logic/feature_gate.dart';
import '../../subscription/soft_paywall.dart';
import '../../subscription/subscription_controller.dart';
import '../../sessions/logic/face_down_sensor.dart';
import '../../sessions/logic/haptic_cues.dart';
import '../../sessions/logic/scheduler.dart';
import '../../sessions/logic/session_calibration.dart';
import '../../sessions/pages/completion_page.dart';
import '../../sessions/pages/face_down_coach.dart';
import '../../sessions/pages/mood_checkin_sheet.dart';
import '../../sessions/pages/reflection_page.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
import '../../sessions/session_audio.dart';
import '../../sessions/session_catalog.dart';
import '../logic/today_logic.dart';

/// M2 — Today, the daily front door. One hero; everything else whispers.
/// Today writes nothing: it is a pure read of plan position + logs + clock.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
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

    final now = DateTime.now();
    final state = progress.state;
    final logs = progress.logs();
    final ctx = buildTodayContext(
      hasPlan: plan != null,
      progress: state,
      logs: logs,
      now: now,
    );

    final week = state.currentWeek;
    final phase = plan == null
        ? ''
        : plan.weeks[(week - 1).clamp(0, plan.weeks.length - 1)].phase;

    var session = (plan == null || catalog == null)
        ? null
        : todaysSession(
            plan: plan,
            week: week,
            day: state.currentDay,
            catalog: catalog.byTag,
          );
    // Gap return: the plan restarts a notch gentler (same calibrate-down the
    // heavy mood uses) before the mood sheet ever sees the session.
    if (ctx.kind == TodayKind.gapReturn && session != null) {
      session = calibrateGapReturn(session);
    }

    final weekChip = ctx.kind == TodayKind.gapReturn
        ? 'WK $week · plan adjusted'
        : 'WK $week${phase.isEmpty ? '' : ' · $phase'}';

    final showSteadyTile =
        !hideStreak &&
        ctx.kind != TodayKind.day0 &&
        ctx.kind != TodayKind.empty &&
        logs.isNotEmpty;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        dateEyebrow(now).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eyebrow(
                          lamp.inkMuted.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    if (plan != null) AppChip(label: weekChip),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(greeting(now), style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.lg),
                if (plan == null)
                  _EmptyCard(lamp: lamp, theme: theme)
                else if (isPlanWeekLocked(week, isPro: isPro))
                  _ProWeekLock(theme: theme, week: week)
                else if (ctx.kind == TodayKind.done)
                  _DoneCard(
                    lamp: lamp,
                    theme: theme,
                    tomorrow: _tomorrowSession(plan, state, catalog),
                  )
                else if (session == null)
                  AppCard(
                    child: Text(
                      'A rest day — nothing scheduled. Breathe easy.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  _HeroCard(
                    lamp: lamp,
                    theme: theme,
                    session: session,
                    ctx: ctx,
                    dayN: (week - 1) * 7 + state.currentDay,
                    whyLine: whyLine(ctx, week: week, phase: phase),
                    onStart: () => _startFlow(context, ref, session!),
                  ),
                if (plan != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _WeekCard(lamp: lamp, theme: theme, ctx: ctx, now: now),
                ],
                if (showSteadyTile) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SteadyTile(
                    lamp: lamp,
                    theme: theme,
                    streak: ctx.displayStreak,
                    longest: state.longestStreak,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  SessionDef? _tomorrowSession(
    Plan plan,
    ProgressState state,
    SessionCatalog? catalog,
  ) {
    if (catalog == null) return null;
    // State already advanced by completion — current position IS tomorrow.
    return todaysSession(
      plan: plan,
      week: state.currentWeek,
      day: state.currentDay,
      catalog: catalog.byTag,
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
        MaterialPageRoute<bool>(builder: (_) => const FaceDownCoachPage()),
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
    var holdSeconds = 0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPlayerPage(
          session: playSession,
          onHoldSeconds: (s) => holdSeconds = s,
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

    // Completing day 7 of week 4/8/12 is the milestone moment. A deferred
    // ("Tomorrow") check-in re-surfaces here too — next completion only,
    // never on Today, never via notification (M3 spec §3).
    final checkins = ref.read(checkinControllerProvider);
    final hitMilestone = stateBefore.currentDay == 7 &&
            const {4, 8, 12}.contains(stateBefore.currentWeek) &&
            !checkins.hasCompleted(stateBefore.currentWeek)
        ? stateBefore.currentWeek
        : null;
    final milestone = hitMilestone ?? checkins.pendingWeek;
    final nthThisWeek = stateBefore.currentDay;

    progress.completeToday(
      SessionLog(
        id: startedAt.microsecondsSinceEpoch.toString(),
        sessionTag: playSession.tag,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        completionPct: completion,
        moodBefore: moodKeys,
        holdSeconds: holdSeconds,
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
    final action = await Navigator.of(context).push<CompletionAction>(
      MaterialPageRoute<CompletionAction>(
        builder: (_) => CompletionPage(
          sessionNumber: sessionNumber,
          nthThisWeek: nthThisWeek,
          tomorrowTitle: tomorrow?.title,
          tomorrowMinutes: tomorrow == null
              ? null
              : (tomorrow.totalSeconds / 60).ceil(),
          milestoneWeek: milestone,
          currentWeek: stateBefore.currentWeek,
        ),
      ),
    );

    if (milestone == null || !context.mounted) return;
    switch (action) {
      case CompletionAction.takeCheckin:
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CheckinFlow(week: milestone),
          ),
        );
      case CompletionAction.tomorrow:
        // The check-in waits indefinitely; it re-surfaces at the next
        // completion only (handled by checkins.pendingWeek above).
        checkins.defer(milestone);
      case CompletionAction.finish:
      case null:
        break;
    }
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

// ---- State cards ----

/// The hero — the only element with CTA energy on the whole screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.lamp,
    required this.theme,
    required this.session,
    required this.ctx,
    required this.dayN,
    required this.whyLine,
    required this.onStart,
  });

  final LamplightTokens lamp;
  final ThemeData theme;
  final SessionDef session;
  final TodayContext ctx;
  final int dayN;
  final String whyLine;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final minutes = (session.totalSeconds / 60).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF332915), Color(0xFF251E14)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: lamp.ochre.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            // The lotus watermark, bleeding off the corner like the mock.
            Positioned(
              right: -46,
              bottom: -46,
              child: LotusMark(
                size: 215,
                color: lamp.ochre.withValues(alpha: 0.13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      if (ctx.kind == TodayKind.day0)
                        const AppChip(
                          label: 'first session',
                          variant: AppChipVariant.ok,
                        )
                      else if (ctx.kind == TodayKind.gapReturn)
                        const AppChip(label: 'adjusted')
                      else
                        AppChip(label: 'day $dayN'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    session.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    whyLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 19 / 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Pre-check-in only; never reproaches after a skip.
                  Row(
                    children: [
                      MoodGlyph(
                        mood: ArrivalMood.open,
                        size: 15,
                        color: lamp.sand,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'adjusts to how you arrive',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: lamp.faint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppButton(label: 'Start', height: 52, onPressed: onStart),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Done — the doorway's job inverts: confirm and leave. No CTA energy.
class _DoneCard extends StatelessWidget {
  const _DoneCard({
    required this.lamp,
    required this.theme,
    required this.tomorrow,
  });

  final LamplightTokens lamp;
  final ThemeData theme;
  final SessionDef? tomorrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28301F), Color(0xFF1E2418)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: lamp.moss.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lamp.moss.withValues(alpha: 0.2),
                      lamp.moss.withValues(alpha: 0.07),
                    ],
                  ),
                  border: Border.all(color: lamp.moss.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: lamp.moss.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: LotusMark(
                  size: 30,
                  color: lamp.mossBright,
                  strokeWidth: 5,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Done for today',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rhythm beats intensity — see you tomorrow.',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tomorrow != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppChip(label: 'Tomorrow · ${tomorrow!.title}'),
                AppChip(label: '${(tomorrow!.totalSeconds / 60).ceil()} min'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: 'Free practice in the Library',
            child: InkWell(
              onTap: () => context.go(Routes.library),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Free practice in the Library',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: lamp.mossBright,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '›',
                      style: TextStyle(color: lamp.mossBright, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.lamp,
    required this.theme,
    required this.ctx,
    required this.now,
  });

  final LamplightTokens lamp;
  final ThemeData theme;
  final TodayContext ctx;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tonight = now.hour >= 17;
    final counter = ctx.weekCompletions == 0
        ? 'starts ${tonight ? 'tonight' : 'today'}'
        : '${ctx.weekCompletions} done';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This week', style: theme.textTheme.labelMedium),
              Flexible(
                child: Text(
                  counter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WeekDots(done: ctx.dayDots, todayIndex: now.weekday - 1),
        ],
      ),
    );
  }
}

/// Steady days — agency over shame: hidden = absent, gap = faint honest zero
/// with `longest` kept as the dignity anchor.
class _SteadyTile extends StatelessWidget {
  const _SteadyTile({
    required this.lamp,
    required this.theme,
    required this.streak,
    required this.longest,
  });

  final LamplightTokens lamp;
  final ThemeData theme;
  final int streak;
  final int longest;

  @override
  Widget build(BuildContext context) {
    final zero = streak == 0;
    final medalColor = zero ? lamp.sand : lamp.mossBright;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: zero
                          ? [
                              lamp.sand.withValues(alpha: 0.14),
                              lamp.sand.withValues(alpha: 0.05),
                            ]
                          : [
                              lamp.moss.withValues(alpha: 0.2),
                              lamp.moss.withValues(alpha: 0.07),
                            ],
                    ),
                    border: Border.all(
                      color: (zero ? lamp.sand : lamp.moss).withValues(
                        alpha: zero ? 0.24 : 0.3,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: LotusMark(
                    size: 20,
                    color: medalColor,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Steady days', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Text(
                        'longest $longest',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: lamp.faint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // A single 200ms count-up, nothing more; instant under
          // reduced motion. The zero sits in faint — honest, never red.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: streak.toDouble()),
            duration: reduceMotion ? Duration.zero : AppMotion.quick,
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: AppTypography.numeral(
                36,
                zero ? lamp.faint : lamp.mossBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// True empty — data wiped, no plan. The only state allowed the lamp
/// illustration; day 0 never uses it.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.lamp, required this.theme});

  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          CustomPaint(
            size: const Size(96, 72),
            painter: _LampPainter(line: lamp.sand, glow: lamp.gold),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your plan starts with one session.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Finish onboarding and it appears here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// Calm-contour lamp: shade, stem, base, a quiet glow above.
class _LampPainter extends CustomPainter {
  _LampPainter({required this.line, required this.glow});

  final Color line;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = line;

    // Shade.
    canvas.drawPath(
      Path()
        ..moveTo(p(34, 14).dx, p(34, 14).dy)
        ..lineTo(p(62, 14).dx, p(62, 14).dy)
        ..lineTo(p(70, 34).dx, p(70, 34).dy)
        ..lineTo(p(26, 34).dx, p(26, 34).dy)
        ..close(),
      paint,
    );
    // Stem + base.
    canvas.drawLine(p(48, 34), p(48, 58), paint);
    canvas.drawPath(
      Path()
        ..moveTo(p(34, 64).dx, p(34, 64).dy)
        ..quadraticBezierTo(
          p(48, 56).dx,
          p(48, 56).dy,
          p(62, 64).dx,
          p(62, 64).dy,
        ),
      paint,
    );
    // Glow.
    canvas.drawCircle(
      p(48, 24),
      26 * s,
      Paint()
        ..style = PaintingStyle.fill
        ..color = glow.withValues(alpha: 0.07),
    );
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.line != line || old.glow != glow;
}

String _typeLabel(SessionType type) => switch (type) {
  SessionType.kegel => 'kegel',
  SessionType.reverseKegel => 'reverse kegel',
  SessionType.breathwork => 'breathwork',
  SessionType.sensate => 'sensate',
  SessionType.education => 'learn',
  SessionType.mindset => 'mindset',
};

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
            onPressed: () =>
                showSoftPaywall(context, source: 'today_week_lock'),
          ),
        ],
      ),
    );
  }
}
