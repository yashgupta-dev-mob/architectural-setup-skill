import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/money.dart';
import '../../vendor/tracker.dart';
import '../products/product.dart';
import '../products/product_thumbnail.dart';
import '../products/products_provider.dart';
import 'favourite_button.dart';
import 'favourites_provider.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key, this.standalone = false});

  /// True when shown by the `/favourites` route rather than as a Home tab.
  final bool standalone;

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  @override
  void initState() {
    super.initState();
    ThirdPartyTracker.screen('Favourites');
  }

  @override
  Widget build(BuildContext context) {
    final favourites = ref.watch(favouritesProvider);
    final products = ref.watch(productsProvider);
    final items = <Product>[];
    for (final id in favourites.ids) {
      final product = products.byId(id);
      if (product != null) items.add(product);
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.standalone
            ? BackButton(onPressed: () => context.go('/'))
            : null,
        title: const Text('Favourites'),
      ),
      body: favourites.ids.isEmpty
          ? const Center(child: Text('No favourites yet'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                return ListTile(
                  leading: ProductThumbnail(url: product.thumbnail, size: 48),
                  title: Text(product.title),
                  subtitle: Text(formatPaise(product.price)),
                  trailing: FavouriteButton(productId: product.id),
                  onTap: () => context.push('/products/${product.id}'),
                );
              },
            ),
    );
  }
}
