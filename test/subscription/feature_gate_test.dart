import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/subscription/logic/feature_gate.dart';

void main() {
  group('pro is unrestricted', () {
    test('nothing is locked for a pro user', () {
      for (final f in ProFeature.values) {
        expect(isFeatureLocked(f, isPro: true), isFalse);
      }
      expect(isArticleLocked(99, isPro: true), isFalse);
      expect(isSessionLocked(99, isPro: true), isFalse);
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

    test('first 8 sessions are free, the rest locked', () {
      expect(isSessionLocked(0, isPro: false), isFalse);
      expect(isSessionLocked(7, isPro: false), isFalse);
      expect(isSessionLocked(8, isPro: false), isTrue);
    });
  });
}
