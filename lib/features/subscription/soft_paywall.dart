import 'package:flutter/material.dart';

import 'pages/paywall_screen.dart';

/// Opens the paywall as a soft, dismissible sheet/route. Soft by design —
/// [PaywallScreen] keeps its close button and "Maybe later", so a locked tap
/// never traps the user.
Future<void> showSoftPaywall(BuildContext context, {required String source}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaywallScreen(source: source),
    ),
  );
}
