import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/logic/data_export.dart';

void main() {
  test('export filename is neutral and dated — never "sahaj"', () {
    final name = exportFileName(DateTime(2026, 6, 9));
    expect(name, 'backup_2026-06-09.json');
    expect(name.toLowerCase().contains('sahaj'), isFalse);
  });

  test('zero-pads month and day', () {
    expect(exportFileName(DateTime(2026, 12, 25)), 'backup_2026-12-25.json');
  });
}
