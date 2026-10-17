import 'package:flutter/material.dart';

import '../app_network_image.dart';

/// Floating "View cart · N items" pill with the first few line thumbnails.
/// Callers show it only when the cart has items.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({
    super.key,
    required this.itemCount,
    required this.onPressed,
    this.thumbnailUrls = const [],
    this.label = 'View cart',
  });

  final int itemCount;
  final VoidCallback? onPressed;

  /// Up to [maxThumbnails] are shown, overlapping.
  final List<String?> thumbnailUrls;
  final String label;

  static const int maxThumbnails = 2;

  /// The pill's height: the thumbnails plus the padding around them.
  static const double height = _thumbSize + 2 * _verticalPadding;

  static const double _thumbSize = 32;
  static const double _thumbOverlap = 12;
  static const double _verticalPadding = 6;
  static const double _arrowSize = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final thumbs = thumbnailUrls.take(maxThumbnails).toList();
    final countLabel = itemCount == 1 ? '1 ITEM' : '$itemCount ITEMS';

    return Semantics(
      button: true,
      label: '$label, $countLabel',
      child: Material(
        color: colors.secondaryContainer,
        shape: const StadiumBorder(),
        elevation: 8,
        shadowColor: colors.shadow.withValues(alpha: 0.5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              _verticalPadding,
              8,
              _verticalPadding,
            ),
            // Only as wide as its content; the caller centres it.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (thumbs.isNotEmpty) ...[
                  SizedBox(
                    width:
                        _thumbSize +
                        (thumbs.length - 1) * (_thumbSize - _thumbOverlap),
                    height: _thumbSize,
                    child: Stack(
                      children: [
                        for (var i = 0; i < thumbs.length; i++)
                          Positioned(
                            left: i * (_thumbSize - _thumbOverlap),
                            child: _Thumb(url: thumbs[i]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else
                  const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  countLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: _arrowSize,
                  height: _arrowSize,
                  decoration: BoxDecoration(
                    color: colors.onSecondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.secondaryContainer,
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: CartSummaryBar._thumbSize,
      height: CartSummaryBar._thumbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.onSecondaryContainer, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: AppNetworkImage(url: url, placeholderIcon: Icons.eco_outlined),
    );
  }
}
