import 'package:purchases_flutter/purchases_flutter.dart';

import 'logic/pricing_tier.dart';
import 'subscription_repository.dart';

/// RevenueCat public SDK API key. **Empty until handed over** — while empty,
/// `main()` keeps the [NoopSubscriptionRepository] and never configures the
/// SDK, so the app is inert to billing. Drop the Android/Google "SDK API key"
/// here (or via --dart-define) to go live. See `docs/EXTERNAL_TASKS.md` §2.
const String kRevenueCatApiKey =
    String.fromEnvironment('REVENUECAT_KEY', defaultValue: '');

/// The single lifetime entitlement configured in RevenueCat. The ₹499/₹999
/// products are **one-time, non-consumable** in-app products; buying either
/// grants `pro` forever. No trial, no renewal, no expiry — one-time has none.
const String kProEntitlement = 'pro';

/// Real billing backend (one-time lifetime unlock). Wired in `main()` only when
/// [kRevenueCatApiKey] is non-empty. Each method degrades to `false` on any
/// error (user-cancelled purchase, network, store hiccup) so the controller's
/// bool contract holds and nothing crashes the flow.
class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  const RevenueCatSubscriptionRepository();

  bool _hasPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(kProEntitlement);

  @override
  Future<bool> fetchIsPro() async {
    try {
      return _hasPro(await Purchases.getCustomerInfo());
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> purchase(PricingTier tier) async {
    final id = tier.productId;
    if (id == null) return false; // free (₹0) is a local grant, never Play
    try {
      final products = await Purchases.getProducts(
        [id],
        productCategory: ProductCategory.nonSubscription,
      );
      if (products.isEmpty) return false;
      return _hasPro(await Purchases.purchaseStoreProduct(products.first));
    } catch (_) {
      // Includes the user cancelling the Play sheet — not an error to surface.
      return false;
    }
  }

  @override
  Future<bool> restore() async {
    try {
      return _hasPro(await Purchases.restorePurchases());
    } catch (_) {
      return false;
    }
  }
}
