import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The app's only way to show an image from a URL.
///
/// Built on `cached_network_image`: each image is downloaded once, kept on
/// disk across launches, and decoded at the size it is drawn at, so long
/// product lists stay light on memory while scrolling. Shows a themed
/// placeholder while loading and when the URL is missing or fails. Fills
/// its box unless [width] or [height] is given.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
    this.width,
    this.height,
  });

  final String? url;
  final BoxFit fit;
  final IconData placeholderIcon;
  final double? width;
  final double? height;

  static const Duration _fadeIn = Duration(milliseconds: 200);
  static const Duration _fadeOut = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null || url.isEmpty) {
      return _Placeholder(icon: placeholderIcon, width: width, height: height);
    }

    return LayoutBuilder(
      builder: (context, constraints) => CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: _decodeWidth(
          context,
          width ?? constraints.maxWidth,
          height ?? constraints.maxHeight,
        ),
        fadeInDuration: _fadeIn,
        fadeOutDuration: _fadeOut,
        placeholder: (context, _) =>
            _Placeholder(icon: placeholderIcon, width: width, height: height),
        errorWidget: (context, _, _) =>
            _Placeholder(icon: placeholderIcon, width: width, height: height),
      ),
    );
  }

  /// Pixel width to decode the image at: the box's longest side on this
  /// screen. Decoding at the drawn size instead of the source size keeps
  /// the in-memory cache small. Null (full size) when the box is unbounded.
  static int? _decodeWidth(BuildContext context, double width, double height) {
    final side = [width, height].where((v) => v.isFinite && v > 0);
    if (side.isEmpty) return null;
    final longest = side.reduce((a, b) => a > b ? a : b);
    return (longest * MediaQuery.devicePixelRatioOf(context)).ceil();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.width, this.height});

  final IconData icon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: colors.surfaceContainerHigh,
        child: Center(
          child: Icon(
            icon,
            size: 36,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
