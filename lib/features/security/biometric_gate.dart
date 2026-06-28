import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/analytics/events.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/widgets.dart';
import '../me/checkin_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import '../settings/account.dart';
import '../settings/erase_confirm_screen.dart';
import '../settings/launcher_disguise.dart';
import '../settings/preferences_controller.dart';
import '../subscription/subscription_controller.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';

/// G2 / `24` — the gate. Mark + sensor only: no app name, no purpose (it may
/// be glimpsed). Biometric auto-fires; "Use PIN" falls back to the pad when a
/// PIN is set. Forgot PIN routes to the erase confirm (no recovery — local-
/// first means wipe-and-restart is the honest path).
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child, this.onForgotPin});
  final Widget child;

  /// Opens the erase-confirm flow (settings wires it to the real wipe).
  final VoidCallback? onForgotPin;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checked = false;
  bool _showPin = false;
  bool _showErase = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAuth());
  }

  Future<void> _maybeAuth() async {
    final locked = ref.read(onboardingControllerProvider).biometricLock;
    if (!locked) {
      _open();
      return;
    }
    bool supported;
    try {
      supported = await _auth.isDeviceSupported();
    } catch (_) {
      supported = false;
    }
    if (!supported) {
      // No biometrics/passcode: fall back to PIN if set, else fail open so the
      // user is never locked out of their own data.
      if (ref.read(lockControllerProvider).hasPin) {
        setState(() {
          _showPin = true;
          _checked = true;
        });
      } else {
        _open();
      }
      return;
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (ok) {
        _open();
      } else {
        setState(() => _checked = true);
      }
    } catch (_) {
      setState(() => _checked = true);
    }
  }

  void _open() => setState(() {
        _unlocked = true;
        _checked = true;
      });

  /// Last-resort recovery from the lock screen: a user who can neither pass
  /// biometrics nor recall their PIN would otherwise be sealed out of their own
  /// local data forever (no cloud copy to restore from). Wipe-and-restart is
  /// the honest path — the same erase the settings screen runs — after which we
  /// drop the gate and let the router redirect to onboarding.
  void _eraseEverything() {
    ref.read(appEventsProvider).accountDeleted();
    wipeAllData(
      onboarding: ref.read(onboardingControllerProvider),
      progress: ref.read(progressControllerProvider),
      preferences: ref.read(preferencesControllerProvider),
      subscription: ref.read(subscriptionControllerProvider),
      checkins: ref.read(checkinControllerProvider),
    );
    ref.read(lockControllerProvider).clearPin();
    ref.read(launcherDisguiseProvider).setDisguise(false);
    setState(() => _showErase = false);
    _open();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    if (_showErase) {
      // The gate sits above the app's router, so there's no ambient Navigator
      // for EraseConfirmScreen to pop against. Host it in a tiny local one with
      // an invisible base page beneath: "Keep my data" / back pops the confirm
      // off, which fires onDidRemovePage and returns us to the PIN pad.
      return Navigator(
        onDidRemovePage: (_) => setState(() {
          _showErase = false;
          _showPin = true;
        }),
        pages: [
          const MaterialPage<void>(child: SizedBox.shrink()),
          MaterialPage<void>(
            child: EraseConfirmScreen(onErase: _eraseEverything),
          ),
        ],
      );
    }

    if (_showPin) {
      final lock = ref.read(lockControllerProvider);
      return PinPad(
        onComplete: (pin) async {
          final ok = await lock.verify(pin);
          if (ok) _open();
          return ok;
        },
        onUseFingerprint:
            ref.read(onboardingControllerProvider).biometricLock
                ? () {
                    setState(() => _showPin = false);
                    _maybeAuth();
                  }
                : null,
        onForgot: widget.onForgotPin ??
            () => setState(() {
                  _showPin = false;
                  _showErase = true;
                }),
      );
    }

    // Biometric gate face (mark + sensor).
    final lamp = context.lamp;
    final theme = Theme.of(context);
    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            child: Column(
              children: [
                const Spacer(),
                LotusMark(size: 58, color: lamp.gold, strokeWidth: 3),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _checked ? _maybeAuth : null,
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: lamp.sand.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(Icons.fingerprint, size: 58, color: lamp.sand),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Touch the sensor to unlock',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                if (ref.read(lockControllerProvider).hasPin)
                  AppButton(
                    label: 'Use PIN',
                    variant: AppButtonVariant.text,
                    onPressed: () => setState(() => _showPin = true),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
