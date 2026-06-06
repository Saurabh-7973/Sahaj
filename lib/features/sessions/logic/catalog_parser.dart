import 'dart:convert';

import 'models/session_models.dart';

/// Parses the sessions JSON asset into a tag-keyed catalog.
Map<String, SessionDef> parseCatalog(String jsonStr) {
  final raw = json.decode(jsonStr) as Map<String, dynamic>;
  return raw.map(
    (tag, value) => MapEntry(tag, SessionDef.fromJson(tag, value as Map)),
  );
}
