// Renders key M6 privacy screens at 390×844@3x → docs/ui_review/.
//   flutter test test/ui_review/m6_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/security/pin_pad.dart';
import 'package:sahaj/features/settings/book_mode_cover.dart';
import 'package:sahaj/features/settings/erase_confirm_screen.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

const _outDir = 'docs/ui_review';
final _boundaryKey = GlobalKey();

Future<void> _loadFonts() async {
  Future<void> load(String f, List<String> a) async {
    final l = FontLoader(f);
    for (final p in a) {
      l.addFont(rootBundle.load(p));
    }
    await l.load();
  }

  await load('Fraunces', [
    'assets/fonts/Fraunces-300.ttf',
    'assets/fonts/Fraunces-400Italic.ttf',
    'assets/fonts/Fraunces-500.ttf',
    'assets/fonts/Fraunces-600.ttf',
  ]);
  await load('Manrope', [
    'assets/fonts/Manrope-400.ttf',
    'assets/fonts/Manrope-500.ttf',
    'assets/fonts/Manrope-600.ttf',
    'assets/fonts/Manrope-700.ttf',
    'assets/fonts/Manrope-800.ttf',
  ]);
  // The Book Mode cover renders in Roboto (the device system font); the SDK
  // ships none in tests, so stand Manrope in for legible review PNGs.
  await load('Roboto', ['assets/fonts/Manrope-400.ttf', 'assets/fonts/Manrope-500.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future.value(f.readAsBytesSync().buffer.asByteData())))
          .load();
    }
  }
}

Future<void> _pump(WidgetTester tester, Widget home,
    {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: home,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  late final ByteData bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });
  File('$_outDir/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $_outDir/$name.png');
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('m6 book cover — note list', (tester) async {
    await _pump(
      tester,
      const BookModeCover(child: SizedBox()),
      overrides: [
        preferencesControllerProvider
            .overrideWith((ref) => PreferencesController()..setBookMode(true)),
      ],
    );
    await _capture(tester, 'm6_23_book_cover');
  });

  testWidgets('m6_01a book cover — note depth', (tester) async {
    await _pump(
      tester,
      const BookModeCover(child: SizedBox()),
      overrides: [
        preferencesControllerProvider
            .overrideWith((ref) => PreferencesController()..setBookMode(true)),
      ],
    );
    await tester.tap(find.text('Grocery — Saturday'));
    // Past the double-tap timeout so the single tap resolves and opens the note.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await _capture(tester, 'm6_01_cover_depth');
  });

  testWidgets('m6_02 PIN pad', (tester) async {
    await _pump(tester, PinPad(onComplete: (_) async => true,
        onUseFingerprint: () {}));
    // Enter two digits to show filled dots.
    await tester.tap(find.text('4'));
    await tester.tap(find.text('2'));
    await tester.pump();
    await _capture(tester, 'm6_02_gate_pin');
  });

  testWidgets('m6 erase confirm', (tester) async {
    await _pump(tester, EraseConfirmScreen(onErase: () {}));
    await _capture(tester, 'm6_22_erase_confirm');
  });
}
