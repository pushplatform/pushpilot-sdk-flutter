import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Error Handling', () {
    const MethodChannel channel = MethodChannel('com.pushplatform/sdk');
    final sdk = PushPlatformFlutter.instance;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('Platform Exception Handling', () {
      test('handles INVALID_API_KEY error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'INVALID_API_KEY',
            message: 'The provided API key is invalid',
            details: {'apiKey': 'bad-key'},
          );
        });

        expect(
          () => sdk.initialize(apiKey: 'bad-key', environment: 'production'),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'INVALID_API_KEY',
            ),
          ),
        );
      });

      test('handles NOT_INITIALIZED error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'NOT_INITIALIZED',
            message: 'SDK must be initialized before calling this method',
          );
        });

        expect(
          () => sdk.login(userId: 'user-123'),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'NOT_INITIALIZED',
            ),
          ),
        );
      });

      test('handles NETWORK_ERROR', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'NETWORK_ERROR',
            message: 'Failed to connect to server',
            details: {'statusCode': 500},
          );
        });

        expect(
          () => sdk.requestPermissions(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'NETWORK_ERROR',
            ),
          ),
        );
      });

      test('handles PERMISSION_DENIED error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'User denied notification permissions',
          );
        });

        expect(
          () => sdk.requestPermissions(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'PERMISSION_DENIED',
            ),
          ),
        );
      });

      test('handles INVALID_USER_ID error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'INVALID_USER_ID',
            message: 'User ID cannot be empty',
          );
        });

        expect(
          () => sdk.login(userId: ''),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'INVALID_USER_ID',
            ),
          ),
        );
      });

      test('handles generic platform exception with details', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'UNKNOWN_ERROR',
            message: 'An unexpected error occurred',
            details: {
              'errorType': 'RuntimeException',
              'stackTrace': 'at com.example...',
            },
          );
        });

        try {
          await sdk.initialize(apiKey: 'test-key', environment: 'production');
          fail('Should have thrown PlatformException');
        } on PlatformException catch (e) {
          expect(e.code, 'UNKNOWN_ERROR');
          expect(e.message, contains('unexpected error'));
          expect(e.details, isNotNull);
          expect(e.details['errorType'], 'RuntimeException');
        }
      });
    });

    group('Null and Empty Value Handling', () {
      test('initialize throws on null apiKey', () {
        expect(
          () => sdk.initialize(
            apiKey: null as dynamic,
            environment: 'production',
          ),
          throwsA(isA<TypeError>()),
        );
      });

      test('initialize throws on empty apiKey', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'INVALID_API_KEY',
            message: 'API key cannot be empty',
          );
        });

        expect(
          () => sdk.initialize(apiKey: '', environment: 'production'),
          throwsA(isA<PlatformException>()),
        );
      });

      test('login throws on null userId', () {
        expect(
          () => sdk.login(userId: null as dynamic),
          throwsA(isA<TypeError>()),
        );
      });

      test('login throws on empty userId', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'INVALID_USER_ID',
            message: 'User ID cannot be empty',
          );
        });

        expect(
          () => sdk.login(userId: ''),
          throwsA(isA<PlatformException>()),
        );
      });

      test('handles null response from platform gracefully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

        await expectLater(
          sdk.initialize(apiKey: 'test-key', environment: 'production'),
          completes,
        );
      });

      test('deviceId returns null when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

        final deviceId = await sdk.deviceId;
        expect(deviceId, isNull);
      });

      test('userId returns null when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

        final userId = await sdk.userId;
        expect(userId, isNull);
      });
    });

    group('Method Call Failures', () {
      test('handles method not implemented error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw MissingPluginException(
            'No implementation found for method ${methodCall.method}',
          );
        });

        expect(
          () => sdk.initialize(apiKey: 'test-key', environment: 'production'),
          throwsA(isA<MissingPluginException>()),
        );
      });

      test('handles unexpected exception from platform', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw Exception('Unexpected platform error');
        });

        expect(
          () => sdk.initialize(apiKey: 'test-key', environment: 'production'),
          throwsException,
        );
      });

      test('multiple sequential errors are handled independently', () async {
        var callCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          callCount++;
          if (callCount == 1) {
            throw PlatformException(
              code: 'NETWORK_ERROR',
              message: 'Network error',
            );
          } else {
            return null;
          }
        });

        // First call should throw
        expect(
          () => sdk.initialize(apiKey: 'test-key', environment: 'production'),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'NETWORK_ERROR',
            ),
          ),
        );

        // Second call should succeed
        await expectLater(
          sdk.initialize(apiKey: 'test-key', environment: 'production'),
          completes,
        );
      });
    });

    group('Concurrent Error Handling', () {
      test('handles errors in concurrent method calls', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'login') {
            throw PlatformException(
              code: 'NOT_INITIALIZED',
              message: 'SDK not initialized',
            );
          }
          return null;
        });

        final initFuture = sdk.initialize(
          apiKey: 'test-key',
          environment: 'production',
        );
        final loginFuture =
            sdk.login(userId: 'user-123').catchError((e) => null);

        await initFuture; // Wait for init
        final loginResult = await loginFuture; // Wait for login

        expect(loginResult, isNull); // login failed and caught
      });

      test('stream errors do not break other streams', () async {
        const EventChannel pushChannel =
            EventChannel('com.pushplatform/push_events');
        const EventChannel stateChannel =
            EventChannel('com.pushplatform/state_events');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(pushChannel,
                MockStreamHandler.inline(onListen: (_, sink) {
          sink.error(code: 'STREAM_ERROR', message: 'Push error');
          return null;
        }));

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(stateChannel,
                MockStreamHandler.inline(onListen: (_, sink) {
          sink.success('initialized');
          return null;
        }));

        expect(
          sdk.onPushReceived.first,
          throwsA(isA<PlatformException>()),
        );

        final state = await sdk.onStateChange.first;
        expect(state, StateChange.initialized);
      });
    });
  });
}
