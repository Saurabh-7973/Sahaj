import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// How the app gate authenticates (M6 §3).
enum LockMethod { none, biometric, pin }

/// Persists the 6-digit PIN. The protection is the platform keystore behind
/// [FlutterSecureStorage], not a hash — a short numeric PIN has no
/// cryptographic strength to add. Swapped for an in-memory store in tests.
abstract class PinStore {
  Future<String?> read();
  Future<void> write(String pin);
  Future<void> clear();
}

class SecurePinStore implements PinStore {
  const SecurePinStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _key = 'sahaj_pin';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String pin) => _storage.write(key: _key, value: pin);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// In-memory store for tests.
class MemoryPinStore implements PinStore {
  String? _pin;
  @override
  Future<String?> read() async => _pin;
  @override
  Future<void> write(String pin) async => _pin = pin;
  @override
  Future<void> clear() async => _pin = null;
}

/// DECISION #8 (resolved): 6-digit PIN, no lockout enforced. The screens
/// absorb either length; lockout stays deferred (keystore is the real guard).
const int kPinLength = 6;

/// Holds the lock method + PIN-set state. Biometric on/off still lives on the
/// onboarding controller (legacy); this adds the PIN fallback the gate needs.
class LockController extends ChangeNotifier {
  LockController([this._store]);

  final PinStore? _store;
  bool _hasPin = false;
  bool get hasPin => _hasPin;

  Future<void> load() async {
    _hasPin = (await _store?.read()) != null;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    assert(pin.length == kPinLength);
    await _store?.write(pin);
    _hasPin = true;
    notifyListeners();
  }

  Future<bool> verify(String pin) async {
    final stored = await _store?.read();
    return stored != null && stored == pin;
  }

  Future<void> clearPin() async {
    await _store?.clear();
    _hasPin = false;
    notifyListeners();
  }
}

final lockControllerProvider =
    ChangeNotifierProvider<LockController>((ref) => LockController());
