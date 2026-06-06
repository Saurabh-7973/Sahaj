import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // TODO(phase0-sentry): wrap runApp in SentryFlutter.init when DSN provided.
  //   await SentryFlutter.init((o) => o.dsn = '...', appRunner: () => runApp(...));
  //
  // TODO(phase0-mixpanel): init Mixpanel with token when account created.
  //   await Mixpanel.init('TOKEN', trackAutomaticEvents: false);
  //
  // TODO(phase0-revenuecat): configure Purchases with API key when set up.
  //   await Purchases.configure(PurchasesConfiguration('REVENUECAT_KEY'));

  runApp(const ProviderScope(child: SahajApp()));
}
