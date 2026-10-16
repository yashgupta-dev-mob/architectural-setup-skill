import 'package:flutter/material.dart';

/// Round icon button. Tonal by default; [filled] makes it brand-coloured,
/// [accent] makes it lime. A null [onPressed] disables it, and
/// [isLoading] shows progress and blocks taps.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 34,
    this.filled = false,
    this.accent = false,
    this.isLoading = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool filled;
  final bool accent;
  final bool isLoading;

  /// Shown as a badge when greater than zero.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;

    final Color background = accent
        ? colors.secondaryContainer
        : filled
        ? colors.primary
        : colors.onSurface.withValues(alpha: 0.08);
    final Color foreground = accent
        ? colors.onSecondaryContainer
        : filled
        ? colors.onPrimary
        : colors.onSurface;

    Widget button = Material(
      color: enabled ? background : background.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : Icon(
                    icon,
                    size: size * 0.5,
                    color: enabled
                        ? foreground
                        : foreground.withValues(alpha: 0.6),
                  ),
          ),
        ),
      ),
    );

    if (badgeCount > 0) {
      button = Badge(
        label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
        child: button,
      );
    }

    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: button,
    );
  }
}
