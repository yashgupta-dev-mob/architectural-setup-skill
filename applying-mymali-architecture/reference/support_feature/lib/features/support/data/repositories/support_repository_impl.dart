import 'package:fpdart/fpdart.dart';

import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/exceptions/cache_exceptions.dart';
import '../../../../core/app/failure.dart';
import '../../domain/entities/support_content.dart';
import '../../domain/failures/support_failures.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_local_data_source.dart';
import '../datasources/support_remote_data_source.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl({
    required SupportRemoteDataSource remote,
    required SupportLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final SupportRemoteDataSource _remote;
  final SupportLocalDataSource _local;

  @override
  Future<Either<Failure, SupportContent>> getSupportContent() async {
    try {
      final content = await _remote.fetchSupport();
      await _save(() => _local.writeSupport(content));
      return Right(content.toEntity());
    } on ServerException catch (e) {
      if (e.code == supportNotConfiguredCode) {
        return Left(SupportUnavailableFailure(code: e.status));
      }
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, SupportContent>> getCachedSupportContent() async {
    final content = await _cached(_local.readSupport);
    if (content == null) return Left(CacheMissFailure());
    return Right(content.toEntity());
  }

  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } on CacheException {
      // Best-effort: the next successful load saves again.
    }
  }

  Future<T?> _cached<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on CacheException {
      return null;
    }
  }
}
