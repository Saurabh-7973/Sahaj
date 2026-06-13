import 'package:flutter/material.dart';

import '../../core/theme/app_background.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'lock_controller.dart';

/// M6·02 — the PIN pad. Mark + dots + 76dp keys; nothing readable over a
/// shoulder. On a wrong PIN: dots flash turmeric + 200ms shake (flash only
/// under reduced motion) + "Try again". No red, no countdown.
///
/// [onComplete] is called with the entered PIN; return true to accept (clears),
/// false to reject (shows the wrong-PIN ceremony).
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onComplete,
    this.onUseFingerprint,
    this.onForgot,
    this.title,
  });

  final Future<bool> Function(String pin) onComplete;
  final VoidCallback? onUseFingerprint;
  final VoidCallback? onForgot;

  /// Optional line above the dots (e.g. "Set a PIN" / "Confirm it").
  final String? title;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _entry = '';
  bool _error = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _press(int digit) async {
    if (_entry.length >= kPinLength) return;
    setState(() {
      _error = false;
      _entry += '$digit';
    });
    if (_entry.length == kPinLength) {
      final ok = await widget.onComplete(_entry);
      if (!mounted) return;
      if (ok) {
        setState(() => _entry = '');
      } else {
        setState(() => _error = true);
        if (!MediaQuery.disableAnimationsOf(context)) {
          _shake.forward(from: 0);
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() => _entry = '');
      }
    }
  }

  void _backspace() {
    if (_entry.isEmpty) return;
    setState(() {
      _error = false;
      _entry = _entry.substring(0, _entry.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            child: Column(
              children: [
                const SizedBox(height: 16),
                LotusMark(size: 44, color: lamp.gold, strokeWidth: 3),
                const SizedBox(height: 24),
                if (widget.title != null) ...[
                  Text(widget.title!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 14),
                ],
                _Dots(
                  count: _entry.length,
                  error: _error,
                  shake: _shake,
                  lamp: lamp,
                ),
                if (_error) ...[
                  const SizedBox(height: 10),
                  Text('Try again',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: lamp.turmeric)),
                ],
                const Spacer(),
                _Keypad(onDigit: _press, onBackspace: _backspace, lamp: lamp),
                const Spacer(),
                if (widget.onUseFingerprint != null)
                  AppButton(
                    label: 'Use fingerprint',
                    variant: AppButtonVariant.text,
                    onPressed: widget.onUseFingerprint,
                  ),
                if (widget.onForgot != null)
                  AppButton(
                    label: 'Forgot PIN',
                    variant: AppButtonVariant.text,
                    onPressed: widget.onForgot,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-step PIN setup: choose, then confirm. Pops the chosen PIN on success
/// (or null if cancelled). On mismatch, restarts with the wrong-PIN ceremony.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _first;

  @override
  Widget build(BuildContext context) {
    return PinPad(
      title: _first == null ? 'Choose a PIN' : 'Confirm your PIN',
      onComplete: (pin) async {
        if (_first == null) {
          setState(() => _first = pin);
          return true; // accept the first entry, move to confirm
        }
        if (pin == _first) {
          Navigator.of(context).pop(pin);
          return true;
        }
        setState(() => _first = null); // mismatch → start over
        return false;
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.error,
    required this.shake,
    required this.lamp,
  });

  final int count;
  final bool error;
  final AnimationController shake;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      label: '$count of $kPinLength digits entered',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kPinLength; i++)
              Container(
                width: 13,
                height: 13,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: error
                      ? Colors.transparent
                      : i < count
                          ? lamp.sand
                          : Colors.transparent,
                  border: Border.all(
                    color: error
                        ? lamp.turmeric
                        : i < count
                            ? lamp.sand
                            : lamp.sand.withValues(alpha: 0.35),
                    width: error ? 2 : 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        final dx = shake.isAnimating
            ? 8 *
                (1 - shake.value) *
                ((shake.value * 8).floor().isEven ? 1 : -1)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: row,
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.lamp,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in r) _Key(digit: d, onTap: onDigit, lamp: lamp)],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 76 + 32),
            _Key(digit: 0, onTap: onDigit, lamp: lamp),
            _BackspaceKey(onTap: onBackspace, lamp: lamp),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.digit, required this.onTap, required this.lamp});
  final int digit;
  final ValueChanged<int> onTap;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Semantics(
        button: true,
        label: '$digit',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onTap(digit),
          customBorder: const CircleBorder(),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lamp.ink.withValues(alpha: 0.04),
              border: Border.all(color: lamp.hairline),
            ),
            alignment: Alignment.center,
            child: Text('$digit',
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                  color: lamp.ink,
                )),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({required this.onTap, required this.lamp});
  final VoidCallback onTap;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Semantics(
        button: true,
        label: 'Delete',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Icon(Icons.backspace_outlined, size: 22, color: lamp.inkMuted),
          ),
        ),
      ),
    );
  }
}
