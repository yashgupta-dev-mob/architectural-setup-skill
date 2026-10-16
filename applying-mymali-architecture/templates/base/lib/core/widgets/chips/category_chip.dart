import 'package:flutter/material.dart';

/// An icon tile with a caption, for category pickers.
///
/// Works as a shortcut in a horizontal strip (leave [selected] false) and
/// as a filter in a vertical rail (set [selected] on the active one). The
/// tile shrinks slightly while pressed, so a tap always gets feedback.
class CategoryChip extends StatefulWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.width = defaultWidth,
  });

  static const double defaultWidth = 80;

  static const double _tileSize = 46;
  static const double _gap = 8;
  static const double _verticalPadding = 6;
  static const int _maxLines = 2;
  static const double _lineHeight = 1.2;

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final double width;

  /// Height of a chip with a two-line label at the current text scale, for
  /// sizing a horizontal strip so labels are never clipped.
  static double heightFor(BuildContext context) {
    final fontSize = _labelStyle(Theme.of(context))?.fontSize ?? 12;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(fontSize) * _lineHeight;
    return (_verticalPadding * 2 + _tileSize + _gap + lineHeight * _maxLines)
        .ceilToDouble();
  }

  static TextStyle? _labelStyle(ThemeData theme) =>
      theme.textTheme.labelMedium?.copyWith(height: _lineHeight);

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _pressed = false;

  static const Duration _duration = Duration(milliseconds: 160);

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = widget.selected;

    final tileColor = selected
        ? colors.primary
        : _pressed
        ? colors.surfaceContainerHighest
        : colors.surfaceContainerHigh;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _setPressed,
        borderRadius: BorderRadius.circular(18),
        // The tile itself reacts to the press, so the press wash stays faint.
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? colors.primary.withValues(alpha: 0.06)
              : null,
        ),
        child: SizedBox(
          width: widget.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: CategoryChip._verticalPadding,
              horizontal: 4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _pressed ? 0.92 : 1,
                  duration: _duration,
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: _duration,
                    width: CategoryChip._tileSize,
                    height: CategoryChip._tileSize,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: selected
                          ? colors.secondaryContainer
                          : colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: CategoryChip._gap),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: CategoryChip._maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: CategoryChip._labelStyle(theme)?.copyWith(
                    color: selected ? colors.secondary : colors.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
