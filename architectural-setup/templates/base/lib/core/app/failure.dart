class Failure {
  final String message;
  final int? code;

  Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

/// The device is offline or the request timed out.
class NetworkFailure extends Failure {
  NetworkFailure({super.message = 'No internet connection.', super.code});
}

/// Any server error without a more specific mapping.
class ServerFailure extends Failure {
  ServerFailure({
    required this.errorCode,
    super.message = 'Something went wrong.',
    super.code,
  });

  /// The API's error code, e.g. `INVALID_BODY` or `PGRST301`.
  // Named errorCode because Failure already has an int `code` (HTTP status).
  final String errorCode;
}

/// Nothing usable is saved on this device for the data asked for. Never
/// shown to the user: the screen simply loads from the network.
class CacheMissFailure extends Failure {
  CacheMissFailure({super.message = 'Nothing saved on this device.'});
}
