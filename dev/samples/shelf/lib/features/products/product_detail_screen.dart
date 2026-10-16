import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/money.dart';
import '../../vendor/tracker.dart';
import '../favourites/favourite_button.dart';
import 'product.dart';
import 'product_thumbnail.dart';
import 'products_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    ThirdPartyTracker.screen('ProductDetail');
  }

  void _buy(Product product) {
    ThirdPartyTracker.track('buy_tapped', {
      'product_id': product.id,
      'price': product.price,
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Order placed')));
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final product = products.byId(widget.productId);
    if (product != null && !_viewTracked) {
      _viewTracked = true;
      ThirdPartyTracker.track('product_viewed', {
        'product_id': product.id,
        'price': product.price,
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.title ?? 'Product'),
        actions: [if (product != null) FavouriteButton(productId: product.id)],
      ),
      body: product == null ? _missing(products) : _details(product),
    );
  }

  Widget _missing(ProductsState products) {
    if (!products.hasData && products.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return const Center(child: Text('Product not found'));
  }

  Widget _details(Product product) {
    final textTheme = Theme.of(context).textTheme;
    final stockColor = product.inStock
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB3261E);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: ProductThumbnail(url: product.thumbnail, size: 220)),
        const SizedBox(height: 16),
        Text(product.title, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          formatPaise(product.price),
          style: textTheme.titleLarge?.copyWith(
            color: const Color(0xFF6750A4),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text(
              product.inStock ? 'In stock' : 'Out of stock',
              style: TextStyle(color: stockColor),
            ),
            backgroundColor: product.inStock
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFDECEA),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: product.inStock ? () => _buy(product) : null,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Buy'),
        ),
      ],
    );
  }
}
