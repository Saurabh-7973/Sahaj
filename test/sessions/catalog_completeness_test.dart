import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';
import 'package:sahaj/features/onboarding/logic/plan_generator.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart' show Goal;
import 'package:sahaj/features/sessions/logic/catalog_parser.dart';
import 'package:sahaj/features/sessions/logic/scheduler.dart';

void main() {
  final catalog =
      parseCatalog(File('assets/content/sessions.json').readAsStringSync());

  Baseline baseline() => const Baseline(bands: {}, raw: {});

  test('every plan week resolves to a real, non-empty catalog session — '
      'across tracks, goals, and a tight floor', () {
    final floors = PelvicFloorPattern.values;
    final tracks = Track.values;
    // Each goal alone, plus the empty set, covers every emphasis tag.
    final goalSets = <Set<Goal>>[{}, for (final g in Goal.values) {g}];

    for (final track in tracks) {
      for (final floor in floors) {
        for (final goals in goalSets) {
          final plan = generatePlan(
            track: track,
            goals: goals,
            baseline: baseline(),
            mindBody: const {},
            pelvicFloor: floor,
          );
          for (var week = 1; week <= 12; week++) {
            for (var day = 1; day <= 7; day++) {
              final s = todaysSession(
                  plan: plan, week: week, day: day, catalog: catalog);
              final ctx = 'track=$track floor=$floor goals=$goals '
                  'week=$week day=$day';
              expect(s, isNotNull, reason: ctx);
              expect(s!.steps, isNotEmpty, reason: ctx);
              expect(s.totalSeconds, greaterThan(0), reason: ctx);
            }
          }
        }
      }
    }
  });

  test('the hypertonic down_training tag exists and is playable', () {
    expect(catalog.containsKey('down_training'), isTrue);
    expect(catalog['down_training']!.steps, isNotEmpty);
  });

  test('phase headline tags carry four distinct weekly variants', () {
    for (final base in ['pfmt_identify', 'kegel_reverse_combined',
        'pfmt_functional']) {
      final tags = [base, '${base}_v2', '${base}_v3', '${base}_v4'];
      for (final t in tags) {
        expect(catalog.containsKey(t), isTrue, reason: t);
      }
      // Titles differ → genuinely distinct sessions, not repeats.
      final titles = tags.map((t) => catalog[t]!.title).toSet();
      expect(titles.length, 4, reason: '$base variants share a title');
    }
  });

  test('seeded journey sessions open with Settle and close with Down-regulate',
      () {
    for (final tag in ['pfmt_identify', 'kegel_reverse_combined_v2',
        'pfmt_functional_v4', 'down_training']) {
      final steps = catalog[tag]!.steps;
      expect(steps.first.title, 'Settle', reason: tag);
      expect(steps.last.title, 'Down-regulate', reason: tag);
    }
  });
}
