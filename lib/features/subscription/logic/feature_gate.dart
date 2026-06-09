/// What Pro unlocks (synthesis §8). Free tier is real and useful forever;
/// these are the extras Pro adds.
enum ProFeature {
  fullProtocol, // the full 12-week plan past the free starter content
  allSessions,
  allArticles,
  detailedProgress,
  partnerMode,
}

/// Free-tier content allowances (synthesis §8): the first N items are free,
/// the rest are Pro. Kept as pure thresholds so gating is testable and the
/// UI/catalog can decide per-item.
const int kFreeArticleCount = 3;
const int kFreeSessionCount = 8;

bool isFeatureLocked(ProFeature feature, {required bool isPro}) => !isPro;

bool isArticleLocked(int index, {required bool isPro}) =>
    !isPro && index >= kFreeArticleCount;

bool isSessionLocked(int index, {required bool isPro}) =>
    !isPro && index >= kFreeSessionCount;
