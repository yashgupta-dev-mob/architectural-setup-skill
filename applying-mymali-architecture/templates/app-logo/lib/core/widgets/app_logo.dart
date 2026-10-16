import 'package:flutter/material.dart';

import '../assets/app_assets.dart';

/// A bundled brand image, decoded at the size it is drawn at: the app
/// logo by default, or another [AppAssets] mark such as the Mali coin.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.size,
    this.color,
    this.asset = AppAssets.icon,
    this.semanticLabel = 'My Mali',
  });

  final double size;

  /// Optional tint, e.g. to show the logo on a dark background.
  final Color? color;

  /// Which image to show, from [AppAssets].
  final String asset;

  /// What a screen reader says for the image.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    // The source images are very large; decode them at display size only.
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Image.asset(
      asset,
      width: size,
      height: size,
      cacheWidth: cacheSize,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      semanticLabel: semanticLabel,
    );
  }
}
