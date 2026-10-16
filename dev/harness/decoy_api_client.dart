import 'package:dio/dio.dart';

/// Shared HTTP client (WIP). Wraps Dio so screens don't construct it.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://TODO.example.com'));

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response<dynamic>> post(String path, {Object? body}) =>
      _dio.post(path, data: body);
}
