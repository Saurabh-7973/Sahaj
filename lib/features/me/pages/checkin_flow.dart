import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/baseline_questions.dart';
import '../../onboarding/health_questions.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../onboarding/widgets/selectable_option.dart';
import '../../sessions/progress_controller.dart';
import '../checkin_controller.dart';
import '../logic/dashboard_logic.dart';
import '../widgets/dashboard_widgets.dart';

/// M3·04 — the check-in: intro → questions (C6/C8 template) → result.
/// Entry only via the milestone completion CTA. Pops true when a check-in
/// was completed (so the dashboard can scroll to the check-ins card).
class CheckinFlow extends ConsumerStatefulWidget {
  const CheckinFlow({super.key, required this.week});

  final int week;

  @override
  ConsumerState<CheckinFlow> createState() => _CheckinFlowState();
}

enum _Stage { intro, questions, result }

class _CheckinFlowState extends ConsumerState<CheckinFlow> {
  _Stage _stage = _Stage.intro;
  int _q = 0;
  final _scores = <String, int>{};
  CheckinRecord? _saved;

  List<HealthQuestion> get _battery {
    final track = ref.read(onboardingControllerProvider).track ?? Track.solo;
    return track == Track.partnered ? partneredBaseline : soloBaseline;
  }

  void _answer(int index) {
    _scores[_battery[_q].id] = index;
    if (_q < _battery.length - 1) {
      setState(() => _q++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final record = CheckinRecord(
      week: widget.week,
      scores: Map<String, int>.from(_scores),
      completedAt: DateTime.now(),
    );
    ref.read(checkinControllerProvider).complete(record);
    setState(() {
      _saved = record;
      _stage = _Stage.result;
    });
  }

  void _defer() {
    ref.read(checkinControllerProvider).defer(widget.week);
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.intro => _IntroScreen(
          week: widget.week,
          questionCount: _battery.length,
          onBegin: () => setState(() => _stage = _Stage.questions),
          onDefer: _defer,
        ),
      _Stage.questions => _QuestionScreen(
          question: _battery[_q],
          index: _q,
          total: _battery.length,
          onAnswer: _answer,
          onBack: _q == 0
              ? null
              : () => setState(() => _q--),
        ),
      _Stage.result => _ResultScreen(
          week: widget.week,
          record: _saved!,
          onDone: () => Navigator.of(context).pop(true),
        ),
    };
  }
}

/// M3·04a — intro. The diamond from the spine, made large.
class _IntroScreen extends StatelessWidget {
  const _IntroScreen({
    required this.week,
    required this.questionCount,
    required this.onBegin,
    required this.onDefer,
  });

  final int week;
  final int questionCount;
  final VoidCallback onBegin;
  final VoidCallback onDefer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(child: _DiamondMedallion(lamp: lamp)),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'Week $week check-in',
                    style: AppTypography.eyebrow(
                      lamp.ochre.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Same questions as week 0.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 29),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Two minutes. Answer how it is — not how you hope. '
                  'The comparison only works if both ends are honest.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: lamp.inkMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    const AppChip(label: '2 min'),
                    AppChip(label: '$questionCount questions'),
                    const AppChip(label: 'just you'),
                  ],
                ),
                const Spacer(),
                AppButton(label: 'Begin', onPressed: onBegin),
                AppButton(
                  label: 'Tomorrow',
                  variant: AppButtonVariant.text,
                  onPressed: onDefer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiamondMedallion extends StatelessWidget {
  const _DiamondMedallion({required this.lamp});
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lamp.ochre.withValues(alpha: 0.18),
            lamp.ochre.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(color: lamp.ochre.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(color: lamp.ochre.withValues(alpha: 0.4), blurRadius: 20),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(36, 36),
          painter: _DiamondPainter(color: lamp.gold),
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  _DiamondPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, h * 0.08)
      ..lineTo(w * 0.92, h / 2)
      ..lineTo(w / 2, h * 0.92)
      ..lineTo(w * 0.08, h / 2)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(w / 2, h * 0.32), Offset(w / 2, h * 0.62), p);
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => old.color != color;
}

