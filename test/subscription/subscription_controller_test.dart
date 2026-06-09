import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

class FakeRepo implements SubscriptionRepository {
  bool backendPro = false;
  bool purchaseSucceeds = true;
  final List<String> calls = [];

  @override
  Future<bool> fetchIsPro() async {
    calls.add('fetch');
    return backendPro;
  }

  @override
  Future<bool> purchase(PricingTier tier) async {
    calls.add('purchase:${tier.productId}');
    return purchaseSucceeds;
  }

  @override
  Future<bool> restore() async {
    calls.add('restore');
    return backendPro;
  }
}

void main() {
  test('default state is not pro', () {
    final c = SubscriptionController(FakeRepo());
    expect(c.isPro, isFalse);
    expect(c.tier, isNull);
  });

  test('choosing free grants Pro locally with no purchase call', () async {
    final repo = FakeRepo();
    final c = SubscriptionController(repo);
    final ok = await c.choose(PricingTier.free);
    expect(ok, isTrue);
    expect(c.isPro, isTrue);
    expect(c.tier, PricingTier.free);
    expect(repo.calls, isEmpty); // never hit billing
  });

  test('choosing a paid tier purchases and grants on success', () async {
    final repo = FakeRepo()..purchaseSucceeds = true;
    final c = SubscriptionController(repo);
    final ok = await c.choose(PricingTier.standard);
    expect(ok, isTrue);
    expect(c.isPro, isTrue);
    expect(c.tier, PricingTier.standard);
    expect(repo.calls, ['purchase:sahaj_pro_999']);
  });

  test('a failed purchase does not grant Pro', () async {
    final repo = FakeRepo()..purchaseSucceeds = false;
    final c = SubscriptionController(repo);
    final ok = await c.choose(PricingTier.low);
    expect(ok, isFalse);
    expect(c.isPro, isFalse);
    expect(c.tier, isNull);
  });

  test('refresh follows the backend for paid entitlement', () async {
    final repo = FakeRepo()..backendPro = true;
    final c = SubscriptionController(repo);
    await c.refresh();
    expect(c.isPro, isTrue);
  });

  test('a free grant survives a backend that reports not-pro', () async {
    final repo = FakeRepo()..backendPro = false;
    final c = SubscriptionController(repo);
    await c.choose(PricingTier.free);
    await c.refresh();
    expect(c.isPro, isTrue); // free grant never expires
    expect(c.tier, PricingTier.free);
  });

  test('restore grants Pro when the backend has an entitlement', () async {
    final repo = FakeRepo()..backendPro = true;
    final c = SubscriptionController(repo);
    final ok = await c.restore();
    expect(ok, isTrue);
    expect(c.isPro, isTrue);
  });

  test('toJson/loadFrom round-trips', () async {
    final repo = FakeRepo();
    final a = SubscriptionController(repo);
    await a.choose(PricingTier.supporter);
    final b = SubscriptionController(repo)..loadFrom(a.toJson());
    expect(b.isPro, isTrue);
    expect(b.tier, PricingTier.supporter);
  });
}
