import 'dart:io';
import 'package:flutter/material.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sdk = PushPlatformFlutter.instance;
  String? _installationId;
  String _currentState = 'Not initialized';
  final List<PushMessage> _messages = [];
  CallInfo? _lastCall;
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _listenToEvents();
  }

  void _listenToEvents() {
    // Listen to push messages
    _sdk.onPushReceived.listen((message) {
      setState(() {
        _messages.insert(0, message);
      });
      _showSnackBar('Push received: ${message.title}');
    });

    // Listen to state changes
    _sdk.onStateChange.listen((state) {
      setState(() {
        _currentState = state.toString().split('.').last;
        if (state == StateChange.initialized) {
          _isInitialized = true;
        } else if (state == StateChange.loggedIn) {
          _isLoggedIn = true;
        } else if (state == StateChange.loggedOut) {
          _isLoggedIn = false;
        }
      });
    });

    // Platform-specific: VoIP on iOS
    if (Platform.isIOS) {
      try {
        _sdk.onVoIPCallReceived.listen((callInfo) {
          setState(() {
            _lastCall = callInfo;
          });
          _showIncomingCallDialog(callInfo);
        });
      } catch (e) {
        debugPrint('VoIP not supported: $e');
      }
    }

    // Platform-specific: high-priority calls on Android
    if (Platform.isAndroid) {
      try {
        _sdk.onCallReceived.listen((callInfo) {
          setState(() {
            _lastCall = callInfo;
          });
          _showIncomingCallDialog(callInfo);
        });
      } catch (e) {
        debugPrint('Call notifications not supported: $e');
      }
    }
  }

  Future<void> _initialize() async {
    try {
      await _sdk.initialize(
        apiKey: 'demo-api-key',
        apiBaseURL: 'https://api.staging.pushplatform.example',
        environment: 'development',
        debugMode: true,
      );

      final id = await _sdk.deviceId;
      setState(() {
        _installationId = id;
      });

      _showSnackBar('SDK initialized');
    } catch (e) {
      _showSnackBar('Init failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await _sdk.requestPermissions();
      _showSnackBar('Permission request sent');
    } catch (e) {
      _showSnackBar('Permission request failed: $e');
    }
  }

  Future<void> _login() async {
    try {
      final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      await _sdk.login(userId: userId);
      _showSnackBar('Logged in as $userId');
    } catch (e) {
      _showSnackBar('Login failed: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _sdk.logout();
      _showSnackBar('Logged out');
    } catch (e) {
      _showSnackBar('Logout failed: $e');
    }
  }

  Future<void> _registerVoIP() async {
    if (!Platform.isIOS) {
      _showSnackBar('VoIP is iOS-only');
      return;
    }

    try {
      await _sdk.registerForVoIP();
      _showSnackBar('VoIP registration initiated');
    } catch (e) {
      _showSnackBar('VoIP registration failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showIncomingCallDialog(CallInfo callInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Call ID: ${callInfo.callId}'),
            Text('Caller: ${callInfo.callerName ?? callInfo.callerId}'),
            if (callInfo.metadata.isNotEmpty)
              Text('Metadata: ${callInfo.metadata}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Call accepted (demo only)');
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Push Platform Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Push Platform Flutter'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            _buildStatusCard(),
            _buildControlButtons(),
            const Divider(),
            Expanded(child: _buildMessageList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_currentState',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_installationId != null)
              Text('Installation ID: $_installationId',
                  style: const TextStyle(fontSize: 12)),
            if (_lastCall != null)
              Text('Last call: ${_lastCall!.callId}',
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isInitialized ? null : _initialize,
                  child: const Text('Initialize'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isInitialized ? null : _requestPermissions,
                  child: const Text('Request Permissions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isInitialized || _isLoggedIn ? null : _login,
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isLoggedIn ? null : _logout,
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
          if (Platform.isIOS)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !_isInitialized ? null : _registerVoIP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register VoIP (iOS)'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No push messages received yet'),
      );
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(message.title ?? '(No title)'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.body != null) Text(message.body!),
                const SizedBox(height: 4),
                Text(
                  'Type: ${message.type.name} | ${_formatTimestamp(message.receivedAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Icon(
              message.type == PushType.silent
                  ? Icons.notifications_off
                  : Icons.notifications,
              color: message.type == PushType.silent
                  ? Colors.grey
                  : Colors.blue,
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
