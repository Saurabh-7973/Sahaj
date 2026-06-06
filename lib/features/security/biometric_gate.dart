import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../onboarding/onboarding_controller.dart';

/// Wraps the app: if biometric lock is on and we haven't authenticated this
/// launch, require local auth before revealing [child].
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAuth());
  }

  Future<void> _maybeAuth() async {
    final locked = ref.read(onboardingControllerProvider).biometricLock;
    if (!locked) {
      setState(() {
        _unlocked = true;
        _checked = true;
      });
      return;
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Sahaj',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      setState(() {
        _unlocked = ok;
        _checked = true;
      });
    } catch (_) {
      setState(() {
        _unlocked = false;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      body: Center(
        child: _checked
            ? IconButton(
                iconSize: 48,
                icon: const Icon(Icons.lock_outline),
                onPressed: _maybeAuth,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
