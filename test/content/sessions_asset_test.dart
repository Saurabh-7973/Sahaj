import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';
import 'package:sahaj/features/onboarding/logic/plan_generator.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart' show Goal;
import 'package:sahaj/features/sessions/logic/catalog_parser.dart';

// Validates the real shipped asset, not a fixture: a malformed module or a
// plan tag with no catalog entry would otherwise only surface at runtime.
void main() {
  final jsonStr = File('assets/content/sessions.json').readAsStringSync();
  final catalog = parseCatalog(jsonStr);

  test('every module is well-formed', () {
    expect(catalog, isNotEmpty);
    for (final def in catalog.values) {
      expect(def.title.trim(), isNotEmpty, reason: '${def.tag}: empty title');
      expect(def.steps, isNotEmpty, reason: '${def.tag}: no steps');
      for (final step in def.steps) {
        expect(step.title.trim(), isNotEmpty,
            reason: '${def.tag}: step with empty title');
        expect(step.seconds, greaterThan(0),
            reason: '${def.tag}/${step.title}: non-positive seconds');
        expect(step.guidance.trim(), isNotEmpty,
            reason: '${def.tag}/${step.title}: empty guidance');
      }
    }
  });

  test('variant chains are contiguous so rotation reaches every variant', () {
    // The scheduler probes _v2, _v3, … and stops at the first gap, so a
    // _v3 without a _v2 (or a variant without its base) is dead content.
    for (final tag in catalog.keys) {
      final match = RegExp(r'^(.*)_v(\d+)$').firstMatch(tag);
      if (match == null) continue;
      final base = match.group(1)!;
      final n = int.parse(match.group(2)!);
      expect(catalog.containsKey(base), isTrue,
          reason: '$tag has no base module $base');
      for (var i = 2; i < n; i++) {
        expect(catalog.containsKey('${base}_v$i'), isTrue,
            reason: '$tag is unreachable: missing ${base}_v$i breaks the chain');
      }
    }
  });

  test('every plan tag from every track/goal combination resolves', () {
    const baseline = Baseline(bands: {}, raw: {});
    for (final track in Track.values) {
      final trackTag = track == Track.partnered ? 'partnered' : 'solo';
      final plan = generatePlan(
        track: track,
        goals: Goal.values.toSet(),
        baseline: baseline,
        mindBody: const {},
      );
      for (final week in plan.weeks) {
        for (final tag in week.moduleTags) {
          if (tag == trackTag) continue; // track marker, intentionally unplayable
          expect(catalog.containsKey(tag), isTrue,
              reason: 'week ${week.number}: tag $tag has no session');
        }
      }
    }
  });
}
