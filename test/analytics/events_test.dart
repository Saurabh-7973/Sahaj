import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/events.dart';

import '../support/fake_analytics.dart';

void main() {
  test('sessionStarted logs name + params', () {
    final fake = FakeAnalytics();
    AppEvents(fake).sessionStarted('kegel', 2, 3);
    final e = fake.last('session_started')!;
    expect(e.params, {'sessionType': 'kegel', 'week': 2, 'day': 3});
  });

  test('goalSelected joins the goals list to a comma string', () {
    final fake = FakeAnalytics();
    AppEvents(fake).goalSelected(['control', 'erections']);
    expect(fake.last('goal_selected')!.params,
        {'goals': 'control,erections'});
  });

  test('planGenerated carries persona + goalCount', () {
    final fake = FakeAnalytics();
    AppEvents(fake).planGenerated('singleInexperienced', 2);
    expect(fake.last('plan_generated')!.params,
        {'persona': 'singleInexperienced', 'goalCount': 2});
  });

  test('moodCheckin joins moods; sessionCompleted carries pct', () {
    final fake = FakeAnalytics();
    AppEvents(fake)
      ..moodCheckin(['calm', 'hopeful'])
      ..sessionCompleted('breathwork', 1.0);
    expect(fake.last('mood_checkin_completed')!.params, {'moods': 'calm,hopeful'});
    expect(fake.last('session_completed')!.params,
        {'sessionType': 'breathwork', 'completionPct': 1.0});
  });

  test('parameterless events log just the name', () {
    final fake = FakeAnalytics();
    AppEvents(fake)
      ..appOpened()
      ..onboardingCompleted()
      ..accountDeleted();
    expect(fake.last('app_opened')!.params, isNull);
    expect(fake.last('onboarding_completed')!.params, isNull);
    expect(fake.last('account_deleted')!.params, isNull);
  });

  test('redFlagFired carries flagType', () {
    final fake = FakeAnalytics();
    AppEvents(fake).redFlagFired('cardiac');
    expect(fake.last('health_screen_red_flag_fired')!.params,
        {'flagType': 'cardiac'});
  });
}
