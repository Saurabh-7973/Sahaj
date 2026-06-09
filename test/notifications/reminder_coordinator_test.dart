import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/notifications/notification_service.dart';
import 'package:sahaj/features/notifications/reminder_coordinator.dart';

/// Records calls so we can assert the coordinator's behaviour.
class FakeNotificationService implements NotificationService {
  bool permissionGranted = true;
  final List<String> calls = [];
  int? scheduledHour;
  int? scheduledMinute;

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return permissionGranted;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    calls.add('schedule');
    scheduledHour = hour;
    scheduledMinute = minute;
  }

  @override
  Future<void> cancelReminder() async => calls.add('cancel');

  @override
  String? consumeLaunchPayload() => null;
}

void main() {
  test('disabling cancels and never asks permission', () async {
    final svc = FakeNotificationService();
    final active = await applyReminderSetting(
      service: svc,
      enabled: false,
      hour: 20,
      minute: 0,
    );
    expect(active, isFalse);
    expect(svc.calls, ['cancel']);
  });

  test('enabling with permission schedules at the chosen time', () async {
    final svc = FakeNotificationService()..permissionGranted = true;
    final active = await applyReminderSetting(
      service: svc,
      enabled: true,
      hour: 21,
      minute: 30,
    );
    expect(active, isTrue);
    expect(svc.calls, ['requestPermission', 'schedule']);
    expect(svc.scheduledHour, 21);
    expect(svc.scheduledMinute, 30);
  });

  test('enabling without permission does not schedule and reports inactive', () async {
    final svc = FakeNotificationService()..permissionGranted = false;
    final active = await applyReminderSetting(
      service: svc,
      enabled: true,
      hour: 20,
      minute: 0,
    );
    expect(active, isFalse);
    expect(svc.calls, ['requestPermission']);
  });
}
