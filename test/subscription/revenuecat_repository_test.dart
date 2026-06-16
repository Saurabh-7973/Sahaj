import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/revenuecat_repository.dart';

void main() {
  // The SDK-backed paths (getCustomerInfo / purchaseStoreProduct / restore)
  // need a platform channel and are exercised on-device with License testing,
  // not in unit tests. What IS unit-testable: the free-tier short-circuit and
  // the inert-by-default key.
  const repo = RevenueCatSubscriptionRepository();

  test('purchasing the free (₹0) tier never reaches the store', () async {
    // PricingTier.free has a null productId → returns false before any
    // Purchases call, so this runs without the SDK.
    expect(await repo.purchase(PricingTier.free), isFalse);
  });

  test('the entitlement id is the single lifetime "pro"', () {
    expect(kProEntitlement, 'pro');
  });

  test('the API key is empty by default — billing stays inert until provided',
      () {
    expect(kRevenueCatApiKey, isEmpty);
  });
}
