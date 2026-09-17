# Architecture

## Overview

The Push Platform Flutter SDK is a **thin wrapper** over native iOS and Android SDKs. It provides a type-safe Dart API while delegating all business logic, retry mechanisms, deduplication, and token management to the native layer.

## Design Principles

### 1. Thin Wrapper Pattern

**Goal**: Keep Dart layer minimal, delegate complexity to native SDKs

**Responsibilities by Layer**:

| Layer | Responsibilities | NOT Responsible For |
|-------|------------------|-------------------|
| **Dart** | Type-safe API, platform channel bridge, event streams, serialization | Business logic, retry, deduplication, token management |
| **iOS Native** | APNs token management, PushKit/VoIP, CallKit, retry, deduplication, Keychain storage | Dart UI logic |
| **Android Native** | FCM token management, high-priority calls, retry, deduplication, EncryptedSharedPreferences | Dart UI logic |

### 2. Security Boundaries

**Critical Security Rules**:

- ✅ Raw device tokens NEVER cross platform channel boundary
- ✅ Token prefixes/hashes NEVER exposed to Dart
- ✅ API keys NEVER hardcoded in Dart code
- ✅ All credentials stored in native secure storage only

**Why**: Dart code is easy to decompile and inspect. Sensitive data must stay in native layer where it's protected by OS-level security (Keychain on iOS, EncryptedSharedPreferences on Android).

### 3. Platform-Specific Logic Stays Native

**iOS VoIP/CallKit**:
- VoIP push registration: Swift only (PushKit)
- CallKit UI: Swift only
- Incoming call handling: Swift only
- Dart receives event AFTER native SDK handles it

**Android High-Priority Calls**:
- Full-screen intent: Kotlin only
- Notification channel creation: Kotlin only
- Call notification handling: Kotlin only
- Dart receives event AFTER native SDK handles it

**Why**: VoIP and call handling require low-level platform APIs (PushKit, CallKit, NotificationManager) that don't map cleanly to Flutter. Keeping them native ensures correct behavior and avoids Flutter event loop delays.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App (Dart)                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         PushPlatformFlutter (Singleton)              │  │
│  │                                                      │  │
│  │  - initialize()                                      │  │
│  │  - login() / logout()                               │  │
│  │  - requestPermissions()                             │  │
│  │  - Stream<PushMessage> onPushReceived               │  │
│  │  - Stream<StateChange> onStateChange                │  │
│  │  - Stream<CallInfo> onVoIPCallReceived (iOS)       │  │
│  │  - Stream<CallInfo> onCallReceived (Android)        │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           │ MethodChannel / EventChannel    │
│                           │                                 │
└───────────────────────────┼─────────────────────────────────┘
                            │
        ┌───────────────────┴────────────────────┐
        │                                        │
        ▼                                        ▼
┌───────────────────┐                 ┌──────────────────────┐
│   iOS Native      │                 │  Android Native      │
│                   │                 │                      │
│ FlutterPushPlatformPlugin          │ FlutterPushPlatformPlugin
│                   │                 │                      │
│ ┌───────────────┐ │                 │ ┌────────────────┐  │
│ │ PushPlatform  │ │                 │ │ PushPlatform   │  │
│ │ SDK (Swift)   │ │                 │ │ SDK (Kotlin)   │  │
│ │               │ │                 │ │                │  │
│ │ - APNs        │ │                 │ │ - FCM          │  │
│ │ - PushKit     │ │                 │ │ - Notification │  │
│ │ - CallKit     │ │                 │ │   Manager      │  │
│ │ - Keychain    │ │                 │ │ - Encrypted    │  │
│ │ - Retry       │ │                 │ │   Prefs        │  │
│ │ - Dedupe      │ │                 │ │ - Retry        │  │
│ └───────────────┘ │                 │ │ - Dedupe       │  │
│                   │                 │ └────────────────┘  │
└───────────────────┘                 └──────────────────────┘
        │                                        │
        │                                        │
        ▼                                        ▼
