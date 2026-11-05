import 'dart:async';

import 'package:flutter/services.dart';
import 'models/push_message.dart';
import 'models/state_change.dart';
import 'notification_display.dart';

export 'notification_display.dart';

/// Main SDK class for Push Platform Flutter
///
/// This is a thin wrapper over native iOS/Android SDKs.
/// All business logic, retry, and deduplication happen in the native layer.
class InitializeOptions {
  final String applicationId;
  final String? url;
  final String? environment;
  final bool debugMode;
  final double? foregroundBannerFallback;

  const InitializeOptions({
    required this.applicationId,
    this.url,
    this.environment,
    this.debugMode = false,
    this.foregroundBannerFallback,
  });
}

class PushPlatformFlutter {
  static PushPlatformFlutter? _instance;

  /// Singleton instance
  static PushPlatformFlutter get instance {
    _instance ??= PushPlatformFlutter._();
    return _instance!;
  }

  PushPlatformFlutter._();

  // Method channel for SDK method calls
  static const MethodChannel _methodChannel =
      MethodChannel('com.pushplatform/sdk');

  // Event channels for push/state events
  static const EventChannel _pushEventChannel =
      EventChannel('com.pushplatform/push_events');
  static const EventChannel _stateEventChannel =
      EventChannel('com.pushplatform/state_events');
  static const EventChannel _openedEventChannel =
      EventChannel('com.pushplatform/notification_opened');
  static const EventChannel _willDisplayEventChannel =
      EventChannel('com.pushplatform/notification_will_display');
  static const EventChannel _tokenEventChannel =
      EventChannel('com.pushplatform/token_events');

  // Lazy-initialized streams
  Stream<PushMessage>? _onPushReceived;
  Stream<PushMessage>? _onNotificationOpened;
  Stream<NotificationDisplayEvent>? _onNotificationWillDisplay;
  Stream<String>? _onPushToken;
  Stream<StateChange>? _onStateChange;
  StreamController<NotificationDisplayEvent>? _displayController;
  StreamSubscription<dynamic>? _displaySource;

  /// Initialize with an application id, or with `{applicationId, url, environment}`.
  /// A string uses https://api.pushpilot.ru and omits environment.
  /// Custom url does not imply development; storage is production unless
  /// `environment` is set explicitly (legacy). APNs sandbox comes from the profile.
  /// A second call returns success.
  Future<void> initialize(Object config) async {
    final Map<String, dynamic> args;
    if (config is String) {
      args = {'applicationId': config};
    } else if (config is InitializeOptions) {
      _rejectInvalidFallback(config.foregroundBannerFallback);
      args = {
        'applicationId': config.applicationId,
        if (config.url != null) 'url': config.url,
        if (config.environment != null) 'environment': config.environment,
        'debugMode': config.debugMode,
        if (config.foregroundBannerFallback != null)
          'foregroundBannerFallback': config.foregroundBannerFallback,
      };
    } else if (config is Map) {
      final applicationId = config['applicationId'];
      if (applicationId is! String || applicationId.isEmpty) {
        throw ArgumentError('applicationId is required');
      }
      final fallback = _readFallback(config['foregroundBannerFallback']);
      args = {
        'applicationId': applicationId,
        if (config['url'] != null) 'url': config['url'],
        if (config['environment'] != null) 'environment': config['environment'],
        'debugMode': config['debugMode'] == true,
        if (fallback != null) 'foregroundBannerFallback': fallback,
      };
    } else {
      throw ArgumentError('initialize expects an application id, InitializeOptions, or a map');
    }
    await _methodChannel.invokeMethod('initialize', args);
  }

  void _rejectInvalidFallback(double? seconds) {
    if (seconds == null) return;
    if (!seconds.isFinite || seconds < 0) {
      throw ArgumentError('foregroundBannerFallback must be a non-negative number of seconds');
    }
  }

  double? _readFallback(Object? value) {
    if (value == null) return null;
    if (value is! num) {
      throw ArgumentError('foregroundBannerFallback must be a non-negative number of seconds');
    }
    final seconds = value.toDouble();
    _rejectInvalidFallback(seconds);
    return seconds;
  }

