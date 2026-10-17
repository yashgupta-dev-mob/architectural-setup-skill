import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectorField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final String? label;
  final String? hint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? Function(DateTime?)? validator;
  final IconData prefixIcon;
  final bool showClearButton;
  final EdgeInsets? contentPadding;

  const DateSelectorField({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.label,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.validator,
    this.prefixIcon = Icons.calendar_today_rounded,
    this.showClearButton = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabledColor = colors.onSurface.withValues(alpha: 0.38);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return FormField<DateTime?>(
      initialValue: selectedDate,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final DateTime? value = field.value;
        final displayText = value != null
            ? dateFormat.format(value)
            : (hint ?? 'Select date');

        final hasError = field.hasError;
        final errorText = field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: enabled
                  ? () async {
                      final picked = await _showDatePicker(context, value);
                      if (picked != null) {
                        field.didChange(picked);
                        field.validate();
                        onDateSelected?.call(picked);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(10.58),
              child: InputDecorator(
                decoration: InputDecoration(
                  label: label != null
                      ? Text(
                          label!,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          textAlign: TextAlign.start,
                        )
                      : null,
                  hintStyle: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  labelStyle: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding:
                      contentPadding ??
                      const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.58),
                    borderSide: BorderSide(
                      color: colors.primaryContainer,
                      width: 1.25,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.58),
                    borderSide: BorderSide(
                      color: colors.primaryContainer,
                      width: 1.25,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.58),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.58),
                    borderSide: BorderSide(
                      color: colors.error,
                      width: enabled ? 0.8 : 1.25,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.58),
                    borderSide: BorderSide(color: colors.error, width: 0.8),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  errorText: hasError ? errorText : null,
                  suffixIcon: value != null && enabled && showClearButton
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            field.didChange(null);
                            field.validate();
                            onDateSelected?.call(null);
                          },
                        )
                      : Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.onSurface,
                          size: 24,
                        ),
                  prefixIcon: Icon(
                    prefixIcon,
                    size: 20,
                    color: enabled
                        ? (value != null
                              ? colors.primary
                              : colors.onSurfaceVariant)
                        : disabledColor,
                  ),
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled
                        ? (value != null
                              ? colors.onSurface
                              : colors.onSurfaceVariant)
                        : disabledColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<DateTime?> _showDatePicker(BuildContext context, DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Theme(
          data: theme.copyWith(
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surface,
              headerBackgroundColor: colors.primary,
              headerForegroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              dayStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.surface),
          ),
          child: child!,
        );
      },
    );
  }
}
