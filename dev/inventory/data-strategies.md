# Inventory: data-strategies (MyMali Flutter app)

Source of truth: the code under `C:/Users/Katyayani/Documents/flutter/mymali` as read on
2026-10-14. AGENTS.md (section 20 above all) is the rulebook; where it and the code differ,
both are recorded in section 4.

MyMali has exactly three data strategies in production, plus one designed but not built:

| Strategy | One-line definition | MyMali examples | Storage |
|---|---|---|---|
| NETWORK-ONLY | Every read goes to the server; nothing is kept on the device. The bloc still keeps data on screen while a refresh runs (`isRefreshing`) but there is no `isStale`. | `OrdersRepositoryImpl` (My Orders, Order Details, Thank You poll), `NotificationsRepositoryImpl` + `NotificationsBloc` | none |
| CACHE-FIRST | The server is the truth; a copy of every good read is saved on the device and shown first (`isStale: true`), then replaced by a fresh load. Variants: (a) two use cases `get<Thing>` / `getCached<Thing>`; (b) one method with a `maxAge` TTL + shared in-flight request (coupons, coin rules); (c) keyed-by-input entries (product page); (d) user-scoped box cleared on sign-out (coins balance, addresses). | catalog/Home/Categories, charge rules, support, Mali Coins, coupons, product, addresses, seller | `LocalCache` (Hive) |
| DEVICE-FIRST | The device copy is the truth; the server gets a copy. Writes hit the device only and return; a push runs in the background, unawaited; a sync reconciles at sign-in. Wishlist keeps a `pending` flag; cart merges with `mergeServerLines` and runs the merge outside the bloc queue (`CartSyncFinished`). | wishlist, cart | `PrefUtils` (SharedPreferences) |
| FULL LOCAL-FIRST | Device copy is the truth with change watching, an outbox of unsent operations and a `SyncService`. **Designed in AGENTS.md section 20 "Going local-first later", not implemented anywhere in the repo.** | none | (would be `LocalCache` + new `core/services/sync/`) |

---

## 1. Files

Classification: **ALWAYS** = generic architecture, install in every app (placeholders listed);
**CONDITIONAL(<capability>)** = install only when the target app has that capability;
**MYMALI-SPECIFIC** = MyMali business logic (KO-Tech, Medusa, Supabase tables, coins, coupons…).
Paths are repo-relative.

### 1.1 Core (shared by every strategy)

| path | role | class | placeholders |
|---|---|---|---|
| `lib/core/services/local_cache/local_cache.dart` | `abstract interface class LocalCache` — read/write/delete/clearBox/clearUserScoped | CONDITIONAL(app caches server data) | none |
| `lib/core/services/local_cache/hive_local_cache.dart` | `HiveLocalCache implements LocalCache`; `static init()` / `openBoxes()`; one `Box<String>` per box; entry = `{"version","saved_at","data"}` JSON string; the ONLY file importing Hive | CONDITIONAL(app caches server data) | none |
| `lib/core/services/local_cache/cache_boxes.dart` | `abstract final class CacheBoxes` — one `static const String` per box, `all`, `userScoped` | CONDITIONAL(app caches server data) | BOX NAMES: `catalog`, `charge_rules`, `addresses`, `mali_coins`, `coin_rules`, `coupons`, `product`, `seller`, `support`; `userScoped = [addresses, maliCoins]` |
| `lib/core/app/exceptions/cache_exceptions.dart` | `CacheException` (thrown by `LocalCache` and local data sources; caught by repositories) | CONDITIONAL(app caches server data) | none |
| `lib/core/app/failure.dart` | `Failure`, `NetworkFailure`, `ServerFailure(errorCode)`, `CacheMissFailure` | ALWAYS | default messages |
| `lib/core/app/exceptions/api_exceptions.dart` | `ServerException(code, status, detail)`, `ConnectionException([message])` | ALWAYS | none |
| `lib/core/app/exceptions/app_exceptions.dart` | legacy `AppException` family thrown by `NetworkingService` when no response arrived | ALWAYS (legacy shape; keep as-is) | none |
| `lib/core/app/api/api_response.dart` | `APIResponse`, `SuccessResponse(rawData, statusCode)`, `ErrorResponse(rawData, errorCode)` (AGENTS §16: has analyzer warnings; do not imitate style) | ALWAYS | none |
| `lib/core/utils/json_readers.dart` | lenient readers `asDouble asInt asNumeric asString asBool asMap asMapList asStringList` | ALWAYS | none |
| `lib/core/usecases/usecase.dart` | `UseCase<T, Params>`, `NoParams` | ALWAYS | none |
| `lib/core/services/pref_utils.dart` | `PrefUtils` over SharedPreferences (static instance, `init()`, `getJsonString`/`setJsonString`) | ALWAYS | legacy key `'xx-token'` in `getUserToken()` (unused by this area) |
| `lib/core/services/networking/networking.dart` | `Networking` abstract, `ApiHost` enum, `NetworkingService` (Dio) | ALWAYS (shape) | `ApiHost` values `medusa`, `koUtils`, `stockship` are MyMali hosts; `_thirdPartyHosts` |
| `lib/core/services/networking/endpoints.dart` | `Endpoints` (Supabase), `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | ALWAYS (shape) / values MYMALI-SPECIFIC | every path constant |
| `lib/core/utils/string_constants.dart` | `StringConstants.appAuthToken = 'auth.access_token'` (+ legacy noise) | ALWAYS (only `appAuthToken` matters) | key name |
| `lib/core/di/injection_container.dart` | `sl`, `configureDependencies()`, `_registerCore()`, `_register<Feature>Data()` / `register<Feature>Feature()` | ALWAYS (shape) | feature list, `Env.*` keys |
| `lib/app/app.dart` | `App`: `MultiBlocProvider` of app-wide blocs + `BlocListener<AuthBloc>` fan-out (`WishlistStarted`/`CartSignedIn`/`MaliCoinsStarted`/`CouponCleared`…) | ALWAYS (shape) | which app-wide blocs exist |
| `lib/app/bootstrap.dart` | startup order: `Env.load()` → Firebase → `DeviceSecureStorage.init()` → `Supabase.initialize` → `HiveLocalCache.init()` → `configureDependencies()` → `runApp` | ALWAYS (shape) | Firebase/Supabase/KC pieces |
| `lib/features/auth/data/datasources/auth_local_data_source.dart` | `AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache)`; `clearTokens()` also calls `_cache.clearUserScoped()` inside `try … on CacheException {}` | CONDITIONAL(app stores tokens AND caches user-scoped data) | key names `auth.refresh_token`, `auth.user_id` |

### 1.2 NETWORK-ONLY

| path | role | class | placeholders |
|---|---|---|---|
| `lib/features/orders/domain/repositories/orders_repository.dart` | `OrdersRepository` contract (4 methods, all `Future<Either<Failure, …>>`) | MYMALI-SPECIFIC (KO/StockShip) — shape is the network-only template | — |
| `lib/features/orders/data/repositories/orders_repository_impl.dart` | two remote sources, no local; injected clock `now`; `_pendingOrders` never throws (logs `[orders] …`); status-0 == offline | MYMALI-SPECIFIC | `StockshipException`, `RefOrdersException`, `KoTokenException`, `'NO_KO_TOKEN'`, `'HTTP_${e.status}'` |
| `lib/features/notifications/domain/entities/app_notification.dart` | `AppNotification` entity, `NotificationCategory` enum | CONDITIONAL(app has a server inbox / list screen) — network-only template | categories `order offer care reward general` |
| `lib/features/notifications/domain/repositories/notifications_repository.dart` | `getNotifications()`, `markRead(ids)` | CONDITIONAL | — |
| `lib/features/notifications/domain/usecases/get_notifications.dart` | `GetNotifications implements UseCase<List<AppNotification>, NoParams>` | CONDITIONAL | — |
| `lib/features/notifications/domain/usecases/mark_notifications_read.dart` | `MarkNotificationsReadParams({required ids})`, `MarkNotificationsRead` | CONDITIONAL | — |
| `lib/features/notifications/data/models/app_notification_model.dart` | model with `fromJson/toJson/fromEntity/toEntity`, `_parseUtc`, `_text` | CONDITIONAL | column names `id,title,body,category,created_at,read,data`; data keys `imageUrl`, `actionUrl`, `deepLink`, `url` |
| `lib/features/notifications/data/datasources/notifications_remote_data_source.dart` | PostgREST list + PATCH mark-read; `defaultLimit = 100`; `listColumns`; `_restHeaders`; `_toServerException` | CONDITIONAL | `Endpoints.appNotifications`, `Prefer: return=representation` |
| `lib/features/notifications/data/repositories/notifications_repository_impl.dart` | `const` repo, remote only; `ServerException → ServerFailure`, `ConnectionException → NetworkFailure` | CONDITIONAL (network-only repository template) | — |
| `lib/features/notifications/presentation/notifications/bloc/notifications_event.dart` | `NotificationsLoadRequested` (load, retry and pull-to-refresh are one event) | CONDITIONAL | — |
| `lib/features/notifications/presentation/notifications/bloc/notifications_state.dart` | `NotificationsStatus {initial, loading, loaded, failure}`; fields `status notifications failure isRefreshing`; `isBusy` | CONDITIONAL (network-only state template) | — |
| `lib/features/notifications/presentation/notifications/bloc/notifications_bloc.dart` | `_onLoadRequested`: busy guard, refreshing-vs-loading, keep list on failed refresh, then silent mark-read | CONDITIONAL (network-only bloc template) | — |
| `lib/features/notifications/presentation/notifications/pages/notifications_page.dart` | `BlocProvider(create: sl<NotificationsBloc>()..add(...))`, refresh-failed `SnackBar` listener, `RefreshIndicator` waiting on `!isBusy`, Skeletonizer skeleton | CONDITIONAL | keys `notifications_*`, texts |
| `lib/features/notifications/presentation/notifications/utils/notification_texts.dart` | texts, `notificationsFailureMessage(Failure?)`, `notificationTime`, `isFromToday` | CONDITIONAL | copy |
| `lib/features/notifications/presentation/notifications/widgets/notifications_header.dart` | `PageHeader` wrapper | CONDITIONAL | title/subtitle |
| `lib/features/notifications/presentation/notifications/widgets/notification_tile.dart` | `AppCard` row; tone by category | CONDITIONAL | icons/tones |

### 1.3 CACHE-FIRST (LocalCache / Hive)

| path | role | class | placeholders |
|---|---|---|---|
| `lib/features/catalog/data/datasources/catalog_local_data_source.dart` | **the reference local data source**: 3 keys, `schemaVersion = 2`, private `_read`/`_write`, `clear() => clearBox` | CONDITIONAL(app caches server data) — template | box `CacheBoxes.catalog`; keys `snapshot`, `sold_counts`, `low_stock_thresholds` |
| `lib/features/catalog/data/datasources/catalog_remote_data_source.dart` | Edge Function + PostgREST + Medusa reads; `_send`, `_rowsOf`, `_unexpected`, `_toServerException`; three header getters | MYMALI-SPECIFIC (shape ALWAYS) | `Endpoints.catalogCache/productSold/productsV2`, `MedusaEndpoints.products`, queries |
| `lib/features/catalog/data/repositories/catalog_repository_impl.dart` | **the reference cache-first repository**: `_fetchSnapshot({required refresh})` (one fetch path), `_save`, `_cached`, `_toFailure` | CONDITIONAL — template (Medusa completion logic MYMALI) | `prepareCatalog`, `buildHomeSections` |
| `lib/features/catalog/domain/repositories/catalog_repository.dart` | 4 remote + 4 `getCached…` pairs | CONDITIONAL — template | method names |
| `lib/features/catalog/domain/usecases/get_catalog.dart`, `get_cached_catalog.dart`, `get_home_sections.dart` (+`GetHomeSectionsParams`), `get_cached_home_sections.dart`, `get_sold_counts.dart`, `get_cached_sold_counts.dart`, `get_low_stock_thresholds.dart`, `get_cached_low_stock_thresholds.dart` | the paired use cases | CONDITIONAL — template | names |
| `lib/features/catalog/data/models/catalog_snapshot_model.dart` | model with `count`, `region_id`, `updated_at`, `cached` (contains stray `// ← ADD THIS` comments) | MYMALI-SPECIFIC | JSON keys |
| `lib/features/catalog/data/models/sold_count_model.dart`, `low_stock_threshold_model.dart` | row models with `static toSkuMap(rows)`; no entity of their own | MYMALI-SPECIFIC (pattern: rows → `Map<String,int>`) | `sku`, `sold_count`, `low_stock_threshold` |
| `lib/features/catalog/domain/entities/catalog_snapshot.dart` | entity (NOT const, `products` is non-final — see gotchas) | MYMALI-SPECIFIC | — |
| `lib/features/catalog/domain/utils/prepare_catalog.dart`, `build_home_sections.dart` | pure domain helpers run on BOTH the cached and the fresh model | MYMALI-SPECIFIC (pattern ALWAYS) | `comingSoonSectionTitle`, `perSection = 5` |
| `lib/features/home/presentation/home/bloc/home_bloc.dart` | **the reference cache-first bloc**: `_onHomeStarted`, `_onHomeRefreshed`, `_showCached`, `_refresh(emit, {required forceRefresh})` | CONDITIONAL — template | app-state/banners extras MYMALI |
| `lib/features/home/presentation/home/bloc/home_event.dart` | `HomeStarted({language})`, `HomeRefreshed({language})` | CONDITIONAL — template | `language` |
| `lib/features/home/presentation/home/bloc/home_state.dart` | `HomeStatus`, `isStale`, `isRefreshing`, `isLoading`, `isBusy`, `copyWith` with clearable getters | CONDITIONAL — template | extra fields |
| `lib/features/home/presentation/home/utils/failure_message.dart` | `homeFailureMessage`, `refreshFailureMessage` | CONDITIONAL — template | copy |
| `lib/features/catalog/presentation/categories/bloc/categories_bloc.dart`, `categories_event.dart`, `categories_state.dart` | second cache-first bloc (`_showCached`, `_refresh`, `_withCatalog`) | MYMALI-SPECIFIC (filters) — shows the shape with many extra fields | — |
| `lib/features/cart/data/datasources/charge_rules_local_data_source.dart` | single-key cache (`rules`), `schemaVersion = 3`, no `clear()` | CONDITIONAL — template (one entry, not user-scoped) | box `charge_rules` |
| `lib/features/cart/data/datasources/charge_rules_remote_data_source.dart` | PostgREST single row `id=eq.1`; inline error mapping; `'CHARGE_RULES_MISSING'` | MYMALI-SPECIFIC | `Endpoints.chargeRules`, `_select` |
| `lib/features/cart/data/models/charge_rules_model.dart` | model + `SmallCartTierModel` | MYMALI-SPECIFIC | — |
| `lib/features/cart/data/repositories/charge_rules_repository_impl.dart` | minimal cache-first repo (`getChargeRules`, `getCachedChargeRules`, `_save`, `_cached`) | CONDITIONAL — smallest template | — |
| `lib/features/cart/domain/repositories/charge_rules_repository.dart`, `domain/usecases/get_charge_rules.dart`, `get_cached_charge_rules.dart` | contract + paired use cases | CONDITIONAL — template | — |
| `lib/features/cart/presentation/cart/bloc/cart_page_bloc.dart`, `cart_page_event.dart`, `cart_page_state.dart` | page bloc that shows cached rules/catalog then fresh WITHOUT status/isStale fields | MYMALI-SPECIFIC (variant) | — |
| `lib/features/support/data/datasources/support_local_data_source.dart` | single key `content`, `schemaVersion = 1`, no `clear()` | CONDITIONAL(app has server-driven help content) — template | box `support` |
| `lib/features/support/data/datasources/support_remote_data_source.dart` | Edge Function POST with `requestBody`; `{support: null}` → `ServerException(code: supportNotConfiguredCode)` | MYMALI-SPECIFIC (shape ALWAYS) | `Endpoints.appState`, body keys |
| `lib/features/support/data/models/support_content_model.dart` | nested models; `isUsable` filters at `toEntity` | CONDITIONAL | `kind` names, `q`/`a` |
| `lib/features/support/data/repositories/support_repository_impl.dart` | cache-first repo (not user-scoped) | CONDITIONAL — template | `SupportUnavailableFailure` |
| `lib/features/support/domain/entities/support_content.dart`, `failures/support_failures.dart`, `repositories/support_repository.dart`, `usecases/get_support_content.dart`, `usecases/get_cached_support_content.dart` | domain | CONDITIONAL | — |
| `lib/features/support/presentation/help_support/bloc/help_support_bloc.dart`, `help_support_event.dart`, `help_support_state.dart` | cache-first bloc, compact form | CONDITIONAL — template | — |
| `lib/features/support/presentation/help_support/utils/support_texts.dart`, `pages/help_support_page.dart`, `widgets/help_support_header.dart`, `widgets/support_channels_card.dart`, `widgets/support_faq_card.dart` | page, texts, widgets (`url_launcher`) | CONDITIONAL | copy, keys `support_*` |
| `lib/features/mali_coins/data/datasources/mali_coins_local_data_source.dart` | TWO boxes in one data source: user-scoped `mali_coins` (`balance`) + config `coin_rules` (`rules`, `maxAge: MaliCoinsRepository.rulesMaxAge`); `clear()` clears only the balance box | MYMALI-SPECIFIC (pattern: user-scoped + TTL) | keys `balance`, `rules` |
| `lib/features/mali_coins/data/datasources/mali_coins_remote_data_source.dart` | one Edge Function, `action` body; `_send(body)`, `_unexpected`, `_toServerException` | MYMALI-SPECIFIC | `welcome`/`balance`/`rules` |
| `lib/features/mali_coins/data/models/coin_balance_model.dart`, `coin_rules_model.dart`, `coin_welcome_model.dart` | models | MYMALI-SPECIFIC | — |
| `lib/features/mali_coins/data/repositories/mali_coins_repository_impl.dart` | `_guard`, `_save`, `_cached`, `_toFailure`; saves the balance from EVERY answer; `getRules(refresh:)` TTL | MYMALI-SPECIFIC (pattern: `_guard` + TTL) | `notConfiguredCode = 'NOT_CONFIGURED'` |
| `lib/features/mali_coins/domain/repositories/mali_coins_repository.dart`, `usecases/claim_welcome_coins.dart`, `get_coin_balance.dart`, `get_cached_coin_balance.dart`, `get_coin_rules.dart`, `failures/mali_coins_failures.dart`, `entities/coin_balance.dart` | domain | MYMALI-SPECIFIC | `rulesMaxAge = 30 min` |
| `lib/features/mali_coins/presentation/bloc/mali_coins_bloc.dart`, `mali_coins_event.dart`, `mali_coins_state.dart` | app-wide bloc: cached balance first, then welcome claim; `_session` counter; `_reset` | MYMALI-SPECIFIC (pattern: session-guarded app-wide bloc) | — |
| `lib/features/mali_coins/presentation/coins/bloc/coins_page_bloc.dart`, `coins_page_event.dart`, `coins_page_state.dart` | page bloc: parallel rules+balance, each emitted as it lands | MYMALI-SPECIFIC | — |
| `lib/features/coupons/data/datasources/coupon_local_data_source.dart` | TTL cache: `readActive()` passes `maxAge: CouponRepository.listMaxAge` | CONDITIONAL — TTL template | box `coupons`, key `active` |
| `lib/features/coupons/data/datasources/coupon_remote_data_source.dart` | PostgREST with `and=(or(...),or(...))` date filter; `_rows`, `_send`, `_toServerException` | MYMALI-SPECIFIC | `Endpoints.coupons`, selects |
| `lib/features/coupons/data/models/coupon_model.dart` | model; `couponType` getter; `toEntity` throws on unknown type | MYMALI-SPECIFIC | — |
| `lib/features/coupons/data/repositories/coupon_repository_impl.dart` | **TTL + shared in-flight**: `_inFlight ??= _fetchActive().whenComplete(() => _inFlight = null)`; failed list never saved | CONDITIONAL — template | `CouponsUnavailableFailure` |
| `lib/features/coupons/domain/entities/coupon.dart`, `applied_coupon.dart`, `failures/coupon_failures.dart`, `repositories/coupon_repository.dart`, `usecases/get_active_coupons.dart`, `check_coupon.dart`, `utils/coupon_validation.dart`, `utils/coupon_progress.dart` | domain; `listMaxAge = 5 min` on the interface | MYMALI-SPECIFIC (constant-on-interface pattern ALWAYS) | — |
| `lib/features/coupons/presentation/bloc/coupon_bloc.dart`, `coupon_event.dart`, `coupon_state.dart` | app-wide MEMORY-ONLY bloc with `_session` counter and `_rechecked` | MYMALI-SPECIFIC (pattern: memory-only app-wide state) | — |
| `lib/features/coupons/presentation/apply_coupon/bloc/apply_coupon_bloc.dart`, `apply_coupon_event.dart`, `apply_coupon_state.dart`, `pages/apply_coupon_page.dart`, `widgets/apply_coupon_header.dart`, `coupon_code_field.dart`, `coupon_ticket_card.dart`; `presentation/utils/coupon_failure_message.dart`, `coupon_label.dart`; `presentation/widgets/coupon_row.dart` | page bloc (plain `isLoading`/`listFailure`), UI | MYMALI-SPECIFIC | — |
| `lib/features/product/data/datasources/product_local_data_source.dart` | keyed cache: `_productKey(id) => 'product.$id'`, `regionKey = 'region'` | CONDITIONAL — keyed template | box `product` |
| `lib/features/product/data/repositories/product_repository_impl.dart` | `_region()` memory → device → server; `getCachedProduct(id)` | MYMALI-SPECIFIC (pattern CONDITIONAL) | — |
| `lib/features/address/data/datasources/address_local_data_source.dart`, `data/repositories/address_repository_impl.dart` | user-scoped cache-first WITH mutations: `_updateCached(change)` after a remote save/delete | CONDITIONAL — mutation template | box `addresses`, key `addresses` |

### 1.4 DEVICE-FIRST (PrefUtils + pending flag + background push)

| path | role | class | placeholders |
|---|---|---|---|
| `lib/features/wishlist/data/datasources/wishlist_local_data_source.dart` | PrefUtils JSON under `wishlist.saved`; `readWishlist()` null when absent; `WishlistStorageException` on bad JSON / failed write | CONDITIONAL(app has a device-first user list) — template | key `wishlist.saved` |
| `lib/features/wishlist/data/datasources/wishlist_remote_data_source.dart` | Edge Function `user-data` `{kind, action}`; whole-list `replace` | MYMALI-SPECIFIC (shape ALWAYS) | `kind='wishlist'`, `list`, `replace`, `ok: true` |
| `lib/features/wishlist/data/exceptions/wishlist_exceptions.dart` | `WishlistStorageException` | CONDITIONAL — template | name |
| `lib/features/wishlist/data/models/stored_wishlist_model.dart` | `{user_id, ids, pending}` — the device shape with the pending flag | CONDITIONAL — template | — |
| `lib/features/wishlist/data/models/wishlist_model.dart` | `{ids}` — the server shape | CONDITIONAL | — |
| `lib/features/wishlist/data/repositories/wishlist_repository_impl.dart` | **the pending-flag device-first repository**: `_inOrder`, `_device`, `_onDevice`, `_waitingPush`, `_send`, `_idsOf`, `_sameIds` | CONDITIONAL — template | `WishlistRepository.maxItems = 50` |
| `lib/features/wishlist/domain/entities/wishlist_item.dart`, `failures/wishlist_failures.dart`, `repositories/wishlist_repository.dart`, `usecases/load_wishlist.dart`, `sync_wishlist.dart`, `push_wishlist.dart`, `add_to_wishlist.dart`, `remove_from_wishlist.dart`, `utils/wishlist_products.dart` | domain (5 use cases each with a `…Params({required userId…})`) | CONDITIONAL — template | — |
| `lib/features/wishlist/presentation/bloc/wishlist_bloc.dart`, `wishlist_event.dart`, `wishlist_state.dart` | app-wide device-first bloc: `_session`, `_showSaved`, `_refresh`, optimistic `_onToggled` with `pendingIds`/`toggleFailure`, `unawaited(_pushWishlist…)`, `_keepPending` | CONDITIONAL — template (catalog lookup MYMALI) | analytics event names |
| `lib/features/wishlist/presentation/utils/failure_message.dart` | `wishlistFailureMessage`, `wishlistRefreshFailureMessage`, `wishlistToggleFailureMessage` | CONDITIONAL | copy |
| `lib/features/cart/data/datasources/cart_local_data_source.dart` | PrefUtils JSON under `cart.items`; `fromLegacyJson` for a bare list; `CartStorageException` | CONDITIONAL(app has a cart) — template | key `cart.items` |
| `lib/features/cart/data/datasources/cart_remote_data_source.dart` | PostgREST upsert (`Prefer: resolution=merge-duplicates,return=minimal`) then DELETE `not.in.(…)` with `Prefer: return=representation` | MYMALI-SPECIFIC (shape: whole-list replace) | `Endpoints.cartItems`, `_select`, `on_conflict=user_id,product_id` |
| `lib/features/cart/data/exceptions/cart_exceptions.dart` | `CartStorageException` | CONDITIONAL — template | — |
| `lib/features/cart/data/models/cart_item_model.dart`, `cart_model.dart`, `server_cart_line_model.dart` | device shape (`items`, `saved_for_later`) vs server row shape | MYMALI-SPECIFIC fields; shape CONDITIONAL | JSON keys |
| `lib/features/cart/data/repositories/cart_repository_impl.dart` | **the merge device-first repository**: `_onDevice`, `_inOrder`, `_update`, `_readCart`, `_linesOf`, `_waitingPush`; `syncCart` reads `before`, merges with `deviceWins: changedVariants(earlier, now)`, `unawaited(pushCart(userId))` | CONDITIONAL — template | — |
| `lib/features/cart/domain/repositories/cart_repository.dart` | 9 methods | CONDITIONAL — template | — |
| `lib/features/cart/domain/utils/merge_cart.dart` | `mergeServerLines(local, server, {deviceWins})`, `changedVariants(before, after)` | CONDITIONAL — template (pure Dart) | — |
| `lib/features/cart/domain/utils/cart_stock.dart`, `saved_for_later.dart`; `entities/cart.dart`, `cart_item.dart`, `cart_stock_check.dart`; `failures/cart_failures.dart` | domain helpers + entities | MYMALI-SPECIFIC (stock/saved-for-later) | — |
| `lib/features/cart/domain/usecases/load_cart.dart`, `save_cart_item.dart`, `remove_cart_items.dart`, `save_for_later.dart`, `move_to_cart.dart`, `remove_saved.dart`, `sync_cart.dart`, `push_cart.dart`, `check_cart_stock.dart` | 9 use cases | CONDITIONAL — template | — |
| `lib/features/cart/presentation/bloc/cart_bloc.dart`, `cart_event.dart`, `cart_state.dart` | **the serialized device-first bloc**: `_serial`/`_queue`, `_beginSync`, `CartSyncFinished(syncId)`, `_synced`, `_changedWhileSyncing`, `_emitChange` (push only when synced), `_emitResult` | CONDITIONAL — template (stock/analytics MYMALI) | analytics event names |

