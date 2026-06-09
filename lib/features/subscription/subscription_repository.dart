import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/pricing_tier.dart';

/// The billing seam. The controller/UI depend on this, not on RevenueCat
/// directly, so tests use a fake and nothing touches Play Billing until the
/// real implementation is wired in main() with the API key.
abstract class SubscriptionRepository {
  /// Pro entitlement according to the billing backend (RevenueCat).
  Future<bool> fetchIsPro();

  /// Purchase a paid tier. Returns true on a completed purchase.
  Future<bool> purchase(PricingTier tier);

  /// Restore prior purchases. Returns the resulting pro state.
  Future<bool> restore();
}

/// Default — used in tests and any un-overridden read. No entitlement, no
/// purchases reach Play. The real `RevenueCatSubscriptionRepository` is wired
/// only in main() once the SDK key exists.
class NoopSubscriptionRepository implements SubscriptionRepository {
  const NoopSubscriptionRepository();

  @override
  Future<bool> fetchIsPro() async => false;

  @override
  Future<bool> purchase(PricingTier tier) async => false;

  @override
  Future<bool> restore() async => false;
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => const NoopSubscriptionRepository(),
);
