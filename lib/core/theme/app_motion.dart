import 'package:flutter/animation.dart';

/// Calm motion. No bouncy or overshooting curves.
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
}
