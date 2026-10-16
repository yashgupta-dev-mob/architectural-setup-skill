// GENERIC: MyMali's FakeNetworking plus putAPICall.
import 'package:mymali/core/app/api/api_response.dart';
import 'package:mymali/core/services/networking/networking.dart';

/// One request made through [FakeNetworking].
class RecordedCall {
  const RecordedCall({
    required this.method,
    required this.endpoint,
    this.queryParameters,
    this.data,
    this.headers,
    this.pathParameters,
    this.host = ApiHost.supabase,
  });

  final String method;
  final String endpoint;
  final Map<String, dynamic>? queryParameters;
  final Object? data;
  final Map<String, String>? headers;
  final Map<String, dynamic>? pathParameters;
  final ApiHost host;
}

/// In-memory [Networking] for data source tests.
///
/// Every GET and POST returns [response], or throws [error] when set, and
/// is recorded in [calls]. While [queued] holds answers, each call takes
/// the first of them instead of [response].
class FakeNetworking implements Networking {
  Object? response;
  Object? error;

  /// Answers for the next calls, in order; see the class comment.
  final List<Object?> queued = [];

  final List<RecordedCall> calls = [];

  RecordedCall get lastCall => calls.last;

  @override
  Future<dynamic> getAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    calls.add(
      RecordedCall(
        method: 'GET',
        endpoint: endpoint,
        queryParameters: queryParameters,
        headers: headers,
        pathParameters: pathParameters,
        host: host,
      ),
    );
    return _answer();
  }

  @override
  Future<dynamic> postAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    calls.add(
      RecordedCall(
        method: 'POST',
        endpoint: endpoint,
        queryParameters: queryParameters,
        data: data,
        headers: headers,
        pathParameters: pathParameters,
        host: host,
      ),
    );
    return _answer();
  }

  @override
  Future<dynamic> deleteAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    calls.add(
      RecordedCall(
        method: 'DELETE',
        endpoint: endpoint,
        queryParameters: queryParameters,
        data: data,
        headers: headers,
        pathParameters: pathParameters,
        host: host,
      ),
    );
    return _answer();
  }

  @override
  Future<dynamic> patchAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    calls.add(
      RecordedCall(
        method: 'PATCH',
        endpoint: endpoint,
        queryParameters: queryParameters,
        data: data,
        headers: headers,
        pathParameters: pathParameters,
        host: host,
      ),
    );
    return _answer();
  }

  @override
  Future<dynamic> putAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    calls.add(
      RecordedCall(
        method: 'PUT',
        endpoint: endpoint,
        queryParameters: queryParameters,
        data: data,
        headers: headers,
        pathParameters: pathParameters,
        host: host,
      ),
    );
    return _answer();
  }

  Object? _answer() {
    if (error != null) throw error!;
    return queued.isEmpty ? response : queued.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SuccessResponse okResponse(Object? body) => SuccessResponse(
  successMessage: '',
  statusCode: '200',
  rawData: body,
  data: body,
);

ErrorResponse errorResponse(Object? body, String status) => ErrorResponse(
  errorMessage: '',
  errorCode: status,
  data: null,
  rawData: body,
);
