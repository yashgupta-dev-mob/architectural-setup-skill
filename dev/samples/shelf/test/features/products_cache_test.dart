import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/features/products/product.dart';
import 'package:shelf/features/products/products_cache.dart';
import 'package:shelf/features/products/products_provider.dart';
import 'package:shelf/globals.dart';

final DateTime now = DateTime.utc(2026, 1, 1, 12);

const Product cachedProduct = Product(
  id: 'p1',
  title: 'Cached mug',
  price: 49900,
  thumbnail: 'https://img.example.com/p1.png',
  inStock: true,
);

const Product serverProduct = Product(
  id: 'p2',
  title: 'Fresh plant',
  price: 129900,
  thumbnail: '',
  inStock: false,
);

String cacheJson(DateTime savedAt, List<Product> items) {
  return jsonEncode({
    'saved_at': savedAt.toIso8601String(),
    'items': [for (final item in items) item.toJson()],
  });
}

Future<SharedPreferences> prefsWith(Map<String, Object> values) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

DioException offline() {
  return DioException(
    requestOptions: RequestOptions(path: '/store/products'),
    type: DioExceptionType.connectionError,
    message: 'offline',
  );
}

/// The real notifier with the network call replaced.
class FakeProductsNotifier extends ProductsNotifier {
  Future<List<Product>> Function() remote = () async => const [];
  int calls = 0;

  @override
  Future<List<Product>> fetchRemote() {
    calls++;
    return remote();
  }
}

ProviderContainer makeContainer(
  SharedPreferences prefs,
  FakeProductsNotifier fake,
) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) => prefs),
      clockProvider.overrideWith(
        (ref) =>
            () => now,
      ),
      productsProvider.overrideWith(() => fake),
    ],
  );
  addTearDown(container.dispose);
  container.listen(productsProvider, (_, _) {});
  return container;
}

void main() {
  group('ProductsCache', () {
    test(
      'returns the saved items when saved_at is younger than 10 minutes',
      () async {
        final prefs = await prefsWith({
          ProductsCache.key: cacheJson(
            now.subtract(const Duration(minutes: 9, seconds: 59)),
            [cachedProduct],
          ),
        });

        final items = ProductsCache(prefs, () => now).read();

        expect(items, isNotNull);
        expect(items!.single.id, 'p1');
        expect(items.single.title, 'Cached mug');
        expect(items.single.price, 49900);
        expect(items.single.thumbnail, 'https://img.example.com/p1.png');
        expect(items.single.inStock, isTrue);
        expect(prefs.getString(ProductsCache.key), isNotNull);
      },
    );

    test(
      'ignores and deletes a cache saved 10 minutes ago or earlier',
      () async {
        final prefs = await prefsWith({
          ProductsCache.key: cacheJson(
            now.subtract(const Duration(minutes: 10)),
            [cachedProduct],
          ),
        });

        expect(ProductsCache(prefs, () => now).read(), isNull);
        await pumpEventQueue();
        expect(prefs.getString(ProductsCache.key), isNull);
      },
    );

    test('ignores and deletes a cache it cannot parse', () async {
      final prefs = await prefsWith({ProductsCache.key: 'not json'});

      expect(ProductsCache(prefs, () => now).read(), isNull);
      await pumpEventQueue();
      expect(prefs.getString(ProductsCache.key), isNull);
    });

    test('returns null when nothing is saved', () async {
      final prefs = await prefsWith({});
      expect(ProductsCache(prefs, () => now).read(), isNull);
    });

    test('write saves the clock time as saved_at and the items', () async {
      final prefs = await prefsWith({});

      await ProductsCache(prefs, () => now).write([serverProduct]);

      final saved = jsonDecode(
        prefs.getString(ProductsCache.key)!,
      ) as Map<String, dynamic>;
      expect(saved['saved_at'], '2026-01-01T12:00:00.000Z');
      expect(saved['items'], [serverProduct.toJson()]);
    });
  });

  group('ProductsNotifier', () {
    test('shows a fresh cache at once, then the server list, and rewrites '
        'the cache', () async {
      final prefs = await prefsWith({
        ProductsCache.key: cacheJson(now.subtract(const Duration(minutes: 5)), [
          cachedProduct,
        ]),
      });
      final fake = FakeProductsNotifier()..remote = () async => [serverProduct];
      final container = makeContainer(prefs, fake);

      final first = container.read(productsProvider);
      expect(first.items.map((p) => p.id), ['p1']);
      expect(first.hasData, isTrue);
      expect(first.fromCache, isTrue);

      await container.read(productsProvider.notifier).refresh();

      final after = container.read(productsProvider);
      expect(after.items.map((p) => p.id), ['p2']);
      expect(after.fromCache, isFalse);
      expect(after.isLoading, isFalse);
      expect(after.refreshFailures, 0);
      expect(fake.calls, 1);
      final saved = jsonDecode(
        prefs.getString(ProductsCache.key)!,
      ) as Map<String, dynamic>;
      expect(saved['saved_at'], '2026-01-01T12:00:00.000Z');
      expect((saved['items'] as List<dynamic>).single, serverProduct.toJson());
    });

    test('keeps the cached items and counts the failure when the refresh '
        'fails', () async {
      final original = cacheJson(now.subtract(const Duration(minutes: 5)), [
        cachedProduct,
      ]);
      final prefs = await prefsWith({ProductsCache.key: original});
      final fake = FakeProductsNotifier()
        ..remote = () => Future.error(offline());
      final container = makeContainer(prefs, fake);

      await container.read(productsProvider.notifier).refresh();

      final state = container.read(productsProvider);
      expect(state.items.map((p) => p.id), ['p1']);
      expect(state.hasData, isTrue);
      expect(state.fromCache, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.loadFailed, isFalse);
      expect(state.refreshFailures, 1);
      expect(prefs.getString(ProductsCache.key), original);
    });

    test('treats a stale cache as a miss: loading, then an error, then '
        'Try again', () async {
      final prefs = await prefsWith({
        ProductsCache.key: cacheJson(
          now.subtract(const Duration(minutes: 11)),
          [cachedProduct],
        ),
      });
      final fake = FakeProductsNotifier()
        ..remote = () => Future.error(offline());
      final container = makeContainer(prefs, fake);

      final first = container.read(productsProvider);
      expect(first.items, isEmpty);
      expect(first.hasData, isFalse);
      expect(first.isLoading, isTrue);

      await container.read(productsProvider.notifier).refresh();

      final failed = container.read(productsProvider);
      expect(failed.hasData, isFalse);
      expect(failed.isLoading, isFalse);
      expect(failed.loadFailed, isTrue);
      expect(failed.refreshFailures, 0);
      expect(prefs.getString(ProductsCache.key), isNull);

      fake.remote = () async => [serverProduct];
      await container.read(productsProvider.notifier).refresh();

      final loaded = container.read(productsProvider);
      expect(loaded.hasData, isTrue);
      expect(loaded.loadFailed, isFalse);
      expect(loaded.items.single.id, 'p2');
      expect(fake.calls, 2);
    });
  });
}
