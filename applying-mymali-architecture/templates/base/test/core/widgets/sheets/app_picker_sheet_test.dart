import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/sheets/app_picker_sheet.dart';
import 'package:mymali/core/widgets/sheets/option_tile.dart';

void main() {
  /// Pumps a page whose button opens a sheet of two options; the picked
  /// one lands in [results].
  Future<void> openSheet(
    WidgetTester tester,
    List<String?> results, {
    Widget? footer,
    bool withIcon = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                results.add(
                  await AppPickerSheet.show<String>(
                    context,
                    builder: (sheetContext) => AppPickerSheet(
                      title: 'Sort by',
                      icon: withIcon ? Icons.auto_awesome_outlined : null,
                      footer: footer,
                      child: Column(
                        children: [
                          for (final option in const ['Newest', 'Alphabetical'])
                            OptionTile(
                              label: option,
                              selected: option == 'Newest',
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(option),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title, icon, choices and footer', (tester) async {
    await openSheet(tester, [], footer: const Text('Footer'));

    expect(find.text('Sort by'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byType(OptionTile), findsNWidgets(2));
    expect(find.text('Footer'), findsOneWidget);
  });

  testWidgets('completes with the value a choice pops', (tester) async {
    final results = <String?>[];
    await openSheet(tester, results);

    await tester.tap(find.text('Alphabetical'));
    await tester.pumpAndSettle();

    expect(results, ['Alphabetical']);
    expect(find.text('Sort by'), findsNothing);
  });

  testWidgets('the close button completes with null', (tester) async {
    final results = <String?>[];
    await openSheet(tester, results);

    await tester.tap(find.byKey(AppPickerSheet.closeKey));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(find.text('Sort by'), findsNothing);
  });

  group('OptionTile', () {
    Future<void> pumpTile(WidgetTester tester, OptionTile tile) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: Center(child: tile)),
        ),
      );
    }

    Color fillOf(WidgetTester tester) => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(OptionTile),
            matching: find.byType(Material),
          ),
        )
        .color!;

    testWidgets('the selected one is tinted', (tester) async {
      final colors = AppTheme.dark.colorScheme;
      await pumpTile(
        tester,
        OptionTile(label: 'Newest', selected: true, onTap: () {}),
      );

      expect(fillOf(tester), colors.primaryContainer);

      await pumpTile(
        tester,
        OptionTile(label: 'Newest', selected: false, onTap: () {}),
      );
      expect(fillOf(tester), colors.surfaceContainerHigh);
    });

    testWidgets('reports taps, and a null onTap disables it', (tester) async {
      var taps = 0;
      await pumpTile(
        tester,
        OptionTile(label: 'Newest', selected: false, onTap: () => taps++),
      );
      await tester.tap(find.byType(OptionTile));
      expect(taps, 1);

      await pumpTile(
        tester,
        const OptionTile(label: 'Newest', selected: false, onTap: null),
      );
      await tester.tap(find.byType(OptionTile));
      expect(taps, 1);
    });

    testWidgets('shows an icon and a subtitle when given', (tester) async {
      await pumpTile(
        tester,
        OptionTile(
          label: 'Pay Online',
          subtitle: 'UPI, cards and wallets',
          icon: Icons.credit_card_outlined,
          selected: false,
          onTap: () {},
        ),
      );

      expect(find.text('Pay Online'), findsOneWidget);
      expect(find.text('UPI, cards and wallets'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);

      await pumpTile(
        tester,
        OptionTile(label: 'Newest', selected: false, onTap: () {}),
      );
      expect(find.byType(Icon), findsNothing);
    });
  });

  testWidgets('without an icon, the title stands alone', (tester) async {
    await openSheet(tester, [], withIcon: false);

    expect(find.text('Sort by'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
  });
}
