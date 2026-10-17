import 'package:flutter/material.dart';

/// Pill-shaped filter trigger, e.g. "Sort ▾". With no [label] it renders
/// as an icon-only pill.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    this.label,
    this.icon,
    this.showDropdownArrow = true,
    this.selected = false,
    this.fillWhenSelected = false,
    this.onHeader = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final bool showDropdownArrow;

  /// Highlights the border, e.g. when a filter other than the default is
  /// active.
  final bool selected;

  /// Whether [selected] also tints the pill, for a chip that is itself the
  /// choice (e.g. "Full Sun" in a filter sheet) rather than a trigger.
  final bool fillWhenSelected;

  /// For a chip on a tinted `PageHeader` (the My Orders tabs): see-through
  /// on the header's colour, and filled with the header's text colour
  /// when [selected]. It replaces the [fillWhenSelected] look.
  final bool onHeader;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    final onTint = colors.onPrimaryContainer;
    final Color base = onHeader
        ? (selected ? colors.primaryContainer : onTint.withValues(alpha: 0.85))
        : colors.onSurface;
    final foreground = enabled ? base : base.withValues(alpha: 0.4);
    final Color fill;
    final Color border;
    if (onHeader) {
      fill = selected ? onTint : onTint.withValues(alpha: 0.12);
      border = selected ? onTint : onTint.withValues(alpha: 0.22);
    } else {
      fill = selected && fillWhenSelected
          ? colors.primaryContainer
          : colors.surfaceContainerHigh;
      border = selected ? colors.primary : colors.outlineVariant;
    }

    return Material(
      color: fill,
      shape: StadiumBorder(
        side: BorderSide(color: border, width: selected && !onHeader ? 1.4 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 12 : 14,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: foreground),
              if (icon != null && label != null) const SizedBox(width: 6),
              if (label != null)
                Text(
                  label!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: onHeader && selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              if (label != null && showDropdownArrow) ...[
                const SizedBox(width: 2),
                Icon(Icons.expand_more_rounded, size: 18, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
