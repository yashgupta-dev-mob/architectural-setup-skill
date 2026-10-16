// GENERIC: MyMali's json_readers.dart with neutral doc wording.
/// Lenient readers for API JSON. A missing or mistyped value reads as null
/// or empty, never a crash, so models can treat every field as optional.
library;

double? asDouble(Object? value) => value is num ? value.toDouble() : null;

int? asInt(Object? value) => value is num ? value.toInt() : null;

/// A number that may arrive as a JSON number or a numeric string, as
/// some APIs send a decimal. Anything else reads as null.
double? asNumeric(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? asString(Object? value) => value is String ? value : null;

bool? asBool(Object? value) => value is bool ? value : null;

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> asMapList(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ]
    : const [];

List<String> asStringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];
