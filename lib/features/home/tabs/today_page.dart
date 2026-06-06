import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/events.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../sessions/logic/scheduler.dart';
import '../../sessions/pages/mood_checkin_sheet.dart';
import '../../sessions/pages/reflection_page.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
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
          if (progress.state.streak > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('🔥 ${progress.state.streak}-day streak',
                style: theme.textTheme.labelMedium),
          ],
          const SizedBox(height: AppSpacing.xl),
          _body(context, ref, theme, plan, session, progress),
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
            Text('Come back tomorrow to keep the streak going.',
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

  Future<void> _startFlow(
    BuildContext context,
    WidgetRef ref,
    SessionDef session,
  ) async {
    final moods = await showMoodCheckin(context);
    if (moods == null || !context.mounted) return;

    final events = ref.read(appEventsProvider);
    final progressState = ref.read(progressControllerProvider).state;
    events.moodCheckin(moods);
    events.sessionStarted(
      session.type.name,
      progressState.currentWeek,
      progressState.currentDay,
    );

    final startedAt = DateTime.now();
    var completion = 0.0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPlayerPage(
          session: session,
          onComplete: (pct) {
            completion = pct;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (completion == 0.0 || !context.mounted) return; // abandoned

    final result = await Navigator.of(context).push<ReflectionResult>(
      MaterialPageRoute<ReflectionResult>(
        builder: (_) => ReflectionPage(sessionTitle: session.title),
      ),
    );
    if (result == null || !context.mounted) return;

    events.sessionCompleted(session.type.name, completion);

    ref.read(progressControllerProvider).completeToday(
          SessionLog(
            id: startedAt.microsecondsSinceEpoch.toString(),
            sessionTag: session.tag,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            completionPct: completion,
            moodBefore: moods,
            perceivedDifficulty: result.difficulty,
            journalNote: result.note,
          ),
        );
  }
}
