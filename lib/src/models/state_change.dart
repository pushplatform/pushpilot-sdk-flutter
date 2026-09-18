/// State change events from the SDK
enum StateChange {
  /// SDK initialized successfully
  initialized,

  /// Push notification permissions granted
  permissionsGranted,

  /// Push notification permissions denied
  permissionsDenied,

  /// Device registered with push platform
  registered,

  /// User logged in successfully
  loggedIn,

  /// User logged out
  loggedOut,

  /// Error occurred
  error,
}

extension StateChangeExtension on StateChange {
  String toJson() => name;

  static StateChange fromJson(String value) {
    switch (value) {
      case 'initialized':
        return StateChange.initialized;
      case 'permissionGranted':
      case 'permissionsGranted':
        return StateChange.permissionsGranted;
      case 'permissionDenied':
      case 'permissionsDenied':
        return StateChange.permissionsDenied;
      case 'tokenRefreshed':
      case 'registered':
        return StateChange.registered;
      case 'loggedIn':
        return StateChange.loggedIn;
      case 'loggedOut':
        return StateChange.loggedOut;
      case 'error':
        return StateChange.error;
      default:
        return StateChange.error;
    }
  }
}
