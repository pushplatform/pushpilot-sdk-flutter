# История изменений

## 1.0.0 — 2026-10-12

- Первый самостоятельный релиз для pub.dev; имя пакета `push_platform_flutter` сохранено.
- Подключены опубликованные Android SDK `com.pushplatform:sdk-android:1.0.0` из публичного Maven и CocoaPod `PushPlatformSDK` 1.0.0.
- Удалена зависимость примера от соседнего Android checkout; установка не требует Maven Local и приватного Git.
- `initialize` требует `applicationId` (UUID PushPilot) и `apiBaseURL`; ожидает завершения регистрации на обеих платформах.
- Исправлены APNs lifecycle callbacks, Android permission result и передача асинхронных результатов на главный поток.
- Добавлены MIT LICENSE, корректные ссылки, инструкция на русском и отчёт о релизе.

## 0.1.0

Внутренняя версия моста MethodChannel/EventChannel; на pub.dev не публиковалась.
