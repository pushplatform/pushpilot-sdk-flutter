# Push Platform Flutter SDK — Example App

This example app demonstrates all features of the Push Platform Flutter SDK.

## Features Demonstrated

1. **SDK Initialization** — configure with API key and environment
2. **Permission Requests** — request notification permissions on iOS and Android
3. **User Login/Logout** — authenticate users and manage sessions
4. **Normal Push Notifications** — receive and display regular push messages
5. **Silent Push Notifications** — receive data-only pushes (logged, not shown in list)
6. **iOS VoIP Push** — register for and receive VoIP calls via PushKit (iOS only)
7. **Android High-Priority Calls** — receive high-priority call notifications (Android only)
8. **State Changes** — track SDK state (initialized, logged in/out, permissions)
9. **Device/Installation ID** — display unique device identifier
10. **Error Handling** — catch and display SDK errors

## Prerequisites

- Flutter SDK 3.0.0 or higher
- iOS 13.0+ (for iOS target)
- Android API 21+ (for Android target)
- Xcode 14.0+ (for iOS development)
- Android Studio with Gradle (for Android development)

## Setup

### 1. Install Dependencies

```bash
cd example
flutter pub get
```

### 2. iOS Setup

#### a. Open iOS project in Xcode

```bash
open ios/Runner.xcworkspace
```

#### b. Configure Signing & Capabilities

1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Select your development team
4. Add capabilities:
   - **Push Notifications**
   - **Background Modes** → check "Remote notifications" and "Voice over IP"

#### c. Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for VoIP calls</string>
```

#### d. Update API Key

Edit `lib/main.dart` and replace the demo API key:

```dart
await _sdk.initialize(
  apiKey: 'YOUR_ACTUAL_API_KEY', // Replace this
  apiBaseURL: 'https://api.pushplatform.example',
  environment: 'production',
  debugMode: false,
);
```

### 3. Android Setup

#### a. Update AndroidManifest.xml

Ensure `example/android/app/src/main/AndroidManifest.xml` contains:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application
        android:label="push_platform_flutter_example"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Activities and services -->
    </application>
</manifest>
```

#### b. Update build.gradle

Ensure `example/android/app/build.gradle` has:

```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 21
        targetSdk 34
    }
}

dependencies {
    implementation project(':push_platform_flutter')
}
```

#### c. Update API Key

Same as iOS — edit `lib/main.dart` and replace the demo API key.

### 4. Configure Native SDKs

#### iOS Native SDK

The example app uses the native iOS SDK via CocoaPods dependency declared in `../ios/push_platform_flutter.podspec`:

```ruby
s.dependency 'PushPlatformSDK', :path => '../../../sdk-ios'
```

Make sure `sdk-ios` is built and available.

#### Android Native SDK

The example app uses the native Android SDK via Gradle dependency declared in `../android/build.gradle.kts`:

```kotlin
dependencies {
    implementation(project(":sdk-android"))
}
```

Make sure `sdk-android` is built and available in `settings.gradle`.

## Running the Example

### iOS Simulator

```bash
flutter run -d "iPhone 15 Pro"
```

**Note**: VoIP push notifications require a **real device**. Simulator cannot receive PushKit notifications.

### Android Emulator

```bash
flutter run -d emulator-5554
```

**Note**: Firebase Cloud Messaging (FCM) works in emulators, but real device testing is recommended.

### Real Devices

#### iOS Device

1. Connect your iPhone via USB
2. Trust the development certificate in iOS Settings
3. Run:
   ```bash
   flutter run -d <your-device-id>
   ```

#### Android Device

1. Enable USB debugging on your Android device
2. Connect via USB
3. Run:
   ```bash
   flutter run -d <your-device-id>
   ```

## Testing Push Notifications

### 1. Initialize SDK

Tap **"Initialize"** button. Status should change to "initialized" and Installation ID should appear.

### 2. Request Permissions

Tap **"Request Permissions"**. System dialog will appear. Grant permissions.

### 3. Login

Tap **"Login"**. A unique user ID will be generated and logged in.

### 4. Send Test Push

Use the Push Platform Dashboard or API to send a test push notification:

```bash
curl -X POST https://api.pushplatform.example/v1/push/send \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-<timestamp>",
    "notification": {
      "title": "Test Push",
      "body": "Hello from Push Platform!"
    }
  }'
```

The notification should appear in the app's message list.

### 5. Test VoIP (iOS only)

1. Tap **"Register VoIP (iOS)"** button
2. Send a VoIP push from your backend (requires APNS VoIP certificate)
3. Incoming call dialog should appear

### 6. Test High-Priority Call (Android only)

1. Send a high-priority call notification with `callId` field
2. Incoming call dialog should appear

### 7. Logout

Tap **"Logout"**. Status should change to "loggedOut".

## Troubleshooting

### iOS Issues

**Problem**: VoIP registration fails  
**Solution**: Ensure you're running on a real device and have VoIP capability enabled in Xcode.

**Problem**: Push notifications not received  
**Solution**: Check that Push Notifications capability is enabled and you've granted permissions.

**Problem**: CocoaPods error  
**Solution**: Run `cd ios && pod install` from the example directory.

### Android Issues

**Problem**: Gradle build fails  
**Solution**: Ensure `sdk-android` module is available in `settings.gradle`.

**Problem**: Permission denied (Android 13+)  
**Solution**: Runtime permission request is required. Tap "Request Permissions" button.

**Problem**: FCM token not registered  
**Solution**: Ensure `google-services.json` is configured (if using Firebase).

### General Issues

**Problem**: API key invalid  
**Solution**: Replace `'demo-api-key'` in `main.dart` with your actual API key.

**Problem**: Network error  
**Solution**: Check that `apiBaseURL` points to a valid Push Platform API endpoint.

## Code Structure

```
example/
├── lib/
│   └── main.dart          # Main app with all SDK features
├── ios/                   # iOS platform configuration
├── android/               # Android platform configuration
├── pubspec.yaml           # Flutter dependencies
└── README.md              # This file
```

## Next Steps

- Integrate the SDK into your own Flutter app
- Customize push notification UI
- Handle VoIP calls with CallKit (iOS) or ConnectionService (Android)
- Implement custom analytics and error tracking
- Review the [main SDK README](../README.md) for detailed API documentation

## License

This example app is part of the Push Platform Flutter SDK and follows the same license.
