import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/icon_list_tile.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, IconListTile tile) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Column(children: [tile])),
      ),
    );
  }

  testWidgets('shows the icon, the title and the subtitle, and reports a '
      'tap', (tester) async {
    var taps = 0;
    await pumpTile(
      tester,
      IconListTile(
        icon: Icons.home_outlined,
        title: 'Home',
        subtitle: 'Y, Arera colony, Bhopal',
        onTap: () => taps++,
      ),
    );

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Y, Arera colony, Bhopal'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

    await tester.tap(find.byType(IconListTile));
    expect(taps, 1);
  });

  testWidgets('has no second line without a subtitle', (tester) async {
    await pumpTile(
      tester,
      IconListTile(icon: Icons.home_outlined, title: 'Home', onTap: () {}),
    );

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('showChevron adds a chevron at the end', (tester) async {
    await pumpTile(
      tester,
      IconListTile(
        icon: Icons.my_location_rounded,
        title: 'Use my current location',
        showChevron: true,
        onTap: () {},
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('frames the icon in a tile, a circle, or not at all', (
    tester,
  ) async {
    BoxDecoration? frame() {
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(IconListTile),
          matching: find.byType(Container),
        ),
      );
      return containers.isEmpty
          ? null
          : containers.first.decoration as BoxDecoration?;
    }

    Future<void> pump(IconListTileLeading leading) => pumpTile(
      tester,
      IconListTile(
        icon: Icons.home_outlined,
        title: 'Home',
        leading: leading,
        onTap: () {},
      ),
    );

    await pump(IconListTileLeading.tile);
    expect(frame()?.shape, BoxShape.rectangle);
    expect(frame()?.borderRadius, isNotNull);

    await pump(IconListTileLeading.circle);
    expect(frame()?.shape, BoxShape.circle);

    await pump(IconListTileLeading.plain);
    expect(frame(), isNull);
  });

  testWidgets('a null onTap disables the row', (tester) async {
    await pumpTile(
      tester,
      const IconListTile(icon: Icons.home_outlined, title: 'Home', onTap: null),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('isLoading shows progress in place of the chevron and blocks '
      'taps', (tester) async {
    var taps = 0;
    await pumpTile(
      tester,
      IconListTile(
        icon: Icons.my_location_rounded,
        title: 'Use my current location',
        showChevron: true,
        isLoading: true,
        onTap: () => taps++,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

    await tester.tap(find.byType(IconListTile));
    expect(taps, 0);
  });

  testWidgets('filled draws a brand-coloured card with light text', (
    tester,
  ) async {
    var taps = 0;
    await pumpTile(
      tester,
      IconListTile(
        icon: Icons.location_on_outlined,
        title: 'Use my current location',
        subtitle: 'Auto-fills pincode, city, district & state',
        showChevron: true,
        filled: true,
        onTap: () => taps++,
      ),
    );

    final colors = AppTheme.dark.colorScheme;
    final card = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(IconListTile),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(card.color, colors.primary);
    final title = tester.widget<Text>(find.text('Use my current location'));
    expect(title.style?.color, colors.onPrimary);

    await tester.tap(find.byType(IconListTile));
    expect(taps, 1);
  });

  testWidgets('badgeLabel shows a pill before the chevron', (tester) async {
    await pumpTile(
      tester,
      IconListTile(
        icon: Icons.event_outlined,
        title: 'My Bookings',
        badgeLabel: 'Soon',
        showChevron: true,
        onTap: () {},
      ),
    );

    expect(find.text('Soon'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Soon')).dx,
      lessThan(tester.getTopLeft(find.byIcon(Icons.chevron_right_rounded)).dx),
    );
  });

  testWidgets('dense makes the row shorter', (tester) async {
    Future<double> heightOf({required bool dense}) async {
      await pumpTile(
        tester,
        IconListTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Appearance, notifications & more',
          dense: dense,
          onTap: () {},
        ),
      );
      return tester.getSize(find.byType(IconListTile)).height;
    }

    final regular = await heightOf(dense: false);
    final dense = await heightOf(dense: true);

    expect(dense, lessThan(regular));
  });

  testWidgets('overline shows a caption above the title', (tester) async {
    await pumpTile(
      tester,
      IconListTile(
        icon: Icons.mail_outline_rounded,
        overline: 'Orders',
        title: 'orders@example.com',
        onTap: () {},
      ),
    );

    expect(find.text('Orders'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Orders')).dy,
      lessThan(tester.getTopLeft(find.text('orders@example.com')).dy),
    );
  });
}
