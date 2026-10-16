# Inventory: storage-secrets-cache

Repo: `C:/Users/Katyayani/Documents/flutter/mymali` (Flutter 3.47.5 stable, Dart 3.13.4, `environment: sdk: ^3.13.4`).
Every file below was read in full. The CODE is the truth; where AGENTS.md says something else, both are recorded in section 4.

## The three storage tiers (as built)

| Tier | Class (abstract → impl) | Engine | What goes there (from code) | Cleared on sign-out? |
|---|---|---|---|---|
| Preferences | `PrefUtils` (concrete, no interface) | `shared_preferences` | Small app-owned values and device-first user lists, each a JSON string or a bool under a dotted key: `cart.items`, `wishlist.saved`, `location.selected_place`, `checkout.order_attempt`, `profile.avatar.<userId>` (base64 photo), `secure_storage.installed` (flag) | No. Never cleared as a whole; each feature decides |
| Secrets | `SecureStorage` → `DeviceSecureStorage` | `flutter_secure_storage` (iOS Keychain / Android Keystore-encrypted) with a static in-memory mirror | Only secrets: `auth.access_token`, `auth.refresh_token`, `auth.user_id` (via `AuthLocalDataSource`), and the whole Supabase session JSON under `sb-<project-ref>-auth-token` (via `SecureSessionStorage`) | Tokens: yes, by `AuthLocalDataSource.clearTokens()`. Session: by the Supabase SDK (`removePersistedSession`) |
| Cache of server data | `LocalCache` → `HiveLocalCache` | `hive_ce` + `hive_ce_flutter`, one `Box<String>` per feature, every entry `{"version","saved_at","data"}` | Copies of server data (catalog snapshot, addresses, coin balance/rules, coupons, product pages, seller, support, charge rules) | Only boxes in `CacheBoxes.userScoped` (`addresses`, `mali_coins`) via `LocalCache.clearUserScoped()`, called from `AuthLocalDataSource.clearTokens()` |

Decision table (AGENTS.md §20 "Which storage to use", confirmed by code):

| Data | Store |
|---|---|
| A copy of server data (lists, snapshots, details, configuration) | `LocalCache` (Hive) |
| Tokens and the Supabase session | `SecureStorage` |
| Small app-owned values (flags, settings) and device-first user lists (the cart, the wishlist) — in code also: the chosen place, the last order attempt, the per-user avatar bytes | `PrefUtils` |
| Images | `AppNetworkImage` (not this area) |

Never put tokens or other secrets in `LocalCache` or `PrefUtils`. Never import Hive outside `lib/core/services/local_cache/`; never import `flutter_secure_storage` outside `device_secure_storage.dart`; never import `shared_preferences` outside `pref_utils.dart` (the legacy `shared_pref_repository.dart` does not, it goes through `PrefUtils`).

---

## 1. Files

Classification: ALWAYS = generic architecture, install in every app · CONDITIONAL(<capability>) · MYMALI-SPECIFIC = this app's business logic (install only as an example/template).

