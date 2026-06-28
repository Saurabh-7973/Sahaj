import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/security/biometric_gate.dart';
import 'features/settings/book_mode_cover.dart';

class SahajApp extends ConsumerWidget {
  const SahajApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sahaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      // Gate OUTSIDE the cover: authenticate once, then the cover sits over the
      // unlocked app. The old order re-mounted the gate every time the cover was
      // dismissed — so a double-tap to reveal re-fired the fingerprint prompt
      // and locked the user back out.
      builder: (context, child) => BiometricGate(
        child: BookModeCover(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
