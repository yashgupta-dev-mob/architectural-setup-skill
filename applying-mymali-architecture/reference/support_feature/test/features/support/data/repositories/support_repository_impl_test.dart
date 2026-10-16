import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/app/exceptions/api_exceptions.dart';
import 'package:mymali/core/app/exceptions/cache_exceptions.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/support/data/datasources/support_local_data_source.dart';
import 'package:mymali/features/support/data/datasources/support_remote_data_source.dart';
import 'package:mymali/features/support/data/models/support_content_model.dart';
import 'package:mymali/features/support/data/repositories/support_repository_impl.dart';
import 'package:mymali/features/support/domain/failures/support_failures.dart';

import '../../../../helpers/fake_local_cache.dart';

const _content = SupportContentModel(
  intro: 'Hi',
  faqs: [SupportFaqModel(question: 'Q', answer: 'A')],
);

class _FakeRemote implements SupportRemoteDataSource {
  _FakeRemote(this.log);

  final List<String> log;
  Object? error;
  int calls = 0;

  @override
  Future<SupportContentModel> fetchSupport() async {
    calls++;
    log.add('fetch');
    final failure = error;
    if (failure != null) throw failure;
    return _content;
  }
}

class _LoggingLocal implements SupportLocalDataSource {
  _LoggingLocal(this._inner, this.log);

  final SupportLocalDataSource _inner;
  final List<String> log;

  @override
  Future<SupportContentModel?> readSupport() => _inner.readSupport();

  @override
  Future<void> writeSupport(SupportContentModel content) {
    log.add('write');
    return _inner.writeSupport(content);
  }
}

void main() {
  late FakeLocalCache cache;
  late List<String> log;
  late _FakeRemote remote;
  late SupportRepositoryImpl repository;

  setUp(() {
    cache = FakeLocalCache();
    log = [];
    remote = _FakeRemote(log);
    repository = SupportRepositoryImpl(
      remote: remote,
      local: _LoggingLocal(SupportLocalDataSourceImpl(cache), log),
    );
  });

  test('fresh content is saved after the fetch', () async {
    final result = await repository.getSupportContent();

    expect(result.toNullable()!.intro, 'Hi');
    expect(log, ['fetch', 'write']);
    expect(
      (await repository.getCachedSupportContent()).toNullable()!.intro,
      'Hi',
    );
  });

  test('a cache write that throws still returns the content', () async {
    cache.writeError = const CacheException('disk full');

    expect((await repository.getSupportContent()).isRight(), isTrue);
  });

  test('errors map to failures', () async {
    remote.error = const ServerException(
      code: supportNotConfiguredCode,
      status: 200,
    );
    expect(
      (await repository.getSupportContent()).getLeft().toNullable(),
      isA<SupportUnavailableFailure>(),
    );

    remote.error = const ServerException(code: 'DB_ERROR', status: 500);
    expect(
      (await repository.getSupportContent()).getLeft().toNullable(),
      isA<ServerFailure>(),
    );

    remote.error = const ConnectionException('offline');
    expect(
      (await repository.getSupportContent()).getLeft().toNullable(),
      isA<NetworkFailure>(),
    );
  });

  test('a miss, or a cache read that throws, is CacheMissFailure and never '
      'calls the server', () async {
    expect(
      (await repository.getCachedSupportContent()).getLeft().toNullable(),
      isA<CacheMissFailure>(),
    );

    cache.readError = const CacheException('locked');
    expect(
      (await repository.getCachedSupportContent()).getLeft().toNullable(),
      isA<CacheMissFailure>(),
    );
    expect(remote.calls, 0);
  });
}
