import 'package:flutter/material.dart';

import 'product_card.dart';

const int _columns = 2;

SliverGridDelegate _delegate(BuildContext context, double width) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: _columns,
    mainAxisSpacing: ProductGrid.spacing,
    crossAxisSpacing: ProductGrid.spacing,
    mainAxisExtent: ProductGrid.tileHeightFor(context, width),
  );
}

/// Two-column grid of [ProductCard]s that sizes itself to its content,
/// for use inside a scroll view.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Gap between tiles.
  static const double spacing = 14;

  /// Width of one tile in a grid laid out [width] wide.
  static double tileWidthFor(double width) =>
      (width - spacing * (_columns - 1)) / _columns;

  /// Height of that tile: a square image plus the details block.
  static double tileHeightFor(BuildContext context, double width) =>
      tileWidthFor(width) + ProductCard.detailsHeightFor(context);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: _delegate(context, constraints.maxWidth),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Sliver version of [ProductGrid], for a `CustomScrollView`.
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        gridDelegate: _delegate(context, constraints.crossAxisExtent),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