| Path | Role | Class | Placeholders another app substitutes |
|---|---|---|---|
| `lib/core/services/pref_utils.dart` | SharedPreferences wrapper. One **static** `SharedPreferences?` shared by every instance; constructor fires `init()` unawaited; every method is null-safe (`?? false`) | ALWAYS | Drop the legacy `getUserToken()` (reads `'xx-token'`) or keep it inert; `getAllData()` uses `print` (lint) |
| `lib/core/services/secure_storage/secure_storage.dart` | `abstract interface class SecureStorage { read, write, delete }` | CONDITIONAL(app signs users in and keeps tokens or a session; note `NetworkingService` takes a `SecureStorage` to read the bearer token, so it comes with the networking area whenever there is auth) | none |
| `lib/core/services/secure_storage/device_secure_storage.dart` | `DeviceSecureStorage implements SecureStorage`: Keychain/Keystore + static memory mirror; `init()` fresh-install wipe behind a prefs flag | CONDITIONAL(same) | `installedKey = 'secure_storage.installed'` (keep), log prefix `[secure_storage]` |
| `lib/core/services/secure_storage/secure_session_storage.dart` | `SecureSessionStorage extends LocalStorage` (supabase_flutter) so the SDK keeps its session in `SecureStorage`; migrates the SDK's old SharedPreferences copy | CONDITIONAL(app uses Supabase Auth via `supabase_flutter`) | `supabaseUrl` comes from `Env.supabaseUrl` (`SUPABASE_URL`) |
| `lib/core/services/local_cache/local_cache.dart` | `abstract interface class LocalCache` (read/write/delete/clearBox/clearUserScoped) | CONDITIONAL(app caches server data on the device; MyMali installs it unconditionally because `AuthLocalDataSource.clearTokens()` calls `clearUserScoped()`) | none |
| `lib/core/services/local_cache/hive_local_cache.dart` | `HiveLocalCache implements LocalCache`, `static init()` / `openBoxes()`, the `{version, saved_at, data}` envelope, `CacheException` mapping | CONDITIONAL(same) | none (field names `version`, `saved_at`, `data` are the envelope: keep) |
| `lib/core/services/local_cache/cache_boxes.dart` | `abstract final class CacheBoxes`: one `static const String` per box, `all`, `userScoped` | CONDITIONAL(same) — shape ALWAYS, contents per app | Every box name is MyMali's: `catalog`, `charge_rules`, `addresses`, `mali_coins`, `coin_rules`, `coupons`, `product`, `seller`, `support`; `userScoped = [addresses, maliCoins]` |
| `lib/core/app/exceptions/cache_exceptions.dart` | `CacheException` | CONDITIONAL(cache) | none |
| `lib/core/app/failure.dart` (the `CacheMissFailure` part) | `CacheMissFailure extends Failure` lives once here because every feature returns it | CONDITIONAL(cache) (file itself is ALWAYS, owned by the failures area) | none |
| `lib/core/utils/string_constants.dart` | Holds `static const String appAuthToken = 'auth.access_token'`, the one constant this area uses (shared between `AuthLocalDataSourceImpl.accessTokenKey` and `NetworkingService._getOptions`). Everything else in it is legacy non-const statics | ALWAYS (the one const); the rest is legacy | Drop the legacy statics in a new app; keep `appAuthToken` |
| `lib/core/utils/json_readers.dart` | Lenient JSON readers used by every local data source and model: `asDouble`, `asInt`, `asNumeric`, `asString`, `asBool`, `asMap`, `asMapList`, `asStringList` | ALWAYS | none |
| `lib/features/auth/data/datasources/auth_local_data_source.dart` | `AuthLocalDataSource` + `Impl`: tokens in `SecureStorage`, legacy prefs migration, `clearTokens()` → `clearUserScoped()` | CONDITIONAL(app keeps auth tokens) | Keys `auth.access_token` / `auth.refresh_token` / `auth.user_id` (keep unless the app has different token fields) |
| `lib/features/auth/data/models/auth_tokens_model.dart` | `AuthTokensModel` `{access_token, refresh_token, user_id}` + `fromEntity`/`toEntity` | CONDITIONAL(auth) | JSON keys follow the app's login API |
| `lib/features/auth/domain/entities/auth_tokens.dart` | `AuthTokens extends Equatable` | CONDITIONAL(auth) | none |
| `lib/features/auth/data/datasources/auth_session_data_source.dart` | The only class touching `SupabaseClient.auth`; `refreshedSessions` stream feeds token re-saves | CONDITIONAL(Supabase Auth) | error codes `SESSION_FAILED`, `SIGN_OUT_FAILED` |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Where tokens are saved (verify ×2, restore, every refresh) and cleared (`signOut` `finally`) | CONDITIONAL(auth); OTP code mapping is MYMALI-SPECIFIC | OTP error codes |
| `lib/features/location/data/datasources/location_local_data_source.dart` | Template for "one JSON value in PrefUtils": `location.selected_place` | MYMALI-SPECIFIC (feature) — shape is the generic template | key, model, exception name |
| `lib/features/location/data/exceptions/location_exceptions.dart` | `LocationStorageException([message])` among others | MYMALI-SPECIFIC; pattern `<Feature>StorageException` | — |
| `lib/features/location/data/models/place_model.dart` | `PlaceModel` JSON `{area, city, district, state, pincode, lat, lng}` | MYMALI-SPECIFIC | — |
| `lib/features/location/data/repositories/location_repository_impl.dart` | `_guard` maps `LocationStorageException` → `LocationStorageFailure` | MYMALI-SPECIFIC; pattern | — |
| `lib/features/checkout/data/datasources/order_attempt_local_data_source.dart` | PrefUtils-held state `checkout.order_attempt` (KO `x-request-id` + signature + `saved_at`) | MYMALI-SPECIFIC (KO-Tech) | — |
| `lib/features/checkout/data/models/order_attempt_model.dart` | `OrderAttemptModel {signature, request_id, saved_at}` | MYMALI-SPECIFIC | — |
| `lib/features/checkout/data/exceptions/checkout_exceptions.dart` | `OrderAttemptStorageException(this.message)` (required, non-null) + KO/Medusa exceptions | MYMALI-SPECIFIC | — |
| `lib/features/wishlist/data/datasources/wishlist_local_data_source.dart` | Device-first list in PrefUtils, `wishlist.saved`, read/write only (no clear) | MYMALI-SPECIFIC (feature); device-first template | — |
| `lib/features/wishlist/data/models/stored_wishlist_model.dart` | `StoredWishlistModel {user_id, ids, pending}` | MYMALI-SPECIFIC | — |
| `lib/features/wishlist/data/exceptions/wishlist_exceptions.dart` | `WishlistStorageException([message])` | MYMALI-SPECIFIC | — |
| `lib/features/cart/data/datasources/cart_local_data_source.dart` | Device-first cart in PrefUtils, `cart.items`; reads a legacy List shape; `readCart()` never returns null | MYMALI-SPECIFIC | — |
| `lib/features/cart/data/exceptions/cart_exceptions.dart` | `CartStorageException([message])` | MYMALI-SPECIFIC | — |
| `lib/features/profile/data/datasources/avatar_local_data_source.dart` | Per-user bytes as base64 in PrefUtils, `profile.avatar.<userId>` | MYMALI-SPECIFIC | — |
| `lib/features/profile/data/exceptions/avatar_exceptions.dart` | `AvatarStorageException([message])` | MYMALI-SPECIFIC | — |
| `lib/features/catalog/data/datasources/catalog_local_data_source.dart` | The reference `LocalCache` consumer: `_read`/`_write` helpers, 3 keys, `schemaVersion = 2`, `clear()` = `clearBox` | MYMALI-SPECIFIC content; the generic TEMPLATE for a multi-key local data source | box, keys, models |
| `lib/features/address/data/datasources/address_local_data_source.dart` | Single-key template, user-scoped box, `schemaVersion = 1` | MYMALI-SPECIFIC content; template | — |
| `lib/features/cart/data/datasources/charge_rules_local_data_source.dart` | Single-key, `schemaVersion = 3` (bumped twice), no clear | MYMALI-SPECIFIC | — |
| `lib/features/coupons/data/datasources/coupon_local_data_source.dart` | List with `maxAge: CouponRepository.listMaxAge`, `clear()` = `delete` | MYMALI-SPECIFIC; the `maxAge` template | — |
| `lib/features/invoice/data/datasources/seller_local_data_source.dart` | Single-key `identity`, not user-scoped | MYMALI-SPECIFIC | — |
| `lib/features/mali_coins/data/datasources/mali_coins_local_data_source.dart` | Two boxes from one data source (`mali_coins` user-scoped, `coin_rules` not); a primitive wrapped as `{balance: n}`; rules with `maxAge` | MYMALI-SPECIFIC; template for "two boxes, one source" | — |
| `lib/features/product/data/datasources/product_local_data_source.dart` | Keys built from input: `_productKey(id) => 'product.$id'`; a primitive wrapped as `{'id': regionId}` | MYMALI-SPECIFIC; the keyed-by-input template | — |
| `lib/features/support/data/datasources/support_local_data_source.dart` | Single-key `content`, not user-scoped | MYMALI-SPECIFIC | — |
| `lib/features/catalog/data/repositories/catalog_repository_impl.dart` | Repository `_save` / `_cached` helpers, `getCached…` → `CacheMissFailure`, one `_fetchSnapshot` path per cache entry | MYMALI-SPECIFIC content; the helpers are the generic pattern | — |
| `lib/features/coupons/data/repositories/coupon_repository_impl.dart` | Same helpers + `_inFlight` shared request + "serve the fresh copy without a request unless `refresh`" | MYMALI-SPECIFIC; pattern | — |
| `lib/features/mali_coins/data/repositories/mali_coins_repository_impl.dart` | Same helpers + `_guard` | MYMALI-SPECIFIC; pattern | — |
| `lib/app/bootstrap.dart` | Startup order: `Env.load` → Firebase → `DeviceSecureStorage.init()` → `Supabase.initialize(authOptions.localStorage: SecureSessionStorage(...))` → `HiveLocalCache.init()` → `configureDependencies()` | ALWAYS (the storage lines); Firebase/engagement/analytics lines belong to other areas | Supabase URL/anon key env names |
| `lib/core/di/injection_container.dart` (`_registerCore`, `_registerAuthData`, every `_register<Feature>Data`) | `registerLazySingleton<SecureStorage>(DeviceSecureStorage.new)`, `<PrefUtils>(PrefUtils.new)`, `<LocalCache>(HiveLocalCache.new)`; local data sources registered by abstract type with `sl()` | ALWAYS | feature registrations |
| `lib/core/services/networking/networking.dart` (lines 89–93, 135–146 only) | `NetworkingService({this.options, SecureStorage? secureStorage}) : _secureStorage = secureStorage ?? DeviceSecureStorage()`; `_getOptions` reads `StringConstants.appAuthToken` from it on every Supabase call | (networking area) — dependency on this area | — |
| `lib/core/repositories/shared_pref_repository.dart` | LEGACY `SharePrefRepo extends BaseApiRepo` wrapping `PrefUtils` with 20 ad-hoc getters/setters | MYMALI-SPECIFIC LEGACY — never install, never copy (AGENTS.md §16) | — |
| `test/core/services/local_cache/hive_local_cache_test.dart` | Real Hive over a temp dir: round-trip, reopen, version miss+delete, expiry miss+keep, corrupt miss+delete, delete/clearBox, non-JSON write throws, closed box behaviour | CONDITIONAL(cache) | temp prefix `'mymali_cache_test'`, clock `DateTime.utc(2026, 10, 1, 12)` |
| `test/core/services/secure_storage/device_secure_storage_test.dart` | Real class over `FlutterSecureStorage.setMockInitialValues`; memory sharing; fresh-install wipe; later start keeps | CONDITIONAL(secrets) | — |
| `test/core/services/secure_storage/secure_session_storage_test.dart` | `keyFor`, persist/read/remove, prefs migration, secure wins over prefs | CONDITIONAL(Supabase) | URL `https://abcd1234.supabase.co` → key `sb-abcd1234-auth-token` |
| `test/helpers/fake_local_cache.dart` | `FakeLocalCache implements LocalCache` (in-memory, JSON round-trip, version + maxAge via injected clock, `readError`/`writeError`, `clearUserScopedCalls`, `keysOf`) | CONDITIONAL(cache) | default clock `DateTime.utc(2026, 10, 1)` |
| `test/helpers/fake_secure_storage.dart` | `FakeSecureStorage implements SecureStorage` (a `Map<String, String> values`) | CONDITIONAL(secrets) | — |
| `test/features/auth/data/datasources/auth_local_data_source_test.dart` | Save → secure only; legacy migration; save removes prefs copy; clear → both copies + `clearUserScopedCalls == 1` | CONDITIONAL(auth) | — |
| `test/features/auth/data/repositories/auth_repository_impl_test.dart` | `_FakeLocal implements AuthLocalDataSource` records `saved` list; proves save order (issued → rotated), restore re-save, refresh stream save, signOut clear | CONDITIONAL(auth) | — |
| `test/features/location/.../location_local_data_source_test.dart`, `checkout/.../order_attempt_local_data_source_test.dart`, `wishlist/.../wishlist_local_data_source_test.dart`, `cart/.../cart_local_data_source_test.dart`, `profile/.../avatar_local_data_source_test.dart` | PrefUtils-backed data sources tested over the REAL `PrefUtils` + `SharedPreferences.setMockInitialValues({})`; corrupt → `<Feature>StorageException` | MYMALI-SPECIFIC content; the generic PrefUtils test template | — |
| `test/features/{catalog,address,cart(charge_rules),coupons,invoice,mali_coins,support,product}/data/datasources/*_test.dart` | `LocalCache`-backed data sources over `FakeLocalCache`: miss → null, write/read equal, `keysOf(box)`, version miss, maxAge miss, `CacheBoxes.all`/`userScoped` membership, `readError`/`writeError` pass through | MYMALI-SPECIFIC content; template | — |
| `test/features/catalog/data/repositories/catalog_repository_impl_test.dart` | Hand-written `_FakeRemote` + `_FakeLocal` sharing one `List<String> log` to assert side-effect ORDER (`['remote.fetchSnapshot', 'local.writeSnapshot']`) | template | — |
| `test/features/cart/data/repositories/charge_rules_repository_impl_test.dart` | Repository over the real local data source + `FakeLocalCache` (`writeError` never fails a read; `readError` is a miss) | template | — |

No `FakePrefUtils` exists anywhere in `test/`. Repository tests fake the local data source **interface** (`_FakeLocal implements XLocalDataSource`, `_FakeAttempts implements OrderAttemptLocalDataSource`, `_FakeAvatars implements AvatarLocalDataSource`); data-source tests use the real `PrefUtils`.

---

