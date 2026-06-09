import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';

void main() {
  test('rupee amounts match the sliding scale', () {
    expect(PricingTier.free.rupees, 0);
    expect(PricingTier.low.rupees, 499);
    expect(PricingTier.standard.rupees, 999);
    expect(PricingTier.supporter.rupees, 1499);
  });

  test('only paid tiers have a Play product id; free has none', () {
    expect(PricingTier.free.productId, isNull);
    expect(PricingTier.low.productId, 'sahaj_pro_499');
    expect(PricingTier.standard.productId, 'sahaj_pro_999');
    expect(PricingTier.supporter.productId, 'sahaj_pro_1499');
  });

  test('free tier does not require a purchase; paid tiers do', () {
    expect(PricingTier.free.requiresPurchase, isFalse);
    expect(PricingTier.low.requiresPurchase, isTrue);
    expect(PricingTier.standard.requiresPurchase, isTrue);
    expect(PricingTier.supporter.requiresPurchase, isTrue);
  });

  test('standard (₹999) is the recommended tier', () {
    expect(PricingTier.standard.isRecommended, isTrue);
    for (final t in PricingTier.values.where((t) => t != PricingTier.standard)) {
      expect(t.isRecommended, isFalse);
    }
  });

  test('paid product ids map back to their tier', () {
    expect(PricingTier.fromProductId('sahaj_pro_999'), PricingTier.standard);
    expect(PricingTier.fromProductId('sahaj_pro_499'), PricingTier.low);
    expect(PricingTier.fromProductId('unknown'), isNull);
  });
}
