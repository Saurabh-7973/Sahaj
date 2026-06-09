import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/subscription/logic/feature_gate.dart';

void main() {
  group('pro is unrestricted', () {
    test('nothing is locked for a pro user', () {
      for (final f in ProFeature.values) {
        expect(isFeatureLocked(f, isPro: true), isFalse);
      }
      expect(isArticleLocked(99, isPro: true), isFalse);
      expect(isPlanWeekLocked(12, isPro: true), isFalse);
    });
  });

  group('free tier allowances (synthesis §8)', () {
    test('pro-only features are locked for free users', () {
      expect(isFeatureLocked(ProFeature.fullProtocol, isPro: false), isTrue);
      expect(isFeatureLocked(ProFeature.allArticles, isPro: false), isTrue);
      expect(isFeatureLocked(ProFeature.detailedProgress, isPro: false), isTrue);
    });

    test('first 3 articles are free, the rest locked', () {
      expect(isArticleLocked(0, isPro: false), isFalse);
      expect(isArticleLocked(2, isPro: false), isFalse);
      expect(isArticleLocked(3, isPro: false), isTrue);
      expect(isArticleLocked(10, isPro: false), isTrue);
    });

    test('plan Weeks 1-4 (Foundation) are free; Weeks 5-12 are Pro', () {
      expect(isPlanWeekLocked(1, isPro: false), isFalse);
      expect(isPlanWeekLocked(4, isPro: false), isFalse);
      expect(isPlanWeekLocked(5, isPro: false), isTrue);
      expect(isPlanWeekLocked(12, isPro: false), isTrue);
    });
  });
}
