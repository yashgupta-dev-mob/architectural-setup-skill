import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/theme/app_theme.dart';
import 'package:mymali/core/widgets/buttons/primary_button.dart';
import 'package:mymali/core/widgets/sheets/app_info_sheet.dart';

void main() {
  /// The value [AppInfoSheet.show] completed with, once it has.
  bool? result;

  setUp(() => result = null);

  /// Pumps a page with an "open" button that shows the sheet.
  Future<void> pumpAndOpen(
    WidgetTester tester, {
    String title = 'Heads up',
    String message = 'Something you should know.',
    AppInfoSheetTone tone = AppInfoSheetTone.info,
    IconData? icon,
    String actionLabel = AppInfoSheet.defaultActionLabel,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await AppInfoSheet.show(
                  context,
                  key: const Key('sheet'),
                  title: title,
                  message: message,
                  tone: tone,
                  icon: icon,
                  actionLabel: actionLabel,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Icon toneIcon(WidgetTester tester) => tester.widget<Icon>(
    find.descendant(
      of: find.byKey(const Key('sheet')),
      matching: find.byWidgetPredicate(
        (w) => w is Icon && w.icon != Icons.close_rounded,
      ),
    ),
  );

  testWidgets('shows the title, the message and a "Got it" button', (
    tester,
  ) async {
    await pumpAndOpen(tester);

    expect(find.byKey(const Key('sheet')), findsOneWidget);
    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('Something you should know.'), findsOneWidget);
    expect(
      tester.widget<PrimaryButton>(find.byKey(AppInfoSheet.actionKey)).label,
      'Got it',
    );
    expect(find.byTooltip('Close'), findsOneWidget);
  });

  testWidgets('the button closes the sheet and completes with true', (
    tester,
  ) async {
    await pumpAndOpen(tester, actionLabel: 'Try again');

    await tester.tap(find.byKey(AppInfoSheet.actionKey));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sheet')), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('the close button closes the sheet and completes with false', (
    tester,
  ) async {
    await pumpAndOpen(tester);

    await tester.tap(find.byKey(AppInfoSheet.closeKey));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sheet')), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('a tap outside closes the sheet and completes with false', (
    tester,
  ) async {
    await pumpAndOpen(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sheet')), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('each tone has its own icon, and error uses the error colour', (
    tester,
  ) async {
    final colors = AppTheme.dark.colorScheme;

    await pumpAndOpen(tester);
    expect(toneIcon(tester).icon, Icons.info_outline_rounded);
    expect(toneIcon(tester).color, colors.secondary);
    await tester.tap(find.byKey(AppInfoSheet.closeKey));
    await tester.pumpAndSettle();

    await pumpAndOpen(tester, tone: AppInfoSheetTone.success);
    expect(toneIcon(tester).icon, Icons.task_alt_rounded);
    expect(toneIcon(tester).color, colors.secondary);
    await tester.tap(find.byKey(AppInfoSheet.closeKey));
    await tester.pumpAndSettle();

    await pumpAndOpen(tester, tone: AppInfoSheetTone.error);
    expect(toneIcon(tester).icon, Icons.error_outline_rounded);
    expect(toneIcon(tester).color, colors.error);
  });

  testWidgets('icon replaces the tone icon and keeps its colour', (
    tester,
  ) async {
    await pumpAndOpen(
      tester,
      tone: AppInfoSheetTone.error,
      icon: Icons.wifi_off_rounded,
    );

    expect(toneIcon(tester).icon, Icons.wifi_off_rounded);
    expect(toneIcon(tester).color, AppTheme.dark.colorScheme.error);
  });

  testWidgets('a very long message scrolls instead of overflowing', (
    tester,
  ) async {
    await pumpAndOpen(
      tester,
      title: 'A title that is long enough to need a second line here',
      message: List.filled(80, 'A long line of explanation.').join(' '),
      theme: AppTheme.light,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(AppInfoSheet.actionKey).hitTestable(), findsOneWidget);
  });

  testWidgets('a null onAction disables the button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AppInfoSheet(
            title: 'Heads up',
            message: 'Something you should know.',
            onAction: null,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<PrimaryButton>(find.byKey(AppInfoSheet.actionKey))
          .onPressed,
      isNull,
    );
  });
}
