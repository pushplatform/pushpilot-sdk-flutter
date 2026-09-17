import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/src/models/push_message.dart';
import 'package:push_platform_flutter/src/models/push_type.dart';

void main() {
  group('PushMessage', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30, 0);
    final testMap = {
      'messageId': 'msg-123',
      'title': 'Test Title',
      'body': 'Test Body',
      'data': {'key1': 'value1', 'key2': 'value2'},
      'type': 'normal',
      'receivedAt': testTimestamp.millisecondsSinceEpoch,
    };

    test('fromMap creates valid PushMessage', () {
      final message = PushMessage.fromMap(testMap);

      expect(message.messageId, 'msg-123');
      expect(message.title, 'Test Title');
      expect(message.body, 'Test Body');
      expect(message.data, {'key1': 'value1', 'key2': 'value2'});
      expect(message.type, PushType.normal);
      expect(message.receivedAt, testTimestamp);
    });

    test('fromMap handles null title and body', () {
      final map = Map<String, dynamic>.from(testMap);
      map.remove('title');
      map.remove('body');

      final message = PushMessage.fromMap(map);

      expect(message.title, isNull);
      expect(message.body, isNull);
    });

    test('fromMap handles empty data', () {
      final map = Map<String, dynamic>.from(testMap);
      map.remove('data');

      final message = PushMessage.fromMap(map);

      expect(message.data, isEmpty);
    });

    test('fromMap handles silent push type', () {
      final map = Map<String, dynamic>.from(testMap);
      map['type'] = 'silent';

      final message = PushMessage.fromMap(map);

      expect(message.type, PushType.silent);
    });

    test('toMap creates valid map', () {
      final message = PushMessage(
        messageId: 'msg-456',
        title: 'Title',
        body: 'Body',
        data: {'test': 'data'},
        type: PushType.normal,
        receivedAt: testTimestamp,
      );

      final map = message.toMap();

      expect(map['messageId'], 'msg-456');
      expect(map['title'], 'Title');
      expect(map['body'], 'Body');
      expect(map['data'], {'test': 'data'});
      expect(map['type'], 'normal');
      expect(map['receivedAt'], testTimestamp.millisecondsSinceEpoch);
    });

    test('equality works correctly', () {
      final message1 = PushMessage.fromMap(testMap);
      final message2 = PushMessage.fromMap(testMap);
      final message3 = PushMessage.fromMap({
        ...testMap,
        'messageId': 'different-id',
      });

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('hashCode is consistent', () {
      final message1 = PushMessage.fromMap(testMap);
      final message2 = PushMessage.fromMap(testMap);

      expect(message1.hashCode, equals(message2.hashCode));
    });

    test('toString includes key fields', () {
      final message = PushMessage.fromMap(testMap);
      final str = message.toString();

      expect(str, contains('msg-123'));
      expect(str, contains('Test Title'));
      expect(str, contains('Test Body'));
      expect(str, contains('normal'));
    });
  });
}
