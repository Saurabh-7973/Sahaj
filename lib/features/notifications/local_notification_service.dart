import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'logic/reminder_schedule.dart';
import 'notification_service.dart';

/// Real notification backend (flutter_local_notifications + timezone).
/// Wired only in main(); everything else depends on the [NotificationService]
/// seam so tests and pure logic stay platform-free.
///
/// Uses inexact scheduling so the app needs no SCHEDULE_EXACT_ALARM permission
/// — a daily wellness nudge does not need to-the-second precision, and inexact
/// alarms are friendlier to OEM battery managers.
class LocalNotificationService implements NotificationService {
  static const int _reminderId = 1001;
  static const String _channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    final next =
        nextReminderTime(hour: hour, minute: minute, now: DateTime.now());
    final scheduled = tz.TZDateTime.from(next, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Daily reminder',
        channelDescription: 'A gentle daily nudge to train.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.zonedSchedule(
      _reminderId,
      'Sahaj',
      'A few quiet minutes for yourself today.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelReminder() async {
    await _plugin.cancel(_reminderId);
  }
}
