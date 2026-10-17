import 'package:flutter/material.dart';

import '../../chips/filter_chip_button.dart';
import '../field_config.dart';

/// A row of pills of which exactly one is picked, e.g. "Home · Work ·
/// Other". Each pill is a [FilterChipButton] that fills when picked.
///
/// [errorText] shows an error without a Form validation; [validator] runs
/// in a Form with the picked value as text.
class ChoiceChipsField extends StatelessWidget {
  const ChoiceChipsField({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.keyPrefix,
    this.enabled = true,
    this.errorText,
    this.validator,
  });

  final List<ChoiceChipOption> options;

  /// The picked option's value; null when none is picked.
  final Object? value;
  final ValueChanged<Object> onChanged;

  /// Each chip gets the key `<keyPrefix>_<keyId>` when both are set.
  final String? keyPrefix;
  final bool enabled;
  final String? errorText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<Object>(
      initialValue: value,
      validator: validator == null
          ? null
          : (picked) => validator!(picked?.toString()),
      builder: (field) {
        final error = field.errorText ?? errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in options)
                  FilterChipButton(
                    key: keyPrefix != null && option.keyId != null
                        ? Key('${keyPrefix}_${option.keyId}')
                        : null,
                    label: option.label,
                    icon: option.icon,
                    showDropdownArrow: false,
                    fillWhenSelected: true,
                    selected: option.value == value,
                    onPressed: enabled
                        ? () {
                            field.didChange(option.value);
                            onChanged(option.value);
                          }
                        : null,
                  ),
              ],
            ),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
