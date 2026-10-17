import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/chips/filter_chip_button.dart';
import 'package:template_app/core/widgets/form_helper/field_config.dart';
import 'package:template_app/core/widgets/form_helper/universal_form_field.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, Widget field) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: field),
        ),
      ),
    );
  }

  group('UFFType.choiceChips', () {
    const options = [
      ChoiceChipOption(
        value: 'Home',
        label: 'Home',
        icon: Icons.home_outlined,
        keyId: 'home',
      ),
      ChoiceChipOption(value: 'Work', label: 'Work', keyId: 'work'),
    ];

    testWidgets('shows a pill per option, the picked one selected, under '
        'its title', (tester) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.choiceChips,
          label: 'Save address as',
          withTitle: true,
          initialValue: 'Home',
          onChanged: (_) {},
        ).build(
          choiceChipsConfig: const ChoiceChipsConfig(
            options: options,
            keyPrefix: 'test_label',
          ),
        ),
      );

      expect(find.text('SAVE ADDRESS AS'), findsOneWidget);
      final home = tester.widget<FilterChipButton>(
        find.byKey(const Key('test_label_home')),
      );
      final work = tester.widget<FilterChipButton>(
        find.byKey(const Key('test_label_work')),
      );
      expect(home.selected, isTrue);
      expect(home.fillWhenSelected, isTrue);
      expect(home.showDropdownArrow, isFalse);
      expect(work.selected, isFalse);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('a tap reports the option value', (tester) async {
      Object? picked;
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.choiceChips,
          label: 'Save address as',
          initialValue: 'Home',
          onChanged: (value) => picked = value,
        ).build(
          choiceChipsConfig: const ChoiceChipsConfig(
            options: options,
            keyPrefix: 'test_label',
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('test_label_work')));
      expect(picked, 'Work');
    });

    testWidgets('shows errorText, and enabled: false blocks taps', (
      tester,
    ) async {
      Object? picked;
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.choiceChips,
          label: 'Kind',
          onChanged: (value) => picked = value,
        ).build(
          choiceChipsConfig: const ChoiceChipsConfig(
            options: options,
            keyPrefix: 'test_label',
            enabled: false,
            errorText: 'Pick one',
          ),
        ),
      );

      expect(find.text('Pick one'), findsOneWidget);
      await tester.tap(find.byKey(const Key('test_label_work')));
      expect(picked, isNull);
    });
  });

  group('UFFType.dropdown', () {
    testWidgets('shows hintText, prefixIcon and errorText, and only the '
        'title as its label when withTitle', (tester) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.dropdown,
          label: 'State *',
          withTitle: true,
          onChanged: (_) {},
        ).build(
          dropdownConfig: const DropdownConfig(
            hintText: 'Select state',
            prefixIcon: Icons.location_on_outlined,
            errorText: 'Choose the state',
            dropdownOptions: [
              DropdownOption(key: 'Goa', value: 'Goa'),
              DropdownOption(key: 'Kerala', value: 'Kerala'),
            ],
          ),
        ),
      );

      expect(find.text('STATE *'), findsOneWidget);
      expect(find.text('State *'), findsNothing);
      expect(find.text('Select state'), findsOneWidget);
      expect(find.text('Choose the state'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });
  });

  group('UFFType.text', () {
    testWidgets('suffix shows a widget at the end of the field', (
      tester,
    ) async {
      await pumpField(
        tester,
        UniversalFormField(
          fieldType: UFFType.text,
          label: 'Phone number',
          withTitle: true,
          initialValue: '+919876543210',
          onChanged: (_) {},
        ).build(
          textInputConfig: const TextInputConfig(
            readOnly: true,
            suffix: Text('Locked', key: Key('suffix')),
          ),
        ),
      );

      expect(find.byKey(const Key('suffix')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('suffix'))).dx,
        greaterThan(tester.getTopRight(find.text('+919876543210')).dx),
      );
    });
  });
}
