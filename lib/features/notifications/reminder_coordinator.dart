import 'notification_service.dart';

/// Applies a reminder preference to the platform: schedules when enabled and
/// permission is granted, cancels otherwise. Returns whether the reminder is
/// actually active afterwards, so the UI can revert its toggle if the OS
/// denied permission. Assumes [NotificationService.init] already ran in main().
Future<bool> applyReminderSetting({
  required NotificationService service,
  required bool enabled,
  required int hour,
  required int minute,
}) async {
  if (!enabled) {
    await service.cancelReminder();
    return false;
  }
  final granted = await service.requestPermission();
  if (!granted) return false;
  await service.scheduleDailyReminder(hour: hour, minute: minute);
  return true;
}
