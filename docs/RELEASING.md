# Выпуск SDK 2.0.1

Версии пакета, нативных зависимостей и runtime metadata должны совпадать.
Инструкции установки и настройки приложения находятся в README.md;
изменения интеграции звонков — в docs/MIGRATION_2.md.

1. Согласуйте pubspec.yaml, Android Gradle и iOS podspec: плагин и нативные зависимости используют 2.0.1.
2. Выполните `flutter pub get`, `flutter analyze` и `flutter test`.
3. Соберите Android и iOS приложения с подключённым плагином и нативными SDK 2.0.1.
4. Проверьте `flutter pub publish --dry-run` и содержимое архива.
5. Workflow `flutter-sdk-release` запускается вручную; параметр `publish` управляет публикацией в pub.dev.

Flutter-пакет подключает Android SDK из публичного Maven-репозитория и iOS SDK через CocoaPods. В Podfile используются SDK и Extension из одного git-тега `v2.0.1`; отдельные checkout нативных SDK приложению не требуются.
