// +30% string room: M6 privacy screens at 1.3 text scale, no overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/security/pin_pad.dart';
import 'package:sahaj/features/settings/erase_confirm_screen.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('erase confirm at 1.3', (tester) async {
    await _pump(tester, EraseConfirmScreen(onErase: () {}));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN pad at 1.3', (tester) async {
    await _pump(tester, PinPad(onComplete: (_) async => true,
        onUseFingerprint: () {}, onForgot: () {}));
    expect(tester.takeException(), isNull);
  });
}