  /// Request push notification permissions
  ///
  /// On iOS: Requests authorization for alerts, badges, and sounds.
  /// On Android: Requests POST_NOTIFICATIONS permission (Android 13+).
  ///
  /// Returns `true` if permissions were granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    final result =
        await _methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  /// Login a user
  ///
  /// Associates the current device with a user identifier.
  ///
  /// [userId] - Unique user identifier
  /// [metadata] - Optional user tags stored by the server login request.
  ///
  /// Returns the device ID on success, or null on failure.
  ///
  /// Throws [PlatformException] on login failure.
  Future<String?> login({
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    final args = {
      'userId': userId,
      if (metadata != null) 'metadata': metadata,
    };
    return await _methodChannel.invokeMethod<String>('login', args);
  }

  /// Logout the current user
  ///
  /// Disassociates the device from the current user.
  ///
  /// Throws [PlatformException] on logout failure.
  Future<void> logout() async {
    await _methodChannel.invokeMethod('logout');
  }

  /// Get the device ID
  ///
  /// Returns the unique device identifier, or null if not yet registered.
  Future<String?> get deviceId async {
    return await _methodChannel.invokeMethod<String>('getDeviceId');
  }

  /// Get the current user ID
  ///
  /// Returns the logged-in user identifier, or null if not logged in.
  Future<String?> get userId async {
    return await _methodChannel.invokeMethod<String>('getUserId');
  }

  Future<String?> getDeviceToken() {
    return _methodChannel.invokeMethod<String>('getDeviceToken');
  }

  Future<String> getPermissionStatus() async {
    final status = await _methodChannel.invokeMethod<String>('getPermissionStatus');
    if (status == 'granted' || status == 'denied' || status == 'not-determined') return status!;
    return 'not-determined';
  }

  /// Delivery only. A click is [onNotificationOpened].
  Stream<PushMessage> get onPushReceived {
    _onPushReceived ??= _pushEventChannel.receiveBroadcastStream().map(
          (event) => PushMessage.fromMap(
            Map<String, dynamic>.from(event as Map),
          ),
        );
    return _onPushReceived!;
  }

  Stream<PushMessage> get onNotificationOpened {
    _onNotificationOpened ??= _openedEventChannel.receiveBroadcastStream().map(
          (event) => PushMessage.fromMap(Map<String, dynamic>.from(event as Map)),
        );
    return _onNotificationOpened!;
  }

  Stream<String> get onPushToken {
    _onPushToken ??= _tokenEventChannel.receiveBroadcastStream().map((event) => event as String);
    return _onPushToken!;
  }

  Stream<NotificationDisplayEvent> get onNotificationWillDisplay {
    _displayController ??= StreamController<NotificationDisplayEvent>.broadcast(
      onListen: () {
        _displaySource = _willDisplayEventChannel.receiveBroadcastStream().listen((event) {
          final payload = Map<String, dynamic>.from(event as Map);
          final message = PushMessage.fromMap(Map<String, dynamic>.from(payload['notification'] as Map));
          var settled = false;
          var prevented = false;
          final display = NotificationDisplayEvent(
            notification: message,
            preventDefault: () {
              if (!settled) prevented = true;
            },
          );
          _displayController?.add(display);
          settled = true;
          unawaited(_methodChannel.invokeMethod('completeNotificationDisplay', {
            'id': payload['id'],
            'prevented': prevented,
          }));
        });
      },
      onCancel: () async {
        await _displaySource?.cancel();
        _displaySource = null;
      },
    );
    _onNotificationWillDisplay ??= _displayController!.stream;
    return _onNotificationWillDisplay!;
  }

  /// Stream of SDK state changes
  ///
  /// Emits [StateChange] events when the SDK state changes
  /// (initialized, permissions granted/denied, logged in/out, etc.).
  Stream<StateChange> get onStateChange {
    _onStateChange ??= _stateEventChannel.receiveBroadcastStream().map(
          (event) => StateChangeExtension.fromJson(event as String),
        );
    return _onStateChange!;
  }
}
