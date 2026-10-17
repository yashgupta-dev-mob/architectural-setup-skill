import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/buttons/primary_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, PrimaryButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  testWidgets('fills the width by default', (tester) async {
    await pumpButton(
      tester,
      PrimaryButton(label: 'Continue', onPressed: () {}),
    );

    expect(tester.getSize(find.byType(PrimaryButton)).width, 800);
    expect(tester.getSize(find.byType(PrimaryButton)).height, 56);
  });

  testWidgets('expand: false is only as wide as its content', (tester) async {
    await pumpButton(
      tester,
      PrimaryButton(
        label: 'Browse products',
        leadingIcon: Icons.shopping_bag_outlined,
        height: 48,
        expand: false,
        onPressed: () {},
      ),
    );

    final size = tester.getSize(find.byType(PrimaryButton));
    expect(size.height, 48);
    // The test surface is 800 wide.
    expect(size.width, lessThan(400));
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    // The leading icon sits before the label.
    expect(
      tester.getCenter(find.byIcon(Icons.shopping_bag_outlined)).dx,
      lessThan(tester.getCenter(find.text('Browse products')).dx),
    );
  });

  testWidgets('a content-width button keeps its width while loading', (
    tester,
  ) async {
    await pumpButton(
      tester,
      PrimaryButton(label: 'Browse products', expand: false, onPressed: () {}),
    );
    final idle = tester.getSize(find.byType(PrimaryButton));

    await pumpButton(
      tester,
      PrimaryButton(
        label: 'Browse products',
        expand: false,
        isLoading: true,
        onPressed: () {},
      ),
    );

    expect(tester.getSize(find.byType(PrimaryButton)), idle);
  });

  testWidgets('a tap calls onPressed; null or loading blocks it', (
    tester,
  ) async {
    var taps = 0;
    await pumpButton(
      tester,
      PrimaryButton(label: 'Go', expand: false, onPressed: () => taps++),
    );
    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 1);

    await pumpButton(
      tester,
      PrimaryButton(
        label: 'Go',
        expand: false,
        isLoading: true,
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 1);

    await pumpButton(
      tester,
      const PrimaryButton(label: 'Go', expand: false, onPressed: null),
    );
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('warm uses the peach colour instead of the brand one', (
    tester,
  ) async {
    Color fill() => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(PrimaryButton),
            matching: find.byType(Material),
          ),
        )
        .color!;
    final colors = AppTheme.light.colorScheme;

    await pumpButton(tester, PrimaryButton(label: 'Apply', onPressed: () {}));
    expect(fill(), colors.primary);

    await pumpButton(
      tester,
      PrimaryButton(label: 'Apply', warm: true, onPressed: () {}),
    );
    expect(fill(), colors.tertiaryContainer);
    expect(
      tester.widget<Text>(find.text('Apply')).style?.color,
      colors.onTertiaryContainer,
    );
  });
}
