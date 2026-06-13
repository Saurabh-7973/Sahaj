import 'package:flutter/animation.dart';

/// Calm motion (design spec A6). No bouncy or overshooting curves, ever.
/// 100 press · 200 selection · 400 transitions/crossfades · 700 ceremonial.
class AppMotion {
  AppMotion._();

  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration settle = Duration(milliseconds: 400);
  static const Duration calm = Duration(milliseconds: 700);

  // Curves — entrance, transition, exit
  static const Curve enter = Curves.easeOutCubic;
  static const Curve transition = Curves.easeInOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// Breath pacing is a sine — symmetric inhale/exhale, no easing corners.
  static const Curve breath = Curves.easeInOutSine;

  // Fixed motion values
  /// Press feedback scale @100ms.
  static const double pressedScale = 0.98;

  /// Breathing ring scale range (A6): 0.86 ↔ 1.00 on the step's pacing.
  static const double breathScaleMin = 0.86;
  static const double breathScaleMax = 1.00;

  /// Reduced-motion swap: breath scale becomes an opacity pulse 70 ↔ 100%.
  static const double breathOpacityMin = 0.70;
  static const double breathOpacityMax = 1.00;

  /// Paused-state recession — chrome and ring drop to 42%.
  static const double dimmedOpacity = 0.42;

  /// Selected mood / chip lift (mock: scale(1.1) @200ms).
  static const double selectedScale = 1.1;
}
