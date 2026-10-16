import 'package:flutter/material.dart';

/// A rounded, softly outlined surface that groups one block of a page: the
/// referral code, a row of stats, a form section, or a list of
/// `IconListTile` rows (pass `padding: EdgeInsets.zero` and put
/// [AppCard.divider] between them).
///
/// With a [title] it opens with a header row (an icon, the title and
/// something at the end) over a divider, as Order Details' "Items",
/// "Delivery Address" and "Bill Summary" cards do. With an [accent] its
/// outline takes that colour and a strip of it runs down the left edge,
/// as My Orders' cards show their status.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.title,
    this.icon,
    this.trailing,
    this.onHeaderTap,
    this.headerKey,
    this.accent,
  });

  final Widget child;

  /// Space between the card's edge (or its header) and [child].
  final EdgeInsetsGeometry padding;

  /// The header row's title; null shows no header.
  final String? title;

  /// Shown before [title].
  final IconData? icon;

  /// Shown at the end of the header row, e.g. "Hide ⌃".
  final Widget? trailing;

  /// Makes the whole header row tappable, e.g. to fold the card.
  final VoidCallback? onHeaderTap;
  final Key? headerKey;

  /// Colours the outline and a strip down the left edge; null keeps the
  /// plain outline.
  final Color? accent;

  static const double radius = 22;

  static const double _accentWidth = 4;

  /// The line between two rows inside one card.
  static Widget divider(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = this.accent;
    final title = this.title;

    // A plain card pads itself; a titled or accented one pads its body.
    final plain = title == null && accent == null;
    Widget body = plain ? child : Padding(padding: padding, child: child);
    if (title != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            key: headerKey,
            title: title,
            icon: icon,
            trailing: trailing,
            onTap: onHeaderTap,
          ),
          divider(context),
          body,
        ],
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: plain ? padding : null,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent != null
              ? accent.withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.6),
          width: accent != null ? 1.5 : 1,
        ),
      ),
      child: accent == null
          ? body
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: _accentWidth),
                  child: body,
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _accentWidth,
                  child: ColoredBox(color: accent),
                ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = this.icon;
    final trailing = this.trailing;

    return Material(
      color: colors.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: colors.onSurface),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
        ),
      ),
    );
  }
}
