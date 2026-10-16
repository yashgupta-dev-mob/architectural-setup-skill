import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/app_network_image.dart';
import 'package:mymali/core/widgets/product/explore_more_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    ExploreMoreCard card, {
    double width = 148,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: 370, child: card),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the labels and calls onTap anywhere on the card', (
    tester,
  ) async {
    var taps = 0;
    await pumpCard(
      tester,
      ExploreMoreCard(countLabel: '+15 products', onTap: () => taps++),
    );

    expect(find.text('Explore more'), findsOneWidget);
    expect(find.text('+15 products'), findsOneWidget);
    expect(find.byType(AppNetworkImage), findsNothing);

    await tester.tap(find.byType(ExploreMoreCard));
    expect(taps, 1);
  });

  testWidgets('shows at most three thumbnails and fits a narrow tile', (
    tester,
  ) async {
    await pumpCard(
      tester,
      ExploreMoreCard(
        countLabel: '+120 products',
        imageUrls: const [null, '', null, null, null],
        onTap: () {},
      ),
      width: 125,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byType(AppNetworkImage),
      findsNWidgets(ExploreMoreCard.maxThumbnails),
    );
  });
}
