import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/app_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: card)),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('shows its child on the theme surface with the default '
      'padding', (tester) async {
    await pumpCard(tester, const AppCard(child: Text('Joined')));

    expect(find.text('Joined'), findsOneWidget);
    expect(
      decorationOf(tester).color,
      AppTheme.dark.colorScheme.surfaceContainerLow,
    );
    final padding = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(padding.padding, const EdgeInsets.all(20));
  });

  testWidgets('padding: zero lets rows reach the edges', (tester) async {
    await pumpCard(
      tester,
      Builder(
        builder: (context) => AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('One'),
              AppCard.divider(context),
              const Text('Two'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
    expect(
      tester
          .widget<Container>(
            find
                .descendant(
                  of: find.byType(AppCard),
                  matching: find.byType(Container),
                )
                .first,
          )
          .padding,
      EdgeInsets.zero,
    );
  });

  testWidgets('a title opens the card with a tappable header row', (
    tester,
  ) async {
    var taps = 0;
    await pumpCard(
      tester,
      AppCard(
        title: 'Items (1)',
        icon: Icons.shopping_bag_outlined,
        trailing: const Text('Hide'),
        headerKey: const Key('header'),
        onHeaderTap: () => taps++,
        child: const Text('Seaweed'),
      ),
    );

    expect(find.text('Items (1)'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Seaweed')).dy,
      greaterThan(tester.getBottomLeft(find.text('Items (1)')).dy),
    );

    await tester.tap(find.byKey(const Key('header')));
    expect(taps, 1);
  });

  testWidgets('an accent colours the outline and a strip on the left', (
    tester,
  ) async {
    const accent = Color(0xFFE57373);
    await pumpCard(
      tester,
      const AppCard(accent: accent, child: Text('Cancelled')),
    );

    final border = decorationOf(tester).border! as Border;
    expect(border.top.color, accent.withValues(alpha: 0.4));
    expect(
      find.byWidgetPredicate((w) => w is ColoredBox && w.color == accent),
      findsOneWidget,
    );
  });
}