## 2. Names

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `PrefUtils` | class | `lib/core/services/pref_utils.dart` | `class PrefUtils { static SharedPreferences? _sharedPreferences; PrefUtils() { if (_sharedPreferences == null) { init(); } } }` |
| `PrefUtils.init` | method | same | `Future<void> init() async { _sharedPreferences ??= await SharedPreferences.getInstance(); }` |
| `PrefUtils.clearPreferencesData` | method | same | `Future<void> clearPreferencesData() async { await _sharedPreferences?.clear(); }` |
| `PrefUtils.setString` | method | same | `Future<bool> setString({required String key, required String value})` → `await _sharedPreferences?.setString(key, value) ?? false` |
| `PrefUtils.getString` | method | same | `String? getString({required String key})` |
| `PrefUtils.setJsonString` | method | same | `Future<bool> setJsonString({required String key, required String jsonValue})` (same as setString) |
| `PrefUtils.getJsonString` | method | same | `String? getJsonString({required String key})` (same as getString) |
| `PrefUtils.remove` | method | same | `Future<bool> remove({required String key})` |
| `PrefUtils.getUserToken` | method (LEGACY) | same | `String? getUserToken()` → `_sharedPreferences?.getString('xx-token')` |
| `PrefUtils.setBool` | method | same | `Future<bool> setBool({required String key, required bool value})` |
| `PrefUtils.getBool` | method | same | `bool? getBool({required String key})` |
| `PrefUtils.getAllData` | method | same | `Map<String, dynamic> getAllData()` (iterates `getKeys()`, `log("ALL PREFERNECE DATA")`, `print(allData)`) |
| `PrefUtils.clearAll` | method | same | `Future<bool> clearAll()` → `_sharedPreferences?.clear() ?? Future.value(false)` |
| `SecureStorage` | abstract interface class | `lib/core/services/secure_storage/secure_storage.dart` | `Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key);` |
| `DeviceSecureStorage` | class | `lib/core/services/secure_storage/device_secure_storage.dart` | `class DeviceSecureStorage implements SecureStorage { DeviceSecureStorage({FlutterSecureStorage storage = _storage}) : _platform = storage; }` |
| `DeviceSecureStorage._storage` | private static const | same | `FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: true), iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device))` |
| `DeviceSecureStorage.installedKey` | static const | same | `static const String installedKey = 'secure_storage.installed';` |
| `DeviceSecureStorage._memory` | private static | same | `static final Map<String, String?> _memory = {};` (shared by every instance) |
| `DeviceSecureStorage.init` | static method | same | `static Future<void> init({PrefUtils? prefs, FlutterSecureStorage storage = _storage})` — never throws |
| `DeviceSecureStorage.resetMemory` | static method | same | `@visibleForTesting static void resetMemory() => _memory.clear();` |
| `SecureSessionStorage` | class | `lib/core/services/secure_storage/secure_session_storage.dart` | `class SecureSessionStorage extends LocalStorage { SecureSessionStorage({required this._storage, required this._prefs, required String supabaseUrl}) : key = keyFor(supabaseUrl); }` — call site: `SecureSessionStorage(storage: …, prefs: …, supabaseUrl: …)` |
| `SecureSessionStorage.key` | field | same | `final String key;` |
| `SecureSessionStorage.keyFor` | static method | same | `static String keyFor(String supabaseUrl) => 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';` |
| `SecureSessionStorage.initialize / hasAccessToken / accessToken / persistSession / removePersistedSession` | overrides of `LocalStorage` | same | `Future<void> initialize()`, `Future<bool> hasAccessToken()`, `Future<String?> accessToken()`, `Future<void> persistSession(String persistSessionString)`, `Future<void> removePersistedSession()` |
| `LocalCache` | abstract interface class | `lib/core/services/local_cache/local_cache.dart` | see verbatim block in §3 |
| `HiveLocalCache` | class | `lib/core/services/local_cache/hive_local_cache.dart` | `class HiveLocalCache implements LocalCache { HiveLocalCache({DateTime Function() now = DateTime.now}) : _now = now; }` |
| `HiveLocalCache.init` | static method | same | `static Future<void> init() async` — `Hive.initFlutter()` in try; on failure returns; then `openBoxes()` |
| `HiveLocalCache.openBoxes` | static method | same | `static Future<void> openBoxes() async` — opens every `CacheBoxes.all` as `Box<String>`; on failure `deleteBoxFromDisk` + reopen; else stays closed |
| `HiveLocalCache._versionField / _savedAtField / _dataField` | private static const | same | `'version'`, `'saved_at'`, `'data'` |
| `HiveLocalCache._boxOrNull` | private method | same | `Box<String>? _boxOrNull(String name) => Hive.isBoxOpen(name) ? Hive.box<String>(name) : null;` |
| `CacheBoxes` | abstract final class | `lib/core/services/local_cache/cache_boxes.dart` | `static const String catalog = 'catalog'; chargeRules = 'charge_rules'; addresses = 'addresses'; maliCoins = 'mali_coins'; coinRules = 'coin_rules'; coupons = 'coupons'; product = 'product'; seller = 'seller'; support = 'support'; static const List<String> all = [catalog, chargeRules, addresses, maliCoins, coinRules, coupons, product, seller, support]; static const List<String> userScoped = [addresses, maliCoins];` |
| `CacheException` | class | `lib/core/app/exceptions/cache_exceptions.dart` | `class CacheException implements Exception { const CacheException([this.message]); final String? message; @override String toString() => 'CacheException($message)'; }` |
| `CacheMissFailure` | class | `lib/core/app/failure.dart` | `class CacheMissFailure extends Failure { CacheMissFailure({super.message = 'Nothing saved on this device.'}); }` |
| `StringConstants.appAuthToken` | static const | `lib/core/utils/string_constants.dart` | `static const String appAuthToken = 'auth.access_token';` |
| `AuthLocalDataSource` | abstract interface class | `lib/features/auth/data/datasources/auth_local_data_source.dart` | `Future<void> saveTokens(AuthTokensModel tokens); Future<AuthTokensModel?> readTokens(); Future<void> clearTokens();` |
| `AuthLocalDataSourceImpl` | class | same | `AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache);` (positional: `SecureStorage`, `PrefUtils`, `LocalCache`) |
| `AuthLocalDataSourceImpl.accessTokenKey / refreshTokenKey / userIdKey` | static const | same | `= StringConstants.appAuthToken` (`'auth.access_token'`), `'auth.refresh_token'`, `'auth.user_id'`; private `static const List<String> _keys = [accessTokenKey, refreshTokenKey, userIdKey];` |
| `AuthTokensModel` | class | `lib/features/auth/data/models/auth_tokens_model.dart` | `const AuthTokensModel({required this.accessToken, required this.refreshToken, required this.userId});` JSON `access_token`, `refresh_token`, `user_id` (missing → `''`); `fromEntity`, `toEntity` |
| `AuthTokens` | entity | `lib/features/auth/domain/entities/auth_tokens.dart` | `class AuthTokens extends Equatable { const AuthTokens({required this.accessToken, required this.refreshToken, required this.userId}); props => [accessToken, refreshToken, userId]; }` |
| `AuthSessionDataSource.refreshedSessions` | getter | `lib/features/auth/data/datasources/auth_session_data_source.dart` | `Stream<AuthSessionModel> get refreshedSessions` — `onAuthStateChange.where(event == tokenRefreshed && session != null).map(fromSupabaseSession)` |
| `LocationLocalDataSource` / `Impl` | interface + class | `lib/features/location/data/datasources/location_local_data_source.dart` | `Future<PlaceModel?> readSelectedPlace(); Future<void> writeSelectedPlace(PlaceModel place); Future<void> clearSelectedPlace();` · `LocationLocalDataSourceImpl(this._prefs); static const String selectedPlaceKey = 'location.selected_place';` |
| `OrderAttemptLocalDataSource` / `Impl` | interface + class | `lib/features/checkout/data/datasources/order_attempt_local_data_source.dart` | `Future<OrderAttemptModel?> readAttempt(); Future<void> writeAttempt(OrderAttemptModel attempt); Future<void> clearAttempt();` · `static const String attemptKey = 'checkout.order_attempt';` |
| `OrderAttemptModel` | class | `lib/features/checkout/data/models/order_attempt_model.dart` | `{signature, requestId → 'request_id', savedAt → 'saved_at' (toUtc().toIso8601String(); unparseable → epoch 0 UTC)}` |
| `WishlistLocalDataSource` / `Impl` | interface + class | `lib/features/wishlist/data/datasources/wishlist_local_data_source.dart` | `Future<StoredWishlistModel?> readWishlist(); Future<void> writeWishlist(StoredWishlistModel wishlist);` · `static const String wishlistKey = 'wishlist.saved';` |
| `StoredWishlistModel` | class | `lib/features/wishlist/data/models/stored_wishlist_model.dart` | `const StoredWishlistModel({required this.userId, this.ids = const [], this.pending = false});` JSON `user_id`, `ids`, `pending`; `fromEntity(List<WishlistItem> items, {required String userId, bool pending = false})`; `List<WishlistItem> toEntity()` |
| `CartLocalDataSource` / `Impl` | interface + class | `lib/features/cart/data/datasources/cart_local_data_source.dart` | `Future<CartModel> readCart(); Future<void> writeCart(CartModel cart);` · `static const String itemsKey = 'cart.items';` |
| `AvatarLocalDataSource` / `Impl` | interface + class | `lib/features/profile/data/datasources/avatar_local_data_source.dart` | `Future<Uint8List?> read(String userId); Future<void> write(String userId, Uint8List bytes);` · `static String keyFor(String userId) => 'profile.avatar.$userId';` |
| `CatalogLocalDataSourceImpl` consts | static const | `lib/features/catalog/data/datasources/catalog_local_data_source.dart` | `snapshotKey = 'snapshot'; soldCountsKey = 'sold_counts'; lowStockThresholdsKey = 'low_stock_thresholds'; static const int schemaVersion = 2;` |
| `AddressLocalDataSourceImpl` consts | static const | `lib/features/address/data/datasources/address_local_data_source.dart` | `addressesKey = 'addresses'; schemaVersion = 1;` |
| `ChargeRulesLocalDataSourceImpl` consts | static const | `lib/features/cart/data/datasources/charge_rules_local_data_source.dart` | `rulesKey = 'rules'; schemaVersion = 3;` |
| `CouponLocalDataSourceImpl` consts | static const | `lib/features/coupons/data/datasources/coupon_local_data_source.dart` | `activeKey = 'active'; schemaVersion = 1;` read with `maxAge: CouponRepository.listMaxAge` |
| `SellerLocalDataSourceImpl` consts | static const | `lib/features/invoice/data/datasources/seller_local_data_source.dart` | `sellerKey = 'identity'; schemaVersion = 1;` |
| `MaliCoinsLocalDataSourceImpl` consts | static const | `lib/features/mali_coins/data/datasources/mali_coins_local_data_source.dart` | `balanceKey = 'balance'; rulesKey = 'rules'; schemaVersion = 1;` balance stored as `{balanceKey: balance}` in box `maliCoins`; rules in box `coinRules` with `maxAge: MaliCoinsRepository.rulesMaxAge` |
| `ProductLocalDataSourceImpl` consts | static const / helper | `lib/features/product/data/datasources/product_local_data_source.dart` | `regionKey = 'region'; schemaVersion = 1; static String _productKey(String productId) => 'product.$productId';` region stored as `{'id': regionId}` |
| `SupportLocalDataSourceImpl` consts | static const | `lib/features/support/data/datasources/support_local_data_source.dart` | `contentKey = 'content'; schemaVersion = 1;` |
| `LocationStorageException` | exception | `lib/features/location/data/exceptions/location_exceptions.dart` | `const LocationStorageException([this.message]); final String? message;` |
| `OrderAttemptStorageException` | exception | `lib/features/checkout/data/exceptions/checkout_exceptions.dart` | `const OrderAttemptStorageException(this.message); final String message;` (required, non-null) |
| `WishlistStorageException` / `CartStorageException` / `AvatarStorageException` | exceptions | respective `data/exceptions/` | `const XStorageException([this.message]); final String? message; toString() => 'XStorageException($message)'` |
| `LocationStorageFailure` | failure | `lib/features/location/domain/failures/location_failures.dart` (not read; referenced by `LocationRepositoryImpl._guard`) | storage exception → this failure |
| `FakeLocalCache` | test helper | `test/helpers/fake_local_cache.dart` | `FakeLocalCache({DateTime? now}) : now = now ?? DateTime.utc(2026, 10, 1); DateTime now; CacheException? readError; CacheException? writeError; int clearUserScopedCalls = 0; List<String> keysOf(String box)` |
| `FakeSecureStorage` | test helper | `test/helpers/fake_secure_storage.dart` | `FakeSecureStorage([Map<String, String>? values]) : values = {...?values}; final Map<String, String> values;` |
| DI registrations | code | `lib/core/di/injection_container.dart` | `registerLazySingleton<SecureStorage>(DeviceSecureStorage.new)`, `registerLazySingleton<Networking>(() => NetworkingService(secureStorage: sl()))`, `registerLazySingleton<PrefUtils>(PrefUtils.new)`, `registerLazySingleton<LocalCache>(HiveLocalCache.new)`, `registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl(), sl(), sl()))`, `registerLazySingleton<XLocalDataSource>(() => XLocalDataSourceImpl(sl()))` |