### 1.5 Tests read (all under `test/`)

`test/core/services/local_cache/hive_local_cache_test.dart`; helpers `test/helpers/fake_local_cache.dart`, `fake_networking.dart`, `fake_catalog_repository.dart`, `fake_cart_repository.dart`, `fake_cart_remote_data_source.dart`, `fake_wishlist_repository.dart`, `fake_coupon_repository.dart`, `fake_support_repository.dart`, `fake_mali_coins_repository.dart`, `fake_notifications_repository.dart`, `fake_orders_repository.dart`, `fake_charge_rules_repository.dart`; feature tests `test/features/catalog/data/datasources/catalog_local_data_source_test.dart`, `catalog/data/repositories/catalog_repository_impl_test.dart`, `catalog/presentation/categories/bloc/categories_bloc_test.dart`, `home/presentation/home/bloc/home_bloc_test.dart`, `coupons/data/repositories/coupon_repository_impl_test.dart`, `coupons/data/datasources/coupon_local_data_source_test.dart`, `support/data/repositories/support_repository_impl_test.dart`, `support/data/datasources/support_local_data_source_test.dart`, `support/presentation/help_support/bloc/help_support_bloc_test.dart`, `mali_coins/data/repositories/mali_coins_repository_impl_test.dart`, `mali_coins/data/datasources/mali_coins_local_data_source_test.dart`, `mali_coins/presentation/bloc/mali_coins_bloc_test.dart`, `mali_coins/presentation/coins/bloc/coins_page_bloc_test.dart`, `wishlist/data/repositories/wishlist_repository_impl_test.dart`, `wishlist/data/datasources/wishlist_local_data_source_test.dart`, `wishlist/presentation/bloc/wishlist_bloc_test.dart`, `cart/data/repositories/cart_repository_impl_test.dart`, `cart/data/repositories/cart_repository_sync_test.dart`, `cart/data/datasources/cart_local_data_source_test.dart`, `cart/data/repositories/charge_rules_repository_impl_test.dart`, `cart/presentation/bloc/cart_bloc_test.dart`, `cart/presentation/bloc/cart_bloc_sync_test.dart`, `cart/presentation/cart/bloc/cart_page_charge_rules_test.dart`, `orders/data/repositories/orders_repository_impl_test.dart`, `notifications/presentation/notifications/bloc/notifications_bloc_test.dart`. Page tests consulted by grep only: `home/presentation/home/pages/home_page_test.dart` (uses `catalog.gate`, key `home_refreshFailedMessage`), `wishlist/presentation/pages/wishlist_page_test.dart` (`isStale`, key `wishlist_refreshFailedMessage`).

---

## 2. Names

Every public name another app must reproduce exactly. "kind" is class / enum / function /
const / key / method. Signatures are verbatim from the code.

### 2.1 Core

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `LocalCache` | abstract interface class | `lib/core/services/local_cache/local_cache.dart` | `Future<Object?> read({required String box, required String key, required int version, Duration? maxAge});` · `Future<void> write({required String box, required String key, required int version, required Object json});` · `Future<void> delete({required String box, required String key});` · `Future<void> clearBox(String box);` · `Future<void> clearUserScoped();` |
| `HiveLocalCache` | class `implements LocalCache` | `hive_local_cache.dart` | `HiveLocalCache({DateTime Function() now = DateTime.now}) : _now = now;` · `static Future<void> init()` · `static Future<void> openBoxes()` · private consts `_versionField = 'version'`, `_savedAtField = 'saved_at'`, `_dataField = 'data'` · `Box<String>? _boxOrNull(String name)` |
| `CacheBoxes` | `abstract final class` | `cache_boxes.dart` | `static const String catalog = 'catalog'; chargeRules = 'charge_rules'; addresses = 'addresses'; maliCoins = 'mali_coins'; coinRules = 'coin_rules'; coupons = 'coupons'; product = 'product'; seller = 'seller'; support = 'support';` · `static const List<String> all = [catalog, chargeRules, addresses, maliCoins, coinRules, coupons, product, seller, support];` · `static const List<String> userScoped = [addresses, maliCoins];` |
| `CacheException` | class `implements Exception` | `lib/core/app/exceptions/cache_exceptions.dart` | `const CacheException([this.message]); final String? message; toString() => 'CacheException($message)'` |
| `Failure` | class | `lib/core/app/failure.dart` | `Failure({required this.message, this.code}); final String message; final int? code;` |
| `NetworkFailure` | class extends Failure | same | `NetworkFailure({super.message = 'No internet connection.', super.code});` |
| `ServerFailure` | class extends Failure | same | `ServerFailure({required this.errorCode, super.message = 'Something went wrong.', super.code}); final String errorCode;` |
| `CacheMissFailure` | class extends Failure | same | `CacheMissFailure({super.message = 'Nothing saved on this device.'});` |
| `ServerException` | class `implements Exception` | `lib/core/app/exceptions/api_exceptions.dart` | `const ServerException({required this.code, required this.status, this.detail}); final String code; final int status; final String? detail;` |
| `ConnectionException` | class `implements Exception` | same | `const ConnectionException([this.message]); final String? message;` |
| `AppException` | class (legacy) | `lib/core/app/exceptions/app_exceptions.dart` | `AppException(this.message, this.prefix)`; subclasses `InternetException`, `RequestTimeoutException`, `ServerException` (name clash with api_exceptions — import with `show AppException`), `InvalidUrlException`, `FetchDataException`, `UnAuthorizedException`, `AuthException` |
| `SuccessResponse` | class extends APIResponse | `lib/core/app/api/api_response.dart` | `const SuccessResponse({required this.successMessage, required this.statusCode, required this.rawData, required super.data})` — `statusCode` is a `String` |
| `ErrorResponse` | class extends APIResponse | same | `const ErrorResponse({required this.errorMessage, required this.errorCode, this.rawData, required super.data})` — `errorCode` is a `String` HTTP status |
| `asDouble asInt asNumeric asString asBool asMap asMapList asStringList` | top-level functions | `lib/core/utils/json_readers.dart` | `double? asDouble(Object? v)`, `int? asInt(Object?)`, `double? asNumeric(Object?)` (num or numeric string), `String? asString(Object?)`, `bool? asBool(Object?)`, `Map<String, dynamic> asMap(Object?)` (const `{}` fallback), `List<Map<String, dynamic>> asMapList(Object?)`, `List<String> asStringList(Object?)` |
| `UseCase<T, Params>` | abstract interface class | `lib/core/usecases/usecase.dart` | `Future<Either<Failure, T>> call(Params params);` |
| `NoParams` | class extends Equatable | same | `const NoParams(); props => []` |
| `PrefUtils` | class | `lib/core/services/pref_utils.dart` | `static SharedPreferences? _sharedPreferences;` · `PrefUtils()` (kicks off `init()`) · `Future<void> init()` · `Future<bool> setString({required String key, required String value})` · `String? getString({required String key})` · `Future<bool> setJsonString({required String key, required String jsonValue})` · `String? getJsonString({required String key})` · `Future<bool> remove({required String key})` · `Future<bool> setBool({required String key, required bool value})` · `bool? getBool({required String key})` · `Future<void> clearPreferencesData()` · `Future<bool> clearAll()` · `Map<String, dynamic> getAllData()` · `String? getUserToken()` |
| `Networking` | abstract class | `lib/core/services/networking/networking.dart` | `Future<dynamic> getAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, Map<String, String>? headers, ApiHost host = ApiHost.supabase})`; `postAPICall({… dynamic data, Map<String,String>? headers, ApiHost host})`; `patchAPICall(…)`; `putAPICall(…)` (NO `headers`); `deleteAPICall({… dynamic data, Map<String,String>? headers, ApiHost host})`; `Future<APIResponse> graphqlQueryCall({required String graphqlEndpoint, required String query, Map<String,dynamic>? variables})` |
| `ApiHost` | enum | same | `supabase, medusa, koUtils, stockship` |
| `NetworkingService` | class extends BaseApiRepo implements Networking | same | `NetworkingService({this.options, SecureStorage? secureStorage})`; success = 200/201/202 only (`returnResponse`) |
| `Endpoints` | class | `lib/core/services/networking/endpoints.dart` | used here: `catalogCache = '/functions/v1/catalog-cache'`, `appState = '/functions/v1/app-state'`, `productSold = '/rest/v1/product_sold'`, `productsV2 = '/rest/v1/products_v2'`, `userData = '/functions/v1/user-data'`, `cartItems = '/rest/v1/cart_items_v2'`, `chargeRules = '/rest/v1/charge_rules'`, `maliCoins = '/functions/v1/mali-coins'`, `coupons = '/rest/v1/coupons'`, `appNotifications = '/rest/v1/app_notifications'` |
| `MedusaEndpoints.products` / `KoUtilsEndpoints.refOrders` / `StockshipEndpoints.orders` | consts | same | `'/store/products'` / `'/order/ref-orders'` / `'/api/orders'` |
| `StringConstants.appAuthToken` | const | `lib/core/utils/string_constants.dart` | `static const String appAuthToken = 'auth.access_token';` |
| `sl` | top-level | `lib/core/di/injection_container.dart` | `final GetIt sl = GetIt.instance;` |
| `configureDependencies` | function | same | `void configureDependencies()` calls `_registerCore()` then per feature `_register<Feature>Data()` + `register<Feature>Feature()` |
| `_registerCore` | private function | same | registers `SecureStorage`, `Networking`, `PrefUtils`, `LocalCache` (`registerLazySingleton<LocalCache>(HiveLocalCache.new)`), `SupabaseClient`, `KoTokenService`, `PaymentGateway`, `LocalNotificationService`, `KoEngagementService`, `AnalyticsService` |
| `AuthLocalDataSourceImpl` | class | `lib/features/auth/data/datasources/auth_local_data_source.dart` | `AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache)`; consts `accessTokenKey = StringConstants.appAuthToken`, `refreshTokenKey = 'auth.refresh_token'`, `userIdKey = 'auth.user_id'`; `clearTokens()` → deletes keys, `_removeLegacyCopy()`, `try { await _cache.clearUserScoped(); } on CacheException {}` |

### 2.2 NETWORK-ONLY

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `OrdersRepository` | abstract interface class | `lib/features/orders/domain/repositories/orders_repository.dart` | `findOrderPlacedAfter({required String phone, required DateTime placedAt})` → `Future<Either<Failure, WarehouseOrder?>>`; `getOrder({required String phone, required String orderId})` → `WarehouseOrder?`; `getOrders({required String phone, int page = 1})` → `OrdersPage`; `getRefOrder({required String refId})` → `RefOrderLookup?` |
| `OrdersRepositoryImpl` | class | `lib/features/orders/data/repositories/orders_repository_impl.dart` | `OrdersRepositoryImpl({required StockshipRemoteDataSource stockship, required RefOrderRemoteDataSource refOrders, DateTime Function() now = DateTime.now})`; private `Future<List<WarehouseOrder>> _pendingOrders(String digits)`, `Future<WarehouseOrder?> _pendingOrder(String refId, String digits)`, `static String? _tenDigits(String phone)`, `Failure _toFailure(StockshipException e) => e.status == 0 ? NetworkFailure() : ServerFailure(errorCode: 'HTTP_${e.status}', code: e.status);` |
| `NotificationCategory` | enum | `lib/features/notifications/domain/entities/app_notification.dart` | `order, offer, care, reward, general` |
| `AppNotification` | class extends Equatable | same | `const AppNotification({required this.id, required this.title, required this.createdAt, this.body, this.category = NotificationCategory.general, this.isRead = false, this.imageUrl, this.actionUrl});` |
| `NotificationsRepository` | abstract interface class | `…/domain/repositories/notifications_repository.dart` | `Future<Either<Failure, List<AppNotification>>> getNotifications();` · `Future<Either<Failure, Unit>> markRead(List<String> ids);` |
| `GetNotifications` | class | `…/domain/usecases/get_notifications.dart` | `class GetNotifications implements UseCase<List<AppNotification>, NoParams> { const GetNotifications(this._repository); … call(NoParams params) => _repository.getNotifications(); }` |
| `MarkNotificationsReadParams` | class | `…/domain/usecases/mark_notifications_read.dart` | `const MarkNotificationsReadParams({required this.ids}); final List<String> ids;` |
| `MarkNotificationsRead` | class | same | `implements UseCase<Unit, MarkNotificationsReadParams>` |
| `AppNotificationModel` | class | `…/data/models/app_notification_model.dart` | `const AppNotificationModel({required this.id, required this.title, required this.createdAt, this.body, this.category = 'general', this.read, this.data = const {}});` + `fromJson`, `fromEntity`, `toJson`, `toEntity`, `static DateTime _parseUtc(String iso)`, `static String? _text(Object? value)` |
| `NotificationsRemoteDataSource` | abstract interface class | `…/data/datasources/notifications_remote_data_source.dart` | `static const int defaultLimit = 100;` · `Future<List<AppNotificationModel>> list({int limit = defaultLimit});` · `Future<void> markRead(List<String> ids);` |
| `NotificationsRemoteDataSourceImpl` | class | same | `NotificationsRemoteDataSourceImpl({required Networking networking, required String anonKey})`; `Map<String, String> get _restHeaders => {'apikey': _anonKey};` `static const String listColumns = 'id,title,body,category,created_at,read,data';` `ServerException _toServerException(ErrorResponse response)` |
| `NotificationsRepositoryImpl` | class | `…/data/repositories/notifications_repository_impl.dart` | `const NotificationsRepositoryImpl({required NotificationsRemoteDataSource remote})` |
| `NotificationsEvent` / `NotificationsLoadRequested` | abstract class / class | `…/bloc/notifications_event.dart` | plain classes, no Equatable |
| `NotificationsStatus` | enum | `…/bloc/notifications_state.dart` | `initial, loading, loaded, failure` |
| `NotificationsState` | class extends Equatable | same | `const NotificationsState({this.status = NotificationsStatus.initial, this.notifications = const [], this.failure, this.isRefreshing = false});` `bool get isBusy => status == NotificationsStatus.loading \|\| isRefreshing;` `copyWith({NotificationsStatus? status, List<AppNotification>? notifications, Failure? Function()? failure, bool? isRefreshing})` |
| `NotificationsBloc` | class | `…/bloc/notifications_bloc.dart` | `NotificationsBloc({required GetNotifications getNotifications, required MarkNotificationsRead markNotificationsRead})`; exports event+state files |
| `notificationsFailureMessage` / `notificationTime` / `isFromToday` | functions | `…/utils/notification_texts.dart` | `String notificationsFailureMessage(Failure? failure)`; `String notificationTime(DateTime createdAt, DateTime now)`; `bool isFromToday(DateTime createdAt, DateTime now)`; consts `notificationsTitle`, `notificationsSubtitle`, `notificationsTodayLabel`, `notificationsEarlierLabel`, `notificationsEmptyTitle`, `notificationsEmptyMessage` |
| page keys | Key | `…/pages/notifications_page.dart` | `notifications_page`, `notifications_refreshFailedMessage`, `notifications_scrollView`, `notifications_tile_<id>`, `notifications_empty`, `notifications_skeleton`, `notifications_backButton` |

