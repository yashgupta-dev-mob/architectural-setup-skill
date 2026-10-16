import 'package:flutter/material.dart';

import 'product_grid.dart';

/// One row of product tiles that scrolls sideways. Each tile is the size
/// of a [ProductGrid] tile, so two show at once with the next peeking in.
/// [trailing], when given, is a narrower last tile, e.g. an
/// `ExploreMoreCard`.
class ProductRail extends StatelessWidget {
  const ProductRail({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.trailing,
    this.horizontalPadding = 16,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? trailing;

  /// Space before the first tile and after the last. The rail itself
  /// should span the full width, so tiles scroll off the screen edge.
  final double horizontalPadding;

  /// Width of [trailing] as a share of a product tile's.
  static const double trailingWidthFactor = 0.86;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - 2 * horizontalPadding;
        final tileWidth = ProductGrid.tileWidthFor(gridWidth);

        return SizedBox(
          height: ProductGrid.tileHeightFor(context, gridWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: itemCount + (trailing == null ? 0 : 1),
            separatorBuilder: (_, _) =>
                const SizedBox(width: ProductGrid.spacing),
            itemBuilder: (context, index) => index < itemCount
                ? SizedBox(width: tileWidth, child: itemBuilder(context, index))
                : SizedBox(
                    width: tileWidth * trailingWidthFactor,
                    child: trailing,
                  ),
          ),
        );
      },
    );
  }
}
