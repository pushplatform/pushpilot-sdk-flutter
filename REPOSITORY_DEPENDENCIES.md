# Dependencies between repositories

`pushpilot-sdk-flutter` bridges the native SDKs:

- iOS: `pushpilot-sdk-ios` via CocoaPods.
- Android: `pushpilot-sdk-android` as a Gradle module or published artifact.

Applications using the plugin also configure the API served by `pushpilot-server`.
