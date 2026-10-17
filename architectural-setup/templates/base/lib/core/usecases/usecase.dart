import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../app/failure.dart';

/// A single application action: one [call], one responsibility.
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// For use cases that take no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
