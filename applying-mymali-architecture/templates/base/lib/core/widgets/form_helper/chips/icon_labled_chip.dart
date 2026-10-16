import 'package:flutter/material.dart';

class IconLabledChip extends StatelessWidget {
  final String label;
  final Icon icon;

  /// Defaults to the theme's `primaryContainer`.
  final Color? color;

  /// Defaults to the theme's `onSurface`.
  final Color? textColor;

  const IconLabledChip({
    super.key,
    required this.label,
    required this.icon,
    this.textColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedTextColor = textColor ?? colors.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resolvedTextColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: resolvedTextColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
