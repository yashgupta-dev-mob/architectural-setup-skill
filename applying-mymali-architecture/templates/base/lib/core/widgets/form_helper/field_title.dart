import 'package:flutter/material.dart';

/// Small uppercase caption shown above a field when
/// `UniversalFormField.withTitle` is true.
class FieldTitle extends StatelessWidget {
  const FieldTitle(this.text, {super.key, this.style, this.textAlign});

  final String text;

  /// Overrides the default caption style.
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style:
          style ??
          theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
    );
  }
}
