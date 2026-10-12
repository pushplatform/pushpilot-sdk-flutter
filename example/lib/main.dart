import 'package:flutter/material.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() => runApp(const PushPilotExample());

/// A credential-free screen. It does not initialize the SDK or send requests.
class PushPilotExample extends StatelessWidget {
  const PushPilotExample({super.key});

  @override
  Widget build(BuildContext context) {
    final sdk = PushPlatformFlutter.instance;
    return MaterialApp(
      title: 'PushPilot',
      home: Scaffold(
        appBar: AppBar(title: const Text('PushPilot Flutter SDK')),
        body: Center(
          child: Text(
            '${sdk.runtimeType} готов к настройке.\n'
            'Укажите UUID приложения, URL API и клиентский ключ по README.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
