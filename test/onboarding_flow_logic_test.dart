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
}