---

## 3. Patterns

### 3.1 `LocalCache` contract (verbatim, `lib/core/services/local_cache/local_cache.dart`)

```dart
/// A copy of server data kept on the device, as JSON under a box and key.
///
/// Every entry is saved with a schema version and the time it was saved,
/// so versioning and expiry are handled here once, not in every feature.
/// Only local data sources use this. Methods throw `CacheException` when
/// the store itself fails.
abstract interface class LocalCache {
  /// The saved JSON (a decoded Map or List). Returns null when:
  /// - nothing is saved under [key]
  /// - it was saved with a different [version] (the entry is deleted)
  /// - it is older than [maxAge]
  /// - it is corrupt (the entry is deleted)
  Future<Object?> read({
    required String box,
    required String key,
    required int version,
    Duration? maxAge,
  });

  /// Saves [json] (a `toJson()` result) with [version] and the current
  /// time.
  Future<void> write({
    required String box,
    required String key,
    required int version,
    required Object json,
  });

  Future<void> delete({required String box, required String key});

  Future<void> clearBox(String box);

  /// Clears every box in `CacheBoxes.userScoped`. Called on sign-out.
  Future<void> clearUserScoped();
}
```

Rule: copy character for character. Nothing varies.

### 3.2 `HiveLocalCache` — the envelope, the miss rules, the error rules (verbatim, `hive_local_cache.dart`)

```dart
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../app/exceptions/cache_exceptions.dart';
import 'cache_boxes.dart';
import 'local_cache.dart';

/// [LocalCache] on Hive. Each box is a `Box<String>`, and each entry is
/// `{"version": int, "saved_at": iso8601, "data": json}` as a JSON string.
///
/// The cache is never required: if Hive or a box cannot be opened, reads
/// miss and writes throw [CacheException], and the app runs on the
/// network alone.
class HiveLocalCache implements LocalCache {
  HiveLocalCache({DateTime Function() now = DateTime.now}) : _now = now;

  final DateTime Function() _now;

  static const String _versionField = 'version';
  static const String _savedAtField = 'saved_at';
  static const String _dataField = 'data';

  /// Starts Hive and opens every box. Call once at startup, before any
  /// read. It never throws: a failure only leaves the cache off.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
    } catch (_) {
      return;
    }
    await openBoxes();
  }

  /// Opens every box in [CacheBoxes.all]. A box that cannot be opened is
  /// deleted and opened again empty; if that fails too, it stays closed.
  /// Tests call this after `Hive.init` with a temporary directory.
  static Future<void> openBoxes() async {
    for (final name in CacheBoxes.all) {
      try {
        await Hive.openBox<String>(name);
      } catch (_) {
        try {
          await Hive.deleteBoxFromDisk(name);
          await Hive.openBox<String>(name);
        } catch (_) {
          // Stays closed: reads miss, writes throw.
        }
      }
    }
  }

  @override
  Future<Object?> read({
    required String box,
    required String key,
    required int version,
    Duration? maxAge,
  }) async {
    final opened = _boxOrNull(box);
    if (opened == null) return null;

    final String? raw;
    try {
      raw = opened.get(key);
    } catch (e) {
      throw CacheException(e.toString());
    }
    if (raw == null) return null;

    final Object? entry;
    try {
      entry = jsonDecode(raw);
    } on FormatException {
      await delete(box: box, key: key);
      return null;
    }

    final savedAt = entry is Map
        ? DateTime.tryParse('${entry[_savedAtField]}')
        : null;
    final data = entry is Map ? entry[_dataField] : null;
    final isCurrent = entry is Map && entry[_versionField] == version;
    if (savedAt == null || data == null || !isCurrent) {
      // Corrupt, or written by another version of the app: never
      // readable again.
      await delete(box: box, key: key);
      return null;
    }

    if (maxAge != null && _now().difference(savedAt) > maxAge) return null;
    return data;
  }

  @override
  Future<void> write({
    required String box,
    required String key,
    required int version,
    required Object json,
  }) async {
    final opened = _boxOrNull(box);
    if (opened == null) throw CacheException('Box "$box" is not open');

    try {
      await opened.put(
        key,
        jsonEncode({
          _versionField: version,
          _savedAtField: _now().toUtc().toIso8601String(),
          _dataField: json,
        }),
      );
    } catch (e) {
      // Disk full, a value that is not JSON, or a Hive error.
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> delete({required String box, required String key}) async {
    try {
      await _boxOrNull(box)?.delete(key);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearBox(String box) async {
    try {
      await _boxOrNull(box)?.clear();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearUserScoped() async {
    for (final box in CacheBoxes.userScoped) {
      await clearBox(box);
    }
  }

  Box<String>? _boxOrNull(String name) =>
      Hive.isBoxOpen(name) ? Hive.box<String>(name) : null;
}
```

Rules encoded: (a) one `Box<String>` per feature; (b) the envelope field names are fixed; (c) **version mismatch and corruption delete the entry; expiry does not** (the entry stays and reads again with a longer `maxAge`); (d) closed box → read `null`, write throws, delete/clear are silent; (e) `saved_at` is written in UTC ISO-8601; (f) the clock is injectable for tests; (g) the only Hive import in the app.

### 3.3 `CacheBoxes` (verbatim shape; contents vary)

```dart
/// Names of the cache boxes. One box per feature.
abstract final class CacheBoxes {
  static const String catalog = 'catalog';
  /// … one `static const String <feature> = '<snake_name>';` per box, each with a
  /// doc comment saying whether it is user data (cleared on sign-out) or not …
  static const List<String> all = [catalog, chargeRules, addresses, maliCoins, coinRules, coupons, product, seller, support];

  /// Boxes holding the signed-in user's data, cleared on sign-out.
  static const List<String> userScoped = [addresses, maliCoins];
}
```

Rule: every new box goes into `all` (or it is never opened: reads miss and writes throw for ever); user data goes into `userScoped` too. The test for the box asserts both memberships (`expect(CacheBoxes.all, contains(CacheBoxes.x)); expect(CacheBoxes.userScoped, contains/isNot(contains(CacheBoxes.x)))`).

### 3.4 A `LocalCache` consumer: the local data source (verbatim, catalog = multi-key template)

```dart
import '../../../../core/services/local_cache/cache_boxes.dart';
import '../../../../core/services/local_cache/local_cache.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/catalog_snapshot_model.dart';
import '../models/low_stock_threshold_model.dart';
import '../models/sold_count_model.dart';

/// The copy of the catalog saved on this device, through [LocalCache].
/// Reads return null on a miss. Throws `CacheException` when the cache
/// itself fails.
abstract interface class CatalogLocalDataSource {
  Future<CatalogSnapshotModel?> readSnapshot();

  Future<void> writeSnapshot(CatalogSnapshotModel snapshot);

  Future<List<SoldCountModel>?> readSoldCounts();

  Future<void> writeSoldCounts(List<SoldCountModel> rows);

  Future<List<LowStockThresholdModel>?> readLowStockThresholds();

  Future<void> writeLowStockThresholds(List<LowStockThresholdModel> rows);

  /// Removes everything this data source saved.
  Future<void> clear();
}

class CatalogLocalDataSourceImpl implements CatalogLocalDataSource {
  const CatalogLocalDataSourceImpl(this._cache);

  static const String snapshotKey = 'snapshot';
  static const String soldCountsKey = 'sold_counts';
  static const String lowStockThresholdsKey = 'low_stock_thresholds';

  /// Bump whenever the JSON shape of a model saved here changes. Old
  /// entries then read as misses.
  static const int schemaVersion = 2;

  final LocalCache _cache;

  @override
  Future<CatalogSnapshotModel?> readSnapshot() async {
    final json = await _read(snapshotKey);
    return json is Map ? CatalogSnapshotModel.fromJson(asMap(json)) : null;
  }

  @override
  Future<void> writeSnapshot(CatalogSnapshotModel snapshot) =>
      _write(snapshotKey, snapshot.toJson());

  @override
  Future<List<SoldCountModel>?> readSoldCounts() async {
    final json = await _read(soldCountsKey);
    return json is List
        ? asMapList(json).map(SoldCountModel.fromJson).toList()
        : null;
  }

  @override
  Future<void> writeSoldCounts(List<SoldCountModel> rows) =>
      _write(soldCountsKey, [for (final row in rows) row.toJson()]);

  @override
  Future<List<LowStockThresholdModel>?> readLowStockThresholds() async {
    final json = await _read(lowStockThresholdsKey);
    return json is List
        ? asMapList(json).map(LowStockThresholdModel.fromJson).toList()
        : null;
  }

  @override
  Future<void> writeLowStockThresholds(List<LowStockThresholdModel> rows) =>
      _write(lowStockThresholdsKey, [for (final row in rows) row.toJson()]);

  @override
  Future<void> clear() => _cache.clearBox(CacheBoxes.catalog);

  Future<Object?> _read(String key) =>
      _cache.read(box: CacheBoxes.catalog, key: key, version: schemaVersion);

  Future<void> _write(String key, Object json) => _cache.write(
    box: CacheBoxes.catalog,
    key: key,
    version: schemaVersion,
    json: json,
  );
}
```

