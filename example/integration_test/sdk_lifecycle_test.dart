import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SDK Lifecycle Integration Tests', () {
    final sdk = PushPlatformFlutter.instance;

    testWidgets('initialize SDK with valid configuration', (tester) async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        apiBaseURL: 'https://api.test.pushplatform.example',
        environment: 'development',
        debugMode: true,
      );

      // Verify SDK is initialized by checking deviceId is available
      final deviceId = await sdk.deviceId;
      expect(deviceId, isNotNull);
      expect(deviceId, isNotEmpty);
    });

    testWidgets('login with userId after initialization', (tester) async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        environment: 'development',
      );

      await sdk.login(userId: 'integration-test-user');

      final userId = await sdk.userId;
      expect(userId, 'integration-test-user');
    });

    testWidgets('logout clears user session', (tester) async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        environment: 'development',
      );

      await sdk.login(userId: 'integration-test-user');

      final userIdBefore = await sdk.userId;
      expect(userIdBefore, isNotNull);

      await sdk.logout();

      final userIdAfter = await sdk.userId;
      expect(userIdAfter, isNull);
    });

    testWidgets('deviceId remains stable across login/logout', (tester) async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        environment: 'development',
      );

      final deviceIdBefore = await sdk.deviceId;

      await sdk.login(userId: 'test-user');
      final deviceIdDuringLogin = await sdk.deviceId;

      await sdk.logout();
      final deviceIdAfterLogout = await sdk.deviceId;

      expect(deviceIdBefore, equals(deviceIdDuringLogin));
      expect(deviceIdBefore, equals(deviceIdAfterLogout));
    });

    testWidgets('requestPermissions returns result', (tester) async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        environment: 'development',
      );

      final granted = await sdk.requestPermissions();
      expect(granted, isA<bool>());
    });
  });
}
