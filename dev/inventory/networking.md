# Inventory — area: networking

Repo: `C:/Users/Katyayani/Documents/flutter/mymali` (Dart package name `mymali`; every absolute import is `package:mymali/...`).
Everything below was read in full. Where AGENTS.md and the code differ, both are recorded (section 4).

Scope covered: `lib/core/services/networking/*`, `lib/core/app/api/api_response.dart`, `lib/core/app/exceptions/*`, `lib/core/app/failure.dart`, `lib/core/repositories/base_api_repository.dart` (+ `shared_pref_repository.dart` for context), `lib/core/utils/string_constants.dart`, `lib/core/config/env.dart`, `.env.example`, `lib/core/utils/json_readers.dart`, `lib/core/utils/currency_format.dart`, `lib/core/services/kotech/ko_token_service.dart`, the three worked-example data sources (auth, coupons, stockship) plus the other host examples they lead to (ref-orders, KO order, Medusa customer, catalog, cart, notifications, gstin, address), their exception files, the secure-storage interface `NetworkingService` depends on, the DI/bootstrap composition, and every test that exercises them.

---

## 1. Files

| path | role | class | placeholders |
|---|---|---|---|
| `lib/core/services/networking/networking.dart` | `ApiHost` enum, `Networking` abstract class, `NetworkingService` (Dio wrapper: one Dio per host, default headers per host, `APIResponse` mapping, `AppException` mapping) | ALWAYS | `ApiHost` values other than `supabase` (`medusa`, `koUtils`, `stockship`); `_thirdPartyHosts` set; `_dioFor` arms; the Supabase default headers (`Access-Control-Allow-Origin`, `referrer`); `StringConstants.appAuthToken` key; `package:mymali` |
| `lib/core/services/networking/endpoints.dart` | `Endpoints` (Supabase paths + the four mutable base-URL statics), `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | ALWAYS (shape: one `static const String` path class per host; `Endpoints` is the default-host class) | Every path; the extra host classes; the `Env` getter each base URL reads |
| `lib/core/services/networking/http_method.dart` | `enum HttpMethod { GET, POST, PATCH, PUT, DELETE }` — **unused anywhere** | ALWAYS (trivial; keep for name parity) or drop | none |
| `lib/core/services/networking/curl_logger_interceptor.dart` | `CurlLoggerInterceptor`: debug-only Dio interceptor printing each request as a runnable curl and its status | ALWAYS | log prefix `[api]` |
| `lib/core/app/api/api_response.dart` | `APIResponse` / `SuccessResponse` / `ErrorResponse` / `InvalidResponse` — the value every HTTP call returns | ALWAYS | none (contains one analyzer warning: `"${map ?? {}}"`) |
| `lib/core/app/exceptions/app_exceptions.dart` | `AppException` family thrown by `NetworkingService` only when **no response arrived** (`InternetException`, `RequestTimeoutException`, `FetchDataException`, … plus legacy `ServerException`, `InvalidUrlException`, `UnAuthorizedException`, `AuthException`) | ALWAYS | none |
| `lib/core/app/exceptions/api_exceptions.dart` | Typed data-layer exceptions: `ServerException(code, status, detail)`, `ConnectionException([message])` | ALWAYS | none |
| `lib/core/app/exceptions/cache_exceptions.dart` | `CacheException([message])` thrown by `LocalCache` / local data sources | CONDITIONAL (app caches server data with `LocalCache`) | none |
| `lib/core/app/failure.dart` | `Failure`, `NetworkFailure`, `ServerFailure(errorCode)`, `CacheMissFailure` | ALWAYS (`CacheMissFailure` CONDITIONAL on caching, but it lives in this one file) | none |
| `lib/core/repositories/base_api_repository.dart` | `BaseApiRepo`: one `Dio` field per host, each with its own base URL, **no timeouts** | ALWAYS | one `Dio` field per `ApiHost` (`dioSupabse` typo included), the `Endpoints.*BaseUrl` each reads |
| `lib/core/repositories/shared_pref_repository.dart` | `SharePrefRepo extends BaseApiRepo` — legacy (AGENTS.md §16); the only user of the legacy `StringConstants` keys | MYMALI-SPECIFIC / LEGACY — do not port | — |
| `lib/core/utils/string_constants.dart` | `StringConstants`: only `appAuthToken = 'auth.access_token'` is live (read by `NetworkingService`, defined-through by `AuthLocalDataSourceImpl.accessTokenKey`); the rest are legacy mutable statics | ALWAYS (the one const) | the key string `'auth.access_token'`; drop the legacy members |
| `lib/core/config/env.dart` | `Env` (`abstract final class`): `load()`, `_require`/`_optional`, typed getters; `KoEnv` + `_koValue` suffix switch; `RazorpayMode` + `allowTestPayments` debug gate | ALWAYS (the `Env`/`_require`/`_optional`/`load` shape); the env-switch (`KoEnv`, `_koValue`) and mode-switch (`RazorpayMode`) are CONDITIONAL (app has a vendor with prod/beta hosts; app has a test payment key) | every getter name and `.env` key; `KoEnv`/`_PROD`/`_BETA`; `RazorpayMode`/`RAZORPAY_*`; `MKTP_ID`, `KC_*`, `FB_*`, `APP_WEB_ORIGIN`, `MEDUSA_*` |
| `.env.example` | Placeholder copy of every `.env` key, grouped with comments | ALWAYS (file) | every key |
| `lib/core/utils/json_readers.dart` | Lenient JSON readers `asDouble`, `asInt`, `asNumeric`, `asString`, `asBool`, `asMap`, `asMapList`, `asStringList` | ALWAYS | none |
| `lib/core/utils/currency_format.dart` | `formatRupees(num)` via `intl` `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)` | CONDITIONAL (app shows money) | locale, symbol, decimals, function name |
| `lib/core/services/kotech/ko_token_service.dart` | `KoTokenService` / `KoTokenServiceImpl`: a bearer for a third-party host minted by an Edge Function, cached until `expirySkew` before expiry, one in-flight mint shared, `invalidate()` after 401 | CONDITIONAL (app calls a third-party host that needs a minted token) | names (`Ko…`), `Endpoints.kotechToken`, body `{refresh, env}`, response keys `access_token`/`expires_at`, log prefix `[ko-token]`, `KoEnv` |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Worked example: Edge Function POST with anon-key bearer, `_toServerException` for the `{code,status,title,detail}` envelope, `UNEXPECTED_RESPONSE` / `INVALID_RESPONSE` | ALWAYS as the **pattern** (file itself MYMALI-SPECIFIC: phone-login) | endpoint, models, header getter name `_supabaseHeaders` |
| `lib/features/coupons/data/datasources/coupon_remote_data_source.dart` | Worked example: PostgREST GET with `select`/`eq.`/`and=(or(...),or(...))`/`order`/`limit` query params, `apikey`-only headers, `_send` + `_rows` helpers, PostgREST envelope `{code,message,details,hint}` | ALWAYS as the pattern (file MYMALI-SPECIFIC: coupons) | table path, columns |
| `lib/features/orders/data/datasources/stockship_remote_data_source.dart` | Worked example: another host (`ApiHost.stockship`), `KoTokenService` bearer, 401 → invalidate + refresh + retry once, 404 → null, feature exceptions `StockshipException`/`KoTokenException` | CONDITIONAL pattern (third-party host with minted token) (file MYMALI-SPECIFIC) | host, endpoint, `mktp_id`, model |
| `lib/features/orders/data/exceptions/orders_exceptions.dart` | `StockshipException(status, [detail])`, `RefOrdersException(status, [detail])`, `KoTokenException()` — the "status 0 = nothing arrived" convention | MYMALI-SPECIFIC (shape generic) | names |
| `lib/features/orders/data/datasources/ref_order_remote_data_source.dart` | Second KO Utils example: token **optional** (sent when mintable; retry only if a token was sent) | MYMALI-SPECIFIC (pattern CONDITIONAL) | — |
| `lib/features/checkout/data/datasources/ko_order_remote_data_source.dart` | Third KO Utils example: `x-request-id` idempotency header, `_postWithToken`, KO error body `{message|error|msg, code?}` at top level or under `data`, 409 → `OrderInProgressException`, code fallback `HTTP_<status>` | MYMALI-SPECIFIC (pattern CONDITIONAL) | — |
| `lib/features/checkout/data/datasources/medusa_customer_data_source.dart` | Medusa host example: `x-publishable-api-key` + optional bearer, `_bodyOf` throwing `MedusaException` | MYMALI-SPECIFIC (pattern CONDITIONAL: app has a Medusa host) | — |
| `lib/features/checkout/data/exceptions/checkout_exceptions.dart` | `QuoteItemsUnavailableException`, `OrderInProgressException`, `OrderNotRegisteredException` **extend `ServerException`**; `MedusaException`, `OrderAttemptStorageException` implement `Exception` | MYMALI-SPECIFIC (subclassing pattern ALWAYS) | — |
| `lib/features/catalog/data/datasources/catalog_remote_data_source.dart` | The canonical **three header getters** (`_edgeFunctionHeaders`, `_restHeaders`, `_medusaHeaders`) and the combined Edge/PostgREST `_toServerException` | ALWAYS as pattern (file MYMALI-SPECIFIC) | — |
| `lib/features/cart/data/datasources/cart_remote_data_source.dart` | PostgREST upsert (`on_conflict`, `Prefer: resolution=merge-duplicates,return=minimal`) and DELETE with `Prefer: return=representation` (204 would be an `ErrorResponse`) | ALWAYS as pattern (file MYMALI-SPECIFIC) | — |
| `lib/features/notifications/data/datasources/notifications_remote_data_source.dart` | PostgREST PATCH with `Prefer: return=representation` | ALWAYS as pattern (file MYMALI-SPECIFIC) | — |
| `lib/features/gstin/data/datasources/gstin_remote_data_source.dart` | PostgREST upsert with injected `DateTime Function() now` | MYMALI-SPECIFIC | — |
| `lib/features/address/data/datasources/address_remote_data_source.dart` | User-scoped Edge Functions: `_edgeFunctionHeaders => {'apikey': anon}` only (user token stays the bearer); `_expectOk` for `{ok:true}`; envelope parser that also reads the gateway's `{code: 401, message}` | ALWAYS as pattern (file MYMALI-SPECIFIC) | — |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | How a repository maps `ServerException.code` → feature `Failure`, `ConnectionException` → `NetworkFailure`, fallback `ServerFailure(errorCode: e.code, code: e.status)` | ALWAYS as pattern | — |
| `lib/features/auth/data/datasources/auth_local_data_source.dart` | Owns the token keys; `accessTokenKey = StringConstants.appAuthToken`, `refreshTokenKey = 'auth.refresh_token'`, `userIdKey = 'auth.user_id'` | CONDITIONAL (app stores tokens) — belongs to the auth/secure-storage area, listed because `NetworkingService` reads the same key | — |
| `lib/core/services/secure_storage/secure_storage.dart`, `device_secure_storage.dart` | `SecureStorage` interface `NetworkingService` reads the access token from; `DeviceSecureStorage` (in-memory shared `_memory`, never throws) | CONDITIONAL (app stores tokens) — secure-storage area; `NetworkingService` constructor defaults to `DeviceSecureStorage()` | — |
| `lib/core/di/injection_container.dart` (`_registerCore`, `_registerAuthData`, `_registerOrdersData`, `_registerCouponsData`, `_registerCheckoutData`) | Registration shape: `registerLazySingleton<Networking>(() => NetworkingService(secureStorage: sl()))`, data sources by abstract type with `Env.*` keys injected | ALWAYS (pattern) | which keys each data source takes |
| `lib/app/bootstrap.dart` | Startup order: `Env.load()` → Firebase → `DeviceSecureStorage.init()` → `Supabase.initialize` → `HiveLocalCache.init()` → `configureDependencies()` | ALWAYS (order) | the Supabase/Firebase/Hive steps are CONDITIONAL |
| `test/helpers/fake_networking.dart` | `FakeNetworking implements Networking` (records `RecordedCall`s; `response`/`error`/`queued`), `okResponse(body)`, `errorResponse(body, status)` | ALWAYS | none |
| `test/helpers/fake_secure_storage.dart` | `FakeSecureStorage implements SecureStorage` | CONDITIONAL (tokens) | none |
| `test/core/services/networking/curl_logger_interceptor_test.dart` | 4 tests on `curlFor` and the printed lines | ALWAYS | none |
| `test/core/config/env_test.dart` | `dotenv.loadFromString(envString:)` tests for `koEnv`, `_koValue`, `razorpayMode`, `allowTestPayments` | ALWAYS (shape) | keys |
| `test/core/utils/currency_format_test.dart` | `formatRupees` tests | CONDITIONAL | — |
| `test/core/services/kotech/ko_token_service_test.dart` | 7 tests: mint body/headers, 5-min skew, 30-min fallback, refresh, shared in-flight, invalidate, refused/offline → null | CONDITIONAL | — |
| `test/features/auth/data/datasources/auth_remote_data_source_test.dart`, `test/features/coupons/data/datasources/coupon_remote_data_source_test.dart`, `test/features/orders/data/datasources/stockship_remote_data_source_test.dart`, `test/features/orders/data/datasources/ref_order_remote_data_source_test.dart` | Data-source tests against `FakeNetworking` (`_FakeTokens implements KoTokenService` inline) | pattern ALWAYS | — |

**Not present (but named by AGENTS.md):** `lib/core/app/api/endpoint.dart` — `lib/core/app/api/` holds only `api_response.dart`.
**No test exists** for `NetworkingService` itself (`returnResponse`, `convertDioExceptionToAppException`, header defaults), for `APIResponse`, or for the exception classes.

---

## 2. Names

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `ApiHost` | enum | networking.dart | `enum ApiHost { supabase, medusa, koUtils, stockship }` |
| `Networking` | abstract class | networking.dart | `abstract class Networking` with `getAPICall`, `postAPICall`, `patchAPICall`, `putAPICall`, `deleteAPICall` (all `Future<dynamic>`), `graphqlQueryCall` (`Future<APIResponse>`); see §3.1 |
| `Networking.getAPICall` | method | networking.dart | `Future<dynamic> getAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, Map<String, String>? headers, ApiHost host = ApiHost.supabase})` |
| `Networking.postAPICall` | method | networking.dart | `Future<dynamic> postAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, dynamic data, Map<String, String>? headers, ApiHost host = ApiHost.supabase})` |
| `Networking.patchAPICall` | method | networking.dart | same parameter list as `postAPICall` |
| `Networking.putAPICall` | method | networking.dart | `Future<dynamic> putAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, dynamic data, ApiHost host = ApiHost.supabase})` — **no `headers`** |
| `Networking.deleteAPICall` | method | networking.dart | same parameter list as `postAPICall` |
| `Networking.graphqlQueryCall` | method | networking.dart | `Future<APIResponse> graphqlQueryCall({required String graphqlEndpoint, required String query, Map<String, dynamic>? variables})` — legacy, unused |
| `NetworkingService` | class | networking.dart | `class NetworkingService extends BaseApiRepo implements Networking`; `NetworkingService({this.options, SecureStorage? secureStorage})`; public field `final Options? options`; public `String setupPathParams(String endpoint, Map<String, dynamic>? pathParameters)`, `APIResponse returnResponse(Response response)`, `AppException convertDioExceptionToAppException(DioException error)`; the five overrides return `Future<APIResponse>` |
| `Endpoints` | class | endpoints.dart | `static String baseUrlMain = Env.supabaseUrl; static String medusaBaseUrl = Env.medusaBaseUrl; static String koUtilsBaseUrl = Env.utilsUrl; static String stockshipBaseUrl = Env.stockshipUrl;` + `static const String` paths (§3.3) |
| `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | classes | endpoints.dart | `static const String` paths only (§3.3) |
| `HttpMethod` | enum | http_method.dart | `enum HttpMethod { GET, POST, PATCH, PUT, DELETE }` |
| `CurlLoggerInterceptor` | class | curl_logger_interceptor.dart | `class CurlLoggerInterceptor extends Interceptor`; `const CurlLoggerInterceptor({void Function(String)? printer})`; `static String curlFor(RequestOptions options)`; overrides `onRequest`, `onResponse`, `onError` |
| `APIResponse` | abstract class | api_response.dart | `abstract class APIResponse extends Equatable { final dynamic data; final String code; final String message; const APIResponse({this.data, this.code = '', this.message = ''}); props => [data, code, message]; }` |
| `SuccessResponse` | class | api_response.dart | `const SuccessResponse({required this.successMessage, required this.statusCode, required this.rawData, required super.data}) : super(code: statusCode, message: successMessage)`; fields `String successMessage`, `String statusCode`, `dynamic rawData`; `copyWith`, `toMap`, `fromMap`, `toJson`, `fromJson`; `props => [successMessage, statusCode, data]` |
| `ErrorResponse` | class | api_response.dart | `const ErrorResponse({required this.errorMessage, required this.errorCode, this.rawData, required super.data}) : super(code: errorCode, message: errorMessage)`; fields `String errorMessage`, `String errorCode`, `dynamic rawData`; `copyWith`, `toMap`, `fromMap`, `toJson`, `fromJson`, `toString`; `props => [errorMessage, errorCode, data]` |
| `InvalidResponse` | class | api_response.dart | `const InvalidResponse() : super(code: 'INVALID_RESPONSE', message: 'Invalid API response')` — unused |
| `AppException` | class | app_exceptions.dart | `class AppException implements Exception { final String message; final String prefix; AppException(this.message, this.prefix); toString() => '$prefix: $message'; }` |
| `InternetException` | class | app_exceptions.dart | `InternetException([String? message]) : super(message ?? 'No internet', 'Internet')` |
| `RequestTimeoutException` | class | app_exceptions.dart | `RequestTimeoutException([String? message]) : super(message ?? 'Request timed out', 'Request Timeout')` |
| `ServerException` (legacy, app_exceptions) | class | app_exceptions.dart | `ServerException([String? message]) : super(message ?? 'Internal server error', 'Server')` — **name clash** with api_exceptions.dart; never thrown by the service |
| `InvalidUrlException` | class | app_exceptions.dart | `InvalidUrlException([String? message]) : super(message ?? 'Invalid URL', 'Invalid URL')` — unused |
| `FetchDataException` | class | app_exceptions.dart | `FetchDataException([String? message]) : super(message ?? 'Error during data fetching', 'Fetch Data')` |
| `UnAuthorizedException` | class | app_exceptions.dart | `UnAuthorizedException([String? message]) : super(message ?? 'Error during data fetching', 'UnAuthorized')` — unused |
| `AuthException` | class | app_exceptions.dart | `class AuthException extends AppException { final String message; AuthException(this.message) : super(message, ""); }` — unused, shadows `message` |
| `ServerException` | class | api_exceptions.dart | `const ServerException({required this.code, required this.status, this.detail}); final String code; final int status; final String? detail; toString() => 'ServerException($status $code: $detail)'` |
| `ConnectionException` | class | api_exceptions.dart | `const ConnectionException([this.message]); final String? message; toString() => 'ConnectionException($message)'` |
| `CacheException` | class | cache_exceptions.dart | `const CacheException([this.message]); final String? message; toString() => 'CacheException($message)'` |
| `Failure` | class | failure.dart | `class Failure { final String message; final int? code; Failure({required this.message, this.code}); toString() => 'Failure(code: $code, message: $message)'; }` — **not** Equatable |
| `NetworkFailure` | class | failure.dart | `NetworkFailure({super.message = 'No internet connection.', super.code})` |
| `ServerFailure` | class | failure.dart | `ServerFailure({required this.errorCode, super.message = 'Something went wrong.', super.code}); final String errorCode;` |
| `CacheMissFailure` | class | failure.dart | `CacheMissFailure({super.message = 'Nothing saved on this device.'})` |
| `BaseApiRepo` | class | base_api_repository.dart | `class BaseApiRepo { Dio dioSupabse = Dio(BaseOptions(baseUrl: Endpoints.baseUrlMain)); Dio dioMedusa = Dio(BaseOptions(baseUrl: Endpoints.medusaBaseUrl)); Dio dioKoUtils = Dio(BaseOptions(baseUrl: Endpoints.koUtilsBaseUrl)); Dio dioStockship = Dio(BaseOptions(baseUrl: Endpoints.stockshipBaseUrl)); }` (note the `dioSupabse` spelling) |
| `StringConstants` | abstract class | string_constants.dart | `static const String appAuthToken = 'auth.access_token';` (live) + legacy `static String` members |
| `KoEnv` | enum | env.dart | `enum KoEnv { production, beta }` |
| `RazorpayMode` | enum | env.dart | `enum RazorpayMode { live, test }` |
| `Env` | abstract final class | env.dart | `static Future<void> load()`; getters `supabaseUrl`, `supabaseAnonKey`, `medusaBaseUrl`, `medusaApiKey`, `webOrigin`, `koEnv`, `utilsUrl`, `stockshipUrl`, `razorpayKeyId`, `razorpayMode`, `mktpId`, `kcSiteId`, `kcApiUrl`, `fbAppId` (`String?`), `fbClientToken` (`String?`), `appVersion`; `@visibleForTesting static bool allowTestPayments = kDebugMode`; private `_fileName = '.env'`, `_koValue`, `_optional`, `_require` |
| `asDouble`, `asInt`, `asNumeric`, `asString`, `asBool`, `asMap`, `asMapList`, `asStringList` | top-level functions | json_readers.dart | §3.10 |
| `formatRupees` | top-level function | currency_format.dart | `String formatRupees(num amount)` |
| `KoTokenService` | abstract interface class | ko_token_service.dart | `Future<String?> token({bool refresh = false}); void invalidate();` |
| `KoTokenServiceImpl` | class | ko_token_service.dart | `KoTokenServiceImpl({required Networking networking, required String anonKey, required KoEnv env, DateTime Function() now = DateTime.now})`; `static const Duration expirySkew = Duration(minutes: 5)`; `static const Duration fallbackLifetime = Duration(minutes: 30)` |
| `AuthRemoteDataSource` / `AuthRemoteDataSourceImpl` | interface / impl | auth_remote_data_source.dart | `const AuthRemoteDataSourceImpl({required Networking networking, required String anonKey})`; `Future<SendOtpResponseModel> sendOtp(OtpRequestModel)`, `Future<AuthTokensModel> verifyOtp(VerifyOtpRequestModel)` |
| `CouponRemoteDataSource` / `CouponRemoteDataSourceImpl` | interface / impl | coupon_remote_data_source.dart | `const CouponRemoteDataSourceImpl({required Networking networking, required String anonKey})`; `Future<List<CouponModel>> fetchActive(DateTime now)`, `Future<CouponModel?> fetchByCode(String code)` |
| `StockshipRemoteDataSource` / `StockshipRemoteDataSourceImpl` | interface / impl | stockship_remote_data_source.dart | `static const int pageSize = 20` on the interface; `const StockshipRemoteDataSourceImpl({required Networking networking, required KoTokenService tokens, required String mktpId})`; `listOrders({required String phone, int page = 1, int limit = pageSize})`, `listOrderPage(...)`, `getOrder({required String orderId})` |
| `StockshipException`, `RefOrdersException` | classes | orders_exceptions.dart | `const StockshipException(this.status, [this.detail]); final int status; final String? detail;` (same for `RefOrdersException`) |
| `KoTokenException` | class | orders_exceptions.dart | `const KoTokenException(); toString() => 'KoTokenException(no token)'` |
| `RefOrderRemoteDataSource(Impl)` | interface / impl | ref_order_remote_data_source.dart | `const RefOrderRemoteDataSourceImpl({required Networking networking, required KoTokenService tokens})`; `listByPhone({required String tenDigitPhone})`, `getByRefId({required String refId})` |
| `KoOrderRemoteDataSource(Impl)` | interface / impl | ko_order_remote_data_source.dart | `const KoOrderRemoteDataSourceImpl(this._networking, {KoTokenService? tokens})`; `static const String requestIdHeader = 'x-request-id'`; `paymentStatusSource = 'app'`; `couponNotApplicableCode = 'COUPON_NOT_APPLICABLE'`; `unbuyableItemCode = 'UNBUYABLE_ITEM'` |
| `MedusaCustomerDataSource(Impl)` | interface / impl | medusa_customer_data_source.dart | `const MedusaCustomerDataSourceImpl({required Networking networking, required String publishableKey})` |
| `MedusaException` | class | checkout_exceptions.dart | `const MedusaException(this.status, [this.detail])` |
| `OrderInProgressException` | class | checkout_exceptions.dart | `extends ServerException`; `const OrderInProgressException({super.detail}) : super(code: 'ORDER_IN_PROGRESS', status: 409)` |
| `OrderNotRegisteredException` | class | checkout_exceptions.dart | `extends ServerException`; `const OrderNotRegisteredException({required super.status, super.detail}) : super(code: 'NOT_REGISTERED')` |
| `QuoteItemsUnavailableException` | class | checkout_exceptions.dart | `extends ServerException`; `const QuoteItemsUnavailableException({required super.code, required super.status, super.detail, this.productIds = const []})` |
| `SecureStorage` | abstract interface class | secure_storage.dart | `Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key);` |
| `DeviceSecureStorage` | class | device_secure_storage.dart | `DeviceSecureStorage({FlutterSecureStorage storage = _storage})`; `static const String installedKey = 'secure_storage.installed'`; `static Future<void> init({PrefUtils? prefs, FlutterSecureStorage storage = _storage})`; `@visibleForTesting static void resetMemory()` |
| `AuthLocalDataSourceImpl.accessTokenKey / refreshTokenKey / userIdKey` | static consts | auth_local_data_source.dart | `= StringConstants.appAuthToken` / `'auth.refresh_token'` / `'auth.user_id'` |
| `sl`, `configureDependencies` | DI | injection_container.dart | `final GetIt sl = GetIt.instance; void configureDependencies()` |
| `FakeNetworking`, `RecordedCall`, `okResponse`, `errorResponse` | test helpers | test/helpers/fake_networking.dart | §3.14 |
| `FakeSecureStorage` | test helper | test/helpers/fake_secure_storage.dart | `FakeSecureStorage([Map<String, String>? values]); final Map<String, String> values;` |

