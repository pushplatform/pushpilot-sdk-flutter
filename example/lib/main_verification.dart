import 'dart:io';
import 'package:flutter/material.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  runApp(const VerificationApp());
}

class VerificationApp extends StatefulWidget {
  const VerificationApp({super.key});

  @override
  State<VerificationApp> createState() => _VerificationAppState();
}

class _VerificationAppState extends State<VerificationApp> {
  final _sdk = PushPlatformFlutter.instance;
  final List<String> _logs = [];
  String? _installationId;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _runVerificationFlow();
  }

  void _log(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$timestamp] $message');
      if (isError) _hasError = true;
    });
    debugPrint('[VERIFICATION] $message');
  }

  Future<void> _runVerificationFlow() async {
    _log('=== Flutter SDK Runtime Verification ===');
    _log('Platform: ${Platform.operatingSystem}');
    _log('Flutter version: ${Platform.version}');
    _log('');

    // Step 1: Native module check
    _log('Step 1: Check native module loaded');
    try {
      final type = _sdk.runtimeType.toString();
      _log('✅ Native module type: $type');
    } catch (e) {
      _log('❌ Native module check failed: $e', isError: true);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Step 2: Initialize SDK
    _log('');
    _log('Step 2: Initialize SDK');
    final initStart = DateTime.now();
    try {
      await _sdk.initialize(
        apiKey: 'test-api-key-flutter',
        apiBaseURL: 'https://api.test.pushplatform.example',
        environment: 'development',
        debugMode: true,
      );
      final initDuration = DateTime.now().difference(initStart).inMilliseconds;
      _log('✅ initialize() succeeded (${initDuration}ms)');
    } catch (e) {
      _log('❌ initialize() failed: $e', isError: true);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Get Installation ID
    _log('');
    _log('Step 3: Get Installation ID');
    final idStart = DateTime.now();
    try {
      final id = await _sdk.deviceId;
      final idDuration = DateTime.now().difference(idStart).inMilliseconds;

      if (id == null) {
        _log('❌ deviceId returned null', isError: true);
        return;
      }

      // Validate UUID format
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      if (!uuidRegex.hasMatch(id)) {
        _log('❌ Invalid UUID format: $id', isError: true);
        return;
      }

      setState(() {
        _installationId = id;
      });
      _log('✅ deviceId: $id (${idDuration}ms)');
      _log('✅ UUID format validated');
    } catch (e) {
      _log('❌ deviceId failed: $e', isError: true);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Step 4: Event subscription
    _log('');
    _log('Step 4: Event subscriptions');
    try {
      // Subscribe to push events
      final pushSub = _sdk.onPushReceived.listen((message) {
        _log('📬 onPushReceived: ${message.title}');
      });

      // Subscribe to state changes
      final stateSub = _sdk.onStateChange.listen((state) {
        _log('🔄 onStateChange: $state');
      });

      _log('✅ Event subscriptions created');

      // Test subscription lifecycle
      await Future.delayed(const Duration(seconds: 3));

      pushSub.cancel();
      stateSub.cancel();
      _log('✅ Event subscriptions cancelled (lifecycle test)');
    } catch (e) {
      _log('❌ Event subscription failed: $e', isError: true);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Final summary
    _log('');
    _log('=== Verification Complete ===');
    if (!_hasError) {
      _log('✅ ALL CHECKS PASSED');
      _log('');
      _log('Push delivery: DEFERRED TO E2E (requires APNs/FCM)');
    } else {
      _log('❌ VERIFICATION FAILED - See errors above');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SDK Verification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _hasError ? Colors.red : Colors.green,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter SDK Runtime Verification'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            if (_installationId != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Installation ID: $_installationId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final isError = log.contains('❌');
                  final isSuccess = log.contains('✅');
                  final isHeader = log.contains('===');

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: isError
                            ? Colors.red.shade700
                            : isSuccess
                                ? Colors.green.shade700
                                : isHeader
                                    ? Colors.blue.shade700
                                    : Colors.black87,
                        fontWeight: isHeader || isError ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
