import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/buttons/heart_toggle_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, HeartToggleButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  ColorScheme colorsOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(HeartToggleButton))).colorScheme;

  testWidgets('off shows an outlined heart', (tester) async {
    await pumpButton(
      tester,
      HeartToggleButton(isActive: false, onPressed: () {}),
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('on shows a filled heart in the error colour', (tester) async {
    await pumpButton(
      tester,
      HeartToggleButton(isActive: true, onPressed: () {}),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
    expect(icon.color, colorsOf(tester).error);
  });

  testWidgets('a tap calls onPressed', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      HeartToggleButton(isActive: false, onPressed: () => taps++),
    );

    await tester.tap(find.byType(HeartToggleButton));

    expect(taps, 1);
  });

  testWidgets('a null onPressed disables it', (tester) async {
    await pumpButton(
      tester,
      const HeartToggleButton(isActive: false, onPressed: null),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('isLoading shows progress and blocks taps', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      HeartToggleButton(
        isActive: false,
        isLoading: true,
        onPressed: () => taps++,
      ),
    );

    await tester.tap(find.byType(HeartToggleButton));

    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('on a plain surface the active fill is an error tint', (
    tester,
  ) async {
    await pumpButton(
      tester,
      HeartToggleButton(isActive: true, overImage: false, onPressed: () {}),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(HeartToggleButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, colorsOf(tester).error.withValues(alpha: 0.18));
  });

  testWidgets('takes the size it is given', (tester) async {
    await pumpButton(
      tester,
      HeartToggleButton(isActive: false, size: 48, onPressed: () {}),
    );

    expect(tester.getSize(find.byType(HeartToggleButton)), const Size(48, 48));
  });
}
