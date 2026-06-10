import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'logic/audio_resolver.dart';
import 'session_audio.dart';

/// Real playback via just_audio (roadmap: M4A, stream-first with caching).
/// One instance per played session; [dispose] releases the platform player.
class JustAudioSessionAudio implements SessionAudio {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> load(ResolvedAudio source) async {
    // Spoken-guidance focus: duck other audio, pause on interruptions.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    switch (source.kind) {
      case AudioSourceKind.network:
        // Streams immediately, caches to disk for offline replays.
        await _player.setAudioSource(
          LockCachingAudioSource(Uri.parse(source.uri)),
        );
      case AudioSourceKind.asset:
        await _player.setAudioSource(AudioSource.asset(source.uri));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}
