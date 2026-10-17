import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/app/exceptions/api_exceptions.dart';
import 'package:template_app/core/app/exceptions/app_exceptions.dart' as app;
import 'package:template_app/core/services/networking/endpoints.dart';
import 'package:template_app/features/support/data/datasources/support_remote_data_source.dart';

import '../../../../helpers/fake_networking.dart';

void main() {
  late FakeNetworking networking;
  late SupportRemoteDataSourceImpl dataSource;

  setUp(() {
    networking = FakeNetworking();
    dataSource = SupportRemoteDataSourceImpl(
      networking: networking,
      anonKey: 'anon',
    );
  });

  test(
    'asks app-state for the support content only, with the anon key',
    () async {
      networking.response = okResponse(const {
        'release_id': null,
        'items': <String, dynamic>{},
        'support': {
          'intro': 'Hi',
          'faqs': [
            {'q': 'Q', 'a': 'A'},
          ],
        },
      });

      final content = await dataSource.fetchSupport();

      expect(content.intro, 'Hi');
      expect(content.faqs.single.question, 'Q');
      expect(networking.lastCall.method, 'POST');
      expect(networking.lastCall.endpoint, Endpoints.appState);
      expect(networking.lastCall.headers, {'apikey': 'anon'});
      expect(networking.lastCall.data, {
        'platform': 'app',
        'surfaces': <String>[],
        'include_support': true,
      });
    },
  );

  test('no support content is "not configured"', () {
    networking.response = okResponse(const {'support': null});

    expect(
      dataSource.fetchSupport(),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          supportNotConfiguredCode,
        ),
      ),
    );
  });

  test('a body that is not an object is an unexpected response', () {
    networking.response = okResponse('nope');

    expect(
      dataSource.fetchSupport(),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          'UNEXPECTED_RESPONSE',
        ),
      ),
    );
  });

  test('an error keeps the envelope code and status', () {
    networking.response = errorResponse(const {
      'code': 'DB_ERROR',
      'status': 500,
    }, '500');

    expect(
      dataSource.fetchSupport(),
      throwsA(
        isA<ServerException>()
            .having((e) => e.code, 'code', 'DB_ERROR')
            .having((e) => e.status, 'status', 500),
      ),
    );
  });

  test('no answer is a connection exception', () {
    networking.error = app.AppException('offline', 'Timeout');

    expect(dataSource.fetchSupport(), throwsA(isA<ConnectionException>()));
  });
}
