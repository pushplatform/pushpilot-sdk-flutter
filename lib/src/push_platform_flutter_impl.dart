import 'dart:io';
import 'package:flutter/services.dart';
import 'models/push_message.dart';
import 'models/call_info.dart';
import 'models/state_change.dart';

/// Main SDK class for Push Platform Flutter
///
/// This is a thin wrapper over native iOS/Android SDKs.
/// All business logic, retry, and deduplication happen in the native layer.
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

  // Event channels for push/VoIP/call/state events
  static const EventChannel _pushEventChannel =
      EventChannel('com.pushplatform/push_events');
  static const EventChannel _voipEventChannel =
      EventChannel('com.pushplatform/voip_events');
  static const EventChannel _callEventChannel =
      EventChannel('com.pushplatform/call_events');
  static const EventChannel _stateEventChannel =
      EventChannel('com.pushplatform/state_events');

  // Lazy-initialized streams
  Stream<PushMessage>? _onPushReceived;
  Stream<StateChange>? _onStateChange;

  /// Initialize the SDK
  ///
  /// Must be called before any other SDK methods.
  ///
  /// [apiKey] - API key from push-platform dashboard (devices:write scope)
  /// [apiBaseURL] - Base URL of the push platform API (default: https://api.pushplatform.example)
  /// [environment] - Environment name ('production' or 'development')
  /// [debugMode] - Enable verbose logging (default: false)
  ///
  /// Throws [PlatformException] on initialization failure.
  Future<void> initialize({
    required String apiKey,
    String apiBaseURL = 'https://api.pushplatform.example',
    required String environment,
    bool debugMode = false,
  }) async {
    final args = {
      'apiKey': apiKey,
      'apiBaseURL': apiBaseURL,
      'environment': environment,
      'debugMode': debugMode,
    };
    await _methodChannel.invokeMethod('initialize', args);
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
  /// [metadata] - Optional user metadata
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

  /// Stream of received push messages
  ///
  /// Emits a [PushMessage] whenever a push notification is received.
  Stream<PushMessage> get onPushReceived {
    _onPushReceived ??= _pushEventChannel.receiveBroadcastStream().map(
          (event) => PushMessage.fromMap(
            Map<String, dynamic>.from(event as Map),
          ),
        );
    return _onPushReceived!;
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
