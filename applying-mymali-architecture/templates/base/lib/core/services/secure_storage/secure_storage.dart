/// Encrypted key-value storage for secrets: the auth tokens and the Supabase
/// session. Everything else stays in `PrefUtils` or `LocalCache`.
///
/// It never throws: a value that cannot be read is `null`, and a value that
/// cannot be saved is kept in memory for this run and logged.
abstract interface class SecureStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
