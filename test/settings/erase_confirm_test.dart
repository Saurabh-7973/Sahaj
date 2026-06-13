import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/settings/erase_confirm_screen.dart';
import 'package:sahaj/shared/widgets/widgets.dart';

void main() {
  testWidgets('full-screen confirm; holding 3s fires onErase', (tester) async {
    var erased = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: EraseConfirmScreen(onErase: () => erased = true),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Erase everything'), findsOneWidget);
    expect(find.text('Keep my data'), findsOneWidget);
    expect(find.byType(HoldToConfirm), findsOneWidget);

    // Press and hold past the 3s meter.
    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirm)));
    await tester.pump(); // let onTapDown fire + start the meter
    await tester.pump(const Duration(seconds: 4));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(erased, isTrue);
  });

  testWidgets('releasing early does not erase', (tester) async {
    var erased = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: EraseConfirmScreen(onErase: () => erased = true),
    ));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirm)));
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(erased, isFalse);
  });
}
