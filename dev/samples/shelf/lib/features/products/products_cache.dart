import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'product.dart';

/// The product list saved on the device under `products_cache`:
/// `{"saved_at": "<ISO-8601 UTC>", "items": [<product json>, ...]}`.
class ProductsCache {
  ProductsCache(this._prefs, this._now);

  static const String key = 'products_cache';
  static const Duration maxAge = Duration(minutes: 10);

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  /// The saved items when `saved_at` is younger than [maxAge]; otherwise
  /// null. An entry that is too old or cannot be parsed is deleted.
  List<Product>? read() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(map['saved_at'] as String);
      if (_now().difference(savedAt) >= maxAge) {
        _prefs.remove(key);
        return null;
      }
      final items = map['items'] as List<dynamic>;
      return [
        for (final item in items)
          Product.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      _prefs.remove(key);
      return null;
    }
  }

  Future<void> write(List<Product> items) {
    final json = <String, dynamic>{
      'saved_at': _now().toUtc().toIso8601String(),
      'items': [for (final item in items) item.toJson()],
    };
    return _prefs.setString(key, jsonEncode(json));
  }
}
