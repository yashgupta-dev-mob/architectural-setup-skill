import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/currency_format.dart';
import '../app_network_image.dart';
import '../buttons/add_button.dart';
import '../buttons/heart_toggle_button.dart';
import '../chips/info_chip.dart';
import 'quantity_stepper.dart';

/// A product tile for grids: image with badges, title, variant and stock
/// chips, price, and either an "ADD +" button or a quantity stepper.
///
/// Takes plain values so it stays feature-agnostic. [testId] seeds the
/// keys of its interactive parts: `product_<testId>_add`,
/// `product_<testId>_increment`, `product_<testId>_decrement`,
/// `product_<testId>_wishlist`.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.testId,
    required this.title,
    required this.price,
    this.subtitle,
    this.imageUrl,
    this.mrp,
    this.discountPercent = 0,
    this.soldCount,
    this.variantLabel,
    this.inStock = true,
    this.isLowStock = false,
    this.isComingSoon = false,
    this.isWishlisted = false,
    this.quantity = 0,
    this.onTap,
    this.onAdd,
    this.onIncrement,
    this.onDecrement,
    this.onWishlistPressed,
  });

  final String testId;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  /// Selling price in rupees.
  final double price;

  /// Struck-through "MRP" price, shown only when above [price].
  final double? mrp;
  final int discountPercent;
  final int? soldCount;
  final String? variantLabel;
  final bool inStock;
  final bool isLowStock;

  /// Browsable but not buyable: no add control.
  final bool isComingSoon;
  final bool isWishlisted;

  /// Units already in the cart; above zero shows the stepper.
  final int quantity;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onWishlistPressed;

  /// Height the card needs below its square image: the details block at
  /// its fullest (subtitle, variant chip, stock chip, price with MRP), in
  /// the current theme and text scale. It mirrors the layout in [build],
  /// so keep the two in step.
  static double detailsHeightFor(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle? style) =>
        scaler.scale(style?.fontSize ?? 14) * (style?.height ?? 1.3);

    final chip = InfoChip.heightFor(context);
    final priceRow = math.max(
      line(text.titleLarge) + line(text.bodySmall),
      _controlHeight,
    );
    return 2 * _padding +
        line(text.titleMedium) +
        line(text.bodySmall) +
        _variantGap +
        chip +
        _gap +
        chip +
        _gap +
        priceRow +
        _slack;
  }

  /// Below this tile width the add control and stepper get tighter.
  static const double compactWidth = 160;

  /// Padding of the details block.
  static const double _padding = 12;
  static const double _variantGap = 8;
  static const double _gap = 6;

  /// Height of the quantity stepper on a regular tile.
  static const double _controlHeight = 40;

  /// Spare room for rounding, so the block never overflows by a pixel.
  static const double _slack = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mrp = this.mrp;
    final showMrp = mrp != null && mrp > price;

    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: imageUrl),
                  if (onWishlistPressed != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: HeartToggleButton(
                        key: Key('product_${testId}_wishlist'),
                        isActive: isWishlisted,
                        onPressed: onWishlistPressed,
                      ),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: _ImageBadges(
                      discountPercent: discountPercent,
                      soldCount: soldCount,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (variantLabel != null && variantLabel!.isNotEmpty)
                      const SizedBox(height: _variantGap),
                    if (variantLabel != null && variantLabel!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InfoChip(label: variantLabel!),
                      ),
                    const SizedBox(height: _gap),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _StockChip(
                        inStock: inStock,
                        isLowStock: isLowStock,
                        isComingSoon: isComingSoon,
                      ),
                    ),
                    // const Spacer(),
                    const SizedBox(height: _gap),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact =
                            constraints.maxWidth < compactWidth - 2 * _padding;
                        final Widget? control = isComingSoon
                            ? null
                            : quantity > 0
                            ? QuantityStepper(
                                quantity: quantity,
                                incrementKey: Key(
                                  'product_${testId}_increment',
                                ),
                                decrementKey: Key(
                                  'product_${testId}_decrement',
                                ),
                                onIncrement: onIncrement,
                                onDecrement: onDecrement,
                                height: compact ? 36 : _controlHeight,
                                buttonWidth: compact ? 28 : 34,
                              )
                            : AddButton(
                                key: Key('product_${testId}_add'),
                                compact: compact,
                                onPressed: inStock ? onAdd : null,
                              );

                        // Price and control always share a row; on a narrow
                        // tile the price scales down rather than wrapping.
                        return Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _PriceBlock(
                                  price: price,
                                  mrp: showMrp ? mrp : null,
                                ),
                              ),
                            ),
                            if (control != null) ...[
                              const SizedBox(width: 6),
                              control,
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The discount badge on the left and the sold badge on the right of the
/// image's foot. When both don't fit, the row scales down as one, so
/// neither label is cut off.
class _ImageBadges extends StatelessWidget {
  const _ImageBadges({required this.discountPercent, required this.soldCount});

  final int discountPercent;
  final int? soldCount;

  @override
  Widget build(BuildContext context) {
    final soldCount = this.soldCount;
    final showDiscount = discountPercent > 0;
    final showSold = soldCount != null && soldCount > 0;
    if (!showDiscount && !showSold) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        // At least the full width, so spaceBetween pushes the sold badge
        // right; wider only when the badges need it, then scaled down.
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showDiscount)
                InfoChip(
                  label: '$discountPercent% OFF',
                  tone: InfoChipTone.highlight,
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 6),
              if (showSold)
                InfoChip(
                  label: '$soldCount sold',
                  icon: Icons.shopping_bag_outlined,
                  tone: InfoChipTone.dark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.price, required this.mrp});

  final double price;

  /// Shown struck through when not null.
  final double? mrp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatRupees(price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (mrp != null)
          Text(
            'MRP ${formatRupees(mrp!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({
    required this.inStock,
    required this.isLowStock,
    required this.isComingSoon,
  });

  final bool inStock;
  final bool isLowStock;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    if (isComingSoon) {
      return const InfoChip(label: 'Coming soon', tone: InfoChipTone.highlight);
    }
    if (!inStock) {
      return const InfoChip(label: 'Out of stock', tone: InfoChipTone.dark);
    }
    if (isLowStock) {
      return const InfoChip(label: 'Few left', tone: InfoChipTone.highlight);
    }
    return const InfoChip(label: 'In Stock', tone: InfoChipTone.accent);
  }
}