### 2.3 CACHE-FIRST

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `CatalogLocalDataSource` | abstract interface class | `lib/features/catalog/data/datasources/catalog_local_data_source.dart` | `Future<CatalogSnapshotModel?> readSnapshot(); Future<void> writeSnapshot(CatalogSnapshotModel snapshot); Future<List<SoldCountModel>?> readSoldCounts(); Future<void> writeSoldCounts(List<SoldCountModel> rows); Future<List<LowStockThresholdModel>?> readLowStockThresholds(); Future<void> writeLowStockThresholds(List<LowStockThresholdModel> rows); Future<void> clear();` |
| `CatalogLocalDataSourceImpl` | class | same | `const CatalogLocalDataSourceImpl(this._cache);` `static const String snapshotKey = 'snapshot'; soldCountsKey = 'sold_counts'; lowStockThresholdsKey = 'low_stock_thresholds';` `static const int schemaVersion = 2;` private `Future<Object?> _read(String key)`, `Future<void> _write(String key, Object json)`; `clear() => _cache.clearBox(CacheBoxes.catalog)` |
| `CatalogRemoteDataSource` | abstract interface class | `…/catalog_remote_data_source.dart` | `fetchSnapshot()`, `fetchSoldCounts()`, `fetchLowStockThresholds()`, `fetchProductsFromMedusa({required String regionId, String? categoryId, int limit = 100})` |
| `CatalogRemoteDataSourceImpl` | class | same | `const CatalogRemoteDataSourceImpl({required Networking networking, required String anonKey, required String medusaPublishableKey})`; `static const Map<String,String> soldCountsQuery = {'select': 'sku,sold_count', 'limit': '5000'}`; `lowStockThresholdsQuery = {'select': 'sku,low_stock_threshold', 'low_stock_threshold': 'not.is.null', 'limit': '2000'}`; getters `_edgeFunctionHeaders` (`apikey` + `Authorization: Bearer <anon>`), `_restHeaders` (`apikey`), `_medusaHeaders` (`x-publishable-api-key`); `Future<SuccessResponse> _send(Future<dynamic> Function() call)`, `List<Map<String,dynamic>> _rowsOf(SuccessResponse)`, `ServerException _unexpected(SuccessResponse)`, `ServerException _toServerException(ErrorResponse)` |
| `CatalogRepository` | abstract interface class | `…/domain/repositories/catalog_repository.dart` | `getCatalog()`, `getCachedCatalog()` → `CatalogSnapshot`; `getHomeSections(bool refresh)`, `getCachedHomeSections()` → `List<HomeSection>`; `getSoldCounts()`, `getCachedSoldCounts()`, `getLowStockThresholds()`, `getCachedLowStockThresholds()` → `Map<String, int>` |
| `CatalogRepositoryImpl` | class | `…/data/repositories/catalog_repository_impl.dart` | `const CatalogRepositoryImpl({required CatalogRemoteDataSource remote, required CatalogLocalDataSource local})`; `Future<CatalogSnapshotModel> _fetchSnapshot({required bool refresh})`; `Future<void> _save(Future<void> Function() write)`; `Future<T?> _cached<T>(Future<T?> Function() read)`; `Failure _toFailure(ServerException e)` |
| `GetCatalog`, `GetCachedCatalog` | classes | `…/domain/usecases/get_catalog.dart`, `get_cached_catalog.dart` | both `implements UseCase<CatalogSnapshot, NoParams>`, `const X(this._repository)` |
| `GetHomeSectionsParams` | class | `…/get_home_sections.dart` | `final bool refresh; const GetHomeSectionsParams({this.refresh = false});` (declared AFTER the use case in the same file) |
| `GetHomeSections` / `GetCachedHomeSections` | classes | same / `get_cached_home_sections.dart` | `UseCase<List<HomeSection>, GetHomeSectionsParams>` → `_repository.getHomeSections(params.refresh)`; cached one is `UseCase<List<HomeSection>, NoParams>` |
| `GetSoldCounts`, `GetCachedSoldCounts`, `GetLowStockThresholds`, `GetCachedLowStockThresholds` | classes | `…/domain/usecases/` | all `UseCase<Map<String, int>, NoParams>` |
| `CatalogSnapshotModel` | class | `…/data/models/catalog_snapshot_model.dart` | `const CatalogSnapshotModel({this.categories = const [], this.products = const [], this.count = 0, this.regionId, this.updatedAt, this.cached = false});` JSON keys `categories products count region_id updated_at cached` |
| `SoldCountModel` | class | `…/sold_count_model.dart` | `const SoldCountModel({this.sku, this.soldCount});` `static Map<String, int> toSkuMap(Iterable<SoldCountModel> rows) => { for (final row in rows) ?row.sku: row.soldCount ?? 0 };` |
| `LowStockThresholdModel` | class | `…/low_stock_threshold_model.dart` | `const LowStockThresholdModel({this.sku, this.lowStockThreshold});` `toSkuMap` → `{ for (final row in rows) ?row.sku: ?row.lowStockThreshold }` |
| `prepareCatalog` | function | `…/domain/utils/prepare_catalog.dart` | `CatalogSnapshot prepareCatalog(CatalogSnapshot snapshot)` |
| `buildHomeSections` / `comingSoonSectionTitle` | function / const | `…/domain/utils/build_home_sections.dart` | `List<HomeSection> buildHomeSections(List<CatalogCategory> categories, List<CatalogProduct> products, {int perSection = 5})`; `const String comingSoonSectionTitle = 'Coming Soon';` |
| `HomeStatus` | enum | `lib/features/home/presentation/home/bloc/home_state.dart` | `initial, loading, loaded, failure` |
| `HomeState` | class extends Equatable | same | `const HomeState({this.status = HomeStatus.initial, this.sections = const [], this.appState, this.banners = const [], this.soldBySku = const {}, this.lowStockThresholdBySku = const {}, this.isStale = false, this.isRefreshing = false, this.failure});` `bool get isLoading => status == HomeStatus.loading; bool get isBusy => isLoading \|\| isRefreshing;` copyWith with `AppState? Function()? appState` and `Failure? Function()? failure` |
| `HomeEvent` / `HomeStarted` / `HomeRefreshed` | classes | `home_event.dart` | `HomeStarted({this.language}); final String? language;` `HomeRefreshed({this.language});` |
| `HomeBloc` | class | `home_bloc.dart` | `HomeBloc({required GetHomeSections getHomeSections, required GetCachedHomeSections getCachedHomeSections, required GetAppState getAppState, required GetSoldCounts getSoldCounts, required GetCachedSoldCounts getCachedSoldCounts, required GetLowStockThresholds getLowStockThresholds, required GetCachedLowStockThresholds getCachedLowStockThresholds, String imageBaseUrl = ''})`; handlers `_onHomeStarted`, `_onHomeRefreshed`, `Future<void> _showCached(Emitter<HomeState> emit)`, `Future<void> _refresh(Emitter<HomeState> emit, {required bool forceRefresh})` |
| `homeFailureMessage` / `refreshFailureMessage` | functions | `lib/features/home/presentation/home/utils/failure_message.dart` | `String homeFailureMessage(Failure? failure)`; `String refreshFailureMessage(Failure? failure)` → `NetworkFailure() => 'No internet connection. Showing saved products.'`, `_ => "Couldn't refresh right now. Showing saved products."` |
| `CategoriesBloc` | class | `lib/features/catalog/presentation/categories/bloc/categories_bloc.dart` | `CategoriesBloc({required GetCatalog getCatalog, required GetCachedCatalog getCachedCatalog, required GetSoldCounts getSoldCounts, required GetCachedSoldCounts getCachedSoldCounts})`; `_onStarted`, `_onRefreshed`, `_showCached`, `_refresh`, `CategoriesState _withCatalog(CatalogSnapshot snapshot, {required bool isStale})` |
| `CategoriesStarted` | class | `categories_event.dart` | `CategoriesStarted({this.categoryName, this.stockFilter, this.showSearch = false});` plus `CategoriesRefreshed`, `CategorySelected(this.categoryId)`, `CategorySelectedByName(this.name)`, filter events |
| `CategoriesStatus` / `CategoriesState` | enum / class | `categories_state.dart` | `initial, loading, loaded, failure`; state has `isStale`, `isRefreshing`, `failure`, `isLoading`, `isBusy` like `HomeState` |
| `ChargeRulesLocalDataSource` / `…Impl` | interface / class | `lib/features/cart/data/datasources/charge_rules_local_data_source.dart` | `Future<ChargeRulesModel?> readRules(); Future<void> writeRules(ChargeRulesModel rules);` · `const ChargeRulesLocalDataSourceImpl(this._cache); static const String rulesKey = 'rules'; static const int schemaVersion = 3;` |
| `ChargeRulesRemoteDataSource` / `…Impl` | interface / class | `charge_rules_remote_data_source.dart` | `Future<ChargeRulesModel> fetchChargeRules();` · `const ChargeRulesRemoteDataSourceImpl({required Networking networking, required String anonKey})`; query `{'select': _select, 'id': 'eq.1'}`; empty rows → `ServerException(code: 'CHARGE_RULES_MISSING', status: 200)` |
| `ChargeRulesRepository` / `ChargeRulesRepositoryImpl` | interface / class | `…/domain/repositories/charge_rules_repository.dart`, `…/data/repositories/charge_rules_repository_impl.dart` | `getChargeRules()`, `getCachedChargeRules()` → `Future<Either<Failure, ChargeRules>>`; `const ChargeRulesRepositoryImpl({required ChargeRulesRemoteDataSource remote, required ChargeRulesLocalDataSource local})` with `_save`, `_cached` |
| `GetChargeRules` / `GetCachedChargeRules` | classes | `…/domain/usecases/` | `UseCase<ChargeRules, NoParams>` |
| `CartPageBloc` | class | `lib/features/cart/presentation/cart/bloc/cart_page_bloc.dart` | `CartPageBloc({required GetCatalog getCatalog, required GetCachedCatalog getCachedCatalog, required GetChargeRules getChargeRules, required GetCachedChargeRules getCachedChargeRules})`; events `CartPageStarted({required items, required savedForLater})`, `CartPageCartChanged({…})`; state `CartPageState({catalog, recommendations, chargeRules, catalogIsCurrent})` |
| `SupportLocalDataSource` / `…Impl` | interface / class | `lib/features/support/data/datasources/support_local_data_source.dart` | `Future<SupportContentModel?> readSupport(); Future<void> writeSupport(SupportContentModel content);` · `const SupportLocalDataSourceImpl(this._cache); static const String contentKey = 'content'; static const int schemaVersion = 1;` |
| `supportNotConfiguredCode` | const | `support_remote_data_source.dart` | `const String supportNotConfiguredCode = 'NOT_CONFIGURED';` |
| `SupportRemoteDataSource` / `…Impl` | interface / class | same | `Future<SupportContentModel> fetchSupport();` · `const SupportRemoteDataSourceImpl({required Networking networking, required String anonKey})`; `static const Map<String, dynamic> requestBody = {'platform': 'app', 'surfaces': <String>[], 'include_support': true};` `Map<String, String> get _edgeFunctionHeaders => {'apikey': _anonKey};` |
| `SupportContentModel` / `SupportChannelModel` / `SupportFaqModel` | classes | `support_content_model.dart` | `const SupportContentModel({this.intro = '', this.channels = const [], this.faqs = const []})`; channel `{kind,label,value,url}` with `bool get isUsable => value.isNotEmpty && url.isNotEmpty`; faq `{q, a}` with `isUsable` |
| `SupportChannelKind` / `SupportChannel` / `SupportFaq` / `SupportContent` | enum / classes | `…/domain/entities/support_content.dart` | `email, phone, whatsapp`; `const SupportChannel({required this.kind, required this.value, required this.url, this.label = ''})`; `const SupportContent({this.intro = '', this.channels = const [], this.faqs = const []}); bool get isEmpty => channels.isEmpty && faqs.isEmpty;` |
| `SupportUnavailableFailure` | class | `…/domain/failures/support_failures.dart` | `SupportUnavailableFailure({super.message = 'Support details are not available.', super.code});` |
| `SupportRepository` / `SupportRepositoryImpl` | interface / class | `…/domain/repositories/support_repository.dart`, `…/data/repositories/support_repository_impl.dart` | `getSupportContent()`, `getCachedSupportContent()`; `const SupportRepositoryImpl({required SupportRemoteDataSource remote, required SupportLocalDataSource local})` |
| `GetSupportContent` / `GetCachedSupportContent` | classes | `…/domain/usecases/` | `UseCase<SupportContent, NoParams>` |
| `HelpSupportBloc` | class | `…/presentation/help_support/bloc/help_support_bloc.dart` | `HelpSupportBloc({required GetCachedSupportContent getCachedSupportContent, required GetSupportContent getSupportContent})`; `on<HelpSupportRefreshed>((event, emit) => _refresh(emit));` |
| `HelpSupportStarted` / `HelpSupportRefreshed` | classes | `help_support_event.dart` | plain |
| `HelpSupportStatus` / `HelpSupportState` | enum / class | `help_support_state.dart` | `initial, loading, loaded, failure`; `const HelpSupportState({this.status = HelpSupportStatus.initial, this.content = const SupportContent(), this.failure, this.isStale = false, this.isRefreshing = false});` |
| `supportLoadFailureMessage`, `supportUnavailableMessage`, `supportRefreshFailedMessage`, `supportOpenFailedMessage`, `supportChannelIcon` | functions/consts | `…/utils/support_texts.dart` | `String supportLoadFailureMessage(Failure? failure)`; `const String supportRefreshFailedMessage = "Couldn't refresh support details. Showing the last saved ones.";` |
| `MaliCoinsLocalDataSource` / `…Impl` | interface / class | `lib/features/mali_coins/data/datasources/mali_coins_local_data_source.dart` | `Future<int?> readBalance(); Future<void> writeBalance(int balance); Future<CoinRulesModel?> readRules(); Future<void> writeRules(CoinRulesModel rules); Future<void> clear();` · `const MaliCoinsLocalDataSourceImpl(this._cache); static const String balanceKey = 'balance'; static const String rulesKey = 'rules'; static const int schemaVersion = 1;` balance stored as `{balanceKey: balance}`; `readRules` passes `maxAge: MaliCoinsRepository.rulesMaxAge`; `clear() => _cache.clearBox(CacheBoxes.maliCoins)` |
| `MaliCoinsRemoteDataSource` / `…Impl` | interface / class | `mali_coins_remote_data_source.dart` | `claimWelcome()`, `fetchBalance()`, `fetchRules()`; `static const String welcomeAction = 'welcome'; balanceAction = 'balance'; rulesAction = 'rules';` `Future<SuccessResponse> _send(Map<String, dynamic> body)` |
| `MaliCoinsRepository` | abstract interface class | `…/domain/repositories/mali_coins_repository.dart` | `static const Duration rulesMaxAge = Duration(minutes: 30);` `claimWelcome()` → `CoinWelcome`; `getBalance()` → `CoinBalance`; `getCachedBalance()` → `int`; `getRules({required bool refresh})` → `CoinRules` |
| `MaliCoinsRepositoryImpl` | class | `…/data/repositories/mali_coins_repository_impl.dart` | `MaliCoinsRepositoryImpl({required MaliCoinsRemoteDataSource remote, required MaliCoinsLocalDataSource local})`; `static const String notConfiguredCode = 'NOT_CONFIGURED';` `Future<Either<Failure, T>> _guard<T>(Future<T> Function() call)`, `_save`, `_cached`, `Failure _toFailure(ServerException e)` |
| `ClaimWelcomeCoins`, `GetCoinBalance`, `GetCachedCoinBalance`, `GetCoinRules` + `GetCoinRulesParams` | classes | `…/domain/usecases/` | `GetCachedCoinBalance implements UseCase<int, NoParams>`; `const GetCoinRulesParams({this.refresh = false});` |
| `CoinsUnavailableFailure` / `CoinsAuthRequiredFailure` | classes | `…/domain/failures/mali_coins_failures.dart` | `CoinsUnavailableFailure({super.message = 'Mali Coins are unavailable right now.', super.code});` `CoinsAuthRequiredFailure({super.message = 'Sign in to see your Mali Coins.', super.code});` |
| `MaliCoinsBloc` | class | `…/presentation/bloc/mali_coins_bloc.dart` | `MaliCoinsBloc({required ClaimWelcomeCoins claimWelcome, required GetCachedCoinBalance getCachedBalance})`; `int _session = 0;` `_onStarted`, `_onBalanceChanged`, `_onSpent`, `_onCleared`, `void _reset(Emitter<MaliCoinsState> emit)` |
| `MaliCoinsStarted` / `MaliCoinsBalanceChanged(this.balance)` / `MaliCoinsSpent(this.coins)` / `MaliCoinsCleared` | classes | `mali_coins_event.dart` | plain |
| `MaliCoinsState` | class extends Equatable | `mali_coins_state.dart` | `const MaliCoinsState({this.balance}); final int? balance; copyWith({int? Function()? balance})` |
| `CoinsPageBloc` / `CoinsPageStarted` / `CoinsPageRefreshed` / `CoinsPageStatus` / `CoinsPageState` | classes | `…/presentation/coins/bloc/` | `CoinsPageBloc({required GetCoinRules getRules, required GetCoinBalance getBalance})`; `Future<void> _load(Emitter emit, {required bool refreshRules})`; `CoinRules? _nextRules(Either<Failure, CoinRules> result)`; state `{status, detail, rules, isRefreshing, failure}`, `history` getter |
| `CouponLocalDataSource` / `…Impl` | interface / class | `lib/features/coupons/data/datasources/coupon_local_data_source.dart` | `Future<List<CouponModel>?> readActive(); Future<void> writeActive(List<CouponModel> coupons); Future<void> clear();` · `const CouponLocalDataSourceImpl(this._cache); static const String activeKey = 'active'; static const int schemaVersion = 1;` `clear() => _cache.delete(box: CacheBoxes.coupons, key: activeKey)` |
| `CouponRemoteDataSource` / `…Impl` | interface / class | `coupon_remote_data_source.dart` | `Future<List<CouponModel>> fetchActive(DateTime now); Future<CouponModel?> fetchByCode(String code);` · `const CouponRemoteDataSourceImpl({required Networking networking, required String anonKey})`; private `_listSelect`, `_checkSelect`, `List<CouponModel> _rows(SuccessResponse)`, `_send`, `_toServerException` |
| `CouponModel` | class | `coupon_model.dart` | `const CouponModel({required this.code, required this.type, required this.value, this.minSubtotal = 0, this.description, this.startsAt, this.endsAt, this.prepaidOnly = false, this.flatTotal});` `CouponType? get couponType => CouponType.tryParse(type);` `toEntity()` throws `StateError` on unknown type |
| `CouponRepository` | abstract interface class | `…/domain/repositories/coupon_repository.dart` | `static const Duration listMaxAge = Duration(minutes: 5);` `getActiveCoupons({required bool refresh})` → `List<Coupon>`; `checkCoupon({required String code, required double subtotal})` → `AppliedCoupon` |
| `CouponRepositoryImpl` | class | `…/data/repositories/coupon_repository_impl.dart` | `CouponRepositoryImpl({required CouponRemoteDataSource remote, required CouponLocalDataSource local, DateTime Function() now = DateTime.now})`; `Future<Either<Failure, List<Coupon>>>? _inFlight;` `Future<Either<Failure, List<Coupon>>> _fetchActive()`, `List<Coupon> _toEntities(List<CouponModel> rows)`, `_save`, `_cached` |
| `GetActiveCouponsParams` / `GetActiveCoupons` / `CheckCouponParams` / `CheckCoupon` | classes | `…/domain/usecases/` | `const GetActiveCouponsParams({this.refresh = false});` `const CheckCouponParams({required this.code, required this.subtotal});` |
| `CouponType` / `Coupon` / `AppliedCoupon` | enum / classes | `…/domain/entities/` | `enum CouponType { fixed, percentage; static CouponType? tryParse(String? value) }`; `Coupon.discountFor(double subtotal)`; `AppliedCoupon.of(Coupon coupon, double subtotal)` |
| coupon failures | classes | `…/domain/failures/coupon_failures.dart` | `CouponsUnavailableFailure({message = 'No coupons right now.', code})`, `CouponCodeEmptyFailure`, `CouponCheckFailure({code})`, `InvalidCouponFailure`, `CouponNotStartedFailure`, `CouponExpiredFailure`, `CouponMinSubtotalFailure({required this.couponCode, required this.shortfall, …})` |
| `normalizeCouponCode` / `couponGapFor` / `validateCoupon` | functions | `…/domain/utils/coupon_validation.dart` | `String normalizeCouponCode(String input) => input.trim().toUpperCase();` `int couponGapFor(Coupon coupon, double subtotal)`; `Either<Failure, AppliedCoupon> validateCoupon(Coupon coupon, double subtotal, DateTime now)` |
| `CouponOpportunity` / `bestUnlocked` / `nextToUnlock` | class / functions | `…/domain/utils/coupon_progress.dart` | `CouponOpportunity? bestUnlocked(List<Coupon> coupons, double subtotal)`; `nextToUnlock(...)` |
| `CouponBloc` | class | `…/presentation/bloc/coupon_bloc.dart` | `CouponBloc({required CheckCoupon checkCoupon, AnalyticsService? analytics, DateTime Function() now = DateTime.now})`; `int _session = 0;` `CouponState _rechecked(CouponState from, Coupon coupon, double subtotal)` |
| coupon events | classes | `coupon_event.dart` | `CouponApplied(this.code)`, `CouponRemoved`, `CouponCartChanged(this.subtotal)`, `CouponDroppedByServer(this.warning)`, `CouponCleared`, `CouponFailureDismissed` |
| `CouponState` | class | `coupon_state.dart` | `const CouponState({this.applied, this.isApplying = false, this.failure, this.serverWarning, this.subtotal = 0});` getters `hasCoupon`, `discount`; copyWith with three clearable getters |
| `ApplyCouponBloc` / events / `ApplyCouponState` | classes | `…/apply_coupon/bloc/` | `ApplyCouponBloc({required GetActiveCoupons getActiveCoupons})`; `ApplyCouponStarted(this.subtotal)`, `ApplyCouponCodeChanged(this.code)`, `ApplyCouponCartChanged(this.subtotal)`; state `{code, subtotal, coupons, isLoading, listFailure}` with `canSubmit`, `gapFor(coupon)` |
| `couponFailureMessage` / `couponLabel` | functions | `…/presentation/utils/` | `String couponFailureMessage(Failure failure)` (non-null param); `String couponLabel(Coupon coupon)` |
| `ProductLocalDataSource` / `…Impl` | interface / class | `lib/features/product/data/datasources/product_local_data_source.dart` | `readProduct(String productId)`, `writeProduct(ProductDetailModel)`, `readRegionId()`, `writeRegionId(String)`; `static const String regionKey = 'region'; static const int schemaVersion = 1; static String _productKey(String productId) => 'product.$productId';` |
| `AddressLocalDataSourceImpl` / `AddressRepositoryImpl._updateCached` | class / method | `lib/features/address/data/...` | `static const String addressesKey = 'addresses'; schemaVersion = 1; clear() => clearBox(CacheBoxes.addresses)`; `Future<void> _updateCached(List<SavedAddress> Function(List<SavedAddress>) change)` |

### 2.4 DEVICE-FIRST

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `WishlistLocalDataSource` / `…Impl` | interface / class | `lib/features/wishlist/data/datasources/wishlist_local_data_source.dart` | `Future<StoredWishlistModel?> readWishlist(); Future<void> writeWishlist(StoredWishlistModel wishlist);` · `WishlistLocalDataSourceImpl(this._prefs); static const String wishlistKey = 'wishlist.saved';` (NOT const ctor; `await _prefs.init()` before each read/write) |
| `WishlistRemoteDataSource` / `…Impl` | interface / class | `wishlist_remote_data_source.dart` | `Future<WishlistModel> fetchWishlist(); Future<void> replaceWishlist(WishlistModel wishlist);` · `const WishlistRemoteDataSourceImpl({required Networking networking, required String anonKey})`; `static const String kind = 'wishlist'; listAction = 'list'; replaceAction = 'replace';` `Future<SuccessResponse> _send(Map<String, dynamic> body)`; replace requires `body['ok'] == true` |
| `WishlistStorageException` | class | `…/data/exceptions/wishlist_exceptions.dart` | `const WishlistStorageException([this.message]);` |
| `StoredWishlistModel` | class | `…/data/models/stored_wishlist_model.dart` | `const StoredWishlistModel({required this.userId, this.ids = const [], this.pending = false});` `factory StoredWishlistModel.fromEntity(List<WishlistItem> items, {required String userId, bool pending = false})`; JSON `{'user_id', 'ids', 'pending'}`; `List<WishlistItem> toEntity()` |
| `WishlistModel` | class | `wishlist_model.dart` | `const WishlistModel({this.ids = const []});` JSON `{'ids': ids}` |
| `WishlistItem` | class extends Equatable | `…/domain/entities/wishlist_item.dart` | `const WishlistItem({required this.productId});` |
| wishlist failures | classes | `…/domain/failures/wishlist_failures.dart` | `WishlistAuthRequiredFailure({super.message = 'Sign in to use your wishlist.', super.code})`, `WishlistFullFailure({super.message = 'Your wishlist is full.'})`, `WishlistStorageFailure({super.message = 'Could not update the wishlist.', super.code})` |
| `WishlistRepository` | abstract interface class | `…/domain/repositories/wishlist_repository.dart` | `static const int maxItems = 50;` `loadWishlist(String userId)`, `syncWishlist(String userId)`, `pushWishlist(String userId)` → `Unit`, `addToWishlist(String userId, String productId)`, `removeFromWishlist(String userId, String productId)` — all list-returning ones → `Future<Either<Failure, List<WishlistItem>>>` |
| `WishlistRepositoryImpl` | class | `…/data/repositories/wishlist_repository_impl.dart` | `WishlistRepositoryImpl({required WishlistRemoteDataSource remote, required WishlistLocalDataSource local})`; fields `Future<void> _lastCall = Future.value(); Future<void> _lastWrite = Future.value(); Future<Either<Failure, Unit>>? _waitingPush; String? _waitingUserId;`; private `Future<List<String>> _send(String userId, List<String> ids)`, `static List<String> _idsOf(StoredWishlistModel? stored, String userId)`, `static List<WishlistItem> _items(List<String> ids)`, `static bool _sameIds(List<String> a, List<String> b)`, `Future<T> _device<T>(Future<T> Function() call)`, `Future<Either<Failure, List<WishlistItem>>> _onDevice(Future<List<String>> Function() call)`, `Future<Either<Failure, T>> _inOrder<T>(Future<T> Function() call)`, `Failure _toFailure(ServerException e)`; file-private `class _WishlistFullException implements Exception` |
| `LoadWishlistParams`/`LoadWishlist`, `SyncWishlistParams`/`SyncWishlist`, `PushWishlistParams`/`PushWishlist`, `AddToWishlistParams`/`AddToWishlist`, `RemoveFromWishlistParams`/`RemoveFromWishlist` | classes | `…/domain/usecases/` | params: `const XParams({required this.userId})`; add/remove: `const XParams({required this.userId, required this.productId})`; `PushWishlist implements UseCase<Unit, PushWishlistParams>` |
| `wishlistProducts` | function | `…/domain/utils/wishlist_products.dart` | `List<CatalogProduct> wishlistProducts(List<WishlistItem> items, CatalogSnapshot? catalog)` |
| `WishlistBloc` | class | `…/presentation/bloc/wishlist_bloc.dart` | `WishlistBloc({required LoadWishlist loadWishlist, required SyncWishlist syncWishlist, required PushWishlist pushWishlist, required AddToWishlist addToWishlist, required RemoveFromWishlist removeFromWishlist, required GetCatalog getCatalog, required GetCachedCatalog getCachedCatalog, AnalyticsService? analytics})`; `int _session = 0; String? _userId;` methods `_onStarted`, `_onRefreshed`, `_onCleared`, `void _reset(Emitter emit)`, `Future<void> _showSaved(Emitter emit, int session, String userId)`, `Future<void> _refresh(Emitter emit, int session, {required bool freshCatalog})`, `_onToggled`, `Future<Either<Failure, CatalogSnapshot>> _loadCatalog({required bool fresh})`, `_ensureCatalogHas(String productId, Emitter emit, int session)`, `List<WishlistItem> _keepPending(List<WishlistItem> fresh)`, `static _without(items, id)`, `static _restored(items, id, index)` |
| wishlist events | classes | `wishlist_event.dart` | `WishlistStarted(this.userId)`, `WishlistRefreshed`, `WishlistToggled(this.productId)`, `WishlistCleared` |
| `WishlistStatus` / `WishlistState` | enum / class | `wishlist_state.dart` | `initial, loading, loaded, failure`; **non-const** ctor `WishlistState({this.status = WishlistStatus.initial, this.items = const [], this.pendingIds = const {}, this.catalog, this.isStale = false, this.isRefreshing = false, this.failure, this.toggleFailure}) : ids = {for (final item in items) item.productId}, products = wishlistProducts(items, catalog);` getters `isLoading`, `isBusy`, `count`, `contains(productId)`, `categoryNameOf(product)`; props include derived `ids`, `products` |
| `wishlistFailureMessage` / `wishlistRefreshFailureMessage` / `wishlistToggleFailureMessage` | functions | `…/presentation/utils/failure_message.dart` | each `String f(Failure? failure)`; refresh: `NetworkFailure() => 'No internet connection. Showing your saved wishlist.'` |
| `CartLocalDataSource` / `…Impl` | interface / class | `lib/features/cart/data/datasources/cart_local_data_source.dart` | `Future<CartModel> readCart(); Future<void> writeCart(CartModel cart);` · `CartLocalDataSourceImpl(this._prefs); static const String itemsKey = 'cart.items';` (read returns `const CartModel()` when absent; `List` → `CartModel.fromLegacyJson`) |
| `CartRemoteDataSource` / `…Impl` | interface / class | `cart_remote_data_source.dart` | `Future<List<ServerCartLineModel>> fetchLines(); Future<void> replaceLines({required String userId, required List<ServerCartLineModel> lines});` · `const CartRemoteDataSourceImpl({required Networking networking, required String anonKey})`; `static const String _mergeHeader = 'resolution=merge-duplicates,return=minimal'; _returnHeader = 'return=representation'; _select = 'product_id,qty,name,display_name,hero_image,seed_type,variant_label,web_price,mrp';` |
| `CartStorageException` | class | `…/data/exceptions/cart_exceptions.dart` | `const CartStorageException([this.message]);` |
| `CartItemModel` | class | `…/data/models/cart_item_model.dart` | `const CartItemModel({required this.productId, required this.variantId, required this.title, required this.unitPrice, required this.quantity, this.variantLabel, this.thumbnail, double? mrp}) : mrp = mrp ?? unitPrice;` JSON `product_id variant_id title variant_label thumbnail unit_price mrp quantity` |
| `CartModel` | class | `cart_model.dart` | `const CartModel({this.items = const [], this.savedForLater = const []});` `fromJson`, `factory CartModel.fromLegacyJson(List<dynamic> json)`, `fromEntity`, `toJson` → `{'items', 'saved_for_later'}`, `toEntity`, `static List<CartItemModel> _lines(Object? json)` |
| `ServerCartLineModel` | class | `server_cart_line_model.dart` | `const ServerCartLineModel({required this.variantId, required this.qty, required this.title, this.thumbnail, this.variantLabel, required this.unitPrice, required this.mrp});` `toEntity()` sets `productId: ''` |
| `Cart` / `CartItem` | classes extends Equatable | `…/domain/entities/` | `const Cart({this.items = const [], this.savedForLater = const []});` `CartItem({required productId, required variantId, required title, required unitPrice, required quantity, variantLabel, thumbnail, double? mrp}) : mrp = mrp ?? unitPrice;` getters `lineTotal lineMrp savings discountPercent`; `copyWith({int? quantity, double? unitPrice, double? mrp})` |
| `CartStockCheck` / `CartStockChanges` / `CartPriceChange` | classes | `cart_stock_check.dart` | `const CartStockCheck({required this.cart, this.changes = const CartStockChanges(), this.limits = const {}});` |
| `CartStorageFailure` | class | `…/domain/failures/cart_failures.dart` | `CartStorageFailure({super.message = 'Could not update the cart.', super.code});` |
| `CartRepository` | abstract interface class | `…/domain/repositories/cart_repository.dart` | `syncCart(String userId)` → `Cart`; `pushCart(String userId)` → `Unit`; `loadCart()`; `saveItem(CartItem item)`; `removeItems(List<String> variantIds)`; `saveForLater(String variantId)`; `moveToCart(String variantId)`; `removeSaved(String variantId)`; `checkStock(List<CatalogProduct> products)` → `CartStockCheck` |
| `CartRepositoryImpl` | class | `…/data/repositories/cart_repository_impl.dart` | `CartRepositoryImpl({required CartLocalDataSource local, required CartRemoteDataSource remote})`; fields `Future<void> _lastCall = Future.value(); Future<void> _lastDeviceCall = Future.value(); Future<Either<Failure, Unit>>? _waitingPush; String? _waitingUserId;`; private `Future<Either<Failure, Cart>> _update(Cart Function(Cart cart) change)`, `Future<Cart> _readCart()`, `Future<T> _onDevice<T>(Future<T> Function() call)`, `List<ServerCartLineModel> _linesOf(Cart cart)`, `Future<Either<Failure, T>> _inOrder<T>(Future<T> Function() call)` |
| `mergeServerLines` / `changedVariants` | functions | `…/domain/utils/merge_cart.dart` | `Cart mergeServerLines(Cart local, List<CartItem> server, {Set<String> deviceWins = const {}})`; `Set<String> changedVariants(Cart before, Cart after)` |
| `checkCartStock` / `cartStockLimits` | functions | `cart_stock.dart` | `CartStockCheck checkCartStock(Cart cart, List<CatalogProduct> products)`; `Map<String, int> cartStockLimits(List<CatalogProduct> products)` |
| `saveLineForLater` / `moveSavedLineToCart` / `removeSavedLine` | functions | `saved_for_later.dart` | each `Cart f(Cart cart, String variantId)` |
| cart use cases | classes | `…/domain/usecases/` | `LoadCart` (`UseCase<Cart, NoParams>`), `SaveCartItem` (`UseCase<Cart, CartItem>` — entity as params), `RemoveCartItemsParams(this.variantIds)` positional, `SaveForLaterParams({required this.variantId})`, `MoveToCartParams({required variantId})`, `RemoveSavedParams({required variantId})`, `SyncCartParams({required this.userId})`, `PushCartParams({required this.userId})`, `CheckCartStockParams({required this.products})` |
| `CartBloc` | class | `…/presentation/bloc/cart_bloc.dart` | `CartBloc({required LoadCart loadCart, required SaveCartItem saveCartItem, required SaveForLater saveForLater, required MoveToCart moveToCart, required RemoveSaved removeSaved, required RemoveCartItems removeCartItems, required SyncCart syncCart, required PushCart pushCart, required CheckCartStock checkCartStock, AnalyticsService? analytics})`; `Future<void> _queue = Future.value(); Future<void> _serial(Future<void> Function() handler)`; `String? _userId; bool _synced = false; String? _syncingUserId; int _syncCount = 0; bool _changedWhileSyncing = false;` methods `_onStarted`, `_onSignedIn`, `void _beginSync(String userId)`, `_onSyncFinished`, `_onSignedOut`, `_onItemAdded`, `_onItemIncremented`, `int? _limitOf(String variantId, int? shown)`, `_onItemDecremented`, `_onItemRemoved`, `_onItemsRemoved`, `_onItemSavedForLater`, `_onSavedItemMovedToCart`, `_onSavedItemRemoved`, `_onStockChecked`, `void _reportQuantity(CartItem item, int before)`, `bool _isSaved(String variantId)`, `Future<void> _save(CartItem item, Emitter emit)`, `void _emitChange(Either<Failure, Cart> result, Emitter emit)`, `void _emitResult(Either<Failure, Cart> result, Emitter emit)` |
| cart events | classes | `cart_event.dart` | `CartStarted`, `CartSignedIn(this.userId)`, `CartSyncFinished(this.userId, this.result, {required this.syncId})` (`Either<Failure, Cart> result`), `CartSignedOut`, `CartItemAdded(this.item, {this.maxQuantity})`, `CartItemIncremented(this.variantId, {this.maxQuantity})`, `CartItemDecremented(this.variantId)`, `CartItemRemoved(this.variantId)`, `CartItemsRemoved(this.variantIds)`, `CartItemSavedForLater(this.variantId)`, `SavedItemMovedToCart(this.variantId)`, `SavedItemRemoved(this.variantId)`, `CartStockChecked(this.products)`, `CartStockChangesSeen` |
| `CartStatus` / `CartState` | enum / class | `cart_state.dart` | `initial, loading, ready, failure` (note `ready`, not `loaded`); `const CartState({this.status = CartStatus.initial, this.items = const [], this.savedForLater = const [], this.failure, this.stockLimits = const {}, this.stockChanges});` getters `canIncrement(variantId)`, `totalQuantity`, `subtotal`, `itemSavings`, `isEmpty`, `savedCount`, `quantityOf(variantId)`, `itemFor(variantId)`, `thumbnails` |

### 2.5 App wiring (DI, app.dart, bootstrap)

