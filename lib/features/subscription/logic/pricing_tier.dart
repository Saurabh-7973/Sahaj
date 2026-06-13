/// Pay-what-you-can sliding scale (synthesis §8, principle 7: Indian price
/// honesty). ₹999 is the standard; ₹0 is a genuine free grant, not a Play SKU
/// (Play Billing won't list a free subscription), so its productId is null.
enum PricingTier {
  free,
  low,
  standard,
  supporter;

  int get rupees => switch (this) {
        PricingTier.free => 0,
        PricingTier.low => 499,
        PricingTier.standard => 999,
        PricingTier.supporter => 1499,
      };

  /// Google Play product id, or null for the free tier (granted locally).
  String? get productId => switch (this) {
        PricingTier.free => null,
        PricingTier.low => 'sahaj_pro_499',
        PricingTier.standard => 'sahaj_pro_999',
        PricingTier.supporter => 'sahaj_pro_1499',
      };

  bool get requiresPurchase => this != PricingTier.free;

  bool get isRecommended => this == PricingTier.standard;

  /// Tier meaning line (M7 §1 canon). The ₹1499 pay-it-forward line ships only
  /// if a real mechanism backs it (DECISION #1 — flagged, not invented).
  String get meaning => switch (this) {
        PricingTier.free =>
          'Keep training free. The core program is yours either way.',
        PricingTier.low => 'A fair price on a tight budget.',
        PricingTier.standard => 'The fair price.',
        PricingTier.supporter =>
          "Covers you — and quietly covers someone's ₹499.",
      };

  /// Price as shown ("₹0", "₹499").
  String get priceLabel => '₹$rupees';

  static PricingTier? fromProductId(String? id) {
    for (final t in PricingTier.values) {
      if (t.productId != null && t.productId == id) return t;
    }
    return null;
  }
}
