import 'package:flutter/material.dart';

class PrimaryChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final EdgeInsetsGeometry? padding;
  final IconData deleteIcon;

  const PrimaryChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.padding,
    this.deleteIcon = Icons.close,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: Icon(
        deleteIcon,
        size: 18,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      onDeleted: onDeleted,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(8),
      //   side: BorderSide(
      //     color: Theme.of(context).colorScheme.primary,
      //     width: 2,
      //   ),
      // ),
      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 4,
      deleteIconColor: Theme.of(context).colorScheme.primary,
    );
  }
}
