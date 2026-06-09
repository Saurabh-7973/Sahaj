/// What Pro unlocks (synthesis §8). Free tier is real and useful forever;
/// these are the extras Pro adds.
enum ProFeature {
  fullProtocol, // the full 12-week plan past the free starter content
  allSessions,
  allArticles,
  detailedProgress,
  partnerMode,
}

/// Free-tier allowances (synthesis §8). The free tier is genuinely useful
/// forever: the first 3 articles, all Library practice, and the 4-week
/// Foundation of the plan. Pro unlocks the full 12-week protocol and the rest
/// of the library reading. Pure thresholds so gating stays testable.
const int kFreeArticleCount = 3;
const int kFreePlanWeeks = 4; // Weeks 1-4 (Foundation) are free.

bool isFeatureLocked(ProFeature feature, {required bool isPro}) => !isPro;

bool isArticleLocked(int index, {required bool isPro}) =>
    !isPro && index >= kFreeArticleCount;

/// A plan week is Pro once it's past the free Foundation. [week] is 1-based.
bool isPlanWeekLocked(int week, {required bool isPro}) =>
    !isPro && week > kFreePlanWeeks;
