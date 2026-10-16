import 'package:flutter/material.dart';

import '../decorator/field_decorator.dart';

class DropdownField extends StatefulWidget {
  final dynamic value;
  final List<DropdownMenuItem>? items;
  final String? label;
  final bool showLabel;
  final String? Function(dynamic)? validator;
  final void Function(dynamic)? onChanged;

  /// Shown while nothing is chosen; defaults to [label].
  final String? hintText;

  /// Icon shown in a tinted tile at the start of the field.
  final IconData? prefixIcon;

  /// Error shown without running a Form validation, e.g. from a BLoC state.
  final String? errorText;

  const DropdownField({
    super.key,
    this.value,
    this.items,
    this.showLabel = true,
    required this.label,
    this.validator,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.errorText,
  });

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonFormField(
      key: widget.key,
      hint: Text(
        widget.hintText ?? widget.label ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
      style: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 16,
        color: colors.onSurface,
      ),
      onChanged: widget.onChanged,
      validator: widget.validator,
      borderRadius: BorderRadius.circular(12),
      initialValue: widget.value,
      isExpanded: true,
      icon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colors.onSurface,
          size: 24,
        ),
      ),
      focusColor: colors.surfaceContainerLowest,
      dropdownColor: colors.surfaceContainer,
      elevation: 12,
      menuMaxHeight: 320,
      decoration: FieldDecorator(
        context,
        label: widget.label ?? '',
        isDropdown: true,
        prefixIcon: widget.prefixIcon,
        floatingLabelBehavior: widget.value == null
            ? FloatingLabelBehavior.never
            : FloatingLabelBehavior.always,
      ).copyWith(errorText: widget.errorText),
      selectedItemBuilder: (BuildContext context) {
        // This displays the selected item in the main field
        return widget.items!.map((item) {
          return Align(alignment: Alignment.centerLeft, child: item.child);
        }).toList();
      },
      items: widget.items?.map((item) {
        final isSelected = widget.value == item.value;

        return DropdownMenuItem(
          value: item.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                // Accent indicator for selected item
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Item text
                Expanded(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : colors.onSurface,
                      letterSpacing: 0.2,
                    ),
                    child: item.child,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: colors.onPrimary, size: 14),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