Error-code string constants used across data sources (must match exactly): `'UNEXPECTED_RESPONSE'`, `'INVALID_RESPONSE'`, `'UNKNOWN'`, `'HTTP_$status'` (KO), `'NOT_CONFIRMED'` (KO 2xx with `success:false`), `'ORDER_IN_PROGRESS'`, `'NOT_REGISTERED'`.

---

## 3. Patterns

### 3.1 `networking.dart` — complete file (reproduce character for character, substituting the placeholders in §6)

```dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:mymali/core/app/api/api_response.dart';
import 'package:mymali/core/app/exceptions/app_exceptions.dart';
import 'package:mymali/core/repositories/base_api_repository.dart';
import 'package:mymali/core/services/secure_storage/device_secure_storage.dart';
import 'package:mymali/core/services/secure_storage/secure_storage.dart';
import 'package:mymali/core/utils/string_constants.dart';

import 'curl_logger_interceptor.dart';

/// The backend a call goes to. Each has its own Dio and base URL, so
/// endpoints stay relative to the chosen host.
enum ApiHost {
  supabase,
  medusa,

  /// KO-Tech's Utils service, where orders are placed. It is not ours, so
  /// the app's own token is never sent to it.
  koUtils,

  /// KO-Tech's StockShip, the warehouse that holds and ships the orders.
  /// Calls carry a KO token minted by the `kotech-token` Edge Function.
  stockship,
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

  Future<dynamic> putAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
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

  /// Holds the access token saved by `AuthLocalDataSource`.
  final SecureStorage _secureStorage;

  NetworkingService({this.options, SecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? DeviceSecureStorage() {
    // Every request printed as a curl command; debug builds only.
    if (kDebugMode) {
      for (final dio in [dioSupabse, dioMedusa, dioKoUtils, dioStockship]) {
        dio.interceptors.add(const CurlLoggerInterceptor());
      }
    }
  }

  Dio _dioFor(ApiHost host) => switch (host) {
    ApiHost.supabase => dioSupabse,
    ApiHost.medusa => dioMedusa,
    ApiHost.koUtils => dioKoUtils,
    ApiHost.stockship => dioStockship,
  };

  /// Hosts that are not Supabase. They get none of the app's default
  /// headers (no Supabase session token, no CORS or referrer headers): only
  /// a `Content-Type` when [hasBody], plus what the call itself passes, so
  /// a request looks exactly as the previous app's plain `fetch` did. For
  /// Medusa the call passes the publishable key, and a Medusa bearer when
  /// it has one.
  static const Set<ApiHost> _thirdPartyHosts = {
    ApiHost.medusa,
    ApiHost.koUtils,
    ApiHost.stockship,
  };

  /// The default headers for [host].
  Future<Options> _optionsFor(
    ApiHost host, {
    String? contentType,
    bool hasBody = true,
  }) async {
    if (!_thirdPartyHosts.contains(host)) {
      return _getOptions(contentType: contentType);
    }
    return Options(
      headers: {if (hasBody) 'Content-Type': contentType ?? 'application/json'},
    );
  }

  Future<Options> _getOptions({String? contentType}) async {
    final token = await _secureStorage.read(StringConstants.appAuthToken);
    return options ??
        Options(
          headers: {
            'Content-Type': contentType ?? 'application/json',
            'Access-Control-Allow-Origin': "*",
            "Authorization": "Bearer ${token ?? ""}",
            "referrer": "",
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

      log("SERVICE GET API  EXECUTED SUCCESS ${endpoint} ${DateTime.now()}");

      return returnResponse(response);
    } on DioException catch (e) {
      log(
        "SERVICE GET ERROR ${endpoint} ${DateTime.now()} - ${e.response?.data}",
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
      log("SERVICE POST API EXECUTED SUCCESS ${endpoint} ${DateTime.now()}");
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
      log("SERVICE DELETE API  EXECUTED SUCCESS ${endpoint} ${DateTime.now()}");

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
      log("SERVICE PATCH API  EXECUTED SUCCESS ${endpoint} ${DateTime.now()}");

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

      final response = await _dioFor(host).put(
        endpoint,
        options: await _optionsFor(host),
        queryParameters: queryParameters,
        data: data,
      );
      log("SERVICE PUT API  EXECUTED SUCCESS ${endpoint} ${DateTime.now()}");

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
```

