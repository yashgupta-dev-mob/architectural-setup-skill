import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/app/failure.dart';
import 'package:template_app/features/support/domain/entities/support_content.dart';
import 'package:template_app/features/support/domain/usecases/get_cached_support_content.dart';
import 'package:template_app/features/support/domain/usecases/get_support_content.dart';
import 'package:template_app/features/support/presentation/help_support/bloc/help_support_bloc.dart';

import '../../../../../helpers/fake_support_repository.dart';

const _saved = SupportContent(
  faqs: [SupportFaq(question: 'Old?', answer: 'Yes.')],
);

void main() {
  late FakeSupportRepository repository;

  HelpSupportBloc build() => HelpSupportBloc(
    getCachedSupportContent: GetCachedSupportContent(repository),
    getSupportContent: GetSupportContent(repository),
  );

  Future<List<HelpSupportState>> run(
    HelpSupportBloc bloc,
    HelpSupportEvent event,
  ) async {
    final states = <HelpSupportState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(event);
    // The fake answers at once; let the handler run to its end.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();
    return states;
  }

  setUp(() => repository = FakeSupportRepository());

  test('a saved copy shows first, then the server replaces it', () async {
    repository.cachedContent = _saved;
    final bloc = build();

    final states = await run(bloc, HelpSupportStarted());

    expect(states.map((s) => (s.status, s.isStale, s.isRefreshing)), [
      (HelpSupportStatus.loaded, true, false),
      (HelpSupportStatus.loaded, true, true),
      (HelpSupportStatus.loaded, false, false),
    ]);
    expect(states.first.content, _saved);
    expect(states.last.content, testSupportContent);
    await bloc.close();
  });

  test('a failed refresh keeps the saved copy and sets failure', () async {
    repository
      ..cachedContent = _saved
      ..failure = NetworkFailure();
    final bloc = build();

    final states = await run(bloc, HelpSupportStarted());

    expect(states.last.status, HelpSupportStatus.loaded);
    expect(states.last.content, _saved);
    expect(states.last.failure, isA<NetworkFailure>());
    expect(states.last.isStale, isTrue);
    await bloc.close();
  });

  test('no saved copy and a failed load is a failure', () async {
    repository.failure = NetworkFailure();
    final bloc = build();

    final states = await run(bloc, HelpSupportStarted());

    expect(states.map((s) => s.status), [
      HelpSupportStatus.loading,
      HelpSupportStatus.failure,
    ]);
    await bloc.close();
  });

  test('retry after a failure loads the content', () async {
    repository.failure = NetworkFailure();
    final bloc = build();
    await run(bloc, HelpSupportStarted());

    repository.failure = null;
    final states = await run(bloc, HelpSupportRefreshed());

    expect(states.last.status, HelpSupportStatus.loaded);
    expect(states.last.content, testSupportContent);
    expect(states.last.failure, isNull);
    await bloc.close();
  });
}
