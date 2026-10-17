// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../app/exceptions/cache_exceptions.dart';
import 'cache_boxes.dart';
import 'local_cache.dart';

/// [LocalCache] on Hive. Each box is a `Box<String>`, and each entry is
/// `{"version": int, "saved_at": iso8601, "data": json}` as a JSON string.
///
/// The cache is never required: if Hive or a box cannot be opened, reads
/// miss and writes throw [CacheException], and the app runs on the
/// network alone.
class HiveLocalCache implements LocalCache {
  HiveLocalCache({DateTime Function() now = DateTime.now}) : _now = now;

  final DateTime Function() _now;

  static const String _versionField = 'version';
  static const String _savedAtField = 'saved_at';
  static const String _dataField = 'data';

  /// Starts Hive and opens every box. Call once at startup, before any
  /// read. It never throws: a failure only leaves the cache off.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
    } catch (_) {
      return;
    }
    await openBoxes();
  }

  /// Opens every box in [CacheBoxes.all]. A box that cannot be opened is
  /// deleted and opened again empty; if that fails too, it stays closed.
  /// Tests call this after `Hive.init` with a temporary directory.
  static Future<void> openBoxes() async {
    for (final name in CacheBoxes.all) {
      try {
        await Hive.openBox<String>(name);
      } catch (_) {
        try {
          await Hive.deleteBoxFromDisk(name);
          await Hive.openBox<String>(name);
        } catch (_) {
          // Stays closed: reads miss, writes throw.
        }
      }
    }
  }

  @override
  Future<Object?> read({
    required String box,
    required String key,
    required int version,
    Duration? maxAge,
  }) async {
    final opened = _boxOrNull(box);
    if (opened == null) return null;

    final String? raw;
    try {
      raw = opened.get(key);
    } catch (e) {
      throw CacheException(e.toString());
    }
    if (raw == null) return null;

    final Object? entry;
    try {
      entry = jsonDecode(raw);
    } on FormatException {
      await delete(box: box, key: key);
      return null;
    }

    final savedAt = entry is Map
        ? DateTime.tryParse('${entry[_savedAtField]}')
        : null;
    final data = entry is Map ? entry[_dataField] : null;
    final isCurrent = entry is Map && entry[_versionField] == version;
    if (savedAt == null || data == null || !isCurrent) {
      // Corrupt, or written by another version of the app: never
      // readable again.
      await delete(box: box, key: key);
      return null;
    }

    if (maxAge != null && _now().difference(savedAt) > maxAge) return null;
    return data;
  }

  @override
  Future<void> write({
    required String box,
    required String key,
    required int version,
    required Object json,
  }) async {
    final opened = _boxOrNull(box);
    if (opened == null) throw CacheException('Box "$box" is not open');

    try {
      await opened.put(
        key,
        jsonEncode({
          _versionField: version,
          _savedAtField: _now().toUtc().toIso8601String(),
          _dataField: json,
        }),
      );
    } catch (e) {
      // Disk full, a value that is not JSON, or a Hive error.
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> delete({required String box, required String key}) async {
    try {
      await _boxOrNull(box)?.delete(key);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearBox(String box) async {
    try {
      await _boxOrNull(box)?.clear();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearUserScoped() async {
    for (final box in CacheBoxes.userScoped) {
      await clearBox(box);
    }
  }

  Box<String>? _boxOrNull(String name) =>
      Hive.isBoxOpen(name) ? Hive.box<String>(name) : null;
}
