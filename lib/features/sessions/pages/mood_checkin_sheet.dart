import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../checkin_moods.dart';

/// Shows the pre-session mood sheet. Returns the selected mood keys (1-3),
/// or null if the user dismissed it (start aborted).
Future<List<String>?> showMoodCheckin(BuildContext context) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _MoodCheckinSheet(),
  );
}

class _MoodCheckinSheet extends StatefulWidget {
  const _MoodCheckinSheet();

  @override
  State<_MoodCheckinSheet> createState() => _MoodCheckinSheetState();
}

class _MoodCheckinSheetState extends State<_MoodCheckinSheet> {
  final _selected = <String>{};

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else if (_selected.length < 3) {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you arriving?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Pick up to three.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final mood in kCheckinMoods)
                FilterChip(
                  label: Text(mood.label),
                  selected: _selected.contains(mood.key),
                  onSelected: (_) => _toggle(mood.key),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Begin session',
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected.toList()),
          ),
        ],
      ),
    );
  }
}
