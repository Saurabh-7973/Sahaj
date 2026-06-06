import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/models/session_models.dart';

/// Result returned to the caller when the user confirms their reflection.
class ReflectionResult {
  const ReflectionResult({required this.difficulty, this.note});
  final PerceivedDifficulty difficulty;
  final String? note;
}

/// Post-session reflection. Pops with a [ReflectionResult] on confirm.
class ReflectionPage extends StatefulWidget {
  const ReflectionPage({
    super.key,
    required this.sessionTitle,
    this.tomorrowPreview,
  });

  final String sessionTitle;
  final String? tomorrowPreview;

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  PerceivedDifficulty? _difficulty;
  final _noteController = TextEditingController();
  bool _noteRevealed = false;

  static const _labels = {
    PerceivedDifficulty.easier: 'Easier',
    PerceivedDifficulty.same: 'About the same',
    PerceivedDifficulty.harder: 'Harder',
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Reflection',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How did that feel?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          for (final d in PerceivedDifficulty.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                color: _difficulty == d
                    ? theme.colorScheme.primaryContainer
                    : null,
                onTap: () => setState(() => _difficulty = d),
                child: Text(_labels[d]!, style: theme.textTheme.titleMedium),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('A note, if you want (private)',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            children: [
              AppTextField(
                controller: _noteController,
                hint: 'Anything you noticed...',
                maxLines: 3,
              ),
              if (!_noteRevealed)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _noteRevealed = true),
                        child: Container(
                          color: theme.colorScheme.surface.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Text('Tap to write',
                              style: theme.textTheme.labelMedium),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.tomorrowPreview != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Tomorrow', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.tomorrowPreview!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: 'Done',
            onPressed: _difficulty == null
                ? null
                : () => Navigator.of(context).pop(
                      ReflectionResult(
                        difficulty: _difficulty!,
                        note: _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
