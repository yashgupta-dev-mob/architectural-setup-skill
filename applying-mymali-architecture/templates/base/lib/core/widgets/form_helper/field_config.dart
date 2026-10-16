// ignore_for_file: constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum UFFType {
  text,
  phone,
  date,
  time,
  year,
  address,
  radio,
  switchBtn,
  multiSelect,
  dropdown,
  multiText,
  slider,
  search,
  checkbox,
  upload,
  singleCheckbox,
  incDec,
  dateTimePicker,
  locationWithTextSearch,
  multiChipField,
  richTextEditor,
  multiDocumentSelect,
  chatTextBox,
  dropdownMultiChip,
  otp,
  choiceChips,
  rating,
}

class WrapperConfig {
  final double widthX5;
  final double widthX4;
  final double widthX3;
  final double? fixedWidth;
  const WrapperConfig({
    this.widthX5 = 350,
    this.widthX4 = 325,
    this.widthX3 = 300,
    this.fixedWidth,
  });

  WrapperConfig copyWith({
    double? widthX5,
    double? widthX4,
    double? widthX3,
    double? fixedWidth,
  }) {
    return WrapperConfig(
      widthX5: widthX5 ?? this.widthX5,
      widthX4: widthX4 ?? this.widthX4,
      widthX3: widthX3 ?? this.widthX3,
      fixedWidth: fixedWidth ?? this.fixedWidth,
    );
  }
}

class TextInputConfig {
  final TextInputType? textInputType;
  final TextInputFieldType? textInputFieldType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final Widget? prefix;

  /// Shown at the end of a text field, e.g. a "Locked" chip on a field
  /// the user cannot change.
  final Widget? suffix;
  final bool obscureText;
  final Function(bool)? obscureChange;
  final Function(String)? onFieldSubmitted;
  final AutovalidateMode autovalidateMode;
  final dynamic Function(String)? onCountryChanged;
  final Iterable<String>? autofillHints;
  final MouseCursor? mouseCursor;
  final InputDecoration? decorator;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool? enabled;
  final Function()? onEditingComplete;
  final TextAlign? textAlign;
  final String? initialCountryCode;

  /// Error shown on the field without running a Form validation, e.g. an
  /// error held in a BLoC state.
  final String? errorText;

  /// Placeholder shown inside the field.
  final String? hintText;

  /// Icon shown in a tinted tile at the start of the field.
  final IconData? prefixIcon;

  /// Whether to show the character counter when [maxLength] is set.
  final bool showCounter;

  /// Phone fields only: fix the country to [initialCountryCode] and hide
  /// the country picker.
  final bool lockCountryCode;
  const TextInputConfig({
    this.lockCountryCode = false,
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.showCounter = true,
    this.textInputType,
    this.inputFormatters,
    this.initialCountryCode,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputFieldType,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.obscureChange,
    this.onFieldSubmitted,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.autofillHints,
    this.mouseCursor,
    this.decorator,
    this.focusNode,
    this.enabled,
    this.onEditingComplete,
    this.textAlign,
    this.autofocus = false,
    this.onCountryChanged,
  });
}

enum TextInputFieldType { email, password }

class OtpConfig {
  /// Number of digit boxes.
  final int length;

  /// Called once every box is filled.
  final void Function(String)? onCompleted;

  /// Error shown without running a Form validation, e.g. from a BLoC state.
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final bool obscureText;
  const OtpConfig({
    this.length = 4,
    this.onCompleted,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
  });
}

class DatePickerConfig {
  final String? Function(DateTime?)? dateValidator;
  final bool showClearButton;
  final bool enabled;
  const DatePickerConfig({
    this.dateValidator,
    this.showClearButton = false,
    this.enabled = true,
  });
}

class TimePickerConfig {
  final String? Function(TimeOfDay?)? timeValidator;
  final bool showClearButton;
  final bool enabled;
  final bool use24HourFormat;
  const TimePickerConfig({
    this.timeValidator,
    this.showClearButton = false,
    this.enabled = true,
    this.use24HourFormat = false,
  });
}

class RadioConfig {
  final Color? radioColor;
  const RadioConfig({this.radioColor});
}

