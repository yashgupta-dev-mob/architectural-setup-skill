import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/buttons/dashed_outline_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, DashedOutlineButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  testWidgets('fills the width, shows the icon and label, and reports '
      'taps', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      DashedOutlineButton(label: 'Add new address', onPressed: () => taps++),
    );

    expect(tester.getSize(find.byType(DashedOutlineButton)).width, 800);
    expect(tester.getSize(find.byType(DashedOutlineButton)).height, 64);
    expect(find.text('Add new address'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    await tester.tap(find.byType(DashedOutlineButton));
    expect(taps, 1);
  });

  testWidgets('a null icon shows the label alone', (tester) async {
    await pumpButton(
      tester,
      DashedOutlineButton(label: 'Add', icon: null, onPressed: () {}),
    );

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('a null onPressed disables it', (tester) async {
    await pumpButton(
      tester,
      const DashedOutlineButton(label: 'Add new address', onPressed: null),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('isLoading hides the label and blocks taps', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      DashedOutlineButton(
        label: 'Add new address',
        isLoading: true,
        onPressed: () => taps++,
      ),
    );

    expect(find.text('Add new address'), findsNothing);
    await tester.tap(find.byType(DashedOutlineButton));
    expect(taps, 0);
  });
}
