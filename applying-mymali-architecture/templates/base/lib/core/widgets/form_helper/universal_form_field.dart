// GENERIC: the date and time cases use the field's label and the configs' hintText instead of fixed demo text.
// ignore_for_file: avoid_unnecessary_containers
import 'package:flutter/material.dart';
import 'package:mymali/core/widgets/form_helper/fields/chip_input_field.dart';
import 'package:mymali/core/widgets/form_helper/fields/date_slector_field.dart';
import 'package:mymali/core/widgets/form_helper/fields/radio_toggle.dart';
import 'package:mymali/core/widgets/form_helper/fields/time_selector_field.dart';
import 'package:mymali/core/widgets/progress_indecator.dart';

import 'field_config.dart';
import 'field_title.dart';
import 'fields/choice_chips_field.dart';
import 'fields/custom_search_field.dart';
import 'fields/custom_text_form_field.dart';
import 'fields/dropdown_fields.dart';
import 'fields/otp_input_field.dart';
import 'fields/phone_text_form_field.dart';
import 'fields/rating_field.dart';

class UniversalFormField {
  final Key? key;
  final bool updateKey;
  final UFFType fieldType;
  final String label;
  final dynamic initialValue;
  final void Function(dynamic val) onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final bool hide;
  final bool fullWidth;
  final bool useController;
  final bool withTitle;
  final TextStyle? labelStyle;

  UniversalFormField({
    this.key,
    this.updateKey = false,
    required this.fieldType,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.controller,
    this.hide = false,
    this.fullWidth = false,
    this.useController = false,
    this.withTitle = false,
    this.labelStyle,
  });

  TextEditingController textEditingController = TextEditingController();

