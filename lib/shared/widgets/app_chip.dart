import 'package:flutter/material.dart';

import '../../core/theme/app_background.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Chip color roles (mock `.chip` variants).
enum AppChipVariant {
  /// Sand neutral — duration, info.
  neutral,

  /// Moss — done/positive ("gentler tonight", "haptics on").
  ok,

  /// Turmeric — attention without alarm.
  warn,
}

/// Small pill chip. For session types use [AppChip.type] — the tint appears
/// on type chips and the ring stroke only (A2).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.neutral,
    this.tint,
  });

  /// Session-type chip carrying the type tint.
  const AppChip.type({super.key, required String typeName, required this.label})
      : variant = AppChipVariant.neutral,
        tint = typeName;

  final String label;
  final AppChipVariant variant;

  /// SessionType.name when this is a type chip.
  final String? tint;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final color = tint != null
        ? sessionTypeTint(lamp, tint!)
        : switch (variant) {
            AppChipVariant.neutral => lamp.sand,
            AppChipVariant.ok => lamp.mossBright,
            AppChipVariant.warn => lamp.turmeric,
          };
    final borderAlpha = switch (variant) {
      _ when tint != null => 0.40,
      AppChipVariant.neutral => 0.16,
      _ => 0.40,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tint != null ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
          color: color,
        ),
      ),
    );
  }
}
