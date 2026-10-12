# PushPilot Flutter SDK

Плагин `push_platform_flutter` подключает опубликованные Android и iOS SDK PushPilot **1.0.0**. Доступны регистрация installation, привязка пользователя, разрешения на уведомления и потоки событий. Dart API и нативные имена `PushPlatform` сохранены.

## Требования и установка

Flutter 3.24+, Dart 3.5+, Android API 21+ или iOS 13+. Для сборки Android нужен JDK 17, Kotlin Gradle plugin 2.0+ и установленный Android SDK; для iOS — macOS, Xcode и CocoaPods. Проверенная версия Flutter указана в [отчёте о релизе](https://github.com/pushplatform/pushpilot-sdk-flutter/blob/release/flutter-1.0.0/docs/RELEASING.md).

```sh
flutter pub add push_platform_flutter:^1.0.0
```

Либо добавьте в `pubspec.yaml` и выполните `flutter pub get`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  push_platform_flutter: ^1.0.0
```

Приватный Git, соседние checkout и Maven Local не нужны. Нативные зависимости подключает плагин:

- Android: `com.pushplatform:sdk-android:1.0.0` из [публичного Maven-репозитория](https://github.com/pushplatform/pushpilot-sdk-android/tree/maven), **не из Maven Central**. AndroidX, Firebase Messaging и OkHttp разрешаются транзитивно.
- iOS: `PushPlatformSDK` **1.0.0** из CocoaPods Trunk; его исходники скачиваются из публичного GitHub по тегу `v1.0.0`. Отдельная строка `pod`, Git dependency и локальный путь к SDK в приложении не нужны.

## Настройка Android

В обычном Flutter-проекте репозитории `google()` и `mavenCentral()` уже настроены, а публичный Maven URL SDK добавляет плагин. Если ваше приложение централизует репозитории через `dependencyResolutionManagement` и `RepositoriesMode.PREFER_SETTINGS`, добавьте туда:

```kotlin
repositories {
    google()
    mavenCentral()
    maven {
        url = uri("https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/")
        content { includeModule("com.pushplatform", "sdk-android") }
    }
}
```

С `FAIL_ON_PROJECT_REPOS` плагин несовместим, поскольку объявляет собственные репозитории; используйте `PREFER_SETTINGS` с настройкой выше.

Для **доставки FCM** зарегистрируйте Android-приложение с вашим `applicationId` в Firebase, добавьте свой `google-services.json` в `android/app/` и подключите официальный Gradle-плагин `com.google.gms.google-services` в проекте и модуле приложения. Альтернатива — самостоятельная нативная инициализация Firebase. Настройте соответствующий FCM provider на сервере PushPilot. Для установки и сборки пакета Firebase-конфигурация не требуется.

Разрешения `INTERNET` и `POST_NOTIFICATIONS`, а также FCM service приходят из манифеста нативного SDK. На Android 13+ вызовите `requestPermissions()` из активного приложения. При наличии другого FCM service, например `firebase_messaging`, согласуйте обработку сообщений: два service не гарантируют получение одного события обоими SDK.

## Настройка iOS

1. Укажите `platform :ios, '13.0'` или выше в `ios/Podfile` и тот же deployment target у Runner. Если Podfile ещё нет, создайте стандартный Flutter Podfile для CocoaPods. Swift Package Manager для этого Flutter-плагина не реализован.
2. Выполните `cd ios` и `pod install --repo-update`; затем откройте `Runner.xcworkspace`.
3. Для реальных уведомлений включите **Push Notifications** у Bundle ID и в Xcode Signing & Capabilities. На сервере PushPilot настройте APNs provider для того же Bundle ID и окружения. APNs ключи остаются на сервере.
4. `AppDelegate` должен наследовать `FlutterAppDelegate` и передавать ему lifecycle callbacks через `super`. Назначьте `UNUserNotificationCenter.current().delegate = self` в `application(_:didFinishLaunchingWithOptions:)`, чтобы Flutter передавал foreground-уведомления и нажатия плагину. Если у вас свой delegate уведомлений, явно согласуйте маршрутизацию с Flutter.
5. Для silent push включите **Background Modes → Remote notifications**; отдельную нативную обработку фонового обновления реализует приложение. Для VoIP включите **Background Modes → Voice over IP** и настройте VoIP topic на сервере.

Плагин передаёт APNs callbacks нативному SDK. Токены не нужно получать или отправлять через Dart. Ручное повторное подключение `PushPlatformSDK` в Podfile не требуется.

## Минимальный пример

Получите в PushPilot UUID приложения, URL своего API и клиентский SDK-ключ со scope `devices:write`. `applicationId` ниже — UUID приложения **PushPilot**, а не Android package name или iOS Bundle ID. Значения `.example` и `SDK_DEVICE_KEY` — заполнители; замените их своей конфигурацией. Серверный ключ отправки сообщений в мобильное приложение не добавляйте.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:push_platform_flutter/push_platform_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: PushDemo()));
}

class PushDemo extends StatefulWidget {
  const PushDemo({super.key});

  @override
  State<PushDemo> createState() => _PushDemoState();
}

class _PushDemoState extends State<PushDemo> {
  StreamSubscription<PushMessage>? _subscription;
  String _status = 'Нажмите для подключения';

  Future<void> _connect() async {
    try {
      final sdk = PushPlatformFlutter.instance;
      _subscription ??= sdk.onPushReceived.listen((message) {
        if (mounted) setState(() => _status = message.title ?? 'Уведомление');
      }, onError: (Object error) {
        if (mounted) setState(() => _status = 'Ошибка потока уведомлений');
      });
      await sdk.initialize(
        applicationId: '11111111-1111-1111-1111-111111111111',
        apiBaseURL: 'https://api.your-company.example',
        apiKey: 'SDK_DEVICE_KEY',
        environment: 'development',
      );
      final allowed = await sdk.requestPermissions();
      // Привязка пользователя необязательна.
      await sdk.login(userId: 'user-123');
      if (mounted) setState(() => _status = allowed ? 'Готово' : 'Разрешение не выдано');
    } catch (error) {
      if (mounted) setState(() => _status = 'Не удалось подключить PushPilot');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_status),
        ElevatedButton(onPressed: _connect, child: const Text('Подключить')),
      ],
    )),
  );
}
```

`await initialize()` завершается после ответа сервера о регистрации installation; при ошибке бросает `PlatformException`. Дождитесь его перед `login`, `logout` и запросом разрешений. `environment` принимает `production`, `development` или синоним `sandbox`; signing/APNs entitlement на iOS настраивается отдельно. Для выхода вызовите `await sdk.logout()`. ID зарегистрированного устройства доступен через `await sdk.deviceId`.

События состояния: `sdk.onStateChange`; звонков iOS: `sdk.onVoIPCallReceived`; звонков Android: `sdk.onCallReceived`. Последние два потока доступны только на соответствующей платформе. Отменяйте подписки при завершении работы экрана.

## Ограничения

- Поддерживаются только Android и iOS. Web и desktop не реализованы. На Flutter 3.47.4 совместимость с AGP 9 обеспечивается флагами стандартного Flutter-шаблона `android.newDsl=false` и `android.builtInKotlin=false`; плагин пока использует Kotlin Gradle Plugin. Более поздняя обязательная миграция Flutter на Built-in Kotlin потребует обновления плагина.
- `userId` возвращает `null` на обеих платформах; храните текущего пользователя в приложении. Аргумент `metadata` у `login` оставлен для совместимости и не передаётся нативными SDK 1.0.0.
- Dart-потоки работают при активном Flutter engine. Фоновый Dart isolate, воспроизведение пропущенных событий и отдельный поток нажатий не реализованы. На iOS получение и нажатие приходят в `onPushReceived`; на Android отдельного callback открытия нет.
- Silent push не гарантирует запуск Dart-кода в фоне. Доставка зависит от FCM/APNs, разрешений и ограничений ОС.
- Нативный Android SDK 1.0.0 регистрирует FCM-токен при `onNewToken` после настройки SDK; автоматическая повторная отправка уже существующего токена при `configure` не реализована. В запросе токена SDK использует фиксированный bundle ID `com.pushplatform.sdk`. Эти ограничения нужно учесть при оценке реальной доставки.
- Событие звонка не предоставляет аудиотранспорт или управление разговором. Полноэкранный интерфейс звонка на Android этот Flutter API не настраивает. iOS SDK автоматически создаёт PushKit/CallKit; `registerForVoIP()` — совместимый no-op, публичного переключателя VoIP нет.
- Повторные попытки сетевых операций и дедупликация выполняются нативными SDK. Их очереди и кеши имеют ограничения; первоначальная регистрация не получает автоматических повторов на уровне Dart.
- `debugMode` предназначен для разработки: нативные логи могут содержать пользовательские идентификаторы. Проверка этого релиза охватывает установку и сборку, без реальных push и credentials.

[Пример](https://github.com/pushplatform/pushpilot-sdk-flutter/tree/release/flutter-1.0.0/example), [исходники](https://github.com/pushplatform/pushpilot-sdk-flutter), [Issues](https://github.com/pushplatform/pushpilot-sdk-flutter/issues). Лицензия — MIT.
