# Troubleshooting Guide

This guide covers common issues, their causes, and solutions for the Push Platform Flutter SDK.

## Table of Contents

- [iOS Issues](#ios-issues)
  - [VoIP Push Not Working](#voip-push-not-working)
  - [Permission Dialog Not Showing](#permission-dialog-not-showing)
  - [CallKit UI Not Appearing](#callkit-ui-not-appearing)
  - [APNs Registration Failed](#apns-registration-failed)
- [Android Issues](#android-issues)
  - [Notifications Not Showing](#notifications-not-showing)
  - [Full-Screen Intent Not Working](#full-screen-intent-not-working)
  - [FCM Token Registration Failed](#fcm-token-registration-failed)
  - [Permission Denied on Android 13+](#permission-denied-on-android-13)
- [Flutter Issues](#flutter-issues)
  - [Platform Exception on Initialize](#platform-exception-on-initialize)
  - [Stream Not Emitting Events](#stream-not-emitting-events)
  - [UnsupportedError on Platform Methods](#unsupportederror-on-platform-methods)
- [Build Issues](#build-issues)
  - [iOS Pod Install Failed](#ios-pod-install-failed)
  - [Android Gradle Build Failed](#android-gradle-build-failed)
- [Runtime Issues](#runtime-issues)
  - [App Crashes on Push Reception](#app-crashes-on-push-reception)
  - [Memory Leaks](#memory-leaks)
  - [High Battery Drain](#high-battery-drain)

---

## iOS Issues

### VoIP Push Not Working

**Symptoms**:
- VoIP push notifications not received
- CallKit UI not shown
- No error messages in logs

**Possible Causes**:

1. **Missing VoIP Background Mode**

   **Check**:
   ```bash
   # Check Info.plist for VoIP background mode
   /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist | grep voip
   ```

   **Fix**:
   - Open Xcode → Target → Signing & Capabilities
   - Add "Background Modes" capability
   - Enable "Voice over IP"

2. **Certificate Missing VoIP Entitlement**

   **Check**:
   ```bash
   # Check provisioning profile
   security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | grep -A 5 Entitlements
   ```

   **Fix**:
   - Regenerate certificate with VoIP entitlement
   - Download new provisioning profile
   - Re-sign app

3. **Wrong VoIP Topic**

   **Check**: Verify push payload sent to correct topic

   **Expected**: `<bundle_id>.voip` (e.g., `com.example.app.voip`)
   
   **Fix**: Update backend to use `.voip` suffix for VoIP push

4. **VoIP Registration Not Automatic**

   **Note**: The SDK automatically registers for VoIP on `initialize()`. No explicit call needed.

   **Verify**:
   ```swift
   // Check logs for:
   [PushPlatform] PushKit registered with token: <token>
   ```

### Permission Dialog Not Showing

**Symptoms**:
- `requestPermissions()` returns immediately without showing dialog
- Permission always returns `false`

**Possible Causes**:

1. **Permission Already Determined**

   **Check**:
   ```dart
   // Check current permission status
   final granted = await PushPlatformFlutter.instance.requestPermissions();
   print('Permission: $granted');
   ```

   **Fix**: If permission already denied, guide user to Settings:
   ```dart
   if (!granted) {
     // Show alert with "Open Settings" button
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

2. **App Deleted and Reinstalled**

   **Cause**: iOS remembers permission denial even after reinstall

   **Fix**: Reset simulator or device:
   ```bash
   # Simulator
   xcrun simctl erase all
   
   # Device: Settings → General → Reset → Reset Location & Privacy
   ```

3. **TestFlight Build**

   **Cause**: TestFlight builds may have different permission behavior

   **Fix**: Test on real device with production build

### CallKit UI Not Appearing

**Symptoms**:
- VoIP push received but no CallKit UI
- `onVoIPCallReceived` stream emits event but no system UI

**Possible Causes**:

1. **Missing CallKit Payload Fields**

   **Check**: Verify push payload includes required fields:
   ```json
   {
     "callId": "call-123",      // Required
     "callerId": "+1234567890", // Required
     "callerName": "John Doe"   // Optional but recommended
   }
   ```

   **Fix**: Update backend to include all required fields

2. **CallKit Not Enabled**

   **Check**:
   ```bash
   # Check Info.plist
   /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist
   ```

   **Fix**: Ensure app linked against CallKit framework

3. **Do Not Disturb Mode**

   **Cause**: DND may suppress CallKit UI

   **Fix**: Test with DND disabled

4. **Multiple VoIP Push in Quick Succession**

   **Cause**: iOS may throttle CallKit if too many calls in short time

   **Fix**: Implement call queueing on backend

### APNs Registration Failed

**Symptoms**:
- `StateChange.error` emitted after `initialize()`
- Logs show "APNs registration failed"

**Possible Causes**:

1. **Simulator Without APNs Support**

   **Cause**: Older simulators don't support APNs

   **Fix**: Use physical device or Xcode 11.4+ simulator

2. **Invalid Provisioning Profile**

   **Check**:
   ```bash
   codesign -d --entitlements :- ios/Runner.app
   ```

   **Fix**: Ensure `aps-environment` entitlement present

3. **Network Issues**

   **Cause**: Device can't reach APNs servers

   **Fix**: Check network connectivity, disable VPN

---

## Android Issues

### Notifications Not Showing

**Symptoms**:
- Push received (logs confirm) but no notification shown
- Silent push works but normal push doesn't

**Possible Causes**:

1. **Missing POST_NOTIFICATIONS Permission (Android 13+)**

   **Check**:
   ```xml
   <!-- AndroidManifest.xml -->
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

   **Fix**: Add permission and request at runtime:
   ```dart
   final granted = await PushPlatformFlutter.instance.requestPermissions();
   ```

2. **Notification Channel Disabled**

   **Check**: User may have disabled channel in Settings

   **Fix**: Guide user to Settings:
   ```dart
   // Check notification settings
   if (!granted) {
     // On Android, open app notification settings
     openAppSettings();
   }
   ```

3. **Do Not Disturb Mode**

   **Cause**: DND suppresses notifications

   **Fix**: Test with DND disabled

4. **Battery Saver Mode**

   **Cause**: Battery optimization may delay/drop notifications

   **Fix**: Whitelist app from battery optimization:
   ```dart
   // Request to ignore battery optimization
   // (requires REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission)
   ```

5. **Missing google-services.json**

   **Check**:
   ```bash
   ls -la android/app/google-services.json
   ```

   **Fix**: Download from Firebase Console and place in `android/app/`

### Full-Screen Intent Not Working

**Symptoms**:
- Call notification shows as banner instead of full-screen
- No incoming call UI

**Possible Causes**:

1. **Missing USE_FULL_SCREEN_INTENT Permission**

   **Check**:
   ```xml
   <!-- AndroidManifest.xml -->
   <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
   ```

   **Fix**: Add permission to manifest

2. **Android Version < 10**

   **Cause**: Full-screen intent requires Android 10+ (API 29+)

   **Fix**: Use high-priority notification on older versions

3. **Do Not Disturb Mode**

   **Cause**: DND may block full-screen intent

   **Fix**: Request DND exception:
   ```kotlin
   // Native code to request DND access
   val notificationManager = getSystemService(NotificationManager::class.java)
   if (!notificationManager.isNotificationPolicyAccessGranted) {
       val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
       startActivity(intent)
   }
   ```

4. **Screen Locked**

   **Cause**: Some devices don't show full-screen intent on lock screen

   **Fix**: Ensure notification uses correct flags:
   ```kotlin
   // Native SDK should set:
   setFullScreenIntent(pendingIntent, true)
   setCategory(NotificationCompat.CATEGORY_CALL)
   setPriority(NotificationCompat.PRIORITY_HIGH)
   ```

### FCM Token Registration Failed

**Symptoms**:
- `StateChange.error` after `initialize()`
- Logs show "FCM registration failed"

**Possible Causes**:

1. **google-services.json Missing or Invalid**

   **Check**:
   ```bash
   cat android/app/google-services.json | jq '.project_info.project_id'
   ```

   **Fix**: Re-download from Firebase Console

2. **Firebase SDK Version Mismatch**

   **Check**:
   ```kotlin
   // android/build.gradle.kts
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

   **Fix**: Update to latest version

3. **Play Services Not Available**

   **Cause**: Device doesn't have Google Play Services

   **Fix**: Use FCM direct boot or alternative push service

### Permission Denied on Android 13+

**Symptoms**:
- `requestPermissions()` returns `false`
- User never saw permission dialog

**Possible Causes**:

1. **Permission Not Declared in Manifest**

   **Fix**:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

2. **Permission Already Denied**

   **Fix**: Guide user to Settings:
   ```dart
   if (!granted) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Permission Required'),
         content: Text('Please enable notifications in app settings'),
         actions: [
           TextButton(
             onPressed: () => openAppSettings(),
             child: Text('Settings'),
           ),
         ],
       ),
     );
   }
   ```

---

## Flutter Issues

### Platform Exception on Initialize

**Symptoms**:
- `initialize()` throws `PlatformException`
- Error codes: `NOT_INITIALIZED`, `INVALID_ARGUMENTS`, `NETWORK_ERROR`

**Solutions by Error Code**:

#### `NOT_INITIALIZED`

**Cause**: Calling other methods before `initialize()`

**Fix**:
```dart
// WRONG
await sdk.login(userId: 'user-123'); // Throws NOT_INITIALIZED

// CORRECT
await sdk.initialize(apiKey: 'key', environment: 'production');
await sdk.login(userId: 'user-123');
```

#### `INVALID_ARGUMENTS`

**Cause**: Missing required parameters or invalid values

**Fix**:
```dart
// Check all required parameters
await sdk.initialize(
  apiKey: 'your-api-key',     // Required, non-empty
  environment: 'production',   // Required: 'production', 'development', or 'sandbox'
  debugMode: true,             // Optional, defaults to false
);
```

#### `NETWORK_ERROR`

**Cause**: Cannot reach API server

**Fix**:
1. Check internet connectivity
2. Verify `apiBaseURL` is correct
3. Check firewall/proxy settings
4. Retry with exponential backoff:
```dart
Future<void> initializeWithRetry({int maxAttempts = 3}) async {
  for (var i = 0; i < maxAttempts; i++) {
    try {
      await sdk.initialize(
        apiKey: apiKey,
        environment: environment,
      );
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

### Stream Not Emitting Events

**Symptoms**:
- `onPushReceived.listen()` callback never called
- Push received (logs confirm) but Dart never sees it

**Possible Causes**:

1. **Listening Too Late**

   **Problem**:
   ```dart
   void initState() {
     super.initState();
     // Push arrives during this delay
     Future.delayed(Duration(seconds: 5), () {
       sdk.onPushReceived.listen((msg) => print(msg)); // Too late
     });
   }
   ```

   **Fix**:
   ```dart
   void initState() {
     super.initState();
     // Listen immediately
     sdk.onPushReceived.listen((msg) {
       setState(() {
         messages.add(msg);
       });
     });
   }
   ```

2. **Stream Subscription Cancelled**

   **Problem**:
   ```dart
   void initState() {
     super.initState();
     final sub = sdk.onPushReceived.listen((msg) => print(msg));
     sub.cancel(); // Oops, cancelled immediately
   }
   ```

   **Fix**: Keep subscription alive:
   ```dart
   class _MyWidgetState extends State<MyWidget> {
     StreamSubscription? _subscription;
     
     @override
     void initState() {
       super.initState();
       _subscription = sdk.onPushReceived.listen((msg) {
         // Handle message
       });
     }
     
     @override
     void dispose() {
       _subscription?.cancel();
       super.dispose();
     }
   }
   ```

3. **SDK Not Initialized**

   **Problem**: Streams only work after SDK initialized

   **Fix**: Listen to state changes:
   ```dart
   sdk.onStateChange.listen((state) {
     if (state == StateChange.initialized) {
       // Now safe to receive push events
       print('SDK ready');
     }
   });
   ```

### UnsupportedError on Platform Methods

**Symptoms**:
- `UnsupportedError` thrown when calling methods
- Error message: "Not supported on this platform"

**Cause**: Calling platform-specific methods on wrong platform

**Examples**:

```dart
// WRONG: Calling iOS method on Android
await sdk.registerForVoIP(); // Throws on Android

// WRONG: Listening to iOS stream on Android
sdk.onVoIPCallReceived.listen((call) {}); // Throws on Android
```

**Fix**: Always check platform:

```dart
import 'dart:io';

if (Platform.isIOS) {
  // iOS-only code
  await sdk.registerForVoIP();
  sdk.onVoIPCallReceived.listen((call) {
    print('VoIP call: ${call.callerName}');
  });
} else if (Platform.isAndroid) {
  // Android-only code
  sdk.onCallReceived.listen((call) {
    print('Call notification: ${call.callerName}');
  });
}
```

---

## Build Issues

### iOS Pod Install Failed

**Symptoms**:
- `pod install` fails
- Error: "Unable to find specification for PushPlatformSDK"

**Solutions**:

1. **Missing Native SDK**

   **Fix**: Ensure native iOS SDK exists:
   ```bash
   ls -la ../pushpilot-sdk-ios/PushPlatformSDK.podspec
   ```

2. **Invalid Podfile Path**

   **Fix**: Update Podfile:
   ```ruby
   # ios/Podfile
   pod 'PushPlatformSDK', :path => '../../../pushpilot-sdk-ios'
   ```

3. **CocoaPods Cache Corruption**

   **Fix**: Clear cache:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod cache clean --all
   pod install
   ```

### Android Gradle Build Failed

**Symptoms**:
- Gradle build fails
- Error: "Could not resolve project :sdk-android"

**Solutions**:

1. **Missing Native SDK**

   **Fix**: Ensure native Android SDK exists:
   ```bash
   ls -la ../pushpilot-sdk-android/build.gradle.kts
   ```

2. **Invalid Gradle Dependency**

   **Fix**: Update build.gradle.kts:
   ```kotlin
   // android/build.gradle.kts
   dependencies {
       implementation(project(":pushpilot-sdk-android"))
   }
   ```

3. **settings.gradle Not Updated**

   **Fix**: Include SDK module:
   ```kotlin
   // android/settings.gradle.kts
   include(":pushpilot-sdk-android")
   includeBuild("../../../pushpilot-sdk-android")
   ```

---

## Runtime Issues

### App Crashes on Push Reception

**Symptoms**:
- App crashes when push received
- Crash logs show null pointer exception

**Possible Causes**:

1. **Malformed Push Payload**

   **Check**: Verify payload matches expected schema:
   ```json
   {
     "messageId": "required-string",
     "title": "optional-string",
     "body": "optional-string",
     "data": {}, // optional-object
     "type": "normal" // or "silent"
   }
   ```

   **Fix**: Update backend to send valid payload

2. **Null Safety Violation**

   **Fix**: Check null before accessing:
   ```dart
   sdk.onPushReceived.listen((message) {
     final title = message.title ?? 'No title';
     final body = message.body ?? 'No body';
     print('$title: $body');
   });
   ```

### Memory Leaks

**Symptoms**:
- Memory usage grows over time
- App becomes sluggish

**Possible Causes**:

1. **Stream Subscription Not Cancelled**

   **Fix**: Always cancel in dispose:
   ```dart
   @override
   void dispose() {
     _pushSubscription?.cancel();
     _stateSubscription?.cancel();
     super.dispose();
   }
   ```

2. **Accumulating Messages in List**

   **Fix**: Implement pagination or limit:
   ```dart
   void _addMessage(PushMessage message) {
     setState(() {
       messages.insert(0, message);
       if (messages.length > 100) {
         messages.removeLast(); // Keep only last 100
       }
     });
   }
   ```

### High Battery Drain

**Symptoms**:
- Battery drains quickly
- App shows high battery usage

**Possible Causes**:

1. **Debug Mode Enabled in Production**

   **Fix**: Disable debug mode:
   ```dart
   await sdk.initialize(
     apiKey: apiKey,
     environment: 'production',
     debugMode: false, // Disable in production
   );
   ```

2. **Too Many Stream Listeners**

   **Fix**: Use single listener and broadcast:
   ```dart
   // Create broadcast stream
   final _pushController = StreamController<PushMessage>.broadcast();
   
   void initState() {
     super.initState();
     // Single subscription to SDK
     sdk.onPushReceived.listen((msg) {
       _pushController.add(msg);
     });
   }
   
   // Multiple widgets can listen to broadcast
   _pushController.stream.listen((msg) {
     // Handle in widget 1
   });
   _pushController.stream.listen((msg) {
     // Handle in widget 2
   });
   ```

---

## Debugging Tools

### Enable Debug Logging

```dart
await PushPlatformFlutter.instance.initialize(
  apiKey: 'your-key',
  environment: 'development',
  debugMode: true, // Enable verbose logging
);
```

### iOS Console Logs

```bash
# Xcode: Window → Devices and Simulators → Select device → Open Console
# Or use command line:
log stream --predicate 'subsystem == "com.pushplatform"'
```

### Android Logcat

```bash
# Filter for PushPlatform logs
adb logcat | grep PushPlatform

# Full logcat with timestamps
adb logcat -v time | grep -i push
```

### Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Monitor streams and memory
```

### Network Traffic

```bash
# iOS: Use Charles Proxy or Proxyman
# Android: Use Charles Proxy or adb proxy

# Configure proxy in device Wi-Fi settings
# Monitor API requests to push platform backend
```

---

## Getting Further Help

If issues persist after trying solutions above:

1. **Check GitHub Issues**: [github.com/pushplatform/sdk-flutter/issues](https://github.com/pushplatform/sdk-flutter/issues)
2. **Collect Debug Logs**: Enable debug mode and capture logs
3. **Create Minimal Reproduction**: Isolate issue in small example
4. **Include Details**:
   - Platform (iOS/Android)
   - OS version
   - SDK version
   - Flutter version
   - Dart version
   - Error messages
   - Stack traces
   - Debug logs

5. **Open New Issue**: Provide all collected information
