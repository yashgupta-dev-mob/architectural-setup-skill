import 'dart:convert';

import 'package:mymali/core/app/exceptions/cache_exceptions.dart';
import 'package:mymali/core/services/local_cache/cache_boxes.dart';
import 'package:mymali/core/services/local_cache/local_cache.dart';

/// In-memory [LocalCache] for tests. Values go through JSON, as in the
/// real cache, and [version] and `maxAge` are honoured against [now].
///
/// Set [readError] or [writeError] to make those calls throw.
class FakeLocalCache implements LocalCache {
  FakeLocalCache({DateTime? now}) : now = now ?? DateTime.utc(2026, 10, 1);

  /// The clock; move it forward to test expiry.
  DateTime now;

  CacheException? readError;
  CacheException? writeError;

  int clearUserScopedCalls = 0;

  final Map<String, Map<String, _Entry>> _boxes = {};

  /// Keys saved in [box], in the order they were written.
  List<String> keysOf(String box) => [...?_boxes[box]?.keys];

  @override
  Future<Object?> read({
    required String box,
    required String key,
    required int version,
    Duration? maxAge,
  }) async {
    final error = readError;
    if (error != null) throw error;

    final entry = _boxes[box]?[key];
    if (entry == null) return null;
    if (entry.version != version) {
      _boxes[box]?.remove(key);
      return null;
    }
    if (maxAge != null && now.difference(entry.savedAt) > maxAge) return null;
    return jsonDecode(entry.json);
  }

  @override
  Future<void> write({
    required String box,
    required String key,
    required int version,
    required Object json,
  }) async {
    final error = writeError;
    if (error != null) throw error;

    _boxes.putIfAbsent(box, () => {})[key] = _Entry(
      version: version,
      savedAt: now,
      json: jsonEncode(json),
    );
  }

  @override
  Future<void> delete({required String box, required String key}) async {
    _boxes[box]?.remove(key);
  }

  @override
  Future<void> clearBox(String box) async {
    _boxes.remove(box);
  }

  @override
  Future<void> clearUserScoped() async {
    clearUserScopedCalls++;
    for (final box in CacheBoxes.userScoped) {
      await clearBox(box);
    }
  }
}

class _Entry {
  const _Entry({
    required this.version,
    required this.savedAt,
    required this.json,
  });

  final int version;
  final DateTime savedAt;
  final String json;
}
