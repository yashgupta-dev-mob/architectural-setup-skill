import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/app_network_image.dart';
import 'package:mymali/core/widgets/buttons/heart_toggle_button.dart';
import 'package:mymali/core/widgets/chips/info_chip.dart';
import 'package:mymali/core/widgets/product/product_list_tile.dart';
import 'package:mymali/core/widgets/product/quantity_stepper.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    ProductListTile tile, {
    double width = 358,
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: tile),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the caption, title, prices and discount ribbon', (
    tester,
  ) async {
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        caption: 'Vegetable Seeds',
        title: 'Green Chilli Seeds (Pusa)',
        imageUrl: 'https://cdn.example.com/chilli.jpg',
        price: 89,
        mrp: 110,
        discountPercent: 19,
        onAdd: () {},
        onWishlistPressed: () {},
      ),
    );

    expect(find.text('VEGETABLE SEEDS'), findsOneWidget);
    expect(find.text('Green Chilli Seeds (Pusa)'), findsOneWidget);
    expect(find.text('₹89'), findsOneWidget);
    expect(find.text('₹110'), findsOneWidget);
    expect(find.text('19% OFF'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .imageUrl,
      'https://cdn.example.com/chilli.jpg',
    );
  });

  testWidgets('hides the MRP and the ribbon when there is no discount', (
    tester,
  ) async {
    await pumpTile(
      tester,
      ProductListTile(testId: 'p1', title: 'Radish', price: 99, mrp: 99),
    );

    expect(find.text('₹99'), findsOneWidget);
    expect(find.textContaining('OFF'), findsNothing);
  });

  for (final textScale in [1.0, 1.1]) {
    testWidgets('a long title wraps to two lines without overflowing at '
        'text scale $textScale', (tester) async {
      await pumpTile(
        tester,
        ProductListTile(
          testId: 'p1',
          caption: 'Vegetable Seeds',
          title: 'Radish White Long Seeds (Mino Early) for kitchen gardens',
          price: 99,
          mrp: 110,
          discountPercent: 10,
          quantity: 1,
          onIncrement: () {},
          onDecrement: () {},
          onWishlistPressed: () {},
        ),
        width: 320,
        textScale: textScale,
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Add to cart calls onAdd', (tester) async {
    var adds = 0;
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        onAdd: () => adds++,
      ),
    );

    await tester.tap(find.byKey(const Key('product_p1_add')));

    expect(adds, 1);
    expect(find.byType(QuantityStepper), findsNothing);
  });

  testWidgets('a quantity shows the filled stepper with a bin at one', (
    tester,
  ) async {
    var quantity = 1;
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        quantity: quantity,
        onIncrement: () => quantity++,
        onDecrement: () => quantity--,
      ),
    );

    final stepper = tester.widget<QuantityStepper>(
      find.byType(QuantityStepper),
    );
    expect(stepper.filled, isTrue);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.text('Add to cart'), findsNothing);

    await tester.tap(find.byKey(const Key('product_p1_increment')));
    expect(quantity, 2);
    await tester.tap(find.byKey(const Key('product_p1_decrement')));
    expect(quantity, 1);
  });

  testWidgets('out of stock disables the add button', (tester) async {
    var adds = 0;
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        inStock: false,
        onAdd: () => adds++,
      ),
    );

    await tester.tap(find.byKey(const Key('product_p1_add')));

    expect(adds, 0);
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('coming soon has no add control', (tester) async {
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        isComingSoon: true,
        onAdd: () {},
      ),
    );

    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byKey(const Key('product_p1_add')), findsNothing);
  });

  testWidgets('the heart reflects isWishlisted and calls onWishlistPressed', (
    tester,
  ) async {
    var taps = 0;
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        isWishlisted: true,
        onWishlistPressed: () => taps++,
      ),
    );

    final heart = find.byKey(const Key('product_p1_wishlist'));
    expect(tester.widget<HeartToggleButton>(heart).isActive, isTrue);
    expect(tester.widget<HeartToggleButton>(heart).overImage, isFalse);

    await tester.tap(heart);
    expect(taps, 1);
  });

  testWidgets('wishlistKey replaces the default heart key', (tester) async {
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        wishlistKey: const Key('custom_heart'),
        onWishlistPressed: () {},
      ),
    );

    expect(find.byKey(const Key('custom_heart')), findsOneWidget);
    expect(find.byKey(const Key('product_p1_wishlist')), findsNothing);
  });

  testWidgets('there is no heart without onWishlistPressed', (tester) async {
    await pumpTile(
      tester,
      const ProductListTile(testId: 'p1', title: 'Radish', price: 99),
    );

    expect(find.byType(HeartToggleButton), findsNothing);
  });

  group('cart rows', () {
    testWidgets('keyPrefix replaces the leading "product" of the keys', (
      tester,
    ) async {
      var quantity = 2;
      await pumpTile(
        tester,
        ProductListTile(
          keyPrefix: 'cart_line',
          testId: 'v1',
          title: 'Radish',
          price: 198,
          quantity: quantity,
          onIncrement: () => quantity++,
          onDecrement: () => quantity--,
        ),
      );

      await tester.tap(find.byKey(const Key('cart_line_v1_increment')));
      expect(quantity, 3);
      await tester.tap(find.byKey(const Key('cart_line_v1_decrement')));
      expect(quantity, 2);
      expect(find.byKey(const Key('product_v1_increment')), findsNothing);
    });

    testWidgets('shows the variant chip and the price note', (tester) async {
      await pumpTile(
        tester,
        const ProductListTile(
          testId: 'v1',
          title: 'Radish',
          variantLabel: '4.5 g',
          priceNote: '₹99 × 2',
          price: 198,
        ),
      );

      expect(find.widgetWithText(InfoChip, '4.5 g'), findsOneWidget);
      expect(find.text('₹99 × 2'), findsOneWidget);
      // The note sits above the price.
      expect(
        tester.getCenter(find.text('₹99 × 2')).dy,
        lessThan(tester.getCenter(find.text('₹198')).dy),
      );
    });

    testWidgets('imageSize sets the thumbnail', (tester) async {
      await pumpTile(
        tester,
        const ProductListTile(
          testId: 'v1',
          title: 'Radish',
          price: 99,
          imageSize: 56,
        ),
      );

      expect(
        tester.getSize(find.byType(AppNetworkImage)),
        const Size.square(56),
      );
    });

    testWidgets('framed: false has no card of its own', (tester) async {
      await pumpTile(
        tester,
        const ProductListTile(testId: 'v1', title: 'Radish', price: 99),
      );
      Material card() => tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ProductListTile),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(card().type, MaterialType.canvas);
      expect(card().shape, isNotNull);

      await pumpTile(
        tester,
        const ProductListTile(
          testId: 'v1',
          title: 'Radish',
          price: 99,
          framed: false,
        ),
      );
      expect(card().type, MaterialType.transparency);
      expect(card().shape, isNull);
    });

    testWidgets('besidePrice puts the stepper at the end of the price row', (
      tester,
    ) async {
      await pumpTile(
        tester,
        ProductListTile(
          testId: 'v1',
          title: 'Radish',
          price: 198,
          quantity: 2,
          controlPlacement: ProductListTileControl.besidePrice,
          onIncrement: () {},
          onDecrement: () {},
        ),
      );

      final price = tester.getRect(find.text('₹198'));
      final stepper = tester.getRect(find.byType(QuantityStepper));
      expect(stepper.left, greaterThan(price.right));
      expect(stepper.bottom, moreOrLessEquals(price.bottom, epsilon: 6));
    });

    testWidgets('the text action shows its icon and calls onAction', (
      tester,
    ) async {
      var actions = 0;
      await pumpTile(
        tester,
        ProductListTile(
          testId: 'v1',
          title: 'Radish',
          price: 99,
          quantity: 1,
          controlPlacement: ProductListTileControl.besidePrice,
          actionLabel: 'Save for later',
          actionIcon: Icons.favorite_border_rounded,
          actionKey: const Key('save'),
          onAction: () => actions++,
          onIncrement: () {},
          onDecrement: () {},
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      // Under the price, not beside it.
      expect(
        tester.getCenter(find.text('Save for later')).dy,
        greaterThan(tester.getRect(find.text('₹99')).bottom),
      );

      await tester.tap(find.byKey(const Key('save')));
      expect(actions, 1);
    });

    testWidgets('there is no text action without actionLabel', (tester) async {
      await pumpTile(
        tester,
        const ProductListTile(testId: 'v1', title: 'Radish', price: 99),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('trailing puts the add pill beside the title, with the '
        'action under it', (tester) async {
      var moves = 0;
      var removes = 0;
      await pumpTile(
        tester,
        ProductListTile(
          testId: 'v1',
          title: 'Green Chilli Seeds (Pusa)',
          price: 89,
          imageSize: 56,
          framed: false,
          controlPlacement: ProductListTileControl.trailing,
          addLabel: 'Move to cart',
          addIcon: Icons.shopping_cart_outlined,
          tonalAdd: true,
          addKey: const Key('move'),
          onAdd: () => moves++,
          actionLabel: 'Remove',
          actionKey: const Key('remove'),
          onAction: () => removes++,
        ),
      );

      final pill = tester.getRect(find.byKey(const Key('move')));
      final title = tester.getRect(find.text('Green Chilli Seeds (Pusa)'));
      final remove = tester.getRect(find.text('Remove'));
      expect(pill.left, greaterThan(title.right));
      expect(remove.top, greaterThanOrEqualTo(pill.bottom));
      expect(remove.left, greaterThan(title.right));
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.byKey(const Key('product_v1_add')), findsNothing);

      // Tonal: the soft container colour, not the brand colour.
      final colors = AppTheme.dark.colorScheme;
      expect(
        tester
            .widget<Material>(
              find.descendant(
                of: find.byKey(const Key('move')),
                matching: find.byType(Material),
              ),
            )
            .color,
        colors.primaryContainer,
      );

      await tester.tap(find.byKey(const Key('move')));
      await tester.tap(find.byKey(const Key('remove')));
      expect(moves, 1);
      expect(removes, 1);
    });

    for (final textScale in [1.0, 1.1]) {
      testWidgets('cart rows fit a narrow screen at text scale '
          '$textScale', (tester) async {
        await pumpTile(
          tester,
          ProductListTile(
            testId: 'v1',
            title: 'Radish White Long Seeds (Mino Early) for kitchen gardens',
            imageSize: 72,
            framed: false,
            variantLabel: '4.5 g',
            priceNote: '₹1,299 × 12',
            price: 15588,
            mrp: 18000,
            discountPercent: 13,
            quantity: 12,
            controlPlacement: ProductListTileControl.besidePrice,
            actionLabel: 'Save for later',
            actionIcon: Icons.favorite_border_rounded,
            onAction: () {},
            onIncrement: () {},
            onDecrement: () {},
          ),
          width: 296,
          textScale: textScale,
        );
        expect(tester.takeException(), isNull);

        await pumpTile(
          tester,
          ProductListTile(
            testId: 'v1',
            title: 'Radish White Long Seeds (Mino Early) for kitchen gardens',
            imageSize: 56,
            framed: false,
            priceNote: '₹1,299 × 12',
            price: 15588,
            controlPlacement: ProductListTileControl.trailing,
            addLabel: 'Move to cart',
            tonalAdd: true,
            onAdd: () {},
            actionLabel: 'Remove',
            onAction: () {},
          ),
          width: 296,
          textScale: textScale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('taps and long presses reach the callbacks', (tester) async {
    var taps = 0;
    var holds = 0;
    await pumpTile(
      tester,
      ProductListTile(
        testId: 'p1',
        title: 'Radish',
        price: 99,
        onTap: () => taps++,
        onLongPress: () => holds++,
      ),
    );

    await tester.tap(find.text('Radish'));
    await tester.longPress(find.text('Radish'));

    expect(taps, 1);
    expect(holds, 1);
  });
}
