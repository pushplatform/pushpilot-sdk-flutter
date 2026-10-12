# Пример PushPilot Flutter

`flutter pub get` и `flutter run` собирают экран без credentials и без автоматических сетевых вызовов. Для подключения к своему серверу используйте код настройки из корневого README. Старые `main_original.dart`, `main_verification.dart` и integration tests — внутренние исторические сценарии; они требуют сервера и не входят в релизный архив.

Нативные SDK загружаются из публичных Maven/CocoaPods, соседние репозитории не нужны. Для iOS создайте стандартный Flutter runner и CocoaPods Podfile, как описано в корневом README.