  Widget build({
    TextInputConfig textInputConfig = const TextInputConfig(),
    DropdownConfig dropdownConfig = const DropdownConfig(),
    MultiChipDropdownConfig multiChipDropdownConfig =
        const MultiChipDropdownConfig(),
    // MultiTextConfig multiTextConfig = const MultiTextConfig(),
    // MultiSelectConfig multiSelectConfig = const MultiSelectConfig(),
    DatePickerConfig datePickerConfig = const DatePickerConfig(),
    TimePickerConfig timePickerConfig = const TimePickerConfig(),
    SearchConfig searchConfig = const SearchConfig(),
    RadioConfig radioConfig = const RadioConfig(),
    SingleCheckboxConfig singleCheckboxConfig = const SingleCheckboxConfig(),
    CheckboxConfig checkboxConfig = const CheckboxConfig(),
    // SliderConfig sliderConfig = const SliderConfig(),
    SwitchConfig switchConfig = const SwitchConfig(),
    WrapperConfig wrapperConfig = const WrapperConfig(),
    // IncDecConfig incDecConfig = const IncDecConfig(),
    MultiChipConfig multiChipConfig = const MultiChipConfig(),
    UploadConfig uploadConfig = const UploadConfig(),
    ChatTextBoxConfig chatTextBoxConfig = const ChatTextBoxConfig(),
    OtpConfig otpConfig = const OtpConfig(),
    ChoiceChipsConfig choiceChipsConfig = const ChoiceChipsConfig(),
    RatingConfig ratingConfig = const RatingConfig(),
  }) {
    Widget returningWidget = const SizedBox();
    if (controller != null) {
      textEditingController = controller!;
    } else {
      textEditingController.text = initialValue?.toString() ?? '';
      textEditingController.selection = TextSelection.collapsed(
        offset: initialValue?.toString().length ?? 0,
      );
    }

    var formField = CustomTextFormField(
      key: updateKey ? Key(initialValue ?? '') : null,
      textInputFieldType: textInputConfig.textInputFieldType,
      label: withTitle ? "" : label,
      autofocus: textInputConfig.autofocus,
      textAlign: textInputConfig.textAlign ?? TextAlign.start,
      autovalidateMode: textInputConfig.autovalidateMode,
      controller: useController
          ? textEditingController
          : initialValue == null
          ? textEditingController
          : null,
      initialValue: !useController ? initialValue?.toString() : null,
      decorator: textInputConfig.decorator,
      enabled: textInputConfig.enabled,
      focusNode: textInputConfig.focusNode,
      inputFormatters: textInputConfig.inputFormatters,
      maxLength: textInputConfig.maxLength,
      maxLines: textInputConfig.maxLines,
      onFieldSubmitted: textInputConfig.onFieldSubmitted,
      onEditingComplete: textInputConfig.onEditingComplete,
      obscureText: textInputConfig.obscureText,
      obscureChange: textInputConfig.obscureChange,
      prefix: textInputConfig.prefix,
      suffix: textInputConfig.suffix,
      readOnly: textInputConfig.readOnly,
      textInputType: textInputConfig.textInputType,
      errorText: textInputConfig.errorText,
      hintText: textInputConfig.hintText,
      prefixIcon: textInputConfig.prefixIcon,
      showCounter: textInputConfig.showCounter,
      validator:
          validator ??
          (_) {
            return null;
          },
      onChanged: onChanged,
    );

    switch (fieldType) {
      case UFFType.text:
        returningWidget = formField;
        break;

      case UFFType.phone:
        returningWidget = PhoneTextFormField(
          label: withTitle ? '' : label,
          hintText: textInputConfig.hintText,
          showCounter: textInputConfig.showCounter,
          onChanged: onChanged,
          onCountryChanged: textInputConfig.onCountryChanged,
          initialCountryCode: textInputConfig.initialCountryCode ?? "IN",
          lockCountryCode: textInputConfig.lockCountryCode,
          inputFormatters: textInputConfig.inputFormatters,
          autofillHints: textInputConfig.autofillHints,
          prefixIcon: textInputConfig.prefixIcon,
          initialValue: initialValue,
          validator: validator,
          readOnly: textInputConfig.readOnly,
          controller: controller,
          errorText: textInputConfig.errorText,
        );
        break;

      case UFFType.search:
        returningWidget = CustomSearchBar(
          label: label,
          initialValue: initialValue?.toString(),
          onChanged: (value) => onChanged(value),
          validator: validator,
          readOnly: textInputConfig.readOnly,
          autofocus: textInputConfig.autofocus,
          controller: useController ? textEditingController : null,
          focusNode: textInputConfig.focusNode,
          hintText: searchConfig.hintText ?? textInputConfig.hintText,
          onSubmitted: searchConfig.onSubmitted,
          trailing: searchConfig.trailing,
          borderRadius: searchConfig.borderRadius,
          debounceDuration: searchConfig.debounceDuration,
        );
        break;
      case UFFType.dropdown:
        returningWidget = Stack(
          alignment: Alignment.centerRight,
          children: [
            IgnorePointer(
              ignoring: dropdownConfig.isLoading,
              child: DropdownField(
                key: key,
                items: dropdownConfig.dropdownOptions.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Row(
                      spacing: 16,
                      children: [
                        if (e.color != null)
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.color,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: dropdownConfig.isLoading ? (_) {} : onChanged,
                validator: dropdownConfig.dropdownValidator,
                label: withTitle ? '' : label,
                hintText: dropdownConfig.hintText,
                prefixIcon: dropdownConfig.prefixIcon,
                errorText: dropdownConfig.errorText,
                value: initialValue,
              ),
            ),
            if (dropdownConfig.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 40),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: ProgressIndecator(strokeWidth: 2),
                ),
              ),
          ],
        );
      case UFFType.multiChipField:
        returningWidget = Container(
          child: ChipInputField(
            labelText: label,
            maxChips: multiChipConfig.maxChips,
            minChips: multiChipConfig.minChips,
            validator: multiChipConfig.onSumbitValidator,
            initialChips: initialValue != null
                ? List<String>.from(initialValue)
                : <String>[],
            onChanged: (chips) => onChanged(chips),
          ),
        );
      case UFFType.radio:
        returningWidget = RadioToggle(
          initialValue: initialValue ?? false,
          onChanged: onChanged,
          radioColor: radioConfig.radioColor,
        );
      case UFFType.date:
        returningWidget = DateSelectorField(
          label: withTitle ? null : label,
          hint: datePickerConfig.hintText ?? label,
          selectedDate: initialValue,
          onDateSelected: (date) => onChanged(date),
          validator: datePickerConfig.dateValidator,
          enabled: datePickerConfig.enabled,
          showClearButton: datePickerConfig.showClearButton,
        );
      case UFFType.time:
        returningWidget = TimeSelectorField(
          label: withTitle ? null : label,
          hint: timePickerConfig.hintText ?? label,
          selectedTime: initialValue,
          onTimeSelected: onChanged,
          validator: timePickerConfig.timeValidator,
          use24HourFormat: timePickerConfig.use24HourFormat,
          enabled: timePickerConfig.enabled,
          showClearButton: timePickerConfig.showClearButton,
        );
      case UFFType.otp:
        returningWidget = OtpInputField(
          length: otpConfig.length,
          initialValue: initialValue?.toString(),
          onChanged: onChanged,
          onCompleted: otpConfig.onCompleted,
          validator: validator,
          errorText: otpConfig.errorText,
          autofocus: otpConfig.autofocus,
          enabled: otpConfig.enabled,
          obscureText: otpConfig.obscureText,
        );
      case UFFType.choiceChips:
        returningWidget = ChoiceChipsField(
          options: choiceChipsConfig.options,
          value: initialValue,
          onChanged: onChanged,
          keyPrefix: choiceChipsConfig.keyPrefix,
          enabled: choiceChipsConfig.enabled,
          errorText: choiceChipsConfig.errorText,
          validator: validator,
        );
      case UFFType.rating:
        returningWidget = RatingField(
          value: initialValue is int ? initialValue as int : 0,
          onChanged: onChanged,
          maxRating: ratingConfig.maxRating,
          starSize: ratingConfig.starSize,
          keyPrefix: ratingConfig.keyPrefix,
          enabled: ratingConfig.enabled,
          errorText: ratingConfig.errorText,
          validator: validator,
        );
      default:
        returningWidget = SizedBox.shrink();
    }

    if (withTitle) {
      returningWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldTitle(
            label,
            style: labelStyle,
            // The OTP boxes are centred, so centre their title too.
            textAlign: fieldType == UFFType.otp ? TextAlign.center : null,
          ),
          const SizedBox(height: 8),
          returningWidget,
        ],
      );
    }

    return hide
        ? const SizedBox.shrink()
        : wrapperConfig.fixedWidth != null
        ? SizedBox(
            width: wrapperConfig.fixedWidth,
            child: SizedBox(child: returningWidget),
          )
        : SizedBox(child: returningWidget);
  }
}
