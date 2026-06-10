import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/audio_resolver.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

SessionDef _def(Map<String, String>? audioRef) => SessionDef(
      tag: 't',
      title: 'T',
      type: SessionType.breathwork,
      steps: const [],
      audioRef: audioRef,
    );

void main() {
  test('returns null for a text+timer session (no audioRef)', () {
    expect(resolveAudio(_def(null), 'en'), isNull);
    expect(resolveAudio(_def({}), 'en'), isNull);
  });

  test('picks the exact locale when present', () {
    final r = resolveAudio(
      _def({'en': 'assets/audio/t_en.m4a', 'hi': 'assets/audio/t_hi.m4a'}),
      'hi',
    );
    expect(r!.uri, 'assets/audio/t_hi.m4a');
  });

  test('falls back to en when the locale is missing', () {
    final r = resolveAudio(_def({'en': 'assets/audio/t_en.m4a'}), 'hi');
    expect(r!.uri, 'assets/audio/t_en.m4a');
  });

  test('returns null when neither locale nor en exists', () {
    expect(resolveAudio(_def({'ta': 'assets/audio/t_ta.m4a'}), 'hi'), isNull);
  });

  test('classifies http(s) refs as network, others as bundled asset', () {
    final net = resolveAudio(
      _def({'en': 'https://cdn.example.com/t_en.m4a'}),
      'en',
    );
    expect(net!.kind, AudioSourceKind.network);

    final asset = resolveAudio(_def({'en': 'assets/audio/t_en.m4a'}), 'en');
    expect(asset!.kind, AudioSourceKind.asset);
  });
}
