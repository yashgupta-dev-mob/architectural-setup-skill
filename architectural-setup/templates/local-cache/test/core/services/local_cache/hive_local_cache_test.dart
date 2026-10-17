// GENERIC: the source app's test over a box of its own.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:template_app/core/app/exceptions/cache_exceptions.dart';
import 'package:template_app/core/services/local_cache/hive_local_cache.dart';

void main() {
  // A box of the test's own: the app's CacheBoxes may still be empty.
  const box = 'test_box';
  const key = 'snapshot';

  late Directory directory;
  late DateTime now;
  late HiveLocalCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('local_cache_test');
    Hive.init(directory.path);
    await HiveLocalCache.openBoxes();
    await Hive.openBox<String>(box);
    now = DateTime.utc(2026, 10, 1, 12);
    cache = HiveLocalCache(now: () => now);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<Object?> read({int version = 1, Duration? maxAge}) =>
      cache.read(box: box, key: key, version: version, maxAge: maxAge);

  Future<void> write(Object json, {int version = 1}) =>
      cache.write(box: box, key: key, version: version, json: json);

  test('reads miss when nothing is saved', () async {
    expect(await read(), isNull);
  });

  test('a saved map reads back the same', () async {
    final json = {
      'region_id': 'reg_01',
      'count': 2,
      'products': [
        {'id': 'prod_01', 'price': 269.5, 'tags': null},
      ],
    };

    await write(json);

    expect(await read(), json);
    expect(await read(), isA<Map<String, dynamic>>());
  });

  test('a saved list reads back the same', () async {
    await write([
      {'sku': 'MM-NEEM-250', 'sold_count': 12},
    ]);

    expect(await read(), [
      {'sku': 'MM-NEEM-250', 'sold_count': 12},
    ]);
  });

  test('an entry survives closing and reopening the box', () async {
    await write({'count': 1});

    await Hive.close();
    Hive.init(directory.path);
    await HiveLocalCache.openBoxes();
    await Hive.openBox<String>(box);

    expect(await read(), {'count': 1});
  });

  test('another schema version misses and deletes the entry', () async {
    await write({'count': 1});

    expect(await read(version: 2), isNull);
    // Gone for the old version too.
    expect(await read(), isNull);
  });

  test('an entry older than maxAge misses but is kept', () async {
    await write({'count': 1});
    now = now.add(const Duration(hours: 2));

    expect(await read(maxAge: const Duration(hours: 1)), isNull);
    expect(await read(maxAge: const Duration(hours: 3)), {'count': 1});
    expect(await read(), {'count': 1});
  });

  test('a corrupt entry misses and is deleted', () async {
    final raw = Hive.box<String>(box);
    for (final corrupt in [
      'not json',
      '[1, 2]',
      '{"version": 1, "data": {"count": 1}}',
      '{"version": 1, "saved_at": "2026-10-01T12:00:00Z"}',
    ]) {
      await raw.put(key, corrupt);

      expect(await read(), isNull, reason: corrupt);
      expect(raw.containsKey(key), isFalse, reason: corrupt);
    }
  });

  test('delete removes one entry, clearBox all of them', () async {
    await write({'count': 1});
    await cache.write(box: box, key: 'other', version: 1, json: [1]);

    await cache.delete(box: box, key: key);
    expect(await read(), isNull);
    expect(await cache.read(box: box, key: 'other', version: 1), [1]);

    await cache.clearBox(box);
    expect(await cache.read(box: box, key: 'other', version: 1), isNull);
  });

  test('a value that is not JSON fails the write', () async {
    expect(write(DateTime(2026)), throwsA(isA<CacheException>()));
  });

  test('a box that is not open misses on read and fails on write', () async {
    await Hive.close();

    expect(await read(), isNull);
    await expectLater(write({'count': 1}), throwsA(isA<CacheException>()));
    // Clearing has nothing to do, so it does not fail.
    await cache.clearBox(box);
    await cache.clearUserScoped();
  });
}
