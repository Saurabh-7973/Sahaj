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

  /// Billing facts rendered as dates, never countdowns (M7 §2). Populated by
  /// the billing backend; until RevenueCat is wired, [choose] sets a local
  /// 7-day trial so the trial/active states are real.
  bool inTrial = false;
  DateTime? trialEndsAt;
  DateTime? renewsAt;

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
    if (t.requiresPurchase) {
      // "Start 7 days free" — a real local trial; renews a year after it ends.
      final now = DateTime.now();
      inTrial = true;
      trialEndsAt = now.add(const Duration(days: 7));
      renewsAt = trialEndsAt!.add(const Duration(days: 365));
    } else {
      inTrial = false;
      trialEndsAt = null;
      renewsAt = null;
    }
    _persist();
    notifyListeners();
  }

  void reset() {
    isPro = false;
    tier = null;
    inTrial = false;
    trialEndsAt = null;
    renewsAt = null;
    _store?.clear();
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'isPro': isPro,
        'tier': tier?.name,
        'inTrial': inTrial,
        'trialEndsAt': trialEndsAt?.toIso8601String(),
        'renewsAt': renewsAt?.toIso8601String(),
      };

  void loadFrom(Map<String, dynamic> json) {
    isPro = (json['isPro'] as bool?) ?? false;
    final name = json['tier'] as String?;
    tier = null;
    for (final t in PricingTier.values) {
      if (t.name == name) tier = t;
    }
    inTrial = (json['inTrial'] as bool?) ?? false;
    trialEndsAt = DateTime.tryParse(json['trialEndsAt'] as String? ?? '');
    renewsAt = DateTime.tryParse(json['renewsAt'] as String? ?? '');
    notifyListeners();
  }

  void _persist() => _store?.save(toJson());
}

/// Overridden in main() with the persisted controller.
final subscriptionControllerProvider =
    ChangeNotifierProvider<SubscriptionController>(
  (ref) => SubscriptionController(ref.watch(subscriptionRepositoryProvider)),
);
