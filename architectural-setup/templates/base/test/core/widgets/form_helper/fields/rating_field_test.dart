import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/theme/app_theme.dart';
import 'package:template_app/core/theme/app_tones.dart';
import 'package:template_app/core/widgets/form_helper/field_config.dart';
import 'package:template_app/core/widgets/form_helper/field_title.dart';
import 'package:template_app/core/widgets/form_helper/fields/rating_field.dart';
import 'package:template_app/core/widgets/form_helper/universal_form_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget field) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: field)),
    ),
  );

  List<Icon> stars(WidgetTester tester) => tester
      .widgetList<Icon>(
        find.descendant(
          of: find.byType(RatingField),
          matching: find.byType(Icon),
        ),
      )
      .toList();

  testWidgets('UFFType.rating fills the first n stars in the rating tone', (
    tester,
  ) async {
    await pump(
      tester,
      UniversalFormField(
        fieldType: UFFType.rating,
        label: 'Your rating',
        initialValue: 3,
        onChanged: (_) {},
      ).build(),
    );

    final icons = stars(tester);
    final tone = AppTones.of(tester.element(find.byType(RatingField))).rating;
    expect(icons, hasLength(5));
    expect(icons.take(3).map((icon) => icon.color), everyElement(tone));
    expect(icons.skip(3).map((icon) => icon.icon), [
      Icons.star_outline_rounded,
      Icons.star_outline_rounded,
    ]);
  });

  testWidgets('tapping the n-th star reports n', (tester) async {
    int? picked;
    await pump(
      tester,
      UniversalFormField(
        fieldType: UFFType.rating,
        label: 'Your rating',
        initialValue: 0,
        onChanged: (value) => picked = value as int,
      ).build(ratingConfig: const RatingConfig(keyPrefix: 'star')),
    );

    await tester.tap(find.byKey(const Key('star_4')));

    expect(picked, 4);
  });

  testWidgets('shows the error text and ignores taps when disabled', (
    tester,
  ) async {
    int? picked;
    await pump(
      tester,
      UniversalFormField(
        fieldType: UFFType.rating,
        label: 'Your rating',
        initialValue: 0,
        onChanged: (value) => picked = value as int,
      ).build(
        ratingConfig: const RatingConfig(
          keyPrefix: 'star',
          enabled: false,
          errorText: 'Pick a rating',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('star_2')));

    expect(picked, isNull);
    expect(find.text('Pick a rating'), findsOneWidget);
  });

  testWidgets('withTitle shows the label above the stars', (tester) async {
    await pump(
      tester,
      UniversalFormField(
        fieldType: UFFType.rating,
        label: 'Your rating',
        withTitle: true,
        initialValue: 0,
        onChanged: (_) {},
      ).build(),
    );

    expect(find.byType(FieldTitle), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(FieldTitle)).dy,
      lessThan(tester.getTopLeft(find.byType(RatingField)).dy),
    );
  });
}