**Rule encoded.** One service, one `Dio` per host, selected by `ApiHost`. Whenever the server replied (any status, including 4xx/5xx, which Dio raises as `DioException` *with* `response`), the service **returns** an `APIResponse`: `SuccessResponse` for 200/201/202, `ErrorResponse` otherwise (so 204 is an error). It **throws** an `AppException` only when `e.response == null` (offline, timeout, DNS, TLS, cancel). Per-call `headers` are spread over the host's defaults with a plain map spread (last key wins, case-sensitive map keys). Supabase gets `_getOptions` (token bearer); third-party hosts get only `Content-Type` when the method carries a body (`hasBody`: GET `false`, DELETE `data != null`, POST/PATCH/PUT `true`). What varies: the `ApiHost` values after `supabase`, the `_thirdPartyHosts` membership, the `_dioFor` arms, the Dio field names, and the exact default header set for the default host.

### 3.2 `base_api_repository.dart` — complete

```dart
import 'package:dio/dio.dart';
import 'package:mymali/core/services/networking/endpoints.dart';

class BaseApiRepo {
  Dio dioSupabse = Dio(BaseOptions(baseUrl: Endpoints.baseUrlMain));
  Dio dioMedusa = Dio(BaseOptions(baseUrl: Endpoints.medusaBaseUrl));

  /// No receive timeout, deliberately: a COD order takes ~44 s, and giving
  /// up early leaves an order placed while the customer is told it failed.
  Dio dioKoUtils = Dio(BaseOptions(baseUrl: Endpoints.koUtilsBaseUrl));
  Dio dioStockship = Dio(BaseOptions(baseUrl: Endpoints.stockshipBaseUrl));
}
```

**Rule.** One non-final `Dio` field per host, `BaseOptions(baseUrl:)` only — no connect/send/receive timeouts anywhere. Field initializers run when `NetworkingService` is constructed, which reads **all** base URLs from `Env` at that moment. The misspelling `dioSupabse` is referenced by `NetworkingService` and must be kept if the file is copied verbatim.

### 3.3 `endpoints.dart` — complete