┌───────────────────┐                 ┌──────────────────────┐
│   APNs (Apple)    │                 │   FCM (Google)       │
└───────────────────┘                 └──────────────────────┘
```

## Component Breakdown

### 1. Dart Layer (`lib/`)

#### `push_platform_flutter.dart`
- Public API surface
- Exports all models and enums
- Entry point for SDK consumers

#### `push_platform_flutter_impl.dart`
- Singleton instance management
- MethodChannel initialization
- EventChannel initialization
- Method call delegation to native
- Event stream controllers

#### `models/`
- `push_message.dart` - Push notification model
- `call_info.dart` - Call notification model
- `state_change.dart` - SDK state enum
- `push_type.dart` - Push type enum

#### `platform_extensions/`
- `ios_voip_extension.dart` - iOS VoIP methods (throws on Android)
- `android_call_extension.dart` - Android call methods (throws on iOS)

### 2. iOS Native Layer (`ios/`)

#### `FlutterPushPlatformPlugin.swift`
- FlutterPlugin implementation
- MethodChannel handler
- EventChannel stream handlers
- Delegates to native PushPlatform SDK
- Serializes events to Dart-compatible JSON

**Key Methods**:
- `handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)`
- `onPushReceived(_ message: PushMessage)` - PushPlatformDelegate
- `onVoIPCallReceived(_ callInfo: CallInfo)` - PushPlatformDelegate
- `onStateChange(_ state: StateChange)` - PushPlatformDelegate

#### Native SDK Integration
- Links to `PushPlatformSDK` framework
- Uses singleton pattern: `PushPlatform.shared`
- Implements `PushPlatformDelegate` for callbacks

### 3. Android Native Layer (`android/`)

#### `FlutterPushPlatformPlugin.kt`
- FlutterPlugin implementation
- ActivityAware for permission requests
- MethodChannel.MethodCallHandler
- EventChannel.StreamHandler (x3: push, call, state events)
- Delegates to native PushPlatform SDK
- Serializes events to Dart-compatible JSON

**Key Methods**:
- `onMethodCall(call: MethodCall, result: MethodChannel.Result)`
- `onPushReceived(notification: ParsedNotification)` - PushPlatformDelegate
- `onCallReceived(callInfo: CallInfo)` - PushPlatformDelegate
- `onStateChange(state: String)` - PushPlatformDelegate

#### Native SDK Integration
- Depends on `sdk-android` module
- Uses singleton pattern: `PushPlatform.getInstance()`
- Implements `PushPlatformDelegate` for callbacks

## Data Flow

### Initialize Flow

```
Flutter App
    │
    │ initialize(apiKey, environment)
    ▼
MethodChannel
    │
    ├─ iOS: handle("initialize")
    │       │
    │       ▼
    │   PushPlatform.shared.configure(apiKey, environment)
    │       │
    │       ├─ Register APNs
    │       ├─ Register PushKit (VoIP)
    │       ├─ Store credentials in Keychain
    │       ▼
    │   Emit: StateChange.initialized
    │
    └─ Android: onMethodCall("initialize")
            │
            ▼
        PushPlatform.getInstance().configure(context, apiKey, environment)
            │
            ├─ Initialize FCM
            ├─ Store credentials in EncryptedSharedPreferences
            ▼
        Emit: StateChange.initialized
```

### Push Reception Flow

```
APNs/FCM
    │
    │ Push payload arrives
    ▼
Native SDK
    │
    ├─ Parse payload
    ├─ Deduplicate (check LRU cache)
    ├─ Store message
    ▼
PushPlatformDelegate callback
    │
    │ onPushReceived(message)
    ▼
Flutter Plugin
    │
    │ Serialize to JSON
    ▼
EventChannel (push_events)
    │
    │ Send to Dart
    ▼
Stream<PushMessage>
    │
    │ onPushReceived.listen()
    ▼
Flutter App UI
```

### VoIP Call Flow (iOS Only)

```
APNs (VoIP)
    │
    │ VoIP push arrives
    ▼
PushKit Framework
    │
    │ didReceiveIncomingPushWith(payload)
    ▼
PushPlatform.shared
    │
    ├─ Parse call payload
    ├─ Extract callId, callerId, callerName
    ▼
CallKit
    │
    │ Report incoming call
    │ Show CallKit UI
    ▼
PushPlatformDelegate callback
    │
    │ onVoIPCallReceived(callInfo)
    ▼
Flutter Plugin
    │
    │ Serialize to JSON
    ▼
EventChannel (voip_events)
    │
    │ Send to Dart
    ▼
Stream<CallInfo>
    │
    │ onVoIPCallReceived.listen()
    ▼
Flutter App
    │
    │ Update in-app call UI
    │ (CallKit UI already shown)
    ▼
```

### Login Flow

```
Flutter App
    │
    │ login(userId, metadata)
    ▼
MethodChannel
    │
    │ Call: login
    │ Args: {userId, metadata}
    ▼
Native SDK
    │
    ├─ Validate userId
    ├─ Send login request to backend
    │   (with retry + exponential backoff)
    ├─ Store userId in secure storage
    ▼
