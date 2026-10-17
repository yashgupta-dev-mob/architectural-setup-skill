import 'package:flutter/material.dart';

import '../buttons/circle_icon_button.dart';

/// A search bar that only looks like one: it has no text field. Tapping
/// the bar calls [onTap], e.g. to open a search screen, and tapping the
/// camera calls [onCameraTap].
///
/// Use `AppSearchBar` instead when the user should type in place.
class SearchTriggerBar extends StatelessWidget {
  const SearchTriggerBar({
    super.key,
    required this.onTap,
    this.onCameraTap,
    this.hintText = 'Search',
    this.cameraTooltip = 'Search with a photo',
  });

  /// Called when the bar is tapped. Null shows the bar but ignores taps.
  final VoidCallback? onTap;

  /// Called when the camera button is tapped. The button is hidden when
  /// null.
  final VoidCallback? onCameraTap;

  final String hintText;
  final String cameraTooltip;

  static const double _radius = 28;
  static const double _minHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
    );

    return Material(
      color: colors.surfaceContainerLowest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search_rounded,
                size: 22,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  child: Text(
                    hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (onCameraTap != null)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleIconButton(
                    icon: Icons.photo_camera_outlined,
                    size: 40,
                    accent: true,
                    tooltip: cameraTooltip,
                    onPressed: onCameraTap,
                  ),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
