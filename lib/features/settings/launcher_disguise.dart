import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Swaps the launcher identity (icon + label) between "Sahaj" and "My Notes"
/// by flipping the two Android activity-aliases (M6/M8). Behind a seam so
/// tests stay platform-free and non-Android builds no-op.
abstract class LauncherDisguise {
  /// [disguised] true → "My Notes" + grey-blue icon; false → "Sahaj".
  Future<void> setDisguise(bool disguised);
}

class NoopLauncherDisguise implements LauncherDisguise {
  const NoopLauncherDisguise();
  @override
  Future<void> setDisguise(bool disguised) async {}
}

/// Real platform-channel implementation (wired in main() on Android).
class PlatformLauncherDisguise implements LauncherDisguise {
  const PlatformLauncherDisguise();

  static const _channel = MethodChannel('sahaj/launcher_disguise');

  @override
  Future<void> setDisguise(bool disguised) async {
    try {
      await _channel.invokeMethod<void>('setDisguise', disguised);
    } catch (_) {
      // Best effort — the in-app cover already disguises; a launcher cache
      // hiccup must never crash a toggle.
    }
  }
}

final launcherDisguiseProvider =
    Provider<LauncherDisguise>((ref) => const NoopLauncherDisguise());
