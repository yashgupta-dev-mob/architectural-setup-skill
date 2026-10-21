// GENERIC: from KOHR; the image path is a placeholder (the test only
// checks which asset is asked for).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/app_header_bar.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, AppHeaderBar bar) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(appBar: bar),
      ),
    );
  }

  testWidgets('is a plain AppBar with the given title and actions', (
    tester,
  ) async {
    await pumpBar(
      tester,
      AppHeaderBar(
        title: const Text('Orders'),
        backgroundColor: const Color(0xff258046),
        actions: [IconButton(icon: const Icon(Icons.send), onPressed: () {})],
      ),
    );

    expect(find.text('Orders'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, const Color(0xff258046));
    expect(appBar.elevation, 0);
    expect(appBar.flexibleSpace, isNull);
    expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
  });

  testWidgets('draws the background image over its colour', (tester) async {
    await pumpBar(
      tester,
      const AppHeaderBar(
        title: Text('Orders'),
        backgroundImage: 'assets/header.png',
        imageColor: Color(0x80258046),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/header.png');
    expect(image.fit, BoxFit.cover);
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
      const Color(0x80258046),
    );
  });

  testWidgets('a custom leading button replaces the back button', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      AppHeaderBar(
        title: const Text('Orders'),
        leading: IconButton(
          key: const Key('bar_close'),
          icon: const Icon(Icons.close),
          onPressed: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('bar_close')));
    expect(tapped, isTrue);
  });

  testWidgets('fades the background image by imageOpacity', (tester) async {
    await pumpBar(
      tester,
      const AppHeaderBar(
        title: Text('Orders'),
        backgroundImage: 'assets/header.png',
        imageOpacity: 0.4,
      ),
    );

    expect(tester.widget<Image>(find.byType(Image)).opacity?.value, 0.4);
  });

  testWidgets('draws the image fully opaque by default', (tester) async {
    await pumpBar(
      tester,
      const AppHeaderBar(
        title: Text('Orders'),
        backgroundImage: 'assets/header.png',
      ),
    );

    expect(tester.widget<Image>(find.byType(Image)).opacity, isNull);
  });
}
