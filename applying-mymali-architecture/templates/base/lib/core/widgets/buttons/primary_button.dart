import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Pill-shaped call-to-action button in the brand style. Full width by
/// default; set [expand] to false to make it only as wide as its label.
///
/// Pass [icon] to show it in an accent-coloured badge at the trailing
/// edge, or [leadingIcon] to show a plain icon before the label. A null
/// [onPressed] disables the button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leadingIcon,
    this.isLoading = false,
    this.height = 56,
    this.expand = true,
    this.warm = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Plain icon shown before the label.
  final IconData? leadingIcon;
  final bool isLoading;
  final double height;

  /// Whether the button fills the width it is given.
  final bool expand;

  /// Whether the button is the warm (peach) one that confirms a choice in
  /// a sheet, e.g. "Apply", instead of the brand colour.
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;
    final fill = warm ? colors.tertiaryContainer : colors.primary;
    final foreground = warm ? colors.onTertiaryContainer : colors.onPrimary;
    final background = enabled ? fill : fill.withValues(alpha: 0.55);

    final Widget text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: foreground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
    final Widget content = Padding(
      // A full-width button keeps its label clear of the trailing badge.
      padding: EdgeInsets.symmetric(horizontal: expand ? height : height / 2),
      child: leadingIcon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(leadingIcon, size: 20, color: foreground),
                const SizedBox(width: 8),
                Flexible(child: text),
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            width: expand ? double.infinity : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: foreground,
                    size: 28,
                  ),
                if (!isLoading)
                  content
                // A content-width button keeps its width while loading.
                else if (!expand)
                  Visibility.maintain(visible: false, child: content),
                if (icon != null && !isLoading)
                  Positioned(
                    right: 6,
                    child: Container(
                      width: height - 12,
                      height: height - 12,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: colors.onSecondaryContainer,
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
