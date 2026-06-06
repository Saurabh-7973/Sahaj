import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../library/library_catalog.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
import '../../sessions/session_catalog.dart';

/// Library tab - browse every catalog session by category and practise any of
/// them freely. Free practice logs activity but does not advance the plan day.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    SessionCatalog? catalog;
    try {
      catalog = ref.watch(sessionCatalogProvider);
    } catch (_) {
      catalog = null;
    }
    final groups = catalog == null ? const <LibraryGroup>[] : groupLibrary(catalog);

    return AppScaffold(
      title: 'Library',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practise any session, any time. Practice does not change your daily plan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (groups.isEmpty)
            AppCard(
              child: Text('Sessions will appear here.',
                  style: theme.textTheme.bodyMedium),
            ),
          for (final group in groups) ...[
            Text(group.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final session in group.sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => _practise(context, ref, session),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session.title,
                                style: theme.textTheme.titleSmall),
                            Text(
                              '${session.type.name} - ~${(session.totalSeconds / 60).ceil()} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_outline),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Future<void> _practise(
    BuildContext context,
    WidgetRef ref,
    SessionDef session,
  ) async {
    final startedAt = DateTime.now();
    var completion = 0.0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPlayerPage(
          session: session,
          onComplete: (pct) {
            completion = pct;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (completion == 0.0 || !context.mounted) return;

    ref.read(progressControllerProvider).logPractice(
          SessionLog(
            id: startedAt.microsecondsSinceEpoch.toString(),
            sessionTag: session.tag,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            completionPct: completion,
            moodBefore: const [],
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nice work.')),
      );
    }
  }
}
