# Patch 1.0.2 — Android initial FCM token

Branch: `release/flutter-fcm-1.0.2`. Android dependency updates to the public immutable `com.pushplatform:sdk-android:1.0.1`. The Dart API and Android bridge stay unchanged. The iOS sources, license, lock and manifest are byte-for-byte unchanged; only the Flutter podspec package version advances to 1.0.2.

Native regression verification: the new existing-token test fails on 1.0.0; eight initial-token/race/error/scope cases plus eight FcmTokenManager tests pass on 1.0.1. Real HTTP payloads are inspected through MockWebServer. No manual token API workaround remains in the normal integration.

Publication uses normal `flutter pub publish` validation, followed by anonymous pub.dev archive/hash verification and an Android consumer of the published dependency. No unrelated console/owner E2E, physical push or iOS build is repeated. Publication and consumer results will be appended.

---
Historical reports follow.

# Релиз PushPilot Flutter SDK 1.0.1

Дата подготовки: 2026-10-24. Пакет: `push_platform_flutter` 1.0.1; patch относительно опубликованной на pub.dev версии 1.0.0. Ветка: `release/flutter-1.0.1-bundled-ios`. Merge выполняет владелец.

## Поставка iOS

CocoaPods по-прежнему используется для интеграции Flutter. Внешняя зависимость `PushPlatformSDK` из Trunk удалена. Публикация нашего native SDK в CocoaPods Trunk для этого и будущих Flutter-релизов больше не нужна.

В pub-пакете находятся все 18 Swift-файлов из `Sources/PushPlatformSDK` опубликованного тега iOS SDK `v1.0.0`, его MIT `LICENSE` и manifest с SHA-256 каждого upstream-файла. Отдельных ресурсов (в том числе privacy manifest) в этом теге нет. Зафиксированы:

- Репозиторий: https://github.com/pushplatform/pushpilot-sdk-ios.git
- Объект аннотированного тега `v1.0.0`: `db4a57e9d8d2d3fcafc914bd2aa59cc99f9d5d4f`.
- Commit: `c67bcdf57ab150a5835570e4b695b173c1953bc1`.

Podspec берёт локальные файлы из `ios/Bundled/PushPlatformSDK/Sources/PushPlatformSDK` и объявляет системные frameworks из upstream podspec. Native-типы компилируются в модуле `push_platform_flutter`, поэтому отдельный `import PushPlatformSDK` в Swift-мосте удалён. Dart-import, module name Flutter-плагина, публичный Dart API и native-типы сохранены. Отдельный Swift-модуль `PushPlatformSDK` этим пакетом не поставляется.

Пользователю достаточно установить пакет с pub.dev и выполнить обычную интеграцию Flutter через CocoaPods. Native-исходники уже в архиве: приватный Git, соседние checkout, отдельная запись native pod в Podfile и ручная настройка путей не нужны. SPM-интеграция не добавлялась. Android SDK остаётся `com.pushplatform:sdk-android:1.0.0`; посторонние зависимости не обновлялись.

## Воспроизводимое обновление bundled SDK

Скрипт нужен только сопровождающему, а не пользователю пакета. Требуются Python 3 и Git; сеть самому скрипту не нужна. Он читает Git-объекты указанного iOS-репозитория, не меняет его checkout и не зависит от его HEAD или незакоммиченных файлов.

```sh
python3 scripts/update-bundled-ios.py --ios-repo ../pushpilot-sdk-ios
```

Путь может указывать на любой локальный clone с нужным опубликованным тегом. Скрипт сверяет объект тега и его commit с `ios/native-sdk.lock.json`, экспортирует полное дерево `Sources/PushPlatformSDK` и LICENSE/NOTICE/COPYING непосредственно из зафиксированного commit и формирует `ios/Bundled/PushPlatformSDK/manifest.json`. Повторный экспорт того же тега даёт те же байты и manifest. При несовпадении SHA выполнение прекращается до замены bundled-файлов.

Для нового native-релиза сначала сверить опубликованный тег и SHA, изменить lock, затем запустить экспорт. Просмотреть изменения исходников, лицензий и ресурсов, сверить frameworks, deployment target и Swift version с upstream podspec. При появлении ресурсов добавить их в `resources`/`resource_bundles` Flutter podspec согласно upstream. Не копировать upstream Package.swift, тесты, примеры и результаты сборок. Закоммитить bundled-файлы вместе с lock и скриптом. Скрипт исключён из pub-архива, а исходники, лицензия, lock и manifest включены.

## Объём проверки 1.0.1

Только просмотр итогового diff и состава публикуемого пакета. Тесты, анализатор, сборки, симуляторы, pod install и запуск примеров не выполняются. Работоспособность сборки 1.0.1 не проверена; результаты 1.0.0 ниже относятся только к историческому релизу.

Для просмотра состава и публикации без дополнительных проверок используются:

```sh
flutter pub publish --dry-run --skip-validation
flutter pub publish --force --skip-validation
```

`--skip-validation` отключает проверки pub и разрешение зависимостей; это осознанное ограничение данного релиза. Перед отправкой просматриваются список файлов и diff. После публикации нужно подтвердить версию через API pub.dev и сверить скачанный архив с checkout, включая все bundled-файлы и их SHA-256.

## Публикация 1.0.1

Публикация **завершена**: pub.dev принял `push_platform_flutter` **1.0.1**. Дополнительная авторизация не потребовалась. [API версии](https://pub.dev/api/packages/push_platform_flutter/versions/1.0.1) подтвердил версию; время публикации: **2026-10-24T09:50:42.726579Z**.

[Опубликованный архив](https://pub.dev/api/archives/push_platform_flutter-1.0.1.tar.gz) скачан анонимно. SHA-256: `14876d4d5cd05786cbad4b975f9b898de00c49c349adbc46be4c1b2045a37ef6` — совпадает с API pub.dev. Все **69 файлов** архива побайтово совпадают с релизным checkout, включая 18 native Swift-файлов, LICENSE, lock и manifest. Скрипты, docs и внутренние материалы в архив не попали. Bundled-исходники и лицензия также побайтово сверены с зафиксированным upstream commit; их SHA-256 совпадают с manifest.

Релизный commit: `7f3177f` (`fix: bundle iOS SDK for Flutter 1.0.1 [skip ci]`). Метка `[skip ci]` предотвращает автоматический запуск тестов при push. Отчёт о публикации записан отдельным commit; `docs/` исключён из pub-архива. Тег до merge не создаётся.

Пакет: https://pub.dev/packages/push_platform_flutter/versions/1.0.1

Создание PR: https://github.com/pushplatform/pushpilot-sdk-flutter/compare/main...release/flutter-1.0.1-bundled-ios?expand=1

Тесты, анализатор, сборки, симуляторы и примеры для 1.0.1 не запускались. Успешная публикация и сверка архива не подтверждают работоспособность сборки.

---

# Исторический отчёт: 1.0.0

Следующие сведения описывают предыдущую поставку через Trunk и её проверки, а не процедуру и результаты релиза 1.0.1. Для будущих релизов используется bundled-поставка выше.

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

Публикация **завершена**: после Google OAuth владельца `flutter pub publish --force` успешно загрузил `push_platform_flutter` **1.0.0**. [Публичный API pub.dev](https://pub.dev/api/packages/push_platform_flutter) вернул HTTP 200 и `latest.version = 1.0.0`. Время публикации: **2026-10-12 12:29:10 UTC / 15:29:10 Europe/Moscow**. Дополнительная авторизация для этого релиза не требуется.

[Опубликованный архив](https://pub.dev/api/archives/push_platform_flutter-1.0.0.tar.gz) скачан анонимно. SHA-256: `10016631988852f4108530bba11692d80ffc3c343e9c21bf73de703914906e8a`; совпадает с API pub.dev. Все **48 файлов** архива побайтово совпадают с релизным checkout; внутренние материалы отсутствуют. Ранее пройденные тесты и сборки не повторялись.

Исходный release commit: `2a1be8c` (`feat: release standalone PushPilot Flutter SDK 1.0.0`), отправлен в `origin/release/flutter-1.0.0`. Отчёт обновляется отдельным commit; `docs/` исключён из pub-архива.

Опубликованный пакет: https://pub.dev/packages/push_platform_flutter

Создание PR: https://github.com/pushplatform/pushpilot-sdk-flutter/compare/main...release/flutter-1.0.0?expand=1

Первая публикация выполнена от авторизованного Google Account. При необходимости владелец может передать пакет verified publisher в разделе Admin на pub.dev; выбор/перенос publisher в этом релизе не выполнялся. Секреты не передавались в чат.

Тег `v1.0.0` до merge не создаётся. После merge владелец может отметить объединённый релизный commit этим тегом; повторно публиковать 1.0.0 нельзя.

## Историческая процедура после 1.0.0

1. Создать отдельную release-ветку, обновить версии pubspec/podspec и CHANGELOG.
2. Сверить реальные опубликованные нативные версии и публичные registry URLs.
3. Проверить `flutter analyze`, `flutter test`, один свежий consumer на Android/iOS. При новых ошибках исправить причину и повторить только затронутую проверку.
4. Убедиться, что архив не содержит build, credentials и внутренних материалов; сделать commit, `flutter pub publish --dry-run`, затем `flutter pub publish`.
5. Проверить pub.dev API, обновить этот отчёт, commit и push ветки. Merge выполняет владелец.

Процедура pub.dev: [официальная инструкция](https://dart.dev/tools/pub/publishing). Ограничения установки, фоновых событий, FCM и VoIP перечислены в README.
