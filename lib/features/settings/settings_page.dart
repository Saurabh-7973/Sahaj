import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/events.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_coordinator.dart';
import '../onboarding/onboarding_controller.dart';
import '../onboarding/widgets/selectable_option.dart';
import '../sessions/progress_controller.dart';
import 'account.dart';
import 'logic/data_export.dart';
import 'preferences_controller.dart';

/// Privacy + settings (synthesis section 9 / 210). Reached from the Me tab.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _disguiseLabels = {
    DisguiseName.none: 'No disguise',
    DisguiseName.calendar: 'Calendar',
    DisguiseName.notes: 'Notes',
    DisguiseName.wellness: 'Wellness',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboarding = ref.watch(onboardingControllerProvider);
    final prefs = ref.watch(preferencesControllerProvider);

    return AppScaffold(
      title: 'Settings',
      leading: const BackButton(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lock', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Biometric lock'),
              subtitle: const Text('Require fingerprint/face to open Sahaj'),
              value: onboarding.biometricLock,
                      onChanged: (v) {
                ref.read(onboardingControllerProvider).setBiometricLock(v);
                if (v) ref.read(appEventsProvider).biometricLockEnabled();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Disguise', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Book Mode'),
              subtitle: const Text(
                  'Open into a plain reading screen; double-tap to reveal'),
              value: prefs.bookMode,
              onChanged: (v) =>
                  ref.read(preferencesControllerProvider).setBookMode(v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('App name on the home screen',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final d in DisguiseName.values)
            SelectableOption(
              label: _disguiseLabels[d]!,
              selected: prefs.disguiseName == d,
              onTap: () =>
                  ref.read(preferencesControllerProvider).setDisguiseName(d),
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Renaming the icon arrives in a later update.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Reminders', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reminder'),
              subtitle: const Text('A gentle nudge at a time you choose.'),
              value: prefs.notificationsEnabled,
              onChanged: (v) async {
                ref
                    .read(preferencesControllerProvider)
                    .setNotificationsEnabled(v);
                await _applyReminder(ref);
              },
            ),
          ),
          if (prefs.notificationsEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder time'),
                trailing: Text(
                  TimeOfDay(
                    hour: prefs.reminderHour,
                    minute: prefs.reminderMinute,
                  ).format(context),
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () => _pickTime(context, ref),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Progress', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hide streak'),
              subtitle: const Text(
                  'Remove the streak counter. Progress is yours, not a scoreboard.'),
              value: prefs.hideStreak,
              onChanged: (v) =>
                  ref.read(preferencesControllerProvider).setHideStreak(v),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Your data', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Export my data',
            variant: AppButtonVariant.outlined,
            onPressed: () => _export(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Delete everything',
            variant: AppButtonVariant.text,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  /// Push the current reminder preference to the OS. If the user enabled it but
  /// the OS denied permission, revert the toggle so the UI reflects reality.
  Future<void> _applyReminder(WidgetRef ref) async {
    final prefs = ref.read(preferencesControllerProvider);
    final active = await applyReminderSetting(
      service: ref.read(notificationServiceProvider),
      enabled: prefs.notificationsEnabled,
      hour: prefs.reminderHour,
      minute: prefs.reminderMinute,
    );
    if (prefs.notificationsEnabled && !active) {
      prefs.setNotificationsEnabled(false);
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(preferencesControllerProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute),
    );
    if (picked == null) return;
    prefs.setReminderTime(picked.hour, picked.minute);
    await _applyReminder(ref);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final onboarding = ref.read(onboardingControllerProvider);
    final progress = ref.read(progressControllerProvider);
    final prefs = ref.read(preferencesControllerProvider);
    final json = assembleExportJson(
      onboarding: onboarding.toJson(),
      progress: progress.state.toJson(),
      logs: progress.logs().map((l) => l.toJson()).toList(),
      preferences: prefs.toJson(),
      exportedAt: DateTime.now(),
    );
    ref.read(appEventsProvider).dataExported();
    await Share.share(json, subject: 'My Sahaj data');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
            'This permanently removes your plan, progress, logs, and settings '
            'from this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(appEventsProvider).accountDeleted();
    wipeAllData(
      onboarding: ref.read(onboardingControllerProvider),
      progress: ref.read(progressControllerProvider),
      preferences: ref.read(preferencesControllerProvider),
    );
    if (context.mounted) context.go(Routes.onboarding);
  }
}