Single-key variant (address) inlines `_cache.read(box: CacheBoxes.addresses, key: addressesKey, version: schemaVersion)` and `_cache.write(..., json: addresses.toJson())` without the helpers. Rules: `const` constructor taking `LocalCache`; keys and **one** `schemaVersion` per data source as `static const`; read returns model-or-null (`json is Map ? Model.fromJson(asMap(json)) : null`; lists via `asMapList`); write returns `Future<void>`; `clear()` is `clearBox` when the data source owns the whole box, `delete` when it owns one key (coupons). **Bump `schemaVersion` whenever any saved model's JSON changes.** An empty saved list is a hit, not a miss.

Keyed-by-input (product): `static String _productKey(String productId) => 'product.$productId';` used in `_read(_productKey(productId))` / `_write(_productKey(product.id), product.toJson())`. Primitives are wrapped in a map before saving (`{balanceKey: balance}`, `{'id': regionId}`) because a JSON `null` data field is treated as corrupt (see 3.2).

With expiry (coupons): `_cache.read(box: CacheBoxes.coupons, key: activeKey, version: schemaVersion, maxAge: CouponRepository.listMaxAge)`; the constant lives on the **domain repository contract** (`CouponRepository.listMaxAge`, `MaliCoinsRepository.rulesMaxAge`), not on the data source.

### 3.5 The repository side: `_save` / `_cached` / `getCached…` (verbatim, `catalog_repository_impl.dart`)

```dart
  @override
  Future<Either<Failure, CatalogSnapshot>> getCachedCatalog() async {
    final snapshot = await _cached(_local.readSnapshot);
    if (snapshot == null) return Left(CacheMissFailure());
    return Right(prepareCatalog(snapshot.toEntity()));
  }

  @override
  Future<Either<Failure, Map<String, int>>> getSoldCounts() async {
    try {
      final rows = await _remote.fetchSoldCounts();
      await _save(() => _local.writeSoldCounts(rows));
      return Right(SoldCountModel.toSkuMap(rows));
    } on ServerException catch (e) {
      return Left(_toFailure(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  /// Runs a cache [write]. A cache failure never fails a successful
  /// request.
  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } on CacheException {
      // Best-effort: the next successful load saves again.
    }
  }

  /// Runs a cache [read]. A cache failure reads as a miss.
  Future<T?> _cached<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on CacheException {
      return null;
    }
  }
```

The two helpers are copied verbatim into every caching repository (`CatalogRepositoryImpl`, `CouponRepositoryImpl`, `MaliCoinsRepositoryImpl`; the same text each time). Rules: fetch → `_save` → `Right`; cached read never touches the network; `null` → `Left(CacheMissFailure())`; the cached method runs the same domain helpers as the remote one.

Serve-fresh-copy-without-a-request + shared in-flight request (verbatim, `coupon_repository_impl.dart`):

```dart
  /// The list request running right now, shared by every caller until it
  /// completes.
  Future<Either<Failure, List<Coupon>>>? _inFlight;

  @override
  Future<Either<Failure, List<Coupon>>> getActiveCoupons({
    required bool refresh,
  }) async {
    if (!refresh) {
      final saved = await _cached(_local.readActive);
      if (saved != null) return Right(_toEntities(saved));
    }
    return _inFlight ??= _fetchActive().whenComplete(() => _inFlight = null);
  }
```

### 3.6 A `PrefUtils` consumer: one JSON value on the device (verbatim, `location_local_data_source.dart`)

```dart
import 'dart:convert';

import '../../../../core/services/pref_utils.dart';
import '../exceptions/location_exceptions.dart';
import '../models/place_model.dart';

/// The place the user chose to shop for, kept on the device through
/// `PrefUtils`. Throws [LocationStorageException] on failure.
abstract interface class LocationLocalDataSource {
  /// The chosen place, or null when none is stored.
  Future<PlaceModel?> readSelectedPlace();

  Future<void> writeSelectedPlace(PlaceModel place);

  Future<void> clearSelectedPlace();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  LocationLocalDataSourceImpl(this._prefs);

  static const String selectedPlaceKey = 'location.selected_place';

  final PrefUtils _prefs;

  @override
  Future<PlaceModel?> readSelectedPlace() async {
    await _prefs.init();
    final raw = _prefs.getJsonString(key: selectedPlaceKey);
    if (raw == null || raw.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw LocationStorageException(e.message);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LocationStorageException('Not a place');
    }
    return PlaceModel.fromJson(decoded);
  }

  @override
  Future<void> writeSelectedPlace(PlaceModel place) async {
    await _prefs.init();
    final saved = await _prefs.setJsonString(
      key: selectedPlaceKey,
      jsonValue: jsonEncode(place.toJson()),
    );
    if (!saved) throw const LocationStorageException('Write failed');
  }

  @override
  Future<void> clearSelectedPlace() async {
    await _prefs.init();
    await _prefs.remove(key: selectedPlaceKey);
  }
}
```

Identical shape in `OrderAttemptLocalDataSourceImpl` (`'checkout.order_attempt'`, `OrderAttemptStorageException`, `'Not an order attempt'`), `WishlistLocalDataSourceImpl` (`'wishlist.saved'`, `WishlistStorageException`, `'Not a wishlist'`, no clear), `CartLocalDataSourceImpl` (`'cart.items'`, `CartStorageException`, `'Not a cart'`, returns `const CartModel()` when empty and accepts a legacy `List` via `CartModel.fromLegacyJson`). Rules: **`await _prefs.init();` is the first line of every method**; key is a dotted `'<feature>.<thing>'` `static const` on the Impl; JSON string in/out through `getJsonString`/`setJsonString`; `raw == null || raw.isEmpty` → `null`; `FormatException` → `<Feature>StorageException(e.message)`; wrong shape → `const <Feature>StorageException('Not a <thing>')`; a `false` from `setJsonString` → `const <Feature>StorageException('Write failed')`; no schema version (PrefUtils values have none).

Bytes variant (avatar): `base64Encode(bytes)` via `setString`, `base64Decode(raw)` with `FormatException` → `AvatarStorageException`, per-user key `static String keyFor(String userId) => 'profile.avatar.$userId';`.

The repository maps the storage exception to a failure in a `_guard` (verbatim, `location_repository_impl.dart`):

```dart
  /// Runs [call] and maps what the data sources throw to a failure.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on LocationPermissionException catch (e) {
      return Left(LocationPermissionDeniedFailure(isPermanent: e.isPermanent));
    } on LocationServiceOffException {
      return Left(LocationServiceDisabledFailure());
    } on PlaceNotFoundException {
      return Left(PlaceNotFoundFailure());
    } on LocationLookupException {
      return Left(LocationUnavailableFailure());
    } on LocationStorageException {
      return Left(LocationStorageFailure());
    }
  }
```

### 3.7 `DeviceSecureStorage` (verbatim, `device_secure_storage.dart`)

```dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../pref_utils.dart';
import 'secure_storage.dart';

/// [SecureStorage] on the iOS Keychain and, on Android, values encrypted with
/// a key held in the Android Keystore. The only file that imports
/// `flutter_secure_storage`.
///
/// Values are also kept in memory once read or written, so the token sent on
/// every request is not read from the Keychain each time. The memory is
/// shared by every instance, as `Supabase.initialize` and `get_it` each make
/// one.
class DeviceSecureStorage implements SecureStorage {
  DeviceSecureStorage({FlutterSecureStorage storage = _storage})
    : _platform = storage;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    // A Keystore key lost to a backup restore wipes the values instead of
    // failing every read.
    aOptions: AndroidOptions(resetOnError: true),
    // Readable after the first unlock (background token refresh), and never
    // copied to a backup or another device.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Set in `PrefUtils` once this install has started. On iOS the Keychain
  /// survives an uninstall, so a missing flag means a fresh install whose
  /// Keychain may still hold the previous install's tokens.
  static const String installedKey = 'secure_storage.installed';

  static final Map<String, String?> _memory = {};

  final FlutterSecureStorage _platform;

  /// Wipes what a previous install left behind. Call once in `bootstrap()`,
  /// before `Supabase.initialize`. Never throws.
  static Future<void> init({
    PrefUtils? prefs,
    FlutterSecureStorage storage = _storage,
  }) async {
    final pref = prefs ?? PrefUtils();
    try {
      await pref.init();
      if (pref.getBool(key: installedKey) == true) return;
      await storage.deleteAll();
      _memory.clear();
      await pref.setBool(key: installedKey, value: true);
    } catch (e) {
      log('[secure_storage] init failed: $e');
    }
  }

  @visibleForTesting
  static void resetMemory() => _memory.clear();

  @override
  Future<String?> read(String key) async {
    if (_memory.containsKey(key)) return _memory[key];
    try {
      return _memory[key] = await _platform.read(key: key);
    } catch (e) {
      log('[secure_storage] read failed for $key: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    _memory[key] = value;
    try {
      await _platform.write(key: key, value: value);
    } catch (e) {
      log('[secure_storage] write failed for $key: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    _memory[key] = null;
    try {
      await _platform.delete(key: key);
    } catch (e) {
      log('[secure_storage] delete failed for $key: $e');
    }
  }
}
```

