import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart' show LamplightTokens;

/// Shortcut: `context.lamp.ochre` etc. Falls back to the dark token set when
/// the theme has no extension (bare-MaterialApp widget tests).
extension LamplightContext on BuildContext {
  LamplightTokens get lamp =>
      Theme.of(this).extension<LamplightTokens>() ??
      (Theme.of(this).brightness == Brightness.light
          ? LamplightTokens.light
          : LamplightTokens.dark);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() =>
      _buildTheme(buildLightScheme(), LamplightTokens.light);
  static ThemeData dark() => _buildTheme(buildDarkScheme(), LamplightTokens.dark);

  static ThemeData _buildTheme(ColorScheme scheme, LamplightTokens lamp) {
    final textTheme = AppTypography.buildTextTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [lamp],
      scaffoldBackgroundColor: lamp.bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: lamp.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: lamp.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: lamp.ink,
          side: BorderSide(color: lamp.sand.withValues(alpha: 0.32)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: lamp.inkMuted,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lamp.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: lamp.faint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: lamp.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: lamp.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        // Validation is turmeric + a specific line, never red (Part J).
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: lamp.turmeric, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: lamp.turmeric, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lamp.hairline,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lamp.surfaceRaised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
