import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/money.dart';
import '../../vendor/tracker.dart';
import 'order.dart';
import 'orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.standalone = false});

  /// True when shown by the `/orders` route rather than as a Home tab.
  final bool standalone;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    ThirdPartyTracker.screen('Orders');
    Future<void>.microtask(() {
      if (!mounted) return;
      ref.read(ordersProvider.notifier).reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OrdersState>(ordersProvider, (previous, next) {
      if (next.failures > (previous?.failures ?? 0)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not load orders')));
      }
    });
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: widget.standalone
            ? BackButton(onPressed: () => context.go('/'))
            : null,
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).reload(),
          ),
        ],
      ),
      body: _body(orders),
    );
  }

  Widget _body(OrdersState orders) {
    if (!orders.loadedOnce) {
      if (orders.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: OutlinedButton(
          onPressed: () => ref.read(ordersProvider.notifier).reload(),
          child: const Text('Retry'),
        ),
      );
    }
    if (orders.orders.isEmpty) {
      return const Center(child: Text('No orders yet'));
    }
    return ListView.builder(
      itemCount: orders.orders.length + 1,
      itemBuilder: (context, index) {
        if (index == orders.orders.length) return _footer(orders);
        return OrderTile(order: orders.orders[index]);
      },
    );
  }

  Widget _footer(OrdersState orders) {
    if (orders.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!orders.hasMore) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton(
        onPressed: () => ref.read(ordersProvider.notifier).loadMore(),
        child: const Text('Load more'),
      ),
    );
  }
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.receipt_long, color: statusColor(order.status)),
      title: Text('Order #${order.id}'),
      subtitle: Text('${order.status} · ${formatOrderDate(order.createdAt)}'),
      trailing: Text(
        formatPaise(order.total),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// delivered → green, cancelled → red, anything else → orange.
Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
      return const Color(0xFF2E7D32);
    case 'cancelled':
      return const Color(0xFFB3261E);
    default:
      return const Color(0xFFEF6C00);
  }
}

/// `dd/MM/yyyy` in the device's local time zone.
String formatOrderDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
