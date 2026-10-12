# Релиз PushPilot Flutter SDK 1.0.0

Дата подготовки: 2026-10-12. Пакет: `push_platform_flutter` 1.0.0. Ветка: `release/flutter-1.0.0`. Работа выполняется только в репозитории `pushpilot-sdk-flutter`; merge выполняет владелец.

## Опубликованные зависимости

Android: `com.pushplatform:sdk-android:1.0.0`. Проверены анонимные загрузки [POM](https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/com/pushplatform/sdk-android/1.0.0/sdk-android-1.0.0.pom), AAR и разрешение транзитивных зависимостей в чистом приложении. Репозиторий — публичная ветка `maven` на GitHub; Maven Central не используется. SHA-256 AAR: `eb5912dced22c09887961e043f6f10c6a8601467876349af2cd49d93145b6a9d`.

iOS: CocoaPod `PushPlatformSDK` **1.0.0**. В podspec плагина закреплено `s.dependency 'PushPlatformSDK', '1.0.0'`. [Trunk API](https://trunk.cocoapods.org/api/v1/pods/PushPlatformSDK/specs/1.0.0), [CDN spec](https://cdn.cocoapods.org/Specs/a/4/5/PushPlatformSDK/1.0.0/PushPlatformSDK.podspec.json) и индекс `all_pods_versions_a_4_5.txt` подтвердили доступность версии. Pod скачивает исходники из публичного репозитория по тегу `v1.0.0`; приватный Git и локальный checkout не нужны.

Источники API сверены с архивами опубликованных тегов Android `v1.0.0` (609af86) и iOS `v1.0.0` (db4a57e). Эти архивы использовались для чтения, не как зависимости приложения.

## Изменения

- Метаданные pub.dev, MIT LICENSE, русский README, описание ограничений нативных SDK.
- Фиксированные нативные версии 1.0.0, публичный Maven URL подключается ко всем проектам для разрешения транзитивной зависимости в app runtime classpath.
- Убрана composite dependency примера на соседний Android checkout.
- `initialize` требует URL API и UUID приложения PushPilot; передаёт их обоим SDK и ждёт завершения регистрации installation.
- iOS передаёт APNs/notification lifecycle callbacks, Android ждёт permission result; асинхронные ответы возвращаются на главном потоке.
- Пример больше не инициирует сетевые запросы при запуске. Исторические внутренние сценарии и отчёты исключены из pub-архива через `.pubignore`.

## Проверки

Среда: Flutter 3.47.4 stable, Dart 3.13.3, Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, CocoaPods 1.16.2. Поддерживаемые нижние границы пакета: Flutter 3.24 / Dart 3.5; Android требует Kotlin Gradle Plugin 2.0+ и JDK 17. Проверка нижних границ отдельно не выполнялась.

- `flutter analyze` — без замечаний.
- `flutter test --reporter expanded` — **73 теста прошли**.
- `flutter test --no-pub --reporter expanded` в `example` — **1 тест прошёл**, пример запускается без credentials и MethodChannel-вызовов.
- Создано одно новое приложение `.release-check/consumer` командой `flutter create --platforms=android,ios`. Пакет установлен из изолированного снимка релизного содержимого `.release-check/package`; приложение не ссылается на рабочий checkout SDK или соседние репозитории. До первой публикации это path dependency на копию пакета, а не установка уже размещённого пакета с pub.dev.
- Android: `flutter build apk --debug --no-pub` — **успех**, `build/app/outputs/flutter-apk/app-debug.apk`. Приложение использует стандартные Gradle-файлы Flutter и опубликованный Maven AAR; Maven Local отсутствует. Первые неудачные попытки выявили устаревший DSL и отсутствие Maven URL на app runtime classpath; исправлены в самом плагине. После успеха сборка не повторялась.
- iOS: `flutter build ios --simulator --no-pub` — **успех**, `build/ios/iphonesimulator/Runner.app` (Xcode build 26,7 s). `Podfile.lock` подтверждает `PushPlatformSDK (1.0.0)` из `trunk`, checksum `16c9e4d81fdf93a69baafb921602b743b8c37934`. Сначала отсутствовал свежий индекс, затем возникла ошибка HTTP/2 загрузки spec. Установка выполнена через одноразовый Ruby wrapper с HTTP/1.1; публичный источник сохранён, установленный CocoaPods и его исходники не менялись. После успешной сборки она не повторялась.
- `flutter pub publish --dry-run` после commit — **успех, 0 warnings**, архив ~32 KB. Предварительные запуски имели единственное предупреждение о незакоммиченных файлах; после commit оно устранено.

Приложение не запускалось на устройстве, реальные push, API credentials, Firebase config и APNs signing не использовались. Нативные исторические XCTest/JUnit и интеграционные сценарии с сервером не запускались; они не являются доказательством работоспособности реальной доставки. Пройденные проверки не повторяются без новых изменений или ошибок.

## Публикация и Git

Публикация на pub.dev разрешена владельцем. Статус: `flutter pub publish --force` запущен, валидация пройдена, CLI ожидает Google OAuth владельца. Пакет пока **не опубликован**. Владелец должен открыть предложенный CLI URL в браузере на этом Mac, выбрать Google Account и подтвердить доступ; callback приходит на localhost. Пароли и OAuth-коды в чат не передаются. После callback CLI продолжит загрузку.

Исходный release commit: `2a1be8c` (`feat: release standalone PushPilot Flutter SDK 1.0.0`), отправлен в `origin/release/flutter-1.0.0`. Отчёт обновляется отдельным commit; `docs/` исключён из pub-архива.

Страница пакета после публикации: https://pub.dev/packages/push_platform_flutter

Создание PR: https://github.com/pushplatform/pushpilot-sdk-flutter/compare/main...release/flutter-1.0.0?expand=1

Новый пакет pub.dev сначала публикуется от Google Account; после публикации при необходимости владелец может передать его verified publisher в настройках пакета. Секреты не передаются в чат. Если CLI предложит авторизацию, владелец открывает URL OAuth из CLI и подтверждает доступ в браузере.

Тег `v1.0.0` до merge не создаётся. После merge владелец может отметить объединённый релизный commit этим тегом; повторно публиковать 1.0.0 нельзя.

## Следующий релиз

1. Создать отдельную release-ветку, обновить версии pubspec/podspec и CHANGELOG.
2. Сверить реальные опубликованные нативные версии и публичные registry URLs.
3. Проверить `flutter analyze`, `flutter test`, один свежий consumer на Android/iOS. При новых ошибках исправить причину и повторить только затронутую проверку.
4. Убедиться, что архив не содержит build, credentials и внутренних материалов; сделать commit, `flutter pub publish --dry-run`, затем `flutter pub publish`.
5. Проверить pub.dev API, обновить этот отчёт, commit и push ветки. Merge выполняет владелец.

Процедура pub.dev: [официальная инструкция](https://dart.dev/tools/pub/publishing). Ограничения установки, фоновых событий, FCM и VoIP перечислены в README.
