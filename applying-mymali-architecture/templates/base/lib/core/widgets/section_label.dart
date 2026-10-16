// GENERIC: MyMali's SectionLabel with neutral doc examples.
import 'package:flutter/material.dart';

/// A small uppercase caption that names the block under it, with a short
/// accent bar before it: "RECENT ACTIVITY", "SETTINGS". Lighter than a
/// [SectionHeader]; use it for the sections of a single page rather than
/// the rails of a feed.
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  /// Shown in uppercase.
  final String title;

  /// Space around the label.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
