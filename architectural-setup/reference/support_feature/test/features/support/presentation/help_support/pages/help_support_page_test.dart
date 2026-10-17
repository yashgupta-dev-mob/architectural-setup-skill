import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/app/failure.dart';
import 'package:template_app/core/di/injection_container.dart';
import 'package:template_app/core/services/analytics/app_events.dart';
import 'package:template_app/features/support/domain/entities/support_content.dart';
import 'package:template_app/features/support/domain/repositories/support_repository.dart';
import 'package:template_app/features/support/presentation/help_support/utils/support_texts.dart';

import '../../../../../helpers/fake_ko_engagement_service.dart';
import '../../../../../helpers/fake_support_repository.dart';
import '../../../../../helpers/signed_in_app.dart';

void main() {
  late FakeSupportRepository repository;
  late FakeKoEngagementService engagement;

  setUp(() {
    engagement = FakeKoEngagementService();
    registerSignedInApp(engagement: engagement);
    repository = FakeSupportRepository();
    sl.registerSingleton<SupportRepository>(repository);
    registerSupportFeature();
  });
  tearDown(sl.reset);

  /// Opens Help & Support from its Account row.
  Future<void> openSupport(WidgetTester tester, {bool settle = true}) async {
    await launchSignedInApp(tester);
    await openAccountTab(tester);
    final row = find.byKey(const Key('account_helpRow'));
    await scrollAccountTo(tester, row);
    await tester.tap(row);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.byKey(const Key('support_page')), findsOneWidget);
  }

  testWidgets('the Account row opens the channels and the questions', (
    tester,
  ) async {
    await openSupport(tester);

    expect(find.text(testSupportContent.intro), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('support@example.com'), findsOneWidget);
    expect(find.text('+91 90000 00000'), findsOneWidget);
    expect(find.text('Chat with us'), findsOneWidget);
    expect(find.byIcon(Icons.call_outlined), findsOneWidget);
    expect(find.text('BEFORE YOU WRITE'), findsOneWidget);
    expect(find.text('Where is my order?'), findsOneWidget);
  });

  testWidgets('tapping a channel reports its kind once', (tester) async {
    await openSupport(tester);

    final channel = find.byKey(const Key('support_channel_0'));
    await tester.ensureVisible(channel);
    await tester.tap(channel);
    await tester.pumpAndSettle();

    expect(
      [
        for (final e in engagement.tracked)
          if (e.name == AppEvents.supportChannelTapped) e.properties,
      ],
      [
        {'channel': testSupportContent.channels.first.kind.name},
      ],
    );
  });

  testWidgets('a question opens into its answer and closes again', (
    tester,
  ) async {
    await openSupport(tester);
    const answer = Key('support_faqAnswer_0');
    expect(find.byKey(answer), findsNothing);

    await tester.tap(find.byKey(const Key('support_faq_0')));
    await tester.pumpAndSettle();
    expect(find.text('Within one business day.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('support_faq_0')));
    await tester.pumpAndSettle();
    expect(find.byKey(answer), findsNothing);
  });

  testWidgets('the saved copy shows while the server is asked', (tester) async {
    repository
      ..cachedContent = const SupportContent(
        faqs: [SupportFaq(question: 'Saved question?', answer: 'Yes.')],
      )
      ..gate = Completer<void>();

    await openSupport(tester, settle: false);

    expect(find.text('Saved question?'), findsOneWidget);
    expect(find.byKey(const Key('support_loadingSkeleton')), findsNothing);

    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saved question?'), findsNothing);
    expect(find.text('Where is my order?'), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the saved copy and says so', (
    tester,
  ) async {
    repository
      ..cachedContent = testSupportContent
      ..failure = NetworkFailure();

    await openSupport(tester);

    expect(find.text('support@example.com'), findsOneWidget);
    expect(
      find.byKey(const Key('support_refreshFailedMessage')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('support_errorView')), findsNothing);
  });

  testWidgets('with nothing saved a failure offers a retry that loads', (
    tester,
  ) async {
    repository.failure = NetworkFailure();

    await openSupport(tester);

    expect(find.byKey(const Key('support_errorView')), findsOneWidget);
    expect(
      find.text(supportLoadFailureMessage(NetworkFailure())),
      findsOneWidget,
    );

    repository.failure = null;
    await tester.tap(find.byKey(const Key('reload_button')));
    await tester.pumpAndSettle();
    expect(find.text('support@example.com'), findsOneWidget);
  });
}
