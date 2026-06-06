import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/models/session_models.dart';
import '../logic/step_clock.dart';

/// Guided stepper player for a text/timer session. Calls [onComplete] with the
/// completion fraction (1.0) when the last step finishes.
class SessionPlayerPage extends StatefulWidget {
  const SessionPlayerPage({
    super.key,
    required this.session,
    required this.onComplete,
  });

  final SessionDef session;
  final ValueChanged<double> onComplete;

  @override
  State<SessionPlayerPage> createState() => _SessionPlayerPageState();
}

class _SessionPlayerPageState extends State<SessionPlayerPage> {
  late List<int> _durations;
  int _step = 0;
  int _secondsLeft = 0;
  bool _playing = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _durations = widget.session.steps.map((s) => s.seconds).toList();
    _secondsLeft = _durations.isEmpty ? 0 : _durations.first;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_playing) return;
    final t = StepClock.tick(_durations, _step, _secondsLeft);
    if (t.finished) {
      _timer?.cancel();
      widget.onComplete(1.0);
      return;
    }
    setState(() {
      _step = t.step;
      _secondsLeft = t.secondsLeft;
    });
  }

  void _togglePlay() => setState(() => _playing = !_playing);

  void _prevStep() {
    if (_step == 0) return;
    setState(() {
      _step -= 1;
      _secondsLeft = _durations[_step];
    });
  }

  void _nextStep() {
    if (_step >= _durations.length - 1) {
      _timer?.cancel();
      widget.onComplete(1.0);
      return;
    }
    setState(() {
      _step += 1;
      _secondsLeft = _durations[_step];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.session.steps;
    final current = steps.isEmpty
        ? const SessionStep(title: '', seconds: 0, guidance: '')
        : steps[_step];
    final fraction = _durations.isEmpty
        ? 1.0
        : StepClock.fraction(_durations, _step, _secondsLeft);

    return AppScaffold(
      title: widget.session.title,
      leading: const BackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Step ${_step + 1} of ${steps.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.xl),
          AppProgressRing(
            value: fraction,
            size: 200,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_secondsLeft',
                    style: theme.textTheme.displayMedium),
                Text('seconds', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(current.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            current.guidance,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 32,
                onPressed: _step == 0 ? null : _prevStep,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton.filled(
                iconSize: 40,
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                iconSize: 32,
                onPressed: _nextStep,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
