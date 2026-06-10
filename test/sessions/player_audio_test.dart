import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/audio_resolver.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/pages/session_player_page.dart';
import 'package:sahaj/features/sessions/session_audio.dart';

class FakeSessionAudio implements SessionAudio {
  final calls = <String>[];
  ResolvedAudio? loaded;

  @override
  Future<void> load(ResolvedAudio source) async {
    calls.add('load');
    loaded = source;
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

SessionDef _def({Map<String, String>? audioRef}) => SessionDef(
      tag: 'breathwork_basics',
      title: 'Calm breathing',
      type: SessionType.breathwork,
      steps: const [
        SessionStep(title: 'Inhale', seconds: 120, guidance: 'Slow breaths.'),
      ],
      audioRef: audioRef,
    );

Future<void> _pump(WidgetTester tester, SessionDef def, SessionAudio audio) {
  return tester.pumpWidget(MaterialApp(
    home: SessionPlayerPage(
      session: def,
      onComplete: (_) {},
      audio: audio,
    ),
  ));
}

void main() {
  testWidgets('audio session: loads then plays on start', (tester) async {
    final audio = FakeSessionAudio();
    await _pump(
      tester,
      _def(audioRef: {'en': 'assets/audio/breathwork_basics_en.m4a'}),
      audio,
    );
    await tester.pump();
    expect(audio.calls, ['load', 'play']);
    expect(audio.loaded!.uri, 'assets/audio/breathwork_basics_en.m4a');
  });

  testWidgets('pause/resume toggles audio with the step timer',
      (tester) async {
    final audio = FakeSessionAudio();
    await _pump(tester, _def(audioRef: {'en': 'a.m4a'}), audio);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(audio.calls.last, 'pause');

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(audio.calls.last, 'play');
  });

  testWidgets('player disposal disposes the audio', (tester) async {
    final audio = FakeSessionAudio();
    await _pump(tester, _def(audioRef: {'en': 'a.m4a'}), audio);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(audio.calls, contains('dispose'));
  });

  testWidgets('text+timer session never touches the audio seam',
      (tester) async {
    final audio = FakeSessionAudio();
    await _pump(tester, _def(), audio);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(audio.calls, isEmpty);
  });
}
