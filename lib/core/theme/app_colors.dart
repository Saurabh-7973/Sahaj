import 'package:flutter/material.dart';

/// Sahaj palette — warm neutrals + muted accents.
/// No pure reds. No aggressive blues. Calm and intentional in dark mode.
class AppColors {
  AppColors._();

  // Light theme
  static const lightPrimary = Color(0xFFE8DDD0); // warm sand
  static const lightOnPrimary = Color(0xFF2A2520);
  static const lightAccent = Color(0xFF4A5D3F); // deep moss
  static const lightOnAccent = Color(0xFFF5F1EB);
  static const lightBackground = Color(0xFFF8F4EE); // cream
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFEFE8DC);
  static const lightOnSurface = Color(0xFF2A2520);
  static const lightOnSurfaceVariant = Color(0xFF6B5F52);
  static const lightOutline = Color(0xFFD4C9B8);

  // Dark theme — default per roadmap
  static const darkPrimary = Color(0xFF2A2520);
  static const darkOnPrimary = Color(0xFFE8DDD0);
  static const darkAccent = Color(0xFFC9A961); // muted ochre
  static const darkOnAccent = Color(0xFF1F1B16);
  static const darkBackground = Color(0xFF15120E);
  static const darkSurface = Color(0xFF1F1B16);
  static const darkSurfaceVariant = Color(0xFF2A2520);
  static const darkOnSurface = Color(0xFFE8DDD0);
  static const darkOnSurfaceVariant = Color(0xFFA89B8A);
  static const darkOutline = Color(0xFF3D362D);

  // Semantic — muted, never pure red
  static const success = Color(0xFF6B8E5A);
  static const warning = Color(0xFFC49A4A);
  static const error = Color(0xFFB55A48); // muted terracotta, not pure red
  static const info = Color(0xFF6B8499);
}

ColorScheme buildLightScheme() => const ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.lightAccent,
  onPrimary: AppColors.lightOnAccent,
  secondary: AppColors.lightPrimary,
  onSecondary: AppColors.lightOnPrimary,
  error: AppColors.error,
  onError: Colors.white,
  surface: AppColors.lightSurface,
  onSurface: AppColors.lightOnSurface,
  surfaceContainerHighest: AppColors.lightSurfaceVariant,
  onSurfaceVariant: AppColors.lightOnSurfaceVariant,
  outline: AppColors.lightOutline,
);

ColorScheme buildDarkScheme() => const ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.darkAccent,
  onPrimary: AppColors.darkOnAccent,
  secondary: AppColors.darkPrimary,
  onSecondary: AppColors.darkOnPrimary,
  error: AppColors.error,
  onError: Colors.white,
  surface: AppColors.darkSurface,
  onSurface: AppColors.darkOnSurface,
  surfaceContainerHighest: AppColors.darkSurfaceVariant,
  onSurfaceVariant: AppColors.darkOnSurfaceVariant,
  outline: AppColors.darkOutline,
);
