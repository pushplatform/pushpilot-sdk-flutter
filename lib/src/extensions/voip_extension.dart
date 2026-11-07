import 'dart:io';
import 'package:flutter/services.dart';
import '../push_platform_flutter_impl.dart';
import '../models/call_info.dart';

/// iOS-specific VoIP extension for PushPlatformFlutter
///
/// VoIP push notifications and CallKit integration are iOS-only features.
/// This extension provides access to VoIP events on iOS.
///
/// On non-iOS platforms, calling these methods will throw [UnsupportedError].
extension PushPlatformFlutterVoIP on PushPlatformFlutter {
  static Stream<CallInfo>? _onVoIPCallReceived;

  static const MethodChannel _methodChannel =
      MethodChannel('com.pushplatform/sdk');
  static const EventChannel _voipEventChannel =
      EventChannel('com.pushplatform/voip_events');

  /// Register for VoIP push notifications (iOS only)
  ///
  /// A native PushKit/CallKit integration must already be installed during launch.
  /// This method validates that integration; it never starts a second calling stack.
  Future<void> registerForVoIP() async {
    if (!Platform.isIOS) {
      throw UnsupportedError(
        'VoIP registration is only supported on iOS',
      );
    }
    await _methodChannel.invokeMethod('registerForVoIP');
  }

  /// Stream of incoming VoIP calls (iOS only)
  ///
  /// Emits a [CallInfo] whenever a VoIP push notification is received.
  /// The native application handler must report the call before this event is emitted.
  ///
  /// Throws [UnsupportedError] if accessed on non-iOS platforms.
  Stream<CallInfo> get onVoIPCallReceived {
    if (!Platform.isIOS) {
      throw UnsupportedError(
        'VoIP events are only supported on iOS',
      );
    }
    _onVoIPCallReceived ??= _voipEventChannel.receiveBroadcastStream().map(
          (event) => CallInfo.fromMap(
            Map<String, dynamic>.from(event as Map),
          ),
        );
    return _onVoIPCallReceived!;
  }
}
