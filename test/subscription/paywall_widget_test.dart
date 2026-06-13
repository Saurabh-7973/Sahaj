import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/analytics.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/pages/paywall_screen.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

import '../support/fake_analytics.dart';

class _Repo implements SubscriptionRepository {
  @override
  Future<bool> fetchIsPro() async => false;
  @override
  Future<bool> purchase(PricingTier tier) async => true;
  @override
  Future<bool> restore() async => true;
}

Widget _app(SubscriptionController sub) => ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(FakeAnalytics()),
        subscriptionControllerProvider.overrideWith((ref) => sub),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const PaywallScreen(source: 'test'),
      ),
    );

void main() {
  testWidgets('nothing pre-selected; CTA disabled with the prompt',
      (tester) async {
    await tester.pumpWidget(_app(SubscriptionController(_Repo())));
    await tester.pumpAndSettle();

    expect(find.text('Nothing is pre-selected — tap a tier first.'),
        findsOneWidget);
    // X and Maybe later are always present (the wall teaches its exit).
    expect(find.byTooltip('Close'), findsNothing); // custom close, not tooltip
    expect(find.text('Maybe later'), findsOneWidget);
    // The recommended label exists but selects nothing.
    expect(find.text('Recommended'), findsOneWidget);
  });

  testWidgets('selecting ₹499 wakes the CTA with a price-specific line',
      (tester) async {
    await tester.pumpWidget(_app(SubscriptionController(_Repo())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A fair price on a tight budget.'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('₹499/yr after 7 days free'),
      findsOneWidget,
    );
    expect(find.text('Nothing is pre-selected — tap a tier first.'),
        findsNothing);
  });

  testWidgets('choosing ₹0 grants Pro and dismisses', (tester) async {
    final sub = SubscriptionController(_Repo());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(FakeAnalytics()),
        subscriptionControllerProvider.overrideWith((ref) => sub),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PaywallScreen(source: 'test'),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(
        find.text('Keep training free. The core program is yours either way.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep training free'));
    await tester.pumpAndSettle();

    expect(sub.isPro, isTrue);
    expect(sub.inTrial, isFalse);
    // Back on the originating screen.
    expect(find.text('open'), findsOneWidget);
  });
}