Rules: never throws; memory-first (writes and deletes update memory before the platform; reads cache the platform's answer, **including `null`**); memory is `static` so the instance made in `bootstrap()` and the one in `get_it` agree; `init()` wipes the platform store exactly once per install, guarded by a `PrefUtils` bool; tests call `resetMemory()`.

### 3.8 `SecureSessionStorage` (verbatim, `secure_session_storage.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pref_utils.dart';
import 'secure_storage.dart';

/// Keeps the Supabase session (access and refresh tokens) in
/// [SecureStorage] instead of the SDK's default, SharedPreferences. Passed
/// to `Supabase.initialize` in `bootstrap()`.
///
/// A session an earlier build saved in SharedPreferences is moved here on
/// [initialize], so nobody is signed out by the update.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this._storage,
    required this._prefs,
    required String supabaseUrl,
  }) : key = keyFor(supabaseUrl);

  final SecureStorage _storage;
  final PrefUtils _prefs;

  /// The SDK's own key, so the old copy is found where the SDK left it.
  final String key;

  static String keyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    await _prefs.init();
    final legacy = _prefs.getString(key: key);
    if (legacy == null) return;
    if (await _storage.read(key) == null) await _storage.write(key, legacy);
    await _prefs.remove(key: key);
  }

  @override
  Future<bool> hasAccessToken() async => await _storage.read(key) != null;

  @override
  Future<String?> accessToken() => _storage.read(key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key, persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key);
}
```

Rules: the key is the SDK's own default (`sb-<project ref>-auth-token`), so the migration finds the SDK's old SharedPreferences copy; a secure copy already present wins over the prefs copy; the prefs copy is removed either way. Note the constructor uses Dart's **private named parameters** (`required this._storage` → call site `storage:`), which need Dart ≥ 3.10; the equivalent for an older SDK is `SecureSessionStorage({required SecureStorage storage, required PrefUtils prefs, required String supabaseUrl}) : _storage = storage, _prefs = prefs, key = keyFor(supabaseUrl);`.

### 3.9 `AuthLocalDataSource`: keys, migration, clear → `clearUserScoped` (verbatim, `auth_local_data_source.dart`)

```dart
import '../../../../core/app/exceptions/cache_exceptions.dart';
import '../../../../core/services/local_cache/local_cache.dart';
import '../../../../core/services/pref_utils.dart';
import '../../../../core/services/secure_storage/secure_storage.dart';
import '../../../../core/utils/string_constants.dart';
import '../models/auth_tokens_model.dart';

/// App-owned copy of the auth tokens, for handing the access token to
/// non-Supabase services and surviving an SDK storage reset.
///
/// Do not use this to decide whether the user is signed in: the Supabase
/// SDK's current session is the authority (it auto-refreshes; this copy
/// does not).
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

**When tokens are saved / cleared** (`AuthRepositoryImpl`, verbatim fragments):

```dart
  AuthRepositoryImpl({...}) : ... {
    // Keep the stored tokens current as the SDK refreshes the session.
    _refreshSubscription = _session.refreshedSessions.listen(_saveTokensOf);
  }
  /// Stops syncing refreshed tokens.
  Future<void> dispose() => _refreshSubscription.cancel();

  // verifyOtp:
      final tokens = await _remote.verifyOtp(VerifyOtpRequestModel.fromEntity(request));
      // Save first, so the tokens survive even if setting the session fails.
      await _local.saveTokens(tokens);
      final session = await _session.establish(tokens);
      // The SDK rotates the refresh token when it starts the session.
      await _saveTokensOf(session);

  // restoreSession:
      final session = await _session.restore();
      if (session == null) return const Right(null);
      // The SDK may have refreshed the tokens while restoring.
      await _saveTokensOf(session);

  // signOut:
    try {
      await _session.signOut();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } finally {
      await _local.clearTokens();
    }
```

DI registers the repository with a disposer: `registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remote: sl(), session: sl(), local: sl()), dispose: (repository) => (repository as AuthRepositoryImpl).dispose())`.

### 3.10 Bootstrap wiring (verbatim storage lines, `lib/app/bootstrap.dart`)

```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Env.load();
  await _initFirebase();
  await DeviceSecureStorage.init();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        storage: DeviceSecureStorage(),
        prefs: PrefUtils(),
        supabaseUrl: Env.supabaseUrl,
      ),
    ),
  );
  await HiveLocalCache.init();

  configureDependencies();
  // …engagement / analytics / runApp
}
```

