import 'package:fpdart/fpdart.dart';

import '../../../../core/app/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/support_content.dart';
import '../repositories/support_repository.dart';

/// The Help & Support content, from the server.
class GetSupportContent implements UseCase<SupportContent, NoParams> {
  const GetSupportContent(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, SupportContent>> call(NoParams params) {
    return _repository.getSupportContent();
  }
}
