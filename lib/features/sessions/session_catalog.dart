import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/catalog_parser.dart';
import 'logic/models/session_models.dart';

/// Loads the bundled session content asset into a tag-keyed catalog.
class SessionCatalog {
  const SessionCatalog(this.byTag);

  final Map<String, SessionDef> byTag;

  SessionDef? operator [](String tag) => byTag[tag];

  static Future<SessionCatalog> load() async {
    final jsonStr =
        await rootBundle.loadString('assets/content/sessions.json');
    return SessionCatalog(parseCatalog(jsonStr));
  }
}

/// Overridden in main() with the catalog loaded at startup.
final sessionCatalogProvider = Provider<SessionCatalog>(
  (ref) => throw UnimplementedError('sessionCatalogProvider not overridden'),
);
