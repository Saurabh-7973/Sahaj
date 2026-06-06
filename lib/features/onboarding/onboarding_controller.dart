import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Holds onboarding answers + completion flag for the duration of the flow.
///
/// Phase 2 = shell only: this collects answers and gates the router, but does
/// NOT yet run persona-routing, red-flag triage, or baseline scoring (roadmap
/// Weeks 3-4). Completion is in-memory for now — does not survive relaunch;
/// persistence (Hive) is a later phase.
class OnboardingController extends ChangeNotifier {
  Persona? persona;
  final Set<Goal> goals = <Goal>{};
  final Map<String, int> healthAnswers = <String, int>{};
  bool complete = false;

  void setPersona(Persona p) {
    persona = p;
    notifyListeners();
  }

  void toggleGoal(Goal g) {
    if (!goals.add(g)) goals.remove(g);
    notifyListeners();
  }

  void setHealthAnswer(String key, int value) {
    healthAnswers[key] = value;
    notifyListeners();
  }

  void finish() {
    complete = true;
    notifyListeners();
  }
}

final onboardingControllerProvider =
    ChangeNotifierProvider<OnboardingController>(
      (ref) => OnboardingController(),
    );
