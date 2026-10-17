import '../../../../core/app/api/api_response.dart';
import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;
import '../../../../core/services/networking/endpoints.dart';
import '../../../../core/services/networking/networking.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/support_content_model.dart';

/// The code thrown when the server has no support content.
const String supportNotConfiguredCode = 'NOT_CONFIGURED';

/// Asks the app-state Edge Function for the Help & Support content only.
/// Returns a model or throws [ServerException] / [ConnectionException].
abstract interface class SupportRemoteDataSource {
  /// Throws [ServerException] with [supportNotConfiguredCode] when the
  /// server has none (`{ "support": null }`).
  Future<SupportContentModel> fetchSupport();
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  const SupportRemoteDataSourceImpl({
    required Networking networking,
    required String anonKey,
  }) : _networking = networking,
       _anonKey = anonKey;

  final Networking _networking;
  final String _anonKey;

  /// No surfaces, only the support content, as the previous app asks.
  static const Map<String, dynamic> requestBody = {
    'platform': 'app',
    'surfaces': <String>[],
    'include_support': true,
  };

  /// The function checks the caller's token, which stays as the service's
  /// default bearer; only the anon key is added.
  Map<String, String> get _edgeFunctionHeaders => {'apikey': _anonKey};

  @override
  Future<SupportContentModel> fetchSupport() async {
    final Object? response;
    try {
      response = await _networking.postAPICall(
        endpoint: Endpoints.appState,
        data: requestBody,
        headers: _edgeFunctionHeaders,
      );
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) {
      final status = int.tryParse(response.statusCode) ?? 200;
      final body = response.rawData;
      if (body is! Map) {
        throw ServerException(code: 'UNEXPECTED_RESPONSE', status: status);
      }
      final support = body['support'];
      if (support is! Map) {
        throw ServerException(code: supportNotConfiguredCode, status: status);
      }
      return SupportContentModel.fromJson(asMap(support));
    }
    if (response is ErrorResponse) throw _toServerException(response);
    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  /// Reads the Edge Function envelope `{ "code", "status", "detail" }`.
  ServerException _toServerException(ErrorResponse response) {
    final envelope = asMap(response.rawData);
    return ServerException(
      code: asString(envelope['code']) ?? 'UNKNOWN',
      status:
          asInt(envelope['status']) ?? int.tryParse(response.errorCode) ?? 0,
      detail: asString(envelope['detail']) ?? asString(envelope['message']),
    );
  }
}
