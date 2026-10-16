import 'package:flutter/material.dart';

import '../app_network_image.dart';

/// Last tile of a product rail: a few product thumbnails, an arrow, and
/// how many more products there are. The whole card is one tap target.
class ExploreMoreCard extends StatelessWidget {
  const ExploreMoreCard({
    super.key,
    required this.countLabel,
    required this.onTap,
    this.label = 'Explore more',
    this.imageUrls = const [],
    this.semanticLabel,
  });

  /// E.g. "+15 products".
  final String countLabel;
  final VoidCallback? onTap;
  final String label;

  /// Thumbnails shown overlapping at the top; the first [maxThumbnails]
  /// are used. A null or empty URL shows a placeholder.
  final List<String?> imageUrls;
  final String? semanticLabel;

  static const int maxThumbnails = 3;
  static const double _thumbnailSize = 42;

  /// How far each thumbnail sits to the right of the one before it.
  static const double _thumbnailStep = 26;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final thumbnails = imageUrls.take(maxThumbnails).toList();

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Soft circle bleeding off the top-right corner.
              Positioned(
                top: -44,
                right: -44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.08),
                  ),
                  child: const SizedBox.square(dimension: 132),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (thumbnails.isNotEmpty) ...[
                        SizedBox(
                          width:
                              _thumbnailSize +
                              (thumbnails.length - 1) * _thumbnailStep,
                          height: _thumbnailSize,
                          child: Stack(
                            children: [
                              for (var i = 0; i < thumbnails.length; i++)
                                Positioned(
                                  left: i * _thumbnailStep,
                                  child: _Thumbnail(url: thumbnails[i]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox.square(
                          dimension: 46,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: colors.primary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          child: Text(
                            countLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  static const double _border = 2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const inner = ExploreMoreCard._thumbnailSize - 2 * _border;

    return Container(
      width: ExploreMoreCard._thumbnailSize,
      height: ExploreMoreCard._thumbnailSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.surface, width: _border),
      ),
      child: ClipOval(
        child: AppNetworkImage(
          url: url,
          placeholderIcon: Icons.eco_outlined,
          width: inner,
          height: inner,
        ),
      ),
    );
  }
}
