/// The media-session law (M8 §1). An audio session puts a lock-screen media
/// notification on screen whether we like it or not, so its metadata is
/// governed: a neutral title, "Audio" as the only subtitle, the lotus glyph,
/// and the app name following the active identity. No technique words, no
/// durations framed as exercise. Beside a Messages card it must read as
/// someone playing a calm track.
class MediaMetadata {
  const MediaMetadata({
    required this.title,
    required this.appName,
  });

  /// The neutral display title (e.g. "Calm breathing").
  final String title;

  /// Always "Audio" — never a technique word or duration.
  String get subtitle => 'Audio';

  /// The active app identity: the disguise alias when Book Mode is on, else
  /// the real name. Shown by the OS as the notification source.
  final String appName;

  /// Artwork asset — the lotus glyph (bundled mono asset).
  String get artworkAsset => 'assets/images/grain_64.png'; // placeholder slot

  /// Builds governed metadata for a session. The [sessionTitle] is already the
  /// neutral catalog title; we never derive anything from technique tags.
  factory MediaMetadata.forSession({
    required String sessionTitle,
    required bool bookMode,
    String aliasName = 'My Notes',
    String realName = 'Sahaj',
  }) =>
      MediaMetadata(
        title: sessionTitle,
        appName: bookMode ? aliasName : realName,
      );
}
