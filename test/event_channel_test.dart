import 'dart:async';
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
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add({
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

      await controller.close();
    });

    test('onPushReceived handles silent push type', () async {
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add({
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

      await controller.close();
    });

    test('onPushReceived handles null/empty data', () async {
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add({
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

      await controller.close();
    });

    test('onStateChange stream emits StateChange events', () async {
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(stateEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add('initialized');
        return null;
      }));

      final state = await sdk.onStateChange.first;

      expect(state, StateChange.initialized);

      await controller.close();
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
        final StreamController<dynamic> controller =
            StreamController<dynamic>();

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(stateEventChannel,
                MockStreamHandler.inline(onListen: (_, __) {
          controller.add(states[i]);
          return null;
        }));

        final state = await sdk.onStateChange.first;
        expect(state, expectedStates[i]);

        await controller.close();
      }
    });

    test('onStateChange handles unknown state as error', () async {
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(stateEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add('unknownState');
        return null;
      }));

      final state = await sdk.onStateChange.first;

      expect(state, StateChange.error);

      await controller.close();
    });

    test('multiple listeners can subscribe to same stream', () async {
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add({
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

      await controller.close();
    });

    test('stream handles errors gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        throw PlatformException(code: 'STREAM_ERROR', message: 'Test error');
      }));

      expect(
        sdk.onPushReceived.first,
        throwsA(isA<PlatformException>()),
      );
    });

    test('stream can be cancelled and resubscribed', () async {
      final StreamController<dynamic> controller = StreamController<dynamic>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(pushEventChannel,
              MockStreamHandler.inline(onListen: (_, __) {
        controller.add({
          'messageId': 'msg-cancel',
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
      expect(message.messageId, 'msg-cancel');

      await controller.close();
    });
  });
}
