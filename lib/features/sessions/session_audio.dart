import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/audio_resolver.dart';

/// The audio seam. The player depends on this, not on just_audio directly, so
/// tests use a fake and text+timer sessions never touch a platform channel.
/// One instance per played session; the player owns its lifecycle.
abstract class SessionAudio {
  /// Prepare [source] for playback (network refs stream with caching).
  Future<void> load(ResolvedAudio source);

  Future<void> play();

  Future<void> pause();

  /// Release the underlying player. The instance is unusable afterwards.
  Future<void> dispose();
}

/// Default no-op — playback silently does nothing until main() wires the
/// real just_audio factory. Also what every text+timer session gets.
class NoopSessionAudio implements SessionAudio {
  const NoopSessionAudio();

  @override
  Future<void> load(ResolvedAudio source) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {}
}

/// Factory: each session play gets a fresh instance. Overridden in main()
/// with the just_audio implementation.
final sessionAudioFactoryProvider =
    Provider<SessionAudio Function()>((ref) => () => const NoopSessionAudio());
