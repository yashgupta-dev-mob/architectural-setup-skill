// GENERIC: per app. One box per feature that already cached server data.
/// Names of the cache boxes. One box per feature.
abstract final class CacheBoxes {
  /// Every box, opened at startup.
  static const List<String> all = [];

  /// Boxes holding the signed-in user's data, cleared on sign-out.
  static const List<String> userScoped = [];
}