Return deviceId
    │
    ▼
Dart Future<String?>
    │
    │ await login(...)
    ▼
Flutter App
    │
    │ Display deviceId in UI
    │ Enable logout button
    ▼
```

## Platform Channel Contracts

### MethodChannel: `com.pushplatform/sdk`

**Methods**:

| Method | Arguments | Returns | Errors |
|--------|-----------|---------|--------|
| `initialize` | `{apiKey, apiBaseURL?, environment, debugMode}` | `null` | `NOT_INITIALIZED`, `INVALID_ARGUMENTS` |
| `requestPermissions` | `null` | `bool` | `PERMISSION_DENIED` |
| `login` | `{userId, metadata?}` | `String?` (deviceId) | `NOT_INITIALIZED`, `INVALID_ARGUMENTS`, `NETWORK_ERROR` |
| `logout` | `null` | `null` | `NOT_INITIALIZED` |
| `getDeviceId` | `null` | `String?` | `NOT_INITIALIZED` |
| `getUserId` | `null` | `String?` | `NOT_INITIALIZED` |
| `registerForVoIP` | `null` | `null` | `UNSUPPORTED_PLATFORM` (Android only) |

### EventChannels

#### `com.pushplatform/push_events`

**Emits**: Push message events

```json
{
  "messageId": "msg-123",
  "title": "Hello",
  "body": "Push notification body",
  "data": {"key": "value"},
  "type": "normal",
  "receivedAt": 1726588800000
}
```

#### `com.pushplatform/voip_events` (iOS only)

**Emits**: VoIP call events

```json
{
  "callId": "call-456",
  "callerId": "+1234567890",
  "callerName": "John Doe",
  "metadata": {"priority": "high"},
  "receivedAt": 1726588800000
}
```

#### `com.pushplatform/call_events` (Android only)

**Emits**: High-priority call notification events

```json
{
  "callId": "call-789",
  "callerId": "+0987654321",
  "callerName": "Jane Smith",
  "metadata": {"priority": "high"},
  "receivedAt": 1726588800000
}
```

#### `com.pushplatform/state_events`

**Emits**: SDK state change events

```json
"initialized"
"loggedIn"
"loggedOut"
"permissionGranted"
"permissionDenied"
"tokenRefreshed"
"error"
```

## Security Architecture

### Token Isolation

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter App (Dart)                    │
│                                                         │
│  ✅ CAN ACCESS:                                         │
│     - deviceId (installation ID)                       │
│     - userId (user identifier)                         │
│     - Push message content (title, body, data)         │
│     - Call info (callId, callerId, callerName)         │
│                                                         │
│  ❌ CANNOT ACCESS:                                      │
│     - Raw APNs device token                            │
│     - Raw FCM device token                             │
│     - Token prefix/hash                                │
│     - API keys (passed in initialize, not stored)      │
│                                                         │
└─────────────────────────────────────────────────────────┘
                            │
                            │ Platform Channel Boundary
                            │ (Security Barrier)
                            │
┌─────────────────────────────────────────────────────────┐
│              Native SDK (iOS/Android)                   │
│                                                         │
│  ✅ HAS ACCESS TO:                                      │
│     - Raw APNs token (iOS Keychain)                    │
│     - Raw FCM token (Android EncryptedSharedPrefs)     │
│     - API keys (in-memory only during operation)       │
│     - User credentials (secure storage)                │
│                                                         │
│  ✅ SECURITY MEASURES:                                  │
│     - Keychain storage (iOS)                           │
│     - EncryptedSharedPreferences (Android)             │
│     - TLS for network requests                         │
│     - Token never logged                               │
│     - Token never serialized to platform channel       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Error Message Sanitization

Native SDK sanitizes error messages before crossing platform channel:

```kotlin
// Android example
private fun mapError(error: SdkError): FlutterError {
    return when (error) {
        is SdkError.InvalidToken -> {
            // NEVER include token in error message
            FlutterError("INVALID_TOKEN", "Device token is invalid", null)
        }
        is SdkError.ApiError -> {
            // NEVER include raw API response (may contain tokens)
            FlutterError("API_ERROR", "Backend API error", null)
        }
    }
}
```

## Retry and Deduplication Architecture

### Retry Logic (Native Only)

```
┌───────────────────────────────────────────────────┐
│            Flutter App (Dart)                     │
│                                                   │
│  ❌ NO retry logic                                │
│  ❌ NO exponential backoff                        │
│  ❌ NO retry counters                             │
│                                                   │
│  ✅ Simply propagates errors to app               │
│  ✅ App can implement app-level retry if needed   │
│                                                   │
└───────────────────────────────────────────────────┘
                      │
                      │ Delegates to
                      ▼
