import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Pill-shaped outline button for the lesser of two actions, e.g. "Clear"
/// beside a `PrimaryButton` "Apply". Full width by default; set [expand]
/// to false to make it only as wide as its label.
///
/// A null [onPressed] disables the button; [isLoading] shows progress and
/// blocks taps.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.expand = true,
    this.warm = false,
    this.destructive = false,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  /// Whether the button fills the width it is given.
  final bool expand;

  /// Whether the outline and label are the warm (peach) colour, to sit
  /// beside a warm `PrimaryButton`, instead of the brand colour.
  final bool warm;

  /// Whether the button ends or removes something, e.g. "Sign Out": the
  /// outline and label take the alert colour (`colorScheme.error`) over a
  /// faint tint of it. Wins over [warm].
  final bool destructive;

  /// Plain icon shown before the label.
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null && !isLoading;
    final tone = destructive
        ? colors.error
        : warm
        ? colors.tertiaryContainer
        : colors.primary;
    final foreground = enabled ? tone : tone.withValues(alpha: 0.55);
    final leadingIcon = this.leadingIcon;
    final Widget labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    final Widget text = Padding(
      padding: EdgeInsets.symmetric(horizontal: height / 2),
      child: leadingIcon == null
          ? labelText
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(leadingIcon, size: 20, color: foreground),
                const SizedBox(width: 8),
                Flexible(child: labelText),
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: destructive ? MaterialType.canvas : MaterialType.transparency,
        color: destructive ? tone.withValues(alpha: 0.08) : null,
        shape: StadiumBorder(side: BorderSide(color: foreground, width: 1.4)),
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
                  text
                // A content-width button keeps its width while loading.
                else if (!expand)
                  Visibility.maintain(visible: false, child: text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
