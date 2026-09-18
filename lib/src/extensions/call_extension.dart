import 'dart:io';
import 'package:flutter/services.dart';
import '../push_platform_flutter_impl.dart';
import '../models/call_info.dart';

/// Android-specific call extension for PushPlatformFlutter
///
/// High-priority call push notifications are Android-only features.
/// This extension provides access to call events on Android.
///
/// On non-Android platforms, calling these methods will throw [UnsupportedError].
extension PushPlatformFlutterCall on PushPlatformFlutter {
  static Stream<CallInfo>? _onCallReceived;

  static const EventChannel _callEventChannel =
      EventChannel('com.pushplatform/call_events');

  /// Stream of incoming call notifications (Android only)
  ///
  /// Emits a [CallInfo] whenever a high-priority call push notification is received.
  /// The notification is displayed by the native SDK before this event is emitted.
  ///
  /// Throws [UnsupportedError] if accessed on non-Android platforms.
  Stream<CallInfo> get onCallReceived {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Call events are only supported on Android',
      );
    }
    _onCallReceived ??= _callEventChannel.receiveBroadcastStream().map(
          (event) => CallInfo.fromMap(
            Map<String, dynamic>.from(event as Map),
          ),
        );
    return _onCallReceived!;
  }
}
