/// The device cache could not be read or written. Thrown by `LocalCache`
/// and local data sources; repositories catch it, and nothing above a
/// repository ever sees it.
class CacheException implements Exception {
  const CacheException([this.message]);

  final String? message;

  @override
  String toString() => 'CacheException($message)';
}
