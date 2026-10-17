/// A copy of server data kept on the device, as JSON under a box and key.
///
/// Every entry is saved with a schema version and the time it was saved,
/// so versioning and expiry are handled here once, not in every feature.
/// Only local data sources use this. Methods throw `CacheException` when
/// the store itself fails.
abstract interface class LocalCache {
  /// The saved JSON (a decoded Map or List). Returns null when:
  /// - nothing is saved under [key]
  /// - it was saved with a different [version] (the entry is deleted)
  /// - it is older than [maxAge]
  /// - it is corrupt (the entry is deleted)
  Future<Object?> read({
    required String box,
    required String key,
    required int version,
    Duration? maxAge,
  });

  /// Saves [json] (a `toJson()` result) with [version] and the current
  /// time.
  Future<void> write({
    required String box,
    required String key,
    required int version,
    required Object json,
  });

  Future<void> delete({required String box, required String key});

  Future<void> clearBox(String box);

  /// Clears every box in `CacheBoxes.userScoped`. Called on sign-out.
  Future<void> clearUserScoped();
}
