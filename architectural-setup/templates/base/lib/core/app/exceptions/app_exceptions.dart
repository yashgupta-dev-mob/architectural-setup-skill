// ignore_for_file: annotate_overrides, overridden_fields
class AppException implements Exception {
  final String message;
  final String prefix;

  AppException(this.message, this.prefix);

  @override
  String toString() {
    return '$prefix: $message';
  }
}

class InternetException extends AppException {
  InternetException([String? message])
    : super(message ?? 'No internet', 'Internet');
}

class RequestTimeoutException extends AppException {
  RequestTimeoutException([String? message])
    : super(message ?? 'Request timed out', 'Request Timeout');
}

class ServerException extends AppException {
  ServerException([String? message])
    : super(message ?? 'Internal server error', 'Server');
}

class InvalidUrlException extends AppException {
  InvalidUrlException([String? message])
    : super(message ?? 'Invalid URL', 'Invalid URL');
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
    : super(message ?? 'Error during data fetching', 'Fetch Data');
}

class UnAuthorizedException extends AppException {
  UnAuthorizedException([String? message])
    : super(message ?? 'Error during data fetching', 'UnAuthorized');
}

class AuthException extends AppException {
  final String message;
  AuthException(this.message) : super(message, "");
}
