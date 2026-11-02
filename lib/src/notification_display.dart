import 'models/push_message.dart';

class NotificationDisplayEvent {
  final PushMessage notification;
  final void Function() preventDefault;

  const NotificationDisplayEvent({
    required this.notification,
    required this.preventDefault,
  });
}

/// Runs display listeners and reports whether the banner should be hidden.
/// preventDefault after the listener returns does not change the result.
bool deliverNotificationDisplay(
  Iterable<void Function(NotificationDisplayEvent event)> listeners,
  PushMessage notification,
) {
  var prevented = false;
  var settled = false;
  final event = NotificationDisplayEvent(
    notification: notification,
    preventDefault: () {
      if (!settled) prevented = true;
    },
  );
  for (final listener in listeners) {
    listener(event);
  }
  settled = true;
  return prevented;
}
