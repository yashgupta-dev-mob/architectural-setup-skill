import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/app_network_image.dart';

void main() {
  Future<void> pumpImage(WidgetTester tester, AppNetworkImage image) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Center(child: SizedBox(width: 120, height: 80, child: image)),
      ),
    );
  }

  testWidgets('a missing or empty URL shows the placeholder only', (
    tester,
  ) async {
    await pumpImage(tester, const AppNetworkImage(url: null));
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    await pumpImage(
      tester,
      const AppNetworkImage(url: '', placeholderIcon: Icons.eco_outlined),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
  });

  testWidgets('a URL loads through the cache, decoded at the drawn size', (
    tester,
  ) async {
    await pumpImage(
      tester,
      const AppNetworkImage(url: 'https://cdn.example.com/neem.jpg'),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://cdn.example.com/neem.jpg');
    expect(image.fit, BoxFit.cover);
    // The longest side of the 120 x 80 box at 3x.
    expect(image.memCacheWidth, 360);
    // The placeholder shows while the image loads.
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('an explicit size is used for decoding and the placeholder', (
    tester,
  ) async {
    await pumpImage(
      tester,
      const AppNetworkImage(
        url: 'https://cdn.example.com/neem.jpg',
        width: 40,
        height: 40,
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 120);
    expect(image.width, 40);
    expect(image.height, 40);
  });
}
