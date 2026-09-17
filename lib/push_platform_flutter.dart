/// Flutter SDK for Push Platform
///
/// This is a thin wrapper over native iOS/Android SDKs.
/// All business logic, retry, deduplication, and token management
/// happen in the native layer.
///
/// ## Usage
///
/// ```dart
/// import 'package:push_platform_flutter/push_platform_flutter.dart';
///
/// // Initialize
/// await PushPlatformFlutter.instance.initialize(
///   apiKey: 'your-api-key',
///   environment: 'production',
/// );
///
/// // Request permissions
/// final granted = await PushPlatformFlutter.instance.requestPermissions();
///
/// // Login
/// await PushPlatformFlutter.instance.login(userId: 'user-123');
///
/// // Listen to push messages
/// PushPlatformFlutter.instance.onPushReceived.listen((message) {
///   print('Received: ${message.title}');
/// });
/// ```
library push_platform_flutter;

export 'src/push_platform_flutter_impl.dart';
export 'src/models/push_message.dart';
export 'src/models/call_info.dart';
export 'src/models/state_change.dart';
export 'src/models/push_type.dart';
export 'src/extensions/voip_extension.dart';
export 'src/extensions/call_extension.dart';
