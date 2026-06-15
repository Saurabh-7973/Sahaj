import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/media_metadata.dart';

void main() {
  test('subtitle is always "Audio" — never a technique word', () {
    final m = MediaMetadata.forSession(
        sessionTitle: 'Calm breathing', bookMode: false);
    expect(m.subtitle, 'Audio');
  });

  test('app name follows the disguise alias when Book Mode is on', () {
    final disguised = MediaMetadata.forSession(
        sessionTitle: 'Calm breathing', bookMode: true);
    expect(disguised.appName, 'Notebook');

    final real = MediaMetadata.forSession(
        sessionTitle: 'Calm breathing', bookMode: false);
    expect(real.appName, 'Sahaj');
  });

  test('title is the neutral session title, untouched', () {
    final m = MediaMetadata.forSession(
        sessionTitle: 'Calm breathing', bookMode: false);
    expect(m.title, 'Calm breathing');
  });
}
