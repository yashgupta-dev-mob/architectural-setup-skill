// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints every request as a curl command that can be pasted into a
/// terminal, then the status it got back. Debug builds only:
/// `NetworkingService` adds it to each host's Dio when `kDebugMode`, so a
/// release never prints a token.
///
/// It sees each request after the service has added its headers, so the
/// command is exactly what went out, `Authorization` and `apikey`
/// included. Read it with the debug console, or
/// `adb logcat -s flutter`.
class CurlLoggerInterceptor extends Interceptor {
  const CurlLoggerInterceptor({void Function(String)? printer})
    : _printer = printer;

  final void Function(String)? _printer;

  static const String _startedAtKey = 'curl_logger.started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    _print('[api] ${curlFor(options)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _print(
      '[api] ← ${response.statusCode} ${_summary(response.requestOptions)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _print(
      '[api] ← ${status ?? err.type.name} ${_summary(err.requestOptions)}',
    );
    handler.next(err);
  }

  void _print(String message) => (_printer ?? debugPrint)(message);

  static String _summary(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    final took = startedAt is DateTime
        ? ' (${DateTime.now().difference(startedAt).inMilliseconds} ms)'
        : '';
    return '${options.method} ${options.uri.path}$took';
  }

  /// The curl command for [options]: the method, every header, the body
  /// (JSON-encoded when it is a map or list) and the full URL with its
  /// query. Each part is single-quoted for a POSIX shell (Git Bash,
  /// macOS, Linux).
  static String curlFor(RequestOptions options) {
    final parts = <String>['curl', '-X', options.method];

    final headers = <String, dynamic>{...options.headers};
    final contentType = options.contentType;
    if (contentType != null &&
        !headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = contentType;
    }
    headers.forEach((name, value) {
      if (value == null) return;
      parts
        ..add('-H')
        ..add(_quote('$name: $value'));
    });

    final body = _bodyOf(options.data);
    if (body != null) {
      parts
        ..add('--data-raw')
        ..add(_quote(body));
    }

    parts.add(_quote(options.uri.toString()));
    return parts.join(' ');
  }

  static String? _bodyOf(Object? data) {
    if (data == null) return null;
    if (data is String) return data.isEmpty ? null : data;
    if (data is FormData) {
      return [
        for (final field in data.fields) '${field.key}=${field.value}',
        for (final file in data.files) '${file.key}=@${file.value.filename}',
      ].join('&');
    }
    try {
      return jsonEncode(data);
    } on Object {
      return '$data';
    }
  }

  /// [value] in single quotes, with any single quote inside closed,
  /// escaped and reopened.
  static String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
}
