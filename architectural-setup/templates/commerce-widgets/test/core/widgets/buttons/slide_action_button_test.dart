import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/buttons/slide_action_button.dart';

void main() {
  const thumbIcon = Icons.arrow_forward_rounded;

  Future<void> pumpButton(
    WidgetTester tester,
    SlideActionButton button, {
    double width = 330,
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: button),
            ),
          ),
        ),
      ),
    );
  }

  double thumbLeft(WidgetTester tester) =>
      tester.getTopLeft(find.byIcon(thumbIcon)).dx;

  testWidgets('shows the prefix and the label, and fills the width', (
    tester,
  ) async {
    await pumpButton(
      tester,
      SlideActionButton(
        prefixLabel: '₹198',
        label: 'Review & Pay',
        onPressed: () {},
      ),
    );

    expect(find.textContaining('₹198', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Review & Pay', findRichText: true),
      findsOneWidget,
    );
    expect(find.byIcon(thumbIcon), findsOneWidget);
    expect(tester.getSize(find.byType(SlideActionButton)), const Size(330, 56));
    // The hint stops by itself, so the button comes to rest.
    await tester.pumpAndSettle();
  });

  testWidgets('height and icon can be changed, and the thumb scales', (
    tester,
  ) async {
    await pumpButton(tester, SlideActionButton(label: 'Pay', onPressed: () {}));
    final regular = tester.getSize(find.byIcon(thumbIcon));

    await pumpButton(
      tester,
      SlideActionButton(
        label: 'Pay',
        height: 72,
        icon: Icons.lock_open_rounded,
        onPressed: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SlideActionButton)).height, 72);
    expect(find.byIcon(thumbIcon), findsNothing);
    expect(
      tester.getSize(find.byIcon(Icons.lock_open_rounded)).width,
      greaterThan(regular.width),
    );
  });

  testWidgets('dragging the thumb to the end calls onPressed once, then the '
      'thumb returns', (tester) async {
    var presses = 0;
    await pumpButton(
      tester,
      SlideActionButton(label: 'Review & Pay', onPressed: () => presses++),
    );
    await tester.pumpAndSettle();
    final rest = thumbLeft(tester);

    await tester.drag(find.byType(SlideActionButton), const Offset(330, 0));
    await tester.pumpAndSettle();

    expect(presses, 1);
    expect(thumbLeft(tester), rest);
  });

  testWidgets('the thumb follows the finger', (tester) async {
    await pumpButton(
      tester,
      SlideActionButton(label: 'Review & Pay', onPressed: () {}),
    );
    await tester.pumpAndSettle();
    final rest = thumbLeft(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(thumbIcon)),
    );
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();

    expect(thumbLeft(tester), greaterThan(rest + 80));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('released short of the end, the thumb springs back and '
      'nothing is called', (tester) async {
    var presses = 0;
    await pumpButton(
      tester,
      SlideActionButton(label: 'Review & Pay', onPressed: () => presses++),
    );
    await tester.pumpAndSettle();
    final rest = thumbLeft(tester);

    await tester.drag(find.byType(SlideActionButton), const Offset(120, 0));
    await tester.pumpAndSettle();

    expect(presses, 0);
    expect(thumbLeft(tester), rest);
  });

  testWidgets('a tap only nudges the thumb', (tester) async {
    var presses = 0;
    await pumpButton(
      tester,
      SlideActionButton(label: 'Review & Pay', onPressed: () => presses++),
    );
    await tester.pumpAndSettle();
    final rest = thumbLeft(tester);

    await tester.tap(find.byType(SlideActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(thumbLeft(tester), greaterThan(rest));

    await tester.pumpAndSettle();
    expect(presses, 0);
    expect(thumbLeft(tester), rest);
  });

  testWidgets('a null onPressed disables the slide', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpButton(
      tester,
      const SlideActionButton(label: 'Review & Pay', onPressed: null),
    );
    final rest = thumbLeft(tester);

    await tester.drag(find.byType(SlideActionButton), const Offset(330, 0));
    await tester.pumpAndSettle();

    expect(thumbLeft(tester), rest);
    expect(
      tester.getSemantics(find.byType(SlideActionButton)),
      isSemantics(
        label: 'Review & Pay',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('isLoading shows progress instead of the label and blocks the '
      'slide', (tester) async {
    var presses = 0;
    await pumpButton(
      tester,
      SlideActionButton(
        label: 'Review & Pay',
        isLoading: true,
        onPressed: () => presses++,
      ),
    );

    expect(
      find.textContaining('Review & Pay', findRichText: true),
      findsNothing,
    );
    expect(find.byIcon(thumbIcon), findsNothing);

    await tester.drag(find.byType(SlideActionButton), const Offset(330, 0));
    // The loading dots never settle, so pump by hand.
    await tester.pump(const Duration(milliseconds: 500));

    expect(presses, 0);
  });

  testWidgets('a screen reader activates it without the drag', (tester) async {
    final handle = tester.ensureSemantics();
    var presses = 0;
    await pumpButton(
      tester,
      SlideActionButton(
        prefixLabel: '₹198',
        label: 'Review & Pay',
        onPressed: () => presses++,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(SlideActionButton)),
      isSemantics(
        label: '₹198, Review & Pay',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('₹198, Review & Pay'));
    await tester.pumpAndSettle();

    expect(presses, 1);
    handle.dispose();
  });

  testWidgets('a long label shrinks instead of overflowing', (tester) async {
    await pumpButton(
      tester,
      SlideActionButton(
        prefixLabel: '₹1,24,999',
        label: 'Review your order and pay securely',
        onPressed: () {},
      ),
      width: 250,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('pay securely', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('when narrow, it drops the chevrons and puts the prefix above '
      'the label, both readable', (tester) async {
    await pumpButton(
      tester,
      SlideActionButton(
        prefixLabel: '₹1,234',
        label: 'Pay & Place',
        onPressed: () {},
      ),
      width: 172,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final price = find.text('₹1,234');
    final label = find.text('Pay & Place');
    expect(price, findsOneWidget);
    expect(label, findsOneWidget);
    expect(tester.getCenter(price).dy, lessThan(tester.getCenter(label).dy));
    // Shown at a readable size, not shrunk to nothing.
    expect(tester.getSize(label).width, greaterThan(60));
    // Clear of the thumb.
    expect(
      tester.getTopLeft(label).dx,
      greaterThanOrEqualTo(tester.getTopRight(find.byIcon(thumbIcon)).dx),
    );
  });

  testWidgets('stays still when the device asks for no animations', (
    tester,
  ) async {
    await pumpButton(
      tester,
      SlideActionButton(label: 'Review & Pay', onPressed: () {}),
      disableAnimations: true,
    );

    expect(tester.hasRunningAnimations, isFalse);
  });
}
