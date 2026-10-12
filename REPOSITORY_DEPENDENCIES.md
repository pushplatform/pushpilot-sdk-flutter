# Зависимости

Flutter-плагин использует только опубликованные нативные SDK 1.0.0:

- Android: `com.pushplatform:sdk-android:1.0.0`, публичный Maven по адресу `https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/`.
- iOS: `PushPlatformSDK` 1.0.0 из CocoaPods Trunk.

Локальные модули, соседние checkout и Maven Local для установки не используются. Серверный API и провайдеры доставки настраивает приложение. См. README.md и docs/RELEASING.md.
