import 'package:flutter/material.dart';

/// Lamplight type system (design spec Part A3). Fraunces for display/H1/H2 and
/// numerals only; Manrope for everything else. Both bundled in assets/fonts —
/// no network fetch, true to the no-cloud promise.
class AppTypography {
  AppTypography._();

  static const display = 'Fraunces';
  static const body = 'Manrope';

  /// Live countdowns must not jitter.
  static const tabular = [FontFeature.tabularFigures()];

  static TextTheme buildTextTheme(ColorScheme scheme) {
    final ink = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return TextTheme(
      // Display numerals — timer, big stats. Fraunces Light, tabular.
      displayLarge: TextStyle(
        fontFamily: display,
        fontSize: 72,
        fontWeight: FontWeight.w300,
        height: 1.0,
        letterSpacing: -0.7,
        fontFeatures: tabular,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontFamily: display,
        fontSize: 64,
        fontWeight: FontWeight.w300,
        height: 1.0,
        letterSpacing: -0.6,
        fontFeatures: tabular,
        color: ink,
      ),
      // H1 — Fraunces SemiBold (mock: 31/38, -0.4).
      displaySmall: TextStyle(
        fontFamily: display,
        fontSize: 31,
        fontWeight: FontWeight.w600,
        height: 38 / 31,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineLarge: TextStyle(
        fontFamily: display,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 32 / 26,
        letterSpacing: -0.2,
        color: ink,
      ),
      // H2 — Fraunces Medium 22/28.
      headlineMedium: TextStyle(
        fontFamily: display,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 28 / 22,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: display,
        fontSize: 19,
        fontWeight: FontWeight.w500,
        height: 25 / 19,
        color: ink,
      ),
      // Title — Manrope (mock: 17.5/23 w700).
      titleLarge: TextStyle(
        fontFamily: body,
        fontSize: 17.5,
        fontWeight: FontWeight.w700,
        height: 23 / 17.5,
        letterSpacing: -0.1,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: ink,
      ),
      // Body — Manrope (mock: 15.5/23 w500).
      bodyLarge: TextStyle(
        fontFamily: body,
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
        height: 23 / 15.5,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: body,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: ink,
      ),
      // Caption.
      bodySmall: TextStyle(
        fontFamily: body,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 17 / 12,
        color: muted,
      ),
      // Label — sentence case, never ALL CAPS (except the eyebrow style below).
      labelLarge: TextStyle(
        fontFamily: body,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 0.15,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 16 / 13,
        letterSpacing: 0.1,
        color: ink,
      ),
      labelSmall: TextStyle(
        fontFamily: body,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        height: 15 / 10.5,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }

  // ---- Styles outside the Material slots (mock classes) ----

  /// `.eyebrow` — tiny tracked-out uppercase kicker. Pass the accent color.
  static TextStyle eyebrow(Color color) => TextStyle(
    fontFamily: body,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 2.0,
    color: color,
  );

  /// `.num` — Fraunces Light tabular numeral at any size (ring countdown 74).
  static TextStyle numeral(double size, Color color) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: size * -0.01,
    fontFeatures: tabular,
    color: color,
  );

  /// `.it` — Fraunces italic (echo line, breath word, pull quotes).
  static TextStyle italic(double size, Color color, {double? height}) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: height,
        color: color,
      );

  /// `.phase` — ring phase word: 11px, very wide tracking, uppercase source.
  static TextStyle phase(Color color) => TextStyle(
    fontFamily: body,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: 3.7,
    color: color,
  );

  /// `.timeleft` — the tiny session time-remaining line.
  static TextStyle timeLeft(Color color) => TextStyle(
    fontFamily: body,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.9,
    color: color,
  );

  /// Reader body — article screens only (17/27).
  static TextStyle reader(Color color) => TextStyle(
    fontFamily: body,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 27.5 / 17,
    color: color,
  );
}
