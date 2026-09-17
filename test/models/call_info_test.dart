import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/src/models/call_info.dart';

void main() {
  group('CallInfo', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30, 0);
    final testMap = {
      'callId': 'call-123',
      'callerId': 'user-456',
      'callerName': 'John Doe',
      'metadata': {'type': 'video', 'duration': '300'},
      'receivedAt': testTimestamp.millisecondsSinceEpoch,
    };

    test('fromMap creates valid CallInfo', () {
      final callInfo = CallInfo.fromMap(testMap);

      expect(callInfo.callId, 'call-123');
      expect(callInfo.callerId, 'user-456');
      expect(callInfo.callerName, 'John Doe');
      expect(callInfo.metadata, {'type': 'video', 'duration': '300'});
      expect(callInfo.receivedAt, testTimestamp);
    });

    test('fromMap handles null callerName', () {
      final map = Map<String, dynamic>.from(testMap);
      map.remove('callerName');

      final callInfo = CallInfo.fromMap(map);

      expect(callInfo.callerName, isNull);
    });

    test('fromMap handles empty metadata', () {
      final map = Map<String, dynamic>.from(testMap);
      map.remove('metadata');

      final callInfo = CallInfo.fromMap(map);

      expect(callInfo.metadata, isEmpty);
    });

    test('toMap creates valid map', () {
      final callInfo = CallInfo(
        callId: 'call-789',
        callerId: 'user-012',
        callerName: 'Jane Smith',
        metadata: {'room': 'meeting-1'},
        receivedAt: testTimestamp,
      );

      final map = callInfo.toMap();

      expect(map['callId'], 'call-789');
      expect(map['callerId'], 'user-012');
      expect(map['callerName'], 'Jane Smith');
      expect(map['metadata'], {'room': 'meeting-1'});
      expect(map['receivedAt'], testTimestamp.millisecondsSinceEpoch);
    });

    test('equality works correctly', () {
      final call1 = CallInfo.fromMap(testMap);
      final call2 = CallInfo.fromMap(testMap);
      final call3 = CallInfo.fromMap({
        ...testMap,
        'callId': 'different-id',
      });

      expect(call1, equals(call2));
      expect(call1, isNot(equals(call3)));
    });

    test('hashCode is consistent', () {
      final call1 = CallInfo.fromMap(testMap);
      final call2 = CallInfo.fromMap(testMap);

      expect(call1.hashCode, equals(call2.hashCode));
    });

    test('toString includes key fields', () {
      final callInfo = CallInfo.fromMap(testMap);
      final str = callInfo.toString();

      expect(str, contains('call-123'));
      expect(str, contains('user-456'));
      expect(str, contains('John Doe'));
    });
  });
}
