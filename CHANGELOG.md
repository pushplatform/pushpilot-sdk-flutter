# 1.2.12 — 2026-11-05

- Один режим storage: custom `url` не регистрирует development. Зависит от iOS **1.2.11** (sandbox из профиля). Чинит universal badge Increase при локальном API.

# 1.2.11 — 2026-11-04

- iOS: `PushPlatformSDK` **1.2.10** + отдельный pod `PushPlatformExtension`. NSE: `pod 'PushPlatformExtension'` (не subspec). В Podfile pin обеих строк с git-тега `v1.2.10` (Trunk read-only). Android — `sdk-android` 1.2.5.

# 1.2.10 — 2026-11-04

- NSE: `pod 'PushPlatformSDK/Extension'` + `import PushPlatformExtension` (iOS SDK 1.2.9).
- Документация и NSE: `PushPlatformSDK` 1.2.9 резолвится с публичного git-тега `v1.2.9` (CocoaPods Trunk read-only). Podspec по-прежнему `s.dependency 'PushPlatformSDK', '1.2.9'`. Android — `sdk-android` 1.2.5.

# 1.2.9 — 2026-11-04

- iOS-зависимость — `PushPlatformSDK` 1.2.8. Подтверждение при закрытом приложении вызывает `PushPlatformExtension` из пода. В Podfile нужен target extension с тем же подом. Новых вызовов в Dart нет. Android остаётся `sdk-android` 1.2.5.

# 1.2.8 — 2026-11-03

- В README добавлены шаги Notification Service Extension для iOS и код `NotificationService.swift` для копирования. Новых вызовов в Dart нет. Зависимости те же: `sdk-android` 1.2.5 и `PushPlatformSDK` 1.2.6.

# 1.2.7 — 2026-11-03

- Нативный iOS SDK сбрасывает бейдж при входе и подтверждает получение через Notification Service Extension. Нативный Android SDK показывает data-only баннер, ставит бейдж и сбрасывает его при входе.
- Новых вызовов в Dart нет.
- Зависит от `sdk-android` 1.2.5 и опубликованного `PushPlatformSDK` 1.2.6. CocoaPods trunk до 6 ноября не принимает 1.2.7.

# 1.2.6 — 2026-11-02

- `PushMessage.notificationId` в событиях клика и показа. Поле `notification_id` больше не попадает в `data`.
- Открытие уведомления нативный SDK отправляет сам через `PUT /notifications/{id}`, включая холодный старт.
- Зависит от `sdk-android` 1.2.4 и `PushPlatformSDK` 1.2.6.

# 1.2.5 — 2026-11-02

- `foregroundBannerFallback` задаёт секунды запасного системного баннера. Ноль и отсутствие ждут обработчик.
- Зависит от `sdk-android` 1.2.3 и `PushPlatformSDK` 1.2.5.

# 1.2.4 — 2026-11-02

- Адрес только `url`. Старое имя адреса удалено.
- Показ ждёт обработчик без восьмисекундного таймера.
- Зависит от `sdk-android` 1.2.2 и `PushPlatformSDK` 1.2.4.

# 1.2.3 — 2026-11-02

- `initialize` принимает строку, `InitializeOptions` или map. Адрес только `url`.
- Отдельные потоки `onNotificationOpened` и `onNotificationWillDisplay`. `onPushReceived` остаётся доставкой. У показа есть `preventDefault()` до возврата обработчика.
- Android проводит клик, показ и токен в Dart. `getDeviceToken()` и `getPermissionStatus()` доступны на обеих платформах.
- `login(userId, metadata)` доходит до натива и в тело login на сервере.
- Зависит от `sdk-android` 1.2.1 и `PushPlatformSDK` 1.2.2.

# 1.2.2 — 2026-11-02

- README на pub.dev описывает плагин 1.2.2 и опубликованные native SDK 1.2.0. В 1.2.1 на pub.dev остался текст про 1.1.1 и вшитые исходники iOS; ту версию заменить нельзя.

# 1.2.1 — 2026-11-02

- Example initialization uses a const `InitializeOptions`, so `flutter analyze` passes on the published package.

# 1.2.0 — 2026-11-01

- `initialize` takes an application id or `{applicationId, url, environment}`. No API key is sent.
- The plugin depends on the published iOS and Android SDKs.

# 1.1.1 — 2026-11-01

Documentation/packaging correction: README now identifies the bundled Android/iOS SDKs as 1.1.0 and the current shared application-key setup. Native runtime, dependencies and Dart/bridge behavior are unchanged from 1.1.0. No additional SDK builds are needed for this documentation patch.

# 1.1.0 — 2026-11-01

- Unified application ID and permanent shared application key for SDK and server; no project/environment setup step.
- Actual device kind, language, time zone, OS/SDK/app version and notification permission metadata. Unknown facts stay unknown.
- Optional legacy environment compatibility; iOS defaults to build-entitlement APNs transport detection.
- Test subscription remains a separate console marker.

# История изменений

## 1.0.2 — 2026-10-31

- Android native SDK обновлён до 1.0.1: при configure автоматически запрашивается текущий FCM-токен, ранние callback дожидаются регистрации установки; development/production и package name передаются из приложения.
- Никакого ручного API-обхода для первоначального токена. Нативные события успешной/неуспешной регистрации сохраняют прежний контракт и не раскрывают токен в JS/Dart.
- iOS SDK и публичные методы обёртки не менялись.

## 1.0.1 — 2026-10-24

- Исходники iOS SDK из опубликованного тега `v1.0.0` (commit `c67bcdf57ab150a5835570e4b695b173c1953bc1`) включены в pub-пакет вместе с MIT-лицензией и SHA-256 manifest.
- Podspec компилирует native SDK внутри Flutter-плагина; внешняя зависимость `PushPlatformSDK` из Trunk удалена. CocoaPods остаётся механизмом интеграции Flutter, но публикация native SDK в Trunk больше не нужна.
- Установка не требует приватного Git, соседнего checkout и ручного подключения native SDK. Dart-import, публичный API и нативные типы сохранены.
- Добавлен воспроизводимый `scripts/update-bundled-ios.py` с фиксацией тега, SHA объекта тега и commit в `ios/native-sdk.lock.json`.
- Обновлены русский README и процедура релиза. Android и остальные зависимости не менялись.
- Проверка ограничена просмотром diff и состава пакета; тесты, сборки, симуляторы и примеры не запускались.

## 1.0.0 — 2026-10-12

- Первый самостоятельный релиз для pub.dev; имя пакета `push_platform_flutter` сохранено.
- Подключены опубликованные Android SDK `com.pushplatform:sdk-android:1.0.0` из публичного Maven и CocoaPod `PushPlatformSDK` 1.0.0.
- Удалена зависимость примера от соседнего Android checkout; установка не требует Maven Local и приватного Git.
- `initialize` требует `applicationId` (UUID PushPilot) и адрес `url`; ожидает завершения регистрации на обеих платформах.
- Исправлены APNs lifecycle callbacks, Android permission result и передача асинхронных результатов на главный поток.
- Добавлены MIT LICENSE, корректные ссылки, инструкция на русском и отчёт о релизе.

## 0.1.0

Внутренняя версия моста MethodChannel/EventChannel; на pub.dev не публиковалась.
