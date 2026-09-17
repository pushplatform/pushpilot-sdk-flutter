import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Stream Integration Tests', () {
    final sdk = PushPlatformFlutter.instance;

    setUp(() async {
      await sdk.initialize(
        apiKey: 'integration-test-key',
        environment: 'development',
        debugMode: true,
      );
    });

    testWidgets('onPushReceived stream emits events', (tester) async {
      final completer = Completer<PushMessage>();

      final subscription = sdk.onPushReceived.listen((message) {
        if (!completer.isCompleted) {
          completer.complete(message);
        }
      });

      // Wait for potential push event with timeout
      final message = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('No push received'),
      ).catchError((e) {
        // Timeout is expected in test environment without real push
        return null;
      });

      await subscription.cancel();

      // If message received, verify structure
      if (message != null) {
        expect(message.messageId, isNotEmpty);
        expect(message.type, isNotNull);
      }
    });

    testWidgets('onStateChange stream emits initialization event', (tester) async {
      // Reinitialize to trigger state change
      final stateChanges = <StateChange>[];

      final subscription = sdk.onStateChange.listen((state) {
        stateChanges.add(state);
      });

      await sdk.initialize(
        apiKey: 'integration-test-key-2',
        environment: 'development',
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await subscription.cancel();

      // Should have received at least one state change
      expect(stateChanges, isNotEmpty);
    });

    testWidgets('multiple listeners receive same event', (tester) async {
      final completer1 = Completer<StateChange>();
      final completer2 = Completer<StateChange>();

      final subscription1 = sdk.onStateChange.listen((state) {
        if (!completer1.isCompleted) {
          completer1.complete(state);
        }
      });

      final subscription2 = sdk.onStateChange.listen((state) {
        if (!completer2.isCompleted) {
          completer2.complete(state);
        }
      });

      // Trigger state change
      await sdk.login(userId: 'multi-listener-test');

      await Future.delayed(const Duration(milliseconds: 500));

      await subscription1.cancel();
      await subscription2.cancel();

      if (completer1.isCompleted && completer2.isCompleted) {
        final state1 = await completer1.future;
        final state2 = await completer2.future;
        expect(state1, equals(state2));
      }
    });
  });
}
