// GENERIC: MyMali's networking.dart; only the hosts and default headers are per app.
// ignore_for_file: prefer_initializing_formals, use_null_aware_elements
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:mymali/core/app/api/api_response.dart';
import 'package:mymali/core/app/exceptions/app_exceptions.dart';
import 'package:mymali/core/repositories/base_api_repository.dart';
import 'package:mymali/core/services/secure_storage/secure_storage.dart';
import 'package:mymali/core/utils/string_constants.dart';

import 'curl_logger_interceptor.dart';

/// The backend a call goes to. Each has its own Dio and base URL (see
/// [BaseApiRepo]), so endpoints stay relative to the chosen host. The
/// first value is the default of every call.
enum ApiHost {
  supabase,
}

/// Every call goes to [ApiHost.supabase] unless `host:` says otherwise.
abstract class Networking {
  /// [headers] are merged over the default headers for this call only.
  Future<dynamic> getAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  });

  /// [headers] are merged over the default headers for this call only.
  Future<dynamic> postAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  });

  /// [headers] are merged over the default headers for this call only.
  Future<dynamic> patchAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  });

  /// [headers] are merged over the default headers for this call only.
  Future<dynamic> putAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  });

  /// [headers] are merged over the default headers for this call only.
  Future<dynamic> deleteAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  });
  Future<APIResponse> graphqlQueryCall({
    required String graphqlEndpoint,
    required String query,
    Map<String, dynamic>? variables,
  });
}

class NetworkingService extends BaseApiRepo implements Networking {
  final Options? options;

  /// Holds the access token saved by `AuthLocalDataSource`. Null when the
  /// app keeps no token; then no `Authorization` header is ever sent.
  final SecureStorage? _secureStorage;

  NetworkingService({this.options, SecureStorage? secureStorage})
    : _secureStorage = secureStorage {
    // Every request printed as a curl command; debug builds only.
    if (kDebugMode) {
      for (final dio in dios.values) {
        dio.interceptors.add(const CurlLoggerInterceptor());
      }
    }
  }

  Dio _dioFor(ApiHost host) => dios[host]!;

  /// Hosts that are not the app's own backend. They get none of the app's
  /// default headers (no token): only a `Content-Type` when there is a
  /// body, plus what the call itself passes.
  static const Set<ApiHost> _thirdPartyHosts = {};

  /// The default headers for [host].
  Future<Options> _optionsFor(
    ApiHost host, {
    String? contentType,
    bool hasBody = true,
  }) async {
    if (!_thirdPartyHosts.contains(host)) {
      return _getOptions(contentType: contentType, hasBody: hasBody);
    }
    return Options(
      headers: {if (hasBody) 'Content-Type': contentType ?? 'application/json'},
    );
  }

  /// The app's default headers: a JSON `Content-Type` when there is a body,
  /// and the saved access token as a bearer when there is one. The token is
  /// read at request time, so a sign-in or sign-out applies at once.
  Future<Options> _getOptions({
    String? contentType,
    bool hasBody = true,
  }) async {
    final token = await _secureStorage?.read(StringConstants.appAuthToken);
    return options ??
        Options(
          headers: {
            if (hasBody) 'Content-Type': contentType ?? 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        );
  }

  /// Falls back to `toString()` for values JSON can't encode.
  static final JsonEncoder _logEncoder = JsonEncoder.withIndent(
    '  ',
    (Object? value) => value.toString(),
  );

  /// [value] as indented JSON for the request logs. A JSON string is
  /// decoded first, and [FormData] shows its fields and file names.
  String _formatForLog(Object? value) {
    if (value == null) return 'none';
    if (value is FormData) {
      value = {
        'fields': {for (final field in value.fields) field.key: field.value},
        'files': {
          for (final file in value.files) file.key: file.value.filename,
        },
      };
    } else if (value is String) {
      final text = value;
      try {
        value = jsonDecode(text);
      } on FormatException {
        return text;
      }
    }
    return _logEncoder.convert(value);
  }

  void _logRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) {
    log(
      'SERVICE $method API CALLING $endpoint ${DateTime.now()}\n'
      'query: ${_formatForLog(queryParameters)}\n'
      'data: ${_formatForLog(data)}',
    );
  }

