import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detects the phone being placed face-down (enters Ember mode) and lifted
/// face-up (returns to the live player).
///
/// DECISION #9 (handoff): proximity vs accelerometer-orientation vs both is a
/// device test, including the no-proximity fallback. Until that lands, the
/// default sensor never fires and Ember is entered manually (coach CTA);
/// double-tap always exits. Real sensing slots in behind this seam.
abstract class FaceDownSensor {
  /// Emits true when the device goes face-down, false when it returns face-up.
  Stream<bool> get faceDown;
}

/// No sensing — manual Ember entry only.
class NoopFaceDownSensor implements FaceDownSensor {
  const NoopFaceDownSensor();

  @override
  Stream<bool> get faceDown => const Stream.empty();
}

final faceDownSensorProvider =
    Provider<FaceDownSensor>((ref) => const NoopFaceDownSensor());
