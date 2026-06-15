// +30% string room: M7 paywall + subscription at 1.3 text scale, no overflow.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/analytics.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/pages/paywall_screen.dart';
import 'package:sahaj/features/subscription/pages/subscription_page.dart';
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

Future<void> _pump(
    WidgetTester tester, Widget home, SubscriptionController sub) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(FakeAnalytics()),
        subscriptionControllerProvider.overrideWith((ref) => sub),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('paywall at 1.3 (selected)', (tester) async {
    await _pump(tester, const PaywallScreen(source: 't'),
        SubscriptionController(_Repo()));
    await tester.tap(find.text('A fair price on a tight budget.'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('subscription trial at 1.3', (tester) async {
    final sub = SubscriptionController(_Repo());
    await sub.choose(PricingTier.standard);
    await _pump(tester, const SubscriptionPage(), sub);
    expect(tester.takeException(), isNull);
  });
}
