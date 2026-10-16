import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'buttons/circle_icon_button.dart';

/// The tinted, round-bottomed header of a full page: a back button, a
/// serif title with an optional line under it, and an optional widget at
/// the end (a badge, a count…). It pads itself below the status bar.
///
/// Every page's header is the same height, with or without a subtitle;
/// see [contentHeightFor].
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.subtitleKey,
    this.backKey,
    this.backTooltip = 'Back',
    this.trailing,
    this.bottom,
  });

  final String title;

  /// Null disables the back button.
  final VoidCallback? onBack;

  /// Muted line under the title.
  final String? subtitle;
  final Key? subtitleKey;
  final Key? backKey;
  final String backTooltip;

  /// Shown at the end of the row.
  final Widget? trailing;

  /// Shown under the row, inside the header: e.g. the tabs of My Orders.
  /// The header grows by its height.
  final Widget? bottom;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(16, 2, 16, 8);
  static const double _backButtonSize = 36;
  static const double _subtitleGap = 2;

  /// Height of the header's row in the current theme and text scale: a
  /// title with a subtitle under it. A header without a subtitle keeps
  /// this height and centres its title, so every page's header is equally
  /// tall. It mirrors the layout in [build], so keep the two in step.
  static double contentHeightFor(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    // Rounded up, so it is never less than the text really takes.
    double line(TextStyle? style) =>
        (scaler.scale(style?.fontSize ?? 14) * (style?.height ?? 1.3))
            .ceilToDouble();

    return math.max(
      _backButtonSize,
      line(text.titleLarge) + _subtitleGap + line(text.bodyMedium),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final bottom = this.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: _padding,
          constraints: BoxConstraints(
            minHeight: contentHeightFor(context) + _padding.vertical,
          ),
          child: _withBottom(
            bottom,
            contentHeightFor(context),
            Row(
              children: [
                CircleIconButton(
                  key: backKey,
                  icon: Icons.arrow_back_rounded,
                  tooltip: backTooltip,
                  size: _backButtonSize,
                  onPressed: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: _subtitleGap),
                        Text(
                          subtitle,
                          key: subtitleKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [row] with [bottom] under it, when there is one. The row keeps the
  /// height every header's row has.
  static Widget _withBottom(Widget? bottom, double rowHeight, Widget row) {
    if (bottom == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: rowHeight),
          child: row,
        ),
        const SizedBox(height: 12),
        bottom,
      ],
    );
  }
}
