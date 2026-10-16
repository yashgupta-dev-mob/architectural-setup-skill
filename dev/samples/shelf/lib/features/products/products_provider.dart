import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../globals.dart';
import '../../net/client.dart';
import 'product.dart';
import 'products_cache.dart';

class ProductsState {
  const ProductsState({
    this.items = const [],
    this.hasData = false,
    this.fromCache = false,
    this.isLoading = false,
    this.loadFailed = false,
    this.refreshFailures = 0,
  });

  final List<Product> items;

  /// A list (cached or fresh) is available to show.
  final bool hasData;

  /// The list shown came from the cache and has not been replaced yet.
  final bool fromCache;

  /// A `GET /store/products` is in flight.
  final bool isLoading;

  /// The request failed while there was nothing to show.
  final bool loadFailed;

  /// How many refreshes failed while a list was on screen. Each increment
  /// shows the "Couldn't refresh products" SnackBar.
  final int refreshFailures;

  Product? byId(String id) {
    for (final product in items) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductsState copyWith({
    List<Product>? items,
    bool? hasData,
    bool? fromCache,
    bool? isLoading,
    bool? loadFailed,
    int? refreshFailures,
  }) {
    return ProductsState(
      items: items ?? this.items,
      hasData: hasData ?? this.hasData,
      fromCache: fromCache ?? this.fromCache,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      refreshFailures: refreshFailures ?? this.refreshFailures,
    );
  }
}

/// Cache-first product list: the saved copy first, then the server.
class ProductsNotifier extends Notifier<ProductsState> {
  Future<void>? _inFlight;

  ProductsCache get _cache => ProductsCache(
    ref.read(sharedPreferencesProvider),
    ref.read(clockProvider),
  );

  @override
  ProductsState build() {
    final cached = _cache.read();
    Future<void>.microtask(refresh);
    if (cached == null) return const ProductsState(isLoading: true);
    return ProductsState(items: cached, hasData: true, fromCache: true);
  }

  /// Fetches the list from the server. Calls made while a fetch is in
  /// flight share it.
  Future<void> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<void> _refresh() async {
    state = state.copyWith(isLoading: true, loadFailed: false);
    final List<Product> items;
    try {
      items = await fetchRemote();
    } catch (_) {
      if (state.hasData) {
        state = state.copyWith(
          isLoading: false,
          refreshFailures: state.refreshFailures + 1,
        );
      } else {
        state = state.copyWith(isLoading: false, loadFailed: true);
      }
      return;
    }
    try {
      await _cache.write(items);
    } catch (_) {
      // A failed cache write never fails the refresh.
    }
    state = ProductsState(
      items: items,
      hasData: true,
      refreshFailures: state.refreshFailures,
    );
  }

  @protected
  Future<List<Product>> fetchRemote() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/store/products',
      queryParameters: {'limit': 100},
    );
    final list = response.data!['products'] as List<dynamic>;
    return [
      for (final item in list) Product.fromJson(item as Map<String, dynamic>),
    ];
  }
}

final productsProvider = NotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);
