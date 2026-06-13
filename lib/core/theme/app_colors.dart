import 'package:flutter/material.dart';

/// Sahaj palette — Lamplight (docs/design spec Part A2, hexes per lamplight.css).
/// Warm brown darkness, ochre as lamplight. No red anywhere, including errors —
/// attention is carried by turmeric + explicit copy. No cool blues outside the
/// Book Mode cover.
class AppColors {
  AppColors._();

  // Light theme — the manuscript page (secondary)
  static const lightPrimary = Color(0xFFE8DDD0);
  static const lightOnPrimary = Color(0xFF2A211A);
  static const lightAccent = Color(0xFFA06F26); // ochre deepened for AA on paper
  static const lightOnAccent = Color(0xFFFFFBF3);
  static const lightBackground = Color(0xFFF6EFE3); // paper
  static const lightSurface = Color(0xFFFFFBF3);
  static const lightSurfaceVariant = Color(0xFFEFE6D6);
  static const lightOnSurface = Color(0xFF2A211A);
  static const lightOnSurfaceVariant = Color(0xFF6B5F4E);
  static const lightOutline = Color(0xFFD8CCB6);

  // Dark theme — default. The room at night.
  static const darkPrimary = Color(0xFF241D15); // surface
  static const darkOnPrimary = Color(0xFFEFE5D4); // ink
  static const darkAccent = Color(0xFFC9913F); // ochre — the lamplight
  static const darkOnAccent = Color(0xFF261B0B); // on-ochre
  static const darkBackground = Color(0xFF1A1510); // bg — warm brown-black
  static const darkSurface = Color(0xFF241D15);
  static const darkSurfaceVariant = Color(0xFF2D2519); // raised
  static const darkOnSurface = Color(0xFFEFE5D4);
  static const darkOnSurfaceVariant = Color(0xFFB9AC96); // inkMuted
  static const darkOutline = Color(0xFF342D24); // hairline flattened on surface

  // Semantic — moss is the only "good" color; turmeric carries all attention.
  static const success = Color(0xFF8FA882); // moss
  static const warning = Color(0xFFD8A03D); // turmeric
  static const error = Color(0xFFD8A03D); // turmeric — there is no red
  static const info = Color(0xFFD9C9A8); // sand
}

/// Lamplight token set beyond the Material scheme. Resolve via
/// `Theme.of(context).extension<LamplightTokens>()!` or the `context.lamp`
/// shortcut in app_theme.dart.
@immutable
class LamplightTokens extends ThemeExtension<LamplightTokens> {
  const LamplightTokens({
    required this.bg,
    required this.bg0,
    required this.deep,
    required this.deep0,
    required this.ember,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.faint,
    required this.hairline,
    required this.ochre,
    required this.gold,
    required this.onOchre,
    required this.moss,
    required this.mossDeep,
    required this.mossBright,
    required this.sand,
    required this.turmeric,
    required this.taupe,
    required this.wheat,
  });

  /// Standard screen background (top of the bg gradient).
  final Color bg;

  /// Bottom of the bg gradient.
  final Color bg0;

  /// "Deep room" background for player/completion (top).
  final Color deep;

  /// "Deep room" background (bottom).
  final Color deep0;

  /// Ember-mode ground — the darkest surface in the app.
  final Color ember;

  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;
  final Color faint;

  /// 8% ink — borders and dividers on dark.
  final Color hairline;

  final Color ochre;

  /// Bright end of the ochre gradient (text-on-dark ochre accents).
  final Color gold;

  /// Text/icon color on ochre fills.
  final Color onOchre;

  final Color moss;
  final Color mossDeep;

  /// Bright end of the moss gradient (text-on-dark moss accents).
  final Color mossBright;

  final Color sand;
  final Color turmeric;

  /// Session-type tint: sensate.
  final Color taupe;

  /// Session-type tint: mindset.
  final Color wheat;

  static const dark = LamplightTokens(
    bg: Color(0xFF1A1510),
    bg0: Color(0xFF14100C),
    deep: Color(0xFF13100C),
    deep0: Color(0xFF0F0C09),
    ember: Color(0xFF0B0907),
    surface: Color(0xFF241D15),
    surfaceRaised: Color(0xFF2D2519),
    ink: Color(0xFFEFE5D4),
    inkMuted: Color(0xFFB9AC96),
    faint: Color(0xFF8C8170),
    hairline: Color(0x14EDE3D2),
    ochre: Color(0xFFC9913F),
    gold: Color(0xFFE2AC57),
    onOchre: Color(0xFF261B0B),
    moss: Color(0xFF8FA882),
    mossDeep: Color(0xFF76906B),
    mossBright: Color(0xFFA9C29B),
    sand: Color(0xFFD9C9A8),
    turmeric: Color(0xFFD8A03D),
    taupe: Color(0xFFB59B7E),
    wheat: Color(0xFFA89A85),
  );

  /// Light theme keeps the same roles on paper. Deep/ember stay dark — the
  /// player is always the dark room regardless of theme.
  static const light = LamplightTokens(
    bg: Color(0xFFF6EFE3),
    bg0: Color(0xFFF0E7D8),
    deep: Color(0xFF13100C),
    deep0: Color(0xFF0F0C09),
    ember: Color(0xFF0B0907),
    surface: Color(0xFFFFFBF3),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF2A211A),
    inkMuted: Color(0xFF6B5F4E),
    faint: Color(0xFF94886F),
    hairline: Color(0x1F2A211A),
    ochre: Color(0xFFA06F26),
    gold: Color(0xFFA06F26),
    onOchre: Color(0xFFFFFBF3),
    moss: Color(0xFF6E8A60),
    mossDeep: Color(0xFF5C7450),
    mossBright: Color(0xFF6E8A60),
    sand: Color(0xFFB5A176),
    turmeric: Color(0xFFB07F23),
    taupe: Color(0xFF96795A),
    wheat: Color(0xFF867A63),
  );

  @override
  LamplightTokens copyWith() => this;

  @override
  LamplightTokens lerp(LamplightTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

ColorScheme buildLightScheme() => const ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.lightAccent,
  onPrimary: AppColors.lightOnAccent,
  secondary: AppColors.lightPrimary,
  onSecondary: AppColors.lightOnPrimary,
  error: AppColors.error,
  onError: Color(0xFF2A211A),
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
  onError: Color(0xFF261B0B),
  surface: AppColors.darkBackground,
  onSurface: AppColors.darkOnSurface,
  surfaceContainerHighest: AppColors.darkSurfaceVariant,
  onSurfaceVariant: AppColors.darkOnSurfaceVariant,
  outline: AppColors.darkOutline,
);
