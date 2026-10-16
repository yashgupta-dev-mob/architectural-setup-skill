import 'package:mymali/core/services/secure_storage/secure_storage.dart';

/// In-memory [SecureStorage].
class FakeSecureStorage implements SecureStorage {
  FakeSecureStorage([Map<String, String>? values]) : values = {...?values};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
