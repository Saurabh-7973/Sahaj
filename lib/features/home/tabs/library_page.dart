import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

/// Library tab — exercises, breathwork, education (populated in later phases).
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Library',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercises, breathwork, and education live here.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                AppListTile(
                  leadingIcon: Icons.fitness_center_outlined,
                  title: 'Pelvic floor exercises',
                  subtitle: 'Kegel, reverse Kegel, elevator, pulse',
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.air_outlined,
                  title: 'Breathwork',
                  subtitle: '4-7-8, box breathing, sensate prep',
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.school_outlined,
                  title: 'Education',
                  subtitle: 'Anatomy, the brain-erection connection',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
