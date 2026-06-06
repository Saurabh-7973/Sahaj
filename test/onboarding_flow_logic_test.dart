import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/app.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  testWidgets('persona routing sets solo track for single user', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SahajApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SahajApp)),
    );
    final c = container.read(onboardingControllerProvider)
      ..setPersona(Persona.singleInexperienced);
    expect(c.track, Track.solo);
  });

  // ── Crisis-interrupt tests ───────────────────────────────────────────────

  /// Drives the onboarding flow from the Welcome screen to the self_harm
  /// health question (14th page, index 14).
  ///
  /// Taps 'Begin' (Welcome → Promise) then 'Continue' 13 more times to reach
  /// the self_harm question page. Returns the [ProviderContainer] so the
  /// caller can set health answers via the controller.
  Future<ProviderContainer> driveToSelfHarm(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SahajApp()));
    await tester.pumpAndSettle();

    // Welcome → Promise
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    // Promise + 12 more steps → self_harm (index 14 = 1 Begin + 13 Continue)
    for (var i = 0; i < 13; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    return ProviderScope.containerOf(
      tester.element(find.byType(SahajApp)),
    );
  }

  testWidgets(
    'self_harm answer above "Not at all" shows crisis screen',
    (tester) async {
      final container = await driveToSelfHarm(tester);

      // Confirm we are on the self_harm question page.
      expect(
        find.text(
          'Over the last 2 weeks, how often have you had thoughts that you '
          'would be better off dead, or of hurting yourself?',
        ),
        findsOneWidget,
      );

      // Set a positive answer (index 1 = "Several days") via the controller —
      // the same path the UI SelectableOption tap takes — then tap Continue.
      // _next() reads healthAnswers['self_harm'] and sets _showingCrisis.
      container
          .read(onboardingControllerProvider)
          .setHealthAnswer('self_harm', 1);
      await tester.pump(); // let Riverpod rebuild (notifyListeners)

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Crisis screen must be visible.
      expect(find.text('You deserve support'), findsOneWidget);
      expect(find.text('Tele-MANAS'), findsOneWidget);
      expect(find.text('14416'), findsOneWidget);
    },
  );

  testWidgets(
    '"Not at all" on self_harm does NOT show the crisis screen',
    (tester) async {
      final container = await driveToSelfHarm(tester);

      // Confirm we are on the self_harm question page.
      expect(
        find.text(
          'Over the last 2 weeks, how often have you had thoughts that you '
          'would be better off dead, or of hurting yourself?',
        ),
        findsOneWidget,
      );

      // Set answer to index 0 = "Not at all" — must NOT trigger crisis screen.
      container
          .read(onboardingControllerProvider)
          .setHealthAnswer('self_harm', 0);
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Crisis screen must be absent; self_harm prompt also gone (page advanced).
      expect(find.text('You deserve support'), findsNothing);
      expect(
        find.text(
          'Over the last 2 weeks, how often have you had thoughts that you '
          'would be better off dead, or of hurting yourself?',
        ),
        findsNothing,
      );
    },
  );
}