┌───────────────────────────────────────────────────┐
│         Native SDK (iOS/Android)                  │
│                                                   │
│  ✅ Exponential backoff with jitter               │
│  ✅ Max retry attempts: 5                         │
│  ✅ Base delay: 1s, max delay: 32s                │
│  ✅ Per-operation retry state                     │
│  ✅ Offline queue with automatic retry            │
│                                                   │
└───────────────────────────────────────────────────┘
```

### Deduplication Logic (Native Only)

```
┌───────────────────────────────────────────────────┐
│            Flutter App (Dart)                     │
│                                                   │
│  ❌ NO message cache                              │
│  ❌ NO duplicate detection                        │
│  ❌ NO Set/Map for tracking seen messages         │
│                                                   │
│  ✅ Receives only deduplicated events             │
│                                                   │
└───────────────────────────────────────────────────┘
                      │
                      │ Delegates to
                      ▼
┌───────────────────────────────────────────────────┐
│         Native SDK (iOS/Android)                  │
│                                                   │
│  ✅ LRU cache: 100 entries, 24h TTL               │
│  ✅ Keyed by messageId                            │
│  ✅ Duplicate messages dropped silently           │
│  ✅ Cache persisted across app restarts           │
│                                                   │
└───────────────────────────────────────────────────┘
```

## Testing Architecture

### Test Pyramid

```
                    ┌──────────────┐
                    │   Manual     │
                    │   Testing    │ 1 example app
                    └──────────────┘
                  ┌──────────────────┐
                  │   Integration    │
                  │     Tests        │ 15 tests
                  └──────────────────┘
              ┌──────────────────────────┐
              │    Platform Tests        │
              │  (iOS + Android)         │ 27 tests
              └──────────────────────────┘
          ┌──────────────────────────────────┐
          │         Unit Tests               │
          │  (Dart + Method/Event Channels)  │ 78 tests
          └──────────────────────────────────┘
```

### Test Coverage by Layer

| Layer | Test Type | Coverage |
|-------|-----------|----------|
| **Dart** | Unit tests (method/event channel mocks) | 78 tests, ~95% coverage |
| **Dart** | Integration tests (example app flows) | 15 tests, end-to-end scenarios |
| **iOS Native** | XCTest (method channel bridge) | 11 tests, 100% bridge coverage |
| **Android Native** | JUnit + Mockito (method channel bridge) | 16 tests, 100% bridge coverage |
| **Manual** | Example app (real devices) | Deferred to E2E gate |

## Performance Considerations

### Memory

- **Dart Layer**: Minimal memory footprint
  - Singleton instance: ~1KB
  - Event stream controllers: ~500 bytes each
  - Cached messages: None (all in native)

- **Native Layer**: Moderate memory footprint
  - LRU cache: ~100KB (100 entries × ~1KB each)
  - Offline queue: Variable (depends on pending operations)

### CPU

- **Serialization overhead**: ~0.1ms per message (JSON encode/decode)
- **Platform channel latency**: ~1-2ms per method call
- **Event delivery latency**: ~2-5ms from native to Dart

### Network

- All network operations in native layer
- TLS connection pooling (native)
- HTTP/2 support (native)
- Retry with exponential backoff (native)

## Future Architecture Evolution

### Planned Improvements

1. **Flutter Web Support**:
   - Web platform channel implementation
   - Firebase Cloud Messaging for web
   - Service Worker for background push

2. **Desktop Support**:
   - macOS: APNs integration
   - Windows: WNS integration
   - Linux: Custom push service

3. **Advanced Features**:
   - Rich notifications (images, actions)
   - Notification categories
   - Push-to-talk integration
   - E2E encrypted push

### Non-Goals

- ❌ Marketing automation (segmentation, campaigns, A/B testing)
- ❌ Analytics (beyond technical metrics)
- ❌ In-app messaging
- ❌ Email/SMS fallback
- ❌ UI components (notification banners, etc.)

**Rationale**: This SDK is a technical push gateway, not a marketing platform. Keep it focused and lightweight.

## References

- [ADR-0015: Flutter SDK Architecture](../../docs/adr/ADR-0015-flutter-sdk-architecture.md)
- [iOS Native SDK Architecture](../../sdk-ios/README.md)
- [Android Native SDK Architecture](../../sdk-android/README.md)
- [Platform Channel Documentation](https://docs.flutter.dev/development/platform-integration/platform-channels)