/// Reuses the onboarding single-question template verbatim (validated-item
/// wording stays identical to week 0).
class _QuestionScreen extends StatelessWidget {
  const _QuestionScreen({
    required this.question,
    required this.index,
    required this.total,
    required this.onAnswer,
    required this.onBack,
  });

  final HealthQuestion question;
  final int index;
  final int total;
  final ValueChanged<int> onAnswer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        icon: Icon(Icons.chevron_left, color: lamp.inkMuted),
                      )
                    else
                      const SizedBox(height: 48),
                    Expanded(child: _StepDots(index: index, total: total, lamp: lamp)),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(question.prompt, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xl),
                for (var i = 0; i < question.options.length; i++)
                  SelectableOption(
                    label: question.options[i],
                    selected: false,
                    onTap: () => onAnswer(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index, required this.total, required this.lamp});
  final int index;
  final int total;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: i == index ? 19 : 6.5,
            height: 6.5,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == index
                  ? lamp.gold
                  : i < index
                      ? lamp.ochre.withValues(alpha: 0.5)
                      : lamp.sand.withValues(alpha: 0.18),
            ),
          ),
      ],
    );
  }
}

/// M3·04b — the result. Deep background: a ceremony, like completion.
class _ResultScreen extends ConsumerWidget {
  const _ResultScreen({
    required this.week,
    required this.record,
    required this.onDone,
  });

  final int week;
  final CheckinRecord record;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final onboarding = ref.read(onboardingControllerProvider);
    final logs = ref.read(progressControllerProvider).logs();

    final series = buildCheckinSeries(
      baselineRaw: onboarding.baselineRaw,
      track: onboarding.track ?? Track.solo,
      records: ref.read(checkinControllerProvider).records,
    );
    final recap = inputRecap(
      logs: logs,
      sinceWeek: 0,
      week: week,
      now: DateTime.now(),
    );

    return Scaffold(
      body: LampBackground(
        room: LampRoom.deep,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            'Week $week · measured',
                            style: AppTypography.eyebrow(
                              lamp.ochre.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DashCard(
                          warm: true,
                          child: CheckinChart(series: series, enlarged: true),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DashCard(
                          child: Column(
                            children: [
                              for (final d in series.deltas)
                                _DomainRow(delta: d, lamp: lamp, theme: theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InputRecapCard(recap: recap, lamp: lamp, theme: theme),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: Text(
                            'Small movements, really measured — on your own week-0 scale.',
                            textAlign: TextAlign.center,
                            style: AppTypography.italic(12.5, lamp.sand),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Done', onPressed: onDone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.delta, required this.lamp, required this.theme});

  final DomainDelta delta;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final value = delta.delta ?? 0;
    final up = delta.up;
    final label = up
        ? '+$value ▲'
        : delta.flat
            ? '—'
            : '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delta.label,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                if (!up) ...[
                  const SizedBox(height: 6),
                  Text(verdictLine(delta),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: lamp.faint)),
                ],
              ],
            ),
          ),
          Text(
            label,
            style: AppTypography.numeral(19, up ? lamp.gold : lamp.faint),
          ),
        ],
      ),
    );
  }
}

class _InputRecapCard extends StatelessWidget {
  const _InputRecapCard({
    required this.recap,
    required this.lamp,
    required this.theme,
  });

  final InputRecap recap;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28301F), Color(0xFF1E2418)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lamp.moss.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you put in',
            style: theme.textTheme.labelMedium?.copyWith(color: lamp.mossBright),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(label: '${recap.sessions} sessions', variant: AppChipVariant.ok),
              AppChip(label: '${recap.minutes} minutes', variant: AppChipVariant.ok),
              AppChip(
                label: '${recap.activeDays} of ${recap.windowDays} days',
                variant: AppChipVariant.ok,
              ),
            ],
          ),
          const SourceTag('from your logs'),
        ],
      ),
    );
  }
}
