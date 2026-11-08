# Выпуск SDK 2.0.2

Версия плагина должна совпадать в pubspec.yaml, Android Gradle и iOS podspec. Нативные зависимости имеют собственные версии.
Инструкции установки и настройки приложения находятся в README.md;
изменения интеграции звонков — в docs/MIGRATION_2.md.

1. Согласуйте pubspec.yaml, Android Gradle и iOS podspec: версия плагина 2.0.2, нативные зависимости — 2.0.1.
2. Выполните `flutter pub get`, `flutter analyze` и `flutter test`.
3. Соберите Android и iOS приложения с подключённым плагином и нативными SDK 2.0.1.
4. Проверьте `flutter pub publish --dry-run` и содержимое архива.
5. Workflow `flutter-sdk-release` запускается вручную; параметр `publish` управляет публикацией в pub.dev.

Flutter-пакет подключает Android SDK из публичного Maven-репозитория и iOS SDK через CocoaPods. Основной iOS SDK подключается плагином транзитивно. Отдельному Notification Service Extension нужен свой target с PushPlatformExtension совместимой ветки 2.x; пример приведён в README.md.
