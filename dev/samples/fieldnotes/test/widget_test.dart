import 'package:fieldnotes/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the login screen when no token is stored', (tester) async {
    await tester.pumpWidget(const FieldNotesApp());
    await tester.pumpAndSettle();

    expect(find.text('Field notes'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
  });

  testWidgets('Sign in is disabled until both fields have text', (
    tester,
  ) async {
    await tester.pumpWidget(const FieldNotesApp());
    await tester.pumpAndSettle();

    ElevatedButton button() =>
        tester.widget(find.widgetWithText(ElevatedButton, 'Sign in'));

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'ranger@example.com');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });
}
