/// Typed exceptions thrown by remote data sources that call the app's
/// Edge Functions or PostgREST. Repositories catch them and map them to
/// failures; nothing above a repository ever sees them.
library;

/// The API answered with an error envelope: `{ "code", "status", "title",
/// "detail" }` from an Edge Function, or `{ "code", "message", "details",
/// "hint" }` from PostgREST.
class ServerException implements Exception {
  const ServerException({
    required this.code,
    required this.status,
    this.detail,
  });

  final String code;
  final int status;
  final String? detail;

  @override
  String toString() => 'ServerException($status $code: $detail)';
}

/// The request never got a response (offline, timeout, DNS…).
class ConnectionException implements Exception {
  const ConnectionException([this.message]);

  final String? message;

  @override
  String toString() => 'ConnectionException($message)';
}
