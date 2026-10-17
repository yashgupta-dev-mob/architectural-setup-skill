import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One-time-code input shown as a row of digit boxes.
///
/// A single invisible text field sits over the boxes and handles typing,
/// backspace, paste and SMS autofill; the boxes only display its value.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    this.length = 4,
    this.initialValue,
    this.onChanged,
    this.onCompleted,
    this.validator,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
  });

  final int length;
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  /// Called once every box is filled.
  final ValueChanged<String>? onCompleted;
  final String? Function(String?)? validator;

  /// Error shown without running a Form validation, e.g. from a BLoC state.
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final bool obscureText;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_rebuild)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (field) {
        final errorText = field.errorText ?? widget.errorText;
        final colors = Theme.of(context).colorScheme;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final boxWidth = math.min(
                  58.0,
                  (constraints.maxWidth - spacing * (widget.length - 1)) /
                      widget.length,
                );

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: spacing,
                      children: [
                        for (var i = 0; i < widget.length; i++)
                          _DigitBox(
                            width: boxWidth,
                            value: i < _controller.text.length
                                ? (widget.obscureText
                                      ? '•'
                                      : _controller.text[i])
                                : null,
                            isActive:
                                _focusNode.hasFocus &&
                                i ==
                                    math.min(
                                      _controller.text.length,
                                      widget.length - 1,
                                    ),
                            hasError: errorText != null,
                            enabled: widget.enabled,
                          ),
                      ],
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: widget.autofocus,
                          enabled: widget.enabled,
                          keyboardType: TextInputType.number,
                          maxLength: widget.length,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {});
                            field.didChange(value);
                            widget.onChanged?.call(value);
                            if (value.length == widget.length) {
                              widget.onCompleted?.call(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.width,
    required this.value,
    required this.isActive,
    required this.hasError,
    required this.enabled,
  });

  final double width;
  final String? value;
  final bool isActive;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = hasError
        ? colors.error
        : isActive
        ? colors.primary
        : colors.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: width * 1.08,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? colors.surfaceContainerLowest
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 1.8 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: value != null
          ? Text(
              value!,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            )
          : isActive
          ? Container(
              width: width * 0.3,
              height: 2,
              margin: EdgeInsets.only(top: width * 0.35),
              color: colors.primary,
            )
          : null,
    );
  }
}
