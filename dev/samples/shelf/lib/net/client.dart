import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set to true by the interceptor when the server answers 401. The router's
/// redirect reads it, and a successful login sets it back to false.
final ValueNotifier<bool> signedOut = ValueNotifier<bool>(false);

/// The one Dio instance every feature talks through.
final Dio dio =
    Dio(
        BaseOptions(
          baseUrl: 'https://shelf-api.example.com',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'x-api-key': 'shelf_pk_123'},
        ),
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('session_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('session_token');
              signedOut.value = true;
            }
            handler.next(error);
          },
        ),
      );
