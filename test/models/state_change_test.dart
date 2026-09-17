import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/src/models/state_change.dart';

void main() {
  group('StateChange', () {
    test('enum has all expected values', () {
      expect(StateChange.values.length, 7);
      expect(StateChange.values, contains(StateChange.initialized));
      expect(StateChange.values, contains(StateChange.permissionsGranted));
      expect(StateChange.values, contains(StateChange.permissionsDenied));
      expect(StateChange.values, contains(StateChange.registered));
      expect(StateChange.values, contains(StateChange.loggedIn));
      expect(StateChange.values, contains(StateChange.loggedOut));
      expect(StateChange.values, contains(StateChange.error));
    });

    test('toJson returns correct string values', () {
      expect(StateChange.initialized.toJson(), 'initialized');
      expect(StateChange.permissionsGranted.toJson(), 'permissionsGranted');
      expect(StateChange.permissionsDenied.toJson(), 'permissionsDenied');
      expect(StateChange.registered.toJson(), 'registered');
      expect(StateChange.loggedIn.toJson(), 'loggedIn');
      expect(StateChange.loggedOut.toJson(), 'loggedOut');
      expect(StateChange.error.toJson(), 'error');
    });

    test('fromJson parses valid values', () {
      expect(StateChangeExtension.fromJson('initialized'), StateChange.initialized);
      expect(StateChangeExtension.fromJson('permissionsGranted'), StateChange.permissionsGranted);
      expect(StateChangeExtension.fromJson('permissionsDenied'), StateChange.permissionsDenied);
      expect(StateChangeExtension.fromJson('registered'), StateChange.registered);
      expect(StateChangeExtension.fromJson('loggedIn'), StateChange.loggedIn);
      expect(StateChangeExtension.fromJson('loggedOut'), StateChange.loggedOut);
      expect(StateChangeExtension.fromJson('error'), StateChange.error);
    });

    test('fromJson defaults to error for unknown values', () {
      expect(StateChangeExtension.fromJson('unknown'), StateChange.error);
      expect(StateChangeExtension.fromJson(''), StateChange.error);
      expect(StateChangeExtension.fromJson('invalid'), StateChange.error);
    });
  });
}
