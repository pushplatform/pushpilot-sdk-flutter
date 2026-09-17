import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushPlatformFlutter Method Channel', () {
    const MethodChannel channel = MethodChannel('com.pushplatform/sdk');
    final List<MethodCall> log = <MethodCall>[];
    final sdk = PushPlatformFlutter.instance;

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'initialize':
            return null;
          case 'requestPermissions':
            return true;
          case 'login':
            return 'inst-123';
          case 'logout':
            return null;
          case 'getDeviceId':
            return 'device-456';
          case 'getUserId':
            return 'user-789';
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('initialize() calls platform with correct arguments', () async {
      await sdk.initialize(
        apiKey: 'test-key',
        apiBaseURL: 'https://api.test',
        environment: 'development',
        debugMode: true,
      );

      expect(log.length, 1);
      expect(log[0].method, 'initialize');
      expect(log[0].arguments['apiKey'], 'test-key');
      expect(log[0].arguments['apiBaseURL'], 'https://api.test');
      expect(log[0].arguments['environment'], 'development');
      expect(log[0].arguments['debugMode'], true);
    });

    test('initialize() defaults debugMode to false', () async {
      await sdk.initialize(
        apiKey: 'test-key',
        environment: 'production',
      );

      expect(log.length, 1);
      expect(log[0].arguments['debugMode'], false);
    });

    test('requestPermissions() calls platform', () async {
      final result = await sdk.requestPermissions();

      expect(log.length, 1);
      expect(log[0].method, 'requestPermissions');
      expect(result, true);
    });

    test('login() calls platform with userId', () async {
      await sdk.login(userId: 'user-123');

      expect(log.length, 1);
      expect(log[0].method, 'login');
      expect(log[0].arguments['userId'], 'user-123');
    });

    test('logout() calls platform', () async {
      await sdk.logout();

      expect(log.length, 1);
      expect(log[0].method, 'logout');
      expect(log[0].arguments, null);
    });

    test('deviceId getter calls getDeviceId', () async {
      final deviceId = await sdk.deviceId;

      expect(log.length, 1);
      expect(log[0].method, 'getDeviceId');
      expect(deviceId, 'device-456');
    });

    test('userId getter calls getUserId', () async {
      final userId = await sdk.userId;

      expect(log.length, 1);
      expect(log[0].method, 'getUserId');
      expect(userId, 'user-789');
    });

    test('initialize() throws on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'INVALID_API_KEY',
          message: 'Invalid API key',
        );
      });

      expect(
        () => sdk.initialize(apiKey: 'bad-key', environment: 'production'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('login() throws on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'NOT_INITIALIZED',
          message: 'SDK not initialized',
        );
      });

      expect(
        () => sdk.login(userId: 'user-123'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('logout() throws on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'NOT_INITIALIZED',
          message: 'SDK not initialized',
        );
      });

      expect(
        () => sdk.logout(),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
