# Зависимости

Flutter-плагин использует опубликованные нативные SDK:

- Android: `com.pushplatform:sdk-android:1.2.5`, публичный Maven `https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/`.
- iOS: `PushPlatformSDK` 1.2.11 + `PushPlatformExtension` 1.2.11. Пока CocoaPods Trunk не отдаёт эту версию — pin в Podfile с git-тега `v1.2.11` (см. README).

Локальные модули, соседние checkout и Maven Local для установки не используются. Серверный API и провайдеры доставки настраивает приложение. См. README.md.
