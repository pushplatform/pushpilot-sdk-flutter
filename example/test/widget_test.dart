// Flutter widget test for verification app

import 'package:flutter_test/flutter_test.dart';

import 'package:push_platform_flutter_example/main.dart';

void main() {
  testWidgets('Verification app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VerificationApp());

    // Verify that verification UI elements are present
    expect(find.text('Flutter SDK Runtime Verification'), findsOneWidget);
    expect(find.textContaining('Platform:'), findsOneWidget);
  });
}
