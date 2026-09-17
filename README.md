# Push Platform Flutter SDK

Flutter SDK for Push Platform - a thin wrapper over native iOS/Android SDKs.

## Features

- ✅ Normal push notifications (alert/banner)
- ✅ Silent push notifications (background data updates)
- ✅ iOS VoIP push (PushKit + CallKit)
- ✅ Android high-priority call notifications
- ✅ Type-safe Dart API
- ✅ Cross-platform support (iOS 13+, Android 5.0+)
- ✅ User login/logout
- ✅ State change events

## Architecture

This SDK is a **thin wrapper** over the native iOS and Android SDKs. All business logic, retry mechanisms, deduplication, and token management happen in the native layer. The Flutter plugin only provides:

1. Type-safe Dart API
2. Platform channel bindings (MethodChannel + EventChannel)
3. Event stream controllers
4. Serialization/deserialization between Dart ↔ Native

**Security**: Raw device tokens, API keys, and credentials are NEVER exposed to Dart. All sensitive data is handled exclusively by the native SDKs.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  push_platform_flutter: ^0.1.0
```

### iOS Setup

1. Add capabilities in Xcode:
   - Push Notifications
   - Background Modes: Remote notifications, Voice over IP (if using VoIP)

2. Link to native iOS SDK (local development):

```ruby
# ios/Podfile
pod 'PushPlatformSDK', :path => '../../../sdk-ios'
```

### Android Setup

1. Link to native Android SDK (local development):

```kotlin
// android/build.gradle.kts
dependencies {
    implementation(project(":sdk-android"))
}
```

2. Add permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" /> <!-- Android 13+ -->
```

## Quick Start

```dart
import 'package:push_platform_flutter/push_platform_flutter.dart';

// Initialize SDK
await PushPlatformFlutter.instance.initialize(
  apiKey: 'your-api-key',
  environment: 'production',
);

// Request permissions
final granted = await PushPlatformFlutter.instance.requestPermissions();
if (!granted) {
  print('Push notifications denied');
  return;
}

// Login user
final deviceId = await PushPlatformFlutter.instance.login(
  userId: 'user-123',
  metadata: {'source': 'flutter_app'},
);
print('Logged in with device: $deviceId');

// Listen to push messages
PushPlatformFlutter.instance.onPushReceived.listen((message) {
  print('Push received: ${message.title}');
  print('Body: ${message.body}');
  print('Data: ${message.data}');
  print('Type: ${message.type}'); // normal or silent
});

// Listen to state changes
PushPlatformFlutter.instance.onStateChange.listen((state) {
  print('SDK state: $state');
});

// Logout
await PushPlatformFlutter.instance.logout();
```

## VoIP Push (iOS only)

```dart
import 'dart:io';
import 'package:push_platform_flutter/push_platform_flutter.dart';

if (Platform.isIOS) {
  // VoIP registration happens automatically after initialize()
  // Optional: Call registerForVoIP() for explicit API compatibility (no-op)
  await PushPlatformFlutter.instance.registerForVoIP();
  
  // Listen to VoIP calls
  PushPlatformFlutter.instance.onVoIPCallReceived.listen((callInfo) {
    print('Incoming VoIP call from: ${callInfo.callerName}');
    print('Call ID: ${callInfo.callId}');
    print('Caller ID: ${callInfo.callerId}');
    
    // CallKit UI is already shown by native SDK
    // Use this event to update your app UI
  });
}
```

**Note**: VoIP registration is automatic. The native SDK's `PushKitManager` registers for VoIP push immediately when `initialize()` is called. The `registerForVoIP()` method is kept for API compatibility but is effectively a no-op.

## High-Priority Call Push (Android only)

```dart
import 'dart:io';
import 'package:push_platform_flutter/push_platform_flutter.dart';

if (Platform.isAndroid) {
  // Listen to call notifications
  PushPlatformFlutter.instance.onCallReceived.listen((callInfo) {
    print('Incoming call from: ${callInfo.callerName}');
    print('Call ID: ${callInfo.callId}');
    
    // Notification is already shown by native SDK
    // Use this event to update your app UI
  });
}
```

