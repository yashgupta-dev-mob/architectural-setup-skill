import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/product/product_grid.dart';
import 'package:mymali/core/widgets/product/product_rail.dart';

void main() {
  const screenWidth = 390.0;

  Future<void> pumpRail(WidgetTester tester, {Widget? trailing}) async {
    tester.view.physicalSize = const Size(screenWidth * 3, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ProductRail(
              itemCount: 5,
              itemBuilder: (_, index) =>
                  ColoredBox(key: Key('tile_$index'), color: Colors.green),
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tiles are the size of a grid tile, in one row', (tester) async {
    await pumpRail(tester);

    const gridWidth = screenWidth - 32;
    final first = tester.getRect(find.byKey(const Key('tile_0')));
    final second = tester.getRect(find.byKey(const Key('tile_1')));

    expect(first.left, 16);
    expect(first.width, ProductGrid.tileWidthFor(gridWidth));
    expect(
      first.height,
      ProductGrid.tileHeightFor(
        tester.element(find.byType(ProductRail)),
        gridWidth,
      ),
    );
    expect(second.top, first.top);
    expect(second.left, first.right + ProductGrid.spacing);
  });

  testWidgets('scrolls sideways to a narrower trailing tile', (tester) async {
    await pumpRail(
      tester,
      trailing: const ColoredBox(key: Key('trailing'), color: Colors.blue),
    );
    expect(find.byKey(const Key('trailing')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('trailing')),
      200,
      scrollable: find.descendant(
        of: find.byType(ProductRail),
        matching: find.byType(Scrollable),
      ),
    );
    // Run the list to its end, so the trailing tile is fully laid out.
    await tester.drag(find.byType(ProductRail), const Offset(-2000, 0));
    await tester.pumpAndSettle();

    final trailing = tester.getRect(find.byKey(const Key('trailing')));
    expect(
      trailing.width,
      closeTo(
        ProductGrid.tileWidthFor(screenWidth - 32) *
            ProductRail.trailingWidthFactor,
        0.01,
      ),
    );
    expect(trailing.right, closeTo(screenWidth - 16, 0.01));
  });
}