  String setupPathParams(
    String endpoint,
    Map<String, dynamic>? pathParameters,
  ) {
    if (pathParameters != null) {
      pathParameters.forEach((key, value) {
        endpoint = endpoint.replaceAll('{$key}', value.toString());
      });
    }
    return endpoint;
  }

  @override
  Future<APIResponse> getAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    // setting up path params with the endpoint
    endpoint = setupPathParams(endpoint, pathParameters);

    try {
      _logRequest('GET', endpoint, queryParameters: queryParameters);

      final defaultOptions = await _optionsFor(host, hasBody: false);
      final options = headers == null
          ? defaultOptions
          : defaultOptions.copyWith(
              headers: {...?defaultOptions.headers, ...headers},
            );
      final response = await _dioFor(host)
          .get(endpoint, options: options, queryParameters: queryParameters);

      log("SERVICE GET API  EXECUTED SUCCESS $endpoint ${DateTime.now()}");

      return returnResponse(response);
    } on DioException catch (e) {
      log(
        "SERVICE GET ERROR $endpoint ${DateTime.now()} - ${e.response?.data}",
      );
      if (e.response != null) {
        return returnResponse(e.response!);
      }
      throw convertDioExceptionToAppException(e);
    }
  }

  @override
  Future<APIResponse> graphqlQueryCall({
    required String graphqlEndpoint,
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    try {
      final body = {
        'query': query,
        if (variables != null) 'variables': variables,
      };

      final response = await Dio(BaseOptions(sendTimeout: Duration(seconds: 3)))
          .post(
            graphqlEndpoint,
            data: jsonEncode(body),
            options: (await _getOptions()).copyWith(
              headers: {
                ...(await _getOptions()).headers ?? {},
                'Content-Type': 'application/json',
              },
            ),
          );

      // Check for GraphQL errors
      final responseData = response.data;
      if (responseData != null && responseData['errors'] != null) {
        return ErrorResponse(
          errorMessage: responseData['errors'][0]['message'] ?? 'GraphQL Error',
          errorCode: response.statusCode?.toString() ?? '400',
          data: null,
          rawData: responseData,
        );
      }

      return SuccessResponse(
        successMessage: "GraphQL Query Success",
        statusCode: response.statusCode?.toString() ?? "200",
        data: responseData['data'],
        rawData: responseData,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return returnResponse(e.response!);
      }
      throw convertDioExceptionToAppException(e);
    }
  }

  @override
  Future<APIResponse> postAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    try {
      // setting up path params with the endpoint
      endpoint = setupPathParams(endpoint, pathParameters);
      final defaultOptions = await _optionsFor(
        host,
        contentType: data is FormData
            ? Headers.multipartFormDataContentType
            : null,
      );
      final options = headers == null
          ? defaultOptions
          : defaultOptions.copyWith(
              headers: {...?defaultOptions.headers, ...headers},
            );
      _logRequest(
        'POST',
        endpoint,
        queryParameters: queryParameters,
        data: data,
      );

      final response = await _dioFor(host).post(
        endpoint,
        options: options,
        queryParameters: queryParameters,
        data: data,
      );
      log("SERVICE POST API EXECUTED SUCCESS $endpoint ${DateTime.now()}");
      return returnResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return returnResponse(e.response!);
      }
      throw convertDioExceptionToAppException(e);
    }
  }

  @override
  Future<APIResponse> deleteAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    try {
      // setting up path params with the endpoint
      endpoint = setupPathParams(endpoint, pathParameters);
      _logRequest(
        'DELETE',
        endpoint,
        queryParameters: queryParameters,
        data: data,
      );

      final defaultOptions = await _optionsFor(host, hasBody: data != null);
      final options = headers == null
          ? defaultOptions
          : defaultOptions.copyWith(
              headers: {...?defaultOptions.headers, ...headers},
            );
      final response = await _dioFor(host).delete(
        endpoint,
        options: options,
        data: data,
        queryParameters: queryParameters,
      );
      log("SERVICE DELETE API  EXECUTED SUCCESS $endpoint ${DateTime.now()}");

      return returnResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return returnResponse(e.response!);
      }
      throw convertDioExceptionToAppException(e);
    }
  }

  @override
  Future<APIResponse> patchAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    try {
      // setting up path params with the endpoint
      endpoint = setupPathParams(endpoint, pathParameters);
      _logRequest(
        'PATCH',
        endpoint,
        queryParameters: queryParameters,
        data: data,
      );

      final defaultOptions = await _optionsFor(host);
      final options = headers == null
          ? defaultOptions
          : defaultOptions.copyWith(
              headers: {...?defaultOptions.headers, ...headers},
            );
      final response = await _dioFor(host).patch(
        endpoint,
        options: options,
        queryParameters: queryParameters,
        data: data,
      );
      log("SERVICE PATCH API  EXECUTED SUCCESS $endpoint ${DateTime.now()}");

      return returnResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return returnResponse(e.response!);
      }
      throw convertDioExceptionToAppException(e);
    }
  }

  @override
  Future<APIResponse> putAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    try {
      // setting up path params with the endpoint
      endpoint = setupPathParams(endpoint, pathParameters);
      _logRequest(
        'PUT',
        endpoint,
        queryParameters: queryParameters,
        data: data,
      );

      final defaultOptions = await _optionsFor(host);
      final options = headers == null
          ? defaultOptions
          : defaultOptions.copyWith(
              headers: {...?defaultOptions.headers, ...headers},
            );
      final response = await _dioFor(host).put(
        endpoint,
        options: options,
        queryParameters: queryParameters,
        data: data,
      );
      log("SERVICE PUT API  EXECUTED SUCCESS $endpoint ${DateTime.now()}");

      return returnResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return returnResponse(e.response!);
      }
      throw convertDioExceptionToAppException(e);
    }
  }

  APIResponse returnResponse(Response response) {
    final int? statusCode = response.statusCode;
    final dynamic responseData = response.data;

    final bool isSuccess =
        statusCode == HttpStatus.ok ||
        statusCode == HttpStatus.created ||
        statusCode == HttpStatus.accepted;

    if (isSuccess) {
      String successMessage = 'Fetched Successfully.';
      dynamic data;

      if (responseData is Map<String, dynamic>) {
        successMessage = responseData['statusMessage'] ?? successMessage;
        data = responseData.containsKey('data')
            ? responseData['data']
            : responseData;
      } else {
        data = responseData;
      }

      return SuccessResponse(
        successMessage: successMessage,
        statusCode: statusCode!.toString(),
        data: data,
        rawData: responseData,
      );
    } else {
      String errorMessage = 'Something went wrong!';
      dynamic data;

      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['statusMessage'] ?? errorMessage;
        data = responseData['data'];
      } else {
        data = null;
      }

      return ErrorResponse(
        errorMessage: errorMessage,
        errorCode: statusCode!.toString(),
        data: data,
        rawData: responseData,
      );
    }
  }

  AppException convertDioExceptionToAppException(DioException error) {
    // Handle no internet (SocketException)
    if (error.type == DioExceptionType.unknown &&
        error.error is SocketException) {
      return InternetException();
    }

    // Handle timeouts
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return RequestTimeoutException();
    }

    // Handle other types (e.g. bad response, cancel, etc.)
    if (error.response != null) {
      final message =
          error.response?.data?['message'] ??
          'Something went wrong! Status Code: ${error.response?.statusCode}';
      return FetchDataException(message);
    }

    // Default fallback
    return FetchDataException(error.message ?? 'Unknown error occurred');
  }
}
