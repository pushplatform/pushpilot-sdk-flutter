import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushPlatformFlutter Event Channels', () {
    const EventChannel pushEventChannel =
        EventChannel('com.pushplatform/push_events');
    const EventChannel voipEventChannel =
        EventChannel('com.pushplatform/voip_events');
    const EventChannel stateEventChannel =
        EventChannel('com.pushplatform/state_events');

    final sdk = PushPlatformFlutter.instance;

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(voipEventChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(stateEventChannel, null);
    });

    test('onPushReceived stream emits PushMessage', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.success({
          'messageId': 'msg-123',
          'title': 'Test Push',
          'body': 'Test body',
          'data': {'key': 'value'},
          'type': 'normal',
          'receivedAt': 1726588800000,
        });
        return null;
      }));

      final message = await sdk.onPushReceived.first;

      expect(message.messageId, 'msg-123');
      expect(message.title, 'Test Push');
      expect(message.body, 'Test body');
      expect(message.data['key'], 'value');
      expect(message.type, PushType.normal);
    });

    test('onPushReceived handles silent push type', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.success({
          'messageId': 'msg-456',
          'title': null,
          'body': null,
          'data': {'silent': 'true'},
          'type': 'silent',
          'receivedAt': 1726588800000,
        });
        return null;
      }));

      final message = await sdk.onPushReceived.first;

      expect(message.messageId, 'msg-456');
      expect(message.type, PushType.silent);
      expect(message.title, null);
      expect(message.body, null);
    });

    test('onPushReceived handles null/empty data', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.success({
          'messageId': 'msg-789',
          'title': 'Empty Data',
          'body': 'No custom data',
          'data': null,
          'type': 'normal',
          'receivedAt': 1726588800000,
        });
        return null;
      }));

      final message = await sdk.onPushReceived.first;

      expect(message.messageId, 'msg-789');
      expect(message.data, isEmpty);
    });

    test('onStateChange stream emits StateChange events', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(stateEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.success('initialized');
        return null;
      }));

      final state = await sdk.onStateChange.first;

      expect(state, StateChange.initialized);
    });

    test('onStateChange handles all state values', () async {
      final states = [
        'initialized',
        'loggedIn',
        'loggedOut',
        'permissionGranted',
        'permissionDenied',
        'tokenRefreshed',
        'error',
      ];

      final expectedStates = [
        StateChange.initialized,
        StateChange.loggedIn,
        StateChange.loggedOut,
        StateChange.permissionsGranted,
        StateChange.permissionsDenied,
        StateChange.registered,
        StateChange.error,
      ];

      for (var i = 0; i < states.length; i++) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(stateEventChannel,
                MockStreamHandler.inline(onListen: (_, sink) {
          sink.success(states[i]);
          return null;
        }));

        final state = await sdk.onStateChange.first;
        expect(state, expectedStates[i]);
      }
    });

    test('onStateChange handles unknown state as error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(stateEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.success('unknownState');
        return null;
      }));

      final state = await sdk.onStateChange.first;

      expect(state, StateChange.error);
    });

    test('multiple listeners can subscribe to same stream', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.success({
          'messageId': 'msg-multi',
          'title': 'Multi Listener Test',
          'body': 'Body',
          'data': {},
          'type': 'normal',
          'receivedAt': 1726588800000,
        });
        return null;
      }));

      final listener1 = sdk.onPushReceived.first;
      final listener2 = sdk.onPushReceived.first;

      final results = await Future.wait([listener1, listener2]);

      expect(results[0].messageId, 'msg-multi');
      expect(results[1].messageId, 'msg-multi');
    });

    test('stream handles errors gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        sink.error(code: 'STREAM_ERROR', message: 'Test error');
        return null;
      }));

      expect(
        sdk.onPushReceived.first,
        throwsA(isA<PlatformException>()),
      );
    });

    test('stream can be cancelled and resubscribed', () async {
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, sink) {
        callCount++;
        sink.success({
          'messageId': 'msg-cancel-$callCount',
          'title': 'Cancel Test',
          'body': 'Body',
          'data': {},
          'type': 'normal',
          'receivedAt': 1726588800000,
        });
        return null;
      }));

      final subscription = sdk.onPushReceived.listen((_) {});
      await subscription.cancel();

      // Resubscribe
      final message = await sdk.onPushReceived.first;
      expect(message.messageId, 'msg-cancel-2');
    });
  });
}
