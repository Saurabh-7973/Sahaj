import 'package:flutter/foundation.dart';

/// Content track chosen by persona routing.
enum Track { solo, partnered }

/// Coarse banding for baseline / mind-body areas (no clinical scoring yet).
enum Band { low, medium, high }

/// Starting ramp for the generated plan.
enum Difficulty { gentle, standard }

/// Where the user stands on the soft medical gate (synthesis §6 screen 7).
enum MedicalClearance { notSeen, proceedAnyway, confirmedDoctor }

/// Categories a red flag can fall into.
enum TriageCategory { cardiac, metabolic, neuro, organicErectile, mentalHealth }

/// Emergency red flags (safety pack §3 carve-out). These override every other
/// route and send the user to urgent care — not the ordinary "see a doctor
/// soon" note. Conservative by design: any single yes fires.
enum EmergencyFlag {
  /// Priapism — an erection that won't subside / has lasted hours and is painful.
  priapism,

  /// Saddle anaesthesia or new leg weakness/numbness — a neurological emergency.
  neuroSaddle,
}

/// Pelvic-floor pattern from the hypertonic screen (safety pack §2). The
/// default program is strengthen-first, which suits most men; a likely-tight
/// (hypertonic) floor should down-train first, ideally with a professional, so
/// strengthening first doesn't make things worse.
enum PelvicFloorPattern { likelyWeak, likelyTight }

/// Version of the must-accept health disclaimer (safety pack §1a). Bump when
/// the wording changes so a prior acceptance no longer counts and is
/// re-collected. Stored with the acceptance date on the onboarding state.
const String kDisclaimerVersion = '1.0';

@immutable
class TriageFlag {
  const TriageFlag(this.category, this.reason);
  final TriageCategory category;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is TriageFlag &&
      other.category == category &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(category, reason);
}

@immutable
class TriageResult {
  const TriageResult(this.flags);
  final List<TriageFlag> flags;

  bool get hasFlags => flags.isNotEmpty;
  Set<TriageCategory> get categories =>
      flags.map((f) => f.category).toSet();
}

@immutable
class Baseline {
  const Baseline({required this.bands, required this.raw});
  final Map<String, Band> bands;
  final Map<String, int> raw;
}

@immutable
class PlanWeek {
  const PlanWeek({
    required this.number,
    required this.phase,
    required this.moduleTags,
  });
  final int number;
  final String phase;
  final List<String> moduleTags;
}

@immutable
class Plan {
  const Plan({
    required this.weeks,
    required this.track,
    required this.emphasis,
    required this.startDifficulty,
  });
  final List<PlanWeek> weeks;
  final Track track;
  final Set<String> emphasis;
  final Difficulty startDifficulty;
}
