/// Push notification type
enum PushType {
  /// Normal push with alert (visible notification)
  normal,

  /// Silent push (background data update, no notification)
  silent,
}

/// Extension for string conversion
extension PushTypeExtension on PushType {
  String toJson() {
    switch (this) {
      case PushType.normal:
        return 'normal';
      case PushType.silent:
        return 'silent';
    }
  }

  static PushType fromJson(String value) {
    switch (value) {
      case 'normal':
        return PushType.normal;
      case 'silent':
        return PushType.silent;
      default:
        // Default to normal for unknown values
        return PushType.normal;
    }
  }
}
