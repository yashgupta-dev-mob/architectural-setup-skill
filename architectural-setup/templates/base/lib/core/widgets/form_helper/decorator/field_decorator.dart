// ignore_for_file: use_super_parameters
import 'package:flutter/material.dart';

class FieldDecorator extends InputDecoration {
  factory FieldDecorator(
    BuildContext context, {
    required String label,
    String? hintText,
    IconData? prefixIcon,
    bool showCounter = true,
    EdgeInsets? contentPadding,
    bool isDropdown = false,
    bool enabled = false,
    Widget? suffixIcon,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return FieldDecorator._(
      Theme.of(context).colorScheme,
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      showCounter: showCounter,
      contentPadding: contentPadding,
      isDropdown: isDropdown,
      enabled: enabled,
      suffixIcon: suffixIcon,
      floatingLabelBehavior: floatingLabelBehavior,
    );
  }

  static const double _radius = 14;

  static OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Icon shown inside a small tinted, rounded tile, as used for
  /// `prefixIcon`.
  static Widget iconTile(ColorScheme colors, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: colors.primary),
      ),
    );
  }

  FieldDecorator._(
    ColorScheme colors, {
    required String label,
    String? hintText,
    IconData? prefixIcon,
    bool showCounter = true,
    EdgeInsets? contentPadding,
    bool isDropdown = false,
    bool enabled = false,
    Widget? suffixIcon,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) : super(
         // An empty label (e.g. when a title is shown above the field)
         // would still reserve floating-label space, so omit it.
         label: isDropdown || label.isEmpty
             ? null
             : Text(
                 label,
                 maxLines: 1,
                 overflow: TextOverflow.fade,
                 softWrap: false,
                 textAlign: TextAlign.start,
               ),
         labelText: isDropdown && label.isNotEmpty ? label : null,
         hintText: hintText,
         hintStyle: TextStyle(
           color: colors.onSurfaceVariant.withValues(alpha: 0.7),
           fontSize: 16,
           fontWeight: FontWeight.normal,
         ),
         labelStyle: TextStyle(
           color: colors.onSurfaceVariant,
           fontSize: 16,
           fontWeight: FontWeight.normal,
         ),
         hintMaxLines: 1,
         alignLabelWithHint: true,
         floatingLabelBehavior: FloatingLabelBehavior.auto,
         filled: true,
         fillColor: colors.surfaceContainerLowest,
         prefixIcon: prefixIcon == null ? null : iconTile(colors, prefixIcon),
         prefixIconConstraints: prefixIcon == null
             ? null
             : const BoxConstraints(minWidth: 54, minHeight: 34),
         counterText: showCounter ? null : '',
         contentPadding:
             contentPadding ?? const EdgeInsets.fromLTRB(16, 16, 16, 16),
         disabledBorder: _border(colors.outlineVariant.withValues(alpha: 0.5)),
         enabledBorder: _border(colors.outlineVariant),
         focusedBorder: _border(colors.primary, 1.6),
         errorBorder: _border(colors.error, enabled ? 0.8 : 1.2),
         focusedErrorBorder: _border(colors.error, 1.6),
         hintTextDirection: TextDirection.ltr,
         suffixIcon:
             suffixIcon ??
             (isDropdown
                 ? Icon(
                     Icons.keyboard_arrow_down,
                     size: 28,
                     weight: 20,
                     color: colors.onSurface,
                   )
                 : null),
       );
}
