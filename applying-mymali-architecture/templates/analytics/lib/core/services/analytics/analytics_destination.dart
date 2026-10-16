/// A third-party place events are sent to besides Katyayani Core (Google
/// Analytics 4, Meta). Each one wraps one SDK and is the only file that
/// imports it. Every method is safe to call when the SDK is not running: it
/// then does nothing, and never throws.
abstract interface class AnalyticsDestination {
  /// Sends one event by its app name (an `AppEvents` value); the destination
  /// shapes the name and the parameters its own way.
  void log(String eventName, Map<String, Object?>? properties);

  /// Ties the events to the signed-in user, or to nobody when [userId] is null.
  void setUserId(String? userId);

  /// Asks for the iOS App Tracking Transparency permission and tells the
  /// destination the answer. Does nothing on Android and where the
  /// destination has no use for it.
  Future<void> requestTrackingPermission();
}
