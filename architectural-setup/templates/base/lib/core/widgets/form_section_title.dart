import 'package:flutter/material.dart';

/// The heading of one group of fields in a long form: a small brand icon,
/// a bold title and an optional muted line under it, e.g. "Contact
/// details — Filled from your profile". It pads itself only above.
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.topPadding = 24,
  });

  final String title;
  final IconData? icon;

  /// Muted line under the title.
  final String? description;

  /// Space above the title, to separate it from the group before.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = this.icon;
    final description = this.description;

    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: colors.primary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
