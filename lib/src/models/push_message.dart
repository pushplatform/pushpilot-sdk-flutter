import 'package:flutter/foundation.dart';
import 'push_type.dart';

/// Represents a received push notification message
@immutable
class PushMessage {
  /// Unique message identifier
  final String messageId;

  /// Notification title (null for silent push)
  final String? title;

  /// Notification body text (null for silent push)
  final String? body;

  /// Additional custom data payload
  final Map<String, dynamic> data;

  /// Type of push notification
  final PushType type;

  /// Timestamp when message was received
  final DateTime receivedAt;

  const PushMessage({
    required this.messageId,
    this.title,
    this.body,
    required this.data,
    required this.type,
    required this.receivedAt,
  });

  /// Creates a PushMessage from a platform channel map
  factory PushMessage.fromMap(Map<String, dynamic> map) {
    return PushMessage(
      messageId: map['messageId'] as String,
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      type: PushTypeExtension.fromJson(map['type'] as String? ?? 'normal'),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        map['receivedAt'] as int,
      ),
    );
  }

  /// Converts to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'title': title,
      'body': body,
      'data': data,
      'type': type.toJson(),
      'receivedAt': receivedAt.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PushMessage &&
        other.messageId == messageId &&
        other.title == title &&
        other.body == body &&
        mapEquals(other.data, data) &&
        other.type == type &&
        other.receivedAt == receivedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      messageId,
      title,
      body,
      Object.hashAllUnordered(
        data.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      type,
      receivedAt,
    );
  }

  @override
  String toString() {
    return 'PushMessage(messageId: $messageId, title: $title, body: $body, '
        'type: $type, receivedAt: $receivedAt)';
  }
}
