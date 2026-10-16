import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/money.dart';
import '../favourites/favourite_button.dart';
import 'product.dart';
import 'product_thumbnail.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ProductThumbnail(url: product.thumbnail, size: 56),
        title: Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              formatPaise(product.price),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              product.inStock ? 'In stock' : 'Out of stock',
              style: TextStyle(
                fontSize: 12,
                color: product.inStock
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFB3261E),
              ),
            ),
          ],
        ),
        trailing: FavouriteButton(productId: product.id),
        onTap: () => context.push('/products/${product.id}'),
      ),
    );
  }
}
