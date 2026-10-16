import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/networking/curl_logger_interceptor.dart';

void main() {
  test('a GET carries its headers and its query in the URL', () {
    final curl = CurlLoggerInterceptor.curlFor(
      RequestOptions(
        method: 'GET',
        baseUrl: 'https://api.stockship.example',
        path: '/api/orders',
        queryParameters: {'phone': '9876543210', 'mktp_id': 'MKTP-1'},
        headers: {'Authorization': 'Bearer ko_1'},
      ),
    );

    expect(
      curl,
      "curl -X GET -H 'Authorization: Bearer ko_1' "
      "'https://api.stockship.example/api/orders?phone=9876543210&mktp_id=MKTP-1'",
    );
  });

  test('a POST sends its map body as JSON, with its content type', () {
    final curl = CurlLoggerInterceptor.curlFor(
      RequestOptions(
        method: 'POST',
        baseUrl: 'https://utils.example',
        path: '/order/create-order',
        headers: {'x-request-id': 'req_1'},
        contentType: 'application/json',
        data: {'paid_amount': 188, 'mobile_number': '919876543210'},
      ),
    );

    expect(curl, contains("-H 'x-request-id: req_1'"));
    expect(curl.toLowerCase(), contains("-h 'content-type: application/json'"));
    expect(
      RegExp('content-type', caseSensitive: false).allMatches(curl),
      hasLength(1),
    );
    expect(
      curl,
      contains(
        """--data-raw '{"paid_amount":188,"mobile_number":"919876543210"}'""",
      ),
    );
    expect(curl, endsWith("'https://utils.example/order/create-order'"));
  });

  test("a single quote inside a value can't break out of the quoting", () {
    final curl = CurlLoggerInterceptor.curlFor(
      RequestOptions(
        method: 'POST',
        baseUrl: 'https://x.example',
        path: '/a',
        data: {'name': "O'Brien"},
      ),
    );

    expect(curl, contains(r"""--data-raw '{"name":"O'\''Brien"}'"""));
  });

  test('prints the command on request, and the status on response', () {
    final printed = <String>[];
    final interceptor = CurlLoggerInterceptor(printer: printed.add);
    final options = RequestOptions(
      method: 'GET',
      baseUrl: 'https://x.example',
      path: '/api/orders',
    );

    interceptor.onRequest(options, RequestInterceptorHandler());
    interceptor.onResponse(
      Response(requestOptions: options, statusCode: 200),
      ResponseInterceptorHandler(),
    );

    expect(printed.first, startsWith('[api] curl -X GET'));
    expect(printed.last, startsWith('[api] ← 200 GET /api/orders ('));
  });
}
