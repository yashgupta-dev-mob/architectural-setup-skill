import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favourites_provider.dart';

/// The heart that toggles a product in and out of the favourites.
class FavouriteButton extends ConsumerWidget {
  const FavouriteButton({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavourite = ref.watch(
      favouritesProvider.select((state) => state.contains(productId)),
    );
    return IconButton(
      tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
      icon: Icon(
        isFavourite ? Icons.favorite : Icons.favorite_border,
        color: isFavourite ? const Color(0xFFE53935) : null,
      ),
      onPressed: () => ref.read(favouritesProvider.notifier).toggle(productId),
    );
  }
}
