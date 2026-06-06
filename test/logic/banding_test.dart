import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/banding.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';

void main() {
  test('index 0 → low, 1 → medium, 2+ → high', () {
    expect(bandFromIndex(0), Band.low);
    expect(bandFromIndex(1), Band.medium);
    expect(bandFromIndex(2), Band.high);
    expect(bandFromIndex(3), Band.high);
  });
}
