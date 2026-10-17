import 'package:flutter/material.dart';

/// How an [InfoChip] is coloured.
enum InfoChipTone {
  /// Outlined, accent text; e.g. a variant label such as "250 ml".
  outline,

  /// Accent-tinted; e.g. "In Stock".
  accent,

  /// Warm highlight; e.g. "46% OFF".
  highlight,

  /// Dark, translucent; e.g. "16 sold" over an image.
  dark,
}

/// Small rounded label, optionally with a leading icon.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = InfoChipTone.outline,
  });

  final String label;
  final IconData? icon;
  final InfoChipTone tone;

  static const double _verticalPadding = 4;

  /// Height of a chip in the current theme and text scale, border
  /// included. Lets a fixed-height parent reserve room for it.
  static double heightFor(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final textHeight =
        MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 12) *
        (style?.height ?? 1.33);
    return textHeight + 2 * _verticalPadding + 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (Color background, Color foreground, Color? border) = switch (tone) {
      InfoChipTone.outline => (
        colors.secondary.withValues(alpha: 0),
        colors.secondary,
        colors.secondary.withValues(alpha: 0.45),
      ),
      InfoChipTone.accent => (
        colors.secondary.withValues(alpha: 0.14),
        colors.secondary,
        null,
      ),
      InfoChipTone.highlight => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        null,
      ),
      InfoChipTone.dark => (
        colors.inverseSurface.withValues(alpha: 0.78),
        colors.onInverseSurface,
        null,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: _verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