```dart
import 'package:mymali/core/config/env.dart';

class Endpoints {
  // sample endpoint -
  //! "/login"
  //! if any path params - "/text/{userId}/{key}"

  static String baseUrlMain = Env.supabaseUrl;
  static String medusaBaseUrl = Env.medusaBaseUrl;
  static String koUtilsBaseUrl = Env.utilsUrl;
  static String stockshipBaseUrl = Env.stockshipUrl;

  // Auth
  static const String phoneLogin = '/functions/v1/phone-login';

  // Home / catalog
  static const String catalogCache = '/functions/v1/catalog-cache';
  static const String appState = '/functions/v1/app-state';
  static const String productSold = '/rest/v1/product_sold';
  static const String productsV2 = '/rest/v1/products_v2';

  // Wishlist (and other per-user lists kept by the user-data function)
  static const String userData = '/functions/v1/user-data';

  // Cart: the server copy of the cart lines, and the free-delivery and
  // small-cart-fee settings the cart page reads.
  static const String cartItems = '/rest/v1/cart_items_v2';
  static const String chargeRules = '/rest/v1/charge_rules';

  // Addresses: the signed-in user's saved delivery addresses.
  static const String listAddresses = '/functions/v1/list-addresses';
  static const String saveAddress = '/functions/v1/save-address';
  static const String removeAddress = '/functions/v1/remove-address';

  // Mali Coins: the loyalty ledger (`action: rules | balance | welcome`).
  static const String maliCoins = '/functions/v1/mali-coins';

  // Coupons: the one table the checkout bills from, and the only source
  // of coupons.
  static const String coupons = '/rest/v1/coupons';

  // Checkout: the server prices the cart (charges, coupon, coins, total).
  static const String checkoutQuote = '/functions/v1/checkout-quote';

  // Our own record of an order KO accepted: spends the quote, debits the
  // coins and feeds referral, rating and the admin orders table.
  static const String placeOrder = '/functions/v1/place-order';

  // The seller printed on invoices: `{ seller: { legal_name, address_lines,
  // phone, gstin, gst_rate } | null }`.
  static const String sellerInfo = '/functions/v1/seller-info';

  // KO-Tech token for StockShip (and later the prepaid order calls);
  // `{ refresh, env }` → `{ access_token, expires_at }`.
  static const String kotechToken = '/functions/v1/kotech-token';

  // GSTIN: the business GSTINs a customer saved for invoicing.
  static const String gstins = '/rest/v1/mali_gstins';

  // Notifications: the in-app inbox (`app_notifications`), one row per push.
  static const String appNotifications = '/rest/v1/app_notifications';

  // Product page: reviews (`action: list | submit | update | delete`) and
  // the pincodes the shop delivers to.
  static const String reviews = '/functions/v1/reviews';
  static const String serviceablePincodes = '/rest/v1/serviceable_pincodes';

  // Profile: the signed-in user's name and email (`mali_profiles`, keyed
  // by user key).
  static const String profiles = '/rest/v1/mali_profiles';

  // Refer & Earn: the user's code and stats (`action: me`) and claiming a
  // friend's code (`action: claim`).
  static const String referral = '/functions/v1/referral';
}

class MedusaEndpoints {
  static const String products = '/store/products';

  /// One product; pass `id` as a path parameter.
  static const String product = '/store/products/{id}';
  static const String regions = '/store/regions';

  // The customer behind an order. The app signs in to Medusa with a bridge
  // email and a derived password (see MedusaCustomerDataSource).
  static const String customerLogin = '/auth/customer/emailpass';
  static const String customerRegister = '/auth/customer/emailpass/register';
  static const String tokenRefresh = '/auth/token/refresh';
  static const String customers = '/store/customers';
  static const String customerMe = '/store/customers/me';
}

/// KO-Tech Utils paths (`ApiHost.koUtils`); the host follows `KO_ENV`.
class KoUtilsEndpoints {
  /// Places a COD order; answers with the Medusa `display_id`. Takes an
  /// `x-request-id` header: a known id returns the same order.
  static const String codOrder = '/order/my-mali';

  /// Registers an order paid online and creates its Razorpay order;
  /// answers with `razorpay_order_id`. Takes the same `x-request-id`
  /// header: a known id returns the same Razorpay order, `duplicate: true`.
  static const String createOrder = '/order/create-order';

  /// Whether a Razorpay order's money was captured
  /// (`{ rzp_order_id, payment_id?, source: "app" }` →
  /// `paymentResult.success`). `source: "app"` keeps it read-only.
  static const String paymentStatus = '/order/payment-status-ksr';

  /// The orders KO registered that the warehouse may not hold yet:
  /// `?user_phone=+91…` lists a customer's, `?ref_id=` fetches one. Any
  /// other query parameter is read as a field filter and matches nothing.
  static const String refOrders = '/order/ref-orders';
}

/// StockShip paths (`ApiHost.stockship`); the host follows `KO_ENV`.
class StockshipEndpoints {
  /// The customer's orders: `?phone=&mktp_id=&page=&limit=` lists them,
  /// `?order_id=&mktp_id=` fetches one.
  static const String orders = '/api/orders';
}
```

**Rule.** The default-host class `Endpoints` also carries the base URLs as **mutable `static String`** fields (they cannot be `const` because they read `Env`; they are evaluated lazily on first access, after `Env.load()`). Every path is relative and a `static const String`, grouped by feature with a comment, path parameters as `{name}`. One extra class per extra host, named `<Host>Endpoints`. Supabase paths follow `/functions/v1/<fn>` for Edge Functions and `/rest/v1/<table>` for PostgREST.

### 3.4 `curl_logger_interceptor.dart` — complete

```dart
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
```

Expected output (from the test): `[api] curl -X GET -H 'Authorization: Bearer ko_1' 'https://api.stockship.example/api/orders?phone=9876543210&mktp_id=MKTP-1'`, then `[api] ← 200 GET /api/orders (12 ms)`; on a no-response error `[api] ← connectionTimeout GET /api/orders (…)`. The `printer` parameter exists for tests; default is `debugPrint`.

### 3.5 `api_response.dart` — complete

```dart
import 'dart:convert';
import 'dart:developer';

import 'package:equatable/equatable.dart';

abstract class APIResponse extends Equatable {
  final dynamic data;
  final String code;
  final String message;

  const APIResponse({this.data, this.code = '', this.message = ''});

  @override
  List<Object?> get props => [data, code, message];
}

class SuccessResponse extends APIResponse {
  final String successMessage;
  final String statusCode;
  final dynamic rawData;
  const SuccessResponse({
    required this.successMessage,
    required this.statusCode,
    required this.rawData,
    required super.data,
  }) : super(code: statusCode, message: successMessage);

  SuccessResponse copyWith({
    String? successMessage,
    String? statusCode,
    dynamic rawData,
    dynamic data,
  }) {
    return SuccessResponse(
      successMessage: successMessage ?? this.successMessage,
      statusCode: statusCode ?? this.statusCode,
      data: data ?? this.data,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'statusMessage': successMessage,
      'statusCode': statusCode,
      'data': data,
    };
  }

  factory SuccessResponse.fromMap(Map<String, dynamic> map) {
    log("${map ?? {}}");
    return SuccessResponse(
      successMessage: map['statusMessage'] as String,
      statusCode: map['statusCode'] as String,
      data: map['data'] as dynamic,
      rawData: map["rawData"] as dynamic,
    );
  }

  String toJson() => json.encode(toMap());

  factory SuccessResponse.fromJson(String source) =>
      SuccessResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [successMessage, statusCode, data];
}

class ErrorResponse extends APIResponse {
  final String errorMessage;
  final String errorCode;
  final dynamic rawData;
  const ErrorResponse({
    required this.errorMessage,
    required this.errorCode,
    this.rawData,
    required super.data,
  }) : super(code: errorCode, message: errorMessage);

  ErrorResponse copyWith({
    String? errorMessage,
    String? errorCode,
    dynamic data,
    dynamic rawData,
  }) {
    return ErrorResponse(
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      data: data ?? this.data,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'statusMessage': errorMessage,
      'statusCode': errorCode,
      'data': data,
    };
  }

  factory ErrorResponse.fromMap(Map<String, dynamic> map) {
    // these can be changed according to the structure of API'S
    return ErrorResponse(
      errorMessage: map['statusMessage'] as String,
      errorCode: map['statusCode'] as String,
      data: map['data'] as dynamic,
    );
  }

  String toJson() => json.encode(toMap());

  factory ErrorResponse.fromJson(String source) =>
      ErrorResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ErrorResponse(errorMessage: $errorMessage, data: $data)';

  @override
  List<Object> get props => [errorMessage, errorCode, data];
}

class InvalidResponse extends APIResponse {
  const InvalidResponse()
    : super(code: 'INVALID_RESPONSE', message: 'Invalid API response');
}
```

**Rule.** `statusCode` / `errorCode` are **strings** (`'200'`, `'401'`); data sources compare `response.errorCode == '401'` and parse with `int.tryParse`. `data` is the server body's `data` key when the body is a map that has one, else the whole body; data sources **always read `rawData`**, never `data`. `rawData` on `SuccessResponse` is required; on `ErrorResponse` it is optional (positional default null). `InvalidResponse` is never constructed; the "neither Success nor Error" branch in data sources is handled by throwing `ServerException(code: 'INVALID_RESPONSE', status: 0)` instead.

### 3.6 Exceptions and failures — complete files

`lib/core/app/exceptions/app_exceptions.dart` (what `NetworkingService` throws):
```dart
class AppException implements Exception {
  final String message;
  final String prefix;

  AppException(this.message, this.prefix);

  @override
  String toString() {
    return '$prefix: $message';
  }
}

class InternetException extends AppException {
  InternetException([String? message])
    : super(message ?? 'No internet', 'Internet');
}

class RequestTimeoutException extends AppException {
  RequestTimeoutException([String? message])
    : super(message ?? 'Request timed out', 'Request Timeout');
}

class ServerException extends AppException {
  ServerException([String? message])
    : super(message ?? 'Internal server error', 'Server');
}

class InvalidUrlException extends AppException {
  InvalidUrlException([String? message])
    : super(message ?? 'Invalid URL', 'Invalid URL');
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
    : super(message ?? 'Error during data fetching', 'Fetch Data');
}

class UnAuthorizedException extends AppException {
  UnAuthorizedException([String? message])
    : super(message ?? 'Error during data fetching', 'UnAuthorized');
}

class AuthException extends AppException {
  final String message;
  AuthException(this.message) : super(message, "");
}
```

`lib/core/app/exceptions/api_exceptions.dart` (what data sources throw):
```dart
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
```

`lib/core/app/exceptions/cache_exceptions.dart`:
```dart
/// The device cache could not be read or written. Thrown by `LocalCache`
/// and local data sources; repositories catch it, and nothing above a
/// repository ever sees it.
class CacheException implements Exception {
  const CacheException([this.message]);

  final String? message;

  @override
  String toString() => 'CacheException($message)';
}
```

`lib/core/app/failure.dart`:
```dart
class Failure {
  final String message;
  final int? code;

  Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

/// The device is offline or the request timed out.
class NetworkFailure extends Failure {
  NetworkFailure({super.message = 'No internet connection.', super.code});
}

/// Any server error without a more specific mapping.
class ServerFailure extends Failure {
  ServerFailure({
    required this.errorCode,
    super.message = 'Something went wrong.',
    super.code,
  });

  /// The API's error code, e.g. `INVALID_BODY` or `PGRST301`.
  // Named errorCode because Failure already has an int `code` (HTTP status).
  final String errorCode;
}

/// Nothing usable is saved on this device for the data asked for. Never
/// shown to the user: the screen simply loads from the network.
class CacheMissFailure extends Failure {
  CacheMissFailure({super.message = 'Nothing saved on this device.'});
}
```

**Rules.** Two classes named `ServerException` exist; every data source imports `app_exceptions.dart` with `show AppException` (`import '.../app_exceptions.dart' show AppException;`) and `api_exceptions.dart` unqualified, so `ServerException` resolves to the typed one. Tests import `app_exceptions.dart` `as app`. Feature-specific server exceptions **extend** `ServerException` (`OrderInProgressException`, `OrderNotRegisteredException`, `QuoteItemsUnavailableException`) when a repository should still be able to `catch (ServerException)`; third-party-host exceptions that are *not* envelope-shaped (`StockshipException`, `RefOrdersException`, `MedusaException`) are their own `implements Exception` classes with the convention `(int status, [String? detail])` where **status 0 means nothing arrived**. `Failure` is **not** Equatable and has a non-const constructor; `Failure.code` is the HTTP status, so the API's string code is `ServerFailure.errorCode`.

### 3.7 `env.dart` and `.env.example` — complete

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The KO-Tech environment, chosen by `KO_ENV` in `.env`.
enum KoEnv { production, beta }

/// Which Razorpay key the payment sheet uses, chosen by `RAZORPAY_MODE`
/// in `.env`. [test] works in debug builds only.
enum RazorpayMode { live, test }

/// Typed access to values from the `.env` file.
///
/// Call [Env.load] once at startup before reading any value.
abstract final class Env {
  static const String _fileName = '.env';

  static Future<void> load() => dotenv.load(fileName: _fileName);

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get medusaBaseUrl => _require('MEDUSA_URL');
  static String get medusaApiKey => _require('MEDUSA_PUBLISHABLE_KEY');

  /// The website shared product links point to, e.g.
  /// `https://example.com/app`; no trailing slash.
  static String get webOrigin => _require('APP_WEB_ORIGIN');

  /// Which KO-Tech environment the app talks to. One switch for every
  /// KO-Tech value below, so StockShip, Utils and Razorpay can never point
  /// at different environments (a mismatch fails silently: an order lands in
  /// a warehouse nobody watches). Throws unless it is `production` or `beta`.
  static KoEnv get koEnv {
    final value = _require('KO_ENV').trim().toLowerCase();
    return switch (value) {
      'production' => KoEnv.production,
      'beta' => KoEnv.beta,
      _ => throw StateError(
        'KO_ENV must be "production" or "beta" in $_fileName, not "$value".',
      ),
    };
  }

  /// KO Utils: places COD orders (`/order/my-mali`); follows [koEnv].
  static String get utilsUrl => _koValue('UTILS_URL');

  /// StockShip: the warehouse's copy of an order; follows [koEnv].
  static String get stockshipUrl => _koValue('STOCKSHIP_URL');

  /// The Razorpay key the payment sheet opens with: the key of the account
  /// KO registers orders in, following [koEnv]; or `RAZORPAY_TEST_KEY_ID`
  /// while [razorpayMode] is [RazorpayMode.test].
  static String get razorpayKeyId => razorpayMode == RazorpayMode.test
      ? _require('RAZORPAY_TEST_KEY_ID')
      : _koValue('RAZORPAY_KEY_ID');

  /// Which Razorpay key to use, chosen by `RAZORPAY_MODE` (`live` | `test`)
  /// in `.env`; `live` when it is absent. `test` is honoured only in a
  /// debug build: a release always pays live, whatever `.env` says.
  /// Throws for any other value.
  static RazorpayMode get razorpayMode {
    final value = (dotenv.maybeGet('RAZORPAY_MODE') ?? 'live')
        .trim()
        .toLowerCase();
    return switch (value) {
      '' || 'live' => RazorpayMode.live,
      'test' => allowTestPayments ? RazorpayMode.test : RazorpayMode.live,
      _ => throw StateError(
        'RAZORPAY_MODE must be "live" or "test" in $_fileName, not "$value".',
      ),
    };
  }

  /// Whether `RAZORPAY_MODE=test` may take effect: debug builds only.
  @visibleForTesting
  static bool allowTestPayments = kDebugMode;

  /// The warehouse channel this app's orders are booked under.
  static String get mktpId => _require('MKTP_ID');

  /// Katyayani Core: the site's API key (`nc_live_…`) and its host.
  static String get kcSiteId => _require('KC_SITE_ID');
  static String get kcApiUrl => _require('KC_API_URL');

  /// Meta (Facebook) App Events: the app id and client token from the Meta
  /// dashboard (Settings → Basic / Advanced). Both optional: with either
  /// blank the app never starts the Meta SDK. The same two values reach the
  /// native projects (see `android/app/build.gradle.kts` and
  /// `tool/sync_native_env.dart`).
  static String? get fbAppId => _optional('FB_APP_ID');
  static String? get fbClientToken => _optional('FB_CLIENT_TOKEN');

  /// The app's release version. (KO orders carry the API version, `v2`.)
  static String get appVersion => _require('APP_VERSION');

  static String _koValue(String key) => _require(switch (koEnv) {
    KoEnv.production => '${key}_PROD',
    KoEnv.beta => '${key}_BETA',
  });

  static String? _optional(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in $_fileName (see .env.example).');
    }
    return value;
  }
}
```

`.env.example` (verbatim; `.env` has exactly these 22 keys, is git-ignored, and is bundled as a Flutter asset via `assets: - .env` in `pubspec.yaml`):
```
# Copy to .env and fill in. Only client-safe values: this file is bundled
# into the app. URLs have no trailing slash.

# ── KO-Tech environment ──────────────────────────────────────
# production | beta. Picks the *_PROD or *_BETA value of every KO-Tech key
# below together, so StockShip, Utils and Razorpay never point at different
# environments.
KO_ENV=beta

# ── Supabase (Project Settings > API) ────────────────────────
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# ── Medusa (catalog) ─────────────────────────────────────────
MEDUSA_URL=https://medusa.example.com
MEDUSA_PUBLISHABLE_KEY=pk_your-publishable-key

# ── Orders / checkout (KO-Tech, follow KO_ENV) ───────────────
STOCKSHIP_URL_BETA=https://beta.stockship.example.com
STOCKSHIP_URL_PROD=https://stockship.example.com
UTILS_URL_BETA=https://beta.utils.example.com
UTILS_URL_PROD=https://utils.example.com
RAZORPAY_KEY_ID_BETA=rzp_test_your-key-id
RAZORPAY_KEY_ID_PROD=rzp_live_your-key-id

# ── Razorpay key switch (debug builds only) ──────────────────
# Keep exactly one RAZORPAY_MODE line uncommented. `live` uses the
# RAZORPAY_KEY_ID_* above (following KO_ENV); `test` uses
# RAZORPAY_TEST_KEY_ID instead, even over the key KO sends back. A release
# build always pays live. Absent means live.
RAZORPAY_MODE=live
#RAZORPAY_MODE=test
RAZORPAY_TEST_KEY_ID=rzp_test_your-key-id
# The warehouse channel this app's orders are booked under.
MKTP_ID=MKTP-000
# The app's release version.
APP_VERSION=1.0.0

# ── Address / GST ────────────────────────────────────────────
PINCODE_HOST=https://utils.example.com
GST_HOST=https://gst.example.com

# ── Katyayani Core: push + analytics (required) ──────────────
KC_API_URL=https://core.example.com
KC_SITE_ID=your-site-id
# ── Facebook (optional) ──────────────────────────────────────
FB_APP_ID=your-facebook-app-id
FB_CLIENT_TOKEN=your-facebook-client-token

# The website shared product links point to.
APP_WEB_ORIGIN=https://example.com/app
```

**Rules.** `Env` is `abstract final class` with only statics. Required values go through `_require` (throws `StateError('Missing $key in .env (see .env.example).')` on null **or empty**); optional ones through `_optional` (trimmed; empty → null). An environment switch is one enum (`KoEnv`) parsed once from one key (`KO_ENV`, trimmed + lowercased, throws on anything else) and a `_koValue(key)` helper that appends `_PROD` / `_BETA` to the base key, so every vendor value flips together. A debug-only mode (`RazorpayMode`) is a getter that reads `dotenv.maybeGet` with a default, lowercases, and consults a `@visibleForTesting static bool allowTestPayments = kDebugMode` gate so tests can flip it. Tests load with `dotenv.loadFromString(envString: '...')` (no `.env` file needed). `Env` is read only by `bootstrap.dart`, `injection_container.dart`, `endpoints.dart`, and two presentation pages (`webOrigin`); data sources receive keys through constructors. `PINCODE_HOST` and `GST_HOST` exist in `.env`/`.env.example` with no `Env` getter (dead keys).

### 3.8 `string_constants.dart` — the live part

```dart
abstract class StringConstants {
  // … legacy `static String` members (jwtToken, firebaseToken, userName, …) used only by SharePrefRepo …

