/// Pay-what-you-can sliding scale (synthesis §8, principle 7: Indian price
/// honesty). ₹999 is the standard; ₹0 is a genuine free grant, not a Play SKU
/// (Play Billing won't list a free subscription), so its productId is null.
///
/// DECISION #10 (resolved): the ₹1499 `supporter` pay-it-forward tier is cut —
/// no real grant-funding mechanism backs the "covers someone's ₹499" promise,
/// so shipping it would be a hollow claim. Reinstate only with a real pool.
enum PricingTier {
  free,
  low,
  standard;

  int get rupees => switch (this) {
        PricingTier.free => 0,
        PricingTier.low => 499,
        PricingTier.standard => 999,
      };

  /// Google Play product id, or null for the free tier (granted locally).
  String? get productId => switch (this) {
        PricingTier.free => null,
        PricingTier.low => 'sahaj_pro_499',
        PricingTier.standard => 'sahaj_pro_999',
      };

  bool get requiresPurchase => this != PricingTier.free;

  bool get isRecommended => this == PricingTier.standard;

  /// Tier meaning line (M7 §1 canon).
  String get meaning => switch (this) {
        PricingTier.free =>
          'Keep training free. The core program is yours either way.',
        PricingTier.low => 'A fair price on a tight budget.',
        PricingTier.standard => 'The fair price.',
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
