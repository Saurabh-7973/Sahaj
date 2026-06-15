import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/security/pin_pad.dart';

Widget _app(Widget home) =>
    MaterialApp(theme: AppTheme.dark(), home: home);

Future<void> _enter(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d).first);
    await tester.pump();
  }
}

void main() {
  testWidgets('correct PIN clears and reports success', (tester) async {
    String? got;
    await tester.pumpWidget(_app(PinPad(
      onComplete: (pin) async {
        got = pin;
        return true;
      },
    )));
    await _enter(tester, '123456');
    await tester.pumpAndSettle();
    expect(got, '123456');
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('wrong PIN shows the Try again ceremony, no red', (tester) async {
    await tester.pumpWidget(_app(PinPad(
      onComplete: (pin) async => false,
    )));
    await _enter(tester, '000000');
    await tester.pump(); // error frame
    expect(find.text('Try again'), findsOneWidget);
    // entry resets after the ceremony
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Try again'), findsOneWidget); // stays until next press
  });

  testWidgets('Use fingerprint + Forgot PIN affordances render when provided',
      (tester) async {
    await tester.pumpWidget(_app(PinPad(
      onComplete: (pin) async => true,
      onUseFingerprint: () {},
      onForgot: () {},
    )));
    expect(find.text('Use fingerprint'), findsOneWidget);
    expect(find.text('Forgot PIN'), findsOneWidget);
  });

  testWidgets('setup flow: choose then confirm pops the PIN', (tester) async {
    String? result;
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a PIN'), findsOneWidget);
    await _enter(tester, '258025');
    await tester.pumpAndSettle();
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await _enter(tester, '258025');
    await tester.pumpAndSettle();
    expect(result, '258025');
  });
}
