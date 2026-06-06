import 'models/onboarding_models.dart';

/// Maps a (higher = better) answer index to a coarse band.
/// 0 → low, 1 → medium, 2 and above → high. Deliberately simple — exact
/// clinical scoring is deferred to clinician review (synthesis §10).
Band bandFromIndex(int index) {
  if (index <= 0) return Band.low;
  if (index == 1) return Band.medium;
  return Band.high;
}
