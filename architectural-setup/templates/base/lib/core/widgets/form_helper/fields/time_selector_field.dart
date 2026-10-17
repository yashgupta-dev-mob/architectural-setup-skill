import 'package:flutter/material.dart';

class TimeSelectorField extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay?>? onTimeSelected;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? Function(TimeOfDay?)? validator;
  final IconData prefixIcon;
  final bool showClearButton;
  final EdgeInsets? contentPadding;
  final bool use24HourFormat;

  const TimeSelectorField({
    super.key,
    this.selectedTime,
    this.onTimeSelected,
    this.label,
    this.hint,
    this.enabled = true,
    this.validator,
    this.prefixIcon = Icons.access_time_rounded,
    this.showClearButton = true,
    this.contentPadding,
    this.use24HourFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabledColor = colors.onSurface.withValues(alpha: 0.38);

    return FormField<TimeOfDay?>(
      initialValue: selectedTime,
      validator: (value) {
        if (validator != null) {
          return validator!(value);
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final TimeOfDay? value = field.value;
        final displayText = value != null
            ? _formatTime(value)
            : (hint ?? 'Select time');

        final hasError = field.hasError;
        final errorText = field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: enabled
                  ? () async {
                      final picked = await _showTimePicker(context, value);
                      if (picked != null) {
                        field.didChange(picked);
                        field.validate();
                        onTimeSelected?.call(picked);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(10.58),
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surface,
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
                            onTimeSelected?.call(null);
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

  String _formatTime(TimeOfDay time) {
    if (use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context, TimeOfDay? current) {
    return showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
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
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colors.surface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.primaryContainer, width: 1),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              hourMinuteColor: colors.primaryContainer,
              hourMinuteTextColor: colors.primary,
              dayPeriodColor: colors.primaryContainer,
              dayPeriodTextColor: colors.primary,
              dialHandColor: colors.primary,
              dialBackgroundColor: colors.surfaceContainerHighest,
              dialTextColor: colors.onSurface,
              entryModeIconColor: colors.primary,
              helpTextStyle: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.surface),
          ),
          child: child!,
        );
      },
    );
  }
}
