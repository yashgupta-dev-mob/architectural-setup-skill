// GENERIC: the price format and the stock / discount labels are optional parameters defaulting to MyMali's, so another app can pass its own.
import 'package:flutter/material.dart';

import '../../utils/currency_format.dart';
import '../app_network_image.dart';
import '../buttons/heart_toggle_button.dart';
import '../chips/info_chip.dart';
import 'quantity_stepper.dart';

/// Where a [ProductListTile] puts its add control or stepper.
enum ProductListTileControl {
  /// Under the price, as on the wishlist.
  below,

  /// At the end of the price row, as on a cart line.
  besidePrice,

  /// In a column at the end of the row, beside the title and price, with
  /// the text action under it; as on a "saved for later" row.
  trailing,
}

/// A product row for vertical lists: a square thumbnail with a discount
/// ribbon, then a caption, title, price and either an "Add to cart" pill
/// or a quantity stepper, with a heart in the top-right corner.
///
/// Takes plain values so it stays feature-agnostic. [testId] seeds the
/// keys of its interactive parts: `product_<testId>_add`,
/// `product_<testId>_increment`, `product_<testId>_decrement`,
/// `product_<testId>_wishlist` (or [wishlistKey] when given). [keyPrefix]
/// replaces the leading `product`.
///
/// The same row serves cart lines: see [controlPlacement], [framed],
/// [variantLabel], [priceNote] and [actionLabel].
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.testId,
    required this.title,
    required this.price,
    this.caption,
    this.imageUrl,
    this.mrp,
    this.discountPercent = 0,
    this.inStock = true,
    this.isComingSoon = false,
    this.isWishlisted = false,
    this.quantity = 0,
    this.addLabel = 'Add to cart',
    this.wishlistKey,
    this.onTap,
    this.onLongPress,
    this.onAdd,
    this.onIncrement,
    this.onDecrement,
    this.onWishlistPressed,
    this.keyPrefix = 'product',
    this.imageSize = thumbnailSize,
    this.framed = true,
    this.variantLabel,
    this.priceNote,
    this.controlPlacement = ProductListTileControl.below,
    this.addIcon = Icons.shopping_bag_outlined,
    this.tonalAdd = false,
    this.addKey,
    this.actionLabel,
    this.actionIcon,
    this.actionKey,
    this.onAction,
    this.formatPrice = formatRupees,
    this.outOfStockLabel = 'Out of stock',
    this.comingSoonLabel = 'Coming soon',
    this.discountLabel,
  });

  final String testId;
  final String title;

  /// Small uppercase line above the title, e.g. the category name.
  final String? caption;
  final String? imageUrl;

  /// Selling price, shown through [formatPrice].
  final double price;

  /// Struck-through price, shown only when above [price].
  final double? mrp;
  final int discountPercent;
  final bool inStock;

  /// Browsable but not buyable: no add control.
  final bool isComingSoon;
  final bool isWishlisted;

  /// Units already in the cart; above zero shows the stepper.
  final int quantity;
  final String addLabel;

  /// Replaces the heart's default key.
  final Key? wishlistKey;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  /// Null hides the heart.
  final VoidCallback? onWishlistPressed;

  /// First part of the default keys, e.g. `cart_line` for
  /// `cart_line_<testId>_increment`.
  final String keyPrefix;

  /// Side of the square thumbnail.
  final double imageSize;

  /// Whether the row is a card of its own. Pass false for rows that share
  /// one card: no background or border, and roomier padding.
  final bool framed;

  /// Shown as a chip under the title, e.g. "250 ml".
  final String? variantLabel;

  /// Small muted line above the price, e.g. "$99 × 2".
  final String? priceNote;
  final ProductListTileControl controlPlacement;

  /// Icon of the add pill.
  final IconData addIcon;

  /// Draws the add pill in the soft container colours instead of the brand
  /// colour, for a secondary action such as "Move to cart".
  final bool tonalAdd;

  /// Replaces the add pill's default key.
  final Key? addKey;

  /// A small text action, e.g. "Save for later" or "Remove". Shown under
  /// the price, or under the control when it is
  /// [ProductListTileControl.trailing]. Null hides it.
  final String? actionLabel;
  final IconData? actionIcon;
  final Key? actionKey;
  final VoidCallback? onAction;

  /// Formats [price] and [mrp]; defaults to rupees (`formatRupees`).
  final String Function(num amount) formatPrice;

  /// Shown on the disabled add pill when not [inStock].
  final String outOfStockLabel;

  /// The chip shown in place of the add control when [isComingSoon].
  final String comingSoonLabel;

  /// The discount ribbon's text for a percentage; defaults to "N% OFF".
  final String Function(int percent)? discountLabel;

  /// Default side of the square thumbnail.
  static const double thumbnailSize = 92;

  static const double _padding = 11;
  static const double _unframedPadding = 16;
  static const double _controlHeight = 28;

  /// Most of the row's width a [ProductListTileControl.trailing] control
  /// may take.
  static const double _trailingShare = 0.55;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final caption = this.caption;
    final variantLabel = this.variantLabel;
    final priceNote = this.priceNote;
    final actionLabel = this.actionLabel;
    final mrp = this.mrp;
    final showMrp = mrp != null && mrp > price;

    final Widget control = isComingSoon
        ? InfoChip(label: comingSoonLabel, tone: InfoChipTone.highlight)
        : quantity > 0
        ? QuantityStepper(
            quantity: quantity,
            incrementKey: Key('${keyPrefix}_${testId}_increment'),
            decrementKey: Key('${keyPrefix}_${testId}_decrement'),
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            height: _controlHeight,
            filled: true,
            removeAtOne: true,
          )
        : _AddButton(
            key: addKey ?? Key('${keyPrefix}_${testId}_add'),
            label: inStock ? addLabel : outOfStockLabel,
            icon: addIcon,
            tonal: tonalAdd,
            height: _controlHeight,
            onPressed: inStock ? onAdd : null,
          );
    final Widget? action = actionLabel == null
        ? null
        : _TextAction(
            key: actionKey,
            label: actionLabel,
            icon: actionIcon,
            onPressed: onAction,
          );

    final Widget heading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (caption != null && caption.isNotEmpty) ...[
                Text(
                  caption.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              if (variantLabel != null && variantLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                InfoChip(label: variantLabel),
              ],
            ],
          ),
        ),
        if (onWishlistPressed != null) ...[
          const SizedBox(width: 8),
          HeartToggleButton(
            key: wishlistKey ?? Key('${keyPrefix}_${testId}_wishlist'),
            isActive: isWishlisted,
            overImage: false,
            onPressed: onWishlistPressed,
          ),
        ],
      ],
    );

    final Widget prices = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (priceNote != null && priceNote.isNotEmpty)
          Text(
            priceNote,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        // A price is never cut short: in a tight spot the line scales
        // down instead.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatPrice(price),
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showMrp) ...[
                const SizedBox(width: 8),
                Text(
                  formatPrice(mrp),
                  maxLines: 1,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final trailing = controlPlacement == ProductListTileControl.trailing;
    final List<Widget> details = switch (controlPlacement) {
      ProductListTileControl.below => [
        heading,
        const SizedBox(height: 2),
        prices,
        const SizedBox(height: 6),
        control,
        if (action != null) ...[const SizedBox(height: 4), action],
      ],
      ProductListTileControl.besidePrice => [
        heading,
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: prices),
            const SizedBox(width: 8),
            control,
          ],
        ),
        if (action != null) ...[const SizedBox(height: 4), action],
      ],
      ProductListTileControl.trailing => [
        heading,
        const SizedBox(height: 2),
        prices,
      ],
    };

    return Material(
      type: framed ? MaterialType.canvas : MaterialType.transparency,
      color: framed ? colors.surfaceContainerLow : null,
      shape: framed
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            )
          : null,
      clipBehavior: framed ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: framed
              ? const EdgeInsets.fromLTRB(_padding, _padding, _padding, 13)
              : const EdgeInsets.all(_unframedPadding),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: trailing
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  imageUrl: imageUrl,
                  discountPercent: discountPercent,
                  size: imageSize,
                  discountLabel: discountLabel,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: details,
                  ),
                ),
                if (trailing) ...[
                  const SizedBox(width: 8),
                  // The control never takes the title's room: past this
                  // width its label is cut short instead.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _trailingShare,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        control,
                        if (action != null) ...[
                          const SizedBox(height: 4),
                          action,
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The square image, with the discount ribbon tucked into its top-left
/// corner.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.imageUrl,
    required this.discountPercent,
    required this.size,
    required this.discountLabel,
  });

  final String? imageUrl;
  final int discountPercent;
  final double size;
  final String Function(int percent)? discountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: imageUrl),
            if (discountPercent > 0)
              Align(
                alignment: Alignment.topLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 1, 9, 1),
                    child: Text(
                      discountLabel?.call(discountPercent) ??
                          '$discountPercent% OFF',
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onError,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact "Add to cart" pill. A null [onPressed] disables it.
class _AddButton extends StatelessWidget {
  const _AddButton({
    super.key,
    required this.label,
    required this.icon,
    required this.tonal,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final IconData icon;

  /// Soft container colours instead of the brand colour.
  final bool tonal;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    final background = tonal ? colors.primaryContainer : colors.primary;
    final foreground = tonal ? colors.onPrimaryContainer : colors.onPrimary;

    return Material(
      color: enabled ? background : background.withValues(alpha: 0.45),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small muted text action, e.g. "Save for later". A null [onPressed]
/// disables it.
class _TextAction extends StatelessWidget {
  const _TextAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = this.icon;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        // No side padding, so the label lines up with the text around it.
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
