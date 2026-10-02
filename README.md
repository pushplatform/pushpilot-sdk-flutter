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

**Security**: Raw device tokens and server credentials are NEVER exposed to Dart. All sensitive data is handled exclusively by the native SDKs. Client API keys (`devices:write` scope) are passed through Dart for initialization, consistent with standard mobile SDK patterns.

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
pod 'PushPlatformSDK', :path => '../pushpilot-sdk-ios'
```

### Android Setup

1. Link to native Android SDK (local development):

```kotlin
// android/build.gradle.kts
dependencies {
    implementation(project(":pushpilot-sdk-android"))
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

#### `initialize()`

Initialize the Push Platform SDK with configuration.

```dart
Future<void> initialize({
  required String apiKey,
  String? apiBaseURL,
  required String environment, // 'production', 'development', or 'sandbox'
  bool debugMode = false,
})
```

**Parameters**:
- `apiKey` - Your application API key from Push Platform dashboard
- `apiBaseURL` - Optional API base URL (defaults to production endpoint)
- `environment` - Environment name (production/development/sandbox)
- `debugMode` - Enable debug logging (default: false)

**Throws**: `PlatformException` if initialization fails

**Example**:
```dart
await PushPlatformFlutter.instance.initialize(
  apiKey: '<set API key from dashboard>',
  environment: 'production',
  debugMode: false,
);
```

#### `requestPermissions()`

Request push notification permissions from the user.

```dart
Future<bool> requestPermissions()
```

**Returns**: `true` if permissions granted, `false` otherwise

**Platform Notes**:
- iOS: Shows system permission dialog (alert, sound, badge)
- Android: On Android 13+, shows POST_NOTIFICATIONS permission dialog; on earlier versions, returns `true` immediately

**Example**:
```dart
final granted = await PushPlatformFlutter.instance.requestPermissions();
if (!granted) {
  // Handle permission denial
}
```

#### `login()`

Login a user to receive personalized push notifications.

```dart
Future<String?> login({
  required String userId,
  Map<String, dynamic>? metadata,
})
```

**Parameters**:
- `userId` - Unique user identifier (1-255 characters)
- `metadata` - Optional user metadata (sent to backend)

**Returns**: Device/installation ID string

**Throws**: `PlatformException` if SDK not initialized or login fails

**Example**:
```dart
final deviceId = await PushPlatformFlutter.instance.login(
  userId: 'user-12345',
  metadata: {
    'name': 'John Doe',
    'email': 'john@example.com',
    'plan': 'premium',
  },
);
print('Device ID: $deviceId');
```

#### `logout()`

Logout the current user.

```dart
Future<void> logout()
```

**Throws**: `PlatformException` if SDK not initialized

**Example**:
```dart
await PushPlatformFlutter.instance.logout();
```

#### `deviceId`

Get the device/installation identifier.

```dart
Future<String?> get deviceId
```

**Returns**: Device ID string or `null` if not available

**Example**:
```dart
final id = await PushPlatformFlutter.instance.deviceId;
print('Device ID: $id');
```

#### `userId`

Get the currently logged-in user identifier.

```dart
Future<String?> get userId
```

**Returns**: User ID string or `null` if no user logged in

**Example**:
```dart
final id = await PushPlatformFlutter.instance.userId;
if (id != null) {
  print('Logged in as: $id');
}
```

### Streams

#### `onPushReceived`

Stream of incoming push notifications.

```dart
Stream<PushMessage> get onPushReceived
```

**Emits**: `PushMessage` objects for both normal and silent pushes

**Example**:
```dart
PushPlatformFlutter.instance.onPushReceived.listen((message) {
  if (message.type == PushType.normal) {
    // Show notification UI
    showNotification(message.title, message.body);
  } else if (message.type == PushType.silent) {
    // Background data update
    syncData(message.data);
  }
});
```

#### `onStateChange`

Stream of SDK state changes.

```dart
Stream<StateChange> get onStateChange
```

**Emits**: `StateChange` enum values (initialized, loggedIn, loggedOut, etc.)

**Example**:
```dart
PushPlatformFlutter.instance.onStateChange.listen((state) {
  switch (state) {
    case StateChange.initialized:
      print('SDK ready');
      break;
    case StateChange.loggedIn:
      print('User logged in');
      break;
    case StateChange.loggedOut:
      print('User logged out');
      break;
    case StateChange.permissionGranted:
      print('Permissions granted');
      break;
    case StateChange.permissionDenied:
      print('Permissions denied');
      break;
    case StateChange.tokenRefreshed:
      print('Device token refreshed');
      break;
    case StateChange.error:
      print('SDK error occurred');
      break;
  }
});
```

### iOS VoIP Extension

#### `registerForVoIP()`

Register for VoIP push notifications (iOS only).

```dart
Future<void> registerForVoIP()
```

**Platform**: iOS only (throws `UnsupportedError` on Android)

**Note**: VoIP registration is automatic when `initialize()` is called. This method is kept for API compatibility and is effectively a no-op.

**Example**:
```dart
if (Platform.isIOS) {
  await PushPlatformFlutter.instance.registerForVoIP();
}
```

#### `onVoIPCallReceived`

Stream of incoming VoIP call notifications (iOS only).

```dart
Stream<CallInfo> get onVoIPCallReceived
```

**Platform**: iOS only (throws `UnsupportedError` on Android)

**Emits**: `CallInfo` objects when VoIP push received

**Example**:
```dart
if (Platform.isIOS) {
  PushPlatformFlutter.instance.onVoIPCallReceived.listen((callInfo) {
    // CallKit UI is already shown by native SDK
    // Update your app UI here
    showIncomingCallScreen(
      callId: callInfo.callId,
      callerName: callInfo.callerName ?? 'Unknown',
    );
  });
}
```

### Android Call Extension

#### `onCallReceived`

Stream of incoming high-priority call notifications (Android only).

```dart
Stream<CallInfo> get onCallReceived
```

**Platform**: Android only (throws `UnsupportedError` on iOS)

**Emits**: `CallInfo` objects when call notification received

**Example**:
```dart
if (Platform.isAndroid) {
  PushPlatformFlutter.instance.onCallReceived.listen((callInfo) {
    // Full-screen intent notification already shown by native SDK
    // Update your app UI here
    showIncomingCallScreen(
      callId: callInfo.callId,
      callerName: callInfo.callerName ?? 'Unknown',
    );
  });
}
```

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
  initialized,        // SDK initialized successfully
  loggedIn,          // User logged in
  loggedOut,         // User logged out
  permissionGranted, // Push permissions granted
  permissionDenied,  // Push permissions denied
  tokenRefreshed,    // Device token refreshed (background)
  error,             // SDK error occurred
}
```

### PushType

```dart
enum PushType {
  normal, // Alert/banner notification with title/body
  silent, // Background data push (no UI)
}
```

## Error Handling

All SDK methods can throw `PlatformException` with standardized error codes:

```dart
try {
  await PushPlatformFlutter.instance.login(userId: 'user-123');
} on PlatformException catch (e) {
  switch (e.code) {
    case 'NOT_INITIALIZED':
      print('SDK not initialized - call initialize() first');
      break;
    case 'INVALID_ARGUMENTS':
      print('Invalid arguments: ${e.message}');
      break;
    case 'NETWORK_ERROR':
      print('Network error: ${e.message}');
      break;
    case 'API_ERROR':
      print('API error: ${e.message}');
      break;
    case 'INVALID_TOKEN':
      print('Invalid device token');
      break;
    case 'MAX_RETRIES_EXCEEDED':
      print('Operation failed after retries');
      break;
    case 'STORAGE_ERROR':
      print('Storage error: ${e.message}');
      break;
    default:
      print('Unknown error: ${e.code} - ${e.message}');
  }
}
```

### Error Codes

| Code | Description | Retry? |
|------|-------------|--------|
| `NOT_INITIALIZED` | SDK not initialized | No - call `initialize()` first |
| `INVALID_ARGUMENTS` | Invalid method arguments | No - fix arguments |
| `NETWORK_ERROR` | Network connectivity issue | Yes - retry with backoff |
| `API_ERROR` | Backend API error | Depends - check message |
| `INVALID_TOKEN` | Device token invalid | No - re-register device |
| `MAX_RETRIES_EXCEEDED` | Retry limit reached | No - operation failed |
| `STORAGE_ERROR` | Local storage error | Yes - may be transient |

### Error Handling Best Practices

1. **Always wrap SDK calls in try-catch**:
```dart
try {
  await sdk.login(userId: userId);
} on PlatformException catch (e) {
  handleError(e);
}
```

2. **Check initialization state**:
```dart
// Listen to state changes
sdk.onStateChange.listen((state) {
  if (state == StateChange.initialized) {
    // Safe to call other methods
  }
});
```

3. **Handle permission denial gracefully**:
```dart
final granted = await sdk.requestPermissions();
if (!granted) {
  showSettingsDialog(); // Guide user to Settings
}
```

4. **Retry on network errors**:
```dart
Future<void> loginWithRetry(String userId, {int maxAttempts = 3}) async {
  for (var i = 0; i < maxAttempts; i++) {
    try {
      await sdk.login(userId: userId);
      return;
    } on PlatformException catch (e) {
      if (e.code == 'NETWORK_ERROR' && i < maxAttempts - 1) {
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
        continue;
      }
      rethrow;
    }
  }
}
```

## Testing

### Unit Tests

Run Dart unit tests:

```bash
cd .
flutter test
```

Run with coverage:

```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

