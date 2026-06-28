import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/security/biometric_gate.dart';
import 'package:sahaj/features/security/lock_controller.dart';

void main() {
  // Regression: the gate advertised a Forgot-PIN → erase recovery in its
  // docstring, but app.dart instantiated it without onForgotPin, so the button
  // never rendered. A user who forgot the PIN and couldn't pass biometrics was
  // sealed out with no recovery. The gate now self-wires the recovery.
  testWidgets('Forgot PIN on the lock gate reaches erase confirm and returns',
      (tester) async {
    final onboarding = OnboardingController()..setBiometricLock(true);
    final lock = LockController(MemoryPinStore());
    await lock.setPin('737963');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref) => onboarding),
          lockControllerProvider.overrideWith((ref) => lock),
        ],
        child: const MaterialApp(
          home: BiometricGate(child: Text('UNLOCKED')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Biometric auth fails (no real sensor in tests) → the gate face shows with
    // a "Use PIN" fallback; it must not auto-open the app.
    expect(find.text('UNLOCKED'), findsNothing);
    await tester.tap(find.text('Use PIN'));
    await tester.pumpAndSettle();

    // The pad must offer the recovery affordance even though app.dart passes no
    // onForgotPin (the gate defaults it internally).
    expect(find.text('Forgot PIN'), findsOneWidget);

    await tester.tap(find.text('Forgot PIN'));
    await tester.pumpAndSettle();
    expect(find.text('Erase everything'), findsOneWidget);
    expect(find.text('Hold to erase'), findsOneWidget);

    // "Keep my data" backs out to the pad — the recovery path is escapable and
    // doesn't pull the trigger.
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot PIN'), findsOneWidget);
    expect(find.text('Erase everything'), findsNothing);
  });
}
