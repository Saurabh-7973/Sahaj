import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/audio_resolver.dart';
import '../logic/face_down_sensor.dart';
import '../logic/haptic_cues.dart';
import '../logic/models/session_models.dart';
import '../logic/player_phases.dart';
import '../logic/step_clock.dart';
import '../session_audio.dart';

/// M1·3/·4 — the session player. The external feedback loop for an invisible
/// muscle: pace me, correct my form, don't expose me.
///
/// The deep room: the ring is the brightest object on screen. Semantic
/// layering — step bar = the session · "Hold 3 of 5" = the set · the ring =
/// this rep. The ring numeral counts the phase's own seconds, never clock
/// time; session time lives in the tiny `4:20 LEFT` line and nowhere else.
class SessionPlayerPage extends StatefulWidget {
  const SessionPlayerPage({
    super.key,
    required this.session,
    required this.onComplete,
    this.onHoldSeconds,
    this.audio = const NoopSessionAudio(),
    this.locale = 'en',
    this.haptics = const NoopHapticCues(),
    this.hapticsEnabled = true,
    this.voiceEnabled = true,
    this.onVoiceChanged,
    this.faceDownSensor = const NoopFaceDownSensor(),
    this.startInEmber = false,
  });

  final SessionDef session;
  final ValueChanged<double> onComplete;

  /// Total squeeze-phase seconds, reported alongside completion (volume
  /// metric per M1 spec §3 — never surfaced as judgment).
  final ValueChanged<int>? onHoldSeconds;

  final SessionAudio audio;
  final String locale;
  final HapticCueEngine haptics;
  final bool hapticsEnabled;

  /// Initial speaker-toggle state; persisted by the caller via
  /// [onVoiceChanged] (ask once, remember).
  final bool voiceEnabled;
  final ValueChanged<bool>? onVoiceChanged;

  final FaceDownSensor faceDownSensor;

  /// Entering straight from the face-down coach ("Try it face-down").
  final bool startInEmber;

  @override
  State<SessionPlayerPage> createState() => _SessionPlayerPageState();
}

