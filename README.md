# PushPilot Flutter SDK

Плагин push_platform_flutter подключает нативные iOS и Android SDK как зависимости. Дополнительные записи native SDK в основной target Podfile не нужны. Dart API предоставляет регистрацию установки, пользователя, разрешения и события уведомлений.

## Формы инициализации

Выполните один из вариантов один раз при запуске приложения.
`debugMode: true` включает диагностику; для обычной работы используйте `false`.

```dart
final sdk = PushPlatformFlutter.instance;
await sdk.initialize(const InitializeOptions(
  applicationId: 'YOUR_APPLICATION_UUID',
  debugMode: true,
));

await sdk.initialize('YOUR_APPLICATION_UUID');
```

## Требования и установка

Flutter 3.24+, Dart 3.5+, Android API 21+ или iOS 13+. Для сборки Android нужен JDK 17, Kotlin Gradle plugin 2.0+ и установленный Android SDK; для iOS — macOS, Xcode и CocoaPods. Состав поставки и процедура обновления описаны в [документации релиза](https://github.com/pushplatform/pushpilot-sdk-flutter/blob/main/docs/UNIFIED_APPLICATIONS.md).

```sh
flutter pub add push_platform_flutter
```

Либо добавьте в `pubspec.yaml` и выполните `flutter pub get`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  push_platform_flutter: '>=2.0.0 <3.0.0'
```

Нативные зависимости подключает плагин:

- Android: `com.pushplatform:sdk-android` из [публичного Maven-репозитория](https://github.com/pushplatform/pushpilot-sdk-android/tree/maven), **не из Maven Central**. AndroidX, Firebase Messaging и OkHttp разрешаются транзитивно.


Dart-import `package:push_platform_flutter/push_platform_flutter.dart`, публичный API, имя модуля плагина `push_platform_flutter` и нативные типы `PushPlatform` сохранены.

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

Плагин передаёт APNs callbacks нативному SDK. Токены не нужно получать или отправлять через Dart.

### Подтверждение доставки при закрытом приложении

iOS показывает баннер, не запуская приложение. `received` отправляет `PushPlatformExtension` (отдельный pod). Плагин target не создаёт. Без него баннер и нажатие остаются.

1. Откройте `ios/Runner.xcworkspace`. **File → New → Target → Notification Service Extension**. **Don't Activate**. Deployment Target как у Runner, не ниже iOS 13.
2. Bundle ID extension — bundle ID приложения плюс `.PushPlatformNotificationService`. Для `com.example.app` это `com.example.app.PushPlatformNotificationService`.
3. **App Groups** на Runner и на extension: `group.com.example.app.pushplatform`.
4. Добавьте отдельный target extension и замените NotificationService.swift кодом ниже. В extension используйте `import PushPlatformExtension`.

```ruby
target 'PushPlatformNotificationServiceExtension' do
	pod 'PushPlatformExtension', '>= 2.0.0', '< 3.0'
end
```

```swift
import UserNotifications
import PushPlatformExtension

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        if let bestAttemptContent {
            PushPlatformExtension.didReceive(receivedRequest, with: bestAttemptContent, withContentHandler: contentHandler)
        } else {
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent,
           PushPlatformExtension.serviceExtensionTimeWillExpireRequest(receivedRequest, with: bestAttemptContent) {
            contentHandler(bestAttemptContent)
        }
    }
}
```

Extension не меняет баннер. Приложение при инициализации записывает в App Group адрес сервера, application id и subscription id.

## Минимальный пример

Получите UUID приложения PushPilot. Ключ серверной отправки хранится на сервере и не передаётся в SDK. `applicationId` ниже — UUID приложения **PushPilot**, а не Android package name или iOS Bundle ID. Замените `YOUR_APPLICATION_UUID` UUID своего приложения. Административные и приватные provider credentials остаются на сервере.

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
      await sdk.initialize(InitializeOptions(
        applicationId: 'YOUR_APPLICATION_UUID',
        debugMode: false,
      ));
      final allowed = await sdk.requestPermissions();
      await sdk.login(userId: 'user-123', metadata: {'role': 'customer'});
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
- `userId` возвращает `null` на обеих платформах; храните текущего пользователя в приложении. `login(userId, metadata)` передаёт metadata в тело login, и сервер записывает её в теги.
- `onPushReceived` — только доставка. Клик приходит в `onNotificationOpened`. Показ в foreground — в `onNotificationWillDisplay`; `preventDefault()` до возврата обработчика скрывает баннер, звук и бейдж. `getDeviceToken()` возвращает последний APNs или FCM токен. Обновление токена приходит в `onPushToken`.
- Silent push не гарантирует запуск Dart-кода в фоне. Доставка зависит от FCM/APNs, разрешений и ограничений ОС.
- Android SDK получает текущий FCM-токен при инициализации и регистрирует его на сервере. `getDeviceToken()` и `onPushToken` отдают этот токен в Dart. `getPermissionStatus()` возвращает `granted`, `denied` или `not-determined`.
- Событие звонка не предоставляет аудиотранспорт или управление разговором. Полноэкранный интерфейс звонка на Android этот Flutter API не настраивает. В 2.0 iOS не создаёт PushKit или CallKit при обычной инициализации. Приложение настраивает нативный CallKit/CallKeep и передаёт VoIP-токен через `PushPlatform.shared.registerVoIPToken`. Альтернатива — `startVoIPNotifications(handler:)`, чей нативный handler немедленно сообщает звонок системному CallKit. `registerForVoIP()` проверяет наличие этой интеграции и возвращает ошибку, если она не настроена. Dart callback не может заменить нативный handler при холодном запуске.
- Повторные попытки сетевых операций и дедупликация выполняются нативными SDK. Их очереди и кеши имеют ограничения; инициализация и регистрация повторяются нативным SDK после восстановления сети.
- `debugMode` предназначен для разработки: нативные логи могут содержать пользовательские идентификаторы. Для FCM подключите Firebase-конфигурацию приложения.

[Пример](https://github.com/pushplatform/pushpilot-sdk-flutter/tree/main/example), [исходники](https://github.com/pushplatform/pushpilot-sdk-flutter), [Issues](https://github.com/pushplatform/pushpilot-sdk-flutter/issues). Лицензия — MIT.


### Текущая поставка · 2.0.4

Обновление: `flutter pub upgrade push_platform_flutter`, затем в `ios` — `pod update push_platform_flutter PushPlatformSDK PushPlatformExtension --repo-update`. Сохраняйте Podfile.lock и пересоберите приложение.

`initialize` принимает application id, `InitializeOptions` или map с `applicationId`, `debugMode` и необязательным `foregroundBannerFallback`. Секретный ключ не нужен. Нативные зависимости — `sdk-android:2.0.3` и `PushPlatformSDK` 2.0.3.

Открытие уведомления нативный SDK сообщает сам: при клике, в том числе при холодном старте, он отправляет `PUT /notifications/{id}`; до `initialize` открытие ждёт в очереди. `PushMessage.notificationId` в потоках клика и показа содержит id из ответа `POST /notifications`; поле `notification_id` в `data` не попадает.

### Unified applications

One PushPilot application contains iOS, Android and Web providers. Use the application ID in SDKs. Keep the permanent application key in server code for sending notifications; device registration does not require that key. Rotate or revoke it in the console.
Omit `environment` during initialization. iOS derives APNs transport from the simulator/build entitlement; Android uses the unified registration scope. The optional legacy argument remains compatible.
Native SDKs report actual model, OS/SDK/app version, language, time zone, permission and physical/simulator/emulator kind (unknown where unavailable). Test subscription is an independent console marker. Metadata refreshes on foreground and permission changes.
