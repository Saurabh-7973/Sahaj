// Renders key M7 paywall + subscription screens at 390×844@3x →
// docs/ui_review/.   flutter test test/ui_review/m7_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/analytics.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/subscription/logic/pricing_tier.dart';
import 'package:sahaj/features/subscription/pages/paywall_screen.dart';
import 'package:sahaj/features/subscription/pages/subscription_page.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

import '../support/fake_analytics.dart';

const _outDir = 'docs/ui_review';
final _boundaryKey = GlobalKey();

class _Repo implements SubscriptionRepository {
  @override
  Future<bool> fetchIsPro() async => false;
  @override
  Future<bool> purchase(PricingTier tier) async => true;
  @override
  Future<bool> restore() async => true;
}

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
    SubscriptionController sub) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(FakeAnalytics()),
        subscriptionControllerProvider.overrideWith((ref) => sub),
      ],
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

  testWidgets('m7_01 paywall — ₹499 selected', (tester) async {
    await _pump(tester, const PaywallScreen(source: 'review'),
        SubscriptionController(_Repo()));
    await tester.tap(find.text('A fair price on a tight budget.'));
    await tester.pumpAndSettle();
    await _capture(tester, 'm7_01_paywall_selected');
  });

  testWidgets('m7 subscription — free', (tester) async {
    await _pump(
        tester, const SubscriptionPage(), SubscriptionController(_Repo()));
    await _capture(tester, 'm7_26_subscription_free');
  });

  testWidgets('m7_03a subscription — unlocked (₹499 paid once)', (tester) async {
    final sub = SubscriptionController(_Repo());
    await sub.choose(PricingTier.low); // one-time unlock
    await _pump(tester, const SubscriptionPage(), sub);
    await _capture(tester, 'm7_03_subscription_trial');
  });

  testWidgets('m7_03b subscription — unlocked (₹0 grant)', (tester) async {
    final sub = SubscriptionController(_Repo());
    await sub.choose(PricingTier.free);
    await _pump(tester, const SubscriptionPage(), sub);
    await _capture(tester, 'm7_03_subscription_active');
  });
}
