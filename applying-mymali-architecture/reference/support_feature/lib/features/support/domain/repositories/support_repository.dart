import 'package:fpdart/fpdart.dart';

import '../../../../core/app/failure.dart';
import '../entities/support_content.dart';
import '../failures/support_failures.dart' show SupportUnavailableFailure;

/// The Help & Support content. It is the same for every customer, so the
/// saved copy survives sign-out, and a customer with no signal can still
/// find the number to call.
abstract interface class SupportRepository {
  /// Asks the server, then saves the answer. Fails with
  /// [SupportUnavailableFailure] when none is configured.
  Future<Either<Failure, SupportContent>> getSupportContent();

  /// The copy saved on this device. Fails with [CacheMissFailure] when
  /// there is none.
  Future<Either<Failure, SupportContent>> getCachedSupportContent();
}