class DropdownConfig {
  final List<DropdownOption> dropdownOptions;
  final String? Function(dynamic)? dropdownValidator;
  final bool isLoading;

  /// Shown while nothing is chosen; defaults to the field's label.
  final String? hintText;

  /// Icon shown in a tinted tile at the start of the field.
  final IconData? prefixIcon;

  /// Error shown without running a Form validation, e.g. an error held in
  /// a BLoC state.
  final String? errorText;
  const DropdownConfig({
    this.dropdownOptions = const [],
    this.dropdownValidator,
    this.isLoading = false,
    this.hintText,
    this.prefixIcon,
    this.errorText,
  });
}

/// One choice of a [UFFType.choiceChips] field.
class ChoiceChipOption {
  /// What `onChanged` receives when this choice is picked.
  final Object value;
  final String label;
  final IconData? icon;

  /// Seeds the chip's key, `<keyPrefix>_<keyId>`, for tests.
  final String? keyId;
  const ChoiceChipOption({
    required this.value,
    required this.label,
    this.icon,
    this.keyId,
  });
}

/// Options of a [UFFType.choiceChips] field: a row of pills of which
/// exactly one is picked. The field's `initialValue` is the picked value.
class ChoiceChipsConfig {
  final List<ChoiceChipOption> options;

  /// Each chip gets the key `<keyPrefix>_<keyId>` when both are set.
  final String? keyPrefix;
  final bool enabled;

  /// Error shown under the chips, e.g. an error held in a BLoC state.
  final String? errorText;
  const ChoiceChipsConfig({
    this.options = const [],
    this.keyPrefix,
    this.enabled = true,
    this.errorText,
  });
}

/// Options of a [UFFType.rating] field: a row of stars, of which the
/// first n are filled. The field's `initialValue` is the rating (0 = none).
class RatingConfig {
  /// How many stars there are.
  final int maxRating;

  /// Size of each star.
  final double starSize;

  /// Each star gets the key `<keyPrefix>_<n>` (n from 1) when set.
  final String? keyPrefix;
  final bool enabled;

  /// Error shown under the stars, e.g. an error held in a BLoC state.
  final String? errorText;
  const RatingConfig({
    this.maxRating = 5,
    this.starSize = 32,
    this.keyPrefix,
    this.enabled = true,
    this.errorText,
  });
}

class MultiChipDropdownConfig {
  final List<DropdownOption> dropDownOptions;
  final String? Function(List<String>?)? validator;
  final bool isLoading;
  const MultiChipDropdownConfig({
    this.dropDownOptions = const [],
    this.isLoading = false,
    this.validator,
  });
}

// for dropdown option
class DropdownOption {
  final dynamic key;
  final String value;
  final Color? color;
  const DropdownOption({required this.key, required this.value, this.color});
}

enum WidgetOrder { NORMAL, REVERSED }

class SingleCheckboxConfig {
  final bool checkboxValue;
  final WidgetOrder widgetOrder;
  const SingleCheckboxConfig({
    this.checkboxValue = false,
    this.widgetOrder = WidgetOrder.NORMAL,
  });
}

class SwitchConfig {
  final bool value;

  const SwitchConfig({this.value = false});
}

class CheckboxConfig {
  final List<String>? options;
  final List<String>? selectedItems;
  const CheckboxConfig({this.options, this.selectedItems});
}

class MultiSelectConfig {
  final Map<dynamic, dynamic> options;
  final List<dynamic>? selectedItems;
  final void Function(List<dynamic> selectedItems)? onChanged;
  final String? Function(List<dynamic>?)? validator;
  const MultiSelectConfig({
    this.options = const {},
    this.selectedItems,
    this.onChanged,
    this.validator,
  });
}

class MultiTextConfig {
  final List<String>? editableStringItems;
  final void Function(List<String>)? updateListInState;
  const MultiTextConfig({this.editableStringItems, this.updateListInState});
}

class SliderConfig {
  final double? minVal;
  final double? maxVal;

  const SliderConfig({this.minVal, this.maxVal});
}

