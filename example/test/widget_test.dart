import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter_example/main.dart';

void main() {
  testWidgets('Example starts without credentials or platform calls',
      (tester) async {
    await tester.pumpWidget(const PushPilotExample());
    expect(find.text('PushPilot Flutter SDK'), findsOneWidget);
    expect(find.textContaining('готов к настройке'), findsOneWidget);
  });
}
