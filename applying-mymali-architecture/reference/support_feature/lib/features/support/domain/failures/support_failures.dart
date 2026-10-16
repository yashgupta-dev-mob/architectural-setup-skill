import '../../../../core/app/failure.dart';

/// The server has no support content configured (`{ "support": null }`).
class SupportUnavailableFailure extends Failure {
  SupportUnavailableFailure({
    super.message = 'Support details are not available.',
    super.code,
  });
}
