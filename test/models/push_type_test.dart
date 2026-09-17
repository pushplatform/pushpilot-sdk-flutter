import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/src/models/push_type.dart';

void main() {
  group('PushType', () {
    test('toJson returns correct string values', () {
      expect(PushType.normal.toJson(), 'normal');
      expect(PushType.silent.toJson(), 'silent');
    });

    test('fromJson parses valid values', () {
      expect(PushTypeExtension.fromJson('normal'), PushType.normal);
      expect(PushTypeExtension.fromJson('silent'), PushType.silent);
    });

    test('fromJson defaults to normal for unknown values', () {
      expect(PushTypeExtension.fromJson('unknown'), PushType.normal);
      expect(PushTypeExtension.fromJson(''), PushType.normal);
    });

    test('enum has correct values', () {
      expect(PushType.values.length, 2);
      expect(PushType.values, contains(PushType.normal));
      expect(PushType.values, contains(PushType.silent));
    });
  });
}
