/// The device's own notification setup: the plugin and the Android channel
/// every push is shown on.
///
/// Showing notifications is not built yet (`TODO(push)`).
abstract interface class LocalNotificationService {
  /// Sets up the plugin and creates the `push_campaigns` channel. Never throws: a
  /// failure is logged and pushes fall back to the system's default sound.
  Future<void> init();
}
