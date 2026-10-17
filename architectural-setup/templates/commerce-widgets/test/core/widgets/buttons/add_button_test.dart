import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/buttons/add_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, AddButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  testWidgets('shows "ADD +" only as wide as its label and reports taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpButton(tester, AddButton(onPressed: () => taps++));

    expect(find.text('ADD'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(AddButton)).width, lessThan(200));
    await tester.tap(find.byType(AddButton));
    expect(taps, 1);
  });

  testWidgets('compact is smaller', (tester) async {
    await pumpButton(tester, AddButton(onPressed: () {}));
    final regular = tester.getSize(find.byType(AddButton));
    await pumpButton(tester, AddButton(onPressed: () {}, compact: true));
    final compact = tester.getSize(find.byType(AddButton));

    expect(compact.width, lessThan(regular.width));
    expect(compact.height, lessThan(regular.height));
  });

  testWidgets('a null onPressed disables it', (tester) async {
    await pumpButton(tester, const AddButton(onPressed: null));

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(AddButton),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.onTap, isNull);
  });
}