## API Reference

### Core Methods

- `initialize({required String apiKey, String apiBaseURL = 'https://api.pushplatform.example', required String environment, bool debugMode = false})` - Initialize SDK
- `requestPermissions()` - Request push notification permissions (returns `bool`)
- `login({required String userId, Map<String, dynamic>? metadata})` - Login user (returns `String?` deviceId)
- `logout()` - Logout current user
- `deviceId` - Get device identifier (returns `Future<String?>`)
- `userId` - Get logged-in user identifier (returns `Future<String?>`)

### Streams

- `onPushReceived` - Stream of `PushMessage` events
- `onStateChange` - Stream of `StateChange` events

### iOS VoIP Extension

- `registerForVoIP()` - Register for VoIP push (iOS only, automatic - kept for API compatibility)
- `onVoIPCallReceived` - Stream of `CallInfo` events (iOS only)

### Android Call Extension

- `onCallReceived` - Stream of `CallInfo` events (Android only)

## Data Models

### PushMessage

```dart
class PushMessage {
  final String messageId;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final PushType type; // normal or silent
  final DateTime receivedAt;
}
```

### CallInfo

```dart
class CallInfo {
  final String callId;
  final String callerId;
  final String? callerName;
  final Map<String, dynamic> metadata;
  final DateTime receivedAt;
}
```

### StateChange

```dart
enum StateChange {
  initialized,
  permissionsGranted,
  permissionsDenied,
  registered,
  loggedIn,
  loggedOut,
  error,
}
```

## Error Handling

All SDK methods can throw `PlatformException`:

```dart
try {
  await PushPlatformFlutter.instance.login(userId: 'user-123');
} on PlatformException catch (e) {
  print('Login failed: ${e.code} - ${e.message}');
}
```

Common error codes:
- `NOT_INITIALIZED` - SDK not initialized
- `PERMISSION_DENIED` - Push permissions denied
- `NETWORK_ERROR` - Network connectivity issue
- `INVALID_CREDENTIALS` - Invalid API credentials

## Testing

Run unit tests:

```bash
flutter test
```

Run with coverage:

```bash
flutter test --coverage
```

## Security

- ✅ Raw device tokens NEVER exposed to Dart
- ✅ API keys NEVER exposed to Dart
- ✅ Token prefixes/hashes NEVER exposed to Dart
- ✅ All credentials handled by native SDK
- ✅ Keychain storage (iOS), EncryptedSharedPreferences (Android)

## Retry and Deduplication

All retry logic and event deduplication are handled by the native iOS/Android SDKs:

- ✅ Exponential backoff with jitter
- ✅ LRU cache for deduplication (100 entries, 24h TTL)
- ✅ Offline queue with automatic retry
- ❌ NO retry logic in Dart layer

## Platform-Specific Features

### iOS
- VoIP push via PushKit
- CallKit integration (native Swift)
- Background push handling
- Keychain credential storage

### Android
- High-priority call notifications
- Notification channels (API 26+)
- Runtime permission request (API 33+)
- EncryptedSharedPreferences storage

## Troubleshooting

### iOS: VoIP not working

- Ensure VoIP background mode is enabled in Xcode capabilities
- Check that your certificate has VoIP entitlement
- VoIP push must be sent to `<bundle_id>.voip` topic
- VoIP registration is automatic - no explicit call needed

### iOS: Permission request implementation

- The Flutter SDK calls `UNUserNotificationCenter.requestAuthorization()` directly
- This is because the native iOS SDK doesn't expose a public permission request method
- The app must handle permission status changes via `UNUserNotificationCenter` delegate

### Android: Notifications not showing

- Check POST_NOTIFICATIONS permission (Android 13+)
- Verify notification channel is created (API 26+)
- Ensure FCM service account JSON is configured

### Flutter: Platform exception on initialize

- Verify native SDK dependencies are linked correctly
- Check that API URL is reachable
- Ensure application ID matches backend configuration

## License

MIT

## Support

For issues and questions, please open an issue on GitHub.
