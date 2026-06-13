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

/// Free library sessions = the Foundation base techniques (and their weekly
/// variants). Everything past Foundation is Pro in the library, rendered as a
/// "Pro" chip — never a week-gate (M5 law 2). DECISION #1 (M5): confirm this
/// free-session set against the intended free-tier scope.
const kFreeSessionBaseTags = <String>{
  'anatomy',
  'pfmt_identify',
  'reverse_kegel_intro',
  'breathwork_basics',
};

/// Strips a `_vN` variant suffix to the base tag.
String sessionBaseTag(String tag) {
  final m = RegExp(r'^(.*)_v\d+$').firstMatch(tag);
  return m == null ? tag : m.group(1)!;
}

/// A library session is Pro-locked when its base technique isn't in the free
/// Foundation set.
bool isSessionLocked(String tag, {required bool isPro}) =>
    !isPro && !kFreeSessionBaseTags.contains(sessionBaseTag(tag));

bool isFeatureLocked(ProFeature feature, {required bool isPro}) => !isPro;

bool isArticleLocked(int index, {required bool isPro}) =>
    !isPro && index >= kFreeArticleCount;

/// A plan week is Pro once it's past the free Foundation. [week] is 1-based.
bool isPlanWeekLocked(int week, {required bool isPro}) =>
    !isPro && week > kFreePlanWeeks;
