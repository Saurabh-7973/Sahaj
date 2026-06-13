import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../shared/widgets/widgets.dart';

/// Visual review surface for the Sahaj design system.
/// Not shipped — wired as home during Phase 1 to eyeball widgets on device.
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  final _mood = <ArrivalMood>{ArrivalMood.level};
  bool _loading = false;
  double _progress = 0.65;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Design System',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(theme, 'Buttons'),
          AppButton(label: 'Filled action', onPressed: () {}),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Outlined action',
            variant: AppButtonVariant.outlined,
            icon: Icons.bolt_outlined,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Text action',
            variant: AppButtonVariant.text,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _loading ? 'Working' : 'Tap to load',
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _loading = false);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const AppButton(label: 'Disabled', onPressed: null),

          _section(theme, 'Card'),
          AppCard(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tappable card', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Surface container with calm radius and ink response.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          _section(theme, 'Mood selector'),
          AppMoodSelector(
            selected: _mood,
            onToggle: (m) => setState(
              () => _mood.contains(m) ? _mood.remove(m) : _mood.add(m),
            ),
          ),

          _section(theme, 'Progress ring'),
          Center(
            child: AppProgressRing(
              value: _progress,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_progress * 100).round()}%',
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text('streak', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _progress,
            onChanged: (v) => setState(() => _progress = v),
          ),

          _section(theme, 'Text field'),
          const AppTextField(
            label: 'Name',
            hint: 'What should we call you?',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Password',
            hint: '••••••••',
            obscureText: true,
            errorText: 'Too short',
          ),

          _section(theme, 'List tiles'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                AppListTile(
                  leadingIcon: Icons.self_improvement_outlined,
                  title: 'Daily practice',
                  subtitle: 'Steady, every day',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.insights_outlined,
                  title: 'Progress',
                  subtitle: 'See your streak',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.lg,
      ),
      child: Text(title, style: theme.textTheme.headlineSmall),
    );
  }
}
