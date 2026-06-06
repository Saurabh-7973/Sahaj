import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import 'preferences_controller.dart';

/// When Book Mode is on, shows a plain reading disguise over the app until a
/// discreet double-tap dismisses it for this launch. The native app icon/name
/// swap is deferred; this is the in-app half of the disguise (synthesis section 9).
class BookModeCover extends ConsumerStatefulWidget {
  const BookModeCover({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BookModeCover> createState() => _BookModeCoverState();
}

class _BookModeCoverState extends ConsumerState<BookModeCover> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final bookMode = ref.watch(preferencesControllerProvider).bookMode;
    if (!bookMode || _dismissed) return widget.child;

    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onDoubleTap: () => setState(() => _dismissed = true),
        child: Container(
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text('My Notes', style: theme.textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.lg),
                  for (final title in const [
                    'Reading list',
                    'Weekly reflections',
                    'Ideas',
                    'To revisit',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.article_outlined),
                          const SizedBox(width: AppSpacing.lg),
                          Text(title, style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text('Double-tap anywhere to open',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