### Integration Tests

Run Flutter integration tests (requires iOS simulator or Android emulator):

```bash
cd example
flutter test integration_test/
```

### Platform Tests

**iOS Tests** (requires Xcode):

```bash
cd ios
xcodebuild test -scheme PushPlatformFlutter -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Android Tests** (requires Android Studio):

```bash
cd android
./gradlew test
```

### Test Coverage

The SDK includes comprehensive test coverage:

- **78+ Dart unit tests**: Method channels, event channels, platform extensions, error handling
- **15+ Flutter integration tests**: SDK lifecycle, event streams, platform-specific features
- **11+ iOS platform tests**: Method channel bridge, VoIP methods, delegation
- **16+ Android platform tests**: Method channel bridge, call methods, validation

### Writing Tests

Example unit test with mocked method channel:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushPlatformFlutter', () {
    const MethodChannel channel = MethodChannel('com.pushplatform/sdk');
    final sdk = PushPlatformFlutter.instance;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'login') {
          return 'device-123';
        }
        return null;
      });
    });

    test('login returns deviceId', () async {
      final deviceId = await sdk.login(userId: 'user-123');
      expect(deviceId, 'device-123');
    });
  });
}
```

## Security

- ✅ Raw device tokens NEVER exposed to Dart
- ✅ Client API keys (`devices:write` scope) passed through Dart for initialization
- ✅ Server API keys (`messages:send` scope) NEVER embedded in app
- ✅ Token prefixes/hashes NEVER exposed to Dart
- ✅ All tokens and internal credentials handled by native SDK
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

