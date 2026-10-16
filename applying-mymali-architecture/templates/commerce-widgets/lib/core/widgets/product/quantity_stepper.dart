import 'dart:math' as math;

import 'package:flutter/material.dart';

/// "− n +" control for a line quantity. [onDecrement] at quantity 1 is
/// the caller's chance to remove the line. A null [onIncrement] or
/// [onDecrement] greys that button out, e.g. "+" once the line holds all
/// the stock there is.
///
/// [filled] draws it as a brand-coloured pill. [removeAtOne] swaps the
/// "−" for a bin at quantity 1, to say that the next tap removes the line.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.incrementKey,
    this.decrementKey,
    this.height = 40,
    this.buttonWidth = 34,
    this.filled = false,
    this.removeAtOne = false,
    this.caption,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final Key? incrementKey;
  final Key? decrementKey;
  final double height;

  /// Width of each "−" / "+" tap target.
  final double buttonWidth;

  /// Brand-coloured pill instead of the tonal box.
  final bool filled;

  /// Shows a bin instead of "−" when [quantity] is 1.
  final bool removeAtOne;

  /// Small capitals under the quantity, e.g. "IN CART". Null shows the
  /// quantity alone.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final removes = removeAtOne && quantity <= 1;
    final foreground = filled ? colors.onPrimary : colors.secondary;
    final iconSize = math.min(20.0, height * 0.6);

    return Material(
      color: filled ? colors.primary : colors.surfaceContainerHigh,
      shape: filled
          ? const StadiumBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              key: decrementKey,
              width: buttonWidth,
              icon: removes
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              iconSize: iconSize,
              color: foreground,
              onTap: onDecrement,
              semanticLabel: removes ? 'Remove' : 'Decrease quantity',
            ),
            if (filled) _Divider(height: height, color: foreground),
            Container(
              constraints: const BoxConstraints(minWidth: 30),
              alignment: Alignment.center,
              decoration: filled
                  ? null
                  : BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
              padding: filled
                  ? const EdgeInsets.symmetric(horizontal: 6)
                  : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _QuantityLabel(
                quantity: quantity,
                caption: caption,
                color: filled ? colors.onPrimary : colors.onSurface,
              ),
            ),
            if (filled) _Divider(height: height, color: foreground),
            _StepButton(
              key: incrementKey,
              width: buttonWidth,
              icon: Icons.add_rounded,
              iconSize: iconSize,
              color: foreground,
              onTap: onIncrement,
              semanticLabel: 'Increase quantity',
            ),
          ],
        ),
      ),
    );
  }
}

/// Hairline between the parts of a filled stepper.
class _Divider extends StatelessWidget {
  const _Divider({required this.height, required this.color});

  /// Height of the stepper; the line is about half of it.
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height * 0.5,
      color: color.withValues(alpha: 0.3),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.width,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
  });

  final double width;
  final IconData icon;
  final double iconSize;
  final Color color;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      // A disabled button still takes its tap, so the tap never reaches a
      // tappable row behind the stepper (e.g. a cart line opening its
      // product page).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? null : () {},
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Icon(
              icon,
              size: iconSize,
              // A disabled button is greyed out, e.g. "+" at the stock left.
              color: enabled ? color : color.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

/// The quantity, with its optional caption under it.
class _QuantityLabel extends StatelessWidget {
  const _QuantityLabel({
    required this.quantity,
    required this.caption,
    required this.color,
  });

  final int quantity;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = this.caption;
    final number = Text(
      '$quantity',
      style: theme.textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        height: caption == null ? null : 1.1,
      ),
    );
    if (caption == null) return number;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        number,
        Text(
          caption,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
