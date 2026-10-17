import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/widgets/search/search_trigger_bar.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, SearchTriggerBar bar) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: bar),
        ),
      ),
    );
  }

  testWidgets('tapping the bar calls onTap, not onCameraTap', (tester) async {
    var taps = 0;
    var cameraTaps = 0;
    await pumpBar(
      tester,
      SearchTriggerBar(
        hintText: 'Search seeds',
        onTap: () => taps++,
        onCameraTap: () => cameraTaps++,
      ),
    );

    expect(find.text('Search seeds'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);

    await tester.tap(find.text('Search seeds'));
    expect(taps, 1);
    expect(cameraTaps, 0);
  });

  testWidgets('tapping the camera calls onCameraTap, not onTap', (
    tester,
  ) async {
    var taps = 0;
    var cameraTaps = 0;
    await pumpBar(
      tester,
      SearchTriggerBar(onTap: () => taps++, onCameraTap: () => cameraTaps++),
    );

    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    expect(cameraTaps, 1);
    expect(taps, 0);
  });

  testWidgets('no camera callback hides the camera button', (tester) async {
    await pumpBar(tester, SearchTriggerBar(onTap: () {}));

    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