class _SessionPlayerPageState extends State<SessionPlayerPage>
    with WidgetsBindingObserver {
  late List<int> _durations;
  int _step = 0;
  int _secondsLeft = 0;
  int _holdSeconds = 0;
  bool _playing = true;
  bool _ember = false;
  late bool _voiceOn;
  Timer? _timer;
  ResolvedAudio? _audioSource;
  StreamSubscription<bool>? _faceDown;
  PlayerPhase? _lastPhase;

  SessionStep get _current => widget.session.steps.isEmpty
      ? const SessionStep(title: '', seconds: 0, guidance: '')
      : widget.session.steps[_step];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceOn = widget.voiceEnabled;
    _ember = widget.startInEmber;
    _durations = widget.session.steps.map((s) => s.seconds).toList();
    _secondsLeft = _durations.isEmpty ? 0 : _durations.first;
    _audioSource = resolveAudio(widget.session, widget.locale);
    if (_audioSource != null && _voiceOn) unawaited(_startAudio());
    _faceDown = widget.faceDownSensor.faceDown.listen((down) {
      if (mounted) setState(() => _ember = down);
    });
    // Keep-awake for the whole session; brightness never flashes.
    unawaited(WakelockPlus.enable().catchError((_) {}));
    if (widget.hapticsEnabled && _playing) {
      final snap = phaseAt(_current, _secondsLeft);
      _lastPhase = snap.phase;
      if (snap.phase == PlayerPhase.squeeze) {
        unawaited(widget.haptics.squeeze());
      }
    }
    _startTimer();
  }

  Future<void> _startAudio() async {
    // Guarded so a bad ref degrades to text+timer, never a crashed session.
    try {
      await widget.audio.load(_audioSource!);
      if (mounted && _playing && _voiceOn) await widget.audio.play();
    } catch (_) {
      _audioSource = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_playing) return;
    // The second that just elapsed: was it a squeeze?
    if (phaseAt(_current, _secondsLeft).phase == PlayerPhase.squeeze) {
      _holdSeconds++;
    }
    final prevStep = _step;
    final t = StepClock.tick(_durations, _step, _secondsLeft);
    if (t.finished) {
      _timer?.cancel();
      if (widget.hapticsEnabled) unawaited(widget.haptics.sessionDone());
      widget.onHoldSeconds?.call(_holdSeconds);
      widget.onComplete(1.0);
      return;
    }
    setState(() {
      _step = t.step;
      _secondsLeft = t.secondsLeft;
    });
    _fireCues(stepChanged: t.step != prevStep);
  }

  /// The cue language: 1 tick = squeeze, 2 = release, long = phase change.
  void _fireCues({required bool stepChanged}) {
    if (!widget.hapticsEnabled) return;
    final snap = phaseAt(_current, _secondsLeft);
    if (stepChanged) {
      unawaited(widget.haptics.phaseChange());
    } else if (snap.phase != _lastPhase) {
      if (snap.phase == PlayerPhase.squeeze) {
        unawaited(widget.haptics.squeeze());
      } else if (_lastPhase == PlayerPhase.squeeze &&
          snap.phase == PlayerPhase.release) {
        unawaited(widget.haptics.release());
      }
    }
    _lastPhase = snap.phase;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Interruption (call/lock): pause where we stand; never auto-resume.
    if (state != AppLifecycleState.resumed && _playing) {
      _setPlaying(false);
    }
  }

  void _setPlaying(bool playing) {
    if (!mounted) {
      _playing = playing;
      return;
    }
    setState(() => _playing = playing);
    if (_audioSource != null) {
      unawaited(
        playing && _voiceOn ? widget.audio.play() : widget.audio.pause(),
      );
    }
  }

  void _toggleVoice() {
    setState(() => _voiceOn = !_voiceOn);
    widget.onVoiceChanged?.call(_voiceOn);
    if (_audioSource != null) {
      // Muting never breaks pacing — the ring and haptics carry it.
      unawaited(_voiceOn && _playing ? widget.audio.play() : widget.audio.pause());
    }
  }

  void _prevStep() {
    if (_step == 0) return;
    setState(() {
      _step -= 1;
      _secondsLeft = _durations[_step];
      _lastPhase = null;
    });
  }

  void _nextStep() {
    if (_step >= _durations.length - 1) {
      _timer?.cancel();
      if (widget.hapticsEnabled) unawaited(widget.haptics.sessionDone());
      widget.onHoldSeconds?.call(_holdSeconds);
      widget.onComplete(1.0);
      return;
    }
    setState(() {
      _step += 1;
      _secondsLeft = _durations[_step];
      _lastPhase = null;
    });
  }

  int get _sessionSecondsLeft {
    var total = _secondsLeft;
    for (var i = _step + 1; i < _durations.length; i++) {
      total += _durations[i];
    }
    return total;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _faceDown?.cancel();
    unawaited(WakelockPlus.disable().catchError((_) {}));
    if (_audioSource != null) unawaited(widget.audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;

    return Scaffold(
      body: LampBackground(
        room: _ember ? LampRoom.ember : LampRoom.deep,
        grain: !_ember,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: AppMotion.settle,
            child: _ember ? _buildEmber(lamp) : _buildPlayer(lamp),
          ),
        ),
      ),
    );
  }

  // ---- Ember (M1·4b): a 12px ember, a 7% arc, nothing else. ----

  Widget _buildEmber(LamplightTokens lamp) {
    final progress = widget.session.totalSeconds == 0
        ? 0.0
        : 1 - _sessionSecondsLeft / widget.session.totalSeconds;

    return GestureDetector(
      key: const ValueKey('ember'),
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => setState(() => _ember = false),
      child: Semantics(
        label: 'Face-down mode. Double-tap to wake.',
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(140),
                    painter: _EmberArcPainter(
                      progress: progress,
                      color: lamp.ochre,
                    ),
                  ),
                  _EmberDot(color: lamp.gold),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Opacity(
                opacity: 0.32,
                child: Text(
                  'double-tap to wake',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- The live player. ----

  Widget _buildPlayer(LamplightTokens lamp) {
    final theme = Theme.of(context);
    final step = _current;
    final snap = phaseAt(step, _secondsLeft);
    final isBreathSession = widget.session.type == SessionType.breathwork;
    final accent = sessionTypeTint(lamp, widget.session.type.name);

    final dim = _playing ? 1.0 : AppMotion.dimmedOpacity;

    return Stack(
      key: const ValueKey('player'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: Column(
            children: [
              AnimatedOpacity(
                duration: AppMotion.quick,
                opacity: dim,
                child: Column(
                  children: [
                    Text(
                      widget.session.title,
                      style: AppTypography.eyebrow(
                        lamp.inkMuted.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _setLine(snap, step),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _StepSegmentBar(
                        count: widget.session.steps.length,
                        active: _step,
                        accent: isBreathSession ? lamp.moss : lamp.ochre,
                        lamp: lamp,
                      ),
                    ),
                    if (_playing) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _timeLeftLine(snap),
                        style: AppTypography.timeLeft(lamp.faint),
                        semanticsLabel:
                            '${formatTimeLeft(_sessionSecondsLeft)} left',
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRing(lamp, snap, step, accent),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: AnimatedSwitcher(
                        duration: AppMotion.settle,
                        child: Text(
                          _playing
                              ? guidanceFor(step, snap.phase)
                              : 'Paused — take your time.',
                          key: ValueKey(
                            _playing
                                ? '${_step}_${snap.phase}'
                                : 'paused',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 18.5,
                            height: 27 / 18.5,
                          ),
                        ),
                      ),
                    ),
                    if (!_playing) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'It picks up exactly here.',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: lamp.faint),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SideControl(
                    icon: Icons.chevron_left,
                    label: 'Previous step',
                    enabled: _step > 0,
                    dimmed: !_playing,
                    onTap: _prevStep,
                    lamp: lamp,
                  ),
                  const SizedBox(width: 30),
                  _PlayPauseButton(
                    playing: _playing,
                    breath: isBreathSession,
                    lamp: lamp,
                    onTap: () => _setPlaying(!_playing),
                  ),
                  const SizedBox(width: 30),
                  _SideControl(
                    icon: Icons.chevron_right,
                    label: 'Next step',
                    enabled: true,
                    dimmed: !_playing,
                    onTap: _nextStep,
                    lamp: lamp,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (_playing) ...[
                    AppChip(
                      label: widget.hapticsEnabled
                          ? 'haptics on'
                          : 'haptics off',
                      variant: widget.hapticsEnabled
                          ? AppChipVariant.ok
                          : AppChipVariant.neutral,
                    ),
                    AppChip(
                      label: _voiceOn && _audioSource != null
                          ? 'voice on'
                          : 'voice off',
                      variant: _voiceOn && _audioSource != null
                          ? AppChipVariant.ok
                          : AppChipVariant.neutral,
                    ),
                  ] else
                    Opacity(
                      opacity: 0.6,
                      child: AppChip(
                        label: widget.hapticsEnabled
                            ? 'haptics paused'
                            : 'haptics off',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Audio toggle, top-right, 38dp (state persists via onVoiceChanged).
        Positioned(
          top: 8,
          right: 22,
          child: Semantics(
            button: true,
            label: _voiceOn ? 'Turn voice guidance off' : 'Turn voice guidance on',
            child: InkWell(
              onTap: _toggleVoice,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: lamp.ink.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: lamp.hairline),
                ),
                child: Icon(
                  _voiceOn ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                  size: 17,
                  color: _voiceOn ? lamp.mossBright : lamp.inkMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _setLine(PhaseSnapshot snap, SessionStep step) {
    if (step.pattern is HoldReleasePattern) {
      return 'Hold ${snap.rep} of ${snap.repsTotal}';
    }
    if (step.pattern is BreathPattern) {
      return 'Breath · Round ${snap.rep} of ${snap.repsTotal}';
    }
    return step.title;
  }

  /// `4:20 LEFT · YOU CAN STOP ANY TIME` — the reassurance clause rides on
  /// the first two holds only, then drops (decision #14: tone pending one
  /// real-user read; cut there if it reads as permission-seeking).
  String _timeLeftLine(PhaseSnapshot snap) {
    final base = '${formatTimeLeft(_sessionSecondsLeft)} LEFT';
    final firstPatterned = widget.session.steps
        .indexWhere((s) => s.pattern is HoldReleasePattern);
    if (firstPatterned == _step && snap.rep >= 1 && snap.rep <= 2) {
      return '$base · YOU CAN STOP ANY TIME';
    }
    return base;
  }

  Widget _buildRing(
    LamplightTokens lamp,
    PhaseSnapshot snap,
    SessionStep step,
    Color accent,
  ) {
    final pattern = step.pattern;
    final theme = Theme.of(context);

    // TalkBack announces phase + seconds ("Squeeze, six seconds").
    final semantics = !_playing
        ? 'Paused'
        : pattern is BreathPattern
            ? '${snap.phase.word}, ${snap.phaseSecondsTotal} seconds'
            : pattern is HoldReleasePattern
                ? '${snap.phase.word}, ${snap.phaseSecondsLeft} seconds'
                : '${snap.phaseSecondsLeft} seconds remaining';

    if (pattern is BreathPattern && _playing) {
      return AppProgressRing(
        value: 1,
        mode: RingMode.breath,
        size: 272,
        tint: lamp.moss,
        breathPeriod: Duration(seconds: pattern.cycleSeconds),
        semanticsLabel: semantics,
        center: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                snap.phase.word,
                style: AppTypography.italic(35, const Color(0xFFCDE0C2)),
              ),
              if (snap.phaseSecondsTotal > 1) ...[
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(
                  child: Text(
                    [
                      for (var i = 2; i <= snap.phaseSecondsTotal; i++) '$i'
                    ].join(' · '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(letterSpacing: 3.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final isSqueeze = snap.phase == PlayerPhase.squeeze;
    final value = pattern is HoldReleasePattern
        ? (isSqueeze ? snap.phaseProgress : 1 - snap.phaseProgress)
        : (step.seconds == 0 ? 1.0 : _secondsLeft / step.seconds);
    final phaseColor = !_playing
        ? lamp.inkMuted
        : pattern is HoldReleasePattern
            ? (isSqueeze ? accent : lamp.sand)
            : accent;

    return AppProgressRing(
      value: value,
      mode: pattern is HoldReleasePattern
          ? RingMode.holdPulse
          : RingMode.countdown,
      size: 272,
      tint: phaseColor,
      glow: _playing && (pattern is! HoldReleasePattern || isSqueeze),
      dimmed: !_playing,
      animationDuration: const Duration(seconds: 1),
      semanticsLabel: semantics,
      center: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (!_playing ? 'Paused' : snap.phase.word).toUpperCase(),
              style: AppTypography.phase(
                !_playing
                    ? lamp.inkMuted
                    : isSqueeze || pattern == null
                        ? lamp.inkMuted
                        : lamp.sand,
              ),
            ),
            if (_playing) ...[
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: Text(
                  '${snap.phaseSecondsLeft}',
                  style: AppTypography.numeral(
                    74,
                    pattern is HoldReleasePattern && !isSqueeze
                        ? lamp.sand
                        : lamp.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- Pieces ----

class _StepSegmentBar extends StatelessWidget {
  const _StepSegmentBar({
    required this.count,
    required this.active,
    required this.accent,
    required this.lamp,
  });

  final int count;
  final int active;
  final Color accent;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${active + 1} of $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == count - 1 ? 0 : 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < active
                      ? accent.withValues(alpha: 0.5)
                      : i > active
                          ? lamp.sand.withValues(alpha: 0.14)
                          : null,
                  gradient: i == active
                      ? LinearGradient(colors: [
                          HSLColor.fromColor(accent)
                              .withLightness(
                                  (HSLColor.fromColor(accent).lightness + 0.1)
                                      .clamp(0.0, 1.0))
                              .toColor(),
                          accent,
                        ])
                      : null,
                  boxShadow: i == active
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideControl extends StatelessWidget {
  const _SideControl({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.dimmed,
    required this.onTap,
    required this.lamp,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool dimmed;
  final VoidCallback onTap;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.quick,
      opacity: dimmed ? AppMotion.dimmedOpacity : (enabled ? 1 : 0.4),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lamp.ink.withValues(alpha: 0.05),
              border: Border.all(color: lamp.hairline),
            ),
            child: Icon(icon, size: 22, color: lamp.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.breath,
    required this.lamp,
    required this.onTap,
  });

  final bool playing;
  final bool breath;
  final LamplightTokens lamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = breath
        ? const [Color(0xFF9CB48E), Color(0xFF71895F)]
        : [lamp.gold, const Color(0xFFBA8030)];
    final fg = breath ? const Color(0xFF16200F) : lamp.onOchre;
    final glow = (breath ? lamp.moss : lamp.ochre).withValues(alpha: 0.6);

    return Semantics(
      button: true,
      label: playing ? 'Pause' : 'Resume',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: 40,
                spreadRadius: -14,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: playing ? 28 : 34,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _EmberDot extends StatefulWidget {
  const _EmberDot({required this.color});

  final Color color;

  @override
  State<_EmberDot> createState() => _EmberDotState();
}

/// 12px ember on a 4s pulse — presence, not pacing. Reduced motion: static.
class _EmberDotState extends State<_EmberDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = still ? 1.0 : Curves.easeInOut.transform(_pulse.value);
        return Opacity(
          opacity: 0.55 + 0.45 * t,
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.85),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The only session readout on Ember: a 7%-opacity arc.
class _EmberArcPainter extends CustomPainter {
  _EmberArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 7,
    );
    canvas.drawArc(
      rect,
      -1.5708,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.07),
    );
    canvas.drawArc(
      rect,
      -1.5708,
      6.2832 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(_EmberArcPainter old) =>
      old.progress != progress || old.color != color;
}
