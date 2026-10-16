import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/buttons/secondary_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, SecondaryButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  Color outlineOf(WidgetTester tester) {
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(SecondaryButton),
        matching: find.byType(Material),
      ),
    );
    return (material.shape! as StadiumBorder).side.color;
  }

  testWidgets('fills the width by default and reports taps', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      SecondaryButton(label: 'Clear', onPressed: () => taps++),
    );

    expect(tester.getSize(find.byType(SecondaryButton)).width, 800);
    expect(tester.getSize(find.byType(SecondaryButton)).height, 56);
    await tester.tap(find.byType(SecondaryButton));
    expect(taps, 1);
  });

  testWidgets('expand: false is only as wide as its label', (tester) async {
    await pumpButton(
      tester,
      SecondaryButton(
        label: 'Clear',
        height: 48,
        expand: false,
        onPressed: () {},
      ),
    );

    final size = tester.getSize(find.byType(SecondaryButton));
    expect(size.height, 48);
    expect(size.width, lessThan(200));
  });

  testWidgets('a null onPressed disables it', (tester) async {
    await pumpButton(
      tester,
      const SecondaryButton(label: 'Clear', onPressed: null),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    expect(outlineOf(tester).a, lessThan(1));
  });

  testWidgets('isLoading hides the label and blocks taps', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      SecondaryButton(label: 'Clear', isLoading: true, onPressed: () => taps++),
    );

    expect(find.text('Clear'), findsNothing);
    await tester.tap(find.byType(SecondaryButton));
    expect(taps, 0);
  });

  testWidgets('warm uses the peach colour instead of the brand one', (
    tester,
  ) async {
    await pumpButton(
      tester,
      SecondaryButton(label: 'Clear', warm: true, onPressed: () {}),
    );

    expect(outlineOf(tester), AppTheme.light.colorScheme.tertiaryContainer);
  });

  testWidgets('destructive uses the alert colour, even when warm', (
    tester,
  ) async {
    await pumpButton(
      tester,
      SecondaryButton(
        label: 'Sign Out',
        destructive: true,
        warm: true,
        onPressed: () {},
      ),
    );

    expect(outlineOf(tester), AppTheme.light.colorScheme.error);
  });

  testWidgets('leadingIcon shows an icon before the label', (tester) async {
    await pumpButton(
      tester,
      SecondaryButton(
        label: 'Sign Out',
        leadingIcon: Icons.logout_rounded,
        onPressed: () {},
      ),
    );

    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.logout_rounded)).dx,
      lessThan(tester.getTopLeft(find.text('Sign Out')).dx),
    );
  });
}
