# Inventory — area `domain-data-shapes`

Repo: `C:/Users/Katyayani/Documents/flutter/mymali` (package name `mymali`; Dart SDK `^3.13.4`).
Source of truth: the code. AGENTS.md is quoted where it differs. Every file below was read in full.

Scope covered: `lib/core/usecases/usecase.dart`, `lib/core/app/failure.dart`, the complete
`domain/` and `data/` folders of `features/auth`, `features/orders`, `features/gstin`, the core
files they import, the DI wiring for the three features, and every test under
`test/features/{auth,orders,gstin}/{data,domain}` plus the `test/helpers` fakes they use.

Classification key:
- **ALWAYS** — generic architecture; install in every app (placeholders listed where MyMali values appear).
- **CONDITIONAL(x)** — install only when the target app has capability *x*.
- **MYMALI-SPECIFIC** — MyMali business logic (KO-Tech, StockShip, Medusa, coins, …). Still a *pattern reference*: the shape is reproduced, the names are not.
- **TEMPLATE** (extra tag) — this file is the worked example whose *shape* every feature copies.

---

## 1. Files

### 1a. Area files

| Path | Role (one line) | Class | Placeholders another app substitutes |
|---|---|---|---|
| `lib/core/usecases/usecase.dart` | `UseCase<T, Params>` contract (one `call`) and `NoParams` | ALWAYS | none |
| `lib/core/app/failure.dart` | `Failure` base (`message`, `int? code`), `NetworkFailure`, `ServerFailure(errorCode)`, `CacheMissFailure` | ALWAYS (`CacheMissFailure` is only *used* when the app caches, but it lives here once per AGENTS §20) | default messages `'No internet connection.'`, `'Something went wrong.'`, `'Nothing saved on this device.'` |
| `lib/features/auth/domain/entities/auth_user.dart` | The signed-in user entity; `withProfile` copy method | CONDITIONAL(app signs users in) · TEMPLATE for an entity with a derived copy method | fields `roles`, `activeRole`, `userKey` (phone-derived) are MyMali's user model |
| `lib/features/auth/domain/entities/auth_session.dart` | `AuthSession(user, accessToken, refreshToken, expiresAt)` | CONDITIONAL(app signs users in) | none |
| `lib/features/auth/domain/entities/auth_tokens.dart` | `AuthTokens(accessToken, refreshToken, userId)` | CONDITIONAL(app stores tokens) | none |
| `lib/features/auth/domain/entities/otp_request.dart` | `OtpRequest(fullName, phoneDigits)` + derived `apiPhone` | CONDITIONAL(phone-OTP login) · TEMPLATE for a request entity with a derived getter | `'91$phoneDigits'` country code; "10 digits" rule |
| `lib/features/auth/domain/entities/verify_otp_request.dart` | `VerifyOtpRequest(fullName, phoneDigits, otp)` + `apiPhone` | CONDITIONAL(phone-OTP login) | `'91'` country code |
| `lib/features/auth/domain/failures/auth_failures.dart` | Seven `Failure` subclasses with default messages and `super.code` | CONDITIONAL(phone-OTP login) · TEMPLATE for a `<feature>_failures.dart` file | class names + messages mirror the `phone-login` Edge Function's error codes |
| `lib/features/auth/domain/repositories/auth_repository.dart` | `abstract interface class AuthRepository` (sendOtp, verifyOtp, hasActiveSession, restoreSession, signOut) | CONDITIONAL(app signs users in) · TEMPLATE for a repository contract | none |
| `lib/features/auth/domain/usecases/send_otp.dart` | `SendOtp implements UseCase<Unit, OtpRequest>` | CONDITIONAL · TEMPLATE for an entity-params use case | none |
| `lib/features/auth/domain/usecases/verify_otp.dart` | `VerifyOtp implements UseCase<AuthSession, VerifyOtpRequest>` | CONDITIONAL | none |
| `lib/features/auth/domain/usecases/restore_session.dart` | `RestoreSession implements UseCase<AuthSession?, NoParams>` | CONDITIONAL · TEMPLATE for a `NoParams` use case returning a nullable | none |
| `lib/features/auth/domain/usecases/sign_out.dart` | `SignOut implements UseCase<Unit, NoParams>` | CONDITIONAL · TEMPLATE for a `Unit` use case | none |
| `lib/features/auth/domain/utils/phone_normalizer.dart` | `normalizeIndianMobile(raw)` pure function | CONDITIONAL(Indian mobile numbers) | `'91'`, leading `'0'`, 10 digits |
| `lib/features/auth/domain/utils/phone_to_id.dart` | `phoneToId(phone)` → UUID-shaped `userKey` | MYMALI-SPECIFIC (backend keys `mali_*` tables by this) | the 8-4-4-4-12 padding rule |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Edge Function `phone-login` POSTs; `_supabaseHeaders`; `_toServerException` | CONDITIONAL(Supabase Edge Functions) · TEMPLATE for every Edge-Function data source | `Endpoints.phoneLogin`, body/response keys, `UNEXPECTED_RESPONSE` checks |
| `lib/features/auth/data/datasources/auth_session_data_source.dart` | The only class touching `SupabaseClient.auth` | CONDITIONAL(Supabase Auth SDK session) | codes `SESSION_FAILED`, `SIGN_OUT_FAILED` |
| `lib/features/auth/data/datasources/auth_local_data_source.dart` | Tokens in `SecureStorage` under three keys; legacy-prefs migration; `clearUserScoped()` on clear | CONDITIONAL(app stores tokens) (migration part: MYMALI-SPECIFIC upgrade history) | keys `auth.access_token`, `auth.refresh_token`, `auth.user_id` |
| `lib/features/auth/data/models/auth_tokens_model.dart` | Four-conversion model for `{access_token, refresh_token, user_id}` | CONDITIONAL(app stores tokens) · TEMPLATE for the four-conversion model | the three JSON keys |
| `lib/features/auth/data/models/otp_request_model.dart` | Request body model with a constant `action` | CONDITIONAL(phone-OTP) · TEMPLATE for a request model whose entity lacks a wire field | `'send'`, `'91'`, keys `action`/`phone` |
| `lib/features/auth/data/models/verify_otp_request_model.dart` | Request body model `{action, phone, otp, fullName}` | CONDITIONAL(phone-OTP) | `'verify'`, `'91'`, key `fullName` (camelCase, as the API defines it) |
| `lib/features/auth/data/models/send_otp_response_model.dart` | Response-only model `{ok}` (no entity) | CONDITIONAL(phone-OTP) · TEMPLATE for a response model with no entity | key `ok` |
| `lib/features/auth/data/models/auth_session_model.dart` | Built only from `supabase.Session` (named factory, JWT decode); `toEntity` | CONDITIONAL(Supabase Auth) | `'CUSTOMER'`, `'@phone.mymali.app'`, claims `user_roles`/`active_role`, metadata `full_name`/`phone` |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Exception → Failure switch per method; token-save side effects; refresh subscription; `dispose()` | CONDITIONAL(app signs users in) · TEMPLATE for a repository impl | the error-code `case` strings |
| `lib/features/orders/domain/entities/warehouse_order.dart` | `WarehouseOrderItem`, `OrderStage`, `OrderDiscount`, `WarehouseOrder` (+6 derived getters) | MYMALI-SPECIFIC (StockShip) · pattern reference for an entity with defaults, derived getters and a private static helper | `KMM-` numbers, "coins", warehouse vocabulary |
| `lib/features/orders/domain/entities/order_party.dart` | `OrderParty` (all-default-`''` fields, `name`, `addressLine`) | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/entities/orders_page.dart` | `OrdersPage(orders, page, hasMore)` | MYMALI-SPECIFIC · pattern reference for a paged result entity | none |
| `lib/features/orders/domain/entities/order_event.dart` | `OrderEvent(status, at)` | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/entities/ref_order_lookup.dart` | `RefOrderLookup(refId, orderId, status, paymentId)` + `isCompleted` | MYMALI-SPECIFIC (KO ref-orders) | none |
| `lib/features/orders/domain/entities/buy_again.dart` | `BuyAgainLine`, `BuyAgain` (depends on cart's `CartItem`) | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/repositories/orders_repository.dart` | Contract with named params and nullable results | MYMALI-SPECIFIC · pattern reference for named-parameter repository methods | none |
| `lib/features/orders/domain/usecases/get_my_orders.dart` | `GetMyOrdersParams` + `GetMyOrders` | MYMALI-SPECIFIC · TEMPLATE for `<UseCase>Params` in the same file | none |
| `lib/features/orders/domain/usecases/get_warehouse_order.dart` | `GetWarehouseOrderParams` + `GetWarehouseOrder` | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/usecases/find_order_placed_after.dart` | `FindOrderPlacedAfterParams` + `FindOrderPlacedAfter` | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/usecases/get_ref_order.dart` | `GetRefOrderParams` + `GetRefOrder` | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/usecases/get_order_products.dart` | `GetOrderProducts` (NoParams; cached-else-fresh over another feature's repository) | MYMALI-SPECIFIC · pattern reference for a cross-feature use case | none |
| `lib/features/orders/domain/usecases/buy_again_order.dart` | `BuyAgainOrder implements UseCase<BuyAgain, WarehouseOrder>` (entity as params; calls another use case inline) | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/utils/order_status.dart` | `OrderStatus` enum with switch getters, `orderStatusOf`, `OrderFilter`, `journeyStageCount` | MYMALI-SPECIFIC · pattern reference for an enum-with-getters + keyword mapper | the warehouse words |
| `lib/features/orders/domain/utils/ref_order_id.dart` | `isRefOrderId(id)` regex predicate | MYMALI-SPECIFIC | `^order_`, `^MYM(ALI)?-` |
| `lib/features/orders/domain/utils/order_placed_after.dart` | `warehouseClockSkew`, `orderPlacedAfter(...)` | MYMALI-SPECIFIC | 2 minutes |
| `lib/features/orders/domain/utils/order_timeline.dart` | `orderTimeline(order)` | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/utils/buy_again.dart` | `buyAgainFor(order, products)` | MYMALI-SPECIFIC | none |
| `lib/features/orders/domain/utils/order_invoice.dart` | `invoiceForOrder(order)` → invoice feature's `Invoice` | MYMALI-SPECIFIC | none |
| `lib/features/orders/data/exceptions/orders_exceptions.dart` | `StockshipException`, `RefOrdersException` (status 0 = no answer), `KoTokenException` | MYMALI-SPECIFIC · TEMPLATE for a per-host feature exception file | class names |
| `lib/features/orders/data/datasources/stockship_remote_data_source.dart` | Third-party GET with mandatory minted bearer, 404 → none, 401 retry once | MYMALI-SPECIFIC · TEMPLATE for a third-party-host data source | `StockshipEndpoints.orders`, `mktp_id`, query names, `pageSize = 20` |
| `lib/features/orders/data/datasources/ref_order_remote_data_source.dart` | Third-party GET with *optional* bearer, 401 retry only if a token was sent | MYMALI-SPECIFIC · TEMPLATE for the optional-token variant | `KoUtilsEndpoints.refOrders`, `user_phone`, `ref_id`, `'+91'` |
| `lib/features/orders/data/models/stockship_order_model.dart` | `StockshipItemModel`, `StockshipPartyModel`, `StockshipOrderModel` (four conversions, lossy `fromEntity`), `StockshipOrderPageModel` | MYMALI-SPECIFIC · pattern reference for lenient nested models with records and `?key` entries | every JSON key |
| `lib/features/orders/data/models/ref_order_model.dart` | `RefOrderModel` (fromJson/toJson/toLookup/toEntity, no fromEntity) with business predicates | MYMALI-SPECIFIC | `maliSources`, `pendingGrace`, keys |
| `lib/features/orders/data/repositories/orders_repository_impl.dart` | Network-only, two hosts, never-throwing private helpers, injected clock, `_toFailure` | MYMALI-SPECIFIC · TEMPLATE for a multi-host network-only repository | `'NO_KO_TOKEN'`, `'HTTP_${e.status}'`, `[orders]` log prefix |
| `lib/features/gstin/domain/entities/gstin.dart` | `Gstin(number, stateName, legalName)` | CONDITIONAL(app collects Indian GSTINs) | none |
| `lib/features/gstin/domain/failures/gstin_failures.dart` | Three failures *without* `super.code` (validation-only) | CONDITIONAL(GSTIN) · TEMPLATE for failures of a device-side validation | messages |
| `lib/features/gstin/domain/repositories/gstin_repository.dart` | `verifyGstin({userKey, number})`, `getSavedGstins(userKey)` | CONDITIONAL(GSTIN) | none |
| `lib/features/gstin/domain/usecases/verify_gstin.dart` | `VerifyGstinParams` + `VerifyGstin` | CONDITIONAL(GSTIN) · TEMPLATE (params class) | none |
| `lib/features/gstin/domain/usecases/get_saved_gstins.dart` | `GetSavedGstinsParams` + `GetSavedGstins` | CONDITIONAL(GSTIN) | none |
| `lib/features/gstin/domain/utils/gstin_validation.dart` | `validateGstin` → `Either<Failure, String>`, `gstinStates`, `normalizeGstin`, `gstinStateName`, `gstinCheckCharacter`, `gstinLength` | CONDITIONAL(GSTIN) · TEMPLATE for an `Either`-returning domain validator | none (Indian law, not per app) |
| `lib/features/gstin/data/models/gstin_model.dart` | Four conversions + `toUpsertJson({userKey, savedAt})`, `checksumMethod` | CONDITIONAL(GSTIN) · TEMPLATE for a model with an extra write-shape | table columns |
| `lib/features/gstin/data/datasources/gstin_remote_data_source.dart` | PostgREST GET (`select`, `eq.`, `order`) and POST upsert (`on_conflict`, `Prefer`); `_restHeaders`; PostgREST `_toServerException` | CONDITIONAL(Supabase PostgREST) · TEMPLATE for every PostgREST data source | `Endpoints.gstins`, `listColumns`, `user_key,gstin` |
| `lib/features/gstin/data/repositories/gstin_repository_impl.dart` | Domain validation first (no request on failure), best-effort save, list with error mapping | CONDITIONAL(GSTIN) · TEMPLATE for "validate then best-effort write" | none |

### 1b. Dependencies followed (read in full; owned by other areas but required by this one)

| Path | Role | Class | Placeholders |
|---|---|---|---|
| `lib/core/app/exceptions/api_exceptions.dart` | `ServerException({code, status, detail})`, `ConnectionException([message])` — the data layer's typed exceptions | ALWAYS | none |
| `lib/core/app/exceptions/app_exceptions.dart` | Legacy `AppException(message, prefix)` family thrown by `NetworkingService` when no response arrived; **also defines a second `ServerException`** | ALWAYS (networking throws it) — import with `show AppException` | none |
| `lib/core/app/exceptions/cache_exceptions.dart` | `CacheException([message])` | CONDITIONAL(app caches server data) | none |
| `lib/core/app/api/api_response.dart` | `APIResponse`, `SuccessResponse`, `ErrorResponse`, `InvalidResponse` — what every data source pattern-matches on | ALWAYS (AGENTS §16 calls it legacy with analyzer warnings, but it is load-bearing) | none |
| `lib/core/utils/json_readers.dart` | `asDouble/asInt/asNumeric/asString/asBool/asMap/asMapList/asStringList` lenient readers | ALWAYS | none |
| `lib/core/utils/string_constants.dart` | Legacy constants; only `StringConstants.appAuthToken = 'auth.access_token'` is used by the new code | ALWAYS (just that const) | the key string |
| `lib/core/services/networking/networking.dart` | `ApiHost` enum, `abstract class Networking`, `NetworkingService` | ALWAYS (detail in the networking area) | `ApiHost` values `supabase, medusa, koUtils, stockship` |
| `lib/core/services/networking/endpoints.dart` | `Endpoints`, `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | ALWAYS (shape); the paths are MYMALI-SPECIFIC | every path |
| `lib/core/repositories/base_api_repository.dart` | `BaseApiRepo`: one `Dio` per host | ALWAYS (shape) | one `Dio` per `ApiHost` |
| `lib/core/services/kotech/ko_token_service.dart` | `KoTokenService { token({refresh}); invalidate(); }` + Impl minting via Edge Function | MYMALI-SPECIFIC · pattern reference for "minted third-party bearer" | `Endpoints.kotechToken`, `KoEnv` |
| `lib/core/services/secure_storage/secure_storage.dart` | `SecureStorage { read; write; delete; }` (never throws) | CONDITIONAL(app stores tokens) | none |
| `lib/core/services/local_cache/local_cache.dart` | `LocalCache` interface | CONDITIONAL(app caches server data) | none |
| `lib/core/services/local_cache/cache_boxes.dart` | `CacheBoxes` consts, `all`, `userScoped` | CONDITIONAL(app caches) | box names; `userScoped = [addresses, maliCoins]` |
| `lib/core/services/pref_utils.dart` | `PrefUtils` over SharedPreferences (`init`, `getString`, `setString`, `remove`, …) | ALWAYS (legacy-shaped) | none |
| `lib/core/config/env.dart` | `Env` typed getters, `KoEnv`, `RazorpayMode`, `_require`, `_optional`, `_koValue` | ALWAYS (shape) | every env key |
| `lib/core/di/injection_container.dart` | `sl`, `configureDependencies`, `_register<Feature>Data`, `register<Feature>Feature` | ALWAYS (shape) | feature names |
| `lib/features/cart/domain/entities/cart_item.dart` | `CartItem` (used by `BuyAgainLine`) | MYMALI-SPECIFIC | — |
| `lib/features/cart/domain/utils/cart_item_from_product.dart` | `cartItemFor(product, variant, {quantity})` | MYMALI-SPECIFIC | — |
| `lib/features/catalog/domain/entities/catalog_product.dart`, `product_variant.dart`, `catalog_snapshot.dart` | Catalog entities read by orders utils | MYMALI-SPECIFIC | — |
| `lib/features/catalog/domain/repositories/catalog_repository.dart` | `CatalogRepository` (get/getCached pairs) | MYMALI-SPECIFIC · pattern reference for cache-first contract | — |
| `lib/features/invoice/domain/entities/invoice.dart` | `Invoice`, `InvoiceParty`, `InvoiceLine` | MYMALI-SPECIFIC | — |

### 1c. Tests read (paths mirror `lib/`)

`test/features/auth/data/models/{auth_tokens_model,otp_request_model,send_otp_response_model,auth_session_model}_test.dart`,
`test/features/auth/data/datasources/{auth_remote_data_source,auth_local_data_source}_test.dart`,
`test/features/auth/data/repositories/auth_repository_impl_test.dart`,
`test/features/auth/domain/usecases/send_otp_test.dart`, `test/features/auth/domain/utils/phone_normalizer_test.dart`,
`test/features/orders/data/datasources/{ref_order_remote_data_source,stockship_remote_data_source}_test.dart`,
`test/features/orders/data/models/{ref_order_model,stockship_order_model}_test.dart`,
`test/features/orders/data/repositories/orders_repository_impl_test.dart`,
`test/features/orders/domain/utils/{buy_again,order_invoice,order_placed_after,order_status,order_timeline,ref_order_id}_test.dart`,
`test/features/gstin/data/datasources/gstin_remote_data_source_test.dart`, `test/features/gstin/data/models/gstin_model_test.dart`,
`test/features/gstin/data/repositories/gstin_repository_impl_test.dart`, `test/features/gstin/domain/utils/gstin_validation_test.dart`,
`test/helpers/{fake_networking,fake_secure_storage,fake_local_cache,fake_auth_repository,fake_orders_repository,fake_gstin_repository,fake_catalog_repository}.dart`.

---

## 2. Names

Every public name in the area. `[A]` = ALWAYS, `[C]` = CONDITIONAL, `[M]` = MYMALI-SPECIFIC (reproduce the shape, rename the business).

### 2a. Core

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `UseCase<T, Params>` [A] | abstract interface class | `lib/core/usecases/usecase.dart` | `abstract interface class UseCase<T, Params> { Future<Either<Failure, T>> call(Params params); }` |
| `NoParams` [A] | class extends Equatable | `lib/core/usecases/usecase.dart` | `class NoParams extends Equatable { const NoParams(); @override List<Object?> get props => []; }` |
| `Failure` [A] | class (NOT Equatable, non-const) | `lib/core/app/failure.dart` | `class Failure { final String message; final int? code; Failure({required this.message, this.code}); @override String toString() => 'Failure(code: $code, message: $message)'; }` |
| `NetworkFailure` [A] | class extends Failure | `lib/core/app/failure.dart` | `NetworkFailure({super.message = 'No internet connection.', super.code});` |
| `ServerFailure` [A] | class extends Failure | `lib/core/app/failure.dart` | `ServerFailure({required this.errorCode, super.message = 'Something went wrong.', super.code}); final String errorCode;` |
| `CacheMissFailure` [A] | class extends Failure | `lib/core/app/failure.dart` | `CacheMissFailure({super.message = 'Nothing saved on this device.'});` (no `code`) |
| `ServerException` [A] | class implements Exception (const) | `lib/core/app/exceptions/api_exceptions.dart` | `const ServerException({required this.code, required this.status, this.detail}); final String code; final int status; final String? detail; toString() => 'ServerException($status $code: $detail)'` |
| `ConnectionException` [A] | class implements Exception (const) | `lib/core/app/exceptions/api_exceptions.dart` | `const ConnectionException([this.message]); final String? message;` |
| `AppException` [A] | class implements Exception | `lib/core/app/exceptions/app_exceptions.dart` | `AppException(this.message, this.prefix); final String message; final String prefix; toString() => '$prefix: $message'` |
| `InternetException`, `RequestTimeoutException`, `ServerException` (legacy), `InvalidUrlException`, `FetchDataException`, `UnAuthorizedException`, `AuthException` [A] | classes extend AppException | `lib/core/app/exceptions/app_exceptions.dart` | each `X([String? message]) : super(message ?? '<default>', '<Prefix>')`; thrown by `NetworkingService.convertDioExceptionToAppException` |
| `CacheException` [C: caching] | class implements Exception (const) | `lib/core/app/exceptions/cache_exceptions.dart` | `const CacheException([this.message]); final String? message;` |
| `APIResponse` [A] | abstract class extends Equatable | `lib/core/app/api/api_response.dart` | `const APIResponse({this.data, this.code = '', this.message = ''});` |
| `SuccessResponse` [A] | class extends APIResponse | same | `const SuccessResponse({required this.successMessage, required this.statusCode, required this.rawData, required super.data})`; `statusCode` is a **String** (`'200'`); read the body from `rawData` |
| `ErrorResponse` [A] | class extends APIResponse | same | `const ErrorResponse({required this.errorMessage, required this.errorCode, this.rawData, required super.data})`; `errorCode` is the HTTP status as **String** (`'401'`) |
| `InvalidResponse` [A] | class extends APIResponse | same | `const InvalidResponse() : super(code: 'INVALID_RESPONSE', message: 'Invalid API response');` |
| `asDouble`, `asInt`, `asNumeric`, `asString`, `asBool`, `asMap`, `asMapList`, `asStringList` [A] | top-level functions | `lib/core/utils/json_readers.dart` | `double? asDouble(Object?)`, `int? asInt(Object?)`, `double? asNumeric(Object?)` (num or numeric string), `String? asString(Object?)`, `bool? asBool(Object?)`, `Map<String, dynamic> asMap(Object?)` (empty map fallback), `List<Map<String, dynamic>> asMapList(Object?)`, `List<String> asStringList(Object?)` |
| `StringConstants.appAuthToken` [A] | static const String | `lib/core/utils/string_constants.dart` | `static const String appAuthToken = 'auth.access_token';` |
| `ApiHost` [A shape / M values] | enum | `lib/core/services/networking/networking.dart` | `enum ApiHost { supabase, medusa, koUtils, stockship }` |
| `Networking` [A] | abstract class | same | `getAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, Map<String, String>? headers, ApiHost host = ApiHost.supabase})`; `postAPICall({… dynamic data, Map<String, String>? headers, ApiHost host = ApiHost.supabase})`; `patchAPICall`, `deleteAPICall` same; `putAPICall` has **no `headers`**; `graphqlQueryCall` |
| `Endpoints.phoneLogin` [C] | static const String | `lib/core/services/networking/endpoints.dart` | `'/functions/v1/phone-login'` |
| `Endpoints.gstins` [C] | static const String | same | `'/rest/v1/mali_gstins'` |
| `Endpoints.kotechToken` [M] | static const String | same | `'/functions/v1/kotech-token'` |
| `KoUtilsEndpoints.refOrders` [M] | static const String | same | `'/order/ref-orders'` |
| `StockshipEndpoints.orders` [M] | static const String | same | `'/api/orders'` |
| `KoTokenService` [M] | abstract interface class | `lib/core/services/kotech/ko_token_service.dart` | `Future<String?> token({bool refresh = false}); void invalidate();` |
| `SecureStorage` [C: tokens] | abstract interface class | `lib/core/services/secure_storage/secure_storage.dart` | `Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key);` |
| `LocalCache` [C: caching] | abstract interface class | `lib/core/services/local_cache/local_cache.dart` | `read({required String box, required String key, required int version, Duration? maxAge})`, `write({box, key, version, required Object json})`, `delete({box, key})`, `clearBox(String box)`, `clearUserScoped()` |
| `CacheBoxes` [C: caching] | abstract final class | `lib/core/services/local_cache/cache_boxes.dart` | `static const String catalog = 'catalog'` … ; `static const List<String> all`; `static const List<String> userScoped = [addresses, maliCoins];` |
| `PrefUtils` [A] | class | `lib/core/services/pref_utils.dart` | `Future<void> init()`, `Future<bool> setString({required String key, required String value})`, `String? getString({required String key})`, `Future<bool> remove({required String key})`, `Map<String, dynamic> getAllData()`, `Future<bool> clearAll()`, … |
| `Env` [A shape] | abstract final class | `lib/core/config/env.dart` | `static Future<void> load()`, `static String get supabaseUrl => _require('SUPABASE_URL')`, `supabaseAnonKey`, `medusaBaseUrl`, `medusaApiKey`, `webOrigin`, `koEnv` (enum `KoEnv { production, beta }`), `utilsUrl`, `stockshipUrl`, `razorpayKeyId`, `razorpayMode`, `allowTestPayments`, `mktpId`, `kcSiteId`, `kcApiUrl`, `fbAppId`, `fbClientToken`, `appVersion`; `_koValue(key)` picks `'${key}_PROD'`/`'${key}_BETA'`; `_require` throws `StateError('Missing $key in .env (see .env.example).')` |
| `sl` [A] | top-level final | `lib/core/di/injection_container.dart` | `final GetIt sl = GetIt.instance;` |
| `configureDependencies()` [A] | top-level function | same | calls `_registerCore()` then `_register<X>Data(); register<X>Feature();` pairs in dependency order |
| `registerAuthFeature()`, `registerOrdersFeature()`, `registerGstinFeature()` [A shape] | top-level functions | same | see Pattern P20 |

### 2b. Auth — domain

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `AuthUser` [C] | entity (Equatable) | `lib/features/auth/domain/entities/auth_user.dart` | `const AuthUser({required this.id, required this.phone, this.fullName, this.email, required this.roles, required this.activeRole, required this.userKey})`; fields `String id; String phone; String? fullName; String? email; List<String> roles; String activeRole; String userKey`; `AuthUser withProfile({String? fullName, String? email})` |
| `AuthSession` [C] | entity | `.../entities/auth_session.dart` | `const AuthSession({required this.user, required this.accessToken, required this.refreshToken, required this.expiresAt})`; `AuthUser user; String accessToken; String refreshToken; DateTime expiresAt` |
| `AuthTokens` [C] | entity | `.../entities/auth_tokens.dart` | `const AuthTokens({required this.accessToken, required this.refreshToken, required this.userId})` |
| `OtpRequest` [C] | entity | `.../entities/otp_request.dart` | `const OtpRequest({required this.fullName, required this.phoneDigits}); String get apiPhone => '91$phoneDigits';` |
| `VerifyOtpRequest` [C] | entity | `.../entities/verify_otp_request.dart` | `const VerifyOtpRequest({required this.fullName, required this.phoneDigits, required this.otp}); String get apiPhone => '91$phoneDigits';` |
| `InvalidPhoneFailure`, `OtpSendFailure`, `InvalidOtpFailure`, `OtpExpiredFailure`, `OtpNotSentFailure`, `OtpAttemptsExceededFailure`, `OtpVerifyFailure` [C] | Failure subclasses | `.../failures/auth_failures.dart` | each `X({super.message = '<default>', super.code});` — defaults: `'Invalid phone number.'`, `'Could not send the code.'`, `'Invalid code.'`, `'The code has expired.'`, `'No code was sent.'`, `'Too many attempts.'`, `'Could not verify the code.'` |
| `AuthRepository` [C] | abstract interface class | `.../repositories/auth_repository.dart` | `Future<Either<Failure, Unit>> sendOtp(OtpRequest request); Future<Either<Failure, AuthSession>> verifyOtp(VerifyOtpRequest request); bool get hasActiveSession; Future<Either<Failure, AuthSession?>> restoreSession(); Future<Either<Failure, Unit>> signOut();` |
| `SendOtp` [C] | use case | `.../usecases/send_otp.dart` | `class SendOtp implements UseCase<Unit, OtpRequest> { const SendOtp(this._repository); final AuthRepository _repository; call(OtpRequest params) => _repository.sendOtp(params); }` |
| `VerifyOtp` [C] | use case | `.../usecases/verify_otp.dart` | `implements UseCase<AuthSession, VerifyOtpRequest>`; `call(params) => _repository.verifyOtp(params)` |
| `RestoreSession` [C] | use case | `.../usecases/restore_session.dart` | `implements UseCase<AuthSession?, NoParams>`; `call(NoParams params) => _repository.restoreSession()` |
| `SignOut` [C] | use case | `.../usecases/sign_out.dart` | `implements UseCase<Unit, NoParams>`; `call(NoParams params) => _repository.signOut()` |
| `normalizeIndianMobile` [C] | function | `.../utils/phone_normalizer.dart` | `String normalizeIndianMobile(String raw)` |
| `phoneToId` [M] | function | `.../utils/phone_to_id.dart` | `String phoneToId(String phone)` → digits right-padded with `'0'` to 32, grouped 8-4-4-4-12 |

### 2c. Auth — data

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `AuthLocalDataSource` [C: tokens] | abstract interface class | `.../data/datasources/auth_local_data_source.dart` | `Future<void> saveTokens(AuthTokensModel tokens); Future<AuthTokensModel?> readTokens(); Future<void> clearTokens();` |
| `AuthLocalDataSourceImpl` [C] | class | same | `AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache);` (positional: `SecureStorage`, `PrefUtils`, `LocalCache`); `static const String accessTokenKey = StringConstants.appAuthToken; static const String refreshTokenKey = 'auth.refresh_token'; static const String userIdKey = 'auth.user_id';` |
| `AuthRemoteDataSource` [C] | abstract interface class | `.../auth_remote_data_source.dart` | `Future<SendOtpResponseModel> sendOtp(OtpRequestModel request); Future<AuthTokensModel> verifyOtp(VerifyOtpRequestModel request);` |
| `AuthRemoteDataSourceImpl` [C] | class (const) | same | `const AuthRemoteDataSourceImpl({required Networking networking, required String anonKey})` |
| `AuthSessionDataSource` [C: Supabase] | abstract interface class | `.../auth_session_data_source.dart` | `Future<AuthSessionModel> establish(AuthTokensModel tokens); Future<AuthSessionModel?> restore(); bool get hasActiveSession; Stream<AuthSessionModel> get refreshedSessions; Future<void> signOut();` |
| `AuthSessionDataSourceImpl` [C] | class (const) | same | `const AuthSessionDataSourceImpl(this._client);` (`supabase.SupabaseClient`) |
| `AuthTokensModel` [C] | model | `.../models/auth_tokens_model.dart` | `const AuthTokensModel({required this.accessToken, required this.refreshToken, required this.userId})`; `factory .fromJson(Map<String, dynamic>)`, `factory .fromEntity(AuthTokens)`, `Map<String, dynamic> toJson()`, `AuthTokens toEntity()`; keys `access_token`, `refresh_token`, `user_id` |
| `OtpRequestModel` [C] | model | `.../models/otp_request_model.dart` | `const OtpRequestModel({required this.action, required this.phone}); static const String sendAction = 'send';` + four conversions |
| `VerifyOtpRequestModel` [C] | model | `.../models/verify_otp_request_model.dart` | `const VerifyOtpRequestModel({required this.action, required this.phone, required this.otp, required this.fullName}); static const String verifyAction = 'verify';` + four conversions |
| `SendOtpResponseModel` [C] | model (no entity) | `.../models/send_otp_response_model.dart` | `const SendOtpResponseModel({required this.ok}); factory .fromJson(json) => SendOtpResponseModel(ok: json['ok'] == true); toJson() => {'ok': ok}` |
| `AuthSessionModel` [C] | model (SDK-built) | `.../models/auth_session_model.dart` | `const AuthSessionModel({required userId, required phone, fullName, email, required roles, required activeRole, required userKey, required accessToken, required refreshToken, required expiresAt})`; `static const String defaultRole = 'CUSTOMER';` `factory AuthSessionModel.fromSupabaseSession(supabase.Session s)`; `AuthSession toEntity()` |
| `AuthRepositoryImpl` [C] | class | `.../repositories/auth_repository_impl.dart` | `AuthRepositoryImpl({required AuthRemoteDataSource remote, required AuthSessionDataSource session, required AuthLocalDataSource local})`; `Future<void> dispose()` |

### 2d. Orders — domain

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `WarehouseOrderItem` [M] | entity | `.../orders/domain/entities/warehouse_order.dart` | `const WarehouseOrderItem({required this.title, required this.quantity, required this.unitPrice, required this.total, this.sku = '', this.imageUrl, this.variantLabel})` |
| `OrderStage` [M] | entity | same | `const OrderStage({required this.name, this.at}); String name; DateTime? at;` |
| `OrderDiscount` [M] | entity | same | `const OrderDiscount({required this.amount, this.code = ''});` |
| `WarehouseOrder` [M] | entity | same | `const WarehouseOrder({required this.id, this.status = '', this.isCashOnDelivery = true, this.isPaid = false, this.total = 0, this.placedAt, this.updatedAt, this.phones = const [], this.items = const [], this.coins = 0, this.discounts = const [], this.failureReason, this.customer, this.billing, this.shipping, this.stages = const [], this.isAwaitingWarehouse = false})`; getters `bool isOwnedBy(String tenDigits)`, `int get displayNumber`, `double get subtotal`, `double get discount`, `double get otherCharges`, `OrderParty? get deliverTo`, `OrderParty? get billTo` |
| `OrderParty` [M] | entity | `.../entities/order_party.dart` | `const OrderParty({this.firstName = '', this.lastName = '', this.phone = '', this.address1 = '', this.address2 = '', this.city = '', this.state = '', this.pincode = '', this.gstin = ''})`; `String get name`, `String get addressLine` |
| `OrdersPage` [M] | entity | `.../entities/orders_page.dart` | `const OrdersPage({required this.orders, required this.page, required this.hasMore})` |
| `OrderEvent` [M] | entity | `.../entities/order_event.dart` | `const OrderEvent({required this.status, required this.at}); OrderStatus status; DateTime at;` |
| `RefOrderLookup` [M] | entity | `.../entities/ref_order_lookup.dart` | `const RefOrderLookup({required this.refId, this.orderId = '', this.status = '', this.paymentId = ''}); bool get isCompleted => const ['complete', 'completed'].contains(status.trim().toLowerCase());` |
| `BuyAgainLine`, `BuyAgain` [M] | entities | `.../entities/buy_again.dart` | `const BuyAgainLine({required this.item, this.maxQuantity})` (`CartItem item; int? maxQuantity`); `const BuyAgain({this.lines = const [], this.unavailable = 0})` |
| `OrdersRepository` [M] | abstract interface class | `.../repositories/orders_repository.dart` | `findOrderPlacedAfter({required String phone, required DateTime placedAt})` → `Either<Failure, WarehouseOrder?>`; `getOrder({required String phone, required String orderId})` → `WarehouseOrder?`; `getOrders({required String phone, int page = 1})` → `OrdersPage`; `getRefOrder({required String refId})` → `RefOrderLookup?` |
| `GetMyOrdersParams` / `GetMyOrders` [M] | params + use case | `.../usecases/get_my_orders.dart` | `const GetMyOrdersParams({required this.phone, this.page = 1});` `class GetMyOrders implements UseCase<OrdersPage, GetMyOrdersParams>` |
| `GetWarehouseOrderParams` / `GetWarehouseOrder` [M] | params + use case | `.../usecases/get_warehouse_order.dart` | `const GetWarehouseOrderParams({required this.phone, required this.orderId});` `implements UseCase<WarehouseOrder?, GetWarehouseOrderParams>` |
| `FindOrderPlacedAfterParams` / `FindOrderPlacedAfter` [M] | params + use case | `.../usecases/find_order_placed_after.dart` | `const FindOrderPlacedAfterParams({required this.phone, required this.placedAt});` `implements UseCase<WarehouseOrder?, FindOrderPlacedAfterParams>` |
| `GetRefOrderParams` / `GetRefOrder` [M] | params + use case | `.../usecases/get_ref_order.dart` | `const GetRefOrderParams({required this.refId});` `implements UseCase<RefOrderLookup?, GetRefOrderParams>` |
| `GetOrderProducts` [M] | use case | `.../usecases/get_order_products.dart` | `class GetOrderProducts implements UseCase<List<CatalogProduct>, NoParams> { const GetOrderProducts(this._catalog); final CatalogRepository _catalog; … }` |
| `BuyAgainOrder` [M] | use case | `.../usecases/buy_again_order.dart` | `class BuyAgainOrder implements UseCase<BuyAgain, WarehouseOrder> { const BuyAgainOrder(this._catalog); final CatalogRepository _catalog; … }` |
| `OrderStatus` [M] | enum | `.../utils/order_status.dart` | `enum OrderStatus { pseudo, created, packed, dispatched, inTransit, outForDelivery, delivered, cancelled, rtoReceived, rtoInTransit, rtoDelivered; bool get isRto; bool get isClosed; bool get isActive; bool get hasJourney; int get journeyIndex; }` |
| `journeyStageCount` [M] | const int | same | `const int journeyStageCount = 5;` |
| `orderStatusOf` [M] | function | same | `OrderStatus orderStatusOf(String raw)` |
| `OrderFilter` [M] | enum | same | `enum OrderFilter { all, active, delivered, cancelled; bool matches(OrderStatus status) }` |
| `isRefOrderId` [M] | function | `.../utils/ref_order_id.dart` | `bool isRefOrderId(String id) => RegExp(r'^order_').hasMatch(id) \|\| RegExp(r'^MYM(ALI)?-').hasMatch(id);` |
| `warehouseClockSkew` [M] | const Duration | `.../utils/order_placed_after.dart` | `const Duration warehouseClockSkew = Duration(minutes: 2);` |
| `orderPlacedAfter` [M] | function | same | `WarehouseOrder? orderPlacedAfter(List<WarehouseOrder> orders, DateTime placedAt, String phone)` |
| `orderTimeline` [M] | function | `.../utils/order_timeline.dart` | `List<OrderEvent> orderTimeline(WarehouseOrder order)` |
| `buyAgainFor` [M] | function | `.../utils/buy_again.dart` | `BuyAgain buyAgainFor(WarehouseOrder order, List<CatalogProduct> products)` |
| `invoiceForOrder` [M] | function | `.../utils/order_invoice.dart` | `Invoice? invoiceForOrder(WarehouseOrder order)` |

### 2e. Orders — data

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `StockshipException` [M] | exception (const) | `.../orders/data/exceptions/orders_exceptions.dart` | `const StockshipException(this.status, [this.detail]); final int status; final String? detail;` |
| `RefOrdersException` [M] | exception (const) | same | `const RefOrdersException(this.status, [this.detail]);` |
| `KoTokenException` [M] | exception (const) | same | `const KoTokenException(); toString() => 'KoTokenException(no token)'` |
| `StockshipRemoteDataSource` [M] | abstract interface class | `.../datasources/stockship_remote_data_source.dart` | `Future<List<StockshipOrderModel>> listOrders({required String phone, int page = 1, int limit = pageSize}); Future<StockshipOrderPageModel> listOrderPage({required String phone, int page = 1, int limit = pageSize}); Future<StockshipOrderModel?> getOrder({required String orderId}); static const int pageSize = 20;` |
| `StockshipRemoteDataSourceImpl` [M] | class (const) | same | `const StockshipRemoteDataSourceImpl({required Networking networking, required KoTokenService tokens, required String mktpId})` |
| `RefOrderRemoteDataSource` [M] | abstract interface class | `.../datasources/ref_order_remote_data_source.dart` | `Future<List<RefOrderModel>> listByPhone({required String tenDigitPhone}); Future<RefOrderModel?> getByRefId({required String refId});` |
| `RefOrderRemoteDataSourceImpl` [M] | class (const) | same | `const RefOrderRemoteDataSourceImpl({required Networking networking, required KoTokenService tokens})` |
| `RefOrderModel` [M] | model | `.../models/ref_order_model.dart` | `const RefOrderModel({this.id, this.refId, this.razorpayOrderId, this.orderId, this.orderStatus, this.paymentId, this.paymentMode, this.orderSource, this.userPhone, this.createdAt, this.updatedAt, this.order = const {}})`; `fromJson`, `toJson`, `String get key`, `bool get isCompleted`, `bool get isCashOnDelivery`, `bool isLive(DateTime now)`, `static const Duration pendingGrace = Duration(minutes: 30)`, `static const Set<String> maliSources = {'my_mali_app', 'my_mali', 'mymali', 'my mali'}`, `bool get isMaliOrder`, `RefOrderLookup toLookup()`, `WarehouseOrder toEntity()` |
| `StockshipItemModel` [M] | model | `.../models/stockship_order_model.dart` | `const StockshipItemModel({this.sku = '', this.name, this.qty = 1, this.unitPrice, this.totalPrice, this.heroImage, this.variant})` + four conversions |
| `StockshipPartyModel` [M] | model | same | `const StockshipPartyModel({this.firstName, this.lastName, this.phone, this.gstNumber, this.address1, this.address2, this.city, this.state, this.pincode})` + four conversions |
| `StockshipOrderModel` [M] | model | same | `const StockshipOrderModel({this.id, this.orderId, this.orderStatus, this.paymentMode, this.totalAmount, this.codAmount, this.prepaidAmount, this.coin, this.date, this.createdAt, this.updatedAt, this.phones = const [], this.items = const [], this.failureMessage, this.customer, this.billingAddress, this.shippingAddress, this.discounts = const [], this.statusMap = const []})`; `discounts` is `List<({double amount, String? code})>`, `statusMap` is `List<({String name, String? timestamp})>`; four conversions |
| `StockshipOrderPageModel` [M] | model | same | `const StockshipOrderPageModel({required this.orders, required this.page, this.pages}); factory .fromJson(Map<String, dynamic> json, {required int requestedPage}); toJson()` |
| `OrdersRepositoryImpl` [M] | class | `.../repositories/orders_repository_impl.dart` | `OrdersRepositoryImpl({required StockshipRemoteDataSource stockship, required RefOrderRemoteDataSource refOrders, DateTime Function() now = DateTime.now})` |

### 2f. GSTIN — domain and data

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `Gstin` [C] | entity | `.../gstin/domain/entities/gstin.dart` | `const Gstin({required this.number, this.stateName, this.legalName});` |
| `GstinEmptyFailure`, `InvalidGstinFailure`, `GstinChecksumFailure` [C] | Failure subclasses | `.../domain/failures/gstin_failures.dart` | `GstinEmptyFailure({super.message = 'Enter a GSTIN.'});` `InvalidGstinFailure({super.message = 'This is not a valid GSTIN.'});` `GstinChecksumFailure({super.message = 'GSTIN check digit does not match.'});` (no `super.code`) |
| `GstinRepository` [C] | abstract interface class | `.../domain/repositories/gstin_repository.dart` | `Future<Either<Failure, Gstin>> verifyGstin({required String userKey, required String number}); Future<Either<Failure, List<Gstin>>> getSavedGstins(String userKey);` |
| `VerifyGstinParams` / `VerifyGstin` [C] | params + use case | `.../domain/usecases/verify_gstin.dart` | `const VerifyGstinParams({required this.userKey, required this.number});` `class VerifyGstin implements UseCase<Gstin, VerifyGstinParams>` |
| `GetSavedGstinsParams` / `GetSavedGstins` [C] | params + use case | `.../domain/usecases/get_saved_gstins.dart` | `const GetSavedGstinsParams({required this.userKey});` `implements UseCase<List<Gstin>, GetSavedGstinsParams>` |
| `gstinLength` [C] | const int | `.../domain/utils/gstin_validation.dart` | `const int gstinLength = 15;` |
| `gstinStates` [C] | const Map | same | `const Map<String, String> gstinStates = { '01': 'Jammu and Kashmir', … '99': 'Centre Jurisdiction' }` (41 entries, verbatim in the file) |
| `normalizeGstin` [C] | function | same | `String normalizeGstin(String input) => input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');` |
| `gstinStateName` [C] | function | same | `String? gstinStateName(String gstin) => gstin.length < 2 ? null : gstinStates[gstin.substring(0, 2)];` |
| `gstinCheckCharacter` [C] | function | same | `String gstinCheckCharacter(String gstin)` (mod-36 Luhn variant over `'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'`) |
| `validateGstin` [C] | function | same | `Either<Failure, String> validateGstin(String input)` |
| `GstinRemoteDataSource` [C] | abstract interface class | `.../data/datasources/gstin_remote_data_source.dart` | `Future<void> save({required String userKey, required GstinModel gstin}); Future<List<GstinModel>> list(String userKey);` |
| `GstinRemoteDataSourceImpl` [C] | class | same | `GstinRemoteDataSourceImpl({required Networking networking, required String anonKey, DateTime Function() now = DateTime.now})`; `static const String listColumns = 'gstin,legal_name,state_name';` |
| `GstinModel` [C] | model | `.../data/models/gstin_model.dart` | `const GstinModel({required this.gstin, this.stateName, this.legalName}); static const String checksumMethod = 'checksum';` four conversions + `Map<String, dynamic> toUpsertJson({required String userKey, required DateTime savedAt})` |
| `GstinRepositoryImpl` [C] | class (const) | `.../data/repositories/gstin_repository_impl.dart` | `const GstinRepositoryImpl({required GstinRemoteDataSource remote})` |

### 2g. Test helpers (names tests depend on)

| Name | File | Shape |
|---|---|---|
| `FakeNetworking`, `RecordedCall`, `okResponse(Object? body)`, `errorResponse(Object? body, String status)` | `test/helpers/fake_networking.dart` | `FakeNetworking implements Networking { Object? response; Object? error; final List<Object?> queued = []; final List<RecordedCall> calls = []; RecordedCall get lastCall => calls.last; … noSuchMethod }`; `RecordedCall({required method, required endpoint, queryParameters, data, headers, pathParameters, host = ApiHost.supabase})` |
| `FakeSecureStorage` | `test/helpers/fake_secure_storage.dart` | `FakeSecureStorage([Map<String, String>? values]) : values = {...?values}; final Map<String, String> values;` |
| `FakeLocalCache` | `test/helpers/fake_local_cache.dart` | `FakeLocalCache({DateTime? now})`; `DateTime now; CacheException? readError; CacheException? writeError; int clearUserScopedCalls = 0; List<String> keysOf(String box)` |
| `FakeAuthRepository`, `testSession` | `test/helpers/fake_auth_repository.dart` | `FakeAuthRepository({this.hasActiveSession = false}); Failure? sendOtpFailure; Failure? verifyOtpFailure; Completer<void>? sendOtpGate; Completer<void>? verifyOtpGate; final List<OtpRequest> sentOtps = []; final List<VerifyOtpRequest> verifiedOtps = [];` |
| `FakeOrdersRepository` | `test/helpers/fake_orders_repository.dart` | `WarehouseOrder? found; WarehouseOrder? byId; int findCallsBeforeMatch = 0; List<List<WarehouseOrder>> pages; Failure? failure; finds/gets/pageCalls records; Map<String, RefOrderLookup> refOrders; int refCallsBeforeMatch; List<String> refLookups` |
| `FakeGstinRepository`, `validGstinNumber`, `savedGstin` | `test/helpers/fake_gstin_repository.dart` | `const String validGstinNumber = '27AAPFU0939F1ZV'; const Gstin savedGstin = Gstin(number: validGstinNumber, stateName: 'Maharashtra');` fake runs the real `validateGstin` and records `saved` |
| `FakeCatalogRepository`, `testVariant`, `testProduct`, `testCategory`, `testCatalog`, `testSections`, `testSoldCounts`, `testLowStockThresholds` | `test/helpers/fake_catalog_repository.dart` | `…Failure?` per call, `…Calls` counters, `cached…` nullable fields, `Completer<void>? gate`, `Either<Failure, T> _cached<T>(T? value) => value == null ? Left(CacheMissFailure()) : Right(value);` |

---

## 3. Patterns

### P1 — The use-case contract and `NoParams` (verbatim, whole file)

`lib/core/usecases/usecase.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../app/failure.dart';

/// A single application action: one [call], one responsibility.
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// For use cases that take no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
```

Rule: `implements UseCase<T, Params>` (never `extends`); exactly one public method `call`; `T` may be nullable (`AuthSession?`, `WarehouseOrder?`) or `Unit`; `Params` is an entity, a dedicated `<UseCase>Params` class, or `NoParams`. Call sites pass `const NoParams()`. `NoParams` **is** Equatable; params classes are **not**.

### P2 — The failure base file (verbatim, whole file)

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

Rule: `Failure` is a plain class (not Equatable, not const). Tests match with `isA<XFailure>()`, never `==`. `code` is the HTTP status; a string API code goes in a differently named field (`ServerFailure.errorCode`).

### P3 — A feature failures file (verbatim, whole file)

`lib/features/auth/domain/failures/auth_failures.dart`:

```dart
import '../../../../core/app/failure.dart';

/// The phone number was rejected as invalid.
class InvalidPhoneFailure extends Failure {
  InvalidPhoneFailure({super.message = 'Invalid phone number.', super.code});
}

/// The code could not be sent (provider error or service not configured).
class OtpSendFailure extends Failure {
  OtpSendFailure({super.message = 'Could not send the code.', super.code});
}

/// The code entered was wrong.
class InvalidOtpFailure extends Failure {
  InvalidOtpFailure({super.message = 'Invalid code.', super.code});
}

/// The code has expired.
class OtpExpiredFailure extends Failure {
  OtpExpiredFailure({super.message = 'The code has expired.', super.code});
}

/// No code was sent for this number (or it was already used).
class OtpNotSentFailure extends Failure {
  OtpNotSentFailure({super.message = 'No code was sent.', super.code});
}

/// Too many wrong attempts for this code.
class OtpAttemptsExceededFailure extends Failure {
  OtpAttemptsExceededFailure({
    super.message = 'Too many attempts.',
    super.code,
  });
}

/// Verification, account creation or session setup failed on the server.
class OtpVerifyFailure extends Failure {
  OtpVerifyFailure({super.message = 'Could not verify the code.', super.code});
}
```

Rule: file `domain/failures/<feature>_failures.dart`; one class per *user-facing reason* (not per API code: `OTP_SEND_FAILED` and `NOT_CONFIGURED` both map to `OtpSendFailure`); a one-line doc comment each; `super.code` present when the failure can carry an HTTP status, omitted for device-side validation failures (gstin). The default message is a fallback only; presentation maps the **type** to text.

### P4 — An entity (verbatim, whole file) — `AuthUser`

`lib/features/auth/domain/entities/auth_user.dart`:

```dart
import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    this.fullName,
    this.email,
    required this.roles,
    required this.activeRole,
    required this.userKey,
  });

  final String id;

  /// E.164, e.g. `+919876543210`.
  final String phone;
  final String? fullName;
  final String? email;
  final List<String> roles;
  final String activeRole;

  /// Stable id derived from [phone]; see `phoneToId`.
  final String userKey;

  /// This user with the name and email from their saved profile; a blank
  /// name keeps the current one, a null email clears it.
  AuthUser withProfile({String? fullName, String? email}) {
    final name = fullName?.trim() ?? '';
    return AuthUser(
      id: id,
      phone: phone,
      fullName: name.isEmpty ? this.fullName : name,
      email: email,
      roles: roles,
      activeRole: activeRole,
      userKey: userKey,
    );
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    fullName,
    email,
    roles,
    activeRole,
    userKey,
  ];
}
```

And the derived-getter variant, `lib/features/auth/domain/entities/otp_request.dart`:

```dart
import 'package:equatable/equatable.dart';

/// A request to send a one-time code to an Indian mobile number.
class OtpRequest extends Equatable {
  const OtpRequest({required this.fullName, required this.phoneDigits});

  /// Trimmed; at least 2 characters.
  final String fullName;

  /// Exactly 10 digits, without the country code.
  final String phoneDigits;

  /// The number as the API expects it: `91` followed by the 10 digits.
  String get apiPhone => '91$phoneDigits';

  @override
  List<Object?> get props => [fullName, phoneDigits];
}
```

Rule: `class X extends Equatable`, `const` constructor, every field `final` and in `props` (in declaration order), optional fields nullable or with `const` defaults (`this.items = const []`, `this.status = ''`), derived values as getters, copies as named methods (`withProfile`) or `copyWith`. Pure Dart imports only. Entities may hold private static helpers (`WarehouseOrder._first`).

### P5 — A `<UseCase>Params` class + use case (verbatim, whole file)

`lib/features/orders/domain/usecases/get_my_orders.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/orders_page.dart';
import '../repositories/orders_repository.dart';

class GetMyOrdersParams {
  const GetMyOrdersParams({required this.phone, this.page = 1});

  /// The customer's mobile number; any format, the last ten digits count.
  final String phone;

  /// The page to load, from 1.
  final int page;
}

/// One page of My Orders, from the warehouse.
class GetMyOrders implements UseCase<OrdersPage, GetMyOrdersParams> {
  const GetMyOrders(this._repository);

  final OrdersRepository _repository;

  @override
  Future<Either<Failure, OrdersPage>> call(GetMyOrdersParams params) {
    return _repository.getOrders(phone: params.phone, page: params.page);
  }
}
```

Rule: params class **first** in the same file, named `<UseCaseClass>Params`, `const` constructor, plain class (not Equatable), documented fields; the use case unpacks it into the repository's named parameters. File name is the snake_case of the use case class (`get_my_orders.dart`). Entity-params variant: `SendOtp implements UseCase<Unit, OtpRequest>` forwards the entity itself (`_repository.sendOtp(params)`). `NoParams` variant: `RestoreSession implements UseCase<AuthSession?, NoParams>` with `call(NoParams params) => _repository.restoreSession()`.

### P6 — Cross-feature and composing use cases (verbatim)

`lib/features/orders/domain/usecases/get_order_products.dart` — a use case over **another feature's** repository, doing cached-else-fresh inside:

```dart
class GetOrderProducts implements UseCase<List<CatalogProduct>, NoParams> {
  const GetOrderProducts(this._catalog);

  final CatalogRepository _catalog;

  @override
  Future<Either<Failure, List<CatalogProduct>>> call(NoParams params) async {
    final cached = await _catalog.getCachedCatalog();
    if (cached case Right(value: final snapshot)
        when snapshot.products.isNotEmpty) {
      return Right(snapshot.products);
    }
    final fresh = await _catalog.getCatalog();
    return fresh.map((snapshot) => snapshot.products);
  }
}
```

`lib/features/orders/domain/usecases/buy_again_order.dart` — an entity as params, and another use case constructed inline from the same repository:

```dart
class BuyAgainOrder implements UseCase<BuyAgain, WarehouseOrder> {
  const BuyAgainOrder(this._catalog);

  final CatalogRepository _catalog;

  @override
  Future<Either<Failure, BuyAgain>> call(WarehouseOrder params) async {
    // The same products the order screens show pictures from.
    final products = await GetOrderProducts(_catalog)(const NoParams());
    return products.map((list) => buyAgainFor(params, list));
  }
}
```

Rule: a use case may depend on a repository from another feature (DI resolves it with `sl()`), may compose two repository calls, and may invoke another use case as `OtherUseCase(_repo)(params)`. It never imports data or presentation.

### P7 — The repository contract (verbatim, whole file)

`lib/features/auth/domain/repositories/auth_repository.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/failure.dart';
import '../entities/auth_session.dart';
import '../entities/otp_request.dart';
import '../entities/verify_otp_request.dart';

/// Contract for authentication operations.
///
/// Presentation must depend on this abstraction via use cases, never on the
/// data-layer implementation.
abstract interface class AuthRepository {
  /// Sends a one-time code by SMS for [request].
  Future<Either<Failure, Unit>> sendOtp(OtpRequest request);

  /// Checks the code, then starts and stores a session.
  Future<Either<Failure, AuthSession>> verifyOtp(VerifyOtpRequest request);

  /// Whether a signed-in session is already stored on this device.
  bool get hasActiveSession;

  /// The session stored on this device (refreshing the saved tokens), or
  /// null when signed out.
  Future<Either<Failure, AuthSession?>> restoreSession();

  Future<Either<Failure, Unit>> signOut();
}
```

Rule: `abstract interface class XRepository` in `domain/repositories/x_repository.dart`; every method that can fail returns `Future<Either<Failure, T>>`; `Unit` for no value; a nullable `T?` for "may legitimately be absent" (`AuthSession?`, `WarehouseOrder?`); a cheap, non-failing read may be a sync getter (`bool get hasActiveSession`). Orders uses **named** parameters (`getOrders({required String phone, int page = 1})`); auth passes a request entity. Doc comments name the failures a method can return (`Fails with NetworkFailure or ServerFailure`).

### P8 — The four-conversion model (verbatim, whole file)

`lib/features/auth/data/models/auth_tokens_model.dart`:

```dart
import '../../domain/entities/auth_tokens.dart';

/// Successful verify response:
/// `{ "access_token", "refresh_token", "user_id" }`.
class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
    );
  }

  factory AuthTokensModel.fromEntity(AuthTokens entity) {
    return AuthTokensModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      userId: entity.userId,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user_id': userId,
  };

  AuthTokens toEntity() => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    userId: userId,
  );
}
```

Rule: `class XModel` (plain, not Equatable), `const` ctor, the doc comment quotes the wire shape, `fromJson` is lenient (`as String? ?? ''`, or `json_readers`), order of members: ctor → fields → `fromJson` → `fromEntity` → `toJson` → `toEntity` (gstin puts factories before fields; both orders exist). API keys exactly as the API spells them (`access_token`, `fullName`).

Variants seen:
- **Request model with a constant discriminator** — `OtpRequestModel`: `static const String sendAction = 'send'; static const String _countryCode = '91';`, `fromEntity(entity) => OtpRequestModel(action: sendAction, phone: entity.apiPhone)`, and `toEntity()` strips the country code and returns `fullName: ''` because the name "is not part of the request".
- **Response-only model (no entity)** — `SendOtpResponseModel`: only `fromJson` (`ok: json['ok'] == true`) and `toJson`.
- **SDK-built model** — `AuthSessionModel.fromSupabaseSession(supabase.Session s)` + `toEntity()`; no JSON conversions (never cached). It decodes the JWT payload itself (`_jwtPayload`: `base64Url.decode(base64Url.normalize(parts[1]))`, `FormatException` → `{}`) and derives `userKey: phoneToId(phone)`, `expiresAt: DateTime.fromMillisecondsSinceEpoch(s.expiresAt! * 1000)`.
- **Model with an extra write shape** — `GstinModel.toUpsertJson({required String userKey, required DateTime savedAt})` returns `{'user_key': userKey, 'gstin': gstin, 'state_name': stateName, 'method': checksumMethod, 'updated_at': savedAt.toUtc().toIso8601String()}` and deliberately omits `legal_name`.
- **Lenient nested model** — `StockshipOrderModel.fromJson` uses `asString/asNumeric/asInt/asMap/asMapList`, record fields `({double amount, String? code})`, if-case filtering `if (asString(s['stage_name']) case final name?)`, and `toJson` uses null-aware entries `'_id': ?id` (key omitted when null) next to always-present keys (`'order_id': orderId`). `fromEntity` is lossy by design (`paymentMode: entity.isCashOnDelivery ? 'cod' : 'prepaid'`).
- **Read-only model with business predicates** — `RefOrderModel`: `fromJson`/`toJson`/`toLookup()`/`toEntity()`, no `fromEntity`; `key`, `isCompleted`, `isCashOnDelivery` (regex, case-insensitive), `isLive(DateTime now)`, `isMaliOrder`, with `static const` thresholds (`pendingGrace`, `maliSources`).

### P9 — Edge Function remote data source (verbatim: headers, one method, the envelope helper)

`lib/features/auth/data/datasources/auth_remote_data_source.dart` (imports and class header, `verifyOtp`, `_toServerException`):

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
```

```dart
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

Rule (copy character for character): `final Object? response; try { … } on AppException catch (e) { throw ConnectionException(e.toString()); }` → `if (response is SuccessResponse) { parse rawData; validate; return model; }` → `if (response is ErrorResponse) throw _toServerException(response);` → `throw const ServerException(code: 'INVALID_RESPONSE', status: 0);`. Required-field validation happens **in the data source after `fromJson`**, throwing `ServerException(code: 'UNEXPECTED_RESPONSE', status: int.tryParse(response.statusCode) ?? 200)`. `sendOtp` checks `if (!model.ok)` the same way. One `_toServerException` per data source. Constructor is `const` with named `networking` and the key(s), assigned to private fields in the initializer list.

### P10 — PostgREST remote data source (verbatim, whole class)

`lib/features/gstin/data/datasources/gstin_remote_data_source.dart`:

```dart
class GstinRemoteDataSourceImpl implements GstinRemoteDataSource {
  GstinRemoteDataSourceImpl({
    required Networking networking,
    required String anonKey,
    DateTime Function() now = DateTime.now,
  }) : _networking = networking,
       _anonKey = anonKey,
       _now = now;

  final Networking _networking;
  final String _anonKey;
  final DateTime Function() _now;

  /// PostgREST needs the anon key. The user's token stays as the service's
  /// default bearer.
  Map<String, String> get _restHeaders => {'apikey': _anonKey};

  /// An upsert on `(user_key, gstin)` that answers with no body.
  static const String _upsertHeader =
      'resolution=merge-duplicates,return=minimal';

  /// The columns the GST & Claims page reads.
  static const String listColumns = 'gstin,legal_name,state_name';

  @override
  Future<List<GstinModel>> list(String userKey) async {
    final Object? response;
    try {
      response = await _networking.getAPICall(
        endpoint: Endpoints.gstins,
        queryParameters: {
          'select': listColumns,
          'user_key': 'eq.$userKey',
          'order': 'created_at.desc',
        },
        headers: _restHeaders,
      );
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) {
      final body = response.rawData;
      if (body is! List) {
        throw ServerException(
          code: 'UNEXPECTED_RESPONSE',
          status: int.tryParse(response.statusCode) ?? 200,
        );
      }
      return asMapList(body)
          .map(GstinModel.fromJson)
          .where((gstin) => gstin.gstin.isNotEmpty)
          .toList();
    }
    if (response is ErrorResponse) throw _toServerException(response);
    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  @override
  Future<void> save({
    required String userKey,
    required GstinModel gstin,
  }) async {
    final Object? response;
    try {
      response = await _networking.postAPICall(
        endpoint: Endpoints.gstins,
        queryParameters: const {'on_conflict': 'user_key,gstin'},
        data: gstin.toUpsertJson(userKey: userKey, savedAt: _now()),
        headers: {..._restHeaders, 'Prefer': _upsertHeader},
      );
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) return;
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

Rule: PostgREST headers are **only** `{'apikey': anonKey}` (the user's bearer stays as the default so RLS applies); filters go in `queryParameters` (`'select'`, `'<col>': 'eq.<v>'`, `'order': '<col>.desc'`); an upsert is a POST with `queryParameters: {'on_conflict': '<cols>'}` and `headers: {..._restHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal'}`; a list body must be a `List` or it is `UNEXPECTED_RESPONSE`; the PostgREST envelope helper reads `code`/`message` and takes the status from `response.errorCode`. A clock is injected as `DateTime Function() now = DateTime.now` when the source stamps times.

### P11 — Third-party host data source with a minted bearer (verbatim: the two private helpers)

Mandatory-token variant, `lib/features/orders/data/datasources/stockship_remote_data_source.dart`:

```dart
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
```

Optional-token variant, `lib/features/orders/data/datasources/ref_order_remote_data_source.dart`:

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

Rule: a host that does not speak the Supabase envelope gets **its own exception class** with `(int status, [String? detail])` where `status == 0` means "no answer" (replacing `ConnectionException`), and the repository maps `status == 0` → `NetworkFailure`, else `ServerFailure(errorCode: 'HTTP_${e.status}', code: e.status)`. Pass `host: ApiHost.<x>` and the bearer explicitly on every call (third-party hosts get no default headers). Query values are strings (`'page': '$page'`). 401 → `invalidate()`, `token(refresh: true)`, retry **once**.

### P12 — Per-host exception file (verbatim, whole file)

`lib/features/orders/data/exceptions/orders_exceptions.dart`:

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

Rule: `data/exceptions/<feature>_exceptions.dart` exists **only** for non-Supabase hosts. Supabase-speaking data sources (auth, gstin) throw the core `ServerException`/`ConnectionException` and have no `data/exceptions/` folder.

### P13 — Repository impl: exception → failure mapping (verbatim, one method + its switch)

`lib/features/auth/data/repositories/auth_repository_impl.dart`:

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
```

```dart
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

  Failure _mapVerifyError(ServerException e) {
    switch (e.code) {
      case 'INVALID_OTP':
        return InvalidOtpFailure(code: e.status);
      case 'OTP_EXPIRED':
        return OtpExpiredFailure(code: e.status);
      case 'OTP_NOT_SENT':
        return OtpNotSentFailure(code: e.status);
      case 'OTP_ATTEMPTS_EXCEEDED':
        return OtpAttemptsExceededFailure(code: e.status);
      case 'OTP_VERIFY_FAILED':
      case 'SESSION_FAILED':
      case 'USER_CREATE_FAILED':
        return OtpVerifyFailure(code: e.status);
      default:
        return ServerFailure(errorCode: e.code, code: e.status);
    }
  }
```

The generic fallthrough used when a method has no specific codes (`restoreSession`, `signOut`, `GstinRepositoryImpl.getSavedGstins`):

```dart
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
```

And the third-party variant, `OrdersRepositoryImpl`:

```dart
  Failure _toFailure(StockshipException e) => e.status == 0
      ? NetworkFailure()
      : ServerFailure(errorCode: 'HTTP_${e.status}', code: e.status);
```

```dart
    } on StockshipException catch (e) {
      return Left(_toFailure(e));
    } on KoTokenException {
      return Left(ServerFailure(errorCode: 'NO_KO_TOKEN', code: 401));
    }
```

Rule: `class XRepositoryImpl implements XRepository`; constructor takes data sources as **named required** parameters (`remote:`, `session:`, `local:`, `stockship:`, `refOrders:`) assigned to `_remote` etc.; each method: entity → model (`XModel.fromEntity`), call the data source, model → entity (`.toEntity()`), `return const Right(unit)` / `Right(entity)`; catch `ServerException` → one private `_map<Method>Error(ServerException e)` switch on `e.code` passing `code: e.status`; `default` → `ServerFailure(errorCode: e.code, code: e.status)`; catch `ConnectionException` → `Left(NetworkFailure())`. Nothing above sees exceptions, models or JSON.

### P14 — Repository impl: session side effects and the refresh subscription (verbatim)

```dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthSessionDataSource session,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _session = session,
       _local = local {
    // Keep the stored tokens current as the SDK refreshes the session.
    _refreshSubscription = _session.refreshedSessions.listen(_saveTokensOf);
  }

  final AuthRemoteDataSource _remote;
  final AuthSessionDataSource _session;
  final AuthLocalDataSource _local;
  late final StreamSubscription<AuthSessionModel> _refreshSubscription;

  /// Stops syncing refreshed tokens.
  Future<void> dispose() => _refreshSubscription.cancel();

  Future<void> _saveTokensOf(AuthSessionModel session) {
    return _local.saveTokens(
      AuthTokensModel(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        userId: session.userId,
      ),
    );
  }
```

```dart
  @override
  Future<Either<Failure, AuthSession>> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    try {
      final tokens = await _remote.verifyOtp(
        VerifyOtpRequestModel.fromEntity(request),
      );
      // Save first, so the tokens survive even if setting the session fails.
      await _local.saveTokens(tokens);

      final session = await _session.establish(tokens);
      // The SDK rotates the refresh token when it starts the session.
      await _saveTokensOf(session);

      return Right(session.toEntity());
    } on ServerException catch (e) {
      return Left(_mapVerifyError(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  @override
  bool get hasActiveSession => _session.hasActiveSession;

  @override
  Future<Either<Failure, AuthSession?>> restoreSession() async {
    try {
      final session = await _session.restore();
      if (session == null) return const Right(null);
      // The SDK may have refreshed the tokens while restoring.
      await _saveTokensOf(session);
      return Right(session.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _session.signOut();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } finally {
      await _local.clearTokens();
    }
  }
```

Rule: token saves happen at exactly four moments (verify before and after `establish`, restore, every SDK refresh); `signOut` clears tokens in `finally` so a failed SDK sign-out still clears; the subscription is created in the constructor body and cancelled by `dispose()`, which DI wires with `dispose: (repository) => (repository as AuthRepositoryImpl).dispose()`. The tests assert the **order** (`local.saved.first` is the issued tokens, `local.saved.last` the rotated ones; on `establish` failure `local.saved == [same(_issuedTokens)]`).

### P15 — Repository impl: validate in domain, best-effort write (verbatim, whole class)

`lib/features/gstin/data/repositories/gstin_repository_impl.dart`:

```dart
class GstinRepositoryImpl implements GstinRepository {
  const GstinRepositoryImpl({required GstinRemoteDataSource remote})
    : _remote = remote;

  final GstinRemoteDataSource _remote;

  @override
  Future<Either<Failure, Gstin>> verifyGstin({
    required String userKey,
    required String number,
  }) async {
    final checked = validateGstin(number);
    if (checked case Left(:final value)) return Left(value);

    final gstin = checked.getOrElse((_) => '');
    final verified = Gstin(number: gstin, stateName: gstinStateName(gstin));

    // Best-effort, like the previous app: the number is good whether or
    // not the copy on the server was written.
    try {
      await _remote.save(
        userKey: userKey,
        gstin: GstinModel.fromEntity(verified),
      );
    } on ConnectionException {
      // Not saved; the order still carries the number.
    } on ServerException {
      // Not saved; the order still carries the number.
    }
    return Right(verified);
  }

  @override
  Future<Either<Failure, List<Gstin>>> getSavedGstins(String userKey) async {
    try {
      final saved = await _remote.list(userKey);
      return Right(saved.map((gstin) => gstin.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }
}
```

Rule: a domain validator returning `Either<Failure, String>` runs **before** any request (`if (checked case Left(:final value)) return Left(value);`); a best-effort write swallows both typed exceptions with a comment and still returns `Right`. A repository with no subscriptions is `const`.

### P16 — Repository impl: multi-host, never-throwing helpers, injected clock (verbatim)

`lib/features/orders/data/repositories/orders_repository_impl.dart`:

```dart
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({
    required StockshipRemoteDataSource stockship,
    required RefOrderRemoteDataSource refOrders,
    DateTime Function() now = DateTime.now,
  }) : _stockship = stockship,
       _refOrders = refOrders,
       _now = now;
```

```dart
  @override
  Future<Either<Failure, OrdersPage>> getOrders({
    required String phone,
    int page = 1,
  }) async {
    final digits = _tenDigits(phone);
    if (digits == null) {
      return Right(OrdersPage(orders: const [], page: page, hasMore: false));
    }
    // The orders not in the warehouse yet are by definition the newest,
    // so they ride on the first page only; neither source hides the other.
    final pending = page == 1
        ? _pendingOrders(digits)
        : Future.value(const <WarehouseOrder>[]);
    try {
      final result = await _stockship.listOrderPage(phone: digits, page: page);
      final orders =
          [
            for (final order in result.orders) order.toEntity(),
            ...await pending,
          ]..sort((a, b) {
            final at = a.placedAt?.millisecondsSinceEpoch ?? 0;
            final bt = b.placedAt?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
      // Without a page count, a full page means another may follow.
      final pages =
          result.pages ??
          (result.orders.length < StockshipRemoteDataSource.pageSize
              ? result.page
              : result.page + 1);
      return Right(
        OrdersPage(
          orders: orders,
          page: result.page,
          hasMore: result.orders.isNotEmpty && result.page < pages,
        ),
      );
    } on StockshipException catch (e) {
      return Left(_toFailure(e));
    } on KoTokenException {
      return Left(ServerFailure(errorCode: 'NO_KO_TOKEN', code: 401));
    }
  }
```

```dart
  /// The customer's orders KO registered that the warehouse does not have
  /// yet: this app's, not completed (a completed one has a warehouse
  /// number and is listed by StockShip already), and live. Never throws:
  /// this list is an addition to My Orders.
  Future<List<WarehouseOrder>> _pendingOrders(String digits) async {
    try {
      final rows = await _refOrders.listByPhone(tenDigitPhone: digits);
      final now = _now();
      return [
        for (final row in rows)
          if (row.isMaliOrder &&
              !row.isCompleted &&
              row.isLive(now) &&
              row.key.isNotEmpty)
            row.toEntity(),
      ];
    } on RefOrdersException catch (e) {
      log('[orders] ref-orders list failed: $e');
      return const [];
    }
  }

  /// The last ten digits of [phone], or null when it has fewer.
  static String? _tenDigits(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 ? null : digits.substring(digits.length - 10);
  }
```

Rule: the repository (not the use case or bloc) picks hosts and composes them; an auxiliary source is wrapped in a private `Future<…>` helper that **never throws** (logs `'[<feature>] …'` with `dart:developer`'s `log` and returns an empty value); input guards (`_tenDigits == null`, `orderId.trim().isEmpty`) return `Right(null)`/an empty page **before** any network call; a clock is `DateTime Function() now = DateTime.now`; the private domain-util call (`orderPlacedAfter`) and the normalisation (`_tenDigits`) are the repository's job.

### P17 — Local data source over `SecureStorage` (verbatim, whole class)

`lib/features/auth/data/datasources/auth_local_data_source.dart`:

```dart
abstract interface class AuthLocalDataSource {
  Future<void> saveTokens(AuthTokensModel tokens);

  Future<AuthTokensModel?> readTokens();

  /// Clears the tokens, and the cached copies of the signed-in user's
  /// data along with them. Called on sign-out.
  Future<void> clearTokens();
}

/// Keeps the tokens in [SecureStorage]. Earlier builds kept them in
/// SharedPreferences under the same keys: [readTokens] moves such a copy
/// over, and every save or clear removes it.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache);

  /// Shared with `NetworkingService`, which sends this token by default.
  static const String accessTokenKey = StringConstants.appAuthToken;
  static const String refreshTokenKey = 'auth.refresh_token';
  static const String userIdKey = 'auth.user_id';

  static const List<String> _keys = [
    accessTokenKey,
    refreshTokenKey,
    userIdKey,
  ];

  final SecureStorage _secure;
  final PrefUtils _prefs;
  final LocalCache _cache;

  @override
  Future<void> saveTokens(AuthTokensModel tokens) async {
    await _secure.write(accessTokenKey, tokens.accessToken);
    await _secure.write(refreshTokenKey, tokens.refreshToken);
    await _secure.write(userIdKey, tokens.userId);
    await _removeLegacyCopy();
  }

  @override
  Future<AuthTokensModel?> readTokens() async {
    final tokens = _tokensFrom(
      accessToken: await _secure.read(accessTokenKey),
      refreshToken: await _secure.read(refreshTokenKey),
      userId: await _secure.read(userIdKey),
    );
    if (tokens != null) return tokens;

    await _prefs.init();
    final legacy = _tokensFrom(
      accessToken: _prefs.getString(key: accessTokenKey),
      refreshToken: _prefs.getString(key: refreshTokenKey),
      userId: _prefs.getString(key: userIdKey),
    );
    if (legacy != null) await saveTokens(legacy);
    return legacy;
  }

  @override
  Future<void> clearTokens() async {
    for (final key in _keys) {
      await _secure.delete(key);
    }
    await _removeLegacyCopy();
    try {
      await _cache.clearUserScoped();
    } on CacheException {
      // The tokens are gone, so sign-out still succeeds.
    }
  }

  static AuthTokensModel? _tokensFrom({
    required String? accessToken,
    required String? refreshToken,
    required String? userId,
  }) {
    if (accessToken == null || refreshToken == null || userId == null) {
      return null;
    }
    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Future<void> _removeLegacyCopy() async {
    await _prefs.init();
    for (final key in _keys) {
      await _prefs.remove(key: key);
    }
  }
}
```

Rule: keys are `static const String` on the Impl; reads return a model or `null` (all three present or nothing); `clearTokens` also calls `LocalCache.clearUserScoped()` and swallows `CacheException`. The legacy-prefs migration (`_removeLegacyCopy`, the prefs fallback in `readTokens`, the `PrefUtils` dependency) is MyMali upgrade history; a fresh app can drop it (then the ctor is `AuthLocalDataSourceImpl(this._secure, this._cache)`).

### P18 — SDK-only data source wrapping SDK exceptions (verbatim, one method)

`lib/features/auth/data/datasources/auth_session_data_source.dart`:

```dart
  @override
  Future<AuthSessionModel> establish(AuthTokensModel tokens) async {
    final supabase.AuthResponse response;
    try {
      response = await _client.auth.setSession(tokens.refreshToken);
    } on supabase.AuthException catch (e) {
      throw ServerException(
        code: 'SESSION_FAILED',
        status: 0,
        detail: e.message,
      );
    }

    final session = response.session;
    if (session == null) {
      throw const ServerException(code: 'SESSION_FAILED', status: 0);
    }
    return AuthSessionModel.fromSupabaseSession(session);
  }
```

```dart
  @override
  Stream<AuthSessionModel> get refreshedSessions => _client
      .auth
      .onAuthStateChange
      .where(
        (state) =>
            state.event == supabase.AuthChangeEvent.tokenRefreshed &&
            state.session != null,
      )
      .map((state) => AuthSessionModel.fromSupabaseSession(state.session!));
```

Rule: the SDK is imported `as supabase`; SDK exceptions become `ServerException(code: '<APP_MADE_CODE>', status: 0, detail: e.message)` with app-made codes (`SESSION_FAILED`, `SIGN_OUT_FAILED`) that the repository maps like server codes; `establish` uses `setSession(refreshToken)`, never `signInWithOtp`/`verifyOTP`.

### P19 — Domain utils (verbatim examples)

Either-returning validator, `lib/features/gstin/domain/utils/gstin_validation.dart`:

```dart
/// The normalised GSTIN, or why [input] is not one.
Either<Failure, String> validateGstin(String input) {
  final gstin = normalizeGstin(input);
  if (gstin.isEmpty) return Left(GstinEmptyFailure());
  if (!_shape.hasMatch(gstin) || gstinStateName(gstin) == null) {
    return Left(InvalidGstinFailure());
  }
  if (gstinCheckCharacter(gstin) != gstin[gstinLength - 1]) {
    return Left(GstinChecksumFailure());
  }
  return Right(gstin);
}
```

Enum with switch getters and a keyword mapper, `lib/features/orders/domain/utils/order_status.dart`:

```dart
  /// The step of [journeyStageCount] the order has reached, from 0
  /// (confirmed) to 4 (delivered); -1 for [pseudo]. Closed orders read 0,
  /// as in the delivery app; check [hasJourney] first.
  int get journeyIndex => switch (this) {
    pseudo => -1,
    created || cancelled || rtoReceived || rtoInTransit || rtoDelivered => 0,
    packed => 1,
    dispatched || inTransit => 2,
    outForDelivery => 3,
    delivered => 4,
  };
```

```dart
OrderStatus orderStatusOf(String raw) {
  final word = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  final known = _known[word];
  if (known != null) return known;
  if (word.isEmpty) return OrderStatus.created;

  bool has(String pattern) => RegExp(pattern).hasMatch(word);
  if (has('rto|return')) {
    if (has('deliver')) return OrderStatus.rtoDelivered;
    if (has('transit|dispatch|ship')) return OrderStatus.rtoInTransit;
    return OrderStatus.rtoReceived;
  }
  if (has('fail|reject|declin')) return OrderStatus.created;
  if (has('cancel')) return OrderStatus.cancelled;
  if (has('out.?for|ofd')) return OrderStatus.outForDelivery;
  if (has('deliver')) {
    return word.contains('out')
        ? OrderStatus.outForDelivery
        : OrderStatus.delivered;
  }
  if (has('transit')) return OrderStatus.inTransit;
  if (has('dispatch|ship')) return OrderStatus.dispatched;
  if (has('pack|ready|pick')) return OrderStatus.packed;
  if (has('pending|unpaid|initiat|pseudo')) return OrderStatus.pseudo;
  return OrderStatus.created;
}
```

Regex predicate, `lib/features/orders/domain/utils/ref_order_id.dart` (whole file):

```dart
/// Whether [id] names an order KO registered but the warehouse may not
/// hold yet (a ref-order), rather than a warehouse order. An order paid
/// online is referenced by its Razorpay order id (`order_…`); the
/// previous app's own references were `MYM-…` / `MYMALI-…`. Warehouse
/// numbers (`KMM-10345`) match none of these.
bool isRefOrderId(String id) =>
    RegExp(r'^order_').hasMatch(id) || RegExp(r'^MYM(ALI)?-').hasMatch(id);
```

Phone-derived key, `lib/features/auth/domain/utils/phone_to_id.dart` (whole file):

```dart
/// Derives a UUID-shaped key from a phone number: its digits, right-padded
/// with `0` to 32 characters, grouped 8-4-4-4-12.
///
/// `+919876543210` → `91987654-3210-0000-0000-000000000000`.
String phoneToId(String phone) {
  final digits = phone
      .replaceAll(RegExp(r'\D'), '')
      .padRight(32, '0')
      .substring(0, 32);
  return [
    digits.substring(0, 8),
    digits.substring(8, 12),
    digits.substring(12, 16),
    digits.substring(16, 20),
    digits.substring(20, 32),
  ].join('-');
}
```

Rule: `domain/utils/<concept>.dart` holds top-level pure functions and `const`s (no classes unless an enum); file-private tables are `_known`, `_shape`, `_alphabet`; a validator returns `Either<Failure, String>`; thresholds are top-level `const Duration`s (`warehouseClockSkew`). Imports: only `fpdart`, `core/app/failure.dart`, the feature's own domain and other features' domain.

### P20 — DI registration for the three features (verbatim)

`lib/core/di/injection_container.dart`:

```dart
void _registerAuthData() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<AuthSessionDataSource>(
      () => AuthSessionDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl(), sl(), sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl(), session: sl(), local: sl()),
      dispose: (repository) => (repository as AuthRepositoryImpl).dispose(),
    );
}

/// Auth use cases and blocs. They depend only on [AuthRepository], so tests
/// can register a fake repository and then call this.
void registerAuthFeature() {
  sl
    // Use cases
    ..registerLazySingleton(() => SendOtp(sl()))
    ..registerLazySingleton(() => VerifyOtp(sl()))
    ..registerLazySingleton(() => RestoreSession(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    // Blocs: a new instance each time one is provided.
    ..registerFactory(
      () => AuthBloc(restoreSession: sl(), signOut: sl(), analytics: sl()),
    )
    ..registerFactory(
      () => LoginBloc(sendOtp: sl(), verifyOtp: sl(), analytics: sl()),
    );
}
```

```dart
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
    ..registerLazySingleton<OrdersRepository>(
      () => OrdersRepositoryImpl(stockship: sl(), refOrders: sl()),
    );
}

/// The warehouse-order use cases and the My Orders / Order Details blocs.
/// They depend only on [OrdersRepository] and [CatalogRepository] (for
/// pictures and "Buy Again"), so tests can register fakes of both and then
/// call this.
void registerOrdersFeature() {
  sl
    ..registerLazySingleton(() => GetWarehouseOrder(sl()))
    ..registerLazySingleton(() => FindOrderPlacedAfter(sl()))
    ..registerLazySingleton(() => GetRefOrder(sl()))
    ..registerLazySingleton(() => GetMyOrders(sl()))
    ..registerLazySingleton(() => GetOrderProducts(sl()))
    ..registerLazySingleton(() => BuyAgainOrder(sl()))
    ..registerFactory(
      () => MyOrdersBloc(
        getMyOrders: sl(),
        getOrderProducts: sl(),
        buyAgainOrder: sl(),
      ),
    )
    ..registerFactory(
      () => OrderDetailsBloc(
        getWarehouseOrder: sl(),
        getOrderProducts: sl(),
        buyAgainOrder: sl(),
      ),
    );
}
```

```dart
void _registerGstinData() {
  sl
    ..registerLazySingleton<GstinRemoteDataSource>(
      () => GstinRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<GstinRepository>(
      () => GstinRepositoryImpl(remote: sl()),
    );
}

/// The GSTIN use case and the Add GSTIN sheet's bloc. They depend only on
/// [GstinRepository], so tests can register a fake repository and then
/// call this.
void registerGstinFeature() {
  sl
    ..registerLazySingleton(() => VerifyGstin(sl()))
    ..registerLazySingleton(() => GetSavedGstins(sl()))
    ..registerFactory(() => GstinSheetBloc(verifyGstin: sl()))
    ..registerFactory(() => GstClaimsBloc(getSavedGstins: sl()));
}
```

Rule: two functions per feature — private `_register<Feature>Data()` (data sources and the repository, by abstract type, `Env.*` read **here**) and public `register<Feature>Feature()` (use cases as `registerLazySingleton(() => UseCase(sl()))`, blocs as `registerFactory`). `configureDependencies()` calls them in pairs in dependency order (`_registerCore(); _registerAuthData(); registerAuthFeature(); …`). A repository with `dispose()` passes `dispose:` to `registerLazySingleton`.

### P21 — Test shapes (verbatim)

Model round-trip, `test/features/auth/data/models/auth_tokens_model_test.dart`:

```dart
void main() {
  const json = {
    'access_token': 'eyJ.access',
    'refresh_token': 'v1.refresh',
    'user_id': 'b3c1f0f2-uuid',
  };

  test('parses the verify response', () {
    final model = AuthTokensModel.fromJson(json);

    expect(
      model.toEntity(),
      const AuthTokens(
        accessToken: 'eyJ.access',
        refreshToken: 'v1.refresh',
        userId: 'b3c1f0f2-uuid',
      ),
    );
  });

  test('round-trips json -> entity -> json', () {
    final roundTripped = AuthTokensModel.fromEntity(
      AuthTokensModel.fromJson(json).toEntity(),
    ).toJson();

    expect(roundTripped, json);
  });
```

The same in gstin's wording: `test('round-trips fromJson → toEntity → fromEntity → toJson', () { final entity = GstinModel.fromJson(json).toEntity(); expect(GstinModel.fromEntity(entity).toJson(), json); });`

Data source test against `FakeNetworking` (gstin):

```dart
  setUp(() {
    networking = FakeNetworking();
    dataSource = GstinRemoteDataSourceImpl(
      networking: networking,
      anonKey: 'anon',
      now: () => DateTime.utc(2026, 10, 7, 11),
    );
  });

  test('upserts on (user_key, gstin) with the anon key', () async {
    networking.response = okResponse(null);

    await dataSource.save(userKey: 'key-1', gstin: gstin);

    final call = networking.lastCall;
    expect(call.method, 'POST');
    expect(call.endpoint, Endpoints.gstins);
    expect(call.queryParameters, {'on_conflict': 'user_key,gstin'});
    expect(call.headers, {
      'apikey': 'anon',
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    });
    expect(call.data, {
      'user_key': 'key-1',
      'gstin': '27AAPFU0939F1ZV',
      'state_name': 'Maharashtra',
      'method': 'checksum',
      'updated_at': '2026-10-07T11:00:00.000Z',
    });
  });

  test('a server error is a ServerException with its code', () async {
    networking.response = errorResponse(const {
      'code': '42501',
      'message': 'permission denied',
    }, '403');

    expect(
      () => dataSource.save(userKey: 'key-1', gstin: gstin),
      throwsA(
        isA<ServerException>()
            .having((e) => e.code, 'code', '42501')
            .having((e) => e.status, 'status', 403),
      ),
    );
  });

  test('no response is a ConnectionException', () async {
    networking.error = app.AppException('offline', 'Timeout');

    expect(
      () => dataSource.save(userKey: 'key-1', gstin: gstin),
      throwsA(isA<ConnectionException>()),
    );
  });
```

Repository test with inline fakes of the data sources (auth):

```dart
class _FakeRemote implements AuthRemoteDataSource {
  Object? sendError;
  Object? verifyError;
  OtpRequestModel? lastSend;
  VerifyOtpRequestModel? lastVerify;

  @override
  Future<SendOtpResponseModel> sendOtp(OtpRequestModel request) async {
    lastSend = request;
    if (sendError != null) throw sendError!;
    return const SendOtpResponseModel(ok: true);
  }

  @override
  Future<AuthTokensModel> verifyOtp(VerifyOtpRequestModel request) async {
    lastVerify = request;
    if (verifyError != null) throw verifyError!;
    return _issuedTokens;
  }
}
```

```dart
    test('maps each error code to its failure', () async {
      final expected = <String, Matcher>{
        'INVALID_OTP': isA<InvalidOtpFailure>(),
        'OTP_EXPIRED': isA<OtpExpiredFailure>(),
        'OTP_NOT_SENT': isA<OtpNotSentFailure>(),
        'OTP_ATTEMPTS_EXCEEDED': isA<OtpAttemptsExceededFailure>(),
        'OTP_VERIFY_FAILED': isA<OtpVerifyFailure>(),
        'USER_CREATE_FAILED': isA<OtpVerifyFailure>(),
        'SESSION_FAILED': isA<OtpVerifyFailure>(),
        'INVALID_BODY': isA<ServerFailure>(),
      };

      for (final MapEntry(key: code, value: matcher) in expected.entries) {
        remote.verifyError = ServerException(code: code, status: 401);
        final result = await repository.verifyOtp(request);
        expect(result.getLeft().toNullable(), matcher, reason: code);
      }
    });
```

Use case test over the shared fake repository, `test/features/auth/domain/usecases/send_otp_test.dart`:

```dart
  test('forwards the request and returns the repository result', () async {
    final repository = FakeAuthRepository();

    final result = await SendOtp(repository)(request);

    expect(result, const Right<dynamic, Unit>(unit));
    expect(repository.sentOtps, [request]);
  });

  test('returns the repository failure', () async {
    final failure = NetworkFailure();
    final repository = FakeAuthRepository()..sendOtpFailure = failure;

    final result = await SendOtp(repository)(request);

    expect(result.getLeft().toNullable(), same(failure));
  });
```

Rule: `Either` results are read with `result.getLeft().toNullable()` / `result.getRight().toNullable()` / `result.toNullable()`; failures with `isA<…>()` or `same(failure)`; `Right(unit)` compared as `const Right<dynamic, Unit>(unit)`; successes with entity equality. Inline fakes `_FakeX implements XDataSource` hold `Object? error` + recorded `last…`/`calls`; shared fakes live in `test/helpers/fake_<thing>.dart` as `Fake<Thing>` with `Failure? xFailure`, `Completer<void>? gate`, and recorded calls. Tests import the app with `package:mymali/...` (lib code uses relative imports).

---

## 4. Rules observed in code (not stated in AGENTS.md, or stated differently)

1. **Two `ServerException` classes.** `core/app/exceptions/api_exceptions.dart` (typed: `code`, `status`, `detail`) is the data layer's; `core/app/exceptions/app_exceptions.dart` has a legacy `ServerException extends AppException`. Every data source therefore writes `import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;`. AGENTS.md never mentions the clash.
2. **No `data/exceptions/` for Supabase features.** AGENTS §5 says data sources "throw a typed exception from `data/exceptions/`"; auth and gstin have no such folder and throw the core `ServerException`/`ConnectionException` (as AGENTS §6's own pattern does). Only orders has `data/exceptions/orders_exceptions.dart`, for hosts with another error envelope.
3. **Two "no answer" conventions.** Supabase sources: `on AppException catch (e) { throw ConnectionException(e.toString()); }` → repo `Left(NetworkFailure())`. Third-party sources: `throw StockshipException(0, e.toString())` → repo `e.status == 0 ? NetworkFailure() : ServerFailure(errorCode: 'HTTP_${e.status}', code: e.status)`.
4. **Required-field validation is in the data source, not the model.** AGENTS §6 says "validate required fields; throw `ServerException('UNEXPECTED_RESPONSE')`" as a pseudo-call. Actual: models are lenient; the data source checks after `fromJson` and throws `ServerException(code: 'UNEXPECTED_RESPONSE', status: int.tryParse(response.statusCode) ?? 200)`; a bad body *shape* (not a `List`) is the same code. Fallthrough is `throw const ServerException(code: 'INVALID_RESPONSE', status: 0);`.
5. **Not every model has four conversions.** AGENTS §5: "Every model/entity pair ships with all four conversions". Code: `SendOtpResponseModel` (fromJson/toJson only, no entity), `AuthSessionModel` (fromSupabaseSession/toEntity only), `RefOrderModel` (no fromEntity; `toLookup()` + `toEntity()` to two different entities), `StockshipOrderPageModel` (fromJson with `requestedPage`, toJson; the repository builds `OrdersPage`). Rule as practised: four conversions when the model is both read and written for an entity; otherwise only the conversions that have a caller.
6. **Round-trip tests vary with the model.** `fromJson → toEntity → fromEntity → toJson == json` (AuthTokensModel, GstinModel, StockshipOrderModel with canonical doubles); `fromJson → toJson == json` for read-only `RefOrderModel`; `fromJson(json).toJson() == json` for `SendOtpResponseModel`; `OtpRequestModel`'s round trip passes only because `fullName` is not on the wire.
7. **A failure's `super.code` is optional.** AGENTS §4 shows `{super.message = …, super.code}`; `GstinEmptyFailure`, `InvalidGstinFailure`, `GstinChecksumFailure` and `CacheMissFailure` omit `super.code` because they never come from HTTP.
8. **`Failure` is not Equatable and not const.** `NetworkFailure()` cannot be `const`; `const Right(unit)` can. Tests use `isA<…>()`.
9. **A repository may expose a sync non-`Either` getter** (`bool get hasActiveSession`) when the read cannot fail. AGENTS §4 only says "every method that can fail returns Either".
10. **Use cases may depend on other features' repositories and call other use cases.** `GetOrderProducts(CatalogRepository)`, `BuyAgainOrder(CatalogRepository)` with `GetOrderProducts(_catalog)(const NoParams())`. `GetOrderProducts` also does cached-else-fresh inside one use case, which AGENTS §20 otherwise assigns to the bloc via two use cases.
11. **Constructor conventions.** Data source Impl: `const`, named `{required Networking networking, required String anonKey}` (+ `required KoTokenService tokens`, `required String mktpId`, `DateTime Function() now = DateTime.now`) assigned to `_networking`, `_anonKey`, …; single-dependency sources use positional (`AuthSessionDataSourceImpl(this._client)`, `AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache)`). Repository Impl: named `{required XDataSource remote, …}` → `_remote`; `const` when it has no subscription.
12. **Header getters are per API, not per host.** Edge Functions: `_supabaseHeaders => {'apikey': _anonKey, 'Authorization': 'Bearer $_anonKey'}` (replaces the default user bearer). PostgREST: `_restHeaders => {'apikey': _anonKey}` (keeps the default user bearer). AGENTS §6 shows only the first; §18 shows both under different names (`_edgeFunctionHeaders`, `_restHeaders`) — the auth file uses `_supabaseHeaders`.
13. **The `Prefer` header and `on_conflict` carry the upsert**; `return=minimal` means a `SuccessResponse` with `rawData == null`, and `save` returns `void` on any `SuccessResponse`.
14. **`StockshipRemoteDataSource.pageSize`** is a `static const` on the *abstract interface class*, referenced from the Impl's default parameter as `StockshipRemoteDataSource.pageSize`.
15. **Mandatory vs optional minted token.** StockShip: `if (token == null) throw const KoTokenException();` → repo `ServerFailure(errorCode: 'NO_KO_TOKEN', code: 401)`. Ref-orders: header `{if (token != null) 'Authorization': 'Bearer $token'}`, retry only `if (token != null && … == '401')`. AGENTS §18 describes the behaviour but names neither `KoTokenException` nor `NO_KO_TOKEN`.
16. **404 is "none" only where the API means it** (StockShip `_get` returns `null` on `'404'`; ref-orders does not special-case 404).
17. **Repositories log with `dart:developer`'s `log('[<feature>] …')`** (`[orders]`, `[ko-token]`) inside never-throwing helpers; AGENTS mentions the bracket prefix only for checkout/firebase/kc.
18. **Injected clocks** `DateTime Function() now = DateTime.now` appear on `OrdersRepositoryImpl` and `GstinRemoteDataSourceImpl`, not only on `HiveLocalCache` as AGENTS §20 says.
19. **Entities with many optional fields default to `''`, `0`, `const []`, `false`** (`WarehouseOrder`, `OrderParty`) so a `const WarehouseOrder(id: 'KMM-1')` is a valid test fixture; `OrderParty()` with all defaults is the "no party" sentinel (`party != const OrderParty()`).
20. **Dart 3.x syntax is assumed**: null-aware map entries `'_id': ?id` and `for … ?asString(…)`, records, `if-case` with guards (`if (cached case Right(value: final snapshot) when …)`, `if (error case final error?) throw error;`), switch expressions. Requires SDK `^3.13.4`.
21. **`Endpoints` base URLs are `static String` (read `Env` lazily); paths are `static const String`** grouped by feature with comments; non-Supabase hosts get their own class (`KoUtilsEndpoints`, `StockshipEndpoints`).
22. **`.env.example` carries keys with no `Env` getter** (`PINCODE_HOST`, `GST_HOST`), against AGENTS §8's "every configuration value comes through a typed getter".
23. **`AuthLocalDataSourceImpl.accessTokenKey` is `StringConstants.appAuthToken`** — the key is shared with `NetworkingService._getOptions`, which reads it from `SecureStorage` on every Supabase call. AGENTS §7 lists the key but not the shared constant.
24. **`AuthSessionModel` derives three things the SDK does not give directly:** `phone` from `user.phone` → `userMetadata['phone']` → synthetic email `^p(\d{10,15})@phone\.mymali\.app$` (→ `'+$digits'`); `roles` from JWT claim `user_roles` (default `['CUSTOMER']`); `email` nulled when it ends with `@phone.mymali.app`.
25. **The orders repository starts the auxiliary fetch before awaiting the main one** (`final pending = page == 1 ? _pendingOrders(digits) : Future.value(const <WarehouseOrder>[]);` then `...await pending`), so the two hosts run in parallel, and sorts the merged list newest first in the repository.
26. **File naming by host, not feature, when a feature has several remote hosts:** `stockship_remote_data_source.dart`, `ref_order_remote_data_source.dart` (and `StockshipException`, `RefOrdersException`), while the repository stays `orders_repository_impl.dart`.
27. **`api_response.dart` is listed as legacy in AGENTS §16 but is the type every data source matches on**; a new app must reproduce `SuccessResponse`/`ErrorResponse` with `rawData`, `statusCode: String`, `errorCode: String`.

---

## 5. Packages

| Package | Files in this area that import it | ALWAYS / CONDITIONAL |
|---|---|---|
| `equatable` (^2.0.7) | `core/usecases/usecase.dart` (NoParams), `core/app/api/api_response.dart`, every entity in `auth/domain/entities`, `orders/domain/entities`, `gstin/domain/entities`, cross-feature entities (`cart_item`, `catalog_product`, `product_variant`, `catalog_snapshot`, `invoice`) | ALWAYS |
| `fpdart` (^1.1.1) | `core/usecases/usecase.dart`, every `domain/repositories/*.dart`, every `domain/usecases/*.dart`, every `data/repositories/*_impl.dart`, `gstin/domain/utils/gstin_validation.dart`; tests use `Right`, `unit`, `getLeft().toNullable()`, `right(...)` | ALWAYS |
| `supabase_flutter` (^2.17.2) | `auth/data/datasources/auth_session_data_source.dart`, `auth/data/models/auth_session_model.dart` (both `as supabase`), `core/di/injection_container.dart` (`SupabaseClient`, `Supabase.instance.client`), `test/.../auth_session_model_test.dart` | CONDITIONAL(app uses Supabase Auth for the session) |
| `dio` (^5.11.1) | `core/services/networking/networking.dart`, `core/repositories/base_api_repository.dart` (not imported by any file in auth/orders/gstin) | ALWAYS (behind `Networking`) |
| `get_it` (^8.0.3) | `core/di/injection_container.dart` | ALWAYS |
| `flutter_dotenv` (^6.0.1) | `core/config/env.dart` | ALWAYS |
| `shared_preferences` (^2.0.5) | `core/services/pref_utils.dart`; `test/.../auth_local_data_source_test.dart` (`SharedPreferences.setMockInitialValues`) | ALWAYS for `PrefUtils`; the auth local source needs it only for the legacy migration |
| `flutter` (`package:flutter/foundation.dart`) | `core/services/networking/networking.dart` (`kDebugMode`), `core/config/env.dart` (`kDebugMode`, `visibleForTesting`), `core/di/injection_container.dart` | ALWAYS |
| `flutter_test` | every test | ALWAYS |
| `flutter_secure_storage` (^11.2.0) | **not** imported in this area (only `DeviceSecureStorage`, another area); `SecureStorage` interface is pure Dart | CONDITIONAL(app stores tokens) |
| `hive_ce`, `hive_ce_flutter` | **not** imported in this area; `LocalCache`/`CacheBoxes` are pure Dart | CONDITIONAL(app caches server data) |
| Dart SDK libs | `dart:convert` (`auth_session_model.dart` JWT decode, `api_response.dart`, `networking.dart`, `fake_local_cache.dart`), `dart:developer` `log` (`orders_repository_impl.dart`, `ko_token_service.dart`, `api_response.dart`, `networking.dart`, `pref_utils.dart`), `dart:async` (`auth_repository_impl.dart` `StreamSubscription`, fakes `Completer`), `dart:io` (`networking.dart` `HttpStatus`, `SocketException`) | ALWAYS (SDK) |

No `mockito`/`mocktail`/`bloc_test` anywhere; `crypto`, `razorpay_flutter`, `katyayani_core` etc. are outside this area.

---

## 6. What varies per app (exact substitutions)

| Thing | Where it appears |
|---|---|
| Package name `mymali` | `package:mymali/...` imports in every test and in `networking.dart`, `endpoints.dart`, `base_api_repository.dart` (lib feature code uses relative imports) |
| `.env` keys read by `Env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MEDUSA_URL`, `MEDUSA_PUBLISHABLE_KEY`, `APP_WEB_ORIGIN`, `KO_ENV` (`production`/`beta`), `UTILS_URL_PROD`/`UTILS_URL_BETA`, `STOCKSHIP_URL_PROD`/`STOCKSHIP_URL_BETA`, `RAZORPAY_KEY_ID_PROD`/`RAZORPAY_KEY_ID_BETA`, `RAZORPAY_MODE`, `RAZORPAY_TEST_KEY_ID`, `MKTP_ID`, `KC_SITE_ID`, `KC_API_URL`, `FB_APP_ID`, `FB_CLIENT_TOKEN`, `APP_VERSION` — `lib/core/config/env.dart`; `.env.example` additionally lists `PINCODE_HOST`, `GST_HOST` (no getter) |
| `Env` getters used by this area's DI | `Env.supabaseAnonKey` (auth, gstin data sources), `Env.mktpId` (StockShip), `Env.koEnv` (KoTokenService) — `injection_container.dart` |
| `ApiHost` values | `supabase, medusa, koUtils, stockship` — `networking.dart`; one `Dio` each in `base_api_repository.dart` (`dioSupabse`, `dioMedusa`, `dioKoUtils`, `dioStockship`); `_thirdPartyHosts = {medusa, koUtils, stockship}` |
| Endpoint paths | `Endpoints.phoneLogin = '/functions/v1/phone-login'`, `Endpoints.gstins = '/rest/v1/mali_gstins'`, `Endpoints.kotechToken = '/functions/v1/kotech-token'`, `KoUtilsEndpoints.refOrders = '/order/ref-orders'`, `StockshipEndpoints.orders = '/api/orders'` |
| Edge Function wire shape | `{action: 'send' \| 'verify', phone: '91XXXXXXXXXX', otp, fullName}` → `{ok: true}` / `{access_token, refresh_token, user_id}`; error envelope `{code, status, title, detail}` — `otp_request_model.dart`, `verify_otp_request_model.dart`, `send_otp_response_model.dart`, `auth_tokens_model.dart`, `auth_remote_data_source.dart` |
| Edge Function error codes mapped | `INVALID_PHONE`, `OTP_SEND_FAILED`, `NOT_CONFIGURED`, `INVALID_OTP`, `OTP_EXPIRED`, `OTP_NOT_SENT`, `OTP_ATTEMPTS_EXCEEDED`, `OTP_VERIFY_FAILED`, `USER_CREATE_FAILED` — `auth_repository_impl.dart` |
| App-made exception codes | `UNEXPECTED_RESPONSE`, `INVALID_RESPONSE`, `UNKNOWN`, `SESSION_FAILED`, `SIGN_OUT_FAILED`, `NO_KO_TOKEN`, `HTTP_<status>` — data sources and repositories |
| Secure-storage keys | `auth.access_token` (`StringConstants.appAuthToken`), `auth.refresh_token`, `auth.user_id` — `auth_local_data_source.dart`, `string_constants.dart` |
| Country code and phone formats | `'91'` (`OtpRequest.apiPhone`, `OtpRequestModel._countryCode`, `VerifyOtpRequestModel._countryCode`, `normalizeIndianMobile`); `'+91$tenDigitPhone'` (ref-orders `user_phone`); bare 10 digits (StockShip `phone`, `_tenDigits`) |
| Session model constants | `AuthSessionModel.defaultRole = 'CUSTOMER'`, `_syntheticEmailDomain = '@phone.mymali.app'`, regex `^p(\d{10,15})@phone\.mymali\.app$`, JWT claims `user_roles`, `active_role`, metadata `full_name`, `phone` |
| `userKey` derivation | `phoneToId(phone)` → `91987654-3210-0000-0000-000000000000` shape; used as `mali_gstins.user_key` |
| PostgREST table and columns | `mali_gstins`: `user_key`, `gstin`, `state_name`, `legal_name`, `method` (`'checksum'`), `updated_at`, `created_at`; `listColumns = 'gstin,legal_name,state_name'`; `on_conflict = 'user_key,gstin'`; `Prefer: resolution=merge-duplicates,return=minimal` |
| Third-party query parameters | StockShip: `phone`, `mktp_id`, `page`, `limit` (`'20'`), `order_id`; KO ref-orders: `user_phone`, `ref_id` |
| Third-party JSON keys | StockShip order: `_id, order_id, order_status, payment_mode, total_amount, cod_amount, prepaid_amount, coin, date, created_at, updated_at, customer, billing_address, shipping_address, items[sku,name,qty,unit_price,total_price,hero_image,images,variant], failure_message, discounts[discount_amount,discount_code], order_status_map[stage_name,timestamp]`, page `data.orders/page/pages`; KO row: `_id, ref_id, razorpay_order_id, order_id, order_status, payment_id, payment_mode, order_source, user_phone, createdAt, updatedAt, order_data.order{items[sku,qty,amount], total_amt, coin, prepaid_amount, cod_amount, discount_amount, discount_code, shipping_addr, billing_addr, customer{customer_gstin}}` |
| Business constants | `StockshipRemoteDataSource.pageSize = 20`, `RefOrderModel.pendingGrace = 30 min`, `RefOrderModel.maliSources = {'my_mali_app','my_mali','mymali','my mali'}`, `warehouseClockSkew = 2 min`, `journeyStageCount = 5`, order-number prefix `KMM-`, ref-id regexes `^order_` / `^MYM(ALI)?-`, `OrderStatus` words map `_known` |
| Log prefixes | `'[orders] …'`, `'[ko-token] …'` |
| `CacheBoxes` names and `userScoped` | `catalog, charge_rules, addresses, mali_coins, coin_rules, coupons, product, seller, support`; `userScoped = [addresses, maliCoins]` |
| Failure default messages | listed per class in §2 (user never sees them; presentation maps types) |
| DI function names | `_registerAuthData`/`registerAuthFeature`, `_registerOrdersData`/`registerOrdersFeature`, `_registerGstinData`/`registerGstinFeature` — rename per feature, keep the pair shape |

---

## 7. Gotchas

1. **Import `app_exceptions.dart` with `show AppException`** in every data source, or `ServerException` is ambiguous with the typed one in `api_exceptions.dart`. `networking.dart` is the only file importing it unqualified.
2. **`SuccessResponse.statusCode` and `ErrorResponse.errorCode` are Strings.** Compare `response.errorCode == '401'`, parse `int.tryParse(response.statusCode) ?? 200` / `int.tryParse(response.errorCode) ?? 0`. Read bodies from `rawData`, never `data`.
3. **Edge Function vs PostgREST headers are different and both matter for security.** Edge Function calls override `Authorization` with the anon key; PostgREST calls send only `apikey` so the user's token (read from `SecureStorage` under `auth.access_token`) stays the bearer and RLS applies.
4. **Third-party hosts get no default headers at all**: pass `host:` and the bearer on each call; a Supabase call must *not* pass `host:`.
5. **`Failure` has no value equality.** Never `expect(result, Left(NetworkFailure()))`; use `isA<NetworkFailure>()`. Also `NetworkFailure()` is not `const`.
6. **`NoParams` is Equatable; `<UseCase>Params` classes are not** (plain `const` classes). Don't "fix" either.
7. **Use cases are callable instances**: tests and `BuyAgainOrder` invoke `SendOtp(repository)(request)`, `GetOrderProducts(_catalog)(const NoParams())`.
8. **`UseCase`, repository contracts and data source contracts are `abstract interface class`** → `implements`. `Networking` is a plain `abstract class` (also `implements`ed by `NetworkingService` and fakes).
9. **Validation lives in the data source, after a lenient `fromJson`.** `AuthTokensModel.fromJson` never throws (`?? ''`); `verifyOtp` checks emptiness and throws `UNEXPECTED_RESPONSE` with the real 2xx status.
10. **`verifyOtp` saves tokens twice on purpose** (issued, then rotated); `signOut` clears in `finally`. The repository test asserts both; reproducing the methods in a different order breaks the tests.
11. **`AuthRepositoryImpl` subscribes in its constructor** → it needs `dispose()` and the DI `dispose:` hook; `sl.reset()` in tests triggers it.
12. **`OtpRequestModel.toEntity()` returns `fullName: ''`** — the name is not on the wire. The round-trip test is json → entity → json, not the reverse.
13. **`AuthSessionModel` has no JSON conversions**; adding a cache for it means adding `fromJson`/`toJson` plus a round-trip test (AGENTS §20 step 2).
14. **`expiresAt` is seconds × 1000**: `DateTime.fromMillisecondsSinceEpoch(s.expiresAt! * 1000)`, fallback `DateTime.now().add(Duration(seconds: s.expiresIn ?? 0))`.
15. **`userKey` is not `AuthUser.id`.** Backend tables keyed by user use `phoneToId(phone)`; `GstinRemoteDataSource` filters `user_key=eq.<userKey>`.
16. **Three phone formats in one area** (see §6): `91XXXXXXXXXX`, `+91XXXXXXXXXX`, ten digits. `OrdersRepositoryImpl._tenDigits` keeps the *last* ten digits.
17. **`RefOrderModel.toJson` uses `?key` for most fields but not for `order_id` and `payment_id`** (always present, possibly `null`), and `StockshipOrderModel.toJson` always emits `hero_image` and omits `_id` when null. The round-trip tests encode exactly that; copy the `?` placement.
18. **`StockshipOrderModel.fromEntity` is lossy** (`payment_mode` → `'cod'`/`'prepaid'`, `cod_amount`/`prepaid_amount` reconstructed from `isCashOnDelivery`). Round-trip tests use canonical JSON with doubles (`213.0`).
19. **404 → `null` only in StockShip's `_get`**; `listOrderPage` turns that into `StockshipOrderPageModel(orders: const [], page: page)` with `pages: null`, and the repository then computes `hasMore` from a full page (`result.orders.length < pageSize ? result.page : result.page + 1`).
20. **`OrdersRepositoryImpl.getOrders` starts `_pendingOrders` before awaiting StockShip**; a thrown StockShip error still returns `Left`, and `_pendingOrders` must never throw (it logs and returns `const []`).
21. **`orderStatusOf('failed')` is `created`, but `RefOrderModel.toEntity` pre-maps failed/rejected/expired to `'pseudo'` (prepaid) or `'cancelled'` (COD)** before the status ever reaches `orderStatusOf`.
22. **`WarehouseOrder.otherCharges` uses an epsilon (`rest > 0.004`)**, as does `Invoice.otherCharges`.
23. **`GstinModel.toUpsertJson` omits `legal_name` on purpose**; a server-side lookup may fill it and an upsert must not wipe it. `updated_at` is `savedAt.toUtc().toIso8601String()` (ends in `Z`, test expects `'2026-10-07T11:00:00.000Z'`).
24. **`GstinRemoteDataSourceImpl.list` filters out empty `gstin` rows** after `fromJson` (`.where((gstin) => gstin.gstin.isNotEmpty)`).
25. **`validateGstin` returns `Left(GstinEmptyFailure())` etc. without `code`**; the repository forwards the failure untouched (`if (checked case Left(:final value)) return Left(value);`).
26. **`Endpoints.baseUrlMain` reads `Env` at class-init time** → `Env.load()` must run before anything touches `Endpoints`/`BaseApiRepo` (bootstrap order).
27. **`registerOrdersFeature()` resolves `CatalogRepository`** for `GetOrderProducts` and `BuyAgainOrder`; in tests register `FakeCatalogRepository` (and `FakeOrdersRepository`) first.
28. **`FakeNetworking` implements GET/POST/DELETE/PATCH only** and relies on `noSuchMethod` for the rest; `queued` answers take priority over `response`; `error` throws on every call until cleared (`networking..response = null..error = …`).
29. **The test for the local source builds `PrefUtils` with `SharedPreferences.setMockInitialValues` and then `clearAll()` + re-set**, because `PrefUtils._sharedPreferences` is a process-wide static.
30. **`CatalogSnapshot.products` is a non-final field** (with a stray `// ← ADD THIS` comment) — the one entity in the dependency chain that is mutable; `GetOrderProducts` reads it. Don't copy that into new entities.
31. **The `TODO(login): resend` comment sits above `AuthRemoteDataSource`**; the resend flow is not implemented in the data layer.
