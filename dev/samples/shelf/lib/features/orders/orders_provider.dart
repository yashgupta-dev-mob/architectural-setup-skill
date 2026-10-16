import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../net/client.dart';
import 'order.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.nextPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.loadedOnce = false,
    this.failures = 0,
  });

  final List<Order> orders;

  /// The page the next `loadMore` asks for.
  final int nextPage;

  /// The last page was full, so there may be another.
  final bool hasMore;

  /// A `GET /me/orders` is in flight.
  final bool isLoading;

  /// At least one page has been received since the last reload.
  final bool loadedOnce;

  /// How many requests failed. Each increment shows the
  /// "Could not load orders" SnackBar.
  final int failures;

  OrdersState copyWith({
    List<Order>? orders,
    int? nextPage,
    bool? hasMore,
    bool? isLoading,
    bool? loadedOnce,
    int? failures,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      nextPage: nextPage ?? this.nextPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      failures: failures ?? this.failures,
    );
  }
}

/// Network-only, paginated orders. Nothing is cached.
class OrdersNotifier extends Notifier<OrdersState> {
  static const int pageSize = 20;

  bool _busy = false;

  @override
  OrdersState build() => const OrdersState(isLoading: true);

  /// Drops the list and loads page 1 again.
  Future<void> reload() => _load(reset: true);

  /// Appends the next page.
  Future<void> loadMore() => _load(reset: false);

  Future<void> _load({required bool reset}) async {
    if (_busy) return;
    _busy = true;
    final base = reset ? OrdersState(failures: state.failures) : state;
    final page = base.nextPage;
    state = base.copyWith(isLoading: true);
    try {
      final orders = await fetchPage(page);
      state = OrdersState(
        orders: [...base.orders, ...orders],
        nextPage: page + 1,
        hasMore: orders.length >= pageSize,
        loadedOnce: true,
        failures: state.failures,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, failures: state.failures + 1);
    } finally {
      _busy = false;
    }
  }

  /// One page of orders. A 404 is an empty page.
  @protected
  Future<List<Order>> fetchPage(int page) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/me/orders',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      final list = response.data!['orders'] as List<dynamic>;
      return [
        for (final item in list) Order.fromJson(item as Map<String, dynamic>),
      ];
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(
  OrdersNotifier.new,
);