| name | kind | file | exact shape |
|---|---|---|---|
| `_registerCatalogData` / `registerCatalogFeature` | functions | `lib/core/di/injection_container.dart` | see section 3.C.8 (verbatim) |
| `registerHomeFeature({String imageBaseUrl = ''})` / `registerCategoriesFeature()` | functions | same | factories for `HomeBloc`, `CategoriesBloc` |
| `_registerCartData` / `registerCartFeature` | functions | same | cart + charge-rules data; 11 use cases; `CartBloc` and `CartPageBloc` factories |
| `_registerWishlistData` / `registerWishlistFeature` | functions | same | 5 use cases + `WishlistBloc` factory |
| `_registerMaliCoinsData` / `registerMaliCoinsFeature` | functions | same | 4 use cases + `MaliCoinsBloc`, `CoinsPageBloc` |
| `_registerCouponsData` / `registerCouponsFeature` | functions | same | `GetActiveCoupons`, `CheckCoupon`, `CouponBloc`, `ApplyCouponBloc` |
| `_registerOrdersData` / `registerOrdersFeature` | functions | same | `StockshipRemoteDataSourceImpl(networking, tokens, mktpId: Env.mktpId)`, `RefOrderRemoteDataSourceImpl(networking, tokens)`, `OrdersRepositoryImpl(stockship, refOrders)` |
| `_registerNotificationsData` / `registerNotificationsFeature` | functions | same | remote + repo; `GetNotifications`, `MarkNotificationsRead`, `NotificationsBloc` |
| `_registerSupportData` / `registerSupportFeature` | functions | same | remote + local + repo; `GetSupportContent`, `GetCachedSupportContent`, `HelpSupportBloc` |
| `App` | class | `lib/app/app.dart` | `const App({super.key, required this.router}); static const double maxTextScaleFactor = 1.1;` `MultiBlocProvider` → `AuthBloc`, `ThemeBloc`, `CartBloc` (`lazy: false`, `..add(CartStarted())`), `WishlistBloc`, `LocationBloc`, `MaliCoinsBloc`, `ProfileBloc`, `CouponBloc` (`lazy: false`), `RepositoryProvider<KoEngagementService>`, `RepositoryProvider<AnalyticsService>` |
| `bootstrap` | function | `lib/app/bootstrap.dart` | `Future<void> bootstrap()`: `WidgetsFlutterBinding.ensureInitialized()` → portrait → `Env.load()` → `_initFirebase()` → `DeviceSecureStorage.init()` → `Supabase.initialize(...)` → `await HiveLocalCache.init()` → `configureDependencies()` → `unawaited(_initEngagement())` → `runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router))` |

### 2.6 Test helpers (names tests depend on)

| name | file | shape |
|---|---|---|
| `FakeLocalCache` | `test/helpers/fake_local_cache.dart` | `FakeLocalCache({DateTime? now})` (default `DateTime.utc(2026, 10, 1)`); `DateTime now; CacheException? readError; CacheException? writeError; int clearUserScopedCalls = 0; List<String> keysOf(String box)`; values round-trip through `jsonEncode`/`jsonDecode`; version mismatch deletes; `maxAge` honoured against `now` |
| `FakeNetworking`, `RecordedCall`, `okResponse(Object? body)`, `errorResponse(Object? body, String status)` | `test/helpers/fake_networking.dart` | `Object? response; Object? error; final List<Object?> queued; final List<RecordedCall> calls; RecordedCall get lastCall;` implements get/post/delete/patch, `noSuchMethod` for the rest |
| `FakeCatalogRepository` + consts `testVariant testProduct testCategory testCatalog testSections testSoldCounts testLowStockThresholds` | `test/helpers/fake_catalog_repository.dart` | `Failure? catalogFailure/homeSectionsFailure/soldCountsFailure/lowStockThresholdsFailure; int catalogCalls/…; CatalogSnapshot catalog; List<HomeSection> sections; bool? lastRefresh; CatalogSnapshot? cachedCatalog; List<HomeSection>? cachedSections; Map<String,int>? cachedSoldCounts/cachedLowStockThresholds; Completer<void>? gate;` `_cached(value) => value == null ? Left(CacheMissFailure()) : Right(value)` |
| `FakeCartRepository` + `testCartItem` | `test/helpers/fake_cart_repository.dart` | `FakeCartRepository({List<CartItem> items = const [], List<CartItem> savedForLater = const []})`; `loadFailure saveFailure gate syncGate loadCalls saved savedForLaterCalls moveToCartCalls removeSavedCalls serverItems syncFailure pushFailure syncCalls pushCalls removed stockChecks`; `syncCart` replays the real `mergeServerLines(now, serverItems, deviceWins: changedVariants(before, now))` |
| `FakeCartRemoteDataSource` | `test/helpers/fake_cart_remote_data_source.dart` | `lines fetchError replaceError fetchGate replaced` (`List<({String userId, List<ServerCartLineModel> lines})>`) |
| `FakeWishlistRepository` | `test/helpers/fake_wishlist_repository.dart` | `FakeWishlistRepository({List<String> ids = const []})`; `ids cachedIds loadFailure addFailure removeFailure pushFailure loadCalls added removed pushes lastUserId gate toggleGate` |
| `FakeCouponRepository` + `welcome10`, `mali50` | `test/helpers/fake_coupon_repository.dart` | `FakeCouponRepository({List<Coupon> coupons = const [welcome10, mali50], DateTime? now})`; `listFailure checkFailure listCalls checkCalls checkedCodes gate`; `checkCoupon` runs the real `validateCoupon` |
| `FakeSupportRepository` + `testSupportContent` | `test/helpers/fake_support_repository.dart` | `FakeSupportRepository({this.content = testSupportContent, this.cachedContent}); Failure? failure; Completer<void>? gate; int calls` |
| `FakeMaliCoinsRepository` + `testCoinRules`, `testCoinBalance` | `test/helpers/fake_mali_coins_repository.dart` | `balance rules cachedBalance welcomed welcomeFailure balanceFailure rulesFailure welcomeCalls balanceCalls rulesCalls rulesRefreshes gate` |
| `FakeNotificationsRepository` + `notificationNamed(id, {isRead, category, createdAt})` | `test/helpers/fake_notifications_repository.dart` | `notifications listFailure markFailure gate listCalls markedRead` |
| `FakeOrdersRepository` | `test/helpers/fake_orders_repository.dart` | `found byId findCallsBeforeMatch pages failure finds gets pageCalls refOrders refCallsBeforeMatch refLookups` |
| `FakeChargeRulesRepository` + `testChargeRules` | `test/helpers/fake_charge_rules_repository.dart` | `FakeChargeRulesRepository({this.rules, this.cached}); Failure? remoteFailure; int remoteCalls, cachedCalls` |

---

## 3. Patterns

Each pattern: the rule it encodes, one verbatim and complete example from the repo, and what
to copy versus what varies. Sub-sections 3.A to 3.I.

### 3.A Core: `LocalCache` over Hive (shared by every cache-first feature)

**Rule.** One abstract cache in `core/services/local_cache/`, one Hive implementation that is the
only file importing Hive, one `CacheBoxes` registry. Entries are JSON strings of
`{"version": int, "saved_at": iso8601, "data": json}` so versioning and expiry live here once.
The cache is never required: `init()` never throws, a box that cannot open is deleted and
reopened, a closed box misses on read and throws `CacheException` on write. Models keep owning
JSON (no Hive TypeAdapters).

**Verbatim — `lib/core/services/local_cache/local_cache.dart` (complete):**

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

**Verbatim — `lib/core/services/local_cache/hive_local_cache.dart` (complete):**

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

**Verbatim — `lib/core/services/local_cache/cache_boxes.dart` (complete; note the misplaced
"Every box, opened at startup." doc comment above `seller`, a cosmetic slip — put it above `all`
when reproducing):**

```dart
/// Names of the cache boxes. One box per feature.
abstract final class CacheBoxes {
  static const String catalog = 'catalog';

  /// Server settings for the cart page (free delivery, small-cart fee).
  /// Not user data, so it survives sign-out.
  static const String chargeRules = 'charge_rules';

  /// The signed-in user's saved delivery addresses.
  static const String addresses = 'addresses';

  /// The signed-in user's Mali Coins balance.
  static const String maliCoins = 'mali_coins';

  /// The Mali Coins rules (earn rate, ways to earn…). Server configuration,
  /// not user data, so it survives sign-out.
  static const String coinRules = 'coin_rules';

  /// The coupons a customer may see, kept for a few minutes. The same for
  /// every signed-in user, so it survives sign-out.
  static const String coupons = 'coupons';

  /// Product pages already opened, and the store region they are priced
  /// in. The same for every user, so it survives sign-out.
  static const String product = 'product';

  /// Every box, opened at startup.
  /// The seller printed on invoices (`seller-info`); the same for every
  /// customer, so it survives sign-out.
  static const String seller = 'seller';

  /// The Help & Support content (`settings:support`); the same for every
  /// customer, so it survives sign-out.
  static const String support = 'support';

  static const List<String> all = [
    catalog,
    chargeRules,
    addresses,
    maliCoins,
    coinRules,
    coupons,
    product,
    seller,
    support,
  ];

  /// Boxes holding the signed-in user's data, cleared on sign-out.
  static const List<String> userScoped = [addresses, maliCoins];
}
```

**Verbatim — `lib/core/app/exceptions/cache_exceptions.dart` (complete):**

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

**Verbatim — `CacheMissFailure` in `lib/core/app/failure.dart`:**

```dart
/// Nothing usable is saved on this device for the data asked for. Never
/// shown to the user: the screen simply loads from the network.
class CacheMissFailure extends Failure {
  CacheMissFailure({super.message = 'Nothing saved on this device.'});
}
```

**Wiring (verbatim fragments):**

```dart
// lib/app/bootstrap.dart — order matters
  await Env.load();
  await _initFirebase();
  await DeviceSecureStorage.init();
  await Supabase.initialize(/* … */);
  await HiveLocalCache.init();

  configureDependencies();
```

```dart
// lib/core/di/injection_container.dart — _registerCore()
    ..registerLazySingleton<PrefUtils>(PrefUtils.new)
    ..registerLazySingleton<LocalCache>(HiveLocalCache.new)
```

```dart
// lib/features/auth/data/datasources/auth_local_data_source.dart — sign-out
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
```

**Test fake (verbatim — `test/helpers/fake_local_cache.dart`, complete):**

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

**HiveLocalCache test harness** (`test/core/services/local_cache/hive_local_cache_test.dart`):
`Directory.systemTemp.createTemp('mymali_cache_test')` → `Hive.init(directory.path)` →
`await HiveLocalCache.openBoxes()` → `HiveLocalCache(now: () => now)`; tearDown `Hive.close()` +
delete dir. Cases: miss when empty; map and list round-trip; survives close/reopen; other
version misses AND deletes; older than `maxAge` misses but is KEPT; corrupt (`'not json'`,
`'[1, 2]'`, missing `saved_at`, missing `data`) misses and is deleted; `delete` one /
`clearBox` all; non-JSON value fails the write with `CacheException`; closed box → read null,
write throws, `clearBox`/`clearUserScoped` do not throw.

**Copy:** everything above character for character. **Varies:** only `CacheBoxes` members and the
`userScoped` list.

### 3.B NETWORK-ONLY

**Rule.** A repository with only remote data sources, no `local:`, no `getCached…` method. It
maps typed exceptions to failures and never caches. The bloc reuses the section-20 refresh shape
without `isStale`: `loading`/`failure` mean "nothing to show"; once `loaded`, a refresh sets
`isRefreshing` and a failed refresh keeps the data and sets `failure`. Load, retry and
pull-to-refresh are ONE event.

**Verbatim — `lib/features/notifications/data/repositories/notifications_repository_impl.dart`
(complete; the minimal network-only repository):**

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remote,
  }) : _remote = remote;

  final NotificationsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      final models = await _remote.list();
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> markRead(List<String> ids) async {
    try {
      await _remote.markRead(ids);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }
}
```

**Verbatim — `notifications_state.dart` (complete; the network-only state):**

```dart
import 'package:equatable/equatable.dart';

import '../../../../../core/app/failure.dart';
import '../../../domain/entities/app_notification.dart';

/// `loading` and `failure` mean nothing has loaded yet; once the inbox is
/// known the status stays `loaded`, whatever a refresh does.
enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.failure,
    this.isRefreshing = false,
  });

  final NotificationsStatus status;

  /// Newest first. A row keeps the `isRead` it had when it was loaded, so
  /// the page can still highlight what was new on this visit.
  final List<AppNotification> notifications;

  /// Why the last load failed.
  final Failure? failure;
  final bool isRefreshing;

  bool get isBusy => status == NotificationsStatus.loading || isRefreshing;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? notifications,
    Failure? Function()? failure,
    bool? isRefreshing,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      failure: failure != null ? failure() : this.failure,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, notifications, failure, isRefreshing];
}
```

**Verbatim — `notifications_bloc.dart` handler (the network-only load/refresh shape):**

```dart
  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.isBusy) return;
    final loaded = state.status == NotificationsStatus.loaded;
    emit(
      loaded
          ? state.copyWith(isRefreshing: true, failure: () => null)
          : state.copyWith(
              status: NotificationsStatus.loading,
              failure: () => null,
            ),
    );

    final result = await _getNotifications(const NoParams());
    final notifications = result.toNullable();
    if (notifications == null) {
      final failure = result.swap().toNullable();
      emit(
        loaded
            ? state.copyWith(isRefreshing: false, failure: () => failure)
            : state.copyWith(
                status: NotificationsStatus.failure,
                failure: () => failure,
              ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        isRefreshing: false,
      ),
    );

    final unreadIds = [
      for (final notification in notifications)
        if (!notification.isRead) notification.id,
    ];
    if (unreadIds.isEmpty) return;
    // A failed write is silent: they are marked again on the next visit.
    await _markNotificationsRead(MarkNotificationsReadParams(ids: unreadIds));
  }
```

**Page glue (verbatim fragments, `notifications_page.dart`):**

```dart
    return BlocProvider<NotificationsBloc>(
      create: (_) => sl<NotificationsBloc>()..add(NotificationsLoadRequested()),
      child: const _NotificationsView(),
    );
```

```dart
    return BlocListener<NotificationsBloc, NotificationsState>(
      // A refresh that failed while the list stays on screen.
      listenWhen: (previous, current) =>
          current.status == NotificationsStatus.loaded &&
          current.failure != null &&
          current.failure != previous.failure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('notifications_refreshFailedMessage'),
            content: Text(notificationsFailureMessage(state.failure)),
          ),
        ),
```

```dart
      NotificationsStatus.loaded => RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<NotificationsBloc>();
          load();
          await bloc.stream.firstWhere((s) => !s.isBusy);
        },
        child: _NotificationsList(notifications: notifications),
      ),
```

**Network-only with several remote sources and an injected clock (`OrdersRepositoryImpl`):**

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
  /// The customer's orders KO registered that the warehouse does not have
  /// yet: … Never throws: this list is an addition to My Orders.
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
```

```dart
  Failure _toFailure(StockshipException e) => e.status == 0
      ? NetworkFailure()
      : ServerFailure(errorCode: 'HTTP_${e.status}', code: e.status);
```

Rules this encodes: a secondary source that only ENRICHES never fails the primary (`log` +
empty); input normalisation (`_tenDigits`) happens in the repository and a short input returns
`Right(null)`/empty WITHOUT a request; the clock is injectable for tests. The KO sources use their
own exception types whose `status == 0` means "no response" (MyMali-specific; Supabase sources use
`ConnectionException` instead).

**DI (verbatim):**

```dart
void _registerNotificationsData() {
  sl
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(remote: sl()),
    );
}

/// The notification use cases and the page's bloc. They depend only on
/// [NotificationsRepository], so tests can register a fake repository and
/// then call this.
void registerNotificationsFeature() {
  sl
    ..registerLazySingleton(() => GetNotifications(sl()))
    ..registerLazySingleton(() => MarkNotificationsRead(sl()))
    ..registerFactory(
      () => NotificationsBloc(
        getNotifications: sl(),
        markNotificationsRead: sl(),
      ),
    );
}
```

**Tests:** `test/features/notifications/presentation/notifications/bloc/notifications_bloc_test.dart`
(load → `[loading, loaded]` + `markedRead == [['a','c']]`; nothing unread marks nothing; failed
mark-read keeps `loaded` with null failure; failed first load → `failure`; failed refresh keeps
the list and sets `failure`), `test/features/notifications/data/datasources/notifications_remote_data_source_test.dart`,
`test/features/notifications/data/models/app_notification_model_test.dart`,
`test/features/orders/data/repositories/orders_repository_impl_test.dart` (fakes implement the two
remote interfaces; `calls` lists assert exact query maps; `now: () => placedAt`).

**Copy:** repository shape, state fields `status/items/failure/isRefreshing` + `isBusy`, the
handler, the page listener/`RefreshIndicator` glue, the one-event convention. **Varies:** entity,
endpoint, columns, texts, keys, the post-load side effect (mark-read).

### 3.C CACHE-FIRST, the two-use-case form (catalog → Home / Categories; support; charge rules)

**File set per feature `<feature>` caching `<Thing>`:**

