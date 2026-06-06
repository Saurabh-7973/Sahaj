import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/book_mode_cover.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

void main() {
  testWidgets('hidden when book mode off', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesControllerProvider
              .overrideWith((ref) => PreferencesController()),
        ],
        child: const MaterialApp(
          home: BookModeCover(child: Text('REAL APP')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('REAL APP'), findsOneWidget);
    expect(find.text('My Notes'), findsNothing);
  });

  testWidgets('covers when book mode on, double-tap reveals', (tester) async {
    final prefs = PreferencesController()..setBookMode(true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesControllerProvider.overrideWith((ref) => prefs),
        ],
        child: const MaterialApp(
          home: BookModeCover(child: Text('REAL APP')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Notes'), findsOneWidget);
    expect(find.text('REAL APP'), findsNothing);

    // Drive a deterministic double-tap via TestGesture so both pointer events
    // land within kDoubleTapTimeout regardless of wall-clock timing.
    final center = tester.getCenter(find.text('My Notes'));
    final gesture = await tester.startGesture(center, kind: PointerDeviceKind.touch);
    await gesture.up();
    // Second tap must start before kDoubleTapTimeout (300 ms). Advance fake
    // clock by a safe 100 ms so the recogniser still sees it as a double-tap.
    await tester.pump(const Duration(milliseconds: 100));
    final gesture2 = await tester.startGesture(center, kind: PointerDeviceKind.touch);
    await gesture2.up();
    await tester.pumpAndSettle();

    expect(find.text('REAL APP'), findsOneWidget);
  });
}
