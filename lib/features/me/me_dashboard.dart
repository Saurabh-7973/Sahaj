import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import '../settings/preferences_controller.dart';
import 'checkin_controller.dart';
import 'logic/dashboard_logic.dart';
import 'logic/progress_metrics.dart';
import 'widgets/dashboard_widgets.dart';

/// M3 — the progress dashboard. The honesty system: every chart is source-
/// tagged, nothing is projected, the dashboard is 100% free. Cards earn
/// existence (growth rule); the one reorder the tab ever does is moving
/// check-ins above volume once outcome data exists.
class ProgressDashboard extends ConsumerWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final c = ref.watch(progressControllerProvider);
    final onboarding = ref.watch(onboardingControllerProvider);
    final checkins = ref.watch(checkinControllerProvider);
    final hideStreak = ref.watch(preferencesControllerProvider).hideStreak;

    final plan = onboarding.plan;
    final week = c.state.currentWeek;
    final phase = (plan == null || plan.weeks.isEmpty)
        ? ''
        : plan.weeks[(week - 1).clamp(0, plan.weeks.length - 1)].phase;
    final now = DateTime.now();
    final logs = c.logs();

    final m = computeMetrics(
      logs: logs,
      progress: c.state,
      phase: phase,
      now: now,
    );

    final series = buildCheckinSeries(
      baselineRaw: onboarding.baselineRaw,
      track: onboarding.track ?? Track.solo,
      records: checkins.records,
    );
    final hasData = m.hasData;
    final grid = consistencyGrid(logs: logs, now: now);
    final volume = weeklyVolume(logs: logs, now: now);

    // Card order: spine → stats → consistency → volume → check-ins, EXCEPT
    // once outcome data exists, check-ins moves above volume.
    final checkinCard = _CheckinCard(series: series, lamp: lamp, theme: theme);
    final volumeCard = hasData
        ? _ChartCard(
            title: 'Practice volume',
            kicker: 'MIN + HOLD-SECONDS',
            source: 'from your sessions',
            child: VolumeBars(values: volume),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spine — always (a plan exists).
        DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JourneySpine(currentWeek: week),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _PhaseLabel(
                        'Foundation', week > 4, week <= 4, lamp,
                        align: TextAlign.left),
                  ),
                  Expanded(
                    child: _PhaseLabel('Integration', week > 8,
                        week > 4 && week <= 8, lamp,
                        align: TextAlign.center),
                  ),
                  Expanded(
                    child: _PhaseLabel('Mastery', false, week > 8, lamp,
                        align: TextAlign.right),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_spineCaption(week, series), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (hasData) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatTile(value: m.totalSessions, label: 'Sessions'),
              const SizedBox(width: AppSpacing.sm),
              if (!hideStreak)
                StatTile(
                    value: m.currentStreak, label: 'Steady days', moss: true),
              if (!hideStreak) const SizedBox(width: AppSpacing.sm),
              StatTile(value: m.longestStreak, label: 'Longest'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            title: 'Consistency',
            kicker: _gridKicker(grid.length),
            source: 'from your session logs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConsistencyGrid(grid: grid),
                if (grid.length == 1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A new row grows here each week — four, then it slides.',
                    style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint),
                  ),
                ],
              ],
            ),
          ),
        ],
        // The reorder: check-ins above volume once a comparison exists.
        if (series.hasComparison) ...[
          const SizedBox(height: AppSpacing.md),
          checkinCard,
          if (volumeCard != null) ...[
            const SizedBox(height: AppSpacing.md),
            volumeCard,
          ],
        ] else ...[
          if (volumeCard != null) ...[
            const SizedBox(height: AppSpacing.md),
            volumeCard,
          ],
          const SizedBox(height: AppSpacing.md),
          checkinCard,
        ],
        // Honesty footer — every dashboard state.
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            'We never estimate. Every number here is something you did or told us.',
            textAlign: TextAlign.center,
            style: AppTypography.italic(12.5, lamp.sand),
          ),
        ),
      ],
    );
  }

  String _spineCaption(int week, CheckinSeries series) {
    if (week <= 1) return 'Week 1 · your week-0 mark is set';
    if (series.hasComparison) {
      final phase = week <= 4
          ? 'Foundation'
          : week <= 8
              ? 'stop-start work'
              : 'Mastery';
      return 'Week $week · $phase';
    }
    final toCheckin = week < 4
        ? 4 - week
        : week < 8
            ? 8 - week
            : 12 - week;
    final unit = toCheckin == 1 ? 'week' : 'weeks';
    return 'Week $week · first check-in in $toCheckin $unit';
  }

  String _gridKicker(int rows) => switch (rows) {
        1 => 'THIS WEEK',
        _ => 'LAST $rows WEEKS',
      };
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel(
    this.name,
    this.done,
    this.current,
    this.lamp, {
    this.align = TextAlign.center,
  });

  final String name;
  final bool done;
  final bool current;
  final LamplightTokens lamp;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      done ? '$name ✓' : name.toUpperCase(),
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppTypography.body,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: current ? lamp.gold : lamp.faint,
      ),
    );
  }
}

/// A titled chart card (label + kicker + child + source tag).
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.kicker,
    required this.source,
    required this.child,
  });

  final String title;
  final String kicker;
  final String source;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: CardKicker(kicker)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
          SourceTag(source),
        ],
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({
    required this.series,
    required this.lamp,
    required this.theme,
  });

  final CheckinSeries series;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final caption = series.hasComparison
        ? deltaCaption(series)
        : series.points.length <= 1
            ? 'Your week-4 check-in unlocks the first comparison — measured, not guessed.'
            : null;

    return DashCard(
      warm: series.hasComparison,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Check-ins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium),
              ),
              if (series.hasComparison)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: lamp.moss.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: lamp.moss.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'first comparison',
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: lamp.mossBright,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckinChart(series: series),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint),
            ),
          ],
          const SourceTag('from your check-ins'),
        ],
      ),
    );
  }
}
