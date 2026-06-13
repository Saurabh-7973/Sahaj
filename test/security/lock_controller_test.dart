import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/security/lock_controller.dart';

void main() {
  test('load reflects whether a PIN exists', () async {
    final store = MemoryPinStore();
    final c = LockController(store);
    await c.load();
    expect(c.hasPin, isFalse);

    await store.write('1234');
    await c.load();
    expect(c.hasPin, isTrue);
  });

  test('setPin persists and flips hasPin', () async {
    final c = LockController(MemoryPinStore());
    await c.setPin('4321');
    expect(c.hasPin, isTrue);
  });

  test('verify accepts the right PIN, rejects others', () async {
    final c = LockController(MemoryPinStore());
    await c.setPin('2580');
    expect(await c.verify('2580'), isTrue);
    expect(await c.verify('0000'), isFalse);
  });

  test('clearPin wipes it', () async {
    final c = LockController(MemoryPinStore());
    await c.setPin('1111');
    await c.clearPin();
    expect(c.hasPin, isFalse);
    expect(await c.verify('1111'), isFalse);
  });
}
