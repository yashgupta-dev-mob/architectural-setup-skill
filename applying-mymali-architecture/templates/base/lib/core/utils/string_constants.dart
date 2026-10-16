// GENERIC: MyMali's storage key for the access token.
abstract class StringConstants {
  /// The signed-in user's access token, saved by `AuthLocalDataSource` and
  /// sent by `NetworkingService` as the default `Authorization` header.
  static const String appAuthToken = 'auth.access_token';
}
