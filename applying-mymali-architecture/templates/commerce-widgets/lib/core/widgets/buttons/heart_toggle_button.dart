import 'package:flutter/material.dart';

/// Round heart button that toggles a "saved" state: an outlined heart when
/// off, a filled one in the error colour when on.
///
/// By default it sits on a dark scrim, for use over a photo. Set
/// [overImage] to false on a plain surface: it then gets a soft tint. A
/// null [onPressed] disables it, and [isLoading] shows progress and blocks
/// taps.
class HeartToggleButton extends StatelessWidget {
  const HeartToggleButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.size = 34,
    this.overImage = true,
    this.isLoading = false,
    this.tooltip,
  });

  /// Whether the heart is filled.
  final bool isActive;
  final VoidCallback? onPressed;
  final double size;

  /// Whether the button is drawn over a photo.
  final bool overImage;
  final bool isLoading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;

    final Color background = overImage
        ? colors.inverseSurface.withValues(alpha: 0.55)
        : isActive
        ? colors.error.withValues(alpha: 0.18)
        : colors.onSurface.withValues(alpha: 0.08);
    final Color foreground = isActive
        ? colors.error
        : overImage
        ? colors.onInverseSurface
        : colors.onSurfaceVariant;

    Widget button = Material(
      color: enabled
          ? background
          : background.withValues(alpha: 0.5 * background.a),
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
                    isActive
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: size * 0.53,
                    color: enabled
                        ? foreground
                        : foreground.withValues(alpha: 0.6),
                  ),
          ),
        ),
      ),
    );

    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: isActive,
      label: tooltip,
      child: button,
    );
  }
}
