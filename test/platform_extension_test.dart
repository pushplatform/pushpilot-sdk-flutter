import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Extension Guards', () {
    const MethodChannel channel = MethodChannel('com.pushplatform/sdk');
    final sdk = PushPlatformFlutter.instance;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('iOS-only methods', () {
      test('registerForVoIP throws on non-iOS platform', () async {
        // Extension methods work via import, test platform guards
        if (!Platform.isIOS) {
          expect(
            () => sdk.registerForVoIP(),
            throwsUnsupportedError,
          );
        }
      });

      test('onVoIPCallReceived stream should only work on iOS', () {
        if (!Platform.isIOS) {
          expect(
            () => sdk.onVoIPCallReceived.listen((_) {}),
            throwsUnsupportedError,
          );
        }
      });
    });

    group('Android-only methods', () {
      test('onCallReceived stream should only work on Android', () {
        if (!Platform.isAndroid) {
          expect(
            () => sdk.onCallReceived.listen((_) {}),
            throwsUnsupportedError,
          );
        }
      });
    });

    group('Cross-platform methods always available', () {
      test('initialize works on any platform', () async {
        await expectLater(
          sdk.initialize(
            apiKey: 'test-key',
            environment: 'development',
          ),
          completes,
        );
      });

      test('requestPermissions works on any platform', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return true;
        });

        await expectLater(
          sdk.requestPermissions(),
          completion(isTrue),
        );
      });

      test('login works on any platform', () async {
        await expectLater(
          sdk.login(userId: 'user-123'),
          completes,
        );
      });

      test('logout works on any platform', () async {
        await expectLater(
          sdk.logout(),
          completes,
        );
      });

      test('deviceId getter works on any platform', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return 'device-456';
        });

        await expectLater(
          sdk.deviceId,
          completion('device-456'),
        );
      });

      test('userId getter works on any platform', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return 'user-789';
        });

        await expectLater(
          sdk.userId,
          completion('user-789'),
        );
      });

      test('onPushReceived stream works on any platform', () {
        expect(
          () => sdk.onPushReceived.listen((_) {}),
          returnsNormally,
        );
      });

      test('onStateChange stream works on any platform', () {
        expect(
          () => sdk.onStateChange.listen((_) {}),
          returnsNormally,
        );
      });
    });
  });
}
