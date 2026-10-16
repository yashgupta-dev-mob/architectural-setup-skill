import 'package:flutter/material.dart';

import '../buttons/circle_icon_button.dart';
import '../form_helper/field_config.dart';
import '../form_helper/universal_form_field.dart';

/// The app's pill-shaped search input, built on `UniversalFormField`
/// (`UFFType.search`), with an optional accent action such as a camera.
///
/// [onChanged] is debounced by the underlying field. Wrap it in a
/// `KeyedSubtree` with a screen-specific key for tests.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search',
    this.initialValue = '',
    this.autofocus = false,
    this.onSubmitted,
    this.trailingIcon,
    this.onTrailingPressed,
    this.trailingTooltip,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final String initialValue;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// Icon of the accent button at the trailing edge. Nothing is shown
  /// when null.
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final String? trailingTooltip;

  @override
  Widget build(BuildContext context) {
    return UniversalFormField(
      fieldType: UFFType.search,
      label: 'products',
      initialValue: initialValue,
      onChanged: (value) => onChanged(value as String),
    ).build(
      textInputConfig: TextInputConfig(autofocus: autofocus),
      searchConfig: SearchConfig(
        hintText: hintText,
        borderRadius: 28,
        onSubmitted: onSubmitted,
        trailing: trailingIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CircleIconButton(
                  icon: trailingIcon!,
                  size: 40,
                  accent: true,
                  tooltip: trailingTooltip,
                  onPressed: onTrailingPressed,
                ),
              ),
      ),
    );
  }
}
