import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The notification seam. UI and coordinator depend on this, not on
/// flutter_local_notifications directly, so tests use a fake and the pure
/// logic layer never touches platform channels.
abstract class NotificationService {
  /// One-time setup (timezone, plugin init, channel). Safe to call repeatedly.
  Future<void> init();

  /// Ask the OS for permission to post notifications (Android 13+ / iOS).
  /// Returns true if granted.
  Future<bool> requestPermission();

  /// Schedule (or replace) the single daily reminder at [hour]:[minute].
  /// When [skipToday] is true the first fire is pushed to tomorrow — used
  /// after a session completes so a man who already trained today isn't
  /// reminded (M8 §0 suppression).
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool skipToday = false,
  });

  /// Cancel the daily reminder.
  Future<void> cancelReminder();

  /// If the app was cold-started by tapping a notification, returns its payload
  /// once (then clears it). Null otherwise. Lets the app route / log the open.
  String? consumeLaunchPayload();
}

/// Default no-op — used in tests and any un-overridden read, so nothing
/// reaches the platform unless explicitly wired in main().
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool skipToday = false,
  }) async {}

  @override
  Future<void> cancelReminder() async {}

  @override
  String? consumeLaunchPayload() => null;
}

/// Overridden in main() with LocalNotificationService.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => const NoopNotificationService());
