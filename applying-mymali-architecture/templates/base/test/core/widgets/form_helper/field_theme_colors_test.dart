import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/form_helper/field_config.dart';
import 'package:mymali/core/widgets/form_helper/universal_form_field.dart';

/// The fields take their text, cursor and fill colours from the theme, so
/// they stay readable on the dark theme as well as the light one.
void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final colors = theme.colorScheme;
    final name = theme.brightness.name;

    Future<void> pumpField(WidgetTester tester, Widget field) {
      return tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: field),
          ),
        ),
      );
    }

    EditableText editable(WidgetTester tester) =>
        tester.widget<EditableText>(find.byType(EditableText));

    InputDecoration decoration(WidgetTester tester) =>
        tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

    testWidgets('$name: a text field types in onSurface with a primary '
        'cursor', (tester) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.text,
          label: 'Full name',
          initialValue: 'Asha',
          onChanged: (_) {},
        ).build(),
      );

      expect(editable(tester).style.color, colors.onSurface);
      expect(editable(tester).cursorColor, colors.primary);
      expect(decoration(tester).fillColor, colors.surfaceContainerLowest);
    });

    testWidgets('$name: a locked phone field types in onSurface with a '
        'primary cursor', (tester) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.phone,
          label: 'Phone',
          initialValue: '',
          onChanged: (_) {},
        ).build(
          textInputConfig: const TextInputConfig(
            lockCountryCode: true,
            initialCountryCode: 'IN',
          ),
        ),
      );

      expect(editable(tester).style.color, colors.onSurface);
      expect(editable(tester).cursorColor, colors.primary);
    });

    testWidgets('$name: a dropdown shows its value in onSurface on the '
        'themed fill', (tester) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.dropdown,
          label: 'State',
          initialValue: 'mp',
          onChanged: (_) {},
        ).build(
          dropdownConfig: const DropdownConfig(
            dropdownOptions: [
              DropdownOption(key: 'mp', value: 'Madhya Pradesh'),
              DropdownOption(key: 'up', value: 'Uttar Pradesh'),
            ],
          ),
        ),
      );

      final value = tester.renderObject<RenderParagraph>(
        find.text('Madhya Pradesh').first,
      );
      expect(value.text.style?.color, colors.onSurface);
      expect(decoration(tester).fillColor, colors.surfaceContainerLowest);
    });

    testWidgets('$name: the chip input keeps the themed fill', (tester) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.multiChipField,
          label: 'Tags',
          onChanged: (_) {},
        ).build(),
      );

      expect(decoration(tester).fillColor, colors.surfaceContainerLowest);
      expect(editable(tester).style.color, colors.onSurface);
    });
  }
}
