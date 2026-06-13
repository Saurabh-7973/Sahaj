import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The haptic cue language (M1 module rule, on by default). Four cues make a
/// session followable with the phone face-down, silent, lights off:
///
/// | 1 tick        | squeeze — begin hold | phase start          |
/// | 2 ticks       | release — let go     | hold→rest transition |
/// | 1 long pulse  | phase change         | step boundary        |
/// | 3 soft taps   | session done         | last step end        |
///
/// DECISION #8 (handoff): the primitive mapping below (HapticFeedback presets
/// vs Android VibrationEffect compositions) needs a device test — the four
/// cues must stay distinguishable through a mattress. Swap implementations
/// behind this seam only; the player never sees primitives.
abstract class HapticCueEngine {
  Future<void> squeeze();
  Future<void> release();
  Future<void> phaseChange();
  Future<void> sessionDone();
}

/// Default mapping on Flutter's portable presets.
class SystemHapticCues implements HapticCueEngine {
  const SystemHapticCues();

  static const _gap = Duration(milliseconds: 140);

  @override
  Future<void> squeeze() => HapticFeedback.lightImpact();

  @override
  Future<void> release() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(_gap);
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> phaseChange() => HapticFeedback.heavyImpact();

  @override
  Future<void> sessionDone() async {
    for (var i = 0; i < 3; i++) {
      if (i > 0) await Future<void>.delayed(_gap);
      await HapticFeedback.selectionClick();
    }
  }
}

/// For tests and the "haptics off" preference.
class NoopHapticCues implements HapticCueEngine {
  const NoopHapticCues();

  @override
  Future<void> squeeze() async {}
  @override
  Future<void> release() async {}
  @override
  Future<void> phaseChange() async {}
  @override
  Future<void> sessionDone() async {}
}

final hapticCuesProvider =
    Provider<HapticCueEngine>((ref) => const SystemHapticCues());
