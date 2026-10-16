import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/product/order_line_tile.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, OrderLineTile tile) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: tile),
      ),
    );
  }

  testWidgets('shows the title, "qty × price" and the line total', (
    tester,
  ) async {
    await pumpTile(
      tester,
      const OrderLineTile(
        title: 'Seaweed Extract',
        quantity: 2,
        unitPrice: 1249,
        total: 2498,
        imageUrl: 'https://img/sea.png',
      ),
    );

    expect(find.text('Seaweed Extract'), findsOneWidget);
    expect(find.text('2 × ₹1,249'), findsOneWidget);
    expect(find.text('₹2,498'), findsOneWidget);
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .imageUrl,
      'https://img/sea.png',
    );
  });

  testWidgets('without a picture it shows the placeholder', (tester) async {
    await pumpTile(
      tester,
      const OrderLineTile(
        title: 'Neem Oil',
        quantity: 1,
        unitPrice: 269,
        total: 269,
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
  });
}