**Problem**: VoIP push notifications not received

**Solutions**:
1. Ensure VoIP background mode enabled in Xcode:
   - Xcode → Target → Signing & Capabilities → Background Modes
   - Enable "Voice over IP"

2. Check VoIP entitlement in certificate:
   ```bash
   # Verify certificate has VoIP entitlement
   security find-identity -v -p codesigning
   ```

3. Verify VoIP topic in push payload:
   - VoIP push MUST use `<bundle_id>.voip` topic
   - Standard push uses `<bundle_id>` topic

4. Check PushKit registration:
   - VoIP registration is automatic after `initialize()`
   - No explicit `registerForVoIP()` call needed
   - Check logs for "PushKit registered" message

### iOS: Permission request not showing

**Problem**: `requestPermissions()` doesn't show system dialog

**Cause**: The native iOS SDK doesn't expose a public permission request method. The Flutter SDK calls `UNUserNotificationCenter.requestAuthorization()` directly.

**Solution**: This is expected behavior. The permission dialog will show on first `requestPermissions()` call. Subsequent calls return the cached permission status.

**Workaround for advanced scenarios**:
```dart
// Check current permission status
final granted = await PushPlatformFlutter.instance.requestPermissions();
if (!granted) {
  // Guide user to Settings app to enable notifications
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Notifications Disabled'),
      content: Text('Please enable notifications in Settings'),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

### iOS: CallKit UI not showing

**Problem**: VoIP call received but no CallKit UI

**Cause**: CallKit UI is managed by native SDK, not Flutter layer

**Solution**:
1. Verify CallKit entitlement in Xcode capabilities
2. Check native SDK logs for CallKit errors
3. Ensure VoIP push payload includes required fields:
   ```json
   {
     "callId": "call-123",
     "callerId": "+1234567890",
     "callerName": "John Doe"
   }
   ```

### Android: Notifications not showing

**Problem**: Push notifications received but not displayed

**Solutions**:
1. Check POST_NOTIFICATIONS permission (Android 13+):
   ```xml
   <!-- AndroidManifest.xml -->
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

2. Verify notification channel created (API 26+):
   - Native SDK creates default channel automatically
   - Check logcat for "NotificationChannel created" message

3. Ensure FCM configuration:
   ```bash
   # Verify google-services.json exists
   ls -la android/app/google-services.json
   ```

4. Check notification importance level:
   - Call notifications use IMPORTANCE_HIGH
   - Regular notifications use IMPORTANCE_DEFAULT
   - Silent notifications don't show UI (expected)

### Android: High-priority call notifications not full-screen

**Problem**: Call notifications show as banner, not full-screen

**Cause**: Full-screen intent requires Android 10+ and USE_FULL_SCREEN_INTENT permission

