import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'logic/reminder_schedule.dart';
import 'notification_service.dart';

/// Real notification backend (flutter_local_notifications + timezone).
/// Wired only in main(); everything else depends on the [NotificationService]
/// seam so tests and pure logic stay platform-free.
///
/// Uses EXACT alarms so the reminder fires at the picked minute instead of
/// being deferred for hours by Doze. Inexact scheduling was unreliable on real
/// OEM devices (Samsung/Xiaomi). Pairs with SCHEDULE_EXACT_ALARM +
/// requestExactAlarmsPermission() and a battery-optimisation exemption prompt;
/// the plugin gracefully demotes to inexact if exact is denied.
class LocalNotificationService implements NotificationService {
  static const int _reminderId = 1001;
  static const String _channelId = 'daily_reminder';
  // White lotus silhouette (res/drawable/ic_notification.xml); muted-ochre tint
  // for the expanded notification, matching the in-app accent.
  static const String _icon = 'ic_notification';
  static const Color _accent = Color(0xFFC9A961);
  static const String _payload = 'today'; // where a tap should land

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _launchPayload;

  @override
  String? consumeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));

    const android = AndroidInitializationSettings(_icon);
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (r) => _launchPayload = r.payload,
    );

    // Cold start: if the app was launched by tapping the notification, the
    // response callback above doesn't fire — capture the payload here instead.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchPayload = launch?.notificationResponse?.payload ?? _payload;
    }

    // Create the channel up front so it appears in OS notification settings.
    // Default importance keeps the nudge calm (no heads-up interrupt).
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Daily reminder',
        description: 'A gentle daily nudge to train.',
        importance: Importance.defaultImportance,
      ),
    );

    _ready = true;
  }

  /// Guards against two permission flows requesting concurrently.
  bool _permissionInFlight = false;

  @override
  Future<bool> requestPermission() async {
    if (_permissionInFlight) return false;
    _permissionInFlight = true;
    try {
      final granted = await _android?.requestNotificationsPermission() ?? false;

      // Exact-alarm permission (Android 12+) so exactAllowWhileIdle fires on
      // time instead of being demoted to inexact. No-op / Settings route on 14+.
      try {
        await _android?.requestExactAlarmsPermission();
      } catch (_) {/* not fatal — falls back to inexact */}

      // OEM battery managers (MIUI/One UI/ColorOS) suppress alarms unless the
      // app is exempt from battery optimisation. Necessary on top of the
      // exact-alarm permission, which alone doesn't survive OEM Doze.
      try {
        if (await Permission.ignoreBatteryOptimizations.status !=
            PermissionStatus.granted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (_) {/* best effort */}

      return granted;
    } finally {
      _permissionInFlight = false;
    }
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
        icon: _icon,
        color: _accent,
      ),
    );

    // Try exact first; if the OS denies exact-alarm permission (Android 14+
    // can revoke it) the plugin throws — fall back to inexact so the reminder
    // still schedules and, critically, launch never crashes.
    try {
      await _schedule(scheduled, details, AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await _schedule(scheduled, details, AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _schedule(
    tz.TZDateTime when,
    NotificationDetails details,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      _reminderId,
      'Sahaj',
      'A few quiet minutes for yourself today.',
      when,
      details,
      payload: _payload,
      androidScheduleMode: mode,
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
