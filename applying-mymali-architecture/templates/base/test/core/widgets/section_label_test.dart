import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/section_label.dart';

void main() {
  Future<void> pumpLabel(WidgetTester tester, SectionLabel label) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Column(children: [label])),
      ),
    );
  }

  testWidgets('shows the title in uppercase with the accent bar', (
    tester,
  ) async {
    await pumpLabel(tester, const SectionLabel(title: 'Ways to earn'));

    expect(find.text('WAYS TO EARN'), findsOneWidget);
    expect(find.text('Ways to earn'), findsNothing);

    final bar = tester.widget<Container>(find.byType(Container).first);
    final decoration = bar.decoration! as BoxDecoration;
    expect(decoration.color, AppTheme.light.colorScheme.secondaryContainer);
  });

  testWidgets('padding is configurable', (tester) async {
    await pumpLabel(
      tester,
      const SectionLabel(title: 'Coin history', padding: EdgeInsets.zero),
    );

    final padding = tester.widget<Padding>(
      find.ancestor(of: find.byType(Row), matching: find.byType(Padding)).first,
    );
    expect(padding.padding, EdgeInsets.zero);
  });
}