**Solutions**:
1. Add permission to manifest:
   ```xml
   <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
   ```

2. Verify Android 10+ (API 29+):
   ```kotlin
   // Native SDK checks API level automatically
   if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
       // Full-screen intent enabled
   }
   ```

3. Check device Do Not Disturb settings:
   - Full-screen intents may be blocked by DND mode
   - Test with DND disabled

### Flutter: Platform exception on initialize

**Problem**: `PlatformException` thrown when calling `initialize()`

**Common causes and solutions**:

1. **NOT_INITIALIZED error when calling other methods**:
   ```dart
   // WRONG: Calling login() before initialize()
   await sdk.login(userId: 'user-123'); // Throws NOT_INITIALIZED
   
   // CORRECT: Initialize first
   await sdk.initialize(apiKey: 'key', environment: 'production');
   await sdk.login(userId: 'user-123');
   ```

2. **INVALID_ARGUMENTS error**:
   ```dart
   // Check required parameters
   await sdk.initialize(
     apiKey: 'your-key',      // Required
     environment: 'production', // Required
     debugMode: true,          // Optional
   );
   ```

3. **Native SDK dependencies not linked**:
   ```bash
   # iOS: Check Podfile
   cd ios && pod install
   
   # Android: Check build.gradle.kts
   cd android && ./gradlew dependencies
   ```

4. **Network connectivity issues**:
   ```dart
   try {
     await sdk.initialize(
       apiKey: 'key',
       apiBaseURL: 'https://api.pushplatform.example',
       environment: 'production',
     );
   } on PlatformException catch (e) {
     if (e.code == 'NETWORK_ERROR') {
       // Check internet connectivity
       print('Network error: ${e.message}');
     }
   }
   ```

### Flutter: Stream not emitting events

**Problem**: `onPushReceived` or other streams not emitting

**Solutions**:

1. **Start listening before push arrives**:
   ```dart
   // WRONG: Listen after push already received
   void initState() {
     super.initState();
     // Push may arrive before this listener
     Future.delayed(Duration(seconds: 5), () {
       sdk.onPushReceived.listen((msg) => print(msg));
     });
   }
   
   // CORRECT: Listen immediately
   void initState() {
     super.initState();
     sdk.onPushReceived.listen((msg) => print(msg));
   }
   ```

2. **Check stream subscription lifecycle**:
   ```dart
   class _MyWidgetState extends State<MyWidget> {
     StreamSubscription? _subscription;
     
     @override
     void initState() {
       super.initState();
       _subscription = sdk.onPushReceived.listen((msg) {
         setState(() { /* update UI */ });
       });
     }
     
     @override
     void dispose() {
       _subscription?.cancel();
       super.dispose();
     }
   }
   ```

3. **Verify SDK initialized**:
   ```dart
   // Listen to state changes first
   sdk.onStateChange.listen((state) {
     if (state == StateChange.initialized) {
       print('SDK ready - streams active');
     }
   });
   
   await sdk.initialize(/* ... */);
   ```

### Platform-specific: UnsupportedError

**Problem**: `UnsupportedError` thrown when calling platform-specific methods

**Cause**: Calling iOS-only methods on Android or vice versa

**Solution**: Always check platform before calling:

```dart
import 'dart:io';

// WRONG: Calling iOS method on Android
await sdk.registerForVoIP(); // Throws UnsupportedError on Android

// CORRECT: Check platform first
if (Platform.isIOS) {
  await sdk.registerForVoIP();
  sdk.onVoIPCallReceived.listen((call) {
    // Handle VoIP call
  });
} else if (Platform.isAndroid) {
  sdk.onCallReceived.listen((call) {
    // Handle call notification
  });
}
```

### Debug Logging

Enable debug mode for verbose logging:

```dart
await PushPlatformFlutter.instance.initialize(
  apiKey: 'your-key',
  environment: 'development',
  debugMode: true, // Enable debug logs
);
```

**iOS logs** (Xcode console):
```
[PushPlatform] SDK initialized
[PushPlatform] PushKit registered: <token>
[PushPlatform] VoIP push received: <payload>
```

**Android logs** (logcat):
```bash
adb logcat | grep PushPlatform
# [PushPlatform] SDK initialized
# [PushPlatform] FCM token: <token>
# [PushPlatform] Notification received: <payload>
```

### Getting Help

If issues persist:

1. Check [GitHub Issues](https://github.com/pushplatform/sdk-flutter/issues)
2. Enable debug logging and capture logs
3. Provide minimal reproduction example
4. Include platform (iOS/Android), OS version, and SDK version

## License

MIT

## Support

For issues and questions, please open an issue on GitHub.