class SearchConfig {
  final FutureOr<Iterable<Object>> Function(String)? optionsBuilder;
  final void Function(Object)? onSuggestionSelected;
  final Widget Function(BuildContext, Object)? itemBuilder;

  /// Placeholder; defaults to "Search <label>...".
  final String? hintText;

  /// Called, undebounced, on the keyboard's search action.
  final void Function(String)? onSubmitted;

  /// Widget shown at the trailing edge, e.g. an accent camera button.
  final Widget? trailing;

  /// Corner radius; 28 gives a pill at the default height.
  final double borderRadius;

  /// How long typing must pause before `onChanged` fires.
  final Duration debounceDuration;

  const SearchConfig({
    this.optionsBuilder,
    this.onSuggestionSelected,
    this.itemBuilder,
    this.hintText,
    this.onSubmitted,
    this.trailing,
    this.borderRadius = 16,
    this.debounceDuration = const Duration(milliseconds: 300),
  });
}

class FileUploadConfig {
  final String? url;

  const FileUploadConfig({this.url});
}

class IncDecConfig {
  final void Function()? onIncrement;
  final void Function()? onDecrement;

  const IncDecConfig({this.onIncrement, this.onDecrement});
}

class MultiChipConfig {
  final List<String>? initialValue;
  final int? maxChips;
  final int? minChips;
  final String? Function(List<String>?)? onSumbitValidator;
  const MultiChipConfig({
    this.onSumbitValidator,
    this.initialValue,
    this.maxChips,
    this.minChips,
  });
}

class UploadConfig {
  final dynamic value;
  final bool? isReadOnly;
  final bool? enableCopy;
  final bool? allowMultiple;
  final int? limit;
  final List<String>? docTypes;
  final String? Function()? validate;
  final double? maximumDocumentSize;
  final bool? enablePreview;
  const UploadConfig({
    this.value,
    this.isReadOnly,
    this.enableCopy,
    this.allowMultiple,
    this.limit,
    this.docTypes,
    this.validate,
    this.maximumDocumentSize,
    this.enablePreview,
  });
}

class ChatTextBoxConfig {
  // final Function(
  //         String message, MessageType type, List<PlatformFile> attachments)?
  //     onSendMessage;
  final Function()? onCallNow;
  final Function()? onCallLater;
  final Function()? onFeedbackSale;
  final Function()? onSalesComplete;
  final Function()? onWhatsAppTemplate;
  final Function()? onStatus;
  final Function()? onType;
  final Function()? onHandOver;
  final Function()? onRelease;

  final bool showNoteButton;
  final bool showCallButtons;
  final bool showFeedbackButton;
  final bool showUploadButton;
  final bool showTemplateButton;
  final String? placeholder;
  final bool showSendMailButton;
  final bool showSendWhatsappButton;
  final int maxLines;
  final bool isSendingMsg;
  final bool showAddNoteButton;

  const ChatTextBoxConfig({
    // this.onSendMessage,
    this.onCallNow,
    this.showSendMailButton = false,
    this.isSendingMsg = false,
    this.onCallLater,
    this.onFeedbackSale,
    this.onStatus,
    this.onType,
    this.onSalesComplete,
    this.onWhatsAppTemplate,
    this.onHandOver,
    this.onRelease,
    this.showAddNoteButton = true,
    this.showNoteButton = true,
    this.showSendWhatsappButton = false,
    this.showCallButtons = true,
    this.showFeedbackButton = true,
    this.showUploadButton = true,
    this.showTemplateButton = true,
    this.placeholder,
    this.maxLines = 4,
  });
}

enum MessageType {
  none,
  ai_chat,
  live_chat,
  text_message,
  live_message,
  whatsapp_message,
  video_call,
  audio_call,
  video_message,
  voice_message,
  feedback_form,
  agent_feedback_form,
  note,
  video_feedback,
  audio_feedback,
  text_feedback,
  bot_response,
  chat_response,
  chat_request,
  request_handover,
  schedule_meeting,
  image,
  document,
  url,
  outbound_call,
  payment,
  meeting_snap,
  lead_config_status_change,
  lead_config_type_change,
  lead_purchase_status_change,
  handover_message,
  lead_owner_changed,
}
