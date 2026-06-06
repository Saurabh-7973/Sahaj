import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_store.dart';
import 'logic/banding.dart';
import 'logic/models/onboarding_models.dart';
import 'logic/plan_generator.dart';
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

/// Goals (synthesis §6 screen 5 — multi-select).
enum Goal {
  finishTooQuick,
  hardness,
  firstTimeOrGap,
  pornRelationship,
  lastLongerOptimize,
  exploring,
}

class OnboardingController extends ChangeNotifier {
  OnboardingController([this._store]);

  final OnboardingStore? _store;

  Persona? persona;
  final Set<Goal> goals = <Goal>{};
  final Map<String, int> healthAnswers = <String, int>{};
  final Map<String, int> baselineRaw = <String, int>{};
  final Map<String, int> mindBodyRaw = <String, int>{};
  bool complete = false;
  bool biometricLock = false;

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
    baselineRaw.clear();
    mindBodyRaw.clear();
    triage = null;
    medicalClearance = null;
    plan = null;
    complete = false;
    biometricLock = false;
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
        'baseline': baselineRaw,
        'mindBody': mindBodyRaw,
        'medicalClearance': medicalClearance?.name,
        'complete': complete,
        'biometricLock': biometricLock,
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
    baselineRaw
      ..clear()
      ..addAll(Map<String, int>.from(json['baseline'] as Map? ?? {}));
    mindBodyRaw
      ..clear()
      ..addAll(Map<String, int>.from(json['mindBody'] as Map? ?? {}));
    medicalClearance =
        _enumByName(MedicalClearance.values, json['medicalClearance'] as String?);
    complete = (json['complete'] as bool?) ?? false;
    biometricLock = (json['biometricLock'] as bool?) ?? false;
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
