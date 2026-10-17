import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/cart/cart_summary_bar.dart';

void main() {
  testWidgets('shows the count and calls onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: CartSummaryBar(
              itemCount: 2,
              thumbnailUrls: const [null, null, null],
              onPressed: () => pressed++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('View cart'), findsOneWidget);
    expect(find.text('2 ITEMS'), findsOneWidget);

    await tester.tap(find.byType(CartSummaryBar));
    expect(pressed, 1);
  });

  testWidgets('uses the singular for one item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartSummaryBar(itemCount: 1, onPressed: () {})),
      ),
    );

    expect(find.text('1 ITEM'), findsOneWidget);
  });
}
