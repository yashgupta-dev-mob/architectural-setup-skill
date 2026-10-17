// GENERIC: the source app's test; the display font is optional per app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/page_header.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, PageHeader header) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Column(children: [header])),
      ),
    );
  }

  testWidgets('shows the title in the display font, and the subtitle', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      PageHeader(
        title: 'My Wishlist',
        subtitle: '2 items saved',
        subtitleKey: const Key('subtitle'),
        onBack: () {},
      ),
    );

    final title = tester.widget<Text>(find.text('My Wishlist'));
    if (AppTheme.displayFontFamily != null) {
      expect(title.style?.fontFamily, AppTheme.displayFontFamily);
    }
    expect(title.style?.fontWeight, FontWeight.w400);
    expect(find.text('2 items saved'), findsOneWidget);
    expect(find.byKey(const Key('subtitle')), findsOneWidget);
  });

  testWidgets('has no second line without a subtitle', (tester) async {
    await pumpHeader(tester, PageHeader(title: 'Your Cart', onBack: () {}));

    expect(find.byType(Text), findsOneWidget);
  });

  for (final textScale in [1.0, 1.1]) {
    testWidgets('is the same height with or without a subtitle, and centres '
        'a lone title, at text scale $textScale', (tester) async {
      Future<void> pump(PageHeader header) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: Column(children: [header])),
          ),
        ),
      );

      // As on the wishlist: a subtitle and a badge at the end.
      await pump(
        PageHeader(
          title: 'My Wishlist',
          subtitle: '2 items saved · hold a card to remove',
          onBack: () {},
          trailing: const SizedBox.square(dimension: 40),
        ),
      );
      final withSubtitle = tester.getSize(find.byType(PageHeader));

      // As on the cart: a title only.
      await pump(PageHeader(title: 'Your Cart', onBack: () {}));
      final titleOnly = tester.getSize(find.byType(PageHeader));

      expect(titleOnly.height, withSubtitle.height);
      expect(
        tester.getCenter(find.text('Your Cart')).dy,
        moreOrLessEquals(
          tester.getCenter(find.byTooltip('Back')).dy,
          epsilon: 0.5,
        ),
      );
    });
  }

  testWidgets('the back button calls onBack and takes backKey', (tester) async {
    var backs = 0;
    await pumpHeader(
      tester,
      PageHeader(
        title: 'Your Cart',
        backKey: const Key('back'),
        onBack: () => backs++,
      ),
    );

    await tester.tap(find.byKey(const Key('back')));

    expect(backs, 1);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('shows the trailing widget after the title', (tester) async {
    await pumpHeader(
      tester,
      PageHeader(
        title: 'Your Cart',
        onBack: () {},
        trailing: const Text('2 items'),
      ),
    );

    expect(
      tester.getCenter(find.text('2 items')).dx,
      greaterThan(tester.getCenter(find.text('Your Cart')).dx),
    );
  });

  testWidgets('a long title is cut short rather than overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpHeader(
      tester,
      PageHeader(
        title: 'A very long page title that cannot fit on one line',
        subtitle: 'And a subtitle that is far too long to fit as well',
        onBack: () {},
        trailing: const Icon(Icons.favorite_rounded),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the bottom widget under the row and grows by it', (
    tester,
  ) async {
    await pumpHeader(tester, PageHeader(title: 'My Orders', onBack: () {}));
    final plain = tester.getSize(find.byType(PageHeader)).height;

    await pumpHeader(
      tester,
      PageHeader(
        title: 'My Orders',
        onBack: () {},
        bottom: const SizedBox(height: 40, child: Text('Tabs')),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Tabs')).dy,
      greaterThan(tester.getBottomLeft(find.text('My Orders')).dy),
    );
    expect(
      tester.getSize(find.byType(PageHeader)).height,
      greaterThanOrEqualTo(plain + 40),
    );
  });
}
