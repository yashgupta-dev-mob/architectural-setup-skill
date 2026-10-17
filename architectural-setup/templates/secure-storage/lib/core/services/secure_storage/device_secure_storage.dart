import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../pref_utils.dart';
import 'secure_storage.dart';

/// [SecureStorage] on the iOS Keychain and, on Android, values encrypted with
/// a key held in the Android Keystore. The only file that imports
/// `flutter_secure_storage`.
///
/// Values are also kept in memory once read or written, so the token sent on
/// every request is not read from the Keychain each time. The memory is
/// shared by every instance, as `Supabase.initialize` and `get_it` each make
/// one.
class DeviceSecureStorage implements SecureStorage {
  DeviceSecureStorage({FlutterSecureStorage storage = _storage})
    : _platform = storage;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    // A Keystore key lost to a backup restore wipes the values instead of
    // failing every read.
    aOptions: AndroidOptions(resetOnError: true),
    // Readable after the first unlock (background token refresh), and never
    // copied to a backup or another device.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Set in `PrefUtils` once this install has started. On iOS the Keychain
  /// survives an uninstall, so a missing flag means a fresh install whose
  /// Keychain may still hold the previous install's tokens.
  static const String installedKey = 'secure_storage.installed';

  static final Map<String, String?> _memory = {};

  final FlutterSecureStorage _platform;

  /// Wipes what a previous install left behind. Call once in `bootstrap()`,
  /// before `Supabase.initialize`. Never throws.
  static Future<void> init({
    PrefUtils? prefs,
    FlutterSecureStorage storage = _storage,
  }) async {
    final pref = prefs ?? PrefUtils();
    try {
      await pref.init();
      if (pref.getBool(key: installedKey) == true) return;
      await storage.deleteAll();
      _memory.clear();
      await pref.setBool(key: installedKey, value: true);
    } catch (e) {
      log('[secure_storage] init failed: $e');
    }
  }

  @visibleForTesting
  static void resetMemory() => _memory.clear();

  @override
  Future<String?> read(String key) async {
    if (_memory.containsKey(key)) return _memory[key];
    try {
      return _memory[key] = await _platform.read(key: key);
    } catch (e) {
      log('[secure_storage] read failed for $key: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    _memory[key] = value;
    try {
      await _platform.write(key: key, value: value);
    } catch (e) {
      log('[secure_storage] write failed for $key: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    _memory[key] = null;
    try {
      await _platform.delete(key: key);
    } catch (e) {
      log('[secure_storage] delete failed for $key: $e');
    }
  }
}
