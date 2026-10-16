import '../../../../core/services/local_cache/cache_boxes.dart';
import '../../../../core/services/local_cache/local_cache.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/support_content_model.dart';

/// The last support content the server sent, in [CacheBoxes.support], so
/// a customer with no signal can still find how to reach us.
abstract interface class SupportLocalDataSource {
  /// The saved content, or null on a miss.
  Future<SupportContentModel?> readSupport();

  Future<void> writeSupport(SupportContentModel content);
}

class SupportLocalDataSourceImpl implements SupportLocalDataSource {
  const SupportLocalDataSourceImpl(this._cache);

  static const String contentKey = 'content';

  /// Bump whenever the model's JSON shape changes. Old entries become misses.
  static const int schemaVersion = 1;

  final LocalCache _cache;

  @override
  Future<SupportContentModel?> readSupport() async {
    final json = await _cache.read(
      box: CacheBoxes.support,
      key: contentKey,
      version: schemaVersion,
    );
    return json is Map ? SupportContentModel.fromJson(asMap(json)) : null;
  }

  @override
  Future<void> writeSupport(SupportContentModel content) => _cache.write(
    box: CacheBoxes.support,
    key: contentKey,
    version: schemaVersion,
    json: content.toJson(),
  );
}
