import 'models/session_models.dart';

/// Where a resolved audio ref points.
enum AudioSourceKind { network, asset }

/// A playable audio source for a session, after locale resolution.
class ResolvedAudio {
  const ResolvedAudio({required this.uri, required this.kind});

  final String uri;
  final AudioSourceKind kind;
}

/// Picks the audio for [locale] from the session's `audioRef`, falling back to
/// English. Returns null for text+timer sessions (no audio authored yet).
///
/// Refs are either full http(s) URLs (Firebase Storage public files, streamed
/// with caching) or bundled asset paths (`assets/audio/…`).
ResolvedAudio? resolveAudio(SessionDef def, String locale) {
  final refs = def.audioRef;
  if (refs == null || refs.isEmpty) return null;
  final uri = refs[locale] ?? refs['en'];
  if (uri == null) return null;
  final kind = uri.startsWith('http')
      ? AudioSourceKind.network
      : AudioSourceKind.asset;
  return ResolvedAudio(uri: uri, kind: kind);
}
