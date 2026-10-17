import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart' show countries;
import 'package:intl_phone_field/intl_phone_field.dart';

import '../decorator/field_decorator.dart';

class PhoneTextFormField extends StatefulWidget {
  final String? label;
  final String? initialCountryCode;
  final String? initialValue;
  final void Function(String)? onChanged;
  final Function(String)? onCountryChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final TextEditingController? controller;
  final String? errorText;
  final String? hintText;
  final bool showCounter;

  /// Fix the country to [initialCountryCode] instead of offering a picker.
  final bool lockCountryCode;

  /// Only used when [lockCountryCode] is true.
  final IconData? prefixIcon;

  /// Only used when [lockCountryCode] is true; defaults to digits only.
  final List<TextInputFormatter>? inputFormatters;

  /// Only used when [lockCountryCode] is true.
  final Iterable<String>? autofillHints;

  const PhoneTextFormField({
    this.lockCountryCode = false,
    this.prefixIcon,
    this.inputFormatters,
    this.autofillHints,
    this.errorText,
    this.hintText,
    this.showCounter = true,
    super.key,
    required this.label,
    this.readOnly = false,
    this.initialCountryCode,
    this.initialValue,
    this.onChanged,
    this.onCountryChanged,
    this.validator,
    this.controller,
  });

  @override
  State<PhoneTextFormField> createState() => _PhoneTextFormFieldState();
}

class _PhoneTextFormFieldState extends State<PhoneTextFormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
      if (widget.initialValue != null &&
          widget.initialValue != _controller.text) {
        _controller.text = widget.initialValue!;
      }
    } else {
      _controller = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void didUpdateWidget(covariant PhoneTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (value) {
        final number = _controller.text.trim();

        if (widget.validator != null) {
          return widget.validator!(number);
        }
        return null;
      },
      builder: (field) {
        if (widget.lockCountryCode) return _buildLocked(context, field);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              controller: _controller,
              showCountryFlag: false,
              cursorColor: Theme.of(context).colorScheme.primary,
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: EdgeInsets.only(left: 8),
              initialCountryCode: widget.initialCountryCode,
              autovalidateMode: AutovalidateMode.disabled,
              enabled: !widget.readOnly,
              dropdownTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: FieldDecorator(
                context,
                label: widget.label ?? "",
                hintText: widget.hintText,
                showCounter: widget.showCounter,
              ).copyWith(errorText: field.errorText ?? widget.errorText),
              onChanged: (phone) {
                if (widget.onChanged != null) {
                  widget.onChanged!(phone.number);
                }
                field.didChange(phone.number);
              },
              onCountryChanged: (value) {
                if (widget.onCountryChanged != null) {
                  widget.onCountryChanged!(value.dialCode);
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// A plain number field with the country's dial code shown as a fixed,
  /// non-editable prefix.
  Widget _buildLocked(BuildContext context, FormFieldState<String> field) {
    final colors = Theme.of(context).colorScheme;
    final code = widget.initialCountryCode ?? 'IN';
    final country = countries.firstWhere(
      (c) => c.code == code,
      orElse: () => countries.firstWhere((c) => c.code == 'IN'),
    );

    final prefix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.prefixIcon != null)
          FieldDecorator.iconTile(colors, widget.prefixIcon!)
        else
          const SizedBox(width: 16),
        Text(
          '+${country.dialCode}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: colors.outlineVariant,
        ),
      ],
    );

    return TextField(
      controller: _controller,
      enabled: !widget.readOnly,
      keyboardType: TextInputType.phone,
      maxLength: country.maxLength,
      autofillHints: widget.autofillHints,
      inputFormatters:
          widget.inputFormatters ?? [FilteringTextInputFormatter.digitsOnly],
      cursorColor: Theme.of(context).colorScheme.primary,
      style: TextStyle(fontSize: 16, color: colors.onSurface),
      decoration:
          FieldDecorator(
            context,
            label: widget.label ?? "",
            hintText: widget.hintText,
            showCounter: widget.showCounter,
          ).copyWith(
            errorText: field.errorText ?? widget.errorText,
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(minHeight: 34),
          ),
      onChanged: (value) {
        widget.onChanged?.call(value);
        field.didChange(value);
      },
    );
  }
}
