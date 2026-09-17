import 'package:flutter/foundation.dart';

/// Represents an incoming call (VoIP on iOS, high-priority on Android)
@immutable
class CallInfo {
  /// Unique call identifier
  final String callId;

  /// Caller's user identifier
  final String callerId;

  /// Caller's display name (optional)
  final String? callerName;

  /// Additional call metadata
  final Map<String, dynamic> metadata;

  /// Timestamp when call was received
  final DateTime receivedAt;

  const CallInfo({
    required this.callId,
    required this.callerId,
    this.callerName,
    required this.metadata,
    required this.receivedAt,
  });

  /// Creates a CallInfo from a platform channel map
  factory CallInfo.fromMap(Map<String, dynamic> map) {
    return CallInfo(
      callId: map['callId'] as String,
      callerId: map['callerId'] as String,
      callerName: map['callerName'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        map['receivedAt'] as int,
      ),
    );
  }

  /// Converts to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'metadata': metadata,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallInfo &&
        other.callId == callId &&
        other.callerId == callerId &&
        other.callerName == callerName &&
        mapEquals(other.metadata, metadata) &&
        other.receivedAt == receivedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      callId,
      callerId,
      callerName,
      Object.hashAll(metadata.entries),
      receivedAt,
    );
  }

  @override
  String toString() {
    return 'CallInfo(callId: $callId, callerId: $callerId, '
        'callerName: $callerName, receivedAt: $receivedAt)';
  }
}
