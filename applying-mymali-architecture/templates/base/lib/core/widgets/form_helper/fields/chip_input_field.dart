import 'package:flutter/material.dart';
import 'package:mymali/core/widgets/form_helper/chips/primary_chip.dart';
import 'package:mymali/core/widgets/form_helper/decorator/field_decorator.dart';

class ChipInputField extends StatefulWidget {
  final List<String> initialChips;
  final ValueChanged<List<String>>? onChanged;
  final String? labelText;
  final String? hintText;
  final int? minChips;
  final int? maxChips;
  final FormFieldValidator<List<String>>? validator;

  const ChipInputField({
    super.key,
    this.initialChips = const [],
    this.onChanged,
    this.labelText,
    this.hintText,
    this.minChips,
    this.maxChips,
    this.validator,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<String> _chips;

  @override
  void initState() {
    super.initState();
    _chips = List<String>.from(widget.initialChips);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addChipFromInput([FormFieldState<List<String>>? field]) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!_chips.contains(text)) {
      setState(() {
        _chips.add(text);
      });
      widget.onChanged?.call(_chips);
      field?.didChange(_chips);
    }
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _removeChip(String chip, [FormFieldState<List<String>>? field]) {
    setState(() {
      _chips.remove(chip);
    });
    widget.onChanged?.call(_chips);
    field?.didChange(_chips);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: _chips,
      validator: (value) {
        final chips = value ?? _chips;

        // Custom validator from outside takes precedence
        if (widget.validator != null) {
          return widget.validator!(chips);
        }

        if (widget.minChips != null && chips.length < widget.minChips!) {
          final min = widget.minChips!;
          return 'Please add at least $min values${min == 1 ? '' : 's'}.';
        }

        if (widget.maxChips != null && chips.length > widget.maxChips!) {
          final max = widget.maxChips!;
          return 'Please add at most $max values${max == 1 ? '' : 's'}.';
        }

        return null;
      },
      builder: (field) {
        final decoration =
            FieldDecorator(
              context,
              label: widget.labelText ?? 'Add value',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addChipFromInput(field),
              ),
            ).copyWith(
              hintText: widget.hintText ?? 'Type and press done or +',
              errorText: field.errorText,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              decoration: decoration,
              onFieldSubmitted: (_) => _addChipFromInput(field),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chips
                  .map(
                    (chip) => PrimaryChip(
                      label: chip,
                      onDeleted: () => _removeChip(chip, field),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}
