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

/// Default mapping. Drives the native Vibrator with explicit VibrationEffect
/// waveforms (see [MainActivity]) rather than Flutter's HapticFeedback presets:
/// those route through Android's touch-feedback path, which obeys the system
/// "touch vibration intensity" setting and is imperceptible (or dropped) on many
/// devices — DECISION #8. A waveform at full amplitude buzzes through a mattress.
///
/// Waveform format: parallel `timings`/`amplitudes` lists. Each slot plays for
/// `timings[i]` ms at `amplitudes[i]` (0 = off/gap, 255 = max). The leading
/// `0`-amplitude slot is a zero-length lead-in the platform expects.
class SystemHapticCues implements HapticCueEngine {
  const SystemHapticCues();

  static const _channel = MethodChannel('sahaj/haptics');

  static const _med = 200; // medium amplitude
  static const _heavy = 255; // heavy amplitude
  static const _soft = 160; // soft amplitude
  static const _gap = 110; // silence between taps (ms)

  Future<void> _vibrate(List<int> timings, List<int> amplitudes) async {
    try {
      await _channel.invokeMethod<void>('vibrate', {
        'timings': timings,
        'amplitudes': amplitudes,
      });
    } on PlatformException {
      // No vibrator / unsupported platform — cues are an enhancement, not a
      // requirement, so silently degrade.
    } on MissingPluginException {
      // Non-Android host (tests, desktop): no-op.
    }
  }

  // The four cues stay distinguishable: 1 medium tick vs 2 medium vs 1 long
  // heavy vs 3 soft taps.
  @override
  Future<void> squeeze() => _vibrate([0, 70], [0, _med]);

  @override
  Future<void> release() => _vibrate([0, 70, _gap, 70], [0, _med, 0, _med]);

  @override
  Future<void> phaseChange() => _vibrate([0, 220], [0, _heavy]);

  @override
  Future<void> sessionDone() => _vibrate(
        [0, 80, _gap, 80, _gap, 80],
        [0, _soft, 0, _soft, 0, _soft],
      );
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
