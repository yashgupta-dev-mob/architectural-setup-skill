// GENERIC: per app. One typed getter per .env value; MyMali's _require/_optional.
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to values from the `.env` file.
///
/// Call [Env.load] once at startup before reading any value.
abstract final class Env {
  static const String _fileName = '.env';

  static Future<void> load() => dotenv.load(fileName: _fileName);

  /// The base URL of the app's main backend (`ApiHost`'s first value).
  static String get baseUrl => _require('BASE_URL');

  // ignore: unused_element
  static String? _optional(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in $_fileName (see .env.example).');
    }
    return value;
  }
}
