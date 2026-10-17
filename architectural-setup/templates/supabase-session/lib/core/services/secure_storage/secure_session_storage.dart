import 'package:supabase_flutter/supabase_flutter.dart';

import '../pref_utils.dart';
import 'secure_storage.dart';

/// Keeps the Supabase session (access and refresh tokens) in
/// [SecureStorage] instead of the SDK's default, SharedPreferences. Passed
/// to `Supabase.initialize` in `bootstrap()`.
///
/// A session an earlier build saved in SharedPreferences is moved here on
/// [initialize], so nobody is signed out by the update.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this._storage,
    required this._prefs,
    required String supabaseUrl,
  }) : key = keyFor(supabaseUrl);

  final SecureStorage _storage;
  final PrefUtils _prefs;

  /// The SDK's own key, so the old copy is found where the SDK left it.
  final String key;

  static String keyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    await _prefs.init();
    final legacy = _prefs.getString(key: key);
    if (legacy == null) return;
    if (await _storage.read(key) == null) await _storage.write(key, legacy);
    await _prefs.remove(key: key);
  }

  @override
  Future<bool> hasAccessToken() async => await _storage.read(key) != null;

  @override
  Future<String?> accessToken() => _storage.read(key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key, persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key);
}