1. `CacheBoxes.<feature>` (+ in `all`, + in `userScoped` when it is the signed-in user's data)
2. `data/datasources/<feature>_local_data_source.dart` — interface + `…Impl(this._cache)`
3. `data/repositories/<feature>_repository_impl.dart` — receives `remote:` and `local:`; `_save`, `_cached`
4. `domain/repositories/<feature>_repository.dart` — `get<Thing>()` + `getCached<Thing>()` returning the SAME type
5. `domain/usecases/get_<thing>.dart` + `domain/usecases/get_cached_<thing>.dart`
6. screen bloc with `isStale`, `isRefreshing`, `isBusy`, `_showCached`/`_refresh`
7. page: refresh-failed `SnackBar` listener + `RefreshIndicator` waiting on `!isBusy`
8. DI: `_register<Feature>Data()` registers remote, local, repository by abstract type; `register<Feature>Feature()` registers both use cases and the bloc factory

#### 3.C.1 Local data source — verbatim `catalog_local_data_source.dart` (complete)

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

The one-entry form (verbatim `support_local_data_source.dart` Impl) inlines the read/write:

```dart
class SupportLocalDataSourceImpl implements SupportLocalDataSource {
  const SupportLocalDataSourceImpl(this._cache);

  static const String contentKey = 'content';

  /// Bump whenever the model's JSON shape changes. Old entries become misses.
  static const int schemaVersion = 1;

  final LocalCache _cache;

  @override
  Future<SupportContentModel?> readSupport() async {
    final json = await _cache.read(
      box: CacheBoxes.support,
      key: contentKey,
      version: schemaVersion,
    );
    return json is Map ? SupportContentModel.fromJson(asMap(json)) : null;
  }

  @override
  Future<void> writeSupport(SupportContentModel content) => _cache.write(
    box: CacheBoxes.support,
    key: contentKey,
    version: schemaVersion,
    json: content.toJson(),
  );
}
```

Rules encoded: `const` constructor taking `this._cache`; keys and `schemaVersion` are
`static const` on the Impl; reads return model-or-null (`json is Map` / `json is List` guard
through `asMap`/`asMapList`, never a cast); an EMPTY saved list is a hit, not a miss (tested);
writes return `Future<void>`; `clear()` exists only when something needs to wipe it
(`clearBox` for a whole-feature box, `delete` for one key as in coupons).

#### 3.C.2 Repository — verbatim `catalog_repository_impl.dart` (complete)

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/exceptions/cache_exceptions.dart';
import '../../../../core/app/failure.dart';
import '../../domain/entities/catalog_snapshot.dart';
import '../../domain/entities/home_section.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/utils/build_home_sections.dart';
import '../../domain/utils/prepare_catalog.dart';
import '../datasources/catalog_local_data_source.dart';
import '../datasources/catalog_remote_data_source.dart';
import '../models/catalog_snapshot_model.dart';
import '../models/low_stock_threshold_model.dart';
import '../models/sold_count_model.dart';

/// Reads the catalog from the server and keeps a copy of every successful
/// read on the device. The `getCached…` methods serve that copy and never
/// touch the network. The cache is best-effort: failing to save or read it
/// never fails a call.
class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl({
    required CatalogRemoteDataSource remote,
    required CatalogLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final CatalogRemoteDataSource _remote;
  final CatalogLocalDataSource _local;

  @override
  Future<Either<Failure, CatalogSnapshot>> getCatalog() async {
    try {
      final snapshot = await _fetchSnapshot(refresh: false);
      return Right(prepareCatalog(snapshot.toEntity()));
    } on ServerException catch (e) {
      return Left(_toFailure(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CatalogSnapshot>> getCachedCatalog() async {
    final snapshot = await _cached(_local.readSnapshot);
    if (snapshot == null) return Left(CacheMissFailure());
    return Right(prepareCatalog(snapshot.toEntity()));
  }

  @override
  Future<Either<Failure, List<HomeSection>>> getHomeSections(
    bool refresh,
  ) async {
    try {
      final snapshot = (await _fetchSnapshot(refresh: refresh)).toEntity();
      return Right(buildHomeSections(snapshot.categories, snapshot.products));
    } on ServerException catch (e) {
      return Left(_toFailure(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<HomeSection>>> getCachedHomeSections() async {
    final cached = await _cached(_local.readSnapshot);
    if (cached == null) return Left(CacheMissFailure());
    final snapshot = cached.toEntity();
    return Right(buildHomeSections(snapshot.categories, snapshot.products));
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

  @override
  Future<Either<Failure, Map<String, int>>> getCachedSoldCounts() async {
    final rows = await _cached(_local.readSoldCounts);
    if (rows == null) return Left(CacheMissFailure());
    return Right(SoldCountModel.toSkuMap(rows));
  }

  @override
  Future<Either<Failure, Map<String, int>>> getLowStockThresholds() async {
    try {
      final rows = await _remote.fetchLowStockThresholds();
      await _save(() => _local.writeLowStockThresholds(rows));
      return Right(LowStockThresholdModel.toSkuMap(rows));
    } catch (_) {
      // Thresholds are configuration: a missing value must never break the
      // screen, so any failure reads as "no thresholds".
      return const Right({});
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>>
  getCachedLowStockThresholds() async {
    final rows = await _cached(_local.readLowStockThresholds);
    if (rows == null) return Left(CacheMissFailure());
    return Right(LowStockThresholdModel.toSkuMap(rows));
  }

  /// The snapshot from the server, saved to the device before returning,
  /// so Home and Categories share one fetch path and one saved copy.
  ///
  /// The catalog-cache function may hold fewer products than exist. Then,
  /// or on [refresh], the products come from Medusa instead.
  Future<CatalogSnapshotModel> _fetchSnapshot({required bool refresh}) async {
    final fetched = await _remote.fetchSnapshot();

    final regionId = fetched.regionId;
    final isIncomplete = fetched.count > fetched.products.length;
    final snapshot = (isIncomplete || refresh) && regionId != null
        ? CatalogSnapshotModel(
            categories: fetched.categories,
            products: await _remote.fetchProductsFromMedusa(regionId: regionId),
            count: fetched.count,
            regionId: regionId,
            updatedAt: fetched.updatedAt,
            cached: fetched.cached,
          )
        : fetched;

    await _save(() => _local.writeSnapshot(snapshot));
    return snapshot;
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

  // No documented catalog error codes yet, so everything is a ServerFailure.
  Failure _toFailure(ServerException e) =>
      ServerFailure(errorCode: e.code, code: e.status);
}
```

Rules encoded (copy verbatim): `_save` swallows `CacheException`; `_cached<T>` turns it into
`null`; `getCached<Thing>` never touches `_remote` and runs the SAME domain helper
(`prepareCatalog`, `buildHomeSections`) as the remote method; the raw server model is saved
(hidden products included), not derived view data; the remote method writes the cache AFTER the
fetch and BEFORE returning, and never falls back to the cache on failure; one private fetch path
(`_fetchSnapshot`) for every method that reads the same server data. `_save`/`_cached` are
re-declared privately in EVERY repository that caches (catalog, charge rules, support, coins,
coupons, product, address, seller) — there is no shared mixin; keep it that way.

The minimal form (`charge_rules_repository_impl.dart`, complete body):

```dart
  @override
  Future<Either<Failure, ChargeRules>> getChargeRules() async {
    try {
      final rules = await _remote.fetchChargeRules();
      await _save(() => _local.writeRules(rules));
      return Right(rules.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ChargeRules>> getCachedChargeRules() async {
    final rules = await _cached(_local.readRules);
    if (rules == null) return Left(CacheMissFailure());
    return Right(rules.toEntity());
  }
```

Mapping a "not configured" server answer to its own failure (support):

```dart
    } on ServerException catch (e) {
      if (e.code == supportNotConfiguredCode) {
        return Left(SupportUnavailableFailure(code: e.status));
      }
      return Left(ServerFailure(errorCode: e.code, code: e.status));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
```

#### 3.C.3 Contract and use cases (verbatim)

```dart
/// Contract for reading the product catalog.
///
/// Each read comes in two forms: one that loads from the server (and
/// saves a copy on this device), and a `getCached…` one that only reads
/// that copy and fails with [CacheMissFailure] when there is none.
abstract interface class CatalogRepository {
  Future<Either<Failure, CatalogSnapshot>> getCatalog();

  /// [getCatalog] from the copy saved on this device.
  Future<Either<Failure, CatalogSnapshot>> getCachedCatalog();

  Future<Either<Failure, List<HomeSection>>> getHomeSections(bool refresh);

  /// [getHomeSections] from the copy saved on this device.
  Future<Either<Failure, List<HomeSection>>> getCachedHomeSections();
  // … getSoldCounts / getCachedSoldCounts / getLowStockThresholds / getCachedLowStockThresholds
}
```

```dart
/// The Home rails as last saved on this device, without touching the network.
class GetCachedHomeSections implements UseCase<List<HomeSection>, NoParams> {
  const GetCachedHomeSections(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, List<HomeSection>>> call(NoParams params) {
    return _repository.getCachedHomeSections();
  }
}
```

```dart
class GetHomeSections
    implements UseCase<List<HomeSection>, GetHomeSectionsParams> {
  const GetHomeSections(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, List<HomeSection>>> call(
    GetHomeSectionsParams params,
  ) {
    return _repository.getHomeSections(params.refresh);
  }
}

class GetHomeSectionsParams {
  final bool refresh;
  const GetHomeSectionsParams({this.refresh = false});
}
```

#### 3.C.4 State — verbatim `home_state.dart` (complete)

```dart
import 'package:equatable/equatable.dart';

import '../../../../../core/app/failure.dart';
import '../../../../app_config/domain/entities/app_state.dart';
import '../../../../catalog/domain/entities/home_section.dart';
import '../../../domain/entities/home_banner.dart';

enum HomeStatus {
  initial,

  /// Fetching the catalog and the app state, with nothing to show yet.
  loading,

  /// The product rails are ready; see [HomeState.sections].
  loaded,

  /// Loading the product rails failed and there is nothing to show; see
  /// [HomeState.failure].
  failure,
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.sections = const [],
    this.appState,
    this.banners = const [],
    this.soldBySku = const {},
    this.lowStockThresholdBySku = const {},
    this.isStale = false,
    this.isRefreshing = false,
    this.failure,
  });

  final HomeStatus status;

  /// The product rails. Loading these is the only fatal step.
  final List<HomeSection> sections;

  /// Banners, hero and settings. Null when the app-state call failed; the
  /// rails still show.
  final AppState? appState;

  /// The banner carousel's slides, built from [appState]. Empty when there
  /// is nothing to show; the carousel is then hidden.
  final List<HomeBanner> banners;

  /// Units sold per SKU. Empty when the call failed.
  final Map<String, int> soldBySku;

  /// Low-stock threshold per SKU. Empty when there is none.
  final Map<String, int> lowStockThresholdBySku;

  /// Whether the rails on screen are the copy saved on this device, not
  /// yet replaced by a fresh load.
  final bool isStale;

  /// Whether a fresh load is running behind rails that are on screen.
  final bool isRefreshing;

  /// Why the last load failed. With [status] [HomeStatus.failure] there is
  /// nothing to show; with [HomeStatus.loaded] the rails on screen are
  /// kept and only the refresh failed.
  final Failure? failure;

  bool get isLoading => status == HomeStatus.loading;

  /// Whether any load is running, with or without rails on screen.
  bool get isBusy => isLoading || isRefreshing;

  /// Nullable fields take a getter so they can be explicitly cleared,
  /// e.g. `copyWith(failure: () => null)`.
  HomeState copyWith({
    HomeStatus? status,
    List<HomeSection>? sections,
    AppState? Function()? appState,
    List<HomeBanner>? banners,
    Map<String, int>? soldBySku,
    Map<String, int>? lowStockThresholdBySku,
    bool? isStale,
    bool? isRefreshing,
    Failure? Function()? failure,
  }) {
    return HomeState(
      status: status ?? this.status,
      sections: sections ?? this.sections,
      appState: appState != null ? appState() : this.appState,
      banners: banners ?? this.banners,
      soldBySku: soldBySku ?? this.soldBySku,
      lowStockThresholdBySku:
          lowStockThresholdBySku ?? this.lowStockThresholdBySku,
      isStale: isStale ?? this.isStale,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sections,
    appState,
    banners,
    soldBySku,
    lowStockThresholdBySku,
    isStale,
    isRefreshing,
    failure,
  ];
}
```

#### 3.C.5 Bloc — verbatim `home_bloc.dart` handlers

```dart
  Future<void> _onHomeStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    _language = event.language;
    if (state.isBusy) return;

    if (state.status != HomeStatus.loaded) await _showCached(emit);
    await _refresh(emit, forceRefresh: false);
  }

  Future<void> _onHomeRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    _language = event.language ?? _language;
    await _refresh(emit, forceRefresh: true);
  }

  /// Shows the rails saved on this device, if any, marked stale.
  Future<void> _showCached(Emitter<HomeState> emit) async {
    final (sections, soldCounts, thresholds) = await (
      _getCachedHomeSections(const NoParams()),
      _getCachedSoldCounts(const NoParams()),
      _getCachedLowStockThresholds(const NoParams()),
    ).wait;

    final cached = sections.getOrElse((_) => const []);
    // Nothing saved, or an empty shop: the skeleton says more.
    if (cached.isEmpty) return;

    emit(
      state.copyWith(
        status: HomeStatus.loaded,
        sections: cached,
        soldBySku: soldCounts.getOrElse((_) => const {}),
        lowStockThresholdBySku: thresholds.getOrElse((_) => const {}),
        isStale: true,
      ),
    );
  }

  /// Loads everything from the server. With rails already on screen they
  /// stay there while it runs and if it fails.
  Future<void> _refresh(
    Emitter<HomeState> emit, {
    required bool forceRefresh,
  }) async {
    if (state.isBusy) return;

    final hasRails = state.status == HomeStatus.loaded;
    emit(
      hasRails
          ? state.copyWith(isRefreshing: true, failure: () => null)
          : state.copyWith(status: HomeStatus.loading, failure: () => null),
    );

    final (sections, appState, soldCounts, thresholds) = await (
      _getHomeSections(GetHomeSectionsParams(refresh: forceRefresh)),
      _getAppState(AppStateRequest(language: _language)),
      _getSoldCounts(const NoParams()),
      _getLowStockThresholds(const NoParams()),
    ).wait;

    emit(
      sections.match(
        (failure) => hasRails
            ? state.copyWith(isRefreshing: false, failure: () => failure)
            : state.copyWith(
                status: HomeStatus.failure,
                failure: () => failure,
              ),
        // A decoration that failed keeps what is already on screen.
        (sections) {
          final nextAppState = appState.toNullable() ?? state.appState;
          return state.copyWith(
            status: HomeStatus.loaded,
            sections: sections,
            appState: () => nextAppState,
            banners: buildHomeBanners(
              nextAppState,
              imageBaseUrl: _imageBaseUrl,
            ),
            soldBySku: soldCounts.getOrElse((_) => state.soldBySku),
            lowStockThresholdBySku: thresholds.getOrElse(
              (_) => state.lowStockThresholdBySku,
            ),
            isStale: false,
            isRefreshing: false,
          );
        },
      ),
    );
  }
```

The compact form (`help_support_bloc.dart`, complete handlers) — same shape with one use case
pair and the `match` callback style:

```dart
  Future<void> _onStarted(
    HelpSupportStarted event,
    Emitter<HelpSupportState> emit,
  ) async {
    final cached = await _getCached(const NoParams());
    cached.match((_) {}, (content) {
      if (content.isEmpty) return;
      emit(
        state.copyWith(
          status: HelpSupportStatus.loaded,
          content: content,
          isStale: true,
        ),
      );
    });
    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<HelpSupportState> emit) async {
    if (state.isBusy) return;
    final hasContent = state.status == HelpSupportStatus.loaded;
    emit(
      hasContent
          ? state.copyWith(isRefreshing: true, failure: () => null)
          : state.copyWith(
              status: HelpSupportStatus.loading,
              failure: () => null,
            ),
    );

    final result = await _getContent(const NoParams());
    result.match(
      (failure) => emit(
        hasContent
            ? state.copyWith(isRefreshing: false, failure: () => failure)
            : state.copyWith(
                status: HelpSupportStatus.failure,
                failure: () => failure,
              ),
      ),
      (content) => emit(
        state.copyWith(
          status: HelpSupportStatus.loaded,
          content: content,
          isStale: false,
          isRefreshing: false,
        ),
      ),
    );
  }
```

Rules encoded: start = `_showCached` then `_refresh`; cached hit emits `loaded` + `isStale: true`;
cached miss or EMPTY data emits nothing (skeleton stays); `_refresh` is the single refresh path
guarded by `if (state.isBusy) return;`; with data on screen emit `isRefreshing: true` else
`loading`, clearing `failure` either way; `Right` → `loaded`, `isStale: false`,
`isRefreshing: false`; `Left` with data → keep data, set `failure`, `isRefreshing: false`
(`isStale` untouched); `Left` without data → `failure`; decorations use
`getOrElse((_) => state.x)`; parallel calls use the Dart 3 record `.wait`; a parameter the
refresh needs again is kept in a private field (`_language`).

#### 3.C.6 Page glue (verbatim fragments, `home_page.dart` / `wishlist_page.dart`)

```dart
    return BlocListener<HomeBloc, HomeState>(
      // A refresh that failed while rails stay on screen.
      listenWhen: (previous, current) =>
          current.status == HomeStatus.loaded &&
          current.failure != null &&
          current.failure != previous.failure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('home_refreshFailedMessage'),
            content: Text(refreshFailureMessage(state.failure)),
          ),
        ),
```

```dart
    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<WishlistBloc>()..add(WishlistRefreshed());
        await bloc.stream.firstWhere((s) => !s.isBusy);
      },
```

```dart
/// User-facing text for a refresh that failed while saved products stay
/// on screen; never shows raw codes.
String refreshFailureMessage(Failure? failure) {
  return switch (failure) {
    NetworkFailure() => 'No internet connection. Showing saved products.',
    _ => "Couldn't refresh right now. Showing saved products.",
  };
}
```

`CacheMissFailure` is never shown (it never reaches a `loaded` state's `failure`). Key naming:
`<screen>_refreshFailedMessage`.

#### 3.C.7 A page bloc that reads cached-then-fresh WITHOUT the status fields (`CartPageBloc`)

```dart
    // The server's rules load alongside the catalog. The copy saved on this
    // device shows until they arrive; with neither, the messages stay hidden.
    final freshRules = _getChargeRules(const NoParams());
    final cachedRules = await _getCachedChargeRules(const NoParams());
    cachedRules.match(
      (_) {},
      (rules) => emit(state.copyWith(chargeRules: rules)),
    );
    // …
    // A failed fetch keeps the saved rules, or leaves the messages hidden.
    (await freshRules).match(
      (_) {},
      (rules) => emit(state.copyWith(chargeRules: rules)),
    );
```

Rule: start the remote future first, then `await` the cached read, emit it, then `await` the
remote and emit it; failures are silent because the data is decoration.

#### 3.C.8 DI — verbatim

```dart
void _registerCatalogData() {
  sl
    ..registerLazySingleton<CatalogRemoteDataSource>(
      () => CatalogRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
        medusaPublishableKey: Env.medusaApiKey,
      ),
    )
    ..registerLazySingleton<CatalogLocalDataSource>(
      () => CatalogLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(remote: sl(), local: sl()),
    );
}

/// Catalog use cases. They depend only on [CatalogRepository], so tests can
/// register a fake repository and then call this.
void registerCatalogFeature() {
  sl
    ..registerLazySingleton(() => GetCatalog(sl()))
    ..registerLazySingleton(() => GetCachedCatalog(sl()))
    ..registerLazySingleton(() => GetHomeSections(sl()))
    ..registerLazySingleton(() => GetCachedHomeSections(sl()))
    ..registerLazySingleton(() => GetSoldCounts(sl()))
    ..registerLazySingleton(() => GetCachedSoldCounts(sl()))
    ..registerLazySingleton(() => GetLowStockThresholds(sl()))
    ..registerLazySingleton(() => GetCachedLowStockThresholds(sl()));
}
```

```dart
void registerHomeFeature({String imageBaseUrl = ''}) {
  sl.registerFactory(
    () => HomeBloc(
      getHomeSections: sl(),
      getCachedHomeSections: sl(),
      getAppState: sl(),
      getSoldCounts: sl(),
      getCachedSoldCounts: sl(),
      getLowStockThresholds: sl(),
      getCachedLowStockThresholds: sl(),
      imageBaseUrl: imageBaseUrl,
    ),
  );
}
```

```dart
void _registerSupportData() {
  sl
    ..registerLazySingleton<SupportRemoteDataSource>(
      () => SupportRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<SupportLocalDataSource>(
      () => SupportLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(remote: sl(), local: sl()),
    );
}

/// The Help & Support page's use cases and bloc. They depend only on
/// [SupportRepository], so tests can register a fake one and call this.
void registerSupportFeature() {
  sl
    ..registerLazySingleton(() => GetSupportContent(sl()))
    ..registerLazySingleton(() => GetCachedSupportContent(sl()))
    ..registerFactory(
      () => HelpSupportBloc(
        getCachedSupportContent: sl(),
        getSupportContent: sl(),
      ),
    );
}
```

#### 3.C.9 Tests that pin the strategy

| test file | what it asserts |
|---|---|
| `test/features/catalog/data/datasources/catalog_local_data_source_test.dart` | every read misses when empty; write→read equal via `toJson()`; `cache.keysOf(CacheBoxes.catalog) == [snapshotKey]`; empty list is a hit; other `schemaVersion + 1` misses; `clear()` wipes; `CacheException` passes through |
| `test/features/catalog/data/repositories/catalog_repository_impl_test.dart` | shared `log` list across fake remote/local proves order `['remote.fetchSnapshot', 'local.writeSnapshot']`; raw snapshot saved with hidden products; failed fetch saves nothing; throwing write still `Right`; cached reads never log `remote.`; `getCachedCatalog` equals a fresh `getCatalog` after `prepareCatalog`; throwing read → `CacheMissFailure`; "what a load saves is what the next cached read returns" |
| `test/features/home/presentation/home/bloc/home_bloc_test.dart` | `HomeStarted` → `[loading, loaded]`; cache-first group: `[stale, stale.copyWith(isRefreshing: true), loaded]`; failed refresh → `stale.copyWith(failure: () => failure)`; failed decoration keeps saved one; empty saved rails not shown; `HomeRefreshed` → `[loaded.copyWith(isRefreshing: true), loaded]` with `catalog.lastRefresh == true`; next refresh clears failure |
| `test/features/catalog/presentation/categories/bloc/categories_bloc_test.dart` | same three-state sequence on `products`/`isStale`/`isRefreshing`; selection kept across cached→fresh |
| `test/features/support/data/repositories/support_repository_impl_test.dart` | `['fetch', 'write']` order; write error still `Right`; `NOT_CONFIGURED` → `SupportUnavailableFailure`; miss / read error → `CacheMissFailure` with `remote.calls == 0` |
| `test/features/support/presentation/help_support/bloc/help_support_bloc_test.dart` | `(status, isStale, isRefreshing)` tuples `(loaded,true,false) → (loaded,true,true) → (loaded,false,false)`; failed refresh keeps saved copy, `isStale` stays true; `[loading, failure]` when nothing saved |
| `test/features/cart/data/repositories/charge_rules_repository_impl_test.dart` | good read saved for next time; miss → `CacheMissFailure`; write/read errors never fail |
| `test/features/cart/presentation/cart/bloc/cart_page_charge_rules_test.dart` | saved rules show while server fails; server rules replace saved; neither → null |
| page tests `home_page_test.dart`, `wishlist_page_test.dart` | `catalog.gate = Completer()` holds the load open while the saved copy shows; a failed refresh shows `Key('home_refreshFailedMessage')` with text `'No internet connection. Showing saved products.'`, not the retry screen |

**Copy:** all of 3.C.1–3.C.8 as written. **Varies:** `<feature>`, `<Thing>`, box/key names,
`schemaVersion`, the domain helper applied to both paths, decorations, texts and keys.

### 3.D CACHE-FIRST, the TTL + shared-in-flight form (coupons list, coin rules)

**Rule.** When a copy younger than a `maxAge` is as good as a fresh one, the repository exposes
ONE method with a `{required bool refresh}` flag instead of a `get`/`getCached` pair. The max age
is a `static const Duration` on the DOMAIN repository interface; the local data source imports
that interface and passes it as `maxAge:` to `LocalCache.read`. Two concurrent asks share one
request. A failed list is never saved.

**Verbatim — `coupon_repository_impl.dart` (the whole list path):**

```dart
class CouponRepositoryImpl implements CouponRepository {
  CouponRepositoryImpl({
    required CouponRemoteDataSource remote,
    required CouponLocalDataSource local,
    DateTime Function() now = DateTime.now,
  }) : _remote = remote,
       _local = local,
       _now = now;

  final CouponRemoteDataSource _remote;
  final CouponLocalDataSource _local;
  final DateTime Function() _now;

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

  Future<Either<Failure, List<Coupon>>> _fetchActive() async {
    final List<CouponModel> rows;
    try {
      rows = await _remote.fetchActive(_now());
    } on ServerException catch (e) {
      return Left(CouponsUnavailableFailure(code: e.status));
    } on ConnectionException {
      return Left(CouponsUnavailableFailure());
    }
    await _save(() => _local.writeActive(rows));
    return Right(_toEntities(rows));
  }
```

**Verbatim — `coupon_local_data_source.dart` Impl (the `maxAge` read):**

```dart
class CouponLocalDataSourceImpl implements CouponLocalDataSource {
  const CouponLocalDataSourceImpl(this._cache);

  static const String activeKey = 'active';

  /// Bump whenever the model's JSON shape changes. Old entries become
  /// misses.
  static const int schemaVersion = 1;

  final LocalCache _cache;

  @override
  Future<List<CouponModel>?> readActive() async {
    final json = await _cache.read(
      box: CacheBoxes.coupons,
      key: activeKey,
      version: schemaVersion,
      maxAge: CouponRepository.listMaxAge,
    );
    if (json is! List) return null;
    return [for (final row in asMapList(json)) CouponModel.fromJson(row)];
  }

  @override
  Future<void> writeActive(List<CouponModel> coupons) => _cache.write(
    box: CacheBoxes.coupons,
    key: activeKey,
    version: schemaVersion,
    json: [for (final coupon in coupons) coupon.toJson()],
  );

  @override
  Future<void> clear() =>
      _cache.delete(box: CacheBoxes.coupons, key: activeKey);
}
```

```dart
abstract interface class CouponRepository {
  /// How long the list of coupons is served without asking the server.
  static const Duration listMaxAge = Duration(minutes: 5);
```

**Same form with a `_guard` wrapper (`mali_coins_repository_impl.dart`):**

```dart
  @override
  Future<Either<Failure, CoinRules>> getRules({required bool refresh}) async {
    if (!refresh) {
      final saved = await _cached(_local.readRules);
      if (saved != null) return Right(saved.toEntity());
    }

    return _guard(() async {
      final rules = await _remote.fetchRules();
      await _save(() => _local.writeRules(rules));
      return rules.toEntity();
    });
  }

  /// Runs [call] and maps what it throws to a failure.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(_toFailure(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
  }
```

```dart
abstract interface class MaliCoinsRepository {
  /// How long a copy of the rules is served without asking the server.
  static const Duration rulesMaxAge = Duration(minutes: 30);
```

Use case params for this form: `const GetActiveCouponsParams({this.refresh = false});`,
`const GetCoinRulesParams({this.refresh = false});` — the page's start passes the default,
pull-to-refresh passes `refresh: true` (`CoinsPageBloc._load(emit, refreshRules: true)`).

**Tests:** `coupon_repository_impl_test.dart` — two asks within 5 min make one request (clock
moved via `cache.now`); after 5 min asks again; `refresh: true` asks even when saved; two asks
while in flight share it (`remote.gate = Completer()`, `remote.listCalls == 1`); a failed list is
`CouponsUnavailableFailure` and NOT cached (retry hits the server); throwing write still returns;
throwing read is a miss. `coupon_local_data_source_test.dart` — older than `listMaxAge + 1s` is
a miss; `CacheBoxes.all` contains `coupons`, `userScoped` does not.
`mali_coins_repository_impl_test.dart` — `getRules` logs `['local.readRules']` on a hit,
`['local.readRules', 'remote.rules', 'local.writeRules']` on a miss, `['remote.rules', 'local.writeRules']`
on refresh; `NOT_CONFIGURED` → `CoinsUnavailableFailure` with no fallback to the saved copy.

### 3.E CACHE-FIRST variants: keyed entries, user-scoped box, saving from every answer, mutations

**Keyed by input (`product_local_data_source.dart`):**

```dart
  static const String regionKey = 'region';

  /// Bump whenever the JSON shape of a model saved here changes. Old
  /// entries then read as misses.
  static const int schemaVersion = 1;

  final LocalCache _cache;

  @override
  Future<ProductDetailModel?> readProduct(String productId) async {
    final json = await _read(_productKey(productId));
    return json is Map ? ProductDetailModel.fromJson(asMap(json)) : null;
  }

  @override
  Future<void> writeProduct(ProductDetailModel product) =>
      _write(_productKey(product.id), product.toJson());

  @override
  Future<String?> readRegionId() async {
    final json = await _read(regionKey);
    final id = json is Map ? asString(json['id']) : null;
    return id == null || id.isEmpty ? null : id;
  }

  @override
  Future<void> writeRegionId(String regionId) =>
      _write(regionKey, {'id': regionId});

  static String _productKey(String productId) => 'product.$productId';
```

Rule: a key that depends on input is built by ONE private static helper (`'product.$id'`); a
scalar is stored wrapped in a map (`{'id': regionId}`, `{balanceKey: balance}`) because
`LocalCache.write` takes a Map/List `json`. The matching repository/use-case take the id:
`getCachedProduct(String productId)` → `_cached(() => _local.readProduct(productId))`.
Memory → device → server for a value asked once per run (`ProductRepositoryImpl._region()`):

```dart
  Future<String> _region() async {
    final known = _regionId ?? await _cached(_local.readRegionId);
    if (known != null) return _regionId = known;

    final fetched = await _remote.fetchRegionId();
    await _save(() => _local.writeRegionId(fetched));
    return _regionId = fetched;
  }
```

**User-scoped box + saving the balance from every answer (`mali_coins_repository_impl.dart`):**

```dart
  @override
  Future<Either<Failure, CoinWelcome>> claimWelcome() {
    return _guard(() async {
      final welcome = await _remote.claimWelcome();
      await _save(() => _local.writeBalance(welcome.balance));
      return welcome.toEntity();
    });
  }

  @override
  Future<Either<Failure, CoinBalance>> getBalance() {
    return _guard(() async {
      final balance = await _remote.fetchBalance();
      await _save(() => _local.writeBalance(balance.balance));
      return balance.toEntity();
    });
  }

  @override
  Future<Either<Failure, int>> getCachedBalance() async {
    final balance = await _cached(_local.readBalance);
    if (balance == null) return Left(CacheMissFailure());
    return Right(balance);
  }
```

```dart
  @override
  Future<int?> readBalance() async {
    final json = await _cache.read(
      box: CacheBoxes.maliCoins,
      key: balanceKey,
      version: schemaVersion,
    );
    return json is Map ? asInt(json[balanceKey]) : null;
  }

  @override
  Future<void> writeBalance(int balance) => _cache.write(
    box: CacheBoxes.maliCoins,
    key: balanceKey,
    version: schemaVersion,
    json: {balanceKey: balance},
  );
  // …
  @override
  Future<void> clear() => _cache.clearBox(CacheBoxes.maliCoins);
```

Rules: a box in `CacheBoxes.userScoped` is wiped by `AuthLocalDataSourceImpl.clearTokens()`;
`clear()` on the data source wipes ONLY the user box, the config box (`coin_rules`) survives
(tested: "clear removes the saved balance but keeps the rules"). The app-wide bloc shows the
cached value, then the server's:

```dart
  Future<void> _onStarted(
    MaliCoinsStarted event,
    Emitter<MaliCoinsState> emit,
  ) async {
    final session = ++_session;
    // Nothing of a previous user may show.
    _reset(emit);

    final cached = (await _getCachedBalance(const NoParams())).toNullable();
    if (session != _session) return;
    if (cached != null) emit(state.copyWith(balance: () => cached));

    final welcome = await _claimWelcome(const NoParams());
    if (session != _session) return;
    welcome.match(
      // Best-effort: the last known balance stays.
      (failure) => developer.log(
        'Welcome claim failed: $failure',
        name: 'MaliCoinsBloc',
      ),
      (result) => emit(state.copyWith(balance: () => result.balance)),
    );
  }
  // …
  /// Back to the empty state. Emits nothing when already there.
  void _reset(Emitter<MaliCoinsState> emit) {
    const empty = MaliCoinsState();
    if (state != empty) emit(empty);
  }
```

The `_session` counter (`int _session = 0;` bumped on every sign-in/sign-out, captured at the
start of a handler, compared after every `await`) is how app-wide blocs drop an answer that
arrives for an earlier user. `WishlistBloc` and `CouponBloc` use the same name and shape.

**Mutations on a cached list (`address_repository_impl.dart`):**

```dart
  @override
  Future<Either<Failure, SavedAddress>> saveAddress(
    SavedAddress address,
  ) async {
    try {
      await _remote.saveAddress(AddressModel.fromEntity(address));
    } on ServerException catch (e) {
      return Left(_toFailure(e));
    } on ConnectionException {
      return Left(NetworkFailure());
    }
    await _updateCached((addresses) => withSavedAddress(addresses, address));
    return Right(address);
  }

  /// Applies [change] to the saved copy, if there is one. With none, the
  /// next load saves the server's list.
  Future<void> _updateCached(
    List<SavedAddress> Function(List<SavedAddress>) change,
  ) async {
    final cached = await _cached(_local.readAddresses);
    if (cached == null) return;
    final changed = AddressListModel.fromEntity(change(cached.toEntity()));
    await _save(() => _local.writeAddresses(changed));
  }
```

Rule: after the remote mutation succeeds, change the saved copy the same way (through a pure
domain helper) so the next cache-first load is not wrong; with no copy saved, do nothing.

### 3.F DEVICE-FIRST with a pending flag (wishlist)

**Rule.** The device copy is the truth and carries `pending` while it holds a change the server
has not accepted. Writes hit the device only (`_onDevice`) and return the whole list; a push
(`pushWishlist`) sends the whole list when `pending`, then clears the flag unless the list
changed meanwhile; a sync (`syncWishlist`) sends when `pending`, otherwise the server's list
replaces the device's. Server calls run one at a time (`_inOrder`), device reads/writes run one
at a time (`_device`), a push not yet started is shared (`_waitingPush`). Storage is `PrefUtils`
JSON under ONE key; one user's list at a time (`user_id`), never cleared on sign-out.

**File set:** `data/datasources/wishlist_local_data_source.dart`,
`wishlist_remote_data_source.dart`, `data/exceptions/wishlist_exceptions.dart`,
`data/models/stored_wishlist_model.dart`, `wishlist_model.dart`,
`data/repositories/wishlist_repository_impl.dart`, `domain/entities/wishlist_item.dart`,
`domain/failures/wishlist_failures.dart`, `domain/repositories/wishlist_repository.dart`,
`domain/usecases/{load,sync,push,add_to,remove_from}_wishlist.dart`,
`domain/utils/wishlist_products.dart`, `presentation/bloc/wishlist_{bloc,event,state}.dart`,
`presentation/utils/failure_message.dart`; wired in `app.dart` by the `BlocListener<AuthBloc>`.

#### 3.F.1 Device storage — verbatim `wishlist_local_data_source.dart` (complete)

```dart
import 'dart:convert';

import '../../../../core/services/pref_utils.dart';
import '../exceptions/wishlist_exceptions.dart';
import '../models/stored_wishlist_model.dart';

/// The wishlist kept on this device through `PrefUtils`, as the cart is.
/// Throws [WishlistStorageException] on failure.
abstract interface class WishlistLocalDataSource {
  /// The stored wishlist, or null when the device holds none.
  Future<StoredWishlistModel?> readWishlist();

  Future<void> writeWishlist(StoredWishlistModel wishlist);
}

class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  WishlistLocalDataSourceImpl(this._prefs);

  static const String wishlistKey = 'wishlist.saved';

  final PrefUtils _prefs;

  @override
  Future<StoredWishlistModel?> readWishlist() async {
    await _prefs.init();
    final raw = _prefs.getJsonString(key: wishlistKey);
    if (raw == null || raw.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw WishlistStorageException(e.message);
    }
    if (decoded is Map<String, dynamic>) {
      return StoredWishlistModel.fromJson(decoded);
    }
    throw const WishlistStorageException('Not a wishlist');
  }

  @override
  Future<void> writeWishlist(StoredWishlistModel wishlist) async {
    await _prefs.init();
    final saved = await _prefs.setJsonString(
      key: wishlistKey,
      jsonValue: jsonEncode(wishlist.toJson()),
    );
    if (!saved) throw const WishlistStorageException('Write failed');
  }
}
```

**Verbatim — `stored_wishlist_model.dart` (complete):**

```dart
import '../../../../core/utils/json_readers.dart';
import '../../domain/entities/wishlist_item.dart';

/// The wishlist as this device keeps it:
/// `{ "user_id", "ids": ["prod_…", …], "pending": bool }`, newest first.
///
/// [pending] is true while the device holds a change the server has not
/// accepted yet.
class StoredWishlistModel {
  const StoredWishlistModel({
    required this.userId,
    this.ids = const [],
    this.pending = false,
  });

  factory StoredWishlistModel.fromJson(Map<String, dynamic> json) {
    return StoredWishlistModel(
      userId: asString(json['user_id']) ?? '',
      ids: asStringList(json['ids']),
      pending: asBool(json['pending']) ?? false,
    );
  }

  factory StoredWishlistModel.fromEntity(
    List<WishlistItem> items, {
    required String userId,
    bool pending = false,
  }) {
    return StoredWishlistModel(
      userId: userId,
      ids: [for (final item in items) item.productId],
      pending: pending,
    );
  }

  /// Whose wishlist this is.
  final String userId;

  /// Product ids, newest first.
  final List<String> ids;
  final bool pending;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'ids': ids,
    'pending': pending,
  };

  List<WishlistItem> toEntity() => [
    for (final id in ids) WishlistItem(productId: id),
  ];
}
```

#### 3.F.2 Repository — verbatim `wishlist_repository_impl.dart` (complete)

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/failure.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/failures/wishlist_failures.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_data_source.dart';
import '../datasources/wishlist_remote_data_source.dart';
import '../exceptions/wishlist_exceptions.dart';
import '../models/stored_wishlist_model.dart';
import '../models/wishlist_model.dart';

/// The wishlist lives on the device; the server gets a copy. See
/// [WishlistRepository] for who wins when the two differ.
///
/// The server can only replace the whole list, so every push sends the
/// device's whole list. Server calls run one at a time, in the order they
/// were asked for, and device reads and writes run one at a time too, so
/// two heart taps never overwrite each other. A push waiting behind
/// another one sends the list as it is when it runs, so waiting pushes are
/// merged.
class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl({
    required WishlistRemoteDataSource remote,
    required WishlistLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final WishlistRemoteDataSource _remote;
  final WishlistLocalDataSource _local;

  /// The last server call asked for; the next one waits for it.
  Future<void> _lastCall = Future.value();

  /// The last device read or write asked for; the next one waits for it.
  Future<void> _lastWrite = Future.value();

  /// A push that has not started yet, and the user it is for.
  Future<Either<Failure, Unit>>? _waitingPush;
  String? _waitingUserId;

  @override
  Future<Either<Failure, List<WishlistItem>>> loadWishlist(String userId) {
    return _onDevice(() async => _idsOf(await _local.readWishlist(), userId));
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> addToWishlist(
    String userId,
    String productId,
  ) {
    return _onDevice(() async {
      final ids = _idsOf(await _local.readWishlist(), userId);
      if (ids.contains(productId)) return ids;
      if (ids.length >= WishlistRepository.maxItems) {
        throw const _WishlistFullException();
      }

      final updated = [productId, ...ids];
      await _local.writeWishlist(
        StoredWishlistModel(userId: userId, ids: updated, pending: true),
      );
      return updated;
    });
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> removeFromWishlist(
    String userId,
    String productId,
  ) {
    return _onDevice(() async {
      final ids = _idsOf(await _local.readWishlist(), userId);
      if (!ids.contains(productId)) return ids;

      final updated = [
        for (final id in ids)
          if (id != productId) id,
      ];
      await _local.writeWishlist(
        StoredWishlistModel(userId: userId, ids: updated, pending: true),
      );
      return updated;
    });
  }

  @override
  Future<Either<Failure, Unit>> pushWishlist(String userId) {
    // A push that has not started yet reads the list when it runs, so it
    // already covers this change.
    final waiting = _waitingPush;
    if (waiting != null && _waitingUserId == userId) return waiting;

    final push = _inOrder(() async {
      // Started: a change after this point needs a push of its own.
      _waitingPush = null;
      _waitingUserId = null;
      final stored = await _device(_local.readWishlist);
      if (stored == null || stored.userId != userId || !stored.pending) {
        return unit;
      }
      await _send(userId, stored.ids);
      return unit;
    });
    _waitingPush = push;
    _waitingUserId = userId;
    return push;
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> syncWishlist(String userId) {
    return _inOrder(() async {
      final stored = await _device(_local.readWishlist);
      // A change the server has not accepted yet: the device wins.
      if (stored != null && stored.userId == userId && stored.pending) {
        return _items(await _send(userId, stored.ids));
      }

      final server = await _remote.fetchWishlist();
      return _items(
        await _device(() async {
          final now = await _local.readWishlist();
          // A heart tapped while the server answered wins; its own push
          // follows.
          if (now != null && now.userId == userId && now.pending) {
            return now.ids;
          }
          await _local.writeWishlist(
            StoredWishlistModel(userId: userId, ids: server.ids),
          );
          return server.ids;
        }),
      );
    });
  }

  /// Sends [ids] to the server, then marks the device's list sent unless it
  /// changed meanwhile. Returns the device's list afterwards.
  Future<List<String>> _send(String userId, List<String> ids) async {
    await _remote.replaceWishlist(WishlistModel(ids: ids));
    return _device(() async {
      final now = await _local.readWishlist();
      if (now == null || now.userId != userId) return ids;
      if (now.pending && _sameIds(now.ids, ids)) {
        await _local.writeWishlist(
          StoredWishlistModel(userId: userId, ids: ids),
        );
      }
      return now.ids;
    });
  }

  /// The stored ids when [stored] is [userId]'s; another user's list reads
  /// as empty.
  static List<String> _idsOf(StoredWishlistModel? stored, String userId) =>
      stored != null && stored.userId == userId ? stored.ids : const [];

  static List<WishlistItem> _items(List<String> ids) => [
    for (final id in ids) WishlistItem(productId: id),
  ];

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Runs [call] after every device read or write asked for before it.
  Future<T> _device<T>(Future<T> Function() call) {
    final result = _lastWrite.then((_) => call());
    _lastWrite = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// [_device] for a call that returns ids, mapped to the wishlist or a
  /// failure.
  Future<Either<Failure, List<WishlistItem>>> _onDevice(
    Future<List<String>> Function() call,
  ) async {
    try {
      return Right(_items(await _device(call)));
    } on WishlistStorageException {
      return Left(WishlistStorageFailure());
    } on _WishlistFullException {
      return Left(WishlistFullFailure());
    }
  }

  /// Runs [call] after every server call asked for before it, and maps
  /// what it throws to a failure.
  Future<Either<Failure, T>> _inOrder<T>(Future<T> Function() call) {
    final result = _lastCall.then<Either<Failure, T>>((_) async {
      try {
        return Right(await call());
      } on ServerException catch (e) {
        return Left(_toFailure(e));
      } on ConnectionException {
        return Left(NetworkFailure());
      } on WishlistStorageException {
        return Left(WishlistStorageFailure());
      }
    });
    _lastCall = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// The function has no wishlist-specific error codes; only a rejected
  /// token (401) gets its own failure.
  Failure _toFailure(ServerException e) => e.status == 401
      ? WishlistAuthRequiredFailure(code: e.status)
      : ServerFailure(errorCode: e.code, code: e.status);
}

/// Adding would take the wishlist past `WishlistRepository.maxItems`.
class _WishlistFullException implements Exception {
  const _WishlistFullException();
}
```

The contract's doc comment is the conflict rule (verbatim, `wishlist_repository.dart`):

```dart
/// The wishlist lives on the device, as the cart does: a heart tap is saved
/// on the device and returns at once, and the server gets a copy
/// afterwards ([pushWishlist]). [syncWishlist] reconciles the two:
///
/// - while this device holds a change the server has not accepted yet, the
///   device's list wins and is sent;
/// - otherwise the server's list wins and replaces the device's copy, so
///   changes made on another device show up.
///
/// Across devices the last list sent wins. The device keeps the list of
/// one user at a time; it stays when that user signs out, so a change not
/// sent yet goes out at their next sign-in. A different user signing in
/// replaces it.
abstract interface class WishlistRepository {
  /// The most products the server keeps in one wishlist.
  static const int maxItems = 50;
```

#### 3.F.3 Bloc — verbatim `wishlist_bloc.dart` (the device-first parts)

```dart
  Future<void> _onStarted(
    WishlistStarted event,
    Emitter<WishlistState> emit,
  ) async {
    final session = ++_session;
    _userId = event.userId;
    // Nothing of a previous user may show.
    _reset(emit);

    await _showSaved(emit, session, event.userId);
    await _refresh(emit, session, freshCatalog: false);
  }
```

```dart
  /// Shows the wishlist kept on this device, if any, marked stale until
  /// the sync with the server answers.
  Future<void> _showSaved(
    Emitter<WishlistState> emit,
    int session,
    String userId,
  ) async {
    final (wishlist, catalog) = await (
      _loadWishlist(LoadWishlistParams(userId: userId)),
      _getCachedCatalog(const NoParams()),
    ).wait;
    if (session != _session) return;

    final items = wishlist.getOrElse((_) => const []);
    final snapshot = catalog.toNullable();
    // Nothing saved, or no catalog to look the products up in: the
    // skeleton says more.
    if (items.isEmpty || snapshot == null) return;

    emit(
      state.copyWith(
        status: WishlistStatus.loaded,
        items: items,
        catalog: () => snapshot,
        isStale: true,
      ),
    );
  }
```

```dart
  Future<void> _onToggled(
    WishlistToggled event,
    Emitter<WishlistState> emit,
  ) async {
    final id = event.productId;
    final userId = _userId;
    if (userId == null) {
      emit(state.copyWith(toggleFailure: () => WishlistAuthRequiredFailure()));
      return;
    }
    // A second tap while the first is being saved is ignored.
    if (state.pendingIds.contains(id)) return;

    final session = _session;
    final wasSaved = state.contains(id);
    final index = state.items.indexWhere((item) => item.productId == id);

    emit(
      state.copyWith(
        items: wasSaved
            ? _without(state.items, id)
            : [WishlistItem(productId: id), ...state.items],
        pendingIds: {...state.pendingIds, id},
        toggleFailure: () => null,
      ),
    );

    if (!wasSaved) await _ensureCatalogHas(id, emit, session);

    final result = wasSaved
        ? await _removeFromWishlist(
            RemoveFromWishlistParams(userId: userId, productId: id),
          )
        : await _addToWishlist(
            AddToWishlistParams(userId: userId, productId: id),
          );
    if (session != _session) return;

    final pendingIds = {...state.pendingIds}..remove(id);
    emit(
      result.match(
        // Put only this item back as it was; other toggles stand.
        (failure) => state.copyWith(
          items: wasSaved
              ? _restored(state.items, id, index)
              : _without(state.items, id),
          pendingIds: pendingIds,
          toggleFailure: () => failure,
        ),
        (_) => state.copyWith(pendingIds: pendingIds),
      ),
    );

    // Saved on the device: the server gets it without holding up the next
    // tap. A failed send stays on the device for the next send or sync.
    if (result.isRight()) {
      _analytics?.track(
        wasSaved ? AppEvents.removeFromFavorite : AppEvents.addToFavorite,
        properties: {'item_id': id},
      );
      unawaited(_pushWishlist(PushWishlistParams(userId: userId)));
    }
  }
```

```dart
  /// [fresh] from the sync, with toggles still being saved kept as the
  /// user left them.
  List<WishlistItem> _keepPending(List<WishlistItem> fresh) {
    if (state.pendingIds.isEmpty) return fresh;

    var items = fresh;
    for (final id in state.pendingIds) {
      final isSaved = items.any((item) => item.productId == id);
      if (state.contains(id) && !isSaved) {
        items = [WishlistItem(productId: id), ...items];
      } else if (!state.contains(id) && isSaved) {
        items = _without(items, id);
      }
    }
    return items;
  }
```

Rules encoded: optimistic state change BEFORE the device write; `pendingIds` blocks a second
tap; roll back ONLY the failed item (`_restored` at its old `index`) and set the SEPARATE
`toggleFailure` so the page's refresh-message listener and the shell's toggle-message listener
each have a precise `listenWhen`; push with `unawaited(...)` after a successful device write; a
sync landing mid-toggle is reconciled by `_keepPending`; `_refresh` has the same section-20 shape
as cache-first plus the `session` check (`if (session != _session || userId == null || state.isBusy) return;`).
The toggle message is shown by the shell (`app_shell_scaffold.dart`):

```dart
    return BlocListener<WishlistBloc, WishlistState>(
      // A heart tap that failed and was undone.
      listenWhen: (previous, current) =>
          current.toggleFailure != null &&
          current.toggleFailure != previous.toggleFailure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('wishlist_toggleFailedMessage'),
            content: Text(wishlistToggleFailureMessage(state.toggleFailure)),
          ),
        ),
```

#### 3.F.4 Sign-in wiring (verbatim, `app.dart`) and DI

```dart
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                (current is Authenticated &&
                    (previous is! Authenticated ||
                        previous.user.id != current.user.id)) ||
                (current is Unauthenticated && previous is! Unauthenticated),
            listener: (context, state) {
              // …
              context.read<WishlistBloc>().add(
                state is Authenticated
                    ? WishlistStarted(state.user.id)
                    : WishlistCleared(),
              );
              context.read<CartBloc>().add(
                state is Authenticated
                    ? CartSignedIn(state.user.id)
                    : CartSignedOut(),
              );
              // …
              context.read<MaliCoinsBloc>().add(
                state is Authenticated
                    ? MaliCoinsStarted()
                    : MaliCoinsCleared(),
              );
              // The applied coupon is the signed-in user's; it is not kept
              // for the next one.
              if (state is! Authenticated) {
                context.read<CouponBloc>().add(CouponCleared());
              }
            },
          ),
```

```dart
void _registerWishlistData() {
  sl
    ..registerLazySingleton<WishlistRemoteDataSource>(
      () => WishlistRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<WishlistLocalDataSource>(
      () => WishlistLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<WishlistRepository>(
      () => WishlistRepositoryImpl(remote: sl(), local: sl()),
    );
}

/// Wishlist use cases and the app-wide wishlist bloc. They depend only on
/// [WishlistRepository], so tests can register a fake repository and then
/// call this. The bloc also looks products up in the catalog, so call
/// [registerCatalogFeature] first.
void registerWishlistFeature() {
  sl
    ..registerLazySingleton(() => LoadWishlist(sl()))
    ..registerLazySingleton(() => SyncWishlist(sl()))
    ..registerLazySingleton(() => PushWishlist(sl()))
    ..registerLazySingleton(() => AddToWishlist(sl()))
    ..registerLazySingleton(() => RemoveFromWishlist(sl()))
    ..registerFactory(
      () => WishlistBloc(
        loadWishlist: sl(),
        syncWishlist: sl(),
        pushWishlist: sl(),
        addToWishlist: sl(),
        removeFromWishlist: sl(),
        getCatalog: sl(),
        getCachedCatalog: sl(),
        analytics: sl(),
      ),
    );
}
```

#### 3.F.5 Tests that pin the strategy

| test | asserts |
|---|---|
| `test/features/wishlist/data/repositories/wishlist_repository_impl_test.dart` | `loadWishlist` reads the device with an empty `log`; another user's list reads as empty; add writes `'local.write prod_02,prod_01 (pending)'` and nothing else; already saved → no write; full → `WishlistFullFailure`, no write; push sends then `'local.write prod_01'` (pending cleared); push with nothing pending sends nothing; failed send keeps `pending`; a change made while sending stays pending (`replaceGate`); pushes waiting behind another are `identical` and send the latest list once; sync with nothing pending → `['remote.fetch', 'local.write prod_02']`; pending wins and is sent; an offline removal does not come back; a heart tapped while fetching is kept (`fetchGate`); another user's list is replaced; failure leaves the device copy; 401 → `WishlistAuthRequiredFailure` |
| `test/features/wishlist/data/datasources/wishlist_local_data_source_test.dart` | `SharedPreferences.setMockInitialValues({})`; write under `wishlistKey` and read back; malformed / non-map → `WishlistStorageException` |
| `test/features/wishlist/presentation/bloc/wishlist_bloc_test.dart` | miss + ok → `[loading, loaded]`; hit + ok → `[stale, stale.copyWith(isRefreshing: true), stale.copyWith(isStale: false, isRefreshing: false)]` with `catalog.catalogCalls == 0`; hit + fail keeps items, `isStale` true, `failure` set; toggle shows at once, is saved, then pushed (`wishlist.pushes == [_user]`); failed push leaves the toggle; a toggle the device refuses is not pushed; failed save rolls back + `toggleFailure`; failed remove restores at its index; a failure rolls back only its own item (`toggleGate`); second tap while pending ignored; refresh mid-toggle keeps the toggle; nobody signed in → `WishlistAuthRequiredFailure`; cleared drops late answers |
| `test/features/wishlist/presentation/pages/wishlist_page_test.dart` | `isStale` true then false; `wishlist_refreshFailedMessage` with `'No internet connection. Showing your saved wishlist.'` |

### 3.G DEVICE-FIRST with a merge and a serialized bloc (cart)

**Rule.** Same device-first contract as the wishlist (device is the truth, whole-list push,
pushes merged, `_inOrder` for server calls, `_onDevice` for device read-modify-writes) but the
reconciliation is a MERGE (`mergeServerLines`: larger quantity wins, server-only lines appended,
lines the shopper changed meanwhile keep the device's value) instead of a pending flag. The bloc
runs every handler one at a time (`_serial`) and NEVER awaits the network inside that queue: the
sign-in merge runs outside it and reports back with an internal `CartSyncFinished(syncId)` event;
pushes are `unawaited`; until the first merge has succeeded nothing is pushed (it would delete
server lines this device has not seen).

**File set:** `data/datasources/cart_local_data_source.dart`, `cart_remote_data_source.dart`,
`data/exceptions/cart_exceptions.dart`, `data/models/cart_item_model.dart`, `cart_model.dart`,
`server_cart_line_model.dart`, `data/repositories/cart_repository_impl.dart`,
`domain/repositories/cart_repository.dart`, `domain/utils/merge_cart.dart` (+ `cart_stock.dart`,
`saved_for_later.dart`), `domain/entities/cart.dart`, `cart_item.dart`, `cart_stock_check.dart`,
`domain/failures/cart_failures.dart`, the 9 use cases, `presentation/bloc/cart_{bloc,event,state}.dart`;
`CartBloc` is provided eagerly in `app.dart` (`lazy: false`, `..add(CartStarted())`).

#### 3.G.1 Device storage — verbatim `cart_local_data_source.dart` (complete)

```dart
import 'dart:convert';

import '../../../../core/services/pref_utils.dart';
import '../exceptions/cart_exceptions.dart';
import '../models/cart_model.dart';

/// The cart and its saved-for-later list, kept on the device through
/// `PrefUtils`. Throws [CartStorageException] on failure.
abstract interface class CartLocalDataSource {
  Future<CartModel> readCart();

  /// Writes the cart lines and the saved list in one save.
  Future<void> writeCart(CartModel cart);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  CartLocalDataSourceImpl(this._prefs);

  /// Holds the whole cart. The name dates from when only the lines were
  /// stored here; it is kept so those carts still load.
  static const String itemsKey = 'cart.items';

  final PrefUtils _prefs;

  @override
  Future<CartModel> readCart() async {
    await _prefs.init();
    final raw = _prefs.getJsonString(key: itemsKey);
    if (raw == null || raw.isEmpty) return const CartModel();

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw CartStorageException(e.message);
    }
    if (decoded is Map<String, dynamic>) return CartModel.fromJson(decoded);
    if (decoded is List) return CartModel.fromLegacyJson(decoded);
    throw const CartStorageException('Not a cart');
  }

  @override
  Future<void> writeCart(CartModel cart) async {
    await _prefs.init();
    final saved = await _prefs.setJsonString(
      key: itemsKey,
      jsonValue: jsonEncode(cart.toJson()),
    );
    if (!saved) throw const CartStorageException('Write failed');
  }
}
```

Difference from the wishlist: an absent cart reads as `const CartModel()` (never null), and an
older stored shape (a bare JSON list) is migrated on read by `CartModel.fromLegacyJson`.

#### 3.G.2 Merge helper — verbatim `merge_cart.dart` (complete)

```dart
import '../entities/cart.dart';
import '../entities/cart_item.dart';

/// [local] with the lines the server holds merged in. A variant on both
/// sides keeps the larger quantity; a variant only on the server is added
/// after the local lines. Server lines with no quantity are skipped.
/// Saved-for-later lines stay as they are: they are never sent to the
/// server.
///
/// Variants in [deviceWins] stay exactly as [local] has them, whether
/// lowered, removed or added: the shopper changed them while the server
/// was being asked, so the server's older copy must not undo that.
Cart mergeServerLines(
  Cart local,
  List<CartItem> server, {
  Set<String> deviceWins = const {},
}) {
  final items = [...local.items];
  for (final line in server) {
    if (line.quantity <= 0 || deviceWins.contains(line.variantId)) continue;
    final index = items.indexWhere((item) => item.variantId == line.variantId);
    if (index < 0) {
      items.add(line);
    } else if (line.quantity > items[index].quantity) {
      items[index] = items[index].copyWith(quantity: line.quantity);
    }
  }
  return Cart(items: items, savedForLater: local.savedForLater);
}

/// The variants whose cart line differs between [before] and [after]:
/// added, removed, or at another quantity.
Set<String> changedVariants(Cart before, Cart after) {
  final earlier = {
    for (final item in before.items) item.variantId: item.quantity,
  };
  final later = {for (final item in after.items) item.variantId: item.quantity};
  return {
    for (final id in {...earlier.keys, ...later.keys})
      if (earlier[id] != later[id]) id,
  };
}
```

#### 3.G.3 Repository — verbatim `cart_repository_impl.dart` (the device-first core)

```dart
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({
    required CartLocalDataSource local,
    required CartRemoteDataSource remote,
  }) : _local = local,
       _remote = remote;

  final CartLocalDataSource _local;
  final CartRemoteDataSource _remote;

  /// The last server call asked for; the next one waits for it.
  Future<void> _lastCall = Future.value();

  /// The last device read or read-modify-write asked for; the next one
  /// waits for it.
  Future<void> _lastDeviceCall = Future.value();

  /// A push that has not started yet, and the user it is for.
  Future<Either<Failure, Unit>>? _waitingPush;
  String? _waitingUserId;

  @override
  Future<Either<Failure, Cart>> loadCart() async {
    try {
      return Right(await _onDevice(_readCart));
    } on CartStorageException {
      return Left(CartStorageFailure());
    }
  }

  @override
  Future<Either<Failure, Cart>> syncCart(String userId) {
    // What the device holds as the sync is asked for, read now rather than
    // behind the server calls queued ahead: a line the shopper changes from
    // here on is theirs to keep, whatever the server's older copy says. A
    // failed read protects nothing; the merge's own read then fails too.
    final before = _onDevice(_readCart)
        .then<Cart?>((cart) => cart, onError: (Object _) => null);
    return _inOrder(() async {
      final server = await _remote.fetchLines();
      final earlier = await before;
      // The device is held only for the merge, never for a server call.
      final merged = await _onDevice(() async {
        final now = await _readCart();
        final merged = mergeServerLines(
          now,
          [for (final line in server) line.toEntity()],
          deviceWins: earlier == null
              ? const {}
              : changedVariants(earlier, now),
        );
        await _local.writeCart(CartModel.fromEntity(merged));
        return merged;
      });
      // The merge is done once it is saved. Sending it back runs behind this
      // call like any push: a failure there is silent, and the next change
      // sends the whole cart again.
      unawaited(pushCart(userId));
      return merged;
    });
  }

  @override
  Future<Either<Failure, Unit>> pushCart(String userId) {
    // A push that has not started yet reads the cart when it runs, so it
    // already covers this change.
    final waiting = _waitingPush;
    if (waiting != null && _waitingUserId == userId) return waiting;

    final push = _inOrder(() async {
      // Started: a change after this point needs a push of its own.
      _waitingPush = null;
      _waitingUserId = null;
      final cart = await _onDevice(_readCart);
      await _remote.replaceLines(userId: userId, lines: _linesOf(cart));
      return unit;
    });
    _waitingPush = push;
    _waitingUserId = userId;
    return push;
  }

  @override
  Future<Either<Failure, Cart>> saveItem(CartItem item) {
    return _update((cart) {
      final index = cart.items.indexWhere((i) => i.variantId == item.variantId);
      final items = [...cart.items];
      if (item.quantity <= 0) {
        if (index >= 0) items.removeAt(index);
      } else if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
      }
      return Cart(items: items, savedForLater: cart.savedForLater);
    });
  }

  @override
  Future<Either<Failure, Cart>> removeItems(List<String> variantIds) {
    final gone = variantIds.toSet();
    return _update(
      (cart) => Cart(
        items: [
          for (final item in cart.items)
            if (!gone.contains(item.variantId)) item,
        ],
        savedForLater: cart.savedForLater,
      ),
    );
  }

  @override
  Future<Either<Failure, Cart>> saveForLater(String variantId) {
    return _update((cart) => saveLineForLater(cart, variantId));
  }

  @override
  Future<Either<Failure, Cart>> moveToCart(String variantId) {
    return _update((cart) => moveSavedLineToCart(cart, variantId));
  }

  @override
  Future<Either<Failure, Cart>> removeSaved(String variantId) {
    return _update((cart) => removeSavedLine(cart, variantId));
  }

  @override
  Future<Either<Failure, CartStockCheck>> checkStock(
    List<CatalogProduct> products,
  ) async {
    try {
      return Right(
        await _onDevice(() async {
          final cart = await _readCart();
          final check = checkCartStock(cart, products);
          // Saved whenever a line changed, including a silent MRP update.
          if (check.cart != cart) {
            await _local.writeCart(CartModel.fromEntity(check.cart));
          }
          return check;
        }),
      );
    } on CartStorageException {
      return Left(CartStorageFailure());
    }
  }

  /// Reads the stored cart, applies [change] and writes the result back in
  /// one save.
  Future<Either<Failure, Cart>> _update(Cart Function(Cart cart) change) async {
    try {
      return Right(
        await _onDevice(() async {
          final updated = change(await _readCart());
          await _local.writeCart(CartModel.fromEntity(updated));
          return updated;
        }),
      );
    } on CartStorageException {
      return Left(CartStorageFailure());
    }
  }

  Future<Cart> _readCart() async => (await _local.readCart()).toEntity();

  /// Runs [call], a device read or read-modify-write, after every device
  /// call asked for before it. What it throws reaches the caller.
  Future<T> _onDevice<T>(Future<T> Function() call) {
    final result = _lastDeviceCall.then((_) => call());
    _lastDeviceCall = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// The lines of [cart] as the server stores them. The saved-for-later
  /// list is not sent.
  List<ServerCartLineModel> _linesOf(Cart cart) => [
    for (final item in cart.items) ServerCartLineModel.fromEntity(item),
  ];

  /// Runs [call] after every server call asked for before it, and maps
  /// what it throws to a failure.
  Future<Either<Failure, T>> _inOrder<T>(Future<T> Function() call) {
    final result = _lastCall.then<Either<Failure, T>>((_) async {
      try {
        return Right(await call());
      } on ServerException catch (e) {
        return Left(ServerFailure(errorCode: e.code, code: e.status));
      } on ConnectionException {
        return Left(NetworkFailure());
      } on CartStorageException {
        return Left(CartStorageFailure());
      }
    });
    _lastCall = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}
```

Note the naming difference between the two device-first repositories: the wishlist calls its
device queue `_device` (field `_lastWrite`) and its `Either`-mapping wrapper `_onDevice`; the cart
calls its device queue `_onDevice` (field `_lastDeviceCall`) and maps with `_update`. Both call
the server queue `_inOrder` (field `_lastCall`) and the shared pending push `_waitingPush` /
`_waitingUserId`. The queue idiom is identical:

```dart
    final result = _last.then((_) => call());
    _last = result.then<void>((_) {}, onError: (_) {});
    return result;
```

Whole-list replace on the server (`cart_remote_data_source.dart`): upsert first
(`POST … ?on_conflict=user_id,product_id`, `Prefer: resolution=merge-duplicates,return=minimal`),
then `DELETE … ?user_id=eq.<id>&product_id=not.in.("v1","v2")` with
`Prefer: return=representation` (a 204 would come back as `ErrorResponse`), so a failure never
leaves the server with fewer lines than the device.

#### 3.G.4 Bloc — verbatim `cart_bloc.dart` (the serialization and sync parts)

```dart
    on<CartStarted>((event, emit) => _serial(() => _onStarted(event, emit)));
    on<CartSignedIn>((event, emit) => _serial(() => _onSignedIn(event, emit)));
    on<CartSyncFinished>(
      (event, emit) => _serial(() => _onSyncFinished(event, emit)),
    );
    on<CartSignedOut>(
      (event, emit) => _serial(() => _onSignedOut(event, emit)),
    );
    on<CartItemAdded>(
      (event, emit) => _serial(() => _onItemAdded(event, emit)),
    );
    // … every other handler wrapped the same way, except:
    on<CartStockChangesSeen>(
      (event, emit) => emit(state.copyWith(stockChanges: () => null)),
    );
  }

  /// The last handler asked to run. Every handler waits for it, so the
  /// cart's events run one at a time whatever their type: a sign-in waits
  /// for the stored cart to load, and two taps never interleave their
  /// read-modify-write of the cart.
  ///
  /// Nothing in this queue waits on the network: the sign-in merge runs
  /// outside it and reports back with [CartSyncFinished], and pushes are
  /// not awaited. Otherwise a slow or hung request would hold up every
  /// tap behind it, and "Add to Cart" would seem to do nothing.
  Future<void> _queue = Future.value();

  Future<void> _serial(Future<void> Function() handler) {
    final run = _queue.then((_) => handler());
    _queue = run.then<void>((_) {}, onError: (_) {});
    return run;
  }
```

```dart
  /// The signed-in user, or null. Changes are sent to the server only while
  /// someone is signed in.
  String? _userId;

  /// Whether the server's lines have been merged in since [_userId] signed
  /// in. Until then the cart is not sent: sending it would delete the
  /// server lines this device has not seen.
  bool _synced = false;

  /// The user whose sign-in merge is running in the background, or null.
  /// One merge runs at a time per user; its answer comes back as a
  /// [CartSyncFinished].
  String? _syncingUserId;

  /// How many merges have been started. An answer carries the count it was
  /// started with, so one made stale by a sign-out or a later merge is
  /// ignored.
  int _syncCount = 0;

  /// Whether the cart's lines changed while the running merge was under
  /// way. Such a change may have missed the merge's copy, so the cart is
  /// sent again once the merge has succeeded, and the merge is asked for
  /// again when it failed.
  bool _changedWhileSyncing = false;

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading, failure: () => null));
    _emitResult(await _loadCart(const NoParams()), emit);
  }

  Future<void> _onSignedIn(CartSignedIn event, Emitter<CartState> emit) async {
    _userId = event.userId;
    _synced = false;
    _beginSync(event.userId);
  }

  /// Starts the sign-in merge for [userId] in the background, unless one
  /// is already running for them. The handlers' queue is not held up: the
  /// result comes back as a [CartSyncFinished] event.
  void _beginSync(String userId) {
    if (_syncingUserId == userId) return;
    _syncingUserId = userId;
    _changedWhileSyncing = false;
    final syncId = ++_syncCount;
    unawaited(
      _syncCart(SyncCartParams(userId: userId))
          .onError<Object>((error, stackTrace) {
            // The repository answers with failures, never throws; should
            // it, the merge still has to end, or nothing is sent again.
            addError(error, stackTrace);
            return Left(Failure(message: error.toString()));
          })
          .then((result) {
            if (isClosed) return;
            add(CartSyncFinished(userId, result, syncId: syncId));
          }),
    );
  }

  /// The sign-in merge finished. On success the stored cart, which holds
  /// the merged lines and any change made meanwhile, goes on screen and
  /// such a change is sent. A failed merge is silent: the device cart stays
  /// as it is, and a change made meanwhile asks for the merge once more.
  Future<void> _onSyncFinished(
    CartSyncFinished event,
    Emitter<CartState> emit,
  ) async {
    // A sign-out or a later merge moved the count on: this answer is stale.
    if (event.syncId != _syncCount) return;
    _syncingUserId = null;
    final changed = _changedWhileSyncing;
    _changedWhileSyncing = false;

    if (event.result.isLeft()) {
      if (changed) _beginSync(event.userId);
      return;
    }
    _synced = true;
    // The merge's own copy may predate a change made while it ran, so show
    // what the device holds now. Should that read fail, the merge's copy
    // is still the best there is.
    final stored = await _loadCart(const NoParams());
    _emitResult(stored.isRight() ? stored : event.result, emit);
    if (changed) unawaited(_pushCart(PushCartParams(userId: event.userId)));
  }

  Future<void> _onSignedOut(
    CartSignedOut event,
    Emitter<CartState> emit,
  ) async {
    // The cart stays on the device, but is no longer sent anywhere. A merge
    // still running answers to a count that no longer matches, so its
    // result is dropped, and signing in again starts a fresh one.
    _userId = null;
    _synced = false;
    _syncingUserId = null;
    _syncCount++;
    _changedWhileSyncing = false;
  }
```

```dart
  Future<void> _save(CartItem item, Emitter<CartState> emit) async {
    _emitChange(await _saveCartItem(item), emit);
  }

  /// Shows a change to the cart and, while a user is signed in, sends the
  /// cart to the server. The push is not awaited, so the next tap is not
  /// held up by the network.
  ///
  /// If the sign-in merge has not succeeded yet, the cart is not pushed:
  /// the change goes out with the merge, or right after it, and the merge
  /// is started again when none is running.
  void _emitChange(Either<Failure, Cart> result, Emitter<CartState> emit) {
    _emitResult(result, emit);
    final userId = _userId;
    if (userId == null || result.isLeft()) return;
    if (_synced) {
      unawaited(_pushCart(PushCartParams(userId: userId)));
      return;
    }
    // Noted before the merge is (re)started: a merge started now reads
    // this change, so it needs no push of its own.
    _changedWhileSyncing = true;
    _beginSync(userId);
  }

  void _emitResult(Either<Failure, Cart> result, Emitter<CartState> emit) {
    emit(
      result.match(
        (failure) =>
            state.copyWith(status: CartStatus.failure, failure: () => failure),
        (cart) => state.copyWith(
          status: CartStatus.ready,
          items: cart.items,
          savedForLater: cart.savedForLater,
          failure: () => null,
        ),
      ),
    );
  }
```

The internal event (verbatim, `cart_event.dart`):

```dart
/// The sign-in merge for [userId] finished with [result]: the merged cart,
/// or why it failed. Added by the bloc itself; screens do not send it.
class CartSyncFinished extends CartEvent {
  CartSyncFinished(this.userId, this.result, {required this.syncId});

  final String userId;
  final Either<Failure, Cart> result;

  /// Which merge this answers. One made stale by a sign-out or a later
  /// merge is ignored.
  final int syncId;
}
```

Rules encoded: a handler that mutates goes `_emitChange(await <device use case>, emit)`;
a handler that only shows (`_onStarted`, `_onSavedItemRemoved`) uses `_emitResult`; removing a
saved-for-later line is NOT pushed (saved list never leaves the device); `CartStatus` is
`initial, loading, ready, failure` with no `isStale`/`isRefreshing`; a failed push or sync never
sets `failure` (the device is the truth); `CartStockChangesSeen` is the one handler outside
`_serial` because it only clears a field.

#### 3.G.5 DI (verbatim)

```dart
void _registerCartData() {
  sl
    ..registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(local: sl(), remote: sl()),
    )
    ..registerLazySingleton<ChargeRulesRemoteDataSource>(
      () => ChargeRulesRemoteDataSourceImpl(
        networking: sl(),
        anonKey: Env.supabaseAnonKey,
      ),
    )
    ..registerLazySingleton<ChargeRulesLocalDataSource>(
      () => ChargeRulesLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ChargeRulesRepository>(
      () => ChargeRulesRepositoryImpl(remote: sl(), local: sl()),
    );
}

void registerCartFeature() {
  sl
    ..registerLazySingleton(() => LoadCart(sl()))
    ..registerLazySingleton(() => SaveCartItem(sl()))
    ..registerLazySingleton(() => SaveForLater(sl()))
    ..registerLazySingleton(() => MoveToCart(sl()))
    ..registerLazySingleton(() => RemoveSaved(sl()))
    ..registerLazySingleton(() => RemoveCartItems(sl()))
    ..registerLazySingleton(() => SyncCart(sl()))
    ..registerLazySingleton(() => PushCart(sl()))
    ..registerLazySingleton(() => CheckCartStock(sl()))
    ..registerLazySingleton(() => GetChargeRules(sl()))
    ..registerLazySingleton(() => GetCachedChargeRules(sl()))
    ..registerFactory(
      () => CartBloc(
        loadCart: sl(),
        saveCartItem: sl(),
        saveForLater: sl(),
        moveToCart: sl(),
        removeSaved: sl(),
        removeCartItems: sl(),
        syncCart: sl(),
        pushCart: sl(),
        checkCartStock: sl(),
        analytics: sl(),
      ),
    )
    ..registerFactory(
      () => CartPageBloc(
        getCatalog: sl(),
        getCachedCatalog: sl(),
        getChargeRules: sl(),
        getCachedChargeRules: sl(),
      ),
    );
}
```

```dart
// lib/app/app.dart
        // Eager, so the stored cart is loaded before any screen needs it.
        BlocProvider<CartBloc>(
          lazy: false,
          create: (_) => sl<CartBloc>()..add(CartStarted()),
        ),
```

#### 3.G.6 Tests that pin the strategy

| test | asserts |
|---|---|
| `test/features/cart/data/repositories/cart_repository_impl_test.dart` | device-only writes (`local.writes` counts), `saveItem` add/replace/remove-at-zero, `removeItems` one write, saved-for-later moves, storage exception → `CartStorageFailure`, `checkStock` writes only when changed and never calls the server (`remote.replaced` empty) |
| `test/features/cart/data/repositories/cart_repository_sync_test.dart` | a change made while the merge is being SAVED is kept (`local.writeGate`); a line changed while the server was ASKED is not undone (`remote.fetchGate` + `saveItem(quantity: 0)` → merged excludes it); a failed push-back still saves and returns the merged cart; merge saves then sends (`remote.replaced.single`); failed fetch leaves the device; `pushCart` sends lines not saved-for-later; three concurrent pushes send once; a push not started sends the cart as it is when it runs; a push after one finished sends again; failed push → `NetworkFailure` and nothing lost; storage failure → `CartStorageFailure` |
| `test/features/cart/data/datasources/cart_local_data_source_test.dart` | empty read; both lists under one key; legacy bare-list loads with `mrp == unit_price`; malformed / non-cart → `CartStorageException` |
| `test/features/cart/presentation/bloc/cart_bloc_test.dart` | `CartStarted` → `[loading, ready]`; add/increment/decrement/remove; `CartItemsRemoved` one write; unknown variant ignored; save failure keeps last cart with `status failure`; saved-for-later behaviours |
| `test/features/cart/presentation/bloc/cart_bloc_sync_test.dart` | sign-in merges server copy; failed sync silent; change while signed in pushed; while sync not succeeded a change is NOT pushed but re-syncs; retry success merges; changes during a running retry carried by one more retry (`syncGate`); sign-out drops a running merge's result; change shows at once while sync runs; server lines join when sync finishes and the meanwhile change is pushed; another user signing in starts their own merge; a line removed meanwhile stays removed |
| `test/features/cart/presentation/bloc/cart_bloc_stock_test.dart`, `cart_bloc_analytics_test.dart` | stock caps and analytics (MyMali-specific) |

**Copy:** 3.G.1–3.G.5 verbatim; the `_serial` queue; the `CartSyncFinished(syncId)` protocol;
`_synced`/`_changedWhileSyncing` gating; `mergeServerLines`/`changedVariants`. **Varies:** the
line entity, the server row shape and endpoint, saved-for-later, stock checks, analytics.

### 3.H FULL LOCAL-FIRST — designed, not implemented

No file in the repo implements this. AGENTS.md section 20 "Going local-first later" is the only
specification; it is reproduced here in condensed form so a skill can recognise and, if asked,
build it. **Ask the user before making any feature local-first** (per-feature decision; adds
shared code to `core`). Suits data the user creates (cart, wishlist, addresses, drafts); read-only
server data stays cache-first.

What already fits and must stay: blocs call use cases only and already handle "local copy
first, then server" (`getCached<Thing>` → read local store; `get<Thing>` → sync then read;
`isStale`/`isRefreshing` keep their meaning); only repositories choose local vs remote; only
local data sources touch `LocalCache`; models own JSON with a `schemaVersion`.

To add once, when the first local-first feature arrives:

1. **Watching.** `Stream<Object?> watch({box, key, version})` on `LocalCache`;
   `StreamUseCase<T, Params>` in `lib/core/usecases/usecase.dart`; repository gets
   `Stream<Either<Failure, T>> watch<Thing>()`. The stream carries only what is in the local
   store; server results are written to the store and reach the screen through the stream. The
   bloc subscribes with `emit.forEach` and never keeps its own `StreamSubscription`.
2. **Writes go local first.** A mutating repository method: (1) writes the change to the local
   store marked pending, (2) adds it to the outbox, (3) returns `Right` at once.
3. **The outbox** in `lib/core/services/sync/`, its own box in `CacheBoxes`. Entry = client-made
   id, feature, operation, payload JSON, created-at, try count. A `SyncService` sends entries in
   order when online, retries with backoff, removes an entry only after the server accepted it.
   Every operation is safe to send twice (server recognises the client id). Feature repositories
   register how to send their operations; the service knows no feature.
4. **Conflicts.** Each local-first repository states its rule in a doc comment agreed with the
   user (usually server wins, or newest `updated_at` wins). A rejected change becomes a
   `Failure` the screen can show, never dropped silently.
5. **Pending state.** If the screen must show "not synced yet", add a plain
   `bool isPendingSync` to the entity; the model stores it; nothing else about sync leaks into
   domain.
6. **Versions become migrations.** For local-first data a `schemaVersion` miss is data loss, so
   the local data source must read the old shape and rewrite it; `LocalCache` needs a way to
   read an older-version entry without deleting it (today `read` DELETES a version mismatch).
   Add that before the first local-first shape changes.
7. **Sign-out.** A user-scoped local-first box may hold unsent changes: try to sync first and
   ask the user what to do with the rest; never just `clearUserScoped()`.
8. **Size.** Boxes hold whole JSON documents; queries over thousands of rows need another engine
   (ask first) kept behind `LocalCache` or a sibling interface in `core/services/`.
9. **Tests to add:** a write is visible before the network answers; the outbox keeps order and
   survives a restart; a rejected change surfaces as a failure; a migration keeps the data.

The "Never" list that still applies: never import Hive outside `lib/core/services/local_cache/`;
never read `LocalCache` from a bloc, use case or repository; never return a `Stream` from a
repository to deliver cached-then-fresh (two use cases instead) EXCEPT for a local-first feature;
never change a model's JSON without bumping `schemaVersion`; never add a second cache service or
caching package; never let the cache fail a screen, request, sign-out or startup.

### 3.I Recognition guide: mapping another app onto MyMali's strategies

| You see in the target app… | It is… | Map onto MyMali as… |
|---|---|---|
| Every screen load goes straight to the API; no local DB/prefs read for that data; pull-to-refresh refetches; maybe a spinner over stale data | **NETWORK-ONLY** | `<Feature>RepositoryImpl({required remote})`, no `local:`; bloc with `status/items/failure/isRefreshing` + `isBusy`; one load event; page `listenWhen` on `loaded && failure changed` → SnackBar (3.B) |
| Reads SharedPreferences / Hive / sqflite / a JSON file first, shows it, then fetches and overwrites; "last updated" or stale badge; stale data thrown away freely; a `Future.wait([local, remote])` or `cache ?? await fetch` | **CACHE-FIRST (two use cases)** | `CacheBoxes.<feature>`, `<Feature>LocalDataSource` over `LocalCache`, repository with `_save`/`_cached` and `get<Thing>`/`getCached<Thing>`, bloc with `isStale`/`isRefreshing`/`isBusy` and `_showCached`/`_refresh` (3.C) |
| A cached value with an expiry/TTL (`expiresAt`, `Duration`, `maxAge`, `fetchedAt` compared to now); "don't refetch within N minutes"; de-duplication of concurrent requests (`_pendingFuture`, `inFlight`) | **CACHE-FIRST (TTL + shared in-flight)** | one method `get<Thing>({required bool refresh})`, `static const Duration <thing>MaxAge` on the domain interface, local DS passes `maxAge:`, repo `_inFlight ??= …whenComplete(() => _inFlight = null)` (3.D) |
| Per-id cache (`cache[productId]`, `'product_$id'` keys, LRU of opened items) | **CACHE-FIRST (keyed)** | `static String _xKey(String id) => 'x.$id'` in the local DS; `getCached<Thing>(id)` (3.E) |
| Cached data wiped on logout; "user" prefix in keys; profile/balance/addresses | **CACHE-FIRST (user-scoped)** | add the box to `CacheBoxes.userScoped`; `AuthLocalDataSourceImpl.clearTokens()` wipes it (3.E) |
| After create/update/delete the local cache is patched or invalidated | **CACHE-FIRST (mutations)** | `_updateCached(change)` after the remote call succeeds (3.E) |
| A list the user edits (cart, favourites, recent searches) stored locally and "synced" to the server; taps update the UI immediately; retries later; "dirty"/"unsynced"/`pending` flags; server only accepts the whole list; merge on login | **DEVICE-FIRST** | `PrefUtils` JSON under one key, `Stored<Thing>Model` with `pending` (wishlist form) or `merge<Thing>` + `changedVariants` (cart form), repository with `_inOrder`/`_device`(`_onDevice`)/`_waitingPush`, bloc pushing with `unawaited`, sync on `AuthBloc` sign-in via `app.dart` (3.F / 3.G) |
| An outbox / operation queue / "pending mutations" table; `isSynced` columns; a background `SyncService`/`WorkManager` job replaying operations with backoff; conflict resolution by timestamp; a local DB that is the source of truth for everything | **FULL LOCAL-FIRST** | not implemented in MyMali; apply the 9-point design in 3.H, and ask the user first |
| State that lives only in a bloc/provider and dies with the app (applied coupon, selected tab) | **MEMORY-ONLY app-wide bloc** | `CouponBloc` shape: app-wide `Bloc` in `app.dart`, `_session` counter, `…Cleared` event on sign-out; no data source (section 2.3 `CouponBloc`) |

Deciding questions for an unknown screen: (1) Is anything read before the first network call?
no → network-only. (2) If the network fails on first open with data saved, is the saved data
shown (stale) or is the screen an error? shown → cache-first; error → network-only with a
spinner. (3) When the user edits, does the write wait for the server? no, and a retry happens
later → device-first; yes → cache-first with mutations. (4) Is there a queue of individual
operations replayed in order? yes → full local-first.

---

## 4. Rules observed in code

Rules the code follows that AGENTS.md does not state, or states differently. Quotes are from
AGENTS.md.

1. **Local data source shape differs from the AGENTS §20 recipe snippet.** AGENTS shows
   `return json is Map<String, dynamic> ? CatalogSnapshotModel.fromJson(json) : null;` and
   `// clear → _cache.delete(...)`. The code reads
   `json is Map ? CatalogSnapshotModel.fromJson(asMap(json)) : null` (lenient `asMap`), routes
   through private `_read(key)`/`_write(key, json)` helpers, has `schemaVersion = 2` (recipe
   says `1`), and `clear() => _cache.clearBox(CacheBoxes.catalog)` (whole box). Only
   `CouponLocalDataSourceImpl.clear()` uses `_cache.delete`. Follow the code.
2. **`read` on a version mismatch DELETES the entry; on expiry it KEEPS it.** AGENTS states the
   delete for version/corrupt; the keep-on-expiry is only in the test
   ("an entry older than maxAge misses but is kept"). Reproduce both.
3. **`HiveLocalCache.read` on a closed box returns null without throwing; `write` throws
   `CacheException('Box "$box" is not open')`; `delete`/`clearBox` on a closed box do nothing.**
   AGENTS only says "reads miss and writes throw".
4. **Start-event guards vary by bloc.** AGENTS §20 step 7 says the start event calls the cached
   use case then refreshes. `HomeBloc._onHomeStarted` adds `if (state.isBusy) return;` and
   `if (state.status != HomeStatus.loaded) await _showCached(emit);` (a re-sent start never
   re-shows the cache over fresh data); `CategoriesBloc._onStarted` has the same two guards;
   `HelpSupportBloc._onStarted` has NEITHER (it always reads the cache, then `_refresh` applies
   the busy guard). The `_refresh` busy guard is universal.
5. **Decorations in `_showCached` default to empty, in `_refresh` to the previous state.**
   `_showCached`: `soldCounts.getOrElse((_) => const {})`; `_refresh`:
   `soldCounts.getOrElse((_) => state.soldBySku)`. AGENTS only states the refresh half.
6. **Parallel use-case calls use Dart 3 record `.wait`**:
   `final (a, b, c) = await (f1, f2, f3).wait;` — not `Future.wait`. Not in AGENTS.
7. **Network-only blocs reuse the §20 fields minus `isStale`**, and merge load/retry/refresh into
   ONE event (`NotificationsLoadRequested`); AGENTS describes separate start and refresh events
   for cache-first blocs. `CartStatus` uses `ready` instead of `loaded`.
8. **The TTL form breaks the "two methods" recipe on purpose.** AGENTS step 4: "Add one
   read-only method next to the existing remote one". Coupons and coin rules expose ONE method
   with `{required bool refresh}`; the `maxAge` constant lives on the DOMAIN interface
   (`CouponRepository.listMaxAge`, `MaliCoinsRepository.rulesMaxAge`) and the DATA local source
   imports the domain interface to read it. (AGENTS does mention `listMaxAge`/`rulesMaxAge` in
   the reference sections, so this is a documented variant, not a contradiction.)
9. **`_save`/`_cached` are duplicated per repository**, never shared via a mixin or base class —
   in catalog, charge rules, support, coins, coupons, product, address, seller. AGENTS says
   "Keep the two cache helpers private to the repository"; the code adds that the comments are
   also identical (`// Best-effort: the next successful load saves again.`).
10. **`MaliCoinsRepositoryImpl._guard<T>`** wraps remote calls once per repository instead of
    repeating try/catch per method. AGENTS does not name it; copy it when a repository has
    several remote methods with the same mapping.
11. **`getLowStockThresholds` catches EVERYTHING (`catch (_)`) and returns `Right({})`.**
    Configuration that must never break a screen is allowed to swallow all errors; the test
    "any other error yields an empty map" (a `StateError`) pins it. AGENTS §5 says repositories
    "catch typed exceptions"; this is the sanctioned exception.
12. **Repositories do not fall back to the cache on remote failure** — tested explicitly
    ("a failed fetch never falls back to the saved balance", log == `['remote.balance']`).
    AGENTS: "Don't fall back to the cache silently".
13. **Device-first local data sources throw FEATURE exceptions** (`WishlistStorageException`,
    `CartStorageException` in `data/exceptions/`), while `LocalCache`-based ones throw the core
    `CacheException`. Repositories map them to `WishlistStorageFailure`/`CartStorageFailure`,
    not `CacheMissFailure`. Every PrefUtils data source calls `await _prefs.init()` before each
    read and write (AGENTS does not mention `PrefUtils.init()`).
14. **PrefUtils-backed local data sources have NON-const constructors**
    (`WishlistLocalDataSourceImpl(this._prefs)`, `CartLocalDataSourceImpl(this._prefs)`),
    `LocalCache`-backed ones are `const`. `PrefUtils` is a class with a `static
    SharedPreferences?`, registered as `registerLazySingleton<PrefUtils>(PrefUtils.new)`.
15. **Device-first repositories are NOT `const`** (they hold mutable `_lastCall`, `_lastWrite`,
    `_waitingPush` fields); cache-first repositories without a clock ARE `const`
    (`CatalogRepositoryImpl`, `ChargeRulesRepositoryImpl`, `SupportRepositoryImpl`,
    `NotificationsRepositoryImpl`); ones with `DateTime Function() now` or `_inFlight` are not.
16. **Wishlist `_send` clears `pending` only when the stored ids are IDENTICAL (`_sameIds`) to
    the ones sent**, otherwise the newer change stays pending. AGENTS: "clears pending unless
    the list changed meanwhile" — the equality is positional.
17. **The cart sync reads `before` OUTSIDE the server queue** (`final before = _onDevice(_readCart)…`
    captured before `_inOrder`) so the device-wins set covers changes made while the sync waited
    behind other server calls. AGENTS describes `changedVariants(earlier, now)` but not the
    outside-the-queue read.
18. **`CartBloc._beginSync` guards against a throwing repository with `.onError<Object>` +
    `addError` + `Left(Failure(...))`**, and checks `isClosed` before `add(CartSyncFinished…)`.
    Not in AGENTS.
19. **`CartStockChangesSeen` is the one `CartBloc` handler not wrapped in `_serial`**; AGENTS
    says "CartBloc runs its handlers one at a time (`_serial`)".
20. **App-wide blocs use an `int _session` counter** (`MaliCoinsBloc`, `WishlistBloc`,
    `CouponBloc`) captured at handler start and compared after each `await`; `_reset(emit)`
    emits the empty state only when `state != empty`. AGENTS mentions dropping stale answers for
    the cart (`syncId`) but not this shared idiom.
21. **`WishlistState` is not `const` and carries derived fields (`ids`, `products`) computed in
    the initializer list and included in `props`.** AGENTS §10 says states are immutable with
    every field in props — satisfied — but the recipe examples all use `const` constructors.
22. **`CartPageState.copyWith` cannot clear `chargeRules`** (`chargeRules ?? this.chargeRules`,
    no getter) — a deviation from "Clearable nullable fields take a getter". Do not copy this
    slip; use `ChargeRules? Function()? chargeRules` in a new app.
23. **`CatalogSnapshot` (domain entity) has a non-final `products` field and a non-const
    constructor**, and `prepareCatalog` drops `count` (rebuilds without it → 0). AGENTS §4 says
    entities are immutable. Treat as legacy; do not copy.
24. **Repository tests assert the ORDER of side effects with a shared `log` list** passed to both
    fake data sources (`['remote.fetchSnapshot', 'local.writeSnapshot']`). AGENTS §14 mentions
    "the order of side effects" without the technique.
25. **Fakes hold calls open with `Completer<void>? gate`** (`gate`, `syncGate`, `toggleGate`,
    `fetchGate`, `replaceGate`, `writeGate`) and tests advance with `pumpEventQueue()` or
    `Future<void>.delayed(Duration.zero)` loops. `FakeLocalCache.now` is mutable for TTL tests.
26. **PostgREST writes that would answer 204 add `Prefer: return=representation`** because
    `NetworkingService` treats only 200/201/202 as success (AGENTS §6 states the 204 rule; the
    header workaround is in `NotificationsRemoteDataSourceImpl.markRead` and
    `CartRemoteDataSourceImpl.replaceLines`).
27. **`putAPICall` has no `headers` parameter** on `Networking`; AGENTS §6 anticipates this
    ("If NetworkingService lacks something (e.g. per-call headers on get/put), extend it in
    place").
28. **DI is split into a private `_register<Feature>Data()` (data sources + repository by
    abstract type) and a public `register<Feature>Feature()` (use cases + bloc factories)**, the
    latter documented as "They depend only on [XRepository], so tests can register a fake
    repository and then call this." AGENTS names only `register<Feature>Feature()`.
29. **Sign-out does not clear device-first data**: `WishlistCleared`/`CartSignedOut` only reset
    bloc state and stop pushing; `wishlist.saved` and `cart.items` stay in prefs;
    `clearUserScoped()` touches only Hive boxes. AGENTS states this; the code confirms
    `PrefUtils.clearAll()` is never called by sign-out.
30. **KO-Tech remote sources signal "no response" with `status == 0`** on their own exception
    types (`StockshipException(500, 'boom')`, `RefOrdersException(0, 'offline')`,
    `KoTokenException()`), mapped in the repository to `NetworkFailure` /
    `ServerFailure(errorCode: 'HTTP_${e.status}', code: e.status)` / `ServerFailure(errorCode: 'NO_KO_TOKEN', code: 401)`.
    MyMali-specific; Supabase sources use `ConnectionException`.

---

## 5. Packages

Versions from `pubspec.yaml` (caret constraints). "Files" lists the files in this area that
import the package directly.

| package | version | files importing it (this area) | ALWAYS / CONDITIONAL |
|---|---|---|---|
| `fpdart` | `^1.1.1` | every repository impl, repository contract, use case and bloc here (`Either`, `Left`, `Right`, `Unit`, `unit`, `.match`, `.toNullable()`, `.getOrElse`, `.swap()`, `.flatMap`, `.isRight()/.isLeft()`); `cart_event.dart` (`CartSyncFinished.result`) | ALWAYS |
| `equatable` | `^2.0.7` | every state and entity; `NoParams`; `api_response.dart` | ALWAYS |
| `flutter_bloc` | `^9.1.0` (+ `bloc ^9.0.0`) | every `*_bloc.dart`; pages (`BlocProvider`, `BlocListener`, `context.select/read`); `app.dart` | ALWAYS |
| `get_it` | `^8.0.3` | `lib/core/di/injection_container.dart` | ALWAYS |
| `dio` | `^5.11.1` | `lib/core/services/networking/networking.dart` (data sources only import `networking.dart`) | ALWAYS |
| `shared_preferences` | `^2.0.5` | `lib/core/services/pref_utils.dart`; tests `cart_local_data_source_test.dart`, `wishlist_local_data_source_test.dart` (`SharedPreferences.setMockInitialValues({})`) | ALWAYS (`PrefUtils` is core; required by device-first) |
| `hive_ce` | `^2.20.1` | tests only: `test/core/services/local_cache/hive_local_cache_test.dart` (`package:hive_ce/hive.dart`) | CONDITIONAL(app caches server data) |
| `hive_ce_flutter` | `^2.4.0` | `lib/core/services/local_cache/hive_local_cache.dart` (`package:hive_ce_flutter/hive_flutter.dart`) — the ONLY production import | CONDITIONAL(app caches server data) |
| `supabase_flutter` | `^2.17.2` | `bootstrap.dart`, `injection_container.dart` (`SupabaseClient`) — not by any file of the three strategies | ALWAYS in MyMali; CONDITIONAL(backend is Supabase) elsewhere |
| `go_router` | `^18.0.2` | `notifications_page.dart`, `help_support_page.dart`, `apply_coupon_page.dart`, `app.dart` | ALWAYS (routing) |
| `skeletonizer` | `^3.0.0` | `notifications_page.dart`, `help_support_page.dart` | CONDITIONAL(loading skeletons; AGENTS §21 mandates it for every skeleton) |
| `url_launcher` | `^6.2.5` | `help_support_page.dart` | CONDITIONAL(app opens mail/tel/web links) |
| `flutter_test` | sdk | every test | ALWAYS (dev) |
| `dart:convert` | sdk | `hive_local_cache.dart`, `wishlist_local_data_source.dart`, `cart_local_data_source.dart`, `fake_local_cache.dart`, `networking.dart` | ALWAYS |
| `dart:async` | sdk | `cart_repository_impl.dart`, `cart_bloc.dart`, `wishlist_bloc.dart` (`unawaited`), fakes (`Completer`) | ALWAYS |
| `dart:developer` | sdk | `orders_repository_impl.dart` (`log`), `mali_coins_bloc.dart` (`developer.log`), `pref_utils.dart`, `networking.dart` | ALWAYS |

Not used by this area but present in `pubspec.yaml` (other areas): `flutter_secure_storage`,
`cached_network_image`, `katyayani_core`, `firebase_*`, `facebook_app_events`,
`app_tracking_transparency`, `razorpay_flutter`, `pdf`, `share_plus`, `geolocator`, `geocoding`,
`image_picker`, `package_info_plus`, `flutter_local_notifications`, `intl_phone_field`,
`flutter_dotenv`, `crypto`, `connectivity_plus`, `internet_connection_checker`,
`loading_animation_widget`, `toastification`, `gap`, `intl`, `cupertino_icons`. No mocking package
(no mockito/mocktail/bloc_test): fakes are hand-written `implements` classes.

---

## 6. What varies per app

Everything another app substitutes, with where each appears.

| What | MyMali value(s) | Where it appears |
|---|---|---|
| Box names and the user-scoped list | `catalog`, `charge_rules`, `addresses`, `mali_coins`, `coin_rules`, `coupons`, `product`, `seller`, `support`; `userScoped = [addresses, maliCoins]` | `lib/core/services/local_cache/cache_boxes.dart`; asserted in `*_local_data_source_test.dart` (`CacheBoxes.all contains …`, `userScoped (not) contains …`) |
| Cache keys per local data source | `snapshot`, `sold_counts`, `low_stock_thresholds`, `rules` (charge rules AND coin rules, different boxes), `content`, `balance`, `active`, `addresses`, `region`, `product.<id>` | `static const String …Key` on each `…LocalDataSourceImpl` |
| `schemaVersion` per local data source | catalog `2`, charge rules `3`, support `1`, coins `1`, coupons `1`, product `1`, addresses `1` | `static const int schemaVersion` on each Impl; bump whenever the saved JSON shape changes |
| TTL constants | `CouponRepository.listMaxAge = Duration(minutes: 5)`, `MaliCoinsRepository.rulesMaxAge = Duration(minutes: 30)` | on the DOMAIN repository interfaces; passed as `maxAge:` from the local data source |
| Device-first prefs keys | `wishlist.saved`, `cart.items` | `WishlistLocalDataSourceImpl.wishlistKey`, `CartLocalDataSourceImpl.itemsKey` |
| Device-first limits | `WishlistRepository.maxItems = 50` | domain interface; `_WishlistFullException` → `WishlistFullFailure` |
| Token key shared with networking | `StringConstants.appAuthToken = 'auth.access_token'`; `auth.refresh_token`, `auth.user_id` | `string_constants.dart`, `auth_local_data_source.dart` |
| Endpoints | `/functions/v1/catalog-cache`, `/functions/v1/app-state`, `/rest/v1/product_sold`, `/rest/v1/products_v2`, `/functions/v1/user-data`, `/rest/v1/cart_items_v2`, `/rest/v1/charge_rules`, `/functions/v1/mali-coins`, `/rest/v1/coupons`, `/rest/v1/app_notifications`, Medusa `/store/products`, KO `/order/ref-orders`, StockShip `/api/orders` | `endpoints.dart` only; data sources reference `Endpoints.x` |
| Hosts | `ApiHost.supabase` (default), `medusa`, `koUtils`, `stockship`; `_thirdPartyHosts` | `networking.dart`; `host:` passed only on non-Supabase calls (`fetchProductsFromMedusa`) |
| Header getters per data source | `_edgeFunctionHeaders` (`apikey` + `Authorization: Bearer <anon>` for JWT-off functions; `apikey` only for functions that read the user token), `_restHeaders` (`apikey`), `_medusaHeaders` (`x-publishable-api-key`) | each remote data source |
| Env keys injected by DI | `Env.supabaseAnonKey`, `Env.medusaApiKey`, `Env.medusaBaseUrl` (Home `imageBaseUrl`), `Env.mktpId`, `Env.koEnv` | `injection_container.dart` only — never inside a data source |
| Server action / kind strings | mali-coins `welcome`/`balance`/`rules`; user-data `kind: 'wishlist'`, `list`/`replace`, `ok: true`; app-state `requestBody = {'platform': 'app', 'surfaces': <String>[], 'include_support': true}`; `supportNotConfiguredCode = 'NOT_CONFIGURED'`; `MaliCoinsRepositoryImpl.notConfiguredCode = 'NOT_CONFIGURED'` | remote data sources / repositories |
| PostgREST query maps | `soldCountsQuery`, `lowStockThresholdsQuery`, coupon `_listSelect`/`_checkSelect` + `and=(or(starts_at.is.null,starts_at.lte.$at),or(ends_at.is.null,ends_at.gte.$at))`, notifications `listColumns` + `order=created_at.desc`, cart `_select` + `order=updated_at.asc`, `on_conflict=user_id,product_id`, `Prefer` headers, charge rules `id=eq.1` | remote data sources |
| Model JSON keys | catalog `categories products count region_id updated_at cached`; cart `product_id variant_id title variant_label thumbnail unit_price mrp quantity` / `items saved_for_later`; server cart line `product_id qty name display_name hero_image seed_type variant_label web_price mrp`; wishlist `user_id ids pending` / `ids`; coupon `code type value min_subtotal description starts_at ends_at prepaid_only flat_total`; support `intro channels{kind,label,value,url} faqs{q,a}`; coins `balance expiring_next{amount,at} history{delta,reason,order_id,created_at}`, rules `earn_rate redeem_cap min_order_to_redeem expiry_months welcome_coins referral_reward referral_bonus earn_ways{key,icon,title,desc,coins}`; notification `id title body category created_at read data{imageUrl,actionUrl,deepLink,url}` | models |
| Domain helpers applied to both cached and fresh paths | `prepareCatalog`, `buildHomeSections(…, perSection: 5)`, `SoldCountModel.toSkuMap`, `LowStockThresholdModel.toSkuMap`, `wishlistProducts`, `mergeServerLines`/`changedVariants`, `checkCartStock`, `saveLineForLater`/`moveSavedLineToCart`/`removeSavedLine`, `withSavedAddress`/`withoutAddress`, `validateCoupon`/`normalizeCouponCode` | `domain/utils/` |
| Feature failures | `CouponsUnavailableFailure`, `CouponCodeEmptyFailure`, `CouponCheckFailure`, `InvalidCouponFailure`, `CouponNotStartedFailure`, `CouponExpiredFailure`, `CouponMinSubtotalFailure(couponCode, shortfall)`, `SupportUnavailableFailure`, `CoinsUnavailableFailure`, `CoinsAuthRequiredFailure`, `WishlistAuthRequiredFailure`, `WishlistFullFailure`, `WishlistStorageFailure`, `CartStorageFailure` (+ default messages) | `domain/failures/<feature>_failures.dart` |
| Status enums | `HomeStatus`, `CategoriesStatus`, `HelpSupportStatus`, `WishlistStatus`, `NotificationsStatus`, `CoinsPageStatus` = `{initial, loading, loaded, failure}`; `CartStatus = {initial, loading, ready, failure}` | state files |
| Event names | `HomeStarted({language})`/`HomeRefreshed`, `CategoriesStarted`/`CategoriesRefreshed`, `HelpSupportStarted`/`HelpSupportRefreshed`, `NotificationsLoadRequested`, `CoinsPageStarted`/`CoinsPageRefreshed`, `MaliCoinsStarted`/`…BalanceChanged`/`…Spent`/`…Cleared`, `WishlistStarted(userId)`/`…Refreshed`/`…Toggled(productId)`/`…Cleared`, `CartStarted`/`CartSignedIn(userId)`/`CartSyncFinished`/`CartSignedOut`/…, `CouponApplied(code)`/`…Removed`/`…CartChanged(subtotal)`/`…DroppedByServer(warning)`/`…Cleared`/`…FailureDismissed` | event files; `app.dart` fan-out |
| Analytics event names used by these blocs | `AppEvents.addToFavorite = 'Added To Favorite'`, `removeFromFavorite = 'Removed From Favorite'`, `productSavedForLater = 'Product Saved For Later'`, `productMovedToCart = 'Product Moved To Cart'`, `productQuantityChanged = 'Product Quantity Changed'`, `couponApplyTapped = 'Coupon Apply Tapped'`, `couponApplied = 'Coupon Applied'`, `couponRemoved = 'Coupon Removed'`, `supportChannelTapped = 'Support Channel Tapped'` | `lib/core/services/analytics/app_events.dart`; blocs take `AnalyticsService? analytics` (null in tests) |
| User-facing texts | `refreshFailureMessage` ("No internet connection. Showing saved products." / "Couldn't refresh right now. Showing saved products."), `wishlistRefreshFailureMessage` ("… Showing your saved wishlist."), `supportRefreshFailedMessage`, `notificationsFailureMessage`, coupon messages, `supportUnavailableMessage` | `presentation/**/utils/*message*.dart`, `support_texts.dart`, `notification_texts.dart` |
| Widget keys | `<screen>_refreshFailedMessage` (`home_`, `wishlist_`, `support_`, `notifications_`), `wishlist_toggleFailedMessage`, `<screen>_page`, `<screen>_scrollView`, `<screen>_backButton`, `support_errorView`/`support_emptyView`/`support_loadingSkeleton`, `notifications_tile_<id>`, `applyCoupon_*` | pages/widgets; asserted by page tests |
| Startup pieces around the cache | Firebase, `DeviceSecureStorage.init()`, `Supabase.initialize(authOptions: … SecureSessionStorage …)`, `_initEngagement()`, `requestTrackingPermission()` | `bootstrap.dart` — keep only `Env.load()` → `HiveLocalCache.init()` → `configureDependencies()` → `runApp` as the ALWAYS skeleton |
| App-wide blocs and their sign-in fan-out | `AuthBloc`, `ThemeBloc`, `CartBloc` (eager), `WishlistBloc`, `LocationBloc`, `MaliCoinsBloc`, `ProfileBloc`, `CouponBloc` (eager); `BlocListener<CartBloc>` → `CouponCartChanged(subtotal)` | `app.dart` |
| Test fixtures | `testVariant`/`testProduct`/`testCategory`/`testCatalog`/`testSections`/`testSoldCounts`/`testLowStockThresholds`, `testCartItem`, `welcome10`/`mali50`, `testSupportContent`, `testCoinRules`/`testCoinBalance`, `testChargeRules`, `notificationNamed(...)`; `FakeLocalCache` default clock `DateTime.utc(2026, 10, 1)` | `test/helpers/` |

---

## 7. Gotchas

1. **`LocalCache.write` takes `required Object json` that must be a JSON-encodable Map or List.**
   A bare `int` (coin balance) or `String` (region id) is wrapped: `{balanceKey: balance}`,
   `{'id': regionId}`. Writing a `DateTime` throws `CacheException` (tested).
2. **Read guards are `json is Map` / `json is List`, then `asMap(json)` / `asMapList(json)`.**
   Hive gives back `Map<dynamic, dynamic>` after `jsonDecode`; a cast to
   `Map<String, dynamic>` is what AGENTS's snippet shows and what the code deliberately avoids.
3. **An empty saved list is a HIT.** `readSoldCounts` on `[]` returns `[]`, not null; the repository
   then returns `Right({})`. Blocs decide separately that EMPTY cached data is not shown
   (`if (cached.isEmpty) return;`). Do not collapse "empty" into "miss" in the data source.
4. **Version mismatch deletes, expiry keeps.** After bumping `schemaVersion` old entries vanish
   on first read; after `maxAge` passes the entry stays and a `read` WITHOUT `maxAge` still
   returns it (the test "an entry older than maxAge misses but is kept" relies on this).
5. **`HiveLocalCache.init()` must run before `configureDependencies()`** and after
   `Supabase.initialize`; `openBoxes()` opens every name in `CacheBoxes.all` — a box missing from
   `all` is never open, so its reads always miss and its writes always throw `CacheException`
   (silently swallowed by `_save`). Symptom: a cache that never hits. Add the box to `all`.
6. **A box must be in `userScoped` to be wiped on sign-out**, and sign-out wiping lives in
   `AuthLocalDataSourceImpl.clearTokens()` wrapped in `try … on CacheException {}` — not in a
   bloc. Device-first prefs (`wishlist.saved`, `cart.items`) are NEVER wiped on sign-out by
   design.
7. **`CacheMissFailure` must never surface.** Blocs treat `Left` from `getCached…` as "emit
   nothing"; the page's refresh-message `listenWhen` requires `status == loaded`, which a miss
   never produces. Never add `CacheMissFailure` to a failure-to-text switch.
8. **`isStale` is set only by the cached/saved path and cleared only by a successful refresh.** A
   failed refresh leaves `isStale` as it was (tests assert `isStale` stays `true`). Do not clear
   it on failure.
9. **The refresh busy guard reads `state.isBusy` (`isLoading || isRefreshing`) and is the first
   line of `_refresh`.** Pull-to-refresh pages `await bloc.stream.firstWhere((s) => !s.isBusy)`;
   if `_refresh` returns early because busy, the stream still settles when the running load
   finishes.
10. **`copyWith` nullable fields take `T? Function()?` getters** (`failure: () => null`,
    `catalog: () => snapshot`, `appState: () => nextAppState`). Passing the value directly
    (`failure: null`) is a no-op. `CartPageState.chargeRules` is the one place that forgot.
11. **Events never extend Equatable**; `WishlistState` is NOT `const` (derived `ids`/`products`
    in the initializer); tests compare `WishlistState()` instances by Equatable value, not
    identity.
12. **`SuccessResponse.statusCode` and `ErrorResponse.errorCode` are `String`s** — parse with
    `int.tryParse(response.errorCode) ?? 0`. Only 200/201/202 are `SuccessResponse`; a 204
    becomes `ErrorResponse`, hence `Prefer: return=representation` on PATCH/DELETE.
13. **Two `ServerException` classes exist** (`core/app/exceptions/api_exceptions.dart` used by
    data sources, and a legacy one in `app_exceptions.dart`). Data sources import
    `app_exceptions.dart` with `show AppException` to avoid the clash.
14. **`_save`/`_cached` catch ONLY `CacheException`.** A `FormatException` from a model's
    `fromJson` would propagate — models use lenient `json_readers` precisely so they never throw
    on bad shapes.
15. **Cache the raw server MODEL, not the derived entity.** `getCatalog` saves the snapshot with
    hidden products and runs `prepareCatalog` on read; `getCachedHomeSections` rebuilds rails
    from the same snapshot. Saving derived data would duplicate the key and break "one fetch
    path per cache entry".
16. **One fetch path per cache entry**: `getCatalog` and `getHomeSections` both go through
    `_fetchSnapshot`; two methods writing different data under the same key is the bug this
    prevents.
17. **TTL constants live on the DOMAIN interface and are imported by the DATA local source**
    (`import '../../domain/repositories/coupon_repository.dart'` inside
    `coupon_local_data_source.dart`). This is an intentional data→domain dependency (allowed by
    §3); do not move the constant to the data layer.
18. **Shared in-flight requests use `??=` + `whenComplete`:**
    `return _inFlight ??= _fetchActive().whenComplete(() => _inFlight = null);` — the
    `whenComplete` must clear the field or every later call reuses a finished future.
19. **Device-first queues must swallow errors in the chain tail**:
    `_last = result.then<void>((_) {}, onError: (_) {});` — without `onError` a failed call
    breaks the queue for every later call.
20. **`pushWishlist`/`pushCart` return the SAME future for a push that has not started**
    (`identical(second, third)` is tested). Clear `_waitingPush`/`_waitingUserId` as the FIRST
    statement inside the queued closure, not after the send.
21. **Never `await` the network inside `CartBloc`'s `_serial` queue.** The merge goes through
    `_beginSync` → `unawaited(...)` → `add(CartSyncFinished(...))`; pushes are `unawaited`. The
    cart's Dio clients have no timeouts, so an awaited call would freeze every tap.
22. **Until the first merge succeeds, the cart is not pushed** (`_synced == false`); a change
    sets `_changedWhileSyncing = true` and re-starts the merge. Pushing earlier would delete
    server lines the device has not seen (whole-list replace).
23. **Wishlist toggles are optimistic BEFORE the device write**, with `pendingIds` blocking a
    second tap and `toggleFailure` (not `failure`) carrying the rollback reason, so two
    listeners (`page: status == loaded && failure changed`, `shell: toggleFailure changed`) never
    fire for each other's events.
24. **`WishlistRepositoryImpl._send` clears `pending` only if the stored ids are positionally
    identical to what was sent**; a tap during the send keeps `pending` for the next push.
25. **Cart `syncCart` captures `before` outside `_inOrder`** so `changedVariants(earlier, now)`
    includes taps made while the sync waited behind earlier server calls; the device is held
    (`_onDevice`) only for the merge, never during `fetchLines`.
26. **Legacy stored shapes are migrated on read, not versioned**: `CartModel.fromLegacyJson(List)`
    for pre-saved-for-later carts, `CartItemModel.mrp ??= unitPrice`. PrefUtils data has no
    `schemaVersion`; changing a device-first JSON shape needs a read-time migration like this.
27. **`PrefUtils` holds a `static SharedPreferences?`** and `init()` is `_sharedPreferences ??=
    await SharedPreferences.getInstance()`; every data source method starts with
    `await _prefs.init()`. In tests call `SharedPreferences.setMockInitialValues({})` in `setUp`
    and note the instance is cached across tests of one file.
28. **Session counters (`_session`, `_syncCount`) are captured BEFORE the first `await` and
    compared after EACH `await`**, including between two sequential awaits in one handler
    (`MaliCoinsBloc._onStarted` checks twice). Missing one check shows a previous user's data.
29. **`_reset(emit)` compares to a `const` empty state and emits only on change** — a `const`
    constructor is required for `MaliCoinsState()`; `WishlistBloc._reset` builds a non-const
    `WishlistState()` and compares by Equatable.
30. **Network-only repositories still normalise input and short-circuit** (`_tenDigits`,
    `refId.trim()`) returning `Right(null)` / empty page without a request; tests assert
    `calls.isEmpty`.
31. **Decoration failures in a network-only or cache-first bloc keep the previous value**
    (`getOrElse((_) => state.soldBySku)`), while a "rules the server says do not exist" failure
    (`CoinsUnavailableFailure`) DROPS the value (`_nextRules`). Distinguish "could not load" from
    "does not exist" per failure type.
32. **Repository tests pass ONE `log` list to both fakes** to assert `['remote.x', 'local.writeX']`
    ordering; a cached read test asserts `log.where(startsWith('remote.'))` is empty. Reproduce
    the technique — it is what proves "write after fetch" and "cached never hits the network".
33. **Do not copy the cosmetic slips**: misplaced doc comment above `CacheBoxes.seller`,
    `// ← ADD THIS` comments in `catalog_snapshot_model.dart`, the non-final `products` on
    `CatalogSnapshot`, `CartPageState.copyWith`'s non-clearable `chargeRules`, `PrefUtils.getAllData`
    printing, `StringConstants` legacy noise.

