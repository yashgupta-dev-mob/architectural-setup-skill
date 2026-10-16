import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/form_section_title.dart';

void main() {
  Future<void> pumpTitle(WidgetTester tester, FormSectionTitle title) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Column(children: [title])),
      ),
    );
  }

  testWidgets('shows the icon, the title and the description', (tester) async {
    await pumpTitle(
      tester,
      const FormSectionTitle(
        icon: Icons.person_outline_rounded,
        title: 'Contact details',
        description: 'Filled from your profile',
      ),
    );

    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.text('Contact details'), findsOneWidget);
    expect(find.text('Filled from your profile'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppTheme.light.colorScheme.primary);
  });

  testWidgets('without an icon or description shows only the title', (
    tester,
  ) async {
    await pumpTitle(tester, const FormSectionTitle(title: 'Locality'));

    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });
}
