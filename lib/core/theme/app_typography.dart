import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme(ColorScheme scheme) {
    final display = GoogleFonts.fraunces(color: scheme.onSurface);
    final body = GoogleFonts.manrope(color: scheme.onSurface);

    return TextTheme(
      displayLarge: display.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      displayMedium: display.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      displaySmall: display.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      headlineLarge: display.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      headlineMedium: display.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      headlineSmall: display.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      titleLarge: body.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: body.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      titleSmall: body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      bodyLarge: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodySmall: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      labelSmall: body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.3,
      ),
    );
  }
}