Rules: `DeviceSecureStorage.init()` runs **before** `Supabase.initialize` (so a fresh install's Keychain leftovers are gone before the SDK reads its session); the `SecureSessionStorage` is built with fresh `DeviceSecureStorage()` / `PrefUtils()` instances because `get_it` is not configured yet (the static memory/static prefs make them equivalent to the DI singletons); `HiveLocalCache.init()` runs after Supabase and before `configureDependencies()`; none of the three can throw.

### 3.11 DI (verbatim, `_registerCore` storage lines + one feature)

```dart
void _registerCore() {
  sl
    ..registerLazySingleton<SecureStorage>(DeviceSecureStorage.new)
    ..registerLazySingleton<Networking>(
      () => NetworkingService(secureStorage: sl()),
    )
    ..registerLazySingleton<PrefUtils>(PrefUtils.new)
    ..registerLazySingleton<LocalCache>(HiveLocalCache.new)
    // …
}

void _registerAuthData() {
  sl
    // …
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl(), sl(), sl()),
    )
    // …
}

void _registerCatalogData() {
  sl
    // …
    ..registerLazySingleton<CatalogLocalDataSource>(
      () => CatalogLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(remote: sl(), local: sl()),
    );
}
```

Rule: storage services are lazy singletons registered by abstract type (`PrefUtils` by its concrete type, it has no interface); local data sources by abstract type, taking `sl()`; repositories take `remote:` and `local:` named parameters (location: `device:` and `local:`; checkout: `attempts:`; profile: `avatars:`).

### 3.12 `PrefUtils` (verbatim, `lib/core/services/pref_utils.dart`)

```dart
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;

  PrefUtils() {
    if (_sharedPreferences == null) {
      init();
    }
  }

  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  Future<void> clearPreferencesData() async {
    await _sharedPreferences?.clear();
  }

  Future<bool> setString({required String key, required String value}) async {
    return await _sharedPreferences?.setString(key, value) ?? false;
  }

  String? getString({required String key}) {
    return _sharedPreferences?.getString(key);
  }

  Future<bool> setJsonString({
    required String key,
    required String jsonValue,
  }) async {
    return await _sharedPreferences?.setString(key, jsonValue) ?? false;
  }

  String? getJsonString({required String key}) {
    return _sharedPreferences?.getString(key);
  }

  Future<bool> remove({required String key}) async {
    return await _sharedPreferences?.remove(key) ?? false;
  }

  String? getUserToken() {
    return _sharedPreferences?.getString('xx-token');
  }

  Future<bool> setBool({required String key, required bool value}) async {
    return await _sharedPreferences?.setBool(key, value) ?? false;
  }

  bool? getBool({required String key}) {
    return _sharedPreferences?.getBool(key);
  }

  Map<String, dynamic> getAllData() {
    final keys = _sharedPreferences?.getKeys() ?? {};
    final Map<String, dynamic> allData = {};
    for (var key in keys) {
      allData[key] = _sharedPreferences?.get(key);
    }
    log("ALL PREFERNECE DATA");
    print(allData);
    return allData;
  }

  Future<bool> clearAll() {
    return _sharedPreferences?.clear() ?? Future.value(false);
  }
}
```

How it is constructed: **not** `SharedPreferences.getInstance()` per call. One `static SharedPreferences? _sharedPreferences` is shared by every `PrefUtils()` instance; `init()` fills it once (`??=`). `PrefUtils()` may be constructed anywhere (bootstrap, `DeviceSecureStorage.init`, tests) and is also a `get_it` lazy singleton. Because the constructor's `init()` is not awaited, **every consumer awaits `_prefs.init()` before reading**. Getters are synchronous; setters return `false` (not throw) when the store is not ready.

### 3.13 Test fakes (verbatim)

`test/helpers/fake_local_cache.dart`:

```dart
import 'dart:convert';

import 'package:mymali/core/app/exceptions/cache_exceptions.dart';
import 'package:mymali/core/services/local_cache/cache_boxes.dart';
import 'package:mymali/core/services/local_cache/local_cache.dart';

/// In-memory [LocalCache] for tests. Values go through JSON, as in the
/// real cache, and [version] and `maxAge` are honoured against [now].
///
/// Set [readError] or [writeError] to make those calls throw.
class FakeLocalCache implements LocalCache {
  FakeLocalCache({DateTime? now}) : now = now ?? DateTime.utc(2026, 10, 1);

  /// The clock; move it forward to test expiry.
  DateTime now;

  CacheException? readError;
  CacheException? writeError;

  int clearUserScopedCalls = 0;

  final Map<String, Map<String, _Entry>> _boxes = {};

  /// Keys saved in [box], in the order they were written.
  List<String> keysOf(String box) => [...?_boxes[box]?.keys];

  @override
  Future<Object?> read({
    required String box,
    required String key,
    required int version,
    Duration? maxAge,
  }) async {
    final error = readError;
    if (error != null) throw error;

    final entry = _boxes[box]?[key];
    if (entry == null) return null;
    if (entry.version != version) {
      _boxes[box]?.remove(key);
      return null;
    }
    if (maxAge != null && now.difference(entry.savedAt) > maxAge) return null;
    return jsonDecode(entry.json);
  }

  @override
  Future<void> write({
    required String box,
    required String key,
    required int version,
    required Object json,
  }) async {
    final error = writeError;
    if (error != null) throw error;

    _boxes.putIfAbsent(box, () => {})[key] = _Entry(
      version: version,
      savedAt: now,
      json: jsonEncode(json),
    );
  }

  @override
  Future<void> delete({required String box, required String key}) async {
    _boxes[box]?.remove(key);
  }

  @override
  Future<void> clearBox(String box) async {
    _boxes.remove(box);
  }

  @override
  Future<void> clearUserScoped() async {
    clearUserScopedCalls++;
    for (final box in CacheBoxes.userScoped) {
      await clearBox(box);
    }
  }
}

class _Entry {
  const _Entry({
    required this.version,
    required this.savedAt,
    required this.json,
  });

  final int version;
  final DateTime savedAt;
  final String json;
}
```

`test/helpers/fake_secure_storage.dart`:

```dart
import 'package:mymali/core/services/secure_storage/secure_storage.dart';

/// In-memory [SecureStorage].
class FakeSecureStorage implements SecureStorage {
  FakeSecureStorage([Map<String, String>? values]) : values = {...?values};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
```

Test setups (verbatim):

```dart
// Real Hive in a unit test (hive_local_cache_test.dart)
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mymali_cache_test');
    Hive.init(directory.path);
    await HiveLocalCache.openBoxes();
    now = DateTime.utc(2026, 10, 1, 12);
    cache = HiveLocalCache(now: () => now);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

// Real PrefUtils in a data-source test (location_local_data_source_test.dart)
  // PrefUtils caches one SharedPreferences instance across tests, so each
  // test starts by removing what the last one stored.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefUtils();
    await prefs.init();
    await prefs.remove(key: LocationLocalDataSourceImpl.selectedPlaceKey);
    dataSource = LocationLocalDataSourceImpl(prefs);
  });

// Real DeviceSecureStorage (device_secure_storage_test.dart)
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    DeviceSecureStorage.resetMemory();
    SharedPreferences.setMockInitialValues({});
    prefs = PrefUtils();
    await prefs.init();
    await prefs.clearAll();
  });
  // in a test:
    FlutterSecureStorage.setMockInitialValues({'auth.access_token': 'old'});
    await DeviceSecureStorage.init(prefs: prefs);

// Seeding legacy prefs for a migration test (auth_local_data_source_test.dart)
  Future<void> build(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    prefUtils = PrefUtils();
    await prefUtils.init();
    await prefUtils.clearAll();
    for (final entry in prefs.entries) {
      await prefUtils.setString(key: entry.key, value: entry.value as String);
    }
    secure = FakeSecureStorage();
    cache = FakeLocalCache();
    dataSource = AuthLocalDataSourceImpl(secure, prefUtils, cache);
  }
```

Repository tests fake the local data source interface with a shared log (`catalog_repository_impl_test.dart`): `class _FakeLocal implements CatalogLocalDataSource { _FakeLocal(this.log); final List<String> log; CacheException? readError; CacheException? writeError; … log.add('local.writeSnapshot'); }` and assert `expect(log, ['remote.fetchSnapshot', 'local.writeSnapshot'])`, `expect(log.where((entry) => entry.startsWith('remote.')), isEmpty)` for cached reads. Alternatively the repository is built over the real local data source + `FakeLocalCache` (`charge_rules_repository_impl_test.dart`).

---

## 4. Rules observed in code (not in AGENTS.md, or stated differently)

1. **`PrefUtils` is a static-backed pseudo-singleton.** AGENTS.md only says "`PrefUtils` (SharedPreferences)". In code the `SharedPreferences` instance is a `static` field shared by every `PrefUtils()`; the constructor starts `init()` without awaiting; every consumer calls `await _prefs.init()` at the top of every method. It is registered in `get_it` as a lazy singleton *and* freely constructed in `bootstrap()` and `DeviceSecureStorage.init()`.
2. **`PrefUtils` setters never throw; they return `false`** when the store is not initialised, and data sources convert that to `<Feature>StorageException('Write failed')`.
3. **`DeviceSecureStorage.read` caches `null`.** After a platform read returned nothing, later reads return `null` from memory without asking the platform again until `write`/`delete`/`resetMemory`. (AGENTS.md says only "keeps values in memory".)
4. **Expired entries are kept; version-mismatched and corrupt entries are deleted.** AGENTS.md §20 says the version mismatch deletes and the corrupt entry deletes (true) but says nothing about expiry: the Hive test "an entry older than maxAge misses but is kept" pins it.
5. **A JSON `null` `data` is corrupt.** `read` deletes an entry whose `data == null`. Features therefore wrap primitives in a map (`{balance: 50}`, `{'id': 'reg_inr'}`). Not in AGENTS.md.
6. **`delete` and `clearBox` on a closed box are silent no-ops**; `read` misses; only `write` throws (`CacheException('Box "$box" is not open')`). AGENTS.md: "reads miss and writes throw `CacheException`" (consistent, incomplete).
7. **`clearUserScoped` has no per-box try/catch**: the first box that throws aborts the loop, and the caller (`AuthLocalDataSourceImpl.clearTokens`) swallows the `CacheException` so sign-out succeeds.
8. **`HiveLocalCache.init()` swallows an `initFlutter()` failure and skips opening boxes**; `openBoxes()` is public and static so tests can call it after `Hive.init(dir)`.
9. **`saved_at` is UTC** (`_now().toUtc().toIso8601String()`); the read side uses `DateTime.tryParse('${entry[_savedAtField]}')` and compares with `_now().difference(savedAt) > maxAge` (strictly greater).
10. **The version check is `entry['version'] == version`** on the decoded JSON value: keep `schemaVersion` an `int`.
11. **`AuthLocalDataSourceImpl.readTokens()` migrates only when all three secure values are missing**, and a partial legacy set (any of the three missing) reads as `null`. Every `saveTokens` and `clearTokens` removes the prefs copy (`_removeLegacyCopy`).
12. **Token save points** (AGENTS.md §7 lists them; code order matters): `verifyOtp` saves the issued tokens *before* `establish`, then saves the SDK's rotated tokens; `restoreSession` re-saves; `refreshedSessions` saves on every `tokenRefreshed` event; `signOut` clears in `finally` even when the SDK's sign-out throws.
13. **`SecureSessionStorage` stores the entire Supabase session JSON string** under the SDK key; `hasAccessToken()` is "the key exists". AGENTS.md says "the Supabase session is kept there too".
14. **`DeviceSecureStorage.init()` is a one-shot wipe per install**, guarded by `PrefUtils` bool `secure_storage.installed`; on an upgrade from a build that had no flag, the first start wipes the Keychain, which is safe only because that build kept its tokens/session in prefs (migrated afterwards). A build that ships secure storage without the flag loses its users' tokens on the next start that adds the flag.
15. **PrefUtils holds more than AGENTS.md's table says**: the selected place (`location.selected_place`), the last order attempt (`checkout.order_attempt`), and the profile photo as base64 (`profile.avatar.<userId>`), besides the cart, wishlist and the installed flag.
16. **`CartLocalDataSource.readCart()` returns a model, never `null`** (empty cart on miss) and accepts a legacy `List` shape; every other PrefUtils read returns `Model?`. `MaliCoinsLocalDataSource.readBalance()` returns `int?` and `ProductLocalDataSource.readRegionId()` returns `String?` (primitives, not models; AGENTS.md §20 says reads return "a model or null").
17. **`OrderAttemptStorageException(this.message)` requires a non-null message**; the other four `<Feature>StorageException([this.message])` take an optional one. Prefer the optional form.
18. **Expiry constants live on the domain repository contract** (`CouponRepository.listMaxAge`, `MaliCoinsRepository.rulesMaxAge`) and are read by the data layer; the data source passes them as `maxAge`. AGENTS.md §20 names them but not where they live.
19. **`StringConstants.appAuthToken`** is the single shared constant for the access-token key; `AuthLocalDataSourceImpl.accessTokenKey` aliases it and `NetworkingService._getOptions` reads `_secureStorage.read(StringConstants.appAuthToken)` on every Supabase call. The rest of `StringConstants` is legacy (non-`const` statics) and unused by this area.
20. **No widget test touches storage**: `registerSignedInApp()` registers fake *repositories*; `SharedPreferences.setMockInitialValues`/`FlutterSecureStorage.setMockInitialValues`/Hive appear only in data-source and core-service tests.
21. **`schemaVersion` history**: catalog = 2, charge_rules = 3, all others = 1 — proof the rule "bump on every JSON change" is followed (AGENTS.md: "Never change a model's JSON without bumping that data source's `schemaVersion`").
22. **AGENTS.md §16 legacy still present**: `lib/core/repositories/shared_pref_repository.dart` (`SharePrefRepo`) and `PrefUtils.getUserToken()` (`'xx-token'`), `getAllData()`'s `print`. Do not port.

---

## 5. Packages

| Package | Version (pubspec → lock) | Files that import it | Class |
|---|---|---|---|
| `shared_preferences` | `^2.0.5` → `2.5.5` | `lib/core/services/pref_utils.dart` only (tests: `SharedPreferences.setMockInitialValues`, `SharedPreferences.getInstance()` in cart/wishlist local tests) | ALWAYS |
| `flutter_secure_storage` | `^11.2.0` → `11.2.0` (Android plugin requires `minSdk = 24`) | `lib/core/services/secure_storage/device_secure_storage.dart` only (test: `FlutterSecureStorage.setMockInitialValues` in `device_secure_storage_test.dart`) | CONDITIONAL(app stores tokens / a session) |
| `supabase_flutter` | `^2.17.2` → `2.17.2` | `secure_session_storage.dart` (`LocalStorage`), `bootstrap.dart` (`Supabase.initialize`, `FlutterAuthClientOptions`), `auth_session_data_source.dart`, `injection_container.dart` (`SupabaseClient`) | CONDITIONAL(app uses Supabase) |
| `hive_ce` | `^2.20.1` → `2.20.1` | test `hive_local_cache_test.dart` (`package:hive_ce/hive.dart`: `Hive.init`, `Hive.close`, `Hive.box`) | CONDITIONAL(app caches server data) |
| `hive_ce_flutter` | `^2.4.0` → `2.4.0` (brings `path_provider` 2.1.6 transitively) | `lib/core/services/local_cache/hive_local_cache.dart` (`package:hive_ce_flutter/hive_flutter.dart`: `Hive.initFlutter`, `openBox`, `deleteBoxFromDisk`, `isBoxOpen`, `Box<String>`) | CONDITIONAL(same) |
| `get_it` | `^8.0.3` → `8.3.0` | `injection_container.dart` | ALWAYS (DI area) |
| `fpdart` | `^1.1.1` | caching repositories (`Either`, `Right`, `Left`, `unit`) | ALWAYS (domain area) |
| `flutter/foundation.dart` (SDK) | — | `device_secure_storage.dart` (`@visibleForTesting`) | ALWAYS |
| `dart:convert` (SDK) | — | `hive_local_cache.dart`, every PrefUtils data source, `avatar_local_data_source.dart` (base64), `fake_local_cache.dart` | ALWAYS |
| `dart:developer` `log` (SDK) | — | `pref_utils.dart`, `device_secure_storage.dart` | ALWAYS |
| `dart:typed_data` (SDK) | — | `avatar_local_data_source.dart` (`Uint8List`) | MYMALI-SPECIFIC |
| `flutter_test` | sdk | all tests | ALWAYS (dev) |

No mocking package. Hand-written fakes only (`FakeLocalCache`, `FakeSecureStorage`, per-test `_FakeLocal implements XLocalDataSource`).

---

## 6. What varies per app

| Thing | MyMali value | Where it appears | Substitute with |
|---|---|---|---|
| Dart package name | `mymali` | every `package:mymali/...` import in tests and helpers | the app's `pubspec.yaml` `name` |
| Cache box names | `catalog`, `charge_rules`, `addresses`, `mali_coins`, `coin_rules`, `coupons`, `product`, `seller`, `support` | `CacheBoxes` consts, `CacheBoxes.all` | one `static const String <feature> = '<snake_feature>'` per cached feature, all in `all` |
| User-scoped boxes | `[addresses, maliCoins]` | `CacheBoxes.userScoped` | the boxes holding the signed-in user's data |
| Cache keys | `snapshot`, `sold_counts`, `low_stock_thresholds`, `addresses`, `rules`, `active`, `identity`, `balance`, `region`, `product.<id>`, `content` | each `<Feature>LocalDataSourceImpl` `static const String …Key` | per feature |
| `schemaVersion` values | catalog 2, charge_rules 3, others 1 | each `<Feature>LocalDataSourceImpl.schemaVersion` | start at 1 |
| Expiry constants | `CouponRepository.listMaxAge` (5 min), `MaliCoinsRepository.rulesMaxAge` (30 min) | domain repository contracts; passed as `maxAge` by the data source | per feature; omit `maxAge` unless stale data would be wrong |
| PrefUtils keys | `cart.items`, `wishlist.saved`, `location.selected_place`, `checkout.order_attempt`, `profile.avatar.<userId>` | each PrefUtils data source `static const String …Key` / `keyFor` | `'<feature>.<thing>'` |
| Installed flag | `secure_storage.installed` | `DeviceSecureStorage.installedKey` | keep as is |
| Token keys | `auth.access_token` (= `StringConstants.appAuthToken`), `auth.refresh_token`, `auth.user_id` | `AuthLocalDataSourceImpl`, `StringConstants`, `NetworkingService._getOptions` | keep if the app has access/refresh/user id; otherwise the app's token fields, still `auth.<field>` |
| Token model JSON | `access_token`, `refresh_token`, `user_id` | `AuthTokensModel` | the login API's field names |
| Supabase session key | `sb-<project-ref>-auth-token` derived from `Env.supabaseUrl` (`SUPABASE_URL`) | `SecureSessionStorage.keyFor` | keep the formula; the env key name is the app's |
| Env getters used | `Env.supabaseUrl`, `Env.supabaseAnonKey` | `bootstrap.dart` | the app's `Env` |
| Storage exception names | `LocationStorageException`, `OrderAttemptStorageException`, `WishlistStorageException`, `CartStorageException`, `AvatarStorageException` | `features/<f>/data/exceptions/` | `<Feature>StorageException([this.message])` |
| Storage failure names | `LocationStorageFailure`, `WishlistStorageFailure` (per AGENTS.md) | `features/<f>/domain/failures/` | `<Feature>StorageFailure` |
| Log prefixes | `[secure_storage]` | `device_secure_storage.dart` | keep |
| Test clocks / temp prefix | `DateTime.utc(2026, 10, 1)` (fake), `DateTime.utc(2026, 10, 1, 12)` (Hive test), `'mymali_cache_test'` | `fake_local_cache.dart`, `hive_local_cache_test.dart` | any fixed instant; `'<app>_cache_test'` |
| Bootstrap neighbours | Firebase, Katyayani Core, analytics, portrait lock | `bootstrap.dart` | other areas; keep the storage order |
| Legacy to drop | `PrefUtils.getUserToken()` (`'xx-token'`), `SharePrefRepo`, the non-const `StringConstants` statics | `pref_utils.dart`, `core/repositories/shared_pref_repository.dart`, `string_constants.dart` | omit in a new app |

---

## 7. Gotchas

1. **Android minSdk.** `flutter_secure_storage` 11.2.0 declares `minSdk = 24` in its own `android/build.gradle`. MyMali's `android/app/build.gradle.kts` uses `minSdk = flutter.minSdkVersion`, which is 24 on Flutter 3.47.5 (`FlutterExtension.kt: val minSdkVersion: Int = 24`). An app on an older Flutter (default 21) must set `minSdk = 24` or the build fails at Gradle merge.
2. **Dart ≥ 3.10 for `SecureSessionStorage`'s constructor** (`required this._storage, required this._prefs` named private parameters; callers write `storage:`/`prefs:`). On an older SDK use explicit initializers (see §3.8).
3. **Order in `bootstrap()`**: `DeviceSecureStorage.init()` → `Supabase.initialize(... localStorage: SecureSessionStorage(...))` → `HiveLocalCache.init()` → `configureDependencies()`. Moving the wipe after `Supabase.initialize` lets a fresh iOS install resume the previous install's session; moving Hive after DI is harmless but AGENTS.md pins the order.
4. **The installed flag must ship with secure storage**: `init()` calls `storage.deleteAll()` whenever `secure_storage.installed` is not `true` in prefs. The first start of the build that introduces the flag wipes the Keychain, so that build must still be able to migrate from prefs (as MyMali does) or users get signed out.
5. **Static memory in `DeviceSecureStorage`**: tests must `DeviceSecureStorage.resetMemory()` in `setUp` or values leak between tests; the read path caches `null`, so a value planted with `FlutterSecureStorage.setMockInitialValues` after a null read is invisible until `resetMemory()`.
6. **`PrefUtils` static instance in tests**: `SharedPreferences.setMockInitialValues({})` alone does not reset values once `PrefUtils` has cached its instance; tests `await prefs.init(); await prefs.clearAll();` (or `remove(key:)`) in `setUp`. To seed legacy values, set them through `PrefUtils.setString` after `clearAll()`, not only through `setMockInitialValues`.
7. **Always `await _prefs.init()` first** in every PrefUtils data-source method; the constructor does not await it, and `getString` on an un-initialised store silently returns `null` while `setString` returns `false`.
8. **Every box must be in `CacheBoxes.all`**, or `_boxOrNull` returns `null` forever: reads miss silently and writes throw `CacheException` which repositories swallow — the feature just never caches, with no error anywhere. Add the membership test (`expect(CacheBoxes.all, contains(CacheBoxes.x))`).
9. **Never save a bare `null`** as the cache `data`; it reads as corrupt and is deleted. Wrap primitives in a map.
10. **`HiveLocalCache.init()` needs Flutter bindings and `path_provider`** (`Hive.initFlutter()`); in unit tests call `Hive.init(tempDir.path)` then `HiveLocalCache.openBoxes()`, and `Hive.close()` + delete the dir in `tearDown`. The Hive test imports `package:hive_ce/hive.dart`, the implementation imports `package:hive_ce_flutter/hive_flutter.dart`.
11. **`jsonEncode` of a non-JSON value (e.g. a `DateTime`) throws inside `write`** and surfaces as `CacheException`; models must `toJson()` to plain JSON (dates as ISO strings).
12. **Expired ≠ deleted**: a `maxAge` miss keeps the entry; a longer `maxAge` or none reads it again. A version mismatch deletes even for the old version ("another schema version misses and deletes the entry").
13. **`clearUserScoped()` aborts on the first throwing box** and `AuthLocalDataSourceImpl.clearTokens()` swallows the `CacheException`; sign-out never fails because of the cache.
14. **`readTokens()` is all-or-nothing**: a legacy copy missing any of the three keys reads as `null` and is not migrated (and is removed on the next `saveTokens`).
15. **`SecureSessionStorage.keyFor`** takes the first label of the Supabase host (`abcd1234.supabase.co` → `sb-abcd1234-auth-token`); it must equal the SDK's default key or the migration never finds the old session. A self-hosted Supabase URL with a different host still works (first label), but the SDK's default key formula should be re-checked against the installed `supabase_flutter` version.
16. **`NetworkingService` reads the token from `SecureStorage` on every Supabase call**; without the in-memory mirror every request would hit the Keychain. Keep the mirror when porting, and construct `NetworkingService(secureStorage: sl())`.
17. **`AuthRepositoryImpl` subscribes to `refreshedSessions` in its constructor** and must be registered with `dispose:` in `get_it`; tests call `await repository.dispose()`.
18. **Hive boxes are `Box<String>`** opened with `Hive.openBox<String>(name)`; opening the same name with another type later throws — never mix `TypeAdapter`s into these boxes (AGENTS.md: no `@HiveType`, no `build_runner`).
19. **AGENTS.md says `clearTokens()` clears the user-scoped cache "at the same moment the tokens are cleared"**; in code it runs *after* the secure deletes and the prefs cleanup, inside a try/catch. Keep that order.
20. **`PrefUtils.getAllData()` prints** to stdout; tests use it (`expect(prefUtils.getAllData(), isEmpty)`). If you remove the `print`, keep the return value.
