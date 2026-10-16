import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/globals.dart';
import 'package:shelf/main.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Map<String, Object> prefsValues,
) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => prefs)],
      child: const ShelfApp(),
    ),
  );
}

void main() {
  testWidgets('without a session token the app opens on the login screen', (
    tester,
  ) async {
    await pumpApp(tester, {});
    await tester.pumpAndSettle();

    // The app bar title and the button both read "Sign in".
    expect(find.text('Sign in'), findsNWidgets(2));
    expect(find.text('Shelf'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Products'), findsNothing);
  });

  testWidgets('with a session token the app opens on Home and shows the cached '
      'products at once, then keeps them when the refresh fails', (
    tester,
  ) async {
    await pumpApp(tester, {
      'session_token': 'token-123',
      'products_cache': jsonEncode({
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'items': [
          {
            'id': 'p1',
            'title': 'Cached mug',
            'price': 49900,
            'thumbnail': '',
            'in_stock': true,
          },
        ],
      }),
    });
    await tester.pump();

    // Products tab: app bar title and tab label.
    expect(find.text('Products'), findsNWidgets(2));
    expect(find.text('Cached mug'), findsOneWidget);
    expect(find.text('₹499.00'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    // The test environment answers every HTTP request with status 400, so
    // the refresh fails: the cached items stay and the SnackBar shows.
    for (
      var i = 0;
      i < 20 && find.text("Couldn't refresh products").evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("Couldn't refresh products"), findsOneWidget);
    expect(find.text('Cached mug'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
