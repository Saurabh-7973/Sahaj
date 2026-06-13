import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/launcher_disguise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Noop seam never throws', () async {
    await const NoopLauncherDisguise().setDisguise(true);
    await const NoopLauncherDisguise().setDisguise(false);
  });

  test('platform seam invokes setDisguise with the flag', () async {
    final calls = <bool>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sahaj/launcher_disguise'),
      (call) async {
        if (call.method == 'setDisguise') calls.add(call.arguments as bool);
        return null;
      },
    );

    await const PlatformLauncherDisguise().setDisguise(true);
    await const PlatformLauncherDisguise().setDisguise(false);
    expect(calls, [true, false]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('sahaj/launcher_disguise'), null);
  });

  test('platform seam swallows channel errors', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sahaj/launcher_disguise'),
      (call) async => throw PlatformException(code: 'boom'),
    );
    // Must not throw.
    await const PlatformLauncherDisguise().setDisguise(true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('sahaj/launcher_disguise'), null);
  });
}
