import 'package:flutter/material.dart';

/// The small brand-coloured "ADD +" button that puts a product in the cart
/// before it has a quantity: on a `ProductCard` and next to the product
/// page's price. Once the line is in the cart, a `QuantityStepper` takes
/// its place. A null [onPressed] disables it.
class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.onPressed,
    this.label = 'ADD',
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final String label;

  /// Tighter padding for narrow tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;

    return Material(
      color: enabled ? colors.primary : colors.primary.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(width: compact ? 2 : 4),
              Icon(
                Icons.add_rounded,
                size: compact ? 16 : 18,
                color: colors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
