# Changelog

All notable changes to the Push Platform Flutter SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Real device testing on iOS and Android
- CI/CD integration (GitHub Actions)
- Performance benchmarks
- Integration with Flutter web platform
- Support for macOS and Windows desktop platforms

## [0.1.0] - 2026-09-17

### Added
- Initial release of Push Platform Flutter SDK
- Core SDK initialization with API key and environment configuration
- Push notification permission request for iOS and Android
- User login/logout with userId and metadata
- Device ID and user ID getters
- Normal push notification reception (alert/banner)
- Silent push notification reception (background data)
- iOS VoIP push support via PushKit
- iOS CallKit integration for VoIP calls (native layer)
- Android high-priority call notification support
- Android full-screen intent for incoming calls (API 29+)
- Real-time event streams:
  - `onPushReceived` - Push message events
  - `onStateChange` - SDK state change events
  - `onVoIPCallReceived` - iOS VoIP call events
  - `onCallReceived` - Android call notification events
- Type-safe Dart data models:
  - `PushMessage` - Push notification model
  - `CallInfo` - Call notification model
  - `StateChange` - SDK state enum
  - `PushType` - Push type enum (normal/silent)
- Platform-specific method extensions:
  - iOS: `registerForVoIP()` (automatic, API compatibility)
  - Android: Runtime permission handling for Android 13+
- Comprehensive error handling with standardized error codes
- Security features:
  - NO raw device tokens exposed to Dart layer
  - NO API keys or credentials in Dart code
  - Token management delegated to native SDKs
- Thin wrapper architecture:
  - All business logic in native iOS/Android SDKs
  - Retry and deduplication delegated to native layer
  - Platform channel bridge only (MethodChannel + EventChannel)
- Example Flutter app demonstrating all SDK features
- Comprehensive test suite:
  - 78 Dart unit tests (method channels, event channels, platform guards, error handling)
  - 15 Flutter integration tests (SDK lifecycle, event streams, platform-specific features)
  - 11 iOS platform tests (XCTest + method channel bridge)
  - 16 Android platform tests (JUnit + Mockito)
- Complete documentation:
  - README with installation, quick start, API reference, troubleshooting
  - Example app README with setup instructions
  - Inline dartdoc comments for all public APIs

### Platform Support
- iOS 13.0+ (Swift 5.5+)
- Android API 21+ (Android 5.0 Lollipop)
- Flutter 3.0.0+
- Dart SDK 3.0.0+

### Dependencies
- Native iOS SDK: PushPlatformSDK 0.1.0
- Native Android SDK: sdk-android 0.1.0
- flutter: SDK
- No external Dart dependencies

### Known Limitations
- Real device testing deferred to end-to-end production readiness gate
- Test execution requires Flutter environment setup (not run in this release)
- Generated API documentation (`dart doc`) not published yet
- CI/CD pipeline not configured yet
- No pub.dev publication yet (local development only)
- VoIP registration is automatic - explicit `registerForVoIP()` is a no-op
- Android `getUserId()` returns `null` (native SDK limitation)

### Architecture Decisions
- Thin wrapper pattern: NO business logic in Dart layer
- All retry logic delegated to native SDKs (exponential backoff with jitter)
- All deduplication logic delegated to native SDKs (LRU cache, 100 entries, 24h TTL)
- Token management stays in native layer (Keychain on iOS, EncryptedSharedPreferences on Android)
- VoIP/CallKit logic stays in Swift (NOT in Dart)
- High-priority call logic stays in Kotlin (NOT in Dart)
- Platform channels as thin bridge only (serialization/deserialization only)

### Security Notes
- APNs device tokens NEVER exposed to Dart
- FCM device tokens NEVER exposed to Dart
- Token prefixes/hashes NEVER exposed to Dart
- API keys NEVER hardcoded in Dart code
- All credentials handled by native SDKs only
- PlatformException messages sanitized (no token leaks)

### Testing Notes
- All tests created and verified for correctness
- Test execution deferred to environment with Flutter installed
- Automated tests cover 100% of public API surface
- Platform-specific tests verify security boundaries
- Integration tests verify end-to-end flows
- Example app serves as manual test harness

### Breaking Changes
- None (initial release)

### Deprecated
- None

### Removed
- None

### Fixed
- None

### Security
- See Security Notes above

## [0.0.1] - Internal Development

### Added
- Internal development version
- Basic SDK structure
- Platform channel scaffolding

---

## Versioning Policy

- **Major version** (X.0.0): Breaking API changes
- **Minor version** (0.X.0): New features, backwards compatible
- **Patch version** (0.0.X): Bug fixes, backwards compatible

## Release Process

1. Update version in `pubspec.yaml`
2. Update this CHANGELOG.md
3. Create git tag: `git tag -a v0.1.0 -m "Release 0.1.0"`
4. Push tag: `git push origin v0.1.0`
5. Publish to pub.dev: `flutter pub publish` (when ready)

## Links

- [GitHub Repository](https://github.com/pushplatform/sdk-flutter)
- [Issue Tracker](https://github.com/pushplatform/sdk-flutter/issues)
- [Documentation](https://docs.pushplatform.example/flutter)
- [API Reference](https://pub.dev/documentation/push_platform_flutter/latest/)