  /// The signed-in user's access token, saved by `AuthLocalDataSource` and
  /// sent by `NetworkingService` as the default `Authorization` header.
  static const String appAuthToken = 'auth.access_token';

  // … more legacy members; `static var appVersion = "2.0.3";` …
}
```
**Rule.** `NetworkingService._getOptions` and `AuthLocalDataSourceImpl.accessTokenKey` share this one `static const`. The storage behind it is `SecureStorage`, never prefs. Everything else in the file is legacy and unused by the clean architecture.

### 3.9 `ko_token_service.dart` — complete (the "minted bearer for a third-party host" pattern)

```dart
import 'dart:developer';

import '../../app/api/api_response.dart';
import '../../app/exceptions/app_exceptions.dart' show AppException;
import '../../config/env.dart';
import '../../utils/json_readers.dart';
import '../networking/endpoints.dart';
import '../networking/networking.dart';

/// The bearer token KO-Tech's services (StockShip, and later the prepaid
/// order calls) take, minted by the `kotech-token` Edge Function for the
/// signed-in user. The previous app's `ssoToken.ts`.
///
/// One token is kept in memory until five minutes before it expires;
/// callers asking at the same time share one mint. A call answered 401
/// should [invalidate] and ask again with `refresh: true`, once.
abstract interface class KoTokenService {
  /// A token for KO's services, or null when none could be minted. With
  /// [refresh] a new one is asked for even if the kept one is still good.
  Future<String?> token({bool refresh = false});

  /// Forgets the kept token, e.g. after a 401.
  void invalidate();
}

class KoTokenServiceImpl implements KoTokenService {
  KoTokenServiceImpl({
    required Networking networking,
    required String anonKey,
    required KoEnv env,
    DateTime Function() now = DateTime.now,
  }) : _networking = networking,
       _anonKey = anonKey,
       _env = env,
       _now = now;

  final Networking _networking;
  final String _anonKey;
  final KoEnv _env;
  final DateTime Function() _now;

  /// A token this close to expiring is minted again.
  static const Duration expirySkew = Duration(minutes: 5);

  /// How long a token without an `expires_at` is kept.
  static const Duration fallbackLifetime = Duration(minutes: 30);

  ({String token, DateTime expiresAt})? _cached;
  Future<String?>? _inFlight;

  /// The function reads the user from the session token, which stays as
  /// the service's default bearer.
  Map<String, String> get _edgeFunctionHeaders => {'apikey': _anonKey};

  @override
  Future<String?> token({bool refresh = false}) async {
    final cached = _cached;
    if (!refresh &&
        cached != null &&
        _now().isBefore(cached.expiresAt.subtract(expirySkew))) {
      return cached.token;
    }
    final inFlight = _inFlight ??= _mint(refresh)
        .whenComplete(() => _inFlight = null);
    return inFlight;
  }

  @override
  void invalidate() => _cached = null;

  Future<String?> _mint(bool refresh) async {
    final Object? response;
    try {
      response = await _networking.postAPICall(
        endpoint: Endpoints.kotechToken,
        data: {'refresh': refresh, 'env': _env.name},
        headers: _edgeFunctionHeaders,
      );
    } on AppException catch (e) {
      log('[ko-token] mint failed: $e');
      return null;
    }
    if (response is! SuccessResponse) {
      log(
        '[ko-token] mint refused: ${(response as ErrorResponse?)?.errorCode}',
      );
      return null;
    }
    final body = asMap(response.rawData);
    final token = asString(body['access_token']);
    if (token == null || token.isEmpty) {
      log('[ko-token] mint returned no access_token');
      return null;
    }
    final expiresAt = DateTime.tryParse(asString(body['expires_at']) ?? '');
    _cached = (
      token: token,
      expiresAt: expiresAt ?? _now().add(fallbackLifetime),
    );
    return token;
  }
}
```
**Rule.** Lives in `lib/core/services/<vendor>/`, registered `registerLazySingleton<KoTokenService>(() => KoTokenServiceImpl(networking: sl(), anonKey: Env.supabaseAnonKey, env: Env.koEnv))`. Never throws: every failure is `null` plus a `log('[ko-token] …')`. The clock is injected for tests. The mint goes to the **default host** with `apikey` only (so the user's session bearer identifies the user). Consumers do: `token()` → send → on `errorCode == '401'`: `invalidate()`, `token(refresh: true)`, resend once.

### 3.10 `json_readers.dart` and `currency_format.dart` — complete

```dart
/// Lenient readers for API JSON. A missing or mistyped value reads as null
/// or empty, never a crash, so models can treat every field as optional.
library;

double? asDouble(Object? value) => value is num ? value.toDouble() : null;

int? asInt(Object? value) => value is num ? value.toInt() : null;

/// A number that may arrive as a JSON number or a numeric string, as
/// PostgREST sends a Postgres `numeric`. Anything else reads as null.
double? asNumeric(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? asString(Object? value) => value is String ? value : null;

bool? asBool(Object? value) => value is bool ? value : null;

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> asMapList(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ]
    : const [];

List<String> asStringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];
```

```dart
import 'package:intl/intl.dart';

final NumberFormat _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Formats an amount in rupees with Indian grouping and no paise,
/// e.g. `formatRupees(1250) == '₹1,250'`.
String formatRupees(num amount) => _rupees.format(amount);
```
**Rule.** Data sources read response bodies with `asMap(response.rawData)`, `asMapList(body['data'])`, `asString(...)`; models use `asNumeric` for Postgres `numeric` columns. `asMap` returns an **unmodifiable** `const {}` on a miss. `formatRupees` is presentation-only (domain never formats money).

### 3.11 The data-source contract — worked example A: Edge Function with anon bearer (`auth_remote_data_source.dart`, complete)

```dart
import '../../../../core/app/api/api_response.dart';
import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;
import '../../../../core/services/networking/endpoints.dart';
import '../../../../core/services/networking/networking.dart';
import '../../../../core/app/exceptions/api_exceptions.dart';
import '../models/auth_tokens_model.dart';
import '../models/otp_request_model.dart';
import '../models/send_otp_response_model.dart';
import '../models/verify_otp_request_model.dart';

/// Calls the phone-login Edge Function. Returns models or throws
/// [ServerException] / [ConnectionException].
// TODO(login): resend
abstract interface class AuthRemoteDataSource {
  Future<SendOtpResponseModel> sendOtp(OtpRequestModel request);

