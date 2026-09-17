# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-17

### Added
- Initial release of Push Platform Flutter SDK
- Core SDK initialization with `apiKey` authentication
- Push notification support (normal and silent)
- iOS VoIP push support via PushKit (automatic registration)
- Android high-priority call notification support
- User login/logout functionality
- Type-safe Dart API with immutable data models
- Platform-specific extensions for iOS VoIP and Android calls
- Event streams for push messages and state changes
- Comprehensive unit test coverage (15+ tests)
- Full API documentation with dartdoc comments
- README with quick start guide and examples

### Implementation Notes
- iOS bridge uses native SDK's `configure(apiKey:apiBaseURL:environment:debugMode:)` API
- VoIP registration happens automatically in native SDK (PushKitManager)
- Permission requests handled via UNUserNotificationCenter (iOS SDK doesn't expose public API)
- User ID getter returns nil (UserManager doesn't expose public getter)
- Metadata/customData sanitized for JSON serialization (removes NSDate, NSData, custom objects)

### Security
- Raw device tokens never exposed to Dart layer
- API keys never exposed to Dart layer
- All credentials handled exclusively by native SDKs
- Token masking in logs and responses

### Known Limitations
- Real device testing deferred to E2E Gate (GATE-E2E-PRODUCTION-READINESS)
- Requires local native SDK dependencies (sdk-ios, sdk-android)
- iOS: No current user ID getter (SDK limitation)
- iOS: Permission request bypasses SDK (calls UNUserNotificationCenter directly)

[0.1.0]: https://github.com/pushplatform/sdk-flutter/releases/tag/v0.1.0
