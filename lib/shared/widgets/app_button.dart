import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant {
  /// Ochre-gradient primary (`.btn.fill`).
  filled,

  /// Moss-gradient — done/breath contexts (`.btn.mossy`).
  moss,

  /// Sand hairline outline (`.btn.line`). Also the destructive dress:
  /// explicit verb, never a hue change.
  outlined,

  /// Quiet text action (`.btn.ghost`).
  text,
}

/// Sahaj primary action button. Calm press feedback (0.98 @100ms),
/// optional leading icon, loading state. Disabled = 42% opacity, no shadow.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  /// Overrides the variant's default height (e.g. the 52dp Today Start).
  final double? height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.loading;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);

    final (Color fg, Gradient? gradient, Color? borderColor, Color? shadow) =
        switch (widget.variant) {
      AppButtonVariant.filled => (
          lamp.onOchre,
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lamp.gold, const Color(0xFFBA8030)],
          ),
          null,
          lamp.ochre.withValues(alpha: 0.55),
        ),
      AppButtonVariant.moss => (
          const Color(0xFF16200F),
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9CB48E), Color(0xFF71895F)],
          ),
          null,
          lamp.moss.withValues(alpha: 0.45),
        ),
      AppButtonVariant.outlined => (
          lamp.ink,
          null,
          lamp.sand.withValues(alpha: 0.32),
          null,
        ),
      AppButtonVariant.text => (lamp.inkMuted, null, null, null),
    };

    final height = widget.height ??
        switch (widget.variant) {
          AppButtonVariant.filled || AppButtonVariant.moss => 56.0,
          AppButtonVariant.outlined => 54.0,
          AppButtonVariant.text => 48.0,
        };

    final content = AnimatedSwitcher(
      duration: AppMotion.quick,
      child: widget.loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
    );

    final box = AnimatedOpacity(
      duration: AppMotion.quick,
      opacity: _disabled ? AppMotion.dimmedOpacity : 1.0,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          color: widget.variant == AppButtonVariant.outlined
              ? lamp.ink.withValues(alpha: 0.04)
              : null,
          boxShadow: shadow != null && !_disabled
              ? [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 36,
                    spreadRadius: -14,
                    offset: const Offset(0, 18),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: GestureDetector(
        onTap: _disabled ? null : widget.onPressed,
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressedScale : 1.0,
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          child: widget.expand
              ? SizedBox(width: double.infinity, child: box)
              : box,
        ),
      ),
    );
  }
}
