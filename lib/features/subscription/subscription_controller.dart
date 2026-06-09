import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/subscription_store.dart';
import 'logic/pricing_tier.dart';
import 'subscription_repository.dart';

/// Holds + persists the Pro entitlement and chosen tier. Free (₹0) is a local
/// grant that never expires; paid tiers go through the billing backend and are
/// reconciled on [refresh].
class SubscriptionController extends ChangeNotifier {
  SubscriptionController(this._repo, [this._store]);

  final SubscriptionRepository _repo;
  final SubscriptionStore? _store;

  bool isPro = false;
  PricingTier? tier;

  /// Reconcile with the billing backend. A free grant is honoured locally and
  /// never downgraded; otherwise the backend is the source of truth.
  Future<void> refresh() async {
    final backendPro = await _repo.fetchIsPro();
    if (tier == PricingTier.free) {
      isPro = true;
    } else {
      isPro = backendPro;
      if (backendPro && tier == null) tier = PricingTier.standard;
    }
    _persist();
    notifyListeners();
  }

  /// Apply a chosen tier. Free grants Pro locally with no purchase; paid tiers
  /// run the purchase flow and only grant on success. Returns whether Pro is
  /// active afterwards.
  Future<bool> choose(PricingTier chosen) async {
    if (!chosen.requiresPurchase) {
      _grant(chosen);
      return true;
    }
    final ok = await _repo.purchase(chosen);
    if (ok) _grant(chosen);
    return ok;
  }

  Future<bool> restore() async {
    final ok = await _repo.restore();
    if (ok) {
      isPro = true;
      tier ??= PricingTier.standard;
      _persist();
      notifyListeners();
    }
    return ok;
  }

  void _grant(PricingTier t) {
    isPro = true;
    tier = t;
    _persist();
    notifyListeners();
  }

  void reset() {
    isPro = false;
    tier = null;
    _store?.clear();
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {'isPro': isPro, 'tier': tier?.name};

  void loadFrom(Map<String, dynamic> json) {
    isPro = (json['isPro'] as bool?) ?? false;
    final name = json['tier'] as String?;
    tier = null;
    for (final t in PricingTier.values) {
      if (t.name == name) tier = t;
    }
    notifyListeners();
  }

  void _persist() => _store?.save(toJson());
}

/// Overridden in main() with the persisted controller.
final subscriptionControllerProvider =
    ChangeNotifierProvider<SubscriptionController>(
  (ref) => SubscriptionController(ref.watch(subscriptionRepositoryProvider)),
);