  Future<AuthTokensModel> verifyOtp(VerifyOtpRequestModel request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({
    required Networking networking,
    required String anonKey,
  }) : _networking = networking,
       _anonKey = anonKey;

  final Networking _networking;
  final String _anonKey;

  /// Edge Functions expect the anon key, not the app's stored token that
  /// the networking service sends by default. JSON content type is already
  /// the service default.
  Map<String, String> get _supabaseHeaders => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  @override
  Future<SendOtpResponseModel> sendOtp(OtpRequestModel request) async {
    final Object? response;
    try {
      // Relative to the networking service's base URL (the Supabase URL).
      response = await _networking.postAPICall(
        endpoint: Endpoints.phoneLogin,
        data: request.toJson(),
        headers: _supabaseHeaders,
      );
    } on AppException catch (e) {
      // The service returns an APIResponse whenever the server answered, and
      // throws an AppException only when no response arrived.
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) {
      final body = response.rawData;
      final model = SendOtpResponseModel.fromJson(
        body is Map<String, dynamic> ? body : const {},
      );
      if (!model.ok) {
        throw ServerException(
          code: 'UNEXPECTED_RESPONSE',
          status: int.tryParse(response.statusCode) ?? 200,
        );
      }
      return model;
    }

    if (response is ErrorResponse) throw _toServerException(response);

    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  @override
  Future<AuthTokensModel> verifyOtp(VerifyOtpRequestModel request) async {
    final Object? response;
    try {
      response = await _networking.postAPICall(
        endpoint: Endpoints.phoneLogin,
        data: request.toJson(),
        headers: _supabaseHeaders,
      );
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) {
      final body = response.rawData;
      final model = AuthTokensModel.fromJson(
        body is Map<String, dynamic> ? body : const {},
      );
      if (model.accessToken.isEmpty || model.refreshToken.isEmpty) {
        throw ServerException(
          code: 'UNEXPECTED_RESPONSE',
          status: int.tryParse(response.statusCode) ?? 200,
        );
      }
      return model;
    }

    if (response is ErrorResponse) throw _toServerException(response);

    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  /// Reads the `{ "code", "status", "title", "detail" }` error envelope.
  ServerException _toServerException(ErrorResponse response) {
    final body = response.rawData;
    final envelope = body is Map<String, dynamic> ? body : const {};
    return ServerException(
      code: envelope['code'] as String? ?? 'UNKNOWN',
      status:
          (envelope['status'] as num?)?.toInt() ??
          int.tryParse(response.errorCode) ??
          0,
      detail: envelope['detail'] as String? ?? envelope['title'] as String?,
    );
  }
}
```

**The four-branch decision every data source method follows (copy exactly):**
1. `final Object? response; try { response = await _networking.xAPICall(...); } on AppException catch (e) { throw ConnectionException(e.toString()); }` — no response arrived.
2. `if (response is SuccessResponse)` → read **`response.rawData`**, check the shape, build the model; a wrong shape throws `ServerException(code: 'UNEXPECTED_RESPONSE', status: int.tryParse(response.statusCode) ?? 200)`.
3. `if (response is ErrorResponse) throw _toServerException(response);` — one private envelope parser per data source.
4. `throw const ServerException(code: 'INVALID_RESPONSE', status: 0);` — anything else (tested by the wishlist test with `networking.response = 'nonsense'`).

The abstract side is `abstract interface class XRemoteDataSource`; the impl is `const` with `{required Networking networking, required String anonKey}` named constructor parameters assigned to `_networking`/`_anonKey`; keys are injected, never read from `Env`.

### 3.12 Worked example B: PostgREST query with `_send` helper (`coupon_remote_data_source.dart`, complete)

```dart
import '../../../../core/app/api/api_response.dart';
import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;
import '../../../../core/services/networking/endpoints.dart';
import '../../../../core/services/networking/networking.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/coupon_model.dart';

/// Reads the `coupons` table through PostgREST, the one source of coupons:
/// it is the table the server bills from. Returns models or throws
/// [ServerException] / [ConnectionException].
abstract interface class CouponRemoteDataSource {
  /// The coupons a customer may see at [now]: active, not hidden, started
  /// and not ended, cheapest minimum first. Signed-in users can read every
  /// row, so these filters are all that keeps test and dead codes off the
  /// screen.
  Future<List<CouponModel>> fetchActive(DateTime now);

  /// The active coupon whose code is exactly [code] (already uppercase),
  /// or null when there is none.
  Future<CouponModel?> fetchByCode(String code);
}

class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  const CouponRemoteDataSourceImpl({
    required Networking networking,
    required String anonKey,
  }) : _networking = networking,
       _anonKey = anonKey;

  final Networking _networking;
  final String _anonKey;

  /// PostgREST needs the anon key. The user's token stays as the service's
  /// default bearer.
  Map<String, String> get _restHeaders => {'apikey': _anonKey};

  static const String _listSelect =
      'code,type,value,min_subtotal,description,starts_at,ends_at,'
      'prepaid_only,flat_total';

  static const String _checkSelect =
      'code,type,value,min_subtotal,active,starts_at,ends_at,prepaid_only,'
      'flat_total';

  @override
  Future<List<CouponModel>> fetchActive(DateTime now) async {
    final at = now.toUtc().toIso8601String();
    final response = await _send(
      () => _networking.getAPICall(
        endpoint: Endpoints.coupons,
        queryParameters: {
          'select': _listSelect,
          'active': 'eq.true',
          'hidden': 'eq.false',
          // Started (or no start) AND not ended (or no end). One `and`
          // parameter, because a query map cannot carry two `or` keys.
          'and':
              '(or(starts_at.is.null,starts_at.lte.$at),'
              'or(ends_at.is.null,ends_at.gte.$at))',
          'order': 'min_subtotal.asc',
        },
        headers: _restHeaders,
      ),
    );
    return _rows(response);
  }

  @override
  Future<CouponModel?> fetchByCode(String code) async {
    final response = await _send(
      () => _networking.getAPICall(
        endpoint: Endpoints.coupons,
        // An exact match on the uppercase code, as the server bills it. A
        // case-insensitive pattern match would accept codes the bill then
        // drops, and would read `%` and `_` as wildcards.
        queryParameters: {
          'select': _checkSelect,
          'code': 'eq.$code',
          'active': 'eq.true',
          'limit': '1',
        },
        headers: _restHeaders,
      ),
    );
    final rows = _rows(response);
    return rows.isEmpty ? null : rows.first;
  }

  List<CouponModel> _rows(SuccessResponse response) {
    final body = response.rawData;
    if (body is! List) {
      throw ServerException(
        code: 'UNEXPECTED_RESPONSE',
        status: int.tryParse(response.statusCode) ?? 200,
      );
    }
    return [for (final row in asMapList(body)) CouponModel.fromJson(row)];
  }

  /// Runs [call] and returns its successful response. The service returns
  /// an APIResponse whenever the server answered, and throws an
  /// AppException only when no response arrived.
  Future<SuccessResponse> _send(Future<dynamic> Function() call) async {
    final Object? response;
    try {
      response = await call();
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) return response;
    if (response is ErrorResponse) throw _toServerException(response);
    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  /// Reads PostgREST's error body `{ "code", "details", "hint", "message" }`.
  ServerException _toServerException(ErrorResponse response) {
    final error = asMap(response.rawData);
    return ServerException(
      code: asString(error['code']) ?? 'UNKNOWN',
      status: int.tryParse(response.errorCode) ?? 0,
      detail: asString(error['message']),
    );
  }
}
```
**Rule.** PostgREST calls: `Endpoints.<table>` = `/rest/v1/<table>`, headers `{'apikey': anon}` **only** (the service's default `Authorization: Bearer <user token>` stays, which RLS reads), filters as query parameters with **string** values (`'eq.true'`, `'limit': '1'`, `'order': 'x.asc'`, `'in.(a,b)'`, `'not.in.(…)'`, `'and': '(or(…),or(…))'`), `select` column lists as `static const String`. A list body that is not a `List` is `UNEXPECTED_RESPONSE`. The `_send(Future<dynamic> Function() call)` helper centralises the four branches when a data source has several methods (also in catalog, cart, address `_post`, wishlist, referral, mali_coins).

PostgREST **writes** (from cart/gstin/notifications):
```dart
  /// An upsert replaces existing rows and answers with no body.
  static const String _mergeHeader =
      'resolution=merge-duplicates,return=minimal';

  /// Without `return=representation` PostgREST answers 204, which the
  /// networking service reports as an error.
  static const String _returnHeader = 'return=representation';
  // …
      await _send(
        () => _networking.postAPICall(
          endpoint: Endpoints.cartItems,
          queryParameters: const {'on_conflict': 'user_id,product_id'},
          data: [
            for (final line in lines) {'user_id': userId, ...line.toJson()},
          ],
          headers: {..._restHeaders, 'Prefer': _mergeHeader},
        ),
      );
  // …
    await _send(
      () => _networking.deleteAPICall(
        endpoint: Endpoints.cartItems,
        queryParameters: {
          'user_id': 'eq.$userId',
          if (lines.isNotEmpty) 'product_id': 'not.in.($keep)',
        },
        headers: {..._restHeaders, 'Prefer': _returnHeader},
      ),
    );
```
```dart
      response = await _networking.patchAPICall(
        endpoint: Endpoints.appNotifications,
        queryParameters: {'id': 'in.(${ids.join(',')})', 'select': 'id'},
        data: const {'read': true},
        // A 204 would come back as an ErrorResponse, so ask for the rows.
        headers: {..._restHeaders, 'Prefer': 'return=representation'},
      );
```
**Rule.** POST upserts use `on_conflict=<cols>` + `Prefer: resolution=merge-duplicates,return=minimal` (PostgREST still answers 201). PATCH and DELETE must add `Prefer: return=representation` because 204 is an `ErrorResponse`.

### 3.13 Worked example C: another host with a minted token and a 401 retry (`stockship_remote_data_source.dart`, complete) and its exceptions

```dart
import '../../../../core/app/api/api_response.dart';
import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;
import '../../../../core/services/kotech/ko_token_service.dart';
import '../../../../core/services/networking/endpoints.dart';
import '../../../../core/services/networking/networking.dart';
import '../../../../core/utils/json_readers.dart';
import '../exceptions/orders_exceptions.dart';
import '../models/stockship_order_model.dart';

/// StockShip's `GET /api/orders`, exactly as the previous app calls it
/// (`stockship.api.ts`): the KO token as the bearer, the app's `mktp_id`
/// on every call, a 404 as "none", and one more try with a fresh token
/// after a 401. Throws [StockshipException] or [KoTokenException].
abstract interface class StockshipRemoteDataSource {
  /// `?phone=&mktp_id=&page=&limit=`: the customer's orders, newest first
  /// as StockShip sends them (the repository sorts).
  Future<List<StockshipOrderModel>> listOrders({
    required String phone,
    int page = 1,
    int limit = pageSize,
  });

  /// The same request as [listOrders], with the page details My Orders
  /// pages by: an empty page on a 404.
  Future<StockshipOrderPageModel> listOrderPage({
    required String phone,
    int page = 1,
    int limit = pageSize,
  });

  /// `?order_id=&mktp_id=`: the one order, or null when StockShip answers
  /// 404 or an empty list.
  Future<StockshipOrderModel?> getOrder({required String orderId});

  /// The previous app's page size.
  static const int pageSize = 20;
}

class StockshipRemoteDataSourceImpl implements StockshipRemoteDataSource {
  const StockshipRemoteDataSourceImpl({
    required Networking networking,
    required KoTokenService tokens,
    required String mktpId,
  }) : _networking = networking,
       _tokens = tokens,
       _mktpId = mktpId;

  final Networking _networking;
  final KoTokenService _tokens;
  final String _mktpId;

  @override
  Future<List<StockshipOrderModel>> listOrders({
    required String phone,
    int page = 1,
    int limit = StockshipRemoteDataSource.pageSize,
  }) async {
    final result = await listOrderPage(phone: phone, page: page, limit: limit);
    return result.orders;
  }

  @override
  Future<StockshipOrderPageModel> listOrderPage({
    required String phone,
    int page = 1,
    int limit = StockshipRemoteDataSource.pageSize,
  }) async {
    final body = await _get({
      'phone': phone,
      'mktp_id': _mktpId,
      'page': '$page',
      'limit': '$limit',
    });
    if (body == null) {
      return StockshipOrderPageModel(orders: const [], page: page);
    }
    return StockshipOrderPageModel.fromJson(body, requestedPage: page);
  }

  @override
  Future<StockshipOrderModel?> getOrder({required String orderId}) async {
    final body = await _get({'order_id': orderId, 'mktp_id': _mktpId});
    if (body == null) return null;
    final orders = asMapList(asMap(body['data'])['orders']);
    return orders.isEmpty ? null : StockshipOrderModel.fromJson(orders.first);
  }

  /// The body of `GET /api/orders?[query]`, or null on a 404.
  Future<Map<String, dynamic>?> _get(Map<String, String> query) async {
    var token = await _tokens.token();
    if (token == null) throw const KoTokenException();

    var response = await _send(query, token);
    if (response is ErrorResponse && response.errorCode == '401') {
      _tokens.invalidate();
      token = await _tokens.token(refresh: true);
      if (token != null) response = await _send(query, token);
    }

    if (response is SuccessResponse) return asMap(response.rawData);
    if (response is ErrorResponse) {
      if (response.errorCode == '404') return null;
      throw StockshipException(
        int.tryParse(response.errorCode) ?? 0,
        asString(asMap(response.rawData)['message']),
      );
    }
    throw const StockshipException(0, 'Invalid response');
  }

  Future<Object?> _send(Map<String, String> query, String token) async {
    try {
      return await _networking.getAPICall(
        endpoint: StockshipEndpoints.orders,
        queryParameters: query,
        headers: {'Authorization': 'Bearer $token'},
        host: ApiHost.stockship,
      );
    } on AppException catch (e) {
      throw StockshipException(0, e.toString());
    }
  }
}
```

```dart
/// StockShip answered with an error [status] (0 when nothing arrived).
class StockshipException implements Exception {
  const StockshipException(this.status, [this.detail]);

  final int status;
  final String? detail;

  @override
  String toString() => 'StockshipException($status: $detail)';
}

/// KO's ref-orders answered with an error [status] (0 when nothing
/// arrived).
class RefOrdersException implements Exception {
  const RefOrdersException(this.status, [this.detail]);

  final int status;
  final String? detail;

  @override
  String toString() => 'RefOrdersException($status: $detail)';
}

/// No KO token could be minted, so StockShip could not be asked.
class KoTokenException implements Exception {
  const KoTokenException();

  @override
  String toString() => 'KoTokenException(no token)';
}
```

**Rule.** For a host whose auth is a minted token: `_send(query, token)` does the one HTTP call with `headers: {'Authorization': 'Bearer $token'}` and `host: ApiHost.<host>`, turning `AppException` into the host's exception with status 0; `_get(query)` orchestrates token → send → (`401` → `invalidate()` → `token(refresh: true)` → send once more) → `SuccessResponse` → `asMap(rawData)`; `404` → `null`; other `ErrorResponse` → `<Host>Exception(int.tryParse(errorCode) ?? 0, asString(asMap(rawData)['message']))`; anything else → `<Host>Exception(0, 'Invalid response')`. When the token is **required** (StockShip) a null token throws `KoTokenException` before any call; when it is **optional** (KO Utils ref-orders / prepaid routes) the call goes out without `Authorization` and the 401 retry runs only `if (token != null && …)`:

```dart
  Future<Map<String, dynamic>> _get(Map<String, String> query) async {
    var token = await _tokens.token();
    var response = await _send(query, token);
    if (token != null &&
        response is ErrorResponse &&
        response.errorCode == '401') {
      _tokens.invalidate();
      token = await _tokens.token(refresh: true);
      if (token != null) response = await _send(query, token);
    }

    if (response is SuccessResponse) return asMap(response.rawData);
    if (response is ErrorResponse) {
      throw RefOrdersException(
        int.tryParse(response.errorCode) ?? 0,
        asString(asMap(response.rawData)['message']),
      );
    }
    throw const RefOrdersException(0, 'Invalid response');
  }

  Future<Object?> _send(Map<String, String> query, String? token) async {
    try {
      return await _networking.getAPICall(
        endpoint: KoUtilsEndpoints.refOrders,
        queryParameters: query,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        host: ApiHost.koUtils,
      );
    } on AppException catch (e) {
      throw RefOrdersException(0, e.toString());
    }
  }
```

KO Utils **POST** with an idempotency header and a vendor-specific envelope (`ko_order_remote_data_source.dart`):
```dart
  /// The header KO recognises a repeated attempt by.
  static const String requestIdHeader = 'x-request-id';
  // …
      response = await _networking.postAPICall(
        endpoint: KoUtilsEndpoints.codOrder,
        data: order.toJson(),
        headers: {requestIdHeader: requestId},
        host: ApiHost.koUtils,
      );
  // …
  /// Posts with the KO bearer when one can be minted, and once more with
  /// a fresh one after a 401, as `StockshipRemoteDataSource` does.
  Future<Object?> _postWithToken({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, String> headers = const {},
  }) async {
    var token = await _tokens?.token();
    var response = await _post(endpoint, data, headers, token);
    if (token != null &&
        response is ErrorResponse &&
        response.errorCode == '401') {
      _tokens?.invalidate();
      token = await _tokens?.token(refresh: true);
      if (token != null) response = await _post(endpoint, data, headers, token);
    }
    return response;
  }

  Future<Object?> _post(
    String endpoint,
    Map<String, dynamic> data,
    Map<String, String> headers,
    String? token,
  ) async {
    try {
      return await _networking.postAPICall(
        endpoint: endpoint,
        data: data,
        headers: {
          ...headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        host: ApiHost.koUtils,
      );
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }
  }
  // …
  /// KO answers errors as `{ "message" | "error" | "msg", "code"? }`, at the
  /// top level or under `data`. The code is `HTTP_<status>` when KO sent
  /// none.
  ServerException _toServerException(ErrorResponse response) {
    final body = asMap(response.rawData);
    final status = int.tryParse(response.errorCode) ?? 0;
    final detail = _detailOf(body);
    if (status == 409) return OrderInProgressException(detail: detail);
    return ServerException(
      code: _codeOf(body) ?? 'HTTP_$status',
      status: status,
      detail: detail,
    );
  }

  static String? _detailOf(Map<String, dynamic> body) =>
      _read(body, const ['message', 'error', 'msg']);

  static String? _codeOf(Map<String, dynamic> body) =>
      _read(body, const ['code', 'error_code', 'errorCode']);

  static String? _read(Map<String, dynamic> body, List<String> keys) {
    final data = asMap(body['data']);
    for (final source in [body, data]) {
      for (final key in keys) {
        if (asString(source[key]) case final String value
            when value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }
```
Also from the same file, a 2xx body that says it failed is `ServerException(code: 'NOT_CONFIRMED', status: status, detail: _detailOf(body))` when `body['success'] == false || body['status'] == false`.

Medusa host (`medusa_customer_data_source.dart`):
```dart
  Map<String, String> _headers({String? token}) => {
    'x-publishable-api-key': _publishableKey,
    if (token != null) 'Authorization': 'Bearer $token',
  };
  // …
  Map<String, dynamic> _bodyOf(Object? response) {
    if (response is SuccessResponse) return asMap(response.rawData);
    if (response is ErrorResponse) {
      throw MedusaException(
        int.tryParse(response.errorCode) ?? 0,
        asString(asMap(response.rawData)['message']),
      );
    }
    throw const MedusaException(0, 'Invalid response');
  }
```

### 3.14 Header getters: one per host a data source talks to (`catalog_remote_data_source.dart`)

```dart
  /// The catalog-cache function has its JWT check off and takes the anon
  /// key as its bearer, not the app's stored user token.
  Map<String, String> get _edgeFunctionHeaders => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  /// PostgREST needs the anon key; the user's token stays as the
  /// service's default bearer.
  Map<String, String> get _restHeaders => {'apikey': _anonKey};

  /// Medusa requires the publishable API key.
  Map<String, String> get _medusaHeaders => {
    'x-publishable-api-key': _medusaPublishableKey,
  };
```
and the combined envelope parser that handles both Supabase shapes plus the gateway's own `{code: 401, message}`:
```dart
  /// Reads the Edge Function envelope `{ "code", "status", "title",
  /// "detail" }` or the PostgREST one `{ "code", "message", "details",
  /// "hint" }`.
  ServerException _toServerException(ErrorResponse response) {
    final envelope = asMap(response.rawData);
    return ServerException(
      code: asString(envelope['code']) ?? 'UNKNOWN',
      status:
          asInt(envelope['status']) ?? int.tryParse(response.errorCode) ?? 0,
      detail:
          asString(envelope['detail']) ??
          asString(envelope['message']) ??
          asString(envelope['title']),
    );
  }
```
User-scoped Edge Functions (address, wishlist, mali_coins, checkout, referral, seller, support, kotech-token) use **`Map<String, String> get _edgeFunctionHeaders => {'apikey': _anonKey};`** (no `Authorization` override) so the user's token remains the bearer. The anon-bearer form (`'Authorization': 'Bearer $_anonKey'`) is used only for functions that must work signed-out: `phone-login` (`_supabaseHeaders`), `catalog-cache` (`_edgeFunctionHeaders` in catalog), and the public reviews list (`_publicHeaders` in product, which pairs with `_userHeaders => {'apikey': _anonKey}` for writes).

**Headers actually sent, per host (service defaults + per-call):**

| host | service default | typical per-call additions |
|---|---|---|
| `ApiHost.supabase` | `Content-Type: application/json` (multipart for `FormData`), `Access-Control-Allow-Origin: *`, `Authorization: Bearer <SecureStorage 'auth.access_token' or "">`, `referrer: ""` (sent on **every** method, GET included) | Edge Functions: `apikey: <anon>` (+ `Authorization: Bearer <anon>` only when the function must work signed-out); PostgREST: `apikey: <anon>`, writes add `Prefer: …` |
| `ApiHost.medusa` | `Content-Type: application/json` only when the method has a body | `x-publishable-api-key: <pk>`; customer calls add `Authorization: Bearer <medusa jwt>` |
| `ApiHost.koUtils` | same as medusa | `x-request-id: <attempt id>` on order routes; `Authorization: Bearer <ko token>` on prepaid routes **when mintable**; `/order/my-mali` gets no token |
| `ApiHost.stockship` | same as medusa (GET → no headers at all by default) | `Authorization: Bearer <ko token>` (required) |

### 3.15 Repository side: exception → failure (`auth_repository_impl.dart`)

```dart
  @override
  Future<Either<Failure, Unit>> sendOtp(OtpRequest request) async {
    try {
      await _remote.sendOtp(OtpRequestModel.fromEntity(request));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(_mapSendError(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }
  // …
  Failure _mapSendError(ServerException e) {
    switch (e.code) {
      case 'INVALID_PHONE':
        return InvalidPhoneFailure(code: e.status);
      case 'OTP_SEND_FAILED':
      case 'NOT_CONFIGURED':
        return OtpSendFailure(code: e.status);
      default:
        return ServerFailure(errorCode: e.code, code: e.status);
    }
  }
```
**Rule.** `on ServerException` → switch on `e.code` to a feature failure carrying `code: e.status`; default `ServerFailure(errorCode: e.code, code: e.status)`; `on ConnectionException` → `NetworkFailure()`. Nothing above the repository sees `APIResponse`, `AppException`, `ServerException` or JSON.

### 3.16 Composition (`injection_container.dart`, `bootstrap.dart`)

```dart
void _registerCore() {
  sl
    ..registerLazySingleton<SecureStorage>(DeviceSecureStorage.new)
    ..registerLazySingleton<Networking>(
      () => NetworkingService(secureStorage: sl()),
    )
    ..registerLazySingleton<PrefUtils>(PrefUtils.new)
    ..registerLazySingleton<LocalCache>(HiveLocalCache.new)
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
    ..registerLazySingleton<KoTokenService>(
      () => KoTokenServiceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
        env: Env.koEnv,
      ),
    )
    // …
}

void _registerAuthData() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    // …
}

void _registerOrdersData() {
  sl
    ..registerLazySingleton<StockshipRemoteDataSource>(
      () => StockshipRemoteDataSourceImpl(
        networking: sl(),
        tokens: sl(),
        mktpId: Env.mktpId,
      ),
    )
    ..registerLazySingleton<RefOrderRemoteDataSource>(
      () => RefOrderRemoteDataSourceImpl(networking: sl(), tokens: sl()),
    )
    // …
}
```
```dart
  await Env.load();
  await _initFirebase();
  await DeviceSecureStorage.init();
  await Supabase.initialize(/* … */);
  await HiveLocalCache.init();

  configureDependencies();
```
**Rule.** `Networking` is registered **by its abstract type** as a lazy singleton; `Env.*` is read only in the registration lambdas and handed to data sources as plain strings/enums. `Env.load()` is the first async step; `Endpoints`'s lazy statics and `BaseApiRepo`'s Dio fields read `Env` only when `sl<Networking>()` is first resolved.

### 3.17 Test doubles (`test/helpers/fake_networking.dart`, complete; `fake_secure_storage.dart`)

```dart
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
```
```dart
class FakeSecureStorage implements SecureStorage {
  FakeSecureStorage([Map<String, String>? values]) : values = {...?values};
  final Map<String, String> values;
  @override Future<String?> read(String key) async => values[key];
  @override Future<void> write(String key, String value) async => values[key] = value;
  @override Future<void> delete(String key) async => values.remove(key);
}
```
And the inline token fake used by both KO data-source tests:
```dart
class _FakeTokens implements KoTokenService {
  final List<String?> answers = ['ko_1'];
  final List<bool> asked = [];
  int invalidated = 0;

  @override
  Future<String?> token({bool refresh = false}) async {
    asked.add(refresh);
    return answers.length > 1 ? answers.removeAt(0) : answers.first;
  }

  @override
  void invalidate() => invalidated++;
}
```
**Rule.** Data-source tests set `networking.response = okResponse(body)` / `errorResponse(body, '401')` / `networking.error = app.AppException('offline', 'Timeout')`, queue multi-step answers in `queued`, and assert on `lastCall.method/endpoint/host/queryParameters/headers/data`. `putAPICall` and `graphqlQueryCall` are not implemented by the fake (`noSuchMethod`). No test pumps a real `NetworkingService`.

---

## 4. Rules observed in code (vs AGENTS.md)

1. **`lib/core/app/api/endpoint.dart` does not exist.** AGENTS.md §16 lists it as legacy "duplicate networking code with broken imports". `lib/core/app/api/` contains only `api_response.dart`.
2. **`BaseApiRepo` is load-bearing, not legacy.** AGENTS.md §16 lists `lib/core/repositories/base_api_repository.dart` under "Legacy code — do not copy", yet `NetworkingService extends BaseApiRepo` and §18 says "`BaseApiRepo` creates one `Dio` per host … add a new `Dio` in `BaseApiRepo`". Another app must reproduce it (including the `dioSupabse` spelling if the service is copied verbatim). `shared_pref_repository.dart` (`SharePrefRepo extends BaseApiRepo`) is the genuinely dead one.
3. **`api_response.dart` is both "legacy with analyzer warnings" (§16) and the core response type.** The warning is `log("${map ?? {}}")` in `SuccessResponse.fromMap` (dead null-aware on a non-nullable). Keep the file; the warning is accepted.
4. **`putAPICall` has no `headers` parameter**, while GET/POST/PATCH/DELETE do. AGENTS.md §6 anticipates this ("If `NetworkingService` lacks something (e.g. per-call headers on `get`/`put`), extend it in place") — `get` already has it; `put` still does not. No caller uses `putAPICall`.
5. **The Supabase default headers are more than §6 states.** §6: "the service sends `Content-Type: application/json` and `Authorization: Bearer <appAuthToken>` by default." Code also sends `Access-Control-Allow-Origin: *` and `referrer: ""`, and sends `Content-Type` on GET too (the `hasBody` flag is honoured only for third-party hosts). An injected `options` (the public `Options? options` constructor parameter) **replaces** all Supabase defaults including the bearer.
6. **Two header variants for Edge Functions.** §6's "required pattern" shows `_supabaseHeaders` with `'Authorization': 'Bearer $_anonKey'`. In code only signed-out-capable functions (`phone-login`, `catalog-cache`, public `reviews` list) override the bearer with the anon key; every user-scoped function sends `{'apikey': anon}` alone so the stored user token stays as bearer (§18's `_edgeFunctionHeaders` example shows the anon-bearer form; most files named `_edgeFunctionHeaders` use the apikey-only form).
7. **The no-response subclass mapping is narrower than "offline, timeout".** `DioExceptionType.connectionError`, `badCertificate` and `cancel` fall through to `FetchDataException`, not `InternetException`; only `unknown` + `SocketException` is `InternetException`. Data sources never distinguish subclasses (they catch `AppException`), so this only affects log text.
8. **Request logging runs in every build.** §6 says debug builds add `CurlLoggerInterceptor` (true) and "Don't add another request logger" — but `_logRequest` (`dart:developer` `log`, with full bodies) and the `SERVICE … EXECUTED SUCCESS` / `SERVICE GET ERROR … ${e.response?.data}` lines are not behind `kDebugMode`.
9. **`graphqlQueryCall` creates its own `Dio`** with a 3 s `sendTimeout`, posts to an absolute URL and always uses Supabase headers. It violates §6 "Never create a `Dio`" and is unused; `FakeNetworking` does not implement it.
10. **The core typed exceptions live in `lib/core/app/exceptions/api_exceptions.dart`**, not under a feature's `data/exceptions/` as §5 ("throw a typed exception from `data/exceptions/`") reads. Feature `data/exceptions/` hold vendor-specific ones and `ServerException` subclasses.
11. **Two classes are named `ServerException`** (`app_exceptions.dart`, legacy; `api_exceptions.dart`, live). Every data source imports `app_exceptions.dart` with `show AppException`. AGENTS.md never mentions the clash.
12. **`Networking` is `abstract class`**, not `abstract interface class` (the data-source convention of §5). `KoTokenService` and all data sources use `abstract interface class`.
13. **`Endpoints` holds mutable `static String` base URLs**, not `static const` (§18: "All paths are `static const String`" — true for paths only). Base URLs read `Env` lazily; nothing in tests reassigns them.
14. **Dead `.env` keys.** `PINCODE_HOST` and `GST_HOST` are in `.env` and `.env.example` with no `Env` getter (§8 says every value comes through a typed getter). `StringConstants.appVersion = "2.0.3"` is a hardcoded legacy version next to `Env.appVersion`.
15. **No tests for `NetworkingService`, `APIResponse`, `AppException`** (§14 "every change adds tests"). The curl interceptor, `Env`, `formatRupees`, `KoTokenService` and the data sources are tested.
16. **`HttpMethod` enum is unused** and its values are SCREAMING_CASE (lint `constant_identifier_names` is not enabled; `analysis_options.yaml` is the stock `flutter_lints` include with no custom rules).
17. **Success status set is exactly {200, 201, 202}** via `dart:io` `HttpStatus`; §6 states this (204 → `ErrorResponse`) and data sources work around it with `Prefer: return=representation` on PATCH/DELETE.
18. **`dart:io` is imported** by `networking.dart` (`HttpStatus`, `SocketException`), so the service is not web-safe; the app is phone-only so this is accepted.
19. **The 401 retry is per data source, not in the service.** §18 describes it on `StockshipRemoteDataSource`; the same code is duplicated in `RefOrderRemoteDataSourceImpl._get` and `KoOrderRemoteDataSourceImpl._postWithToken` (with the `token != null &&` guard in the optional-token variants).
20. **`KoTokenService.invalidate()` clears only the cached token**, not an in-flight mint; `token(refresh: true)` while a mint is in flight returns that mint's result (the `??=`).
21. **Query parameter values are passed as `String`s** everywhere (`'limit': '1'`, `'page': '$page'`), and tests assert on the string form.

---

## 5. Packages

| package | version (pubspec) | files that import it | class |
|---|---|---|---|
| `dio` | `^5.11.1` | `lib/core/services/networking/networking.dart`, `lib/core/services/networking/curl_logger_interceptor.dart`, `lib/core/repositories/base_api_repository.dart`, `test/core/services/networking/curl_logger_interceptor_test.dart` | ALWAYS |
| `equatable` | `^2.0.7` | `lib/core/app/api/api_response.dart` | ALWAYS |
| `flutter` (`package:flutter/foundation.dart`: `kDebugMode`, `debugPrint`, `@visibleForTesting`) | sdk | `networking.dart`, `curl_logger_interceptor.dart`, `env.dart`, `device_secure_storage.dart` | ALWAYS |
| `flutter_dotenv` | `^6.0.1` | `lib/core/config/env.dart`, `test/core/config/env_test.dart`, `test/features/referral/presentation/refer/pages/referral_page_test.dart` | ALWAYS |
| `intl` | `^0.20.2` | `lib/core/utils/currency_format.dart` | CONDITIONAL (app shows money) |
| `flutter_secure_storage` | `^11.2.0` | `lib/core/services/secure_storage/device_secure_storage.dart` only (dependency of `NetworkingService`'s default `SecureStorage`) | CONDITIONAL (app stores tokens; a tokenless app can pass a no-op `SecureStorage`) |
| `shared_preferences` | `^2.0.5` | `lib/core/services/pref_utils.dart` (used by `DeviceSecureStorage.init`) | CONDITIONAL (same as above) |
| `get_it` | `^8.0.3` | `lib/core/di/injection_container.dart` | ALWAYS |
| `fpdart` | `^1.1.1` | repositories (`auth_repository_impl.dart`) — the `Either<Failure, T>` the data layer feeds | ALWAYS |
| `supabase_flutter` | `^2.17.2` | `bootstrap.dart`, `injection_container.dart` (not by the networking files themselves) | CONDITIONAL (app's default host is Supabase) |
| `flutter_test` | sdk | all tests | ALWAYS |
| `dart:io`, `dart:convert`, `dart:developer` | sdk | `networking.dart` (all three), `curl_logger_interceptor.dart` (`dart:convert`), `api_response.dart` (`dart:convert`, `dart:developer`), `ko_token_service.dart` (`dart:developer`) | ALWAYS (`dart:io` makes the service non-web) |

Not used by this area but present in the stack for context: `connectivity_plus`, `internet_connection_checker` (legacy `ConnectivityBloc`), `crypto` (Medusa password).

---

## 6. What varies per app

| what | where it appears | MyMali value → placeholder |
|---|---|---|
| Dart package name | every `package:mymali/...` import in `networking.dart`, `base_api_repository.dart`, `endpoints.dart`, tests | `mymali` → `<package>` |
| `ApiHost` values beyond the default | `enum ApiHost`, `_dioFor`, `_thirdPartyHosts`, `NetworkingService` constructor loop, `BaseApiRepo` fields, `Endpoints.*BaseUrl`, `Env` getters, `.env` keys, `FakeNetworking` default | `supabase` (default), `medusa`, `koUtils`, `stockship` → `<default host>` + `<extra hosts>` |
| Dio field names | `BaseApiRepo`, `_dioFor`, constructor loop | `dioSupabse`, `dioMedusa`, `dioKoUtils`, `dioStockship` → `dio<Host>` |
| Base-URL statics | `Endpoints.baseUrlMain / medusaBaseUrl / koUtilsBaseUrl / stockshipBaseUrl` ← `Env.supabaseUrl / medusaBaseUrl / utilsUrl / stockshipUrl` | one per host |
| Endpoint classes and every path | `Endpoints` (22 paths), `MedusaEndpoints` (8), `KoUtilsEndpoints` (4), `StockshipEndpoints` (1) | `<Host>Endpoints` + the app's paths; Supabase conventions `/functions/v1/<fn>`, `/rest/v1/<table>` |
| Default-host default headers | `_getOptions` | `Content-Type`, `Access-Control-Allow-Origin: *`, `Authorization: Bearer <token>`, `referrer: ""` → keep or trim the two odd ones |
| Access-token storage key | `StringConstants.appAuthToken`, `AuthLocalDataSourceImpl.accessTokenKey` | `'auth.access_token'` |
| Token store | `SecureStorage` / `DeviceSecureStorage` default in `NetworkingService` | an app without tokens injects a stub `SecureStorage` |
| Per-call auth header names | data-source header getters | `apikey` (Supabase), `x-publishable-api-key` (Medusa), `x-request-id` (KO idempotency), `Authorization: Bearer` (all) |
| Header getter names | data sources | `_edgeFunctionHeaders`, `_restHeaders`, `_medusaHeaders`, `_supabaseHeaders` (auth), `_publicHeaders`/`_userHeaders` (product), `_headers({token})` (Medusa customer) |
| Error envelopes | `_toServerException` variants | Edge `{code,status,title,detail}`; PostgREST `{code,message,details,hint}`; KO `{message|error|msg, code?}` (+ under `data`); StockShip/Medusa/ref-orders `{message}` |
| Env getters and `.env` keys | `env.dart`, `.env.example` | 22 keys (§3.7); `SUPABASE_URL`/`SUPABASE_ANON_KEY` are the only ones the default host needs |
| Environment switch | `KoEnv`, `KO_ENV`, `_koValue` suffixes `_PROD`/`_BETA`, `utilsUrl`, `stockshipUrl`, `razorpayKeyId` | `<Vendor>Env`, `<VENDOR>_ENV`, `<KEY>_PROD` / `<KEY>_BETA` |
| Debug-only mode switch | `RazorpayMode`, `RAZORPAY_MODE`, `RAZORPAY_TEST_KEY_ID`, `allowTestPayments` | drop or rename for the app's payment vendor |
| Minted-token service | `lib/core/services/kotech/ko_token_service.dart`: `KoTokenService(Impl)`, `Endpoints.kotechToken`, body `{refresh, env}`, response `access_token`/`expires_at`, `expirySkew`, `fallbackLifetime`, log prefix `[ko-token]` | `<Vendor>TokenService` in `lib/core/services/<vendor>/` |
| Vendor exception names | `StockshipException`, `RefOrdersException`, `KoTokenException`, `MedusaException`, `OrderInProgressException`, `OrderNotRegisteredException` | `<Host>Exception(status, [detail])` |
| Money formatting | `formatRupees`, `en_IN`, `₹`, `decimalDigits: 0` | `format<Currency>` |
| Log prefixes | `[api]` (curl), `[ko-token]`, `SERVICE <METHOD> API …` | keep `[api]`; rename vendor ones |
| Vendor-specific query/body keys | `mktp_id`, `user_phone`, `ref_id`, `order_id`, `phone`, `page`, `limit`, `on_conflict`, `select`, `Prefer` values | PostgREST ones are generic; `mktp_id` etc. are MyMali |
| Feature-level `static const` on data sources | `StockshipRemoteDataSource.pageSize = 20`, `KoOrderRemoteDataSourceImpl.requestIdHeader`, `paymentStatusSource`, `couponNotApplicableCode`, `unbuyableItemCode`, `NotificationsRemoteDataSource.defaultLimit = 100` | per feature |

---

## 7. Gotchas

1. **Read `rawData`, not `data`.** `returnResponse` unwraps a `data` key when the body is a map that has one, so `SuccessResponse.data` is sometimes the inner object and sometimes the whole body. Every data source reads `response.rawData`. `okResponse()` in tests sets both to the same body, so a data source that wrongly read `.data` would still pass its tests.
2. **Status codes are strings.** `SuccessResponse.statusCode` / `ErrorResponse.errorCode` are `'200'` / `'401'`. Compare with `== '401'`, parse with `int.tryParse(...) ?? 0` (errors) or `?? 200` (unexpected success bodies).
3. **204 is an error.** Only 200/201/202 are success. PostgREST PATCH/DELETE need `Prefer: return=representation`; POST upserts can use `return=minimal` (201).
4. **Import `app_exceptions.dart` with `show AppException`.** Otherwise `ServerException` is ambiguous between the legacy `AppException` subclass and the typed `api_exceptions.dart` one. Tests import it `as app`.
5. **`AppException` means "no response arrived"; `ErrorResponse` means "the server replied".** Dio raises 4xx/5xx as `DioException` *with* `response`; the service converts those back into `ErrorResponse`. A data source therefore sees HTTP errors as returned values, never as exceptions.
6. **Header override is a case-sensitive map spread.** To replace the default bearer a data source must spell the key exactly `Authorization` (and `Content-Type` to replace the content type). `{...?defaultOptions.headers, ...headers}`: per-call wins.
7. **Third-party GETs carry no headers by default** (`hasBody: false` → empty `Options.headers`); the ref-orders test asserts `lastCall.headers, isEmpty` when no token is mintable — the service then sends a header-less GET.
8. **The default host sends the user's token even to Edge Functions that want the anon key.** Functions with their JWT check off (`phone-login`, `catalog-cache`) override `Authorization` with `Bearer <anon>`; user-scoped ones must **not** override it. Getting this backwards yields 401s from the gateway (whose envelope is `{code: 401, message}` — numeric `code`, hence `asString(envelope['code']) ?? 'UNKNOWN'` and the `?? asString(envelope['message'])` fallbacks).
9. **`NetworkingService` builds all four `Dio`s in field initializers**, reading every base URL from `Env` when `sl<Networking>()` is first resolved. A missing `UTILS_URL_BETA` (or any host's key) throws `StateError` on the first network call of any feature, not only KO features. Another app must provide a key for every `ApiHost` it declares.
10. **`Env.load()` must precede the first touch of `Endpoints` or `Env`.** `Endpoints.baseUrlMain` etc. are lazily-initialised mutable statics; once read they never re-read `.env`.
11. **`_require` treats empty as missing**; `_optional` trims and treats empty as null. `koEnv` and `razorpayMode` lowercase + trim and **throw** on unknown values (tests: `'staging'`, `'sandbox'`).
12. **`allowTestPayments` is a mutable static with `@visibleForTesting`**; tests reset it in `tearDown(() => Env.allowTestPayments = true)`.
13. **No timeouts anywhere** (`BaseOptions(baseUrl:)` only): a hung connection hangs the call. The repo relies on bloc-level design (background pushes) rather than Dio timeouts. `graphqlQueryCall` is the one exception (3 s `sendTimeout`), and it is unused.
14. **`convertDioExceptionToAppException` only maps `unknown`+`SocketException` to `InternetException`**; Dio 5's `connectionError` becomes `FetchDataException`. Catch `AppException`, never a subclass.
15. **`returnResponse` uses `statusCode!`** — a `Response` without a status would throw; Dio always sets one for delivered responses.
16. **`FormData` switches the Supabase `Content-Type` to multipart** (`Headers.multipartFormDataContentType`) only on POST; the curl logger prints form fields as `key=value&file=@name`.
17. **Request bodies are logged in release** via `dart:developer` `log` (`_logRequest`, and `SERVICE GET ERROR … ${e.response?.data}`); only the curl interceptor is debug-gated.
18. **PostgREST `and`/`or` filters go in one `and` key** (`'(or(a.is.null,a.lte.X),or(b.is.null,b.gte.X))'`) because a `Map` cannot hold two `or` keys; the ISO timestamp is `now.toUtc().toIso8601String()` (ends in `Z`).
19. **Exact-match coupon lookup uses `eq.`, never `ilike`** (wildcards `%`/`_`); the test asserts `isNot(contains('ilike'))`.
20. **Token retry is exactly once** and only after `errorCode == '401'`; `invalidate()` then `token(refresh: true)`. StockShip requires a token (`KoTokenException` before any call); KO Utils routes go without one (`headers: {if (token != null) 'Authorization': …}`) and retry only `if (token != null && …)`.
21. **404 → `null` is checked *after* the 401 retry and *before* the generic throw** (StockShip); ref-orders has no 404 special case (an empty `data` list is "none").
22. **KO's error code fallback is `'HTTP_$status'`**, and `_read` looks in both the top level and `body['data']` for `message|error|msg` and `code|error_code|errorCode`; 409 becomes `OrderInProgressException` (a `ServerException` subclass with `code 'ORDER_IN_PROGRESS'`).
23. **`asMap` returns `const {}`** (unmodifiable) on a miss — never mutate its result.
24. **`FakeNetworking.queued` answers are consumed in order and fall back to `response`**; `error` wins over both. It lacks `putAPICall`/`graphqlQueryCall` (`noSuchMethod`).
25. **`DeviceSecureStorage` shares one static `_memory` across instances**, so the token the service reads on every call is an in-memory lookup after the first read; `FakeSecureStorage` is the test double.
26. **`Failure` is not `Equatable`** and has no `const` constructor; bloc states that hold a `Failure` compare by identity, which is why `listenWhen: current.failure != previous.failure` works per emission.
27. **`InvalidResponse` and `HttpMethod` exist but are unused**; data sources express the "neither" branch as `ServerException(code: 'INVALID_RESPONSE', status: 0)`.
28. **`pubspec.yaml` lists `.env` as an asset** (`assets: - .env`); without that line `dotenv.load` fails at startup. `.env` is git-ignored; `.env.example` is committed.
