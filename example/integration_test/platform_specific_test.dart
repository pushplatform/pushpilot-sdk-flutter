import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform-Specific Integration Tests', () {
    final sdk = PushPlatformFlutter.instance;

    setUp(() async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        environment: 'development',
        debugMode: true,
      );
    });

    group('iOS-specific', () {
      testWidgets('registerForVoIP available on iOS', (tester) async {
        if (Platform.isIOS) {
          await expectLater(
            sdk.registerForVoIP(),
            completes,
          );
        } else {
          expect(
            () => sdk.registerForVoIP(),
            throwsUnsupportedError,
          );
        }
      });

      testWidgets('onVoIPCallReceived stream on iOS', (tester) async {
        if (Platform.isIOS) {
          expect(
            () => sdk.onVoIPCallReceived.listen((_) {}),
            returnsNormally,
          );
        } else {
          expect(
            () => sdk.onVoIPCallReceived.listen((_) {}),
            throwsUnsupportedError,
          );
        }
      });
    });

    group('Android-specific', () {
      testWidgets('onCallReceived stream on Android', (tester) async {
        if (Platform.isAndroid) {
          expect(
            () => sdk.onCallReceived.listen((_) {}),
            returnsNormally,
          );
        } else {
          expect(
            () => sdk.onCallReceived.listen((_) {}),
            throwsUnsupportedError,
          );
        }
      });
    });
  });
}
