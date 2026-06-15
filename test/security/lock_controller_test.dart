import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/security/lock_controller.dart';

void main() {
  test('load reflects whether a PIN exists', () async {
    final store = MemoryPinStore();
    final c = LockController(store);
    await c.load();
    expect(c.hasPin, isFalse);

    await store.write('123456');
    await c.load();
    expect(c.hasPin, isTrue);
  });

  test('setPin persists and flips hasPin', () async {
    final c = LockController(MemoryPinStore());
    await c.setPin('654321');
    expect(c.hasPin, isTrue);
  });

  test('verify accepts the right PIN, rejects others', () async {
    final c = LockController(MemoryPinStore());
    await c.setPin('258025');
    expect(await c.verify('258025'), isTrue);
    expect(await c.verify('000000'), isFalse);
  });

  test('clearPin wipes it', () async {
    final c = LockController(MemoryPinStore());
    await c.setPin('111111');
    await c.clearPin();
    expect(c.hasPin, isFalse);
    expect(await c.verify('111111'), isFalse);
  });
}
