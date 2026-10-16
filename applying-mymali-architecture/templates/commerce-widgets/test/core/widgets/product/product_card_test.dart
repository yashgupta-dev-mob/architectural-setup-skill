// GENERIC: MyMali's test with room for the app's own type scale.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/product/product_card.dart';
import 'package:mymali/core/widgets/product/quantity_stepper.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    ProductCard card, {
    double width = 180,
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => SizedBox(
                  width: width,
                  height: width + ProductCard.detailsHeightFor(context),
                  child: card,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final textScale in [1.0, 1.1]) {
    testWidgets('the fullest card fills its height at text scale $textScale', (
      tester,
    ) async {
      await pumpCard(
        tester,
        ProductCard(
          testId: 'p1',
          title: 'Activated Neem Oil',
          subtitle: 'Cold pressed',
          price: 269,
          mrp: 595,
          variantLabel: '250 ml',
          quantity: 1,
          onIncrement: () {},
          onDecrement: () {},
        ),
        textScale: textScale,
      );

      // No overflow, and no empty band left under the price row.
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(ProductCard));
      final stepper = tester.getRect(find.byType(QuantityStepper));
      final price = tester.getRect(find.text('MRP ₹595'));
      final contentBottom = stepper.bottom > price.bottom
          ? stepper.bottom
          : price.bottom;
      expect(card.bottom - contentBottom, inInclusiveRange(8, 32));
    });
  }

  bool isCutOff(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

  testWidgets('a narrow tile keeps badges whole and ADD beside the price', (
    tester,
  ) async {
    // A 360 dp phone gives two-column tiles of about 157 dp.
    await pumpCard(
      tester,
      ProductCard(
        testId: 'p1',
        title: '3-in-1 Organic Pesticide',
        price: 319,
        mrp: 595,
        discountPercent: 46,
        soldCount: 16,
        variantLabel: '250 ml',
        onAdd: () {},
      ),
      width: 150,
    );

    expect(tester.takeException(), isNull);
    expect(isCutOff(tester, '46% OFF'), isFalse);
    expect(isCutOff(tester, '16 sold'), isFalse);

    final card = tester.getRect(find.byType(ProductCard));
    expect(tester.getRect(find.text('16 sold')).right, lessThan(card.right));

    final price = tester.getRect(find.text('₹319'));
    final add = tester.getRect(find.byKey(const Key('product_p1_add')));
    expect(add.left, greaterThan(price.right));
    expect(add.top, lessThan(price.bottom));
    expect(add.bottom, greaterThan(price.top));
  });

  testWidgets('a narrow tile fits the stepper beside the price', (
    tester,
  ) async {
    await pumpCard(
      tester,
      ProductCard(
        testId: 'p1',
        title: 'Spinach Seeds',
        price: 99,
        mrp: 110,
        quantity: 1,
        onIncrement: () {},
        onDecrement: () {},
      ),
      width: 150,
    );

    expect(tester.takeException(), isNull);
    final price = tester.getRect(find.text('₹99'));
    final plus = tester.getRect(find.byKey(const Key('product_p1_increment')));
    expect(plus.left, greaterThan(price.right));
    expect(plus.top, lessThan(price.bottom));
  });

  testWidgets('shows price, MRP, badges and an ADD button', (tester) async {
    var added = 0;
    await pumpCard(
      tester,
      ProductCard(
        testId: 'p1',
        title: 'Activated Neem Oil',
        subtitle: 'Cold pressed',
        price: 269,
        mrp: 595,
        discountPercent: 55,
        soldCount: 12,
        variantLabel: '250 ml',
        onAdd: () => added++,
      ),
    );

    expect(find.text('Activated Neem Oil'), findsOneWidget);
    expect(find.text('₹269'), findsOneWidget);
    expect(find.text('MRP ₹595'), findsOneWidget);
    expect(find.text('55% OFF'), findsOneWidget);
    expect(find.text('12 sold'), findsOneWidget);
    expect(find.text('250 ml'), findsOneWidget);
    expect(find.text('In Stock'), findsOneWidget);
    expect(find.byType(QuantityStepper), findsNothing);

    await tester.tap(find.byKey(const Key('product_p1_add')));
    expect(added, 1);
  });

  testWidgets('shows the stepper once there is a quantity', (tester) async {
    var up = 0;
    var down = 0;
    await pumpCard(
      tester,
      ProductCard(
        testId: 'p1',
        title: 'Spinach Seeds',
        price: 99,
        quantity: 2,
        onIncrement: () => up++,
        onDecrement: () => down++,
      ),
    );

    expect(find.byKey(const Key('product_p1_add')), findsNothing);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('product_p1_increment')));
    await tester.tap(find.byKey(const Key('product_p1_decrement')));
    expect(up, 1);
    expect(down, 1);
  });

  testWidgets('out of stock disables ADD; coming soon hides it', (
    tester,
  ) async {
    await pumpCard(
      tester,
      ProductCard(
        testId: 'p1',
        title: 'Vermiwash',
        price: 450,
        inStock: false,
        onAdd: () {},
      ),
    );
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('MRP ₹450'), findsNothing);

    await pumpCard(
      tester,
      ProductCard(
        testId: 'p2',
        title: 'Sprouter',
        price: 150,
        isComingSoon: true,
        onAdd: () {},
      ),
    );
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byKey(const Key('product_p2_add')), findsNothing);
  });
}
