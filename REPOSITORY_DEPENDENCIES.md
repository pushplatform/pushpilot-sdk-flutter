# Зависимости

Flutter-плагин использует опубликованные нативные SDK:

- Android: `com.pushplatform:sdk-android:2.0.1`, публичный Maven `https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/`.
- iOS: `PushPlatformSDK` 2.0.1 + `PushPlatformExtension` 2.0.1. Пока CocoaPods Trunk не отдаёт эту версию — pin в Podfile с git-тега `v2.0.1` (см. README).

Локальные модули, соседние checkout и Maven Local для установки не используются. Серверный API и провайдеры доставки настраивает приложение. См. README.md.
