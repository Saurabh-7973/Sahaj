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
  Future<void> scheduleDailyReminder({required int hour, required int minute});

  /// Cancel the daily reminder.
  Future<void> cancelReminder();
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
  }) async {}

  @override
  Future<void> cancelReminder() async {}
}

/// Overridden in main() with LocalNotificationService.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => const NoopNotificationService());
