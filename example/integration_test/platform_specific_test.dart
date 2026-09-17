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
      testWidgets('registerForVoIPPushes available on iOS', (tester) async {
        if (Platform.isIOS) {
          await expectLater(
            sdk.registerForVoIPPushes(),
            completes,
          );
        } else {
          expect(
            () => sdk.registerForVoIPPushes(),
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

      testWidgets('reportIncomingVoIPCall on iOS', (tester) async {
        if (Platform.isIOS) {
          await expectLater(
            sdk.reportIncomingVoIPCall(
              callId: 'test-call-ios',
              callerName: 'Test Caller',
            ),
            completes,
          );
        } else {
          expect(
            () => sdk.reportIncomingVoIPCall(
              callId: 'test-call-ios',
              callerName: 'Test Caller',
            ),
            throwsUnsupportedError,
          );
        }
      });

      testWidgets('endVoIPCall on iOS', (tester) async {
        if (Platform.isIOS) {
          await expectLater(
            sdk.endVoIPCall(callId: 'test-call-ios'),
            completes,
          );
        } else {
          expect(
            () => sdk.endVoIPCall(callId: 'test-call-ios'),
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

      testWidgets('reportIncomingCall on Android', (tester) async {
        if (Platform.isAndroid) {
          await expectLater(
            sdk.reportIncomingCall(
              callId: 'test-call-android',
              callerName: 'Test Caller',
            ),
            completes,
          );
        } else {
          expect(
            () => sdk.reportIncomingCall(
              callId: 'test-call-android',
              callerName: 'Test Caller',
            ),
            throwsUnsupportedError,
          );
        }
      });

      testWidgets('endCall on Android', (tester) async {
        if (Platform.isAndroid) {
          await expectLater(
            sdk.endCall(callId: 'test-call-android'),
            completes,
          );
        } else {
          expect(
            () => sdk.endCall(callId: 'test-call-android'),
            throwsUnsupportedError,
          );
        }
      });
    });
  });
}
