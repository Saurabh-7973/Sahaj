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
      expect(PricingTier.supporter.meaning,
          "Covers you — and quietly covers someone's ₹499.");
    });

    test('only ₹999 is recommended', () {
      expect(PricingTier.standard.isRecommended, isTrue);
      for (final t in [
        PricingTier.free,
        PricingTier.low,
        PricingTier.supporter
      ]) {
        expect(t.isRecommended, isFalse);
      }
    });

    test('every paid tier unlocks the identical pro flag', () async {
      for (final t in [
        PricingTier.low,
        PricingTier.standard,
        PricingTier.supporter
      ]) {
        final c = SubscriptionController(const _AlwaysOkRepo());
        await c.choose(t);
        expect(c.isPro, isTrue, reason: t.name);
      }
    });
  });

  group('trial / renewal', () {
    test('choosing a paid tier starts a 7-day trial with a renewal date',
        () async {
      final c = SubscriptionController(const _AlwaysOkRepo());
      await c.choose(PricingTier.low);
      expect(c.inTrial, isTrue);
      expect(c.trialEndsAt, isNotNull);
      expect(c.renewsAt, isNotNull);
      // Renewal is ~a year after the trial ends.
      expect(c.renewsAt!.isAfter(c.trialEndsAt!), isTrue);
    });

    test('free grant carries no trial dates', () async {
      final c = SubscriptionController(const _AlwaysOkRepo());
      await c.choose(PricingTier.free);
      expect(c.isPro, isTrue);
      expect(c.inTrial, isFalse);
      expect(c.trialEndsAt, isNull);
    });

    test('reset clears trial state', () async {
      final c = SubscriptionController(const _AlwaysOkRepo());
      await c.choose(PricingTier.standard);
      c.reset();
      expect(c.inTrial, isFalse);
      expect(c.renewsAt, isNull);
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
