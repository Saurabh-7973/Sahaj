import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/subscription/logic/billing_dates.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

void main() {
  group('pricing tiers', () {
    test('canon meaning lines', () {
      expect(PricingTier.free.meaning,
          'Keep training free. The core program is yours either way.');
      expect(PricingTier.low.meaning, 'A fair price on a tight budget.');
      expect(PricingTier.standard.meaning, 'The fair price.');
    });

    test('only ₹999 is recommended', () {
      expect(PricingTier.standard.isRecommended, isTrue);
      for (final t in [
        PricingTier.free,
        PricingTier.low,
      ]) {
        expect(t.isRecommended, isFalse);
      }
    });

    test('every paid tier unlocks the identical pro flag', () async {
      for (final t in [
        PricingTier.low,
        PricingTier.standard,
      ]) {
        final c = SubscriptionController(const _AlwaysOkRepo());
        await c.choose(t);
        expect(c.isPro, isTrue, reason: t.name);
      }
    });
  });

  group('one-time unlock (no trial, no renewal)', () {
    test('choosing a paid tier unlocks Pro for that tier', () async {
      final c = SubscriptionController(const _AlwaysOkRepo());
      await c.choose(PricingTier.low);
      expect(c.isPro, isTrue);
      expect(c.tier, PricingTier.low);
    });

    test('free grant unlocks Pro at ₹0', () async {
      final c = SubscriptionController(const _AlwaysOkRepo());
      await c.choose(PricingTier.free);
      expect(c.isPro, isTrue);
      expect(c.tier, PricingTier.free);
    });

    test('reset clears the entitlement', () async {
      final c = SubscriptionController(const _AlwaysOkRepo());
      await c.choose(PricingTier.standard);
      c.reset();
      expect(c.isPro, isFalse);
      expect(c.tier, isNull);
    });
  });

  group('billing date format (dates, not countdowns)', () {
    final now = DateTime(2026, 6, 11);
    test('same year omits the year', () {
      expect(billingDate(DateTime(2026, 6, 18), now: now), '18 June');
    });
    test('different year includes it', () {
      expect(billingDate(DateTime(2027, 6, 14), now: now), '14 June 2027');
    });
  });
}

class _AlwaysOkRepo implements SubscriptionRepository {
  const _AlwaysOkRepo();
  @override
  Future<bool> fetchIsPro() async => false;
  @override
  Future<bool> purchase(PricingTier tier) async => true;
  @override
  Future<bool> restore() async => true;
}
