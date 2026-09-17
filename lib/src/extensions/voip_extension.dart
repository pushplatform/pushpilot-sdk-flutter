import 'dart:io';
import 'package:flutter/services.dart';
import 'push_platform_flutter_impl.dart';
import 'models/call_info.dart';

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
  /// NOTE: VoIP registration happens automatically when the SDK is initialized.
  /// This method is kept for API compatibility but is effectively a no-op.
  /// The native SDK's PushKitManager registers for VoIP push immediately upon initialization.
  ///
  /// VoIP token handling and CallKit integration happen entirely in the native Swift layer.
  ///
  /// Throws [UnsupportedError] if called on non-iOS platforms.
  Future<void> registerForVoIP() async {
    if (!Platform.isIOS) {
      throw UnsupportedError(
        'VoIP registration is only supported on iOS',
      );
    }
    // VoIP registration is automatic - this is a no-op for API compatibility
    await _methodChannel.invokeMethod('registerForVoIP');
  }

  /// Stream of incoming VoIP calls (iOS only)
  ///
  /// Emits a [CallInfo] whenever a VoIP push notification is received.
  /// The CallKit UI is presented by the native SDK before this event is emitted.
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
