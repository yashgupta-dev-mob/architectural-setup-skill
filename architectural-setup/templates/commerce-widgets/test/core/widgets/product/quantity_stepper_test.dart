import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/product/quantity_stepper.dart';

void main() {
  Future<void> pumpStepper(WidgetTester tester, QuantityStepper stepper) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: stepper)),
      ),
    );
  }

  ColorScheme colorsOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(QuantityStepper))).colorScheme;

  Material surfaceOf(WidgetTester tester) => tester.widget<Material>(
    find
        .descendant(
          of: find.byType(QuantityStepper),
          matching: find.byType(Material),
        )
        .first,
  );

  testWidgets('shows the quantity and steps both ways', (tester) async {
    var quantity = 2;
    await pumpStepper(
      tester,
      QuantityStepper(
        quantity: quantity,
        incrementKey: const Key('plus'),
        decrementKey: const Key('minus'),
        onIncrement: () => quantity++,
        onDecrement: () => quantity--,
      ),
    );

    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus')));
    expect(quantity, 3);
    await tester.tap(find.byKey(const Key('minus')));
    expect(quantity, 2);
  });

  testWidgets('a null onIncrement greys "+" out and ignores taps', (
    tester,
  ) async {
    var decrements = 0;
    await pumpStepper(
      tester,
      QuantityStepper(
        quantity: 4,
        incrementKey: const Key('plus'),
        decrementKey: const Key('minus'),
        onIncrement: null,
        onDecrement: () => decrements++,
      ),
    );

    Color iconColor(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color!;
    final foreground = colorsOf(tester).secondary;

    expect(iconColor(Icons.add_rounded), foreground.withValues(alpha: 0.38));
    expect(iconColor(Icons.remove_rounded), foreground);

    await tester.tap(find.byKey(const Key('plus')));
    await tester.tap(find.byKey(const Key('minus')));
    expect(decrements, 1);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a disabled button keeps its tap from a tappable parent', (
    tester,
  ) async {
    var rowTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: InkWell(
              onTap: () => rowTaps++,
              child: const QuantityStepper(
                quantity: 3,
                incrementKey: Key('plus'),
                onIncrement: null,
                onDecrement: null,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('plus')));
    await tester.pump();

    expect(rowTaps, 0);
  });

  testWidgets('by default it is a tonal box with a minus at one', (
    tester,
  ) async {
    await pumpStepper(
      tester,
      QuantityStepper(quantity: 1, onIncrement: () {}, onDecrement: () {}),
    );

    expect(surfaceOf(tester).color, colorsOf(tester).surfaceContainerHigh);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('filled is a brand-coloured pill', (tester) async {
    await pumpStepper(
      tester,
      QuantityStepper(
        quantity: 2,
        filled: true,
        height: 30,
        onIncrement: () {},
        onDecrement: () {},
      ),
    );

    final surface = surfaceOf(tester);
    expect(surface.color, colorsOf(tester).primary);
    expect(surface.shape, const StadiumBorder());
    expect(tester.getSize(find.byType(QuantityStepper)).height, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removeAtOne shows a bin at one and a minus above it', (
    tester,
  ) async {
    await pumpStepper(
      tester,
      QuantityStepper(
        quantity: 1,
        removeAtOne: true,
        onIncrement: () {},
        onDecrement: () {},
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsNothing);

    await pumpStepper(
      tester,
      QuantityStepper(
        quantity: 2,
        removeAtOne: true,
        onIncrement: () {},
        onDecrement: () {},
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
  });

  testWidgets('shows a caption under the quantity when given', (tester) async {
    await pumpStepper(
      tester,
      QuantityStepper(
        quantity: 5,
        caption: 'IN CART',
        filled: true,
        onIncrement: () {},
        onDecrement: () {},
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('IN CART'), findsOneWidget);
  });

  testWidgets('shows no caption by default', (tester) async {
    await pumpStepper(
      tester,
      QuantityStepper(quantity: 5, onIncrement: () {}, onDecrement: () {}),
    );

    expect(find.byType(Column), findsNothing);
  });
}
