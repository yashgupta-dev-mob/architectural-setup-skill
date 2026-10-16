import 'package:flutter/material.dart';

import '../../utils/currency_format.dart';
import '../app_network_image.dart';

/// One line of a placed order: thumbnail, title, "2 × ₹89" and the line's
/// total. Thank You's and Order Details' item cards list these.
class OrderLineTile extends StatelessWidget {
  const OrderLineTile({
    super.key,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.imageUrl,
  });

  final String title;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: AppNetworkImage(
                url: imageUrl,
                placeholderIcon: Icons.eco_outlined,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$quantity × ${formatRupees(unitPrice)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatRupees(total),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
