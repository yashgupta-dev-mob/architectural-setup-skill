import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityChip extends StatelessWidget {
  final String name;
  final int count;
  final IconData icon;
  final Color color;
  final Function()? onTap;

  const ActivityChip({
    super.key,
    required this.name,
    required this.count,
    required this.icon,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 5,
      surfaceTintColor: Colors.transparent,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: colors.onPrimary),
              ),
              Text(
                '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
