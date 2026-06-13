import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// B2 `DialCard` — crisis screen. Full-width, ≥64dp, moss-tinted phone glyph,
/// name + availability + tap-to-dial. The largest tap targets in the app.
class DialCard extends StatelessWidget {
  const DialCard({
    super.key,
    required this.name,
    required this.availability,
    required this.onCall,
  });

  final String name;
  final String availability;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Call $name. $availability.',
      child: InkWell(
        onTap: onCall,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E2619), Color(0xFF241E15)],
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: lamp.moss.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lamp.moss.withValues(alpha: 0.2),
                      lamp.moss.withValues(alpha: 0.07),
                    ],
                  ),
                  border: Border.all(color: lamp.moss.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.call_outlined, size: 20, color: lamp.mossBright),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(availability, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: lamp.moss.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: lamp.moss.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Call',
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: lamp.mossBright,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
