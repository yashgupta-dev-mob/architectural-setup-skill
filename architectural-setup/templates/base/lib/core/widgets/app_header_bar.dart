import 'package:flutter/material.dart';

/// The app's own Material app bar, as each page had it: a title, a
/// leading button, actions, and optionally a bundled image laid over the
/// bar's colour. It is a plain [AppBar], so the theme's app bar look
/// (height, title style, icon colours) is kept exactly.
///
/// Use it as `Scaffold.appBar`, from a small feature widget that passes
/// the page's title, leading button and actions.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({
    super.key,
    required this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.backgroundImage,
    this.imageColor,
    this.imageOpacity,
    this.elevation = 0,
    this.centerTitle,
    this.bottom,
  });

  /// Usually a [Text]; its style comes from the theme unless it sets one.
  final Widget title;

  /// Null shows the route's default back button, when there is one.
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;

  /// Null keeps the theme's app bar colour.
  final Color? backgroundColor;

  /// Null keeps the theme's colour for the title and icons.
  final Color? foregroundColor;

  /// An `AppAssets` path, drawn over [backgroundColor] to cover the bar.
  final String? backgroundImage;

  /// Painted behind [backgroundImage], inside the bar's image area.
  final Color? imageColor;

  /// Fades [backgroundImage] (0 to 1); null draws it fully opaque.
  final double? imageOpacity;

  final double elevation;

  /// Null keeps the platform's alignment.
  final bool? centerTitle;

  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final image = backgroundImage;
    final imageColor = this.imageColor;
    final imageOpacity = this.imageOpacity;

    return AppBar(
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      flexibleSpace: image == null
          ? null
          : Stack(
              fit: StackFit.expand,
              children: [
                if (imageColor != null) ColoredBox(color: imageColor),
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  opacity: imageOpacity == null
                      ? null
                      : AlwaysStoppedAnimation(imageOpacity),
                ),
              ],
            ),
    );
  }
}
