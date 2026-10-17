import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../decorator/field_decorator.dart';
import '../field_config.dart';

class CustomTextFormField extends StatefulWidget {
  final String label;
  final Widget? prefix;

  /// Shown at the end of the field.
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final String? initialValue;
  final EdgeInsets? padding;
  final int maxLines;
  final bool? obscureText;
  final Function(bool)? obscureChange;
  final AutovalidateMode autovalidateMode;
  final String? Function(String? value) validator;
  final void Function(String value) onChanged;
  final void Function(String value)? onFieldSubmitted;
  final void Function()? onTap;
  final bool? readOnly;
  final TextInputType? textInputType;
  final bool isDateField;
  final bool isTimeField;
  final bool isYearField;
  final FocusNode? focusNode;
  final Function()? onEditingComplete;
  final bool? enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final InputDecoration? decorator;
  final bool autofocus;
  final TextAlign textAlign;
  final TextInputFieldType? textInputFieldType;
  final String? errorText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool showCounter;
  const CustomTextFormField({
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.showCounter = true,
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.padding,
    this.maxLines = 1,
    this.obscureText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    required this.validator,
    this.onFieldSubmitted,
    required this.onChanged,
    this.onTap,
    this.prefix,
    this.suffix,
    this.readOnly,
    this.textInputType,
    this.isDateField = false,
    this.isTimeField = false,
    this.isYearField = false,
    this.focusNode,
    this.onEditingComplete,
    this.enabled = true,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.decorator,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.textInputFieldType,
    this.obscureChange,
  });

  CustomTextFormField copyWith({
    Key? key,
    String? label,
    TextEditingController? controller,
    String? initialValue,
    EdgeInsets? padding,
    int? maxLines,
    bool? obscureText,
    AutovalidateMode? autovalidateMode,
    String? Function(String? value)? validator,
    void Function(String value)? onChanged,
    void Function(String value)? onFieldSubmitted,
    void Function()? onTap,
    bool? readOnly,
    TextInputType? textInputType,
    bool isDateField = false,
    bool isTimeField = false,
    bool isYearField = false,
    FocusNode? focusNode,
    Function()? onEditingComplete,
    bool? autofocus,
    InputDecoration? decorator,
    List<TextInputFormatter>? inputFormatters,
    TextInputFieldType? textInputFieldType,
  }) {
    return CustomTextFormField(
      key: key ?? this.key,
      label: label ?? this.label,
      controller: controller ?? this.controller,
      initialValue: initialValue,
      padding: padding ?? this.padding,
      maxLines: maxLines ?? this.maxLines,
      obscureText: obscureText ?? this.obscureText,
      autovalidateMode: autovalidateMode ?? this.autovalidateMode,
      validator: validator ?? this.validator,
      onChanged: onChanged ?? this.onChanged,
      onFieldSubmitted: onFieldSubmitted ?? this.onFieldSubmitted,
      onTap: onTap ?? this.onTap,
      readOnly: readOnly ?? this.readOnly,
      textInputType: textInputType ?? this.textInputType,
      isDateField: isDateField,
      isTimeField: isTimeField,
      textInputFieldType: textInputFieldType ?? this.textInputFieldType,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      isYearField: isYearField,
      focusNode: focusNode ?? this.focusNode,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      autofocus: autofocus ?? this.autofocus,
      decorator: decorator ?? this.decorator,
    );
  }

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  FieldDecorator _baseDecoration(BuildContext context) {
    return FieldDecorator(
      context,
      label: widget.label,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      showCounter: widget.showCounter,
      contentPadding: widget.padding,
      suffixIcon: widget.suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Theme(
      // Extend the app theme rather than replacing it with a default one.
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(cursorColor: colors.primary),
      ),
      child: TextFormField(
        key: widget.key,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        inputFormatters: widget.inputFormatters,
        onFieldSubmitted: widget.onFieldSubmitted,
        controller: widget.controller,
        initialValue: widget.initialValue,
        enabled: widget.enabled,
        decoration:
            (widget.isDateField
                    ? _baseDecoration(context).copyWith(
                        suffixIcon: GestureDetector(
                          onTap: widget.onTap,
                          child: const Icon(Icons.calendar_month_outlined),
                        ),
                        suffixIconColor: colors.onSurfaceVariant,
                      )
                    : widget.isTimeField
                    ? _baseDecoration(context).copyWith(
                        suffixIcon: const Icon(Icons.watch_later_outlined),
                        suffixIconColor: colors.primary,
                      )
                    : widget.isYearField
                    ? _baseDecoration(context).copyWith(
                        suffixIcon: GestureDetector(
                          onTap: widget.onTap,
                          child: const Icon(Icons.calendar_month),
                        ),
                        suffixIconColor: colors.primary,
                      )
                    : widget.textInputFieldType == TextInputFieldType.email
                    ? _baseDecoration(context).copyWith(
                        prefixIcon: Icon(
                          Icons.email,
                          color: colors.onSurfaceVariant,
                        ),
                        suffixIconColor: colors.primary,
                      )
                    : widget.textInputFieldType == TextInputFieldType.password
                    ? _baseDecoration(context).copyWith(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: colors.onSurfaceVariant,
                        ),
                        suffixIcon: (widget.obscureText != null)
                            ? IconButton(
                                onPressed: () {
                                  if (widget.obscureChange != null) {
                                    widget.obscureChange!(!widget.obscureText!);
                                  }
                                },
                                icon: Icon(
                                  widget.obscureText!
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              )
                            : null,
                        suffixIconColor: colors.onSurfaceVariant,
                      )
                    : widget.decorator ??
                          _baseDecoration(context)
                              .copyWith(prefix: widget.prefix))
                .copyWith(errorText: widget.errorText),
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        cursorColor: colors.primary,
        obscureText: widget.obscureText ?? false,
        maxLines: widget.maxLines,
        autovalidateMode: widget.autovalidateMode,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onTap: widget.isTimeField ? widget.onTap ?? () {} : () {},
        readOnly: widget.readOnly ?? false,
        keyboardType: widget.textInputType,
        onEditingComplete: widget.onEditingComplete,
        maxLength: widget.maxLength,
        textAlign: widget.textAlign,
      ),
    );
  }
}
