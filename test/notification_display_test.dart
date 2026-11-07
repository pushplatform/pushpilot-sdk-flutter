import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:push_platform_flutter/push_platform_flutter.dart'
    show PushPlatformFlutter;
import 'package:push_platform_flutter/src/notification_display.dart';
import 'package:push_platform_flutter/src/models/push_message.dart';
import 'package:push_platform_flutter/src/models/push_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final message = PushMessage(
    messageId: 'n1',
    title: 'Hello',
    data: const <String, dynamic>{},
    type: PushType.normal,
    receivedAt: DateTime.utc(2026, 11, 2),
  );

  test('shows the banner when nobody is subscribed', () {
    expect(deliverNotificationDisplay(const [], message), isFalse);
  });

  test('hides the banner when preventDefault runs before return', () {
    expect(
      deliverNotificationDisplay([(event) => event.preventDefault()], message),
      isTrue,
    );
  });

  test('ignores preventDefault after the handler returns', () {
    NotificationDisplayEvent? captured;
    final prevented =
        deliverNotificationDisplay([(event) => captured = event], message);
    captured?.preventDefault();
    expect(prevented, isFalse);
  });
  test(
      'real platform stream applies preventDefault before completing native display',
      () async {
    const events = EventChannel('com.pushplatform/notification_will_display');
    const methods = MethodChannel('com.pushplatform/sdk');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final completed = Completer<Map>();
    messenger.setMockStreamHandler(events,
        MockStreamHandler.inline(onListen: (_, sink) {
      sink.success({'id': 'display-1', 'notification': message.toMap()});
      return null;
    }));
    messenger.setMockMethodCallHandler(methods, (call) async {
      if (call.method == 'completeNotificationDisplay')
        completed.complete(call.arguments as Map);
      return null;
    });
    final subscription = PushPlatformFlutter.instance.onNotificationWillDisplay
        .listen((event) => event.preventDefault());
    try {
      final result = await completed.future.timeout(const Duration(seconds: 2));
      expect(result['id'], 'display-1');
      expect(result['prevented'], isTrue);
    } finally {
      await subscription.cancel();
      messenger.setMockStreamHandler(events, null);
      messenger.setMockMethodCallHandler(methods, null);
    }
  });
}
