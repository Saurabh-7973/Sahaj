import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/library/logic/library_logic.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';
import 'package:sahaj/features/subscription/logic/feature_gate.dart';

SessionDef _def(String tag, SessionType type, {String? title}) => SessionDef(
      tag: tag,
      title: title ?? tag,
      type: type,
      steps: const [
        SessionStep(title: 'Settle', seconds: 30, guidance: 'g'),
        SessionStep(title: 'Long holds', seconds: 120, guidance: 'g'),
      ],
    );

SessionCatalog _catalog() => SessionCatalog({
      'pfmt_identify': _def('pfmt_identify', SessionType.kegel,
          title: 'Find the muscle'),
      'pfmt_functional': _def('pfmt_functional', SessionType.kegel,
          title: 'Wave holds'),
      'pfmt_identify_v2': _def('pfmt_identify_v2', SessionType.kegel,
          title: 'Cleaner contractions'),
      'breathwork_basics': _def('breathwork_basics', SessionType.breathwork,
          title: 'Calm breathing'),
    });

void main() {
  group('session lock', () {
    test('Foundation base tags + variants are free', () {
      expect(isSessionLocked('pfmt_identify', isPro: false), isFalse);
      expect(isSessionLocked('pfmt_identify_v3', isPro: false), isFalse);
      expect(isSessionLocked('breathwork_basics', isPro: false), isFalse);
    });

    test('non-Foundation sessions are Pro for free users', () {
      expect(isSessionLocked('pfmt_functional', isPro: false), isTrue);
      expect(isSessionLocked('stop_start', isPro: false), isTrue);
    });

    test('Pro users have nothing locked', () {
      expect(isSessionLocked('pfmt_functional', isPro: true), isFalse);
    });
  });

  group('grouping', () {
    test('free rows sort before Pro within a group', () {
      final groups = buildGroups(
        catalog: _catalog(),
        isPro: false,
        doneTags: {'pfmt_identify'},
      );
      final kegel = groups.firstWhere((g) => g.type == SessionType.kegel);
      // free first (pfmt_identify, pfmt_identify_v2), then locked (pfmt_functional)
      expect(kegel.rows.first.locked, isFalse);
      expect(kegel.rows.last.locked, isTrue);
      expect(kegel.rows.last.session.tag, 'pfmt_functional');
    });

    test('done-before mark comes from logs', () {
      final groups = buildGroups(
        catalog: _catalog(),
        isPro: false,
        doneTags: {'pfmt_identify'},
      );
      final kegel = groups.firstWhere((g) => g.type == SessionType.kegel);
      final find = kegel.rows.firstWhere((r) => r.session.tag == 'pfmt_identify');
      expect(find.doneBefore, isTrue);
    });

    test('context line uses a meaningful step, skips Settle', () {
      final groups = buildGroups(
        catalog: _catalog(),
        isPro: true,
        doneTags: const {},
      );
      final row = groups.first.rows.first;
      expect(row.context, contains('long holds'));
      expect(row.context, isNot(contains('settle')));
    });

    test('total session count', () {
      final groups = buildGroups(
          catalog: _catalog(), isPro: true, doneTags: const {});
      expect(totalSessions(groups), 4);
    });
  });

  group('search', () {
    test('matches titles case-insensitively, returns highlight span', () {
      final groups = buildGroups(
          catalog: _catalog(), isPro: true, doneTags: const {});
      final matches = searchLibrary(groups, 'hold');
      expect(matches, hasLength(1));
      expect(matches.first.row.session.title, 'Wave holds');
      final m = matches.first;
      expect(m.row.session.title.substring(m.start, m.end), 'hold');
    });

    test('empty query → no matches', () {
      final groups = buildGroups(
          catalog: _catalog(), isPro: true, doneTags: const {});
      expect(searchLibrary(groups, '  '), isEmpty);
    });

    test('no match → empty (sections disappear)', () {
      final groups = buildGroups(
          catalog: _catalog(), isPro: true, doneTags: const {});
      expect(searchLibrary(groups, 'zzzz'), isEmpty);
    });
  });

  test('completedTags collects session tags from logs', () {
    final logs = [
      SessionLog(
        id: '1',
        sessionTag: 'pfmt_identify',
        startedAt: DateTime(2026),
        completedAt: DateTime(2026),
        completionPct: 1,
        moodBefore: const [],
      ),
    ];
    expect(completedTags(logs), {'pfmt_identify'});
  });
}
