import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../vendor/tracker.dart';
import '../auth/auth_provider.dart';
import 'product_card.dart';
import 'products_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    ThirdPartyTracker.screen('Products');
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProductsState>(productsProvider, (previous, next) {
      if (next.refreshFailures > (previous?.refreshFailures ?? 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't refresh products")),
        );
      }
    });
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _body(products),
    );
  }

  Widget _body(ProductsState products) {
    if (!products.hasData && products.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!products.hasData && products.loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Couldn't load products"),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(productsProvider.notifier).refresh(),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (products.items.isEmpty) {
      return const Center(child: Text('No products'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: products.items.length,
        itemBuilder: (context, index) =>
            ProductCard(product: products.items[index]),
      ),
    );
  }
}
