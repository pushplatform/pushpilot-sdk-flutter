# Unified application SDK release

Version: 1.1.1 (native runtime 1.1.0). One application ID/key across SDKs and server. The key is deliberately extractable and grants device registration/read access and message sending/history only for that application; no organization/platform/billing administration.

No project/environment selection is needed. Optional legacy environment arguments remain compatible. APNs sandbox/production follows the build entitlement and is a transport property. Native SDK metadata includes real model/versions/locale/timezone/permission/device kind; Web reports unknown hardware kind. Test subscription is a separate console flag.

Validation on 2026-11-01: Android 170 tests and release Maven staging; iOS metadata tests plus 21 affected API/token integration tests on Simulator; RN 98 JS tests, Expo plugin tests, packed-distribution Maven/Pod probes and actual Android/iOS consumer builds; Flutter 74 tests and actual Android/iOS consumer builds. Web 91 unit tests, 11 browser scenarios headless and the actual notification display scenario in a visible macOS browser (headless macOS resolves showNotification without retaining a visible notification). The actual built Web SDK also registered through the unified real API and origin policy in console acceptance.

Console acceptance uses a disposable postgres database and real queue/worker with guarded mock transports. Same key registers iOS/Android/Web; two native devices share an External ID, metadata/tags/test-marker persist; composer creates one message/two accepted mock deliveries. No real push, credentials exchange with Apple/Firebase, or charging occurred. Real device/provider delivery still requires the customer's actual APNs/Firebase/Web credentials, OS permission and signed builds.

## Publication verified on 2026-11-01

Flutter 1.1.1 is published on pub.dev. It corrects setup documentation/metadata from 1.1.0; the validated native runtime remains Android/iOS 1.1.0. All 70 archive files match local sources. Archive SHA-256: `5324301415b4c9add8978bf4606a704264be2deee13cd985f3ab3d17eeb6e85a`. [PR #4](https://github.com/pushplatform/pushpilot-sdk-flutter/pull/4).
