import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_store.dart';
import 'logic/banding.dart';
import 'logic/models/onboarding_models.dart';
import 'logic/plan_generator.dart';
import 'logic/safety_screening.dart';
import 'logic/triage.dart';

export 'logic/models/onboarding_models.dart';

/// Persona routing options (synthesis §6 screen 4 — Persona Zero gateway).
enum Persona {
  partneredActive,
  partneredInactive,
  singleExperienced,
  singleInexperienced,
  preferNotToSay,
}

/// Goals (onboarding_copy.md S4 — multi-select, "What brings you here").
/// Persona-Zero-inclusive: [foundation] is a first-class option, never lesser.
enum Goal {
  control,
  erections,
  anxiety,
  confidence,
  foundation,
  partner,
}

class OnboardingController extends ChangeNotifier {
  OnboardingController([this._store]);

  final OnboardingStore? _store;

  Persona? persona;
  final Set<Goal> goals = <Goal>{};
  final Map<String, int> healthAnswers = <String, int>{};
  final Map<String, int> emergencyAnswers = <String, int>{};
  final Map<String, int> tensionAnswers = <String, int>{};
  final Map<String, int> baselineRaw = <String, int>{};
  final Map<String, int> mindBodyRaw = <String, int>{};
  bool complete = false;
  bool biometricLock = false;

  /// Must-accept health disclaimer (safety pack §1a): the version the user
  /// accepted and when. [disclaimerAccepted] is true only when the accepted
  /// version matches the current [kDisclaimerVersion].
  String? disclaimerVersion;
  DateTime? disclaimerAcceptedAt;
  bool get disclaimerAccepted => disclaimerVersion == kDisclaimerVersion;

  /// Emergency carve-out flags (safety pack §3) — override all routing.
  Set<EmergencyFlag> get emergencyFlags => evaluateEmergency(emergencyAnswers);

  /// Hypertonic-screen outcome (safety pack §2).
  PelvicFloorPattern get pelvicFloorPattern => evaluateTension(tensionAnswers);

  /// The onboarding step the user last reached, persisted after every
  /// advance so an interruption (lock / kill) resumes at the exact screen
  /// (M4·3). 0 until the flow moves past Welcome.
  int lastStep = 0;

  // Derived/result state (computed on finish()).
  TriageResult? triage;
  MedicalClearance? medicalClearance;
  Plan? plan;

  /// Persona routing → content track (synthesis §6 screen 4).
  Track? get track {
    switch (persona) {
      case Persona.partneredActive:
      case Persona.partneredInactive:
        return Track.partnered;
      case Persona.singleExperienced:
      case Persona.singleInexperienced:
      case Persona.preferNotToSay:
        return Track.solo;
      case null:
        return null;
    }
  }

  void setPersona(Persona p) {
    persona = p;
    _persist();
  }

  void toggleGoal(Goal g) {
    if (!goals.add(g)) goals.remove(g);
    _persist();
  }

  void setHealthAnswer(String key, int value) {
    healthAnswers[key] = value;
    _persist();
  }

  void setEmergencyAnswer(String key, int value) {
    emergencyAnswers[key] = value;
    _persist();
  }

  void setTensionAnswer(String key, int value) {
    tensionAnswers[key] = value;
    _persist();
  }

  /// Records acceptance of the current disclaimer version with a timestamp.
  void acceptDisclaimer() {
    disclaimerVersion = kDisclaimerVersion;
    disclaimerAcceptedAt = DateTime.now();
    _persist();
  }

  void setBaselineAnswer(String key, int value) {
    baselineRaw[key] = value;
    _persist();
  }

  void setMindBodyAnswer(String key, int value) {
    mindBodyRaw[key] = value;
    _persist();
  }

  void setBiometricLock(bool v) {
    biometricLock = v;
    _persist();
  }

  void setLastStep(int step) {
    if (step == lastStep) return;
    lastStep = step;
    _persist();
  }

  void setMedicalClearance(MedicalClearance c) {
    medicalClearance = c;
    _persist();
  }

  void finish() {
    triage = evaluate(healthAnswers);
    if (triage!.hasFlags && medicalClearance == null) {
      medicalClearance = MedicalClearance.notSeen;
    }
    final t = track ?? Track.solo;
    final baseline = Baseline(
      bands: _band(baselineRaw),
      raw: Map<String, int>.from(baselineRaw),
    );
    plan = generatePlan(
      track: t,
      goals: goals,
      baseline: baseline,
      mindBody: _band(mindBodyRaw),
      pelvicFloor: pelvicFloorPattern,
    );
    complete = true;
    _persist();
  }

  Map<String, Band> _band(Map<String, int> raw) =>
      raw.map((k, v) => MapEntry(k, bandFromIndex(v)));

  void reset() {
    persona = null;
    goals.clear();
    healthAnswers.clear();
    emergencyAnswers.clear();
    tensionAnswers.clear();
    baselineRaw.clear();
    mindBodyRaw.clear();
    triage = null;
    medicalClearance = null;
    plan = null;
    complete = false;
    biometricLock = false;
    disclaimerVersion = null;
    disclaimerAcceptedAt = null;
    lastStep = 0;
    _store?.clear();
    notifyListeners();
  }

  void _persist() {
    _store?.save(toJson());
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'persona': persona?.name,
        'goals': goals.map((g) => g.name).toList(),
        'health': healthAnswers,
        'emergency': emergencyAnswers,
        'tension': tensionAnswers,
        'baseline': baselineRaw,
        'mindBody': mindBodyRaw,
        'medicalClearance': medicalClearance?.name,
        'disclaimerVersion': disclaimerVersion,
        'disclaimerAcceptedAt': disclaimerAcceptedAt?.toIso8601String(),
        'complete': complete,
        'biometricLock': biometricLock,
        'lastStep': lastStep,
      };

  void loadFrom(Map<String, dynamic> json) {
    persona = _enumByName(Persona.values, json['persona'] as String?);
    goals
      ..clear()
      ..addAll(((json['goals'] as List?) ?? [])
          .map((n) => _enumByName(Goal.values, n as String))
          .whereType<Goal>());
    healthAnswers
      ..clear()
      ..addAll(Map<String, int>.from(json['health'] as Map? ?? {}));
    emergencyAnswers
      ..clear()
      ..addAll(Map<String, int>.from(json['emergency'] as Map? ?? {}));
    tensionAnswers
      ..clear()
      ..addAll(Map<String, int>.from(json['tension'] as Map? ?? {}));
    baselineRaw
      ..clear()
      ..addAll(Map<String, int>.from(json['baseline'] as Map? ?? {}));
    mindBodyRaw
      ..clear()
      ..addAll(Map<String, int>.from(json['mindBody'] as Map? ?? {}));
    medicalClearance =
        _enumByName(MedicalClearance.values, json['medicalClearance'] as String?);
    disclaimerVersion = json['disclaimerVersion'] as String?;
    disclaimerAcceptedAt =
        DateTime.tryParse((json['disclaimerAcceptedAt'] as String?) ?? '');
    complete = (json['complete'] as bool?) ?? false;
    biometricLock = (json['biometricLock'] as bool?) ?? false;
    lastStep = (json['lastStep'] as num?)?.toInt() ?? 0;
    if (complete) finish(); // recompute triage + plan from stored answers
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

final onboardingControllerProvider =
    ChangeNotifierProvider<OnboardingController>(
      (ref) => OnboardingController(),
    );
