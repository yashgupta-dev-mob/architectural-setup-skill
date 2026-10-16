import 'package:flutter/material.dart';
import 'package:mymali/core/widgets/form_helper/chips/primary_chip.dart';
import 'package:mymali/core/widgets/form_helper/field_config.dart';
import 'package:mymali/core/widgets/form_helper/universal_form_field.dart';

class DropDownMultiChip extends StatefulWidget {
  final String label;
  final List<String>? initialValue;
  final List<DropdownOption> dropdownOptions;
  final String? Function(List<String>?)? validator;
  final bool isLoading;
  const DropDownMultiChip({
    super.key,
    required this.label,
    this.initialValue,
    this.validator,
    this.isLoading = false,
    this.dropdownOptions = const [],
  });

  @override
  State<DropDownMultiChip> createState() => _DropDownMultiChipState();
}

class _DropDownMultiChipState extends State<DropDownMultiChip> {
  late List<String> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List<String>.from(widget.initialValue ?? const <String>[]);
  }

  /// Returns only the options whose values are NOT already selected
  List<DropdownOption> get _availableOptions {
    return widget.dropdownOptions
        .where((option) => !selectedItems.contains(option.value))
        .toList();
  }

  void _addItem(String val, FormFieldState<List<String>> field) {
    // Guard: don't add duplicates (handles race conditions)
    if (selectedItems.contains(val)) return;

    setState(() {
      selectedItems = [val, ...selectedItems];
      field.didChange(List<String>.from(selectedItems));
    });
  }

  void _removeItem(String item, FormFieldState<List<String>> field) {
    setState(() {
      selectedItems.remove(item);
      field.didChange(List<String>.from(selectedItems));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: selectedItems,
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(val);
        }
        return null;
      },
      builder: (field) {
        return Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UniversalFormField(
              // Key changes whenever selectedItems changes so the dropdown
              // re-renders with the updated (filtered) options list and also
              // resets its own internal value back to null — giving the
              // "select another" UX.
              key: ValueKey(selectedItems.join(',')),
              fieldType: UFFType.dropdown,
              label: widget.label,
              initialValue: null,
              onChanged: (val) => _addItem(val, field),
            ).build(
              dropdownConfig: DropdownConfig(
                isLoading: widget.isLoading,
                dropdownValidator: (val) {
                  if (widget.validator != null) {
                    return widget.validator!(selectedItems);
                  }
                  return null;
                },
                dropdownOptions: _availableOptions,
              ),
            ),
            if (selectedItems.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectedItems
                    .map(
                      (item) => PrimaryChip(
                        label: item,
                        onDeleted: () => _removeItem(item, field),
                      ),
                    )
                    .toList(),
              ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  field.errorText ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
