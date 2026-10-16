// GENERIC: doc example made neutral (no MyMali address).
import 'package:flutter/material.dart';

/// How an [IconListTile] frames its icon.
enum IconListTileLeading {
  /// The bare icon.
  plain,

  /// The icon in a tinted, rounded square.
  tile,

  /// The icon in a tinted circle.
  circle,
}

/// A tappable row for a vertical list of choices: an icon, a title, an
/// optional line under it and an optional chevron at the end, e.g. "Use my
/// current location", a search result or a saved address.
///
/// A null [onTap] disables the row; [isLoading] shows progress at the end
/// and blocks taps.
class IconListTile extends StatelessWidget {
  const IconListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.overline,
    this.leading = IconListTileLeading.tile,
    this.showChevron = false,
    this.isLoading = false,
    this.filled = false,
    this.badgeLabel,
    this.dense = false,
  });

  final IconData icon;
  final String title;

  /// Muted line under the title.
  final String? subtitle;

  /// Small muted caption above the title, e.g. "Email" over
  /// "support@example.com" on a help page.
  final String? overline;

  /// Null disables the row.
  final VoidCallback? onTap;
  final IconListTileLeading leading;

  /// Shows a chevron at the end, for a row that opens or starts something.
  final bool showChevron;
  final bool isLoading;

  /// A short word in a lime pill at the end, before the chevron, e.g.
  /// "Soon" on a row whose feature is not open yet.
  final String? badgeLabel;

  /// A shorter row with a smaller icon and text, for a long menu of rows
  /// such as the Account tab's.
  final bool dense;

  /// Draws the row as a rounded card in the brand colour, with light text,
  /// for the one row that leads a form: "Use my current location" on the
  /// address form. Give it margin at the call site.
  final bool filled;

  static const double _frameSize = 44;
  static const double _denseFrameSize = 36;
  static const double _filledRadius = 18;
  static const double _progressSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitle = this.subtitle;
    final overline = this.overline;
    final badgeLabel = this.badgeLabel;
    final enabled = onTap != null && !isLoading;
    final foreground = filled ? colors.onPrimary : colors.onSurface;
    final mutedForeground = filled
        ? colors.onPrimary.withValues(alpha: 0.8)
        : colors.onSurfaceVariant;
    final titleColor = onTap == null
        ? foreground.withValues(alpha: 0.4)
        : foreground;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        type: filled ? MaterialType.canvas : MaterialType.transparency,
        color: filled ? colors.primary : null,
        borderRadius: filled ? BorderRadius.circular(_filledRadius) : null,
        clipBehavior: filled ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: filled
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 14)
                : EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: dense ? 7 : 10,
                  ),
            child: Row(
              children: [
                _leadingIcon(colors),
                SizedBox(width: leading == IconListTileLeading.plain ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overline != null && overline.isNotEmpty) ...[
                        Text(
                          overline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: mutedForeground,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (dense
                                    ? theme.textTheme.bodyLarge
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                                  color: titleColor,
                                  fontWeight: dense
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        SizedBox(height: dense ? 0 : 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (dense
                                      ? theme.textTheme.bodySmall
                                      : theme.textTheme.bodyMedium)
                                  ?.copyWith(color: mutedForeground),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badgeLabel != null && badgeLabel.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (isLoading) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: _progressSize,
                    height: _progressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: filled ? colors.onPrimary : colors.secondary,
                    ),
                  ),
                ] else if (showChevron) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: mutedForeground,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leadingIcon(ColorScheme colors) {
    final tint = filled ? colors.onPrimary : colors.secondary;
    if (leading == IconListTileLeading.plain) {
      return Icon(
        icon,
        size: 24,
        color: filled ? colors.onPrimary : colors.onSurfaceVariant,
      );
    }

    return Container(
      width: dense ? _denseFrameSize : _frameSize,
      height: dense ? _denseFrameSize : _frameSize,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: filled ? 0.16 : 0.12),
        shape: leading == IconListTileLeading.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: leading == IconListTileLeading.circle
            ? null
            : BorderRadius.circular(dense ? 10 : 12),
      ),
      child: Icon(icon, size: dense ? 18 : 22, color: tint),
    );
  }
}
