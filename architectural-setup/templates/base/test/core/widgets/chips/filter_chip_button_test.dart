import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/chips/filter_chip_button.dart';

void main() {
  final colors = AppTheme.dark.colorScheme;

  Future<void> pumpChip(WidgetTester tester, FilterChipButton chip) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: chip)),
      ),
    );
  }

  Material pill(WidgetTester tester) => tester.widget<Material>(
    find.descendant(
      of: find.byType(FilterChipButton),
      matching: find.byType(Material),
    ),
  );

  testWidgets('shows its label, icon and arrow, and reports taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpChip(
      tester,
      FilterChipButton(
        label: 'Sort',
        icon: Icons.auto_awesome_outlined,
        onPressed: () => taps++,
      ),
    );

    expect(find.text('Sort'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    await tester.tap(find.byType(FilterChipButton));
    expect(taps, 1);
  });

  testWidgets('selected highlights only the border by default', (tester) async {
    await pumpChip(
      tester,
      FilterChipButton(label: 'Sort', selected: true, onPressed: () {}),
    );

    expect((pill(tester).shape! as StadiumBorder).side.color, colors.primary);
    expect(pill(tester).color, colors.surfaceContainerHigh);
  });

  testWidgets('fillWhenSelected tints the pill only while selected', (
    tester,
  ) async {
    await pumpChip(
      tester,
      FilterChipButton(
        label: 'Full Sun',
        showDropdownArrow: false,
        selected: true,
        fillWhenSelected: true,
        onPressed: () {},
      ),
    );
    expect(pill(tester).color, colors.primaryContainer);
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);

    await pumpChip(
      tester,
      FilterChipButton(
        label: 'Full Sun',
        fillWhenSelected: true,
        onPressed: () {},
      ),
    );
    expect(pill(tester).color, colors.surfaceContainerHigh);
  });

  testWidgets('onHeader: see-through on the header, filled with its text '
      'colour when selected', (tester) async {
    await pumpChip(
      tester,
      FilterChipButton(
        label: 'All',
        showDropdownArrow: false,
        onHeader: true,
        selected: true,
        onPressed: () {},
      ),
    );
    expect(pill(tester).color, colors.onPrimaryContainer);

    await pumpChip(
      tester,
      FilterChipButton(
        label: 'Active',
        showDropdownArrow: false,
        onHeader: true,
        onPressed: () {},
      ),
    );
    expect(
      pill(tester).color,
      colors.onPrimaryContainer.withValues(alpha: 0.12),
    );
  });
}
