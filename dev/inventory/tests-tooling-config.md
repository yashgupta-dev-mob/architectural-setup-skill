# Inventory: tests-tooling-config

Repo: `C:/Users/Katyayani/Documents/flutter/mymali` (package `mymali`), read on 2026-10-14.
Toolchain observed: Flutter 3.47.5 stable (revision `6a19cca564`), Dart 3.13.4, DevTools 2.60.0. `pubspec.lock` `sdks:` block: `dart: ">=3.13.4 <4.0.0"`, `flutter: ">=3.47.0"`.

Scope: every file in `test/helpers/`, `test/widget_test.dart`, 29 representative tests (model round-trip, data source over `FakeNetworking`, repository exception→failure, bloc, page tests that pump `App`, local-cache, secure-storage, Env, generic widgets, plugin method-channel fakes), `analysis_options.yaml`, `pubspec.yaml` (+ resolved versions from `pubspec.lock`), `.env.example` (and the key names of `.env`, values not read), `tool/sync_native_env.dart`, `.gitignore` (+ `android/.gitignore`, `ios/.gitignore`), `.claude/settings.json`, the native config the architecture touches (`android/app/build.gradle.kts`, `android/settings.gradle.kts`, `android/build.gradle.kts`, `AndroidManifest.xml`, `ios/Runner/Info.plist`, `ios/Flutter/Debug.xcconfig`, `Release.xcconfig`, the "Copy Firebase Config" phase in `project.pbxproj`), and the `lib/` files the fakes implement (`Networking`, `APIResponse`, `Failure`, `LocalCache`, `SecureStorage`, `PaymentGateway`, `KoEngagementService`, `AnalyticsService`, `KoAnalyticsService`, `injection_container.dart`, `app.dart`, `bootstrap.dart`, `env.dart`, `usecase.dart`, `pref_utils.dart`, exceptions, `SplashPage`, `AppRouter`, `AppInfoSheet`, `AppPickerSheet`, `DeviceSecureStorage`, `SecureSessionStorage`, `HiveLocalCache`, `CacheBoxes`).

Numbers: 258 `*_test.dart` files; 1456 `test(` and 463 `testWidgets(` occurrences; 14 test files pump `App(...)`; 23 set `tester.view.physicalSize`; 22 call `tearDown(sl.reset)` (one more does it inside a block); 40 test files use a `Completer<void>` gate; 384 distinct `Key('<screen>_<element>')` strings in `lib/`; zero `// ignore` comments in `lib/`.

---

## 1. Files

Legend: **ALWAYS** = generic architecture, install in every app · **CONDITIONAL(x)** = install only when the target app has capability x · **MYMALI-SPECIFIC** = this app's business. "Placeholders" = the exact MyMali values another app substitutes.

### 1a. `test/helpers/` (all 29 files, read in full)

| path | role | class | placeholders |
|---|---|---|---|
| `test/helpers/fake_networking.dart` | In-memory `Networking`: `RecordedCall`, `FakeNetworking` (`response`, `error`, `queued`, `calls`, `lastCall`), `okResponse()`, `errorResponse()`. Used by 22 test files | ALWAYS | `package:mymali/…` import prefix; `ApiHost.supabase` default (the app's default host enum value); `getAPICall/postAPICall/deleteAPICall/patchAPICall` must match the app's `Networking` signatures |
| `test/helpers/fake_auth_repository.dart` | In-memory `AuthRepository` + `testSession` constant; gates `sendOtpGate`/`verifyOtpGate`, failures `sendOtpFailure`/`verifyOtpFailure`, recorders `sentOtps`/`verifiedOtps`. The AGENTS.md-named reference fake. Used by 20 files | ALWAYS (template of "fake repository"); body CONDITIONAL(app has phone-OTP auth with this `AuthRepository` contract) | `AuthSession`, `AuthUser(id, phone, fullName, roles, activeRole, userKey)`, `OtpRequest`, `VerifyOtpRequest`; values `user-1`, `+919876543210`, `Asha`, `CUSTOMER`, `91987654-3210-0000-0000-000000000000`, `access`, `refresh`, `DateTime.utc(2030)` |
| `test/helpers/fake_local_cache.dart` | In-memory `LocalCache` honouring `version` and `maxAge` against a mutable `now`; `readError`/`writeError`; `clearUserScopedCalls`; `keysOf(box)`. Used by 13 files | CONDITIONAL(app caches server data through `LocalCache`) | default clock `DateTime.utc(2026, 10, 1)`; reads `CacheBoxes.userScoped` |
| `test/helpers/fake_secure_storage.dart` | In-memory `SecureStorage` with a public `values` map. Used by 2 files | CONDITIONAL(app stores tokens in `SecureStorage`) | none |
| `test/helpers/fake_payment_gateway.dart` | In-memory `PaymentGateway`: `payment`, `error`, `gate`, `checkouts`, `lastCheckout`. Used by 1 file (`checkout_repository_impl_test.dart`) | CONDITIONAL(app has an online payment sheet behind `PaymentGateway`) | `GatewayPayment(paymentId: 'pay_01', orderId: 'order_01', signature: 'sig_01')` |
| `test/helpers/fake_ko_engagement_service.dart` | Recording `KoEngagementService` (`identified`, `resetCount`, `initCount`, `events`, `tracked`, `screens`, `registerPushCount`) + `registerFakeEngagement()` which registers it **and** `AnalyticsService` = `KoAnalyticsService(fake)` in `sl`. Used by 28 files | CONDITIONAL(app has an engagement/analytics service the `App` widget provides) — the *shape* (one recording fake, one `register…()` helper that satisfies every `sl<…>()` `App` performs) is ALWAYS | `KoEngagementService`, `KoAnalyticsService`, `AnalyticsItem`, method list (`identify`, `resetIdentity`, `requestPushPermission`, `registerPush`, `track`, `screenView`, `viewItem`, `addToCart`, `removeFromCart`, `viewCart`, `beginCheckout`, `purchase`, `search`, `login`, `addPaymentInfo`, `capturePayment`, `checkNudges`) |
| `test/helpers/signed_in_app.dart` | `registerSignedInApp({auth, coins, wishlist, profile, referral, account, engagement})`, `launchSignedInApp(tester)`, `openAccountTab(tester)`, `scrollAccountTo(tester, finder)`: the one-call setup for a page test of the signed-in app. Used by 10 files | ALWAYS (pattern); contents MYMALI-SPECIFIC | the list of repositories `App` needs (`AuthRepository`, `CatalogRepository`, `AppConfigRepository`, `CartRepository`, `WishlistRepository`, `LocationRepository`, `MaliCoinsRepository`, `CouponRepository`), the `register<Feature>Feature()` list, `SplashPage.displayDuration`, `HomePage`, keys `shell_accountTab`, `account_page`, `account_scrollView` |
| `test/helpers/fake_account_repository.dart` | `FakeAccountRepository({version})` + `registerAccountFakes({profile, referral, account})` (composite: registers 3 fake repos then 3 feature functions) | MYMALI-SPECIFIC (pattern of a composite registrar is ALWAYS) | `AppVersion(version: '1.0.1', buildNumber: '9')` |
| `test/helpers/fake_address_repository.dart` | `FakeAddressRepository({addresses})`, `testAddress`; `gate`, `changeGate`, `loadFailure`/`saveFailure`/`removeFailure`, `saved`/`removed`, `cachedAddresses` | MYMALI-SPECIFIC | Bhopal address values |
| `test/helpers/fake_app_config_repository.dart` | `FakeAppConfigRepository`, `testAppState`; `appStateFailure`, `requests` | MYMALI-SPECIFIC | `releaseId: 'rel_01'`, banner, `VersionSettings(latest: '1.0.2', minSupported: '1.0.0')` |
| `test/helpers/fake_cart_remote_data_source.dart` | `FakeCartRemoteDataSource({lines})` (a **data-source** fake, for repository tests): `fetchError`, `replaceError`, `fetchGate`, `replaced` | MYMALI-SPECIFIC (shape: a data-source fake lives in helpers only when 2+ tests share it) | `ServerCartLineModel` |
| `test/helpers/fake_cart_repository.dart` | `FakeCartRepository({items, savedForLater})`, `testCartItem`; `gate`, `syncGate`, `loadFailure`, `saveFailure`, `syncFailure`, `pushFailure`, recorders; `syncCart` re-runs the real `mergeServerLines`/`changedVariants` | MYMALI-SPECIFIC | |
| `test/helpers/fake_catalog_repository.dart` | `FakeCatalogRepository` with `gate`, 4 `…Failure`, 4 `…Calls`, 4 `cached…` (null = miss) and private `_cached<T>`; constants `testVariant`, `testProduct`, `testCategory`, `testCatalog`, `testSections`, `testSoldCounts`, `testLowStockThresholds`. Used by 33 files (most-used helper) | MYMALI-SPECIFIC (its *shape* is the cache-first fake template) | `prod_01`, `variant_01`, `MM-NEEM-250`, `Activated Neem Oil`, `pcat_01`, `Liquid Tonics`, `reg_01` |
| `test/helpers/fake_charge_rules_repository.dart` | `FakeChargeRulesRepository({rules, cached})`, `testChargeRules` | MYMALI-SPECIFIC | |
| `test/helpers/fake_checkout_repository.dart` | `FakeCheckoutRepository({prices, coinsAvailable, codCharge})`: a stand-in that *prices* a quote like the server; `gate`, `placeGate`, `registerGate`, `paymentGate`; `requests`, `placedOrders`, `registeredOrders`, `payments`, `records`, `identities` | MYMALI-SPECIFIC | |
| `test/helpers/fake_coupon_repository.dart` | `FakeCouponRepository({coupons, now})`, `welcome10`, `mali50`; runs the real `normalizeCouponCode`/`validateCoupon` | MYMALI-SPECIFIC | |
| `test/helpers/fake_delivery_repository.dart` | `FakeDeliveryRepository({rows})`; returns `Option.fromNullable` | MYMALI-SPECIFIC | |
| `test/helpers/fake_gstin_repository.dart` | `FakeGstinRepository`, `validGstinNumber = '27AAPFU0939F1ZV'`, `savedGstin`; runs real `validateGstin` | MYMALI-SPECIFIC | |
| `test/helpers/fake_location_repository.dart` | `FakeLocationRepository({selectedPlace})`, `testPlace`; `searchGate`, `currentGate`; default "search finds nothing, GPS unavailable" | MYMALI-SPECIFIC | |
| `test/helpers/fake_mali_coins_repository.dart` | `FakeMaliCoinsRepository({balance, rules})`, `testCoinRules`, `testCoinBalance`; `cachedBalance`, `rulesRefreshes`, `gate`; `rules == null` → `ServerFailure(errorCode: 'NOT_CONFIGURED')` | MYMALI-SPECIFIC | |
| `test/helpers/fake_notifications_repository.dart` | `FakeNotificationsRepository`, `notificationNamed(id, {isRead, category, createdAt})` factory | MYMALI-SPECIFIC | |
| `test/helpers/fake_orders_repository.dart` | `FakeOrdersRepository`: `found`, `byId`, `findCallsBeforeMatch`, `refOrders`, `refCallsBeforeMatch`, `pages`; recorders as records `({String phone, DateTime placedAt})` | MYMALI-SPECIFIC | |
| `test/helpers/fake_product_repository.dart` | `FakeProductRepository({product, cached})`, `testLargeVariant`, `testDetail`, `testReview`, `testDetailSoldOut`; private `_write()` | MYMALI-SPECIFIC | |
| `test/helpers/fake_profile_repository.dart` | `FakeProfileRepository({profile})`, `avatars`, `picked`, `saveGate` | MYMALI-SPECIFIC | |
| `test/helpers/fake_referral_repository.dart` | `FakeReferralRepository({summary})`, `testReferralSummary`, `validCode = 'FRIEND1'` | MYMALI-SPECIFIC | |
| `test/helpers/fake_seller_repository.dart` | `FakeSellerRepository({seller, cachedSeller})`, `testSeller` | MYMALI-SPECIFIC | |
| `test/helpers/fake_support_repository.dart` | `FakeSupportRepository({content, cachedContent})`, `testSupportContent` | MYMALI-SPECIFIC | |
| `test/helpers/fake_wishlist_repository.dart` | `FakeWishlistRepository({ids})`; `cachedIds`, `gate`, `toggleGate`, `pushes`, `lastUserId` | MYMALI-SPECIFIC | |

### 1b. Tests read in full or in part (the conventions come from these)

| path | role | class | placeholders |
|---|---|---|---|
| `test/widget_test.dart` | **Not** the template counter test: the full splash → login → OTP → home → sign-out flow, with the hand-rolled `setUp` that registers every fake `App` needs; helpers `pumpApp`, `passSplash`, `input(key)`, `tapKey`, `loginBloc(tester)`, `authBloc(tester)` | ALWAYS (pattern) | keys `login_nameField`, `login_phoneNumberField`, `login_getOtpButton`, `login_otpField`, `login_verifyButton`, `login_editNumberButton`, `shell_accountTab`, `account_footer`, `account_scrollView`, `account_signOutButton`, `account_signOutSheet`; texts |
| `test/features/auth/data/models/auth_tokens_model_test.dart` | Model round-trip test (the reference) | ALWAYS | JSON keys `access_token`, `refresh_token`, `user_id` |
| `test/features/auth/data/datasources/auth_remote_data_source_test.dart` | Data-source test with a **file-private** `_FakeNetworking` (predates the shared helper) and `_ok`/`_error` builders; asserts endpoint, body, headers, `ServerException` fields, `ConnectionException` | ALWAYS (pattern) | `/functions/v1/phone-login`, `apikey`/`Authorization: Bearer anon-key` |
| `test/features/auth/data/repositories/auth_repository_impl_test.dart` | Repository test: private `_FakeRemote`/`_FakeSession`/`_FakeLocal`, code→failure map loop, order of side effects (`local.saved` length 2), refresh stream, `dispose()` | ALWAYS (pattern) | error codes `INVALID_PHONE`, `OTP_SEND_FAILED`, `NOT_CONFIGURED`, `INVALID_OTP`, `OTP_EXPIRED`, `OTP_NOT_SENT`, `OTP_ATTEMPTS_EXCEEDED`, `OTP_VERIFY_FAILED`, `USER_CREATE_FAILED`, `SESSION_FAILED`, `INVALID_BODY`, `PGRST301` |
| `test/features/auth/presentation/login/bloc/login_bloc_test.dart` | Bloc test built directly with use cases over `FakeAuthRepository`; `dispatch`/`dispatchAll`; gate re-entrancy tests | ALWAYS (pattern) | `LoginBloc`, `LoginStatus`, `LoginStep` |
| `test/features/catalog/presentation/categories/bloc/categories_bloc_test.dart` | Cache-first bloc test: the `[loaded(stale), loaded(stale, refreshing), loaded(fresh)]` sequence, "empty saved data is not shown", "a failed refresh keeps data" | CONDITIONAL(cache-first) pattern | |
| `test/features/catalog/presentation/categories/pages/categories_page_test.dart` | Page test pumping `App`; hand-rolled `setUp`; `AppPickerSheet.closeKey`; the `gate` held open to show saved data; failed-refresh SnackBar text; analytics `named(event)` helper | ALWAYS (pattern) | keys `shell_categoriesTab`, `catalog_*` |
| `test/features/catalog/data/datasources/catalog_local_data_source_test.dart` | Local data source over `FakeLocalCache`: miss → null, write-then-read equality by `toJson()`, `keysOf`, `schemaVersion + 1` miss, `CacheException` pass-through | CONDITIONAL(cache) | `CacheBoxes.catalog`, `snapshotKey` |
| `test/features/catalog/data/repositories/catalog_repository_impl_test.dart` | Repository test with a shared `log` list for the order of side effects (`['remote.fetchSnapshot', 'local.writeSnapshot']`), cache write that throws still returns `Right`, cached reads never touch remote | CONDITIONAL(cache) pattern | |
| `test/core/services/local_cache/hive_local_cache_test.dart` | Real Hive in a temp dir: `Hive.init(dir)`, `HiveLocalCache.openBoxes()`, injected clock, corrupt entries list | CONDITIONAL(cache) | box `catalog`, key `snapshot` |
| `test/core/services/secure_storage/device_secure_storage_test.dart` | Real class over `FlutterSecureStorage.setMockInitialValues`, `DeviceSecureStorage.resetMemory()`, `SharedPreferences.setMockInitialValues`, fresh-install wipe | CONDITIONAL(tokens) | `auth.access_token`, `DeviceSecureStorage.installedKey` |
| `test/core/services/secure_storage/secure_session_storage_test.dart` | `SecureSessionStorage` over `FakeSecureStorage` + real `PrefUtils`; `keyFor(url)` | CONDITIONAL(Supabase session) | `sb-abcd1234-auth-token` |
| `test/features/auth/data/datasources/auth_local_data_source_test.dart` | Local DS over `FakeSecureStorage` + `FakeLocalCache` + real `PrefUtils`; legacy-prefs migration; `clearUserScopedCalls == 1` | CONDITIONAL(tokens) | the 3 token keys |
| `test/core/config/env_test.dart` | `dotenv.loadFromString`, `Env` switch getters, `Env.allowTestPayments` reset in `tearDown` | ALWAYS (pattern) | `KO_ENV`, `*_PROD/_BETA`, `RAZORPAY_MODE` |
| `test/core/widgets/app_network_image_test.dart` | Asserts on `CachedNetworkImage.imageUrl`/`memCacheWidth`; `MaterialApp(theme: AppTheme.light)` | CONDITIONAL(network images) | |
| `test/core/widgets/sheets/app_info_sheet_test.dart` | `AppInfoSheet.show` result (true/false), `actionKey`/`closeKey`, tone icons, long message scroll | ALWAYS | |
| `test/core/widgets/buttons/primary_button_test.dart` | Generic widget test: `MaterialApp(theme: AppTheme.light, home: Scaffold(body: Center(child: …)))`; default 800×600 test surface | ALWAYS | |
| `test/features/account/presentation/account/pages/account_page_test.dart` | Page test via `registerSignedInApp(...)` + `launchSignedInApp` + `openAccountTab` + `scrollAccountTo`; `textOf(key)`; `AppInfoSheet.closeKey/actionKey` | ALWAYS (pattern) | `account_*` keys |
| `test/app/app_engagement_test.dart` | `App`-level test of identify/reset/screens/`registerPush`; `PushPermissionPrompt.resetForTest()` | CONDITIONAL(analytics/push) | screen names `ShopTab`, `CategoriesTab` |
| `test/core/services/kotech/ko_token_service_test.dart` | Service over `FakeNetworking` (response swapping, `calls.single`, `lastCall.data`, `error = app.AppException(...)`) | MYMALI-SPECIFIC (pattern ALWAYS) | |
| `test/features/orders/data/datasources/stockship_remote_data_source_test.dart` | `FakeNetworking.queued` for a 401-then-200 retry; `host: ApiHost.stockship`; `_FakeTokens` private fake | MYMALI-SPECIFIC (pattern ALWAYS) | |
| `test/features/cart/data/repositories/cart_repository_sync_test.dart` | `pumpEventQueue()` between steps; `writeGate`/`fetchGate` on data-source fakes; device-wins merge | MYMALI-SPECIFIC (pattern ALWAYS) | |
| `test/features/checkout/data/repositories/checkout_repository_impl_test.dart` (head) | `_FakeKoOrders(answers)` "list of answers, the last repeats", `_FakeAttempts`, `_FakeMedusaCustomers` map-of-answers, `FakePaymentGateway` | MYMALI-SPECIFIC | |
| `test/features/product/presentation/product_detail/pages/product_detail_page_test.dart` (head) | Pushing a route from a test: `router = AppRouter().router; … router.pushNamed(AppRoute.productDetail.name, pathParameters: {ProductDetailPage.idParam: 'prod_01'})` | ALWAYS (pattern) | |
| `test/features/checkout/presentation/order_placed/bloc/order_placed_bloc_test.dart` (head) | Injected `now: () => now` and `wait: (d) async { waits.add(d); now = now.add(d); }` | ALWAYS (pattern for timed blocs) | |
| `test/features/invoice/presentation/invoice/pages/invoice_page_test.dart` (head) | Plugin method-channel mocks: `MethodChannel('dev.fluttercommunity.plus/share')`, `MethodChannel('plugins.flutter.io/path_provider')` via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`; `tearDown(() { …; sl.reset(); })` | CONDITIONAL(share/PDF) | |
| `test/features/referral/presentation/refer/pages/referral_page_test.dart` (head) | `dotenv.loadFromString(envString: 'APP_WEB_ORIGIN=https://example.com/app')` inside a page test; `settle: false` pumping while a gate holds a skeleton open | MYMALI-SPECIFIC (patterns ALWAYS) | |
| `test/core/services/analytics/meta_analytics_destination_test.dart` (head) | `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test()` file; method-channel mock of the Meta plugin | CONDITIONAL(Meta) | |
| `test/core/services/payments/razorpay_payment_gateway_test.dart` (head) | Pure function test of `classifyRazorpayError` | CONDITIONAL(payments) | |

### 1c. Tooling and config

| path | role | class | placeholders |
|---|---|---|---|
| `analysis_options.yaml` | `include: package:flutter_lints/flutter.yaml`; analyzer `exclude:` `build/**, android/**, ios/**, web/**, windows/**, macos/**, linux/**`; **no** custom lint rules (the `rules:` block is the template's comments only) | ALWAYS | none |
| `pubspec.yaml` | `name: mymali`, `version: 1.0.1+21`, `sdk: ^3.13.4`; dependencies (section 5); `assets:` 3 PNGs + `.env`; `fonts:` Marcellus; `flutter_launcher_icons:` block | ALWAYS (skeleton) | `name`, `version`, asset paths `assets/icon.png`, `assets/applogo.png`, `assets/coin.png`, font `Marcellus` / `assets/fonts/Marcellus-Regular.ttf`, launcher `image_path: assets/applogo.png`, `adaptive_icon_background: "#FFFFFF"`, `theme_color: "#13372E"`, `background_color: "#FFFFFF"` |
| `.env.example` | Every `.env` key with a placeholder value, grouped by host; comments explain `KO_ENV` and `RAZORPAY_MODE` | ALWAYS (pattern) | all keys except `SUPABASE_URL`/`SUPABASE_ANON_KEY` are MyMali hosts (section 6) |
| `.env` (git-ignored; only key names read) | Same 22 key names as `.env.example` (verified: identical sets; `.env.example` lists `RAZORPAY_MODE` twice, one commented) | ALWAYS (pattern) | values |
| `tool/sync_native_env.dart` | Copies `FB_APP_ID`, `FB_CLIENT_TOKEN` from `.env` into `ios/Flutter/Env.xcconfig`; run `dart run tool/sync_native_env.dart` from the repo root | CONDITIONAL(a native iOS value must come from `.env`, here Meta) | `_keys` list |
| `.gitignore` | Flutter template + `.env`, `.mcp.json` ("holds a token"), `ios/Flutter/Env.xcconfig` | ALWAYS | none |
| `android/.gitignore` | Template: `key.properties`, `**/*.keystore`, `**/*.jks`, `/local.properties` (so `android/key.properties` and `android/app/upload-keystore.jks`, present locally, are untracked) | ALWAYS | |
| `ios/.gitignore` | Template | ALWAYS | |
| `.claude/settings.json` | Permission allowlist proving the dev commands: `Bash(dart analyze *)`, `Bash(flutter test *)`, `Bash(dart format *)`, `Bash(python -)`, plus one-off `sed -i` edits | tooling (ALWAYS as evidence of the workflow) | paths |
| `.mcp.json` | MCP server config for `katyayani-core-mcp`; **contains a token**; git-ignored. Never copy | MYMALI-SPECIFIC | |
| `flutter_project_audit.md` | A 279-line prompt ("For the AI agent running this file: audit the Flutter project…") that encodes the package/architecture preferences this codebase follows (flutter_bloc, go_router, get_it, dio, fpdart, hive_ce, cached_network_image, skeletonizer, flutter_secure_storage for tokens, mocktail over mockito…). Read-only tooling | tooling, optional | none |
| `README.md`, `devtools_options.yaml`, `.metadata` | Flutter template defaults (README untouched) | ALWAYS (defaults) | `.metadata` `revision: 6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, `unmanaged_files: lib/main.dart, ios/Runner.xcodeproj/project.pbxproj` |
| `android/app/build.gradle.kts` | Conditional `com.google.gms.google-services` plugin (`if (file("google-services.json").exists())`); parses the repo-root `.env` for `FB_APP_ID`/`FB_CLIENT_TOKEN` → `resValue` strings + `facebook_auto_init` bool; optional `key.properties` signing with debug fallback; `isCoreLibraryDesugaringEnabled = true` (for `flutter_local_notifications`); `applicationId`/`namespace` | ALWAYS (orientation is in the manifest; the `.env` parse and google-services guard are CONDITIONAL(firebase / Meta)) | `com.katyayani.mymali`, `desugar_jdk_libs:2.1.4`, Java 17 |
| `android/settings.gradle.kts` | AGP `9.1.0`, Kotlin `2.4.0`, `com.google.gms.google-services` `4.4.4` `apply false` | CONDITIONAL(firebase) for the gms line | versions |
| `android/build.gradle.kts` | Template + `subprojects` block raising any plugin `compileSdk < 34` to `36` ("android_play_install_referrer, via katyayani_core") | MYMALI-SPECIFIC (the raise); rest template | |
| `android/gradle.properties` | `org.gradle.jvmargs=-Xmx8G …`, `android.useAndroidX=true`, `android.newDsl=false`, `android.builtInKotlin=false` | ALWAYS (template) | |
| `android/app/src/main/AndroidManifest.xml` | `android:screenOrientation="portrait"` (orientation lock, ALWAYS); permissions INTERNET, ACCESS_NETWORK_STATE, COARSE/FINE_LOCATION, POST_NOTIFICATIONS, VIBRATE; FCM `default_notification_channel_id` = `push_campaigns`, `default_notification_icon` = `@drawable/notification_icon`; Meta meta-data reading `@string/facebook_app_id`, `@string/facebook_client_token`, `@bool/facebook_auto_init`; `<queries>` for `upi:` VIEW intents | ALWAYS (orientation); rest CONDITIONAL(location/push/Meta/UPI) | `android:label="mymali"`, channel id, schemes |
| `ios/Runner/Info.plist` | `UISupportedInterfaceOrientations` (+`~ipad`) = Portrait only, `UIRequiresFullScreen`; `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSUserTrackingUsageDescription`; `LSApplicationQueriesSchemes` (tez, gpay, phonepe, paytm, paytmmp, bhim, credpay, amazonpay, upi, fbapi, fb-messenger-share-api); `FacebookAppID $(FB_APP_ID)`, `FacebookClientToken $(FB_CLIENT_TOKEN)`, `CFBundleURLSchemes fb$(FB_APP_ID)` | ALWAYS (orientation); rest CONDITIONAL | `CFBundleDisplayName Mymali`, `CFBundleName mymali`, usage strings |
| `ios/Flutter/Debug.xcconfig`, `Release.xcconfig` | Exactly: `#include "Generated.xcconfig"` then `#include? "Env.xcconfig"` (optional include, so a build without the generated file still works) | CONDITIONAL(.env → iOS) | |
| `ios/Runner.xcodeproj/project.pbxproj` → build phase `FB5E0C0A2E7A4B9100C0FFEE /* Copy Firebase Config */` | Shell: copies `Runner/GoogleService-Info.plist` into the app bundle only if present, else `echo "warning: GoogleService-Info.plist not found; Firebase is off in this build."` | CONDITIONAL(firebase) | |
| `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | Firebase config. **Tracked in git** (see Rules/Gotchas: comments say git-ignored) | CONDITIONAL(firebase) | project `getmymali` |
| `assets/` | `applogo.png` (745 KB), `coin.png`, `icon.png`, `fonts/Marcellus-Regular.ttf` + `Marcellus-OFL.txt` | app-specific | |
| `android/app/src/main/res/raw/notification.wav`, `drawable-night-*/notification_icon.png`, `values-night/` | Push channel sound and small icon | CONDITIONAL(push) | |
| `web/`, `windows/`, `linux/`, `macos/` | Present (template); excluded by the analyzer; Firebase must not be set up there (AGENTS §23) | template | |

### 1d. `lib/` files read because the fakes implement or the tests touch them (owned by other areas; listed for the names the tests use)

| path | role | class |
|---|---|---|
| `lib/core/services/networking/networking.dart` | `enum ApiHost { supabase, medusa, koUtils, stockship }`; `abstract class Networking` (get/post/patch/put/delete/graphql); `NetworkingService` | ALWAYS (ApiHost values are placeholders) |
| `lib/core/app/api/api_response.dart` | `APIResponse extends Equatable`, `SuccessResponse`, `ErrorResponse`, `InvalidResponse` | ALWAYS (legacy-styled but load-bearing for the fakes) |
| `lib/core/app/failure.dart` | `Failure`, `NetworkFailure`, `ServerFailure(errorCode)`, `CacheMissFailure` | ALWAYS |
| `lib/core/app/exceptions/app_exceptions.dart` | `AppException(message, prefix)`, `InternetException`, `RequestTimeoutException`, `ServerException` (**name clash**, see Gotchas), `InvalidUrlException`, `FetchDataException`, `UnAuthorizedException`, `AuthException` | ALWAYS |
| `lib/core/app/exceptions/api_exceptions.dart` | `ServerException({code, status, detail})`, `ConnectionException([message])` | ALWAYS |
| `lib/core/app/exceptions/cache_exceptions.dart` | `CacheException([message])` | CONDITIONAL(cache) |
| `lib/core/usecases/usecase.dart` | `UseCase<T, Params>`, `NoParams` | ALWAYS |
| `lib/core/services/pref_utils.dart` | `PrefUtils` (static `SharedPreferences`) | ALWAYS |
| `lib/core/utils/string_constants.dart` | legacy; `appAuthToken = 'auth.access_token'` is live | ALWAYS (that one const) |
| `lib/core/services/local_cache/{local_cache,cache_boxes,hive_local_cache}.dart` | `LocalCache`, `CacheBoxes`, `HiveLocalCache` | CONDITIONAL(cache) |
| `lib/core/services/secure_storage/{secure_storage,device_secure_storage,secure_session_storage}.dart` | `SecureStorage`, `DeviceSecureStorage`, `SecureSessionStorage` | CONDITIONAL(tokens / Supabase) |
| `lib/core/services/payments/payment_gateway.dart` | `GatewayCheckout`, `GatewayPayment`, `GatewayPaymentError`, `GatewayPaymentException`, `PaymentGateway` | CONDITIONAL(payments) |
| `lib/core/services/katyayani_core/ko_engagement_service.dart`, `lib/core/services/analytics/{analytics_service,ko_analytics_service}.dart` | the engagement/analytics interfaces the fake implements | CONDITIONAL(analytics) |
| `lib/core/di/injection_container.dart` | `sl`, `configureDependencies()`, `_register<Feature>Data()` (private) + `register<Feature>Feature()` (public) pairs | ALWAYS |
| `lib/app/app.dart`, `lib/app/bootstrap.dart` | `App(router:)`, `App.maxTextScaleFactor`, `bootstrap()` | ALWAYS |
| `lib/core/config/env.dart` | `Env`, `KoEnv`, `RazorpayMode`, `Env.allowTestPayments` | ALWAYS (getters are placeholders) |
| `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics})`, `late final GoRouter router` | ALWAYS |
| `lib/features/auth/presentation/splash/pages/splash_page.dart` | `SplashPage.displayDuration = Duration(milliseconds: 2600)` | ALWAYS (pattern) |
| `lib/core/widgets/sheets/{app_info_sheet,app_picker_sheet}.dart` | `AppInfoSheet.show`, `actionKey`, `closeKey`, `defaultActionLabel`; `AppPickerSheet.show<T>`, `closeKey` | ALWAYS |
| `lib/features/home/presentation/home/widgets/push_permission_prompt.dart` | `resetForTest()`, `settleDelay`, `locationWait` | CONDITIONAL(push) |
| `lib/features/checkout/presentation/order_placed/pages/order_placed_page.dart` | `@visibleForTesting static final Set<String> reportedOrders` | MYMALI-SPECIFIC |
| `lib/core/app/bloc/connectivity_bloc/connectivity_bloc.dart` | legacy; imports `connectivity_plus` + `internet_connection_checker`; **not referenced anywhere outside its folder** | legacy, do not copy |
| Feedback call sites: `categories_page.dart`, `login_page.dart`, `app_shell_scaffold.dart`, `address_form_page.dart`, `orders/presentation/utils/buy_again_to_cart.dart` | see Pattern 18 | MYMALI content, ALWAYS shape |

---

## 2. Names

Public names another app must reproduce exactly (spelling, casing, parameters).

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `RecordedCall` | class | `test/helpers/fake_networking.dart` | `const RecordedCall({required this.method, required this.endpoint, this.queryParameters, this.data, this.headers, this.pathParameters, this.host = ApiHost.supabase});` fields `String method; String endpoint; Map<String, dynamic>? queryParameters; Object? data; Map<String, String>? headers; Map<String, dynamic>? pathParameters; ApiHost host;` |
| `FakeNetworking` | class `implements Networking` | same | `Object? response; Object? error; final List<Object?> queued = []; final List<RecordedCall> calls = []; RecordedCall get lastCall => calls.last;` overrides `getAPICall`, `postAPICall`, `deleteAPICall`, `patchAPICall` (method strings `'GET'`, `'POST'`, `'DELETE'`, `'PATCH'`); private `Object? _answer()`; `noSuchMethod` passthrough |
| `okResponse` | top-level function | same | `SuccessResponse okResponse(Object? body) => SuccessResponse(successMessage: '', statusCode: '200', rawData: body, data: body);` |
| `errorResponse` | top-level function | same | `ErrorResponse errorResponse(Object? body, String status) => ErrorResponse(errorMessage: '', errorCode: status, data: null, rawData: body);` |
| `testSession` | top-level `final` | `fake_auth_repository.dart` | `AuthSession(user: const AuthUser(id: 'user-1', phone: '+919876543210', fullName: 'Asha', roles: ['CUSTOMER'], activeRole: 'CUSTOMER', userKey: '91987654-3210-0000-0000-000000000000'), accessToken: 'access', refreshToken: 'refresh', expiresAt: DateTime.utc(2030))` |
| `FakeAuthRepository` | class `implements AuthRepository` | same | `FakeAuthRepository({this.hasActiveSession = false}); @override bool hasActiveSession; Failure? sendOtpFailure; Failure? verifyOtpFailure; Completer<void>? sendOtpGate; Completer<void>? verifyOtpGate; final List<OtpRequest> sentOtps = []; final List<VerifyOtpRequest> verifiedOtps = [];` |
| `FakeLocalCache` | class `implements LocalCache` | `fake_local_cache.dart` | `FakeLocalCache({DateTime? now}) : now = now ?? DateTime.utc(2026, 10, 1); DateTime now; CacheException? readError; CacheException? writeError; int clearUserScopedCalls = 0; List<String> keysOf(String box)`; private `_Entry({version, savedAt, json})` |
| `FakeSecureStorage` | class `implements SecureStorage` | `fake_secure_storage.dart` | `FakeSecureStorage([Map<String, String>? values]) : values = {...?values}; final Map<String, String> values;` |
| `FakePaymentGateway` | class `implements PaymentGateway` | `fake_payment_gateway.dart` | `GatewayPayment payment = const GatewayPayment(paymentId: 'pay_01', orderId: 'order_01', signature: 'sig_01'); GatewayPaymentException? error; Completer<void>? gate; final List<GatewayCheckout> checkouts = []; GatewayCheckout get lastCheckout => checkouts.last;` |
| `FakeKoEngagementService` | class `implements KoEngagementService` | `fake_ko_engagement_service.dart` | `final List<String> identified = []; int resetCount = 0; int initCount = 0; final List<String> events = []; final List<({String name, Map<String, dynamic>? properties})> tracked = []; final List<String> screens = []; int registerPushCount = 0;` typed events push fixed strings into `events`: `'screen_view'`, `'view_item'`, `'add_to_cart'`, `'remove_from_cart'`, `'view_cart'`, `'begin_checkout'`, `'purchase'`, `'search'`, `'login'`, `'add_payment_info'`, `'capture_payment'`, `'check_nudges'` |
| `registerFakeEngagement` | top-level function | same | `FakeKoEngagementService registerFakeEngagement() { final fake = FakeKoEngagementService(); sl.registerSingleton<KoEngagementService>(fake); sl.registerSingleton<AnalyticsService>(KoAnalyticsService(fake)); return fake; }` |
| `registerSignedInApp` | top-level function | `signed_in_app.dart` | `void registerSignedInApp({FakeAuthRepository? auth, FakeMaliCoinsRepository? coins, FakeWishlistRepository? wishlist, FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account, FakeKoEngagementService? engagement})` |
| `launchSignedInApp` | top-level function | same | `Future<void> launchSignedInApp(WidgetTester tester)` — sets `physicalSize = const Size(1170, 2532)`, `devicePixelRatio = 3`, `addTearDown(tester.view.reset)`, pumps `App(router: AppRouter(analytics: sl<AnalyticsService>()).router)`, `pump(SplashPage.displayDuration)`, `pumpAndSettle()`, `expect(find.byType(HomePage), findsOneWidget)` |
| `openAccountTab` | top-level function | same | `Future<void> openAccountTab(WidgetTester tester)` — taps `Key('shell_accountTab')`, expects `Key('account_page')` |
| `scrollAccountTo` | top-level function | same | `Future<void> scrollAccountTo(WidgetTester tester, Finder finder)` — `scrollUntilVisible(finder, 250, scrollable: find.descendant(of: find.byKey(const Key('account_scrollView')), matching: find.byType(Scrollable)))` |
| `registerAccountFakes` | top-level function | `fake_account_repository.dart` | `void registerAccountFakes({FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account})` — registers 3 repos then `registerProfileFeature(); registerReferralFeature(); registerAccountFeature();` |
| `FakeCatalogRepository` | class | `fake_catalog_repository.dart` | `Failure? catalogFailure; Failure? homeSectionsFailure; Failure? soldCountsFailure; Failure? lowStockThresholdsFailure; int catalogCalls = 0; … CatalogSnapshot catalog = testCatalog; List<HomeSection> sections = testSections; bool? lastRefresh; CatalogSnapshot? cachedCatalog; List<HomeSection>? cachedSections; Map<String, int>? cachedSoldCounts; Map<String, int>? cachedLowStockThresholds; Completer<void>? gate;` private `Either<Failure, T> _cached<T>(T? value) => value == null ? Left(CacheMissFailure()) : Right(value);` |
| `testVariant`, `testProduct`, `testCategory`, `testCatalog`, `testSections`, `testSoldCounts`, `testLowStockThresholds` | top-level consts/finals | same | see file (section 3, Pattern 2) |
| Other fakes | classes | `test/helpers/fake_*.dart` | `FakeAccountRepository`, `FakeAddressRepository`, `FakeAppConfigRepository`, `FakeCartRemoteDataSource`, `FakeCartRepository`, `FakeChargeRulesRepository`, `FakeCheckoutRepository`, `FakeCouponRepository`, `FakeDeliveryRepository`, `FakeGstinRepository`, `FakeLocationRepository`, `FakeMaliCoinsRepository`, `FakeNotificationsRepository`, `FakeOrdersRepository`, `FakeProductRepository`, `FakeProfileRepository`, `FakeReferralRepository`, `FakeSellerRepository`, `FakeSupportRepository`, `FakeWishlistRepository`; test data `testAddress`, `testAppState`, `testCartItem`, `testChargeRules`, `welcome10`, `mali50`, `validGstinNumber`, `savedGstin`, `testPlace`, `testCoinRules`, `testCoinBalance`, `notificationNamed(...)`, `testLargeVariant`, `testDetail`, `testReview`, `testDetailSoldOut`, `testReferralSummary`, `testSeller`, `testSupportContent` |
| Naming rule for fakes | convention | all helpers | file `fake_<interface_snake>.dart`; class `Fake<Interface>`; one `Failure? <method>Failure` per failable call; one `int <method>Calls` or `List<…> <recorded>` per call worth asserting; `Completer<void>? gate` (or `<method>Gate`); `<thing>? cached<Thing>` where null = miss; public `test<Thing>` constants for data |
| `Networking` | abstract class | `lib/core/services/networking/networking.dart` | methods `getAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, Map<String, String>? headers, ApiHost host = ApiHost.supabase})`, `postAPICall({… dynamic data, Map<String, String>? headers, ApiHost host})`, `patchAPICall(…)`, `putAPICall({… dynamic data, ApiHost host})` (**no `headers`**), `deleteAPICall(…)`, `graphqlQueryCall({required String graphqlEndpoint, required String query, Map<String, dynamic>? variables})`; all return `Future<dynamic>` except graphql `Future<APIResponse>` |
| `ApiHost` | enum | same | `supabase, medusa, koUtils, stockship` |
| `SuccessResponse` | class | `lib/core/app/api/api_response.dart` | `const SuccessResponse({required this.successMessage, required this.statusCode, required this.rawData, required super.data})`; `props => [successMessage, statusCode, data]` (rawData excluded) |
| `ErrorResponse` | class | same | `const ErrorResponse({required this.errorMessage, required this.errorCode, this.rawData, required super.data})`; `errorCode` is the HTTP status **as a String** |
| `Failure` | class | `lib/core/app/failure.dart` | `Failure({required this.message, this.code}); final String message; final int? code;` (not Equatable, not const) |
| `NetworkFailure` | class | same | `NetworkFailure({super.message = 'No internet connection.', super.code});` |
| `ServerFailure` | class | same | `ServerFailure({required this.errorCode, super.message = 'Something went wrong.', super.code}); final String errorCode;` |
| `CacheMissFailure` | class | same | `CacheMissFailure({super.message = 'Nothing saved on this device.'});` |
| `ServerException` (api) | class | `lib/core/app/exceptions/api_exceptions.dart` | `const ServerException({required this.code, required this.status, this.detail}); final String code; final int status; final String? detail;` |
| `ConnectionException` | class | same | `const ConnectionException([this.message]); final String? message;` |
| `AppException` | class | `lib/core/app/exceptions/app_exceptions.dart` | `AppException(this.message, this.prefix)`; subclasses `InternetException([message])`, `RequestTimeoutException([message])`, `FetchDataException([message])`, `ServerException([message])` (clashes with api one: tests import this file `as app`), `InvalidUrlException`, `UnAuthorizedException`, `AuthException(message)` |
| `CacheException` | class | `lib/core/app/exceptions/cache_exceptions.dart` | `const CacheException([this.message]); final String? message;` |
| `LocalCache` | abstract interface class | `lib/core/services/local_cache/local_cache.dart` | `Future<Object?> read({required String box, required String key, required int version, Duration? maxAge}); Future<void> write({required String box, required String key, required int version, required Object json}); Future<void> delete({required String box, required String key}); Future<void> clearBox(String box); Future<void> clearUserScoped();` |
| `CacheBoxes` | abstract final class | `cache_boxes.dart` | `static const String catalog = 'catalog'; chargeRules = 'charge_rules'; addresses = 'addresses'; maliCoins = 'mali_coins'; coinRules = 'coin_rules'; coupons = 'coupons'; product = 'product'; seller = 'seller'; support = 'support'; static const List<String> all = [...]; static const List<String> userScoped = [addresses, maliCoins];` |
| `HiveLocalCache` | class | `hive_local_cache.dart` | `HiveLocalCache({DateTime Function() now = DateTime.now}); static Future<void> init(); static Future<void> openBoxes();` entry fields `'version'`, `'saved_at'`, `'data'` |
| `SecureStorage` | abstract interface class | `secure_storage.dart` | `Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key);` |
| `DeviceSecureStorage` | class | `device_secure_storage.dart` | `DeviceSecureStorage({FlutterSecureStorage storage = _storage}); static const String installedKey = 'secure_storage.installed'; static Future<void> init({PrefUtils? prefs, FlutterSecureStorage storage = _storage}); @visibleForTesting static void resetMemory();` |
| `SecureSessionStorage` | class `extends LocalStorage` (Supabase) | `secure_session_storage.dart` | `SecureSessionStorage({required SecureStorage storage, required PrefUtils prefs, required String supabaseUrl}); final String key; static String keyFor(String supabaseUrl) => 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';` |
| `PrefUtils` | class | `lib/core/services/pref_utils.dart` | `PrefUtils()` (calls `init()` if static instance null); `Future<void> init(); Future<bool> setString({required String key, required String value}); String? getString({required String key}); Future<bool> setBool({required String key, required bool value}); bool? getBool({required String key}); Future<bool> remove({required String key}); Map<String, dynamic> getAllData(); Future<bool> clearAll(); Future<void> clearPreferencesData();` |
| `StringConstants.appAuthToken` | static const | `lib/core/utils/string_constants.dart` | `'auth.access_token'` |
| `UseCase<T, Params>` / `NoParams` | abstract interface class / class | `lib/core/usecases/usecase.dart` | `Future<Either<Failure, T>> call(Params params);` / `const NoParams(); props => []` |
| `PaymentGateway` & co | see file | `payment_gateway.dart` | `GatewayCheckout({required keyId, required orderId, required amountPaise, required merchantName, required description, contact, email})`; `GatewayPayment({required paymentId, required orderId, signature = ''})`; `enum GatewayPaymentError { cancelled, upiTimeout, network, insufficientFunds, incorrectOtp, timeout, invalidVpa, cardDeclined, cardExpired, invalidCard, bankDown, limitExceeded, notConfigured, unknown; bool get isCancellation }`; `GatewayPaymentException(this.error, {this.detail})`; `Future<GatewayPayment> collect(GatewayCheckout checkout)` |
| `KoEngagementService` | abstract interface class | `ko_engagement_service.dart` | `init()`, `identify({required String phone, String? fullName, String? email})`, `resetIdentity()`, `requestPushPermission()`, `registerPush()`, `track(String name, {Map<String, dynamic>? properties})`, `screenView(String screenName, {Map<String, dynamic>? properties})`, `viewItem/addToCart/removeFromCart/viewCart({required List<AnalyticsItem> items, num? value})`, `beginCheckout({… String? coupon})`, `purchase({required String transactionId, required List<AnalyticsItem> items, num? value, num? shipping, String? coupon})`, `search(String searchTerm)`, `login({String? method})`, `addPaymentInfo({… String? paymentType})`, `capturePayment(double amount, {String? orderId})`, `checkNudges(BuildContext context, String route)` |
| `AnalyticsService` | abstract interface class | `analytics_service.dart` | the same event methods minus `init/identify/resetIdentity/requestPushPermission/registerPush`, plus `setUserId(String? userId)` and `Future<void> requestTrackingPermission()` |
| `KoAnalyticsService` | class | `ko_analytics_service.dart` | `const KoAnalyticsService(this._core);` forwards; `setUserId` and `requestTrackingPermission` are no-ops |
| `sl` | global | `injection_container.dart` | `final GetIt sl = GetIt.instance;` |
| `configureDependencies` | function | same | `void configureDependencies()` — `_registerCore()` then alternating `_register<X>Data(); register<X>Feature();` |
| `register<Feature>Feature` | functions | same | `registerAuthFeature()`, `registerCatalogFeature()`, `registerAppConfigFeature()`, `registerHomeFeature({String imageBaseUrl = ''})`, `registerCategoriesFeature()`, `registerCartFeature()`, `registerWishlistFeature()`, `registerSettingsFeature()`, `registerGardenFeature()`, `registerAddressFeature()`, `registerLocationFeature()`, `registerMaliCoinsFeature()`, `registerCouponsFeature()`, `registerOrdersFeature()`, `registerCheckoutFeature()`, `registerInvoiceFeature()`, `registerGstinFeature()`, `registerNotificationsFeature()`, `registerDeliveryFeature()`, `registerProductFeature()`, `registerProfileFeature()`, `registerReferralFeature()`, `registerAccountFeature()`, `registerSupportFeature()` — each registers use cases with `registerLazySingleton(() => X(sl()))` and blocs with `registerFactory(...)`, and depends **only on repositories** so tests can call it over fakes |
| `App` | widget | `lib/app/app.dart` | `const App({super.key, required this.router}); final GoRouter router; static const double maxTextScaleFactor = 1.1;` |
| `AppRouter` | class | `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics}); late final GoRouter router` |
| `SplashPage.displayDuration` | static const | `splash_page.dart` | `Duration(milliseconds: 2600)` |
| `AppInfoSheet` | widget | `app_info_sheet.dart` | `static const String defaultActionLabel = 'Got it'; static const Key actionKey = Key('appInfoSheet_actionButton'); static const Key closeKey = Key('appInfoSheet_closeButton'); static Future<bool> show(BuildContext context, {required String title, required String message, AppInfoSheetTone tone = AppInfoSheetTone.info, IconData? icon, String actionLabel = defaultActionLabel, Key? key})`; `enum AppInfoSheetTone { info, success, error }` |
| `AppPickerSheet` | widget | `app_picker_sheet.dart` | `static const Key closeKey = Key('appPickerSheet_closeButton'); static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder})` |
| `Env` | abstract final class | `env.dart` | `static Future<void> load()`; `_require(key)` throws `StateError('Missing $key in .env (see .env.example).')`; `_optional(key)`; `_koValue(key)` picks `${key}_PROD`/`${key}_BETA`; `@visibleForTesting static bool allowTestPayments = kDebugMode;` |
| `PushPermissionPrompt` | widget | `push_permission_prompt.dart` | `static const Duration settleDelay = Duration(seconds: 1); static const Duration locationWait = Duration(seconds: 30); @visibleForTesting static void resetForTest();` |
| Widget key convention | convention | `lib/` (384 keys) | `Key('<screenCamel>_<elementCamel>')`; suffixes seen: `Button`, `Field`, `Sheet`, `Message` (snackbars), `Row`, `Tile`, `Chip`, `Stat`, `_page`, `_scrollView`, `_skeleton`, `_reload`; shared widgets prefix with their own name (`appInfoSheet_…`, `appPickerSheet_…`); product keys `product_<testId>_add/_increment/_decrement/_wishlist`; tabs `shell_homeTab`, `shell_categoriesTab`, `shell_accountTab` |
| pubspec identity | yaml | `pubspec.yaml` | `name: mymali`, `description: "A new Flutter project."`, `publish_to: 'none'`, `version: 1.0.1+21`, `environment: sdk: ^3.13.4` |

---

## 3. Patterns

### Pattern 1 — The fake repository (gate + failure + recorder)

Rule: every fake `implements` the domain interface; one nullable `Failure` per failable call; one `Completer<void>? …Gate` (or a single `gate`) awaited **after** recording the call; the failure is read into a local before returning so a test can flip it mid-flight; successful writes mutate the fake's own state so later reads see them. Verbatim, `test/helpers/fake_auth_repository.dart`:

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/auth/domain/entities/auth_session.dart';
import 'package:mymali/features/auth/domain/entities/auth_user.dart';
import 'package:mymali/features/auth/domain/entities/otp_request.dart';
import 'package:mymali/features/auth/domain/entities/verify_otp_request.dart';
import 'package:mymali/features/auth/domain/repositories/auth_repository.dart';

final testSession = AuthSession(
  user: const AuthUser(
    id: 'user-1',
    phone: '+919876543210',
    fullName: 'Asha',
    roles: ['CUSTOMER'],
    activeRole: 'CUSTOMER',
    userKey: '91987654-3210-0000-0000-000000000000',
  ),
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresAt: DateTime.utc(2030),
);

/// In-memory [AuthRepository] for tests.
///
/// Set [sendOtpFailure] / [verifyOtpFailure] to make those calls fail, or
/// [sendOtpGate] / [verifyOtpGate] to hold them until the completer
/// completes.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.hasActiveSession = false});

  @override
  bool hasActiveSession;

  Failure? sendOtpFailure;
  Failure? verifyOtpFailure;
  Completer<void>? sendOtpGate;
  Completer<void>? verifyOtpGate;

  final List<OtpRequest> sentOtps = [];
  final List<VerifyOtpRequest> verifiedOtps = [];

  @override
  Future<Either<Failure, Unit>> sendOtp(OtpRequest request) async {
    sentOtps.add(request);
    await sendOtpGate?.future;
    final failure = sendOtpFailure;
    return failure == null ? const Right(unit) : Left(failure);
  }

  @override
  Future<Either<Failure, AuthSession>> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    verifiedOtps.add(request);
    await verifyOtpGate?.future;
    final failure = verifyOtpFailure;
    if (failure != null) return Left(failure);
    hasActiveSession = true;
    return Right(testSession);
  }

  @override
  Future<Either<Failure, AuthSession?>> restoreSession() async {
    return Right(hasActiveSession ? testSession : null);
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    hasActiveSession = false;
    return const Right(unit);
  }
}
```

What varies: the interface, entity types, test values. What to copy: file/class naming, the doc comment that lists the knobs, the `final failure = …; return failure == null ? Right(...) : Left(failure);` shape, the public recorder lists.

### Pattern 2 — The cache-first fake (`cached…` = null is a miss; `_cached<T>`)

Verbatim, `test/helpers/fake_catalog_repository.dart` (complete):

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/catalog/domain/entities/catalog_category.dart';
import 'package:mymali/features/catalog/domain/entities/catalog_product.dart';
import 'package:mymali/features/catalog/domain/entities/catalog_snapshot.dart';
import 'package:mymali/features/catalog/domain/entities/home_section.dart';
import 'package:mymali/features/catalog/domain/entities/product_variant.dart';
import 'package:mymali/features/catalog/domain/repositories/catalog_repository.dart';

const testVariant = ProductVariant(
  id: 'variant_01',
  sku: 'MM-NEEM-250',
  label: '250 ml',
  price: 269,
  mrp: 595,
  stock: 42,
);

const testProduct = CatalogProduct(
  id: 'prod_01',
  title: 'Activated Neem Oil',
  handle: 'activated-neem-oil',
  status: CatalogProduct.publishedStatus,
  categoryIds: ['pcat_01'],
  variants: [testVariant],
);

const testCategory = CatalogCategory(
  id: 'pcat_01',
  name: 'Liquid Tonics',
  handle: 'liquid-tonics',
  rank: 0,
);

final testCatalog = CatalogSnapshot(
  categories: [testCategory],
  products: [testProduct],
  regionId: 'reg_01',
  cached: true,
);

const testSections = [
  HomeSection(title: 'Liquid Tonics', products: [testProduct], total: 1),
];

const testSoldCounts = {'MM-NEEM-250': 12};
const testLowStockThresholds = {'MM-NEEM-250': 5};

/// In-memory [CatalogRepository] for tests.
///
/// Set a `…Failure` to make that call fail. The `getCached…` calls miss
/// until a `cached…` value is set.
class FakeCatalogRepository implements CatalogRepository {
  Failure? catalogFailure;
  Failure? homeSectionsFailure;
  Failure? soldCountsFailure;
  Failure? lowStockThresholdsFailure;

  int catalogCalls = 0;
  int homeSectionsCalls = 0;
  int soldCountsCalls = 0;
  int lowStockThresholdsCalls = 0;

  /// The snapshot [getCatalog] returns.
  CatalogSnapshot catalog = testCatalog;

  /// The rails [getHomeSections] returns.
  List<HomeSection> sections = testSections;

  /// The `refresh` flag of the last [getHomeSections] call.
  bool? lastRefresh;

  /// What the device has saved; null is a cache miss.
  CatalogSnapshot? cachedCatalog;
  List<HomeSection>? cachedSections;
  Map<String, int>? cachedSoldCounts;
  Map<String, int>? cachedLowStockThresholds;

  /// Completes the server calls only when completed, to hold a load open.
  Completer<void>? gate;

  @override
  Future<Either<Failure, CatalogSnapshot>> getCatalog() async {
    catalogCalls++;
    await gate?.future;
    final failure = catalogFailure;
    return failure == null ? Right(catalog) : Left(failure);
  }

  @override
  Future<Either<Failure, List<HomeSection>>> getHomeSections(
    bool refresh,
  ) async {
    homeSectionsCalls++;
    lastRefresh = refresh;
    await gate?.future;
    final failure = homeSectionsFailure;
    return failure == null ? Right(sections) : Left(failure);
  }

  @override
  Future<Either<Failure, Map<String, int>>> getSoldCounts() async {
    soldCountsCalls++;
    final failure = soldCountsFailure;
    return failure == null ? const Right(testSoldCounts) : Left(failure);
  }

  @override
  Future<Either<Failure, Map<String, int>>> getLowStockThresholds() async {
    lowStockThresholdsCalls++;
    final failure = lowStockThresholdsFailure;
    return failure == null
        ? const Right(testLowStockThresholds)
        : Left(failure);
  }

  @override
  Future<Either<Failure, CatalogSnapshot>> getCachedCatalog() async =>
      _cached(cachedCatalog);

  @override
  Future<Either<Failure, List<HomeSection>>> getCachedHomeSections() async =>
      _cached(cachedSections);

  @override
  Future<Either<Failure, Map<String, int>>> getCachedSoldCounts() async =>
      _cached(cachedSoldCounts);

  @override
  Future<Either<Failure, Map<String, int>>>
  getCachedLowStockThresholds() async => _cached(cachedLowStockThresholds);

  Either<Failure, T> _cached<T>(T? value) =>
      value == null ? Left(CacheMissFailure()) : Right(value);
}
```

Rule: the `gate` gates only the *remote* calls; cached reads answer at once. Simpler fakes inline the same thing: `final cached = cachedBalance; return cached == null ? Left(CacheMissFailure()) : Right(cached);` (`FakeMaliCoinsRepository`, `FakeAddressRepository`, `FakeSellerRepository`, `FakeSupportRepository`, `FakeProductRepository`, `FakeChargeRulesRepository`).

### Pattern 3 — `FakeNetworking` and the response builders (complete file)

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

How a test drives it (from `stockship_remote_data_source_test.dart`): single answer `networking.response = okResponse({...})`; ordered answers `networking.queued..add(errorResponse({'message': 'expired'}, '401'))..add(okResponse({...}))`; no answer `networking..response = null..error = app.AppException('offline', 'Timeout')`; assertions `final call = networking.lastCall; expect(call.method, 'GET'); expect(call.host, ApiHost.stockship); expect(call.endpoint, StockshipEndpoints.orders); expect(call.queryParameters, {...}); expect(call.headers, {'Authorization': 'Bearer ko_1'});` and `expect(networking.calls.map((c) => c.headers!['Authorization']), ['Bearer ko_old', 'Bearer ko_new']);`.

### Pattern 4 — Data-source test (older, file-private fake; the shape AGENTS.md §6 describes)

Verbatim head of `test/features/auth/data/datasources/auth_remote_data_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/app/api/api_response.dart';
import 'package:mymali/core/app/exceptions/app_exceptions.dart' as app;
import 'package:mymali/core/services/networking/networking.dart';
import 'package:mymali/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mymali/core/app/exceptions/api_exceptions.dart';
import 'package:mymali/features/auth/data/models/otp_request_model.dart';
import 'package:mymali/features/auth/data/models/verify_otp_request_model.dart';

class _FakeNetworking implements Networking {
  Object? response;
  Object? error;
  String? endpoint;
  Object? data;
  Map<String, String>? headers;

  @override
  Future<dynamic> postAPICall({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    Map<String, String>? headers,
    ApiHost host = ApiHost.supabase,
  }) async {
    this.endpoint = endpoint;
    this.data = data;
    this.headers = headers;
    if (error != null) throw error!;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ErrorResponse _error(Map<String, dynamic> envelope, String status) =>
    ErrorResponse(
      errorMessage: '',
      errorCode: status,
      data: null,
      rawData: envelope,
    );

SuccessResponse _ok(Map<String, dynamic> body) => SuccessResponse(
  successMessage: '',
  statusCode: '200',
  rawData: body,
  data: body,
);

void main() {
  late _FakeNetworking networking;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    networking = _FakeNetworking();
    dataSource = AuthRemoteDataSourceImpl(
      networking: networking,
      anonKey: 'anon-key',
    );
  });

  group('sendOtp', () {
    const request = OtpRequestModel(action: 'send', phone: '919876543210');

    test('posts the body with Supabase headers and parses ok', () async {
      networking.response = _ok({'ok': true});

      final result = await dataSource.sendOtp(request);

      expect(result.ok, isTrue);
      expect(networking.endpoint, '/functions/v1/phone-login');
      expect(networking.data, {'action': 'send', 'phone': '919876543210'});
      expect(networking.headers, {
        'apikey': 'anon-key',
        'Authorization': 'Bearer anon-key',
      });
    });

    test('an error envelope throws ServerException', () async {
      networking.response = _error({
        'code': 'INVALID_PHONE',
        'status': 422,
        'title': 'Invalid phone',
        'detail': 'Phone must be 12 digits',
      }, '422');

      expect(
        () => dataSource.sendOtp(request),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'INVALID_PHONE')
              .having((e) => e.status, 'status', 422)
              .having((e) => e.detail, 'detail', 'Phone must be 12 digits'),
        ),
      );
    });

    test('no response throws ConnectionException', () async {
      networking.error = app.InternetException();

      expect(
        () => dataSource.sendOtp(request),
        throwsA(isA<ConnectionException>()),
      );
    });
  });
  // …
}
```

Rule: every data source test covers the three answers — success (asserting endpoint, body, headers), an error envelope (asserting `ServerException.code/status/detail` with `isA<…>().having(...)`), and no response (`app.InternetException()` / `app.RequestTimeoutException()` → `ConnectionException`) — plus "a 200 without the required fields throws `UNEXPECTED_RESPONSE`". Newer tests use the shared `FakeNetworking` instead of a private one.

### Pattern 5 — Repository test: exception → failure map and the order of side effects

From `test/features/auth/data/repositories/auth_repository_impl_test.dart`:

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

```dart
    test('other codes map to ServerFailure with the code', () async {
      remote.sendError = const ServerException(
        code: 'INVALID_BODY',
        status: 422,
      );

      final failure = (await repository.sendOtp(request))
          .getLeft()
          .toNullable();

      expect(failure, isA<ServerFailure>());
      expect((failure! as ServerFailure).errorCode, 'INVALID_BODY');
    });

    test('ConnectionException maps to NetworkFailure', () async {
      remote.sendError = const ConnectionException();

      final result = await repository.sendOtp(request);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
```

Side-effect order with a shared log (from `catalog_repository_impl_test.dart`): the private `_FakeRemote(this.log)` and `_FakeLocal(this.log)` both push `'remote.fetchSnapshot'`, `'local.writeSnapshot'` …, and tests assert `expect(log, ['remote.fetchSnapshot', 'local.writeSnapshot']);`, `expect(log.where((entry) => entry.startsWith('local.')), isEmpty);` (a failed fetch saves nothing), `expect(log.where((entry) => entry.startsWith('remote.')), isEmpty);` (cached reads never touch the network). A throwing cache write still returns `Right`: `local.writeError = const CacheException('disk full'); expect((await repository.getCatalog()).isRight(), isTrue);`. A throwing cache read is a miss: `expect(result.getLeft().toNullable(), isA<CacheMissFailure>());`.

Rule: fakes for a repository test are **file-private** (`_FakeRemote`, `_FakeLocal`, `_FakeSession`) unless two tests need the same one (then `test/helpers/fake_cart_remote_data_source.dart`). Right/Left are unwrapped with fpdart's `result.getRight().toNullable()` / `result.getLeft().toNullable()`, or compared whole: `expect(result, const Right<dynamic, Unit>(unit));`.

### Pattern 6 — Model round-trip test (complete)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/features/auth/data/models/auth_tokens_model.dart';
import 'package:mymali/features/auth/data/models/verify_otp_request_model.dart';
import 'package:mymali/features/auth/domain/entities/auth_tokens.dart';
import 'package:mymali/features/auth/domain/entities/verify_otp_request.dart';

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

  test('VerifyOtpRequestModel builds the verify body and round-trips', () {
    const entity = VerifyOtpRequest(
      fullName: 'Ramesh Kumar',
      phoneDigits: '9876543210',
      otp: '1234',
    );
    const body = {
      'action': 'verify',
      'phone': '919876543210',
      'otp': '1234',
      'fullName': 'Ramesh Kumar',
    };

    expect(VerifyOtpRequestModel.fromEntity(entity).toJson(), body);
    expect(VerifyOtpRequestModel.fromJson(body).toEntity(), entity);
  });
}
```

Rule: `fromJson → toEntity → fromEntity → toJson == original map`, exactly as AGENTS.md §5 says; entity equality relies on `Equatable`.

### Pattern 7 — Bloc test (built directly over use cases; stream-based waiting)

From `test/features/auth/presentation/login/bloc/login_bloc_test.dart`:

```dart
void main() {
  late FakeAuthRepository repository;
  late LoginBloc bloc;

  setUp(() {
    repository = FakeAuthRepository();
    bloc = LoginBloc(
      sendOtp: SendOtp(repository),
      verifyOtp: VerifyOtp(repository),
    );
  });
  tearDown(() => bloc.close());

  Future<LoginState> dispatch(LoginEvent event) async {
    bloc.add(event);
    return bloc.stream.first;
  }

  Future<List<LoginState>> dispatchAll(LoginEvent event, int count) {
    final states = bloc.stream.take(count).toList();
    bloc.add(event);
    return states;
  }
  // …
    test('SendOtpPressed is ignored unless canSubmit', () async {
      await dispatch(FullNameChanged('Asha'));
      bloc.add(SendOtpPressed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, LoginStatus.idle);
      expect(repository.sentOtps, isEmpty);
    });
  // …
    test('a second SendOtpPressed while sending is ignored', () async {
      final gate = Completer<void>();
      repository.sendOtpGate = gate;
      await fillValidDetails();

      final sending = await dispatch(SendOtpPressed());
      expect(sending.status, LoginStatus.requestingOtp);

      bloc.add(SendOtpPressed());
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await bloc.stream.firstWhere((s) => s.status == LoginStatus.otpSent);

      expect(repository.sentOtps, hasLength(1));
    });
```

Cache-first sequence (from `categories_bloc_test.dart`):

```dart
    Future<List<CategoriesState>> states(CategoriesEvent event, int count) {
      final states = bloc.stream.take(count).toList();
      bloc.add(event);
      return states;
    }

    test('shows the saved catalog, then the fresh one', () async {
      repository.cachedCatalog = saved;

      final emitted = await states(CategoriesStarted(), 3);

      expect(emitted[0].status, CategoriesStatus.loaded);
      expect(emitted[0].products, [savedProduct]);
      expect(emitted[0].isStale, isTrue);
      expect(emitted[0].isRefreshing, isFalse);
      // The saved catalog stays on screen while the fresh one loads.
      expect(emitted[1].status, CategoriesStatus.loaded);
      expect(emitted[1].products, [savedProduct]);
      expect(emitted[1].isRefreshing, isTrue);
      expect(emitted[2].products, testCatalog.products);
      expect(emitted[2].isStale, isFalse);
      expect(emitted[2].isRefreshing, isFalse);
    });
```

Rules: no `bloc_test`; subscribe (`bloc.stream.take(n).toList()`) **before** `bloc.add`; `tearDown(() => bloc.close())`; `Future<void>.delayed(Duration.zero)` lets an ignored event run; a `Completer` gate tests re-entrancy; `expect(state.failure, same(failure))` checks identity of the failure instance; blocs that time things take `now:`/`wait:` (Pattern 17).

### Pattern 8 — Page test that pumps `App` (hand-rolled setUp)

From `test/widget_test.dart` (the fullest hand-rolled form; `categories_page_test.dart` and `product_detail_page_test.dart` are the same shape):

```dart
void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
    // Real use cases and blocs, backed by the fake repositories.
    sl
      ..registerSingleton<AuthRepository>(repository)
      ..registerSingleton<CatalogRepository>(FakeCatalogRepository())
      ..registerSingleton<AppConfigRepository>(FakeAppConfigRepository())
      ..registerSingleton<CartRepository>(FakeCartRepository());
    sl.registerSingleton<WishlistRepository>(FakeWishlistRepository());
    registerFakeEngagement();
    registerAuthFeature();
    registerCatalogFeature();
    registerAppConfigFeature();
    registerHomeFeature();
    registerCategoriesFeature();
    // App provides these app-wide blocs on every screen.
    registerCartFeature();
    registerWishlistFeature();
    sl.registerSingleton<LocationRepository>(FakeLocationRepository());
    registerLocationFeature();
    registerSettingsFeature();
    sl.registerSingleton<MaliCoinsRepository>(FakeMaliCoinsRepository());
    registerMaliCoinsFeature();
    registerAccountFakes();
    sl.registerSingleton<CouponRepository>(FakeCouponRepository());
    registerCouponsFeature();
  });
  tearDown(sl.reset);

  Future<void> pumpApp(WidgetTester tester) async {
    // A typical portrait phone screen.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(App(router: AppRouter().router));
  }

  Future<void> passSplash(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pump(SplashPage.displayDuration);
    await tester.pumpAndSettle();
  }

  Finder input(String key) => find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(EditableText),
  );

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  LoginBloc loginBloc(WidgetTester tester) =>
      BlocProvider.of<LoginBloc>(tester.element(find.byType(PageView)));

  AuthBloc authBloc(WidgetTester tester) =>
      BlocProvider.of<AuthBloc>(tester.element(find.byType(Scaffold).last));

  Future<void> submitDetails(WidgetTester tester) async {
    await tester.enterText(input('login_nameField'), 'Asha');
    await tester.enterText(input('login_phoneNumberField'), '9876543210');
    // Rebuild so the button reflects canSubmit before tapping.
    await tester.pump();
    await tapKey(tester, 'login_getOtpButton');
  }
```

Rules encoded: fakes are registered with `registerSingleton` (an instance the test keeps a reference to), then the production `register<Feature>Feature()` functions build real use cases and blocs over them; `registerFakeEngagement()` is mandatory because `App` reads `sl<KoEngagementService>()` and `sl<AnalyticsService>()`; `CartBloc` and `CouponBloc` are `lazy: false` in `App`, so `CartRepository`/`CouponRepository` fakes must exist before the pump; the splash must be advanced with `pump(SplashPage.displayDuration)`; a field is typed into through `find.descendant(of: byKey, matching: byType(EditableText))` because `UniversalFormField` wraps the editable; a bloc is reached through `BlocProvider.of<X>(tester.element(find.byType(SomeWidgetInsideIt)))`; a pushed route is opened from a test with `router.pushNamed(AppRoute.productDetail.name, pathParameters: {ProductDetailPage.idParam: 'prod_01'})` after keeping `router = AppRouter().router`.

### Pattern 9 — `registerSignedInApp` / `launchSignedInApp` (complete `test/helpers/signed_in_app.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/app/app.dart';
import 'package:mymali/core/di/injection_container.dart';
import 'package:mymali/core/services/analytics/analytics_service.dart';
import 'package:mymali/core/services/analytics/ko_analytics_service.dart';
import 'package:mymali/core/services/katyayani_core/ko_engagement_service.dart';
import 'package:mymali/core/router/app_router.dart';
import 'package:mymali/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:mymali/features/auth/domain/repositories/auth_repository.dart';
import 'package:mymali/features/auth/presentation/splash/pages/splash_page.dart';
import 'package:mymali/features/cart/domain/repositories/cart_repository.dart';
import 'package:mymali/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:mymali/features/coupons/domain/repositories/coupon_repository.dart';
import 'package:mymali/features/home/presentation/home/pages/home_page.dart';
import 'package:mymali/features/location/domain/repositories/location_repository.dart';
import 'package:mymali/features/mali_coins/domain/repositories/mali_coins_repository.dart';
import 'package:mymali/features/wishlist/domain/repositories/wishlist_repository.dart';

import 'fake_account_repository.dart';
import 'fake_app_config_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_cart_repository.dart';
import 'fake_catalog_repository.dart';
import 'fake_coupon_repository.dart';
import 'fake_location_repository.dart';
import 'fake_mali_coins_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_referral_repository.dart';
import 'fake_wishlist_repository.dart';
import 'fake_ko_engagement_service.dart';

/// Registers fakes for everything the signed-in app reads, with a stored
/// session. Pass a fake to inspect or steer it. Pair with
/// `tearDown(sl.reset)`.
void registerSignedInApp({
  FakeAuthRepository? auth,
  FakeMaliCoinsRepository? coins,
  FakeWishlistRepository? wishlist,
  FakeProfileRepository? profile,
  FakeReferralRepository? referral,
  FakeAccountRepository? account,
  FakeKoEngagementService? engagement,
}) {
  sl
    ..registerSingleton<AuthRepository>(
      auth ?? (FakeAuthRepository()..hasActiveSession = true),
    )
    ..registerSingleton<CatalogRepository>(FakeCatalogRepository())
    ..registerSingleton<AppConfigRepository>(FakeAppConfigRepository())
    ..registerSingleton<CartRepository>(FakeCartRepository())
    ..registerSingleton<WishlistRepository>(
      wishlist ?? FakeWishlistRepository(),
    )
    ..registerSingleton<LocationRepository>(FakeLocationRepository())
    ..registerSingleton<MaliCoinsRepository>(coins ?? FakeMaliCoinsRepository())
    ..registerSingleton<CouponRepository>(FakeCouponRepository());
  final core = engagement ?? FakeKoEngagementService();
  sl
    ..registerSingleton<KoEngagementService>(core)
    ..registerSingleton<AnalyticsService>(KoAnalyticsService(core));
  registerAuthFeature();
  registerCatalogFeature();
  registerAppConfigFeature();
  registerHomeFeature();
  registerCategoriesFeature();
  registerCartFeature();
  registerWishlistFeature();
  registerLocationFeature();
  registerSettingsFeature();
  registerGardenFeature();
  registerMaliCoinsFeature();
  registerCouponsFeature();
  registerAccountFakes(profile: profile, referral: referral, account: account);
}

/// Launches the app on a phone-size view and waits until it lands home.
Future<void> launchSignedInApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    App(router: AppRouter(analytics: sl<AnalyticsService>()).router),
  );
  await tester.pump(SplashPage.displayDuration);
  await tester.pumpAndSettle();
  expect(find.byType(HomePage), findsOneWidget);
}

/// Opens the Account tab.
Future<void> openAccountTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('shell_accountTab')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('account_page')), findsOneWidget);
}

/// Scrolls the Account tab until [finder] is built and on screen.
Future<void> scrollAccountTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.descendant(
      of: find.byKey(const Key('account_scrollView')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}
```

Typical use (`account_page_test.dart`): `setUp(() { engagement = FakeKoEngagementService(); auth = FakeAuthRepository()..hasActiveSession = true; profile = FakeProfileRepository(); registerSignedInApp(auth: auth, profile: profile, engagement: engagement); }); tearDown(sl.reset);`. A feature not in the default set is added after it: `registerSignedInApp(engagement: engagement); sl.registerSingleton<SellerRepository>(FakeSellerRepository()); registerInvoiceFeature();` (`invoice_page_test.dart`).

### Pattern 10 — Holding a load open in a page test (the `gate`)

From `categories_page_test.dart`:

```dart
    testWidgets('shows the saved catalog while the fresh one loads', (
      tester,
    ) async {
      catalog().cachedCatalog = saved;
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(App(router: AppRouter().router));
      await tester.pump(SplashPage.displayDuration);
      await tester.pumpAndSettle();
      // Home has loaded; hold the Categories load open.
      catalog().gate = Completer<void>();
      await tapKey(tester, 'shell_categoriesTab');

      expect(find.text('Saved Product'), findsOneWidget);

      catalog().gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Activated Neem Oil'), findsOneWidget);
      expect(find.text('Saved Product'), findsNothing);
    });

    testWidgets('a failed refresh keeps the saved catalog and says so', (
      tester,
    ) async {
      catalog()
        ..cachedCatalog = saved
        ..catalogFailure = NetworkFailure();
      await openCategories(tester);

      expect(find.text('Saved Product'), findsOneWidget);
      expect(find.byKey(const Key('catalog_retryButton')), findsNothing);
      expect(
        find.text('No internet connection. Showing saved products.'),
        findsOneWidget,
      );
    });
```

where `FakeCatalogRepository catalog() => sl<CatalogRepository>() as FakeCatalogRepository;` reads the registered fake back out of `sl`. When the gate holds a **skeleton** on screen (shimmer animates forever), do not `pumpAndSettle`; pump fixed durations instead (`referral_page_test.dart`: `await tester.pump(); await tester.pump(const Duration(milliseconds: 400));`, then `referral.gate!.complete(); await tester.pumpAndSettle();`).

### Pattern 11 — Local data source test over `FakeLocalCache` (complete)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/app/exceptions/cache_exceptions.dart';
import 'package:mymali/core/services/local_cache/cache_boxes.dart';
import 'package:mymali/features/catalog/data/datasources/catalog_local_data_source.dart';
import 'package:mymali/features/catalog/data/models/catalog_category_model.dart';
import 'package:mymali/features/catalog/data/models/catalog_product_model.dart';
import 'package:mymali/features/catalog/data/models/catalog_snapshot_model.dart';
import 'package:mymali/features/catalog/data/models/low_stock_threshold_model.dart';
import 'package:mymali/features/catalog/data/models/sold_count_model.dart';

import '../../../../helpers/fake_local_cache.dart';

void main() {
  late FakeLocalCache cache;
  late CatalogLocalDataSourceImpl dataSource;

  setUp(() {
    cache = FakeLocalCache();
    dataSource = CatalogLocalDataSourceImpl(cache);
  });

  final snapshot = CatalogSnapshotModel(
    categories: const [
      CatalogCategoryModel(
        id: 'pcat_01',
        name: 'Liquid Tonics',
        handle: 'liquid-tonics',
        rank: 0,
      ),
    ],
    products: const [
      CatalogProductModel(
        id: 'prod_01',
        title: 'Activated Neem Oil',
        handle: 'activated-neem-oil',
        status: 'published',
        categoryIds: ['pcat_01'],
      ),
    ],
    count: 1,
    regionId: 'reg_01',
    updatedAt: DateTime.utc(2026, 10, 1, 9, 30),
    cached: true,
  );

  test('every read misses when nothing is saved', () async {
    expect(await dataSource.readSnapshot(), isNull);
    expect(await dataSource.readSoldCounts(), isNull);
    expect(await dataSource.readLowStockThresholds(), isNull);
  });

  test('a saved snapshot reads back the same', () async {
    await dataSource.writeSnapshot(snapshot);

    final read = await dataSource.readSnapshot();

    expect(read?.toJson(), snapshot.toJson());
    expect(cache.keysOf(CacheBoxes.catalog), [
      CatalogLocalDataSourceImpl.snapshotKey,
    ]);
  });

  test('saved sold counts read back the same', () async {
    const rows = [
      SoldCountModel(sku: 'MM-NEEM-250', soldCount: 12),
      SoldCountModel(sku: 'MM-SEED-2', soldCount: 0),
    ];
    await dataSource.writeSoldCounts(rows);

    final read = await dataSource.readSoldCounts();

    expect(read?.map((row) => row.toJson()), rows.map((row) => row.toJson()));
  });

  test('saved low-stock thresholds read back the same', () async {
    const rows = [
      LowStockThresholdModel(sku: 'MM-NEEM-250', lowStockThreshold: 5),
    ];
    await dataSource.writeLowStockThresholds(rows);

    final read = await dataSource.readLowStockThresholds();

    expect(read?.map((row) => row.toJson()), rows.map((row) => row.toJson()));
  });

  test('an empty saved list is a hit, not a miss', () async {
    await dataSource.writeSoldCounts(const []);

    expect(await dataSource.readSoldCounts(), isEmpty);
  });

  test('entries saved under another schema version miss', () async {
    await cache.write(
      box: CacheBoxes.catalog,
      key: CatalogLocalDataSourceImpl.snapshotKey,
      version: CatalogLocalDataSourceImpl.schemaVersion + 1,
      json: snapshot.toJson(),
    );

    expect(await dataSource.readSnapshot(), isNull);
  });

  test('clear removes everything saved', () async {
    await dataSource.writeSnapshot(snapshot);
    await dataSource.writeSoldCounts(const []);

    await dataSource.clear();

    expect(await dataSource.readSnapshot(), isNull);
    expect(await dataSource.readSoldCounts(), isNull);
  });

  test('a cache failure is passed on as a CacheException', () async {
    cache
      ..readError = const CacheException('read')
      ..writeError = const CacheException('write');

    expect(dataSource.readSnapshot(), throwsA(isA<CacheException>()));
    expect(dataSource.writeSnapshot(snapshot), throwsA(isA<CacheException>()));
  });
}
```

`FakeLocalCache` (complete):

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

### Pattern 12 — The real cache in a temp directory (`hive_local_cache_test.dart`)

```dart
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
```

Corrupt entries exercised: `'not json'`, `'[1, 2]'`, `'{"version": 1, "data": {"count": 1}}'` (no `saved_at`), `'{"version": 1, "saved_at": "2026-10-01T12:00:00Z"}'` (no `data`) — each must read `null` and be deleted (`raw.containsKey(key)` false). `write(DateTime(2026))` must throw `CacheException`. After `Hive.close()`: read → `null`, write → `CacheException`, `clearBox`/`clearUserScoped` do not throw.

### Pattern 13 — Plugin-backed classes in tests (platform mocks)

`SharedPreferences` + `PrefUtils` (because `PrefUtils._sharedPreferences` is **static** and survives tests):

```dart
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

`flutter_secure_storage` real class (`device_secure_storage_test.dart`): `TestWidgetsFlutterBinding.ensureInitialized();` at the top of `main`, `DeviceSecureStorage.resetMemory();` in `setUp`, `FlutterSecureStorage.setMockInitialValues({...});` per test, `await DeviceSecureStorage.init(prefs: prefs);`.

Method channels (`invoice_page_test.dart`): `const MethodChannel _share = MethodChannel('dev.fluttercommunity.plus/share'); const MethodChannel _paths = MethodChannel('plugins.flutter.io/path_provider');` then in `setUp`: `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger..setMockMethodCallHandler(_paths, (call) async => temp.path)..setMockMethodCallHandler(_share, (call) async { shared.add(call); return 'shared'; });` with `temp = Directory.systemTemp.createTempSync('invoice_test');`. Same for the Meta plugin (`meta_analytics_destination_test.dart`, `MethodChannel(channelName)` exported by the destination file; `Future<void> settle() => Future<void>.delayed(Duration.zero);`).

### Pattern 14 — `Env` in tests: `dotenv.loadFromString`

```dart
const _koKeys = '''
UTILS_URL_BETA=https://beta.utils
UTILS_URL_PROD=https://utils
STOCKSHIP_URL_BETA=https://beta.stockship
STOCKSHIP_URL_PROD=https://stockship
RAZORPAY_KEY_ID_BETA=rzp_beta
RAZORPAY_KEY_ID_PROD=rzp_prod
MKTP_ID=MKTP-208
APP_VERSION=1.0.1
''';

void _load(String koEnv) =>
    dotenv.loadFromString(envString: 'KO_ENV=$koEnv\n$_koKeys');
```

`Env.load()` (the `.env` asset) is never called in tests; a page test that needs one value loads just that value (`dotenv.loadFromString(envString: 'APP_WEB_ORIGIN=https://example.com/app')`). A `@visibleForTesting` static switch is reset in `tearDown`: `tearDown(() => Env.allowTestPayments = true);`. Unknown values must throw: `expect(() => Env.koEnv, throwsStateError);`.

### Pattern 15 — Asserting analytics

```dart
  List<Map<String, dynamic>?> tracked(String name) => [
    for (final e in engagement.tracked)
      if (e.name == name) e.properties,
  ];
  // …
      expect(tracked(AppEvents.accountMenuTapped), [
        {'item': 'wishlist'},
      ]);
      expect(engagement.events.where((e) => e == 'search'), hasLength(1));
      expect(engagement.screens, ['ShopTab', 'CategoriesTab', 'ShopTab']);
      expect(engagement.identified, ['+919876543210']);
      expect(engagement.resetCount, 1);
      expect(engagement.registerPushCount, 1);
```

Event names always come from `AppEvents.*`, never typed in the test.

### Pattern 16 — Generic widget test (no `App`, no `sl`)

```dart
void main() {
  Future<void> pumpButton(WidgetTester tester, PrimaryButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  testWidgets('fills the width by default', (tester) async {
    await pumpButton(
      tester,
      PrimaryButton(label: 'Continue', onPressed: () {}),
    );

    expect(tester.getSize(find.byType(PrimaryButton)).width, 800);
    expect(tester.getSize(find.byType(PrimaryButton)).height, 56);
  });
```

Rules: pump the component inside `MaterialApp(theme: AppTheme.light | AppTheme.dark, home: …)` (`AppTheme.dark` 30 uses, `AppTheme.light` 24 in tests); the default test surface is 800×600 logical (comment: "The test surface is 800 wide"); sheets are opened from a `Builder` + `TextButton('open')` and the completed value is captured into a `bool? result`; colours are asserted against `AppTheme.dark.colorScheme.secondary` / `.error`; `expect(tester.takeException(), isNull)` guards overflow; `find.byKey(AppInfoSheet.actionKey).hitTestable()`.

### Pattern 17 — Deterministic time: `now` and `wait` injection

Production classes that time things take a clock and, for blocs that sleep, a waiter: `DateTime Function() now` (default `DateTime.now`) and `Future<void> Function(Duration) wait`. Found in: `lib/core/services/kotech/ko_token_service.dart`, `lib/core/services/local_cache/hive_local_cache.dart`, `lib/features/address/presentation/address_form/bloc/address_form_bloc.dart`, `lib/features/checkout/data/repositories/checkout_repository_impl.dart`, `lib/features/checkout/presentation/order_placed/bloc/order_placed_bloc.dart`, `lib/features/coupons/data/repositories/coupon_repository_impl.dart`, `lib/features/coupons/presentation/bloc/coupon_bloc.dart`, `lib/features/gstin/data/datasources/gstin_remote_data_source.dart`, `lib/features/orders/data/repositories/orders_repository_impl.dart`, `lib/features/product/presentation/product_detail/widgets/delivery_check_section.dart`. Test side (`order_placed_bloc_test.dart`):

```dart
    bloc = OrderPlacedBloc(
      getWarehouseOrder: GetWarehouseOrder(orders),
      findOrderPlacedAfter: FindOrderPlacedAfter(orders),
      getRefOrder: GetRefOrder(orders),
      recordPlacedOrder: RecordPlacedOrder(checkout),
      getCachedCatalog: GetCachedCatalog(catalog),
      getCatalog: GetCatalog(catalog),
      now: () => now,
      wait: (duration) async {
        waits.add(duration);
        now = now.add(duration);
      },
    );
```

and in `ko_token_service_test.dart`: `KoTokenServiceImpl(networking: networking, anonKey: 'anon', env: KoEnv.beta, now: () => now)` with `now = DateTime.utc(2026, 10, 8, 10, 56);` moved between calls.

### Pattern 18 — User feedback (exactly how it is done)

Counts over `lib/` (2026-10-14): `toastification` **0** imports (declared in pubspec, unused); `Fluttertoast` **0**; `SnackBar` 71 lines / `ScaffoldMessenger` 24 lines across 23 files; `AppInfoSheet.show` 25 lines (23 real call sites in 15 feature files + 2 in its own doc comments); `showDialog` **1** and `AlertDialog` **1** (both the legacy OTP verify dialog in `login_page.dart`); `showModalBottomSheet` **2** (only inside `AppInfoSheet.show` and `AppPickerSheet.show`); `AppPickerSheet.show` 6 call sites (catalog sort/filter/price sheets, delivery-address sheet, payment-method sheet, GSTIN sheet).

The SnackBar form, always from a `BlocListener` with a precise `listenWhen`, always `..hideCurrentSnackBar()` first, always keyed `<screen>_<what>Message`, text from a failure-to-text helper (`categories_page.dart`):

```dart
        // A refresh that failed while the catalog stays on screen.
        BlocListener<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) =>
              current.status == CategoriesStatus.loaded &&
              current.failure != null &&
              current.failure != previous.failure,
          listener: (context, state) => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('catalog_refreshFailedMessage'),
                content: Text(refreshFailureMessage(state.failure)),
              ),
            ),
        ),
```

Outside a listener, capture the messenger before navigating (`buy_again_to_cart.dart`): `final messenger = ScaffoldMessenger.of(context); context.pushNamed(AppRoute.cart.name); if (note != null) { messenger..hideCurrentSnackBar()..showSnackBar(SnackBar(key: const Key('orders_buyAgainPartialMessage'), content: Text(note))); }`.

The `AppInfoSheet` form with a retry (`address_form_page.dart`):

```dart
        BlocListener<AddressFormBloc, AddressFormState>(
          listenWhen: (previous, current) =>
              current.saveFailure != null &&
              current.saveFailure != previous.saveFailure,
          listener: (context, state) async {
            final bloc = context.read<AddressFormBloc>();
            final retry = await AppInfoSheet.show(
              context,
              key: const Key('addressForm_saveFailedSheet'),
              tone: AppInfoSheetTone.error,
              title: "Couldn't save your address",
              message: addressSaveFailureMessage(state.saveFailure),
              actionLabel: 'Try again',
            );
            if (retry) bloc.add(AddressFormSubmitted());
          },
        ),
```

(the bloc is read **before** the `await`, so no `context` use after the gap). A confirmation uses the same sheet: `final confirmed = await AppInfoSheet.show(...)` (account sign-out, review delete, address delete). The one legacy exception, kept deliberately (`login_page.dart` `_onVerifyResult`): `showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))]))`, and `_onSendResult` shows `SnackBar(content: Text(message))` without a key. In tests: `await tester.tap(find.byKey(AppInfoSheet.actionKey)); await tester.pumpAndSettle();` / `find.byKey(AppInfoSheet.closeKey)` / `find.byKey(const Key('account_signOutSheet'))`; the legacy dialog is dismissed with `find.text('OK')` and asserted gone with `find.byType(AlertDialog)`.

### Pattern 19 — `.env` reaching the native projects

`tool/sync_native_env.dart` (complete):

```dart
// Copies the values the iOS project needs from `.env` into
// `ios/Flutter/Env.xcconfig` (git-ignored), which Debug.xcconfig and
// Release.xcconfig include and Info.plist reads as $(FB_APP_ID) and
// $(FB_CLIENT_TOKEN). Android reads `.env` itself in app/build.gradle.kts.
//
// Run it before an iOS build, whenever `.env` changes:
//   dart run tool/sync_native_env.dart
import 'dart:io';

const List<String> _keys = ['FB_APP_ID', 'FB_CLIENT_TOKEN'];

void main() {
  final env = File('.env');
  if (!env.existsSync()) {
    stderr.writeln('No .env here: run this from the project root.');
    exit(1);
  }

  final values = <String, String>{};
  for (final raw in env.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#') || !line.contains('=')) continue;
    final at = line.indexOf('=');
    values[line.substring(0, at).trim()] = line.substring(at + 1).trim();
  }

  final out = StringBuffer(
    '// Generated by tool/sync_native_env.dart from .env. Do not edit.\n',
  );
  for (final key in _keys) {
    final value = values[key] ?? '';
    if (value.isEmpty) {
      stderr.writeln('Warning: $key is not set in .env; Meta stays off.');
    }
    out.writeln('$key = $value');
  }
  File('ios/Flutter/Env.xcconfig').writeAsStringSync(out.toString());
  stdout.writeln('Wrote ios/Flutter/Env.xcconfig');
}
```

`ios/Flutter/Debug.xcconfig` and `Release.xcconfig` are each exactly:

```
#include "Generated.xcconfig"
#include? "Env.xcconfig"
```

Android reads the same `.env` in `android/app/build.gradle.kts`:

```kotlin
val dotEnv: Map<String, String> =
    rootProject.projectDir.parentFile.resolve(".env").takeIf { it.exists() }
        ?.readLines()
        ?.map { it.trim() }
        ?.filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
        ?.associate { it.substringBefore("=").trim() to it.substringAfter("=").trim() }
        ?: emptyMap()
val fbAppId = dotEnv["FB_APP_ID"].orEmpty()
val fbClientToken = dotEnv["FB_CLIENT_TOKEN"].orEmpty()
val metaEnabled = fbAppId.isNotEmpty() && fbClientToken.isNotEmpty()
// … in defaultConfig:
        resValue("string", "facebook_app_id", fbAppId.ifEmpty { "0" })
        resValue("string", "facebook_client_token", fbClientToken.ifEmpty { "0" })
        resValue("bool", "facebook_auto_init", metaEnabled.toString())
```

with `buildFeatures { resValues = true }`.

### Pattern 20 — Optional native config (Firebase)

`android/app/build.gradle.kts`:

```kotlin
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
```

`android/settings.gradle.kts` plugins block: `id("com.google.gms.google-services") version "4.4.4" apply false`. Xcode "Copy Firebase Config" run-script phase:

```sh
# Firebase reads ios/Runner/GoogleService-Info.plist (from the Firebase console).
# It is git-ignored, so it is copied into the app only when present;
# without it the app builds and runs without Firebase.
SRC="${PROJECT_DIR}/Runner/GoogleService-Info.plist"
if [ -f "$SRC" ]; then
  cp "$SRC" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
else
  echo "warning: GoogleService-Info.plist not found; Firebase is off in this build."
fi
```

Release signing with a debug fallback: `key.properties` (git-ignored by `android/.gitignore`) → `signingConfigs.create("release")`, `release { signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug") }`.

### Pattern 21 — `analysis_options.yaml` (complete, template with excludes)

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**

linter:
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule
```

(the file also carries the Flutter template's explanatory comments). No rule is enabled or disabled beyond `flutter_lints`; `lib/` contains zero `// ignore:` / `// ignore_for_file:`.

### Pattern 22 — pubspec `flutter:` and `flutter_launcher_icons:` blocks (verbatim)

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icon.png
    - assets/applogo.png
    - assets/coin.png
    - .env
  fonts:
    - family: Marcellus
      fonts:
        - asset: assets/fonts/Marcellus-Regular.ttf

flutter_launcher_icons:
  image_path: assets/applogo.png
  android: true
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: assets/applogo.png
  ios: true
  remove_alpha_ios: true
  web:
    generate: true
    background_color: "#FFFFFF"
    theme_color: "#13372E"
  windows:
    generate: true
    icon_size: 256
  macos:
    generate: true
```

`.env` is a bundled asset (so `Env.load()` can read it) — only client-safe values may go in it.

### Pattern 23 — `.gitignore` additions beyond the Flutter template (verbatim tail)

```
# Local environment values (see .env.example)
.env

# MCP config holds a token
.mcp.json

# Native config generated from .env (tool/sync_native_env.dart)
ios/Flutter/Env.xcconfig
```

(The template part also ignores `.dart_tool/`, `.flutter-plugins-dependencies`, `/build/`, `/coverage/`, `.widget_preview/`, generated plugin registrants, `.fvm/flutter_sdk`.)

### Pattern 24 — Dev workflow commands (exact)

From AGENTS.md §15, confirmed by `.claude/settings.json` (`Bash(dart format *)`, `Bash(dart analyze *)`, `Bash(flutter test *)`) and the project memory:

```
dart format <every touched file>
dart analyze                      # no errors or warnings in touched files
flutter test                      # the full suite must pass
flutter test test/features/<feature>/...   # one file or folder while working
flutter test --reporter compact | tr '\r' '\n' | grep '[0-9]'   # Windows: the compact reporter separates lines with \r
dart run tool/sync_native_env.dart         # before an iOS build, whenever .env changes
firebase.cmd apps:sdkconfig ANDROID <app id> --project getmymali -o android/app/google-services.json   # Windows: firebase.cmd
dart run <script in the scratchpad>        # Python is not installed on the dev machine; JSON is parsed with dart run
```

Not stated anywhere but implied by the `flutter_launcher_icons:` block: `dart run flutter_launcher_icons`. The gradle comment notes `flutter run --release` works without `key.properties` (debug key fallback).

---

## 4. Rules observed in code

Rules the code follows that AGENTS.md does not state, or states differently. Where AGENTS.md is quoted, the quote is verbatim.

1. **The widget-test setup in AGENTS.md §14 is incomplete.** It shows only `sl.registerSingleton<AuthRepository>(FakeAuthRepository()); registerAuthFeature();`. In code, anything that pumps `App` must also register `CatalogRepository`, `AppConfigRepository`, `CartRepository`, `WishlistRepository`, `LocationRepository`, `MaliCoinsRepository`, `CouponRepository`, `KoEngagementService` + `AnalyticsService` (via `registerFakeEngagement()`), and call `registerCatalogFeature`, `registerAppConfigFeature`, `registerHomeFeature`, `registerCategoriesFeature`, `registerCartFeature`, `registerWishlistFeature`, `registerLocationFeature`, `registerSettingsFeature`, `registerMaliCoinsFeature`, `registerCouponsFeature` and `registerAccountFakes()`, or `sl<…>()` throws inside `App`/`HomePage`. `registerSignedInApp` is the actual minimal set.
2. **Two registration styles coexist.** Older page tests hand-roll the `sl` block (`widget_test.dart`, `categories_page_test.dart`, `product_detail_page_test.dart`, `cart_page_test.dart`…); newer ones call `registerSignedInApp(...)` (10 files). Both end with `tearDown(sl.reset)`; `invoice_page_test.dart` resets inside a multi-statement `tearDown(() { …; sl.reset(); })` because it also clears method-channel mocks.
3. **Fakes are registered with `registerSingleton` (eager instance), production code with `registerLazySingleton`/`registerFactory`.** AGENTS.md §9 only describes the production side. A test reads a fake back with `sl<CatalogRepository>() as FakeCatalogRepository` when it did not keep the reference.
4. **File-private fakes are the norm for data-layer tests.** `_FakeRemote`, `_FakeLocal`, `_FakeSession`, `_FakeTokens`, `_FakeKoOrders`, `_FakeAttempts`, `_FakeMedusaCustomers` live in the test file; a fake moves to `test/helpers/` when a second test needs it (`FakeCartRemoteDataSource`, used by 2) or when it fakes a core service (`FakePaymentGateway`, used by 1). AGENTS.md says only "see `test/helpers/fake_auth_repository.dart`".
5. **Fakes may reuse pure domain helpers** instead of stubbing: `FakeCartRepository.syncCart` runs `mergeServerLines`/`changedVariants`; `FakeCouponRepository.checkCoupon` runs `normalizeCouponCode`/`validateCoupon`; `FakeGstinRepository.verifyGstin` runs `validateGstin`/`gstinStateName`; `FakeCheckoutRepository.getQuote` uses `smallCartFee(subtotal, testChargeRules)`.
6. **Test-data constants are public and prefixed `test`** in helpers (`testSession`, `testProduct`, `testCartItem`, `testCoinRules`…), **private and `_`-prefixed** inside a test file (`_issuedTokens`, `_sessionModel`, `_serverError`, `_quote`). Two helpers break the prefix: `welcome10`/`mali50` (coupons) and `validGstinNumber`/`savedGstin`.
7. **Test descriptions are lower-case sentences without "should"**: `'saves the tokens in secure storage, not in prefs'`, `'a 401 forgets the token, mints again and tries once more'`. Long ones are split across adjacent string literals. `group()` is per method or per concern (`'sendOtp'`, `'cache-first'`, `'the price sheet'`, `'analytics'`).
8. **Bloc tests never use `bloc_test`** (AGENTS.md §1 agrees); the idioms are `bloc.stream.take(n).toList()` subscribed *before* `add`, `bloc.stream.first`, `bloc.stream.firstWhere(...)`, `Future<void>.delayed(Duration.zero)` (21 files) and, in repository tests with background pushes, `await pumpEventQueue()` (14 files). Not in AGENTS.md.
9. **Blocs and services take `now`/`wait` for determinism** (10 files, Pattern 17). AGENTS.md mentions the clock only for `HiveLocalCache`.
10. **`@visibleForTesting` statics are the sanctioned test hooks**: `Env.allowTestPayments`, `DeviceSecureStorage.resetMemory()`, `PushPermissionPrompt.resetForTest()`, `OrderPlacedPage.reportedOrders`. Static state (`PrefUtils._sharedPreferences`, `DeviceSecureStorage._memory`, `PushPermissionPrompt._asked`) must be reset in `setUp`.
11. **Phone-size view.** AGENTS.md: "Use a phone-size view: `tester.view.physicalSize = Size(1170, 2532)` with `devicePixelRatio = 3`." Code: 23 files set a size; 20+ use exactly `const Size(1170, 2532)`; outliers `Size(1080, 2400)`, `Size(960, 1800)`, `Size(screenWidth * 3, 2532)`. Always paired with `addTearDown(tester.view.reset)`. Generic widget tests use the default 800×600 surface instead.
12. **Splash is time-based**: every `App` test does `await tester.pump(SplashPage.displayDuration); await tester.pumpAndSettle();` before asserting a page. AGENTS.md does not mention `displayDuration` (2600 ms).
13. **`AppRouter(analytics: sl<AnalyticsService>())` vs `AppRouter()`**: `launchSignedInApp` passes analytics so screen views are recorded; hand-rolled tests that do not assert screens use `AppRouter().router`.
14. **Test file paths mirror `lib/`** (AGENTS.md §14) with these deviations: combined layer tests `test/features/account/data/account_data_test.dart`, `test/features/delivery/data/delivery_remote_data_source_test.dart`, `test/features/delivery/domain/delivery_test.dart`, `test/features/product/data/datasources/product_data_sources_test.dart`, `test/features/product/data/models/product_models_test.dart`, `test/features/profile/data/models/profile_models_test.dart`, `test/features/referral/data/models/referral_models_test.dart`; concern-split tests `cart_bloc_test` / `cart_bloc_stock_test` / `cart_bloc_sync_test` / `cart_bloc_analytics_test`, `cart_repository_impl_test` / `cart_repository_sync_test`, `cart_page_bloc_test` / `cart_page_charge_rules_test`, `auth_bloc_test` / `auth_login_analytics_test`, `coupon_bloc_test` / `coupon_bloc_analytics_test`, `wishlist_bloc_test` / `wishlist_bloc_analytics_test`; app-level tests in `test/app/app_engagement_test.dart` and the root `test/widget_test.dart`.
15. **`FakeNetworking` does not implement `putAPICall` or `graphqlQueryCall`**; `noSuchMethod` forwards to `Object.noSuchMethod`, so a data source that calls them in a test throws `NoSuchMethodError`. Add the override when needed. (`Networking` is `abstract class`, not `abstract interface class`; fakes still `implements` it.)
16. **Two `ServerException` classes exist** (`core/app/exceptions/app_exceptions.dart` legacy, `core/app/exceptions/api_exceptions.dart` the live one). Tests import the legacy file `as app` (`app.InternetException()`, `app.AppException('offline', 'Timeout')`) and the api one unprefixed.
17. **AnalyticsService in tests is `KoAnalyticsService(fake)`**, never `MultiDestinationAnalyticsService`; GA4/Meta destinations are unit-tested through method-channel mocks only. AGENTS.md §23 says the fake "also registers the `AnalyticsService` over it" (consistent) but does not say which class.
18. **AGENTS.md "Reference: placing a COD order" is stale about the warehouse pause.** It says: "their two calls in `OrderPlacedBloc._onStarted` are commented out, and their tests are skipped (`_warehousePaused`)". Code: `lib/features/checkout/presentation/order_placed/bloc/order_placed_bloc.dart:106-112` runs `_lookUp(emit)` and `_poll(openedAt, emit)` inside `Future.wait([...])` (live), and `grep -rn "warehousePaused\|skip:" test/` finds nothing. Also "Restore the calls to bring back the warehouse's lines" and "The warehouse is not asked for now" are therefore not true of the code.
19. **Firebase config files are tracked in git**, though the Xcode phase comment says "It is git-ignored" and AGENTS.md §23 says they are "downloaded from the Firebase console". `git ls-files` lists `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`; neither root nor platform `.gitignore` names them. (`android/key.properties` and `android/app/upload-keystore.jks` exist locally and **are** ignored by `android/.gitignore`.)
20. **`toastification`, `connectivity_plus`, `internet_connection_checker`, `cupertino_icons` are declared but unused by the architecture**: `toastification` 0 imports; the two connectivity packages are imported only by the legacy `lib/core/app/bloc/connectivity_bloc/` which nothing references; `cupertino_icons` 0 imports (template default). AGENTS.md §16 lists the connectivity bloc as legacy but does not say the packages are otherwise dead.
21. **`analysis_options.yaml` is the untouched template plus an `exclude:` list**; "no errors or warnings in touched files" (AGENTS.md §15) is achieved without a single `// ignore`.
22. **Snackbars are keyed** (`Key('<screen>_<x>Message')`) and always preceded by `hideCurrentSnackBar()`; AGENTS.md §20/§22 says "shows a `SnackBar`" without the key or the hide.
23. **`Failure` is not `Equatable` and not `const`**; tests check identity with `same(failure)` and type with `isA<…>()`, never equality. `ServerFailure.errorCode` is asserted via `.having((f) => f.errorCode, 'errorCode', 'PGRST301')`.
24. **`APIResponse` equality excludes `rawData`** (`SuccessResponse.props = [successMessage, statusCode, data]`), so two responses differing only in `rawData` are equal — tests never compare responses, only what the data source produced.
25. **`.env.example` lists `RAZORPAY_MODE` twice** (one commented) on purpose: "Keep exactly one RAZORPAY_MODE line uncommented". `.env` and `.env.example` have identical key sets (22 keys).
26. **The pbxproj is listed under `.metadata` `unmanaged_files`**, i.e. the Firebase copy phase was added by hand and `flutter migrate` must not touch it.

---

## 5. Packages

Constraint from `pubspec.yaml`; resolved version from `pubspec.lock`; importers from `grep "import 'package:<name>/"` over `lib/` (test importers from `test/`).

| package | constraint → resolved | files that import it (lib) | class |
|---|---|---|---|
| `flutter` (sdk) | — | everywhere | ALWAYS |
| `cupertino_icons` | `^1.0.8` → 1.0.9 | none | template default (UNUSED; keep or drop) |
| `equatable` | `^2.0.7` → 2.1.0 | 99 files (states, entities, `APIResponse`, `NoParams`) | ALWAYS |
| `flutter_bloc` | `^9.1.0` → 9.1.1 | 93 files | ALWAYS |
| `bloc` | `^9.0.0` → 9.2.1 | 0 direct `package:bloc/` imports (comes through `flutter_bloc`); declared anyway | ALWAYS (declared) |
| `gap` | `^3.0.1` → 3.0.1 | `features/auth/presentation/login/widgets/login_details_step.dart`, `login_otp_step.dart` | optional UI helper |
| `intl` | `^0.20.2` → 0.20.3 | `core/utils/currency_format.dart`, `core/widgets/form_helper/fields/date_slector_field.dart`, `checkout/…/estimated_delivery.dart`, `invoice/…/invoice_format.dart`, `mali_coins/…/coin_formats.dart`, `orders/…/order_texts.dart`, `product/…/product_texts.dart` | ALWAYS (formatting) |
| `fpdart` | `^1.1.1` → 1.2.0 | 131 files | ALWAYS |
| `get_it` | `^8.0.3` → 8.3.0 | `core/di/injection_container.dart` only | ALWAYS |
| `loading_animation_widget` | `^1.3.0` → 1.3.0 | `core/widgets/buttons/{primary,secondary,dashed_outline,slide_action}_button.dart`, `auth/…/splash_page.dart` (the loading dots) | ALWAYS (button contract `isLoading`) |
| `toastification` | `^2.3.0` → 2.3.0 | **none** | UNUSED — declared in pubspec, never imported; feedback is `SnackBar` / `AppInfoSheet` |
| `connectivity_plus` | `^6.0.5` → 6.1.5 | only legacy `core/app/bloc/connectivity_bloc/connectivity_bloc.dart` (unreferenced) | LEGACY / effectively unused |
| `internet_connection_checker` | `^1.0.0+1` → 1.0.0+1 | same legacy file | LEGACY / effectively unused |
| `dio` | `^5.11.1` → 5.11.1 | `core/repositories/base_api_repository.dart`, `core/services/networking/curl_logger_interceptor.dart`, `core/services/networking/networking.dart` | ALWAYS |
| `crypto` | `^3.0.6` → 3.0.7 | `features/checkout/data/repositories/checkout_repository_impl.dart` (SHA-256 Medusa password) | MYMALI-SPECIFIC |
| `shared_preferences` | `^2.0.5` → 2.5.5 | `core/services/pref_utils.dart` | ALWAYS |
| `flutter_secure_storage` | `^11.2.0` → 11.2.0 | `core/services/secure_storage/device_secure_storage.dart` | CONDITIONAL(app stores tokens) |
| `go_router` | `^18.0.2` → 18.0.2 | 30 files | ALWAYS |
| `intl_phone_field` | `^3.2.0` → 3.2.0 | `core/widgets/form_helper/fields/phone_text_form_field.dart` | CONDITIONAL(phone input) |
| `url_launcher` | `^6.2.5` → 6.3.2 | `core/widgets/rich_text.dart` (legacy), `home/…/home_page.dart`, `support/…/help_support_page.dart` | CONDITIONAL(opens links) |
| `supabase_flutter` | `^2.17.2` → 2.17.2 | `app/bootstrap.dart`, `core/di/injection_container.dart`, `core/services/secure_storage/secure_session_storage.dart`, `auth/data/datasources/auth_session_data_source.dart`, `auth/data/models/auth_session_model.dart` | CONDITIONAL(Supabase backend) |
| `flutter_dotenv` | `^6.0.1` → 6.0.1 | `core/config/env.dart` | ALWAYS |
| `skeletonizer` | `^3.0.0` → 3.0.0 | 14 skeleton/page files | ALWAYS (loading placeholders) |
| `cached_network_image` | `^4.0.4` → 4.0.4 | `core/widgets/app_network_image.dart` | CONDITIONAL(network images) |
| `hive_ce` | `^2.20.1` → 2.20.1 | `core/services/local_cache/hive_local_cache.dart` (via `hive_ce_flutter`) | CONDITIONAL(caches server data) |
| `hive_ce_flutter` | `^2.4.0` → 2.4.0 | `core/services/local_cache/hive_local_cache.dart` | CONDITIONAL(caches server data) |
| `geolocator` | `^14.1.1` → 14.1.1 | `location/data/datasources/device_location_data_source.dart` | CONDITIONAL(location) |
| `geocoding` | `^5.0.0` → 5.0.0 | same | CONDITIONAL(location) |
| `share_plus` | `^13.3.1` → 13.3.1 | `invoice/…/invoice_page.dart`, `product/…/product_detail_page.dart`, `referral/…/referral_page.dart` | CONDITIONAL(share) |
| `image_picker` | `^1.2.4` → 1.2.4 | `profile/data/datasources/avatar_picker_data_source.dart` | CONDITIONAL(photo pick) |
| `package_info_plus` | `^10.2.2` → 10.2.2 | `account/data/datasources/app_info_data_source.dart` | CONDITIONAL(shows version) |
| `firebase_core` | `^4.15.0` → 4.15.0 | `app/bootstrap.dart`, `core/services/analytics/firebase_analytics_destination.dart` | CONDITIONAL(Firebase) |
| `katyayani_core` | `^2.0.7` → 2.0.7 | `core/services/katyayani_core/ko_engagement_service_impl.dart` **only** | MYMALI-SPECIFIC |
| `flutter_local_notifications` | `^22.3.1` → 22.3.1 | `core/services/local_notifications/local_notification_service_impl.dart` | CONDITIONAL(push channel) |
| `pdf` | `^3.13.1` → 3.13.1 | `invoice/presentation/utils/invoice_pdf.dart` | CONDITIONAL(PDF) |
| `razorpay_flutter` | `^1.4.7` → 1.4.7 | `core/services/payments/razorpay_payment_gateway.dart` | CONDITIONAL(payments) |
| `firebase_analytics` | `^12.6.0` → 12.6.0 | `core/services/analytics/firebase_analytics_destination.dart` | CONDITIONAL(GA4) |
| `facebook_app_events` | `^0.30.5` → 0.30.5 | `core/services/analytics/meta_analytics_destination.dart` | CONDITIONAL(Meta) |
| `app_tracking_transparency` | `^2.0.7` → 2.0.7 | same | CONDITIONAL(Meta on iOS) |
| **dev** `flutter_test` (sdk) | — | 259 test imports | ALWAYS |
| **dev** `flutter_lints` | `^6.0.0` → 6.0.0 | `analysis_options.yaml` | ALWAYS |
| **dev** `flutter_launcher_icons` | `^0.14.4` → 0.14.4 | pubspec block | ALWAYS (tooling) |

No `mockito`, `mocktail`, `bloc_test`, `build_runner`, `json_serializable`, `freezed`, `dependency_overrides` or `pubspec_overrides.yaml`.

Packages imported by tests (count of import lines): `mymali` 1578, `flutter_test` 259, `flutter` 66, `fpdart` 29, `flutter_bloc` 10, `shared_preferences` 8, `go_router` 8, `cached_network_image` 4, `flutter_dotenv` 2, `supabase_flutter` 1, `skeletonizer` 1, `package_info_plus` 1, `hive_ce` 1, `flutter_secure_storage` 1, `facebook_app_events` 1, `dio` 1.

---

## 6. What varies per app

| thing | MyMali value | where it appears |
|---|---|---|
| Package name / import prefix | `mymali` → `package:mymali/…` | `pubspec.yaml` `name`; every `lib/` and `test/` import |
| Version | `1.0.1+21` | `pubspec.yaml`; `FakeAccountRepository` default `AppVersion('1.0.1', '9')`; `.env` `APP_VERSION` |
| SDK | `sdk: ^3.13.4`; Flutter 3.47.x | `pubspec.yaml`, `pubspec.lock` `sdks:`, `.metadata` revision |
| Android `applicationId`/`namespace`, iOS bundle id | `com.katyayani.mymali` | `android/app/build.gradle.kts`; Xcode project |
| App labels | `android:label="mymali"`, `CFBundleDisplayName Mymali`, `CFBundleName mymali`, `MaterialApp.router(title: 'MyMali')`, `FacebookDisplayName My Mali` | manifest, `Info.plist`, `app.dart` |
| Assets | `assets/icon.png`, `assets/applogo.png`, `assets/coin.png`, `assets/fonts/Marcellus-Regular.ttf`, font family `Marcellus` | `pubspec.yaml`, `AppAssets`, `AppTheme.displayFontFamily` |
| Launcher icon | `image_path: assets/applogo.png`, `#FFFFFF`, `theme_color "#13372E"` | `pubspec.yaml` |
| `.env` keys | Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (CONDITIONAL). MyMali: `KO_ENV`, `MEDUSA_URL`, `MEDUSA_PUBLISHABLE_KEY`, `STOCKSHIP_URL_BETA/_PROD`, `UTILS_URL_BETA/_PROD`, `RAZORPAY_KEY_ID_BETA/_PROD`, `RAZORPAY_MODE`, `RAZORPAY_TEST_KEY_ID`, `MKTP_ID`, `APP_VERSION`, `PINCODE_HOST`, `GST_HOST`, `KC_API_URL`, `KC_SITE_ID`, `FB_APP_ID`, `FB_CLIENT_TOKEN`, `APP_WEB_ORIGIN` | `.env`, `.env.example`, `Env` getters, `env_test.dart`, `build.gradle.kts`, `sync_native_env.dart` `_keys` |
| `Env` getter names and enums | `supabaseUrl`, `supabaseAnonKey`, `medusaBaseUrl`, `medusaApiKey`, `webOrigin`, `koEnv`, `utilsUrl`, `stockshipUrl`, `razorpayKeyId`, `razorpayMode`, `allowTestPayments`, `mktpId`, `kcSiteId`, `kcApiUrl`, `fbAppId`, `fbClientToken`, `appVersion`; `enum KoEnv { production, beta }`, `enum RazorpayMode { live, test }` | `lib/core/config/env.dart` |
| `ApiHost` values | `supabase` (default), `medusa`, `koUtils`, `stockship` | `networking.dart`; `RecordedCall.host` default; test assertions `call.host` |
| Cache boxes | `catalog`, `charge_rules`, `addresses`, `mali_coins`, `coin_rules`, `coupons`, `product`, `seller`, `support`; `userScoped = [addresses, maliCoins]` | `CacheBoxes`; `FakeLocalCache.clearUserScoped`; `hive_local_cache_test` uses `CacheBoxes.catalog` |
| Secure keys | `auth.access_token`, `auth.refresh_token`, `auth.user_id`, `secure_storage.installed`, Supabase `sb-<ref>-auth-token` | `AuthLocalDataSource`, `StringConstants.appAuthToken`, `DeviceSecureStorage.installedKey`, `SecureSessionStorage.keyFor` |
| Repositories `App` needs | `AuthRepository`, `CatalogRepository`, `AppConfigRepository`, `CartRepository`, `WishlistRepository`, `LocationRepository`, `MaliCoinsRepository`, `CouponRepository`, `ProfileRepository`, `ReferralRepository`, `AccountRepository` | `registerSignedInApp`, `registerAccountFakes`, `App` providers |
| `register<Feature>Feature()` list | 24 functions (section 2) | `injection_container.dart`; every page test |
| Engagement/analytics service names | `KoEngagementService`, `KoAnalyticsService`, `AnalyticsService`, `AnalyticsItem`, `AppEvents.*`, screen names `ShopTab`, `CategoriesTab`, … | `signed_in_app.dart`, `fake_ko_engagement_service.dart`, `app_engagement_test.dart` |
| Splash duration | `SplashPage.displayDuration = 2600 ms` | every `App` test |
| Widget keys used by helpers | `shell_homeTab`, `shell_categoriesTab`, `shell_accountTab`, `account_page`, `account_scrollView`, `account_footer`, `account_signOutButton`, `account_signOutSheet`, `home_themeToggle`, `login_*`, `catalog_*`, `product_page`, `product_scrollView`, `referral_page`, `editProfile_page` | helpers and page tests |
| Test fixture values | `user-1`, `+919876543210`, `Asha`, `CUSTOMER`, `prod_01`, `variant_01`, `MM-NEEM-250`, `pcat_01`, Bhopal address, `WELCOME10`/`MALI50`, `27AAPFU0939F1ZV`, `KMM-10345`, `MKTP-208`, `rzp_test_key`, clock `DateTime.utc(2026, 10, 1)` | `test/helpers/*` |
| Push channel | id `push_campaigns`, icon `@drawable/notification_icon`, sound `res/raw/notification.wav` | manifest, `LocalNotificationServiceImpl` |
| Permissions and usage strings | location, photos, tracking texts; `POST_NOTIFICATIONS`, `VIBRATE`, `ACCESS_NETWORK_STATE` | manifest, `Info.plist` |
| UPI schemes | `tez, gpay, phonepe, paytm, paytmmp, bhim, credpay, amazonpay, upi, fbapi, fb-messenger-share-api`; Android `<queries>` `upi` | `Info.plist`, manifest |
| Firebase | project `getmymali`; gms plugin `4.4.4`; files `google-services.json`, `GoogleService-Info.plist` | gradle, pbxproj phase |
| Gradle toolchain | AGP `9.1.0`, Kotlin `2.4.0`, Java 17, `desugar_jdk_libs:2.1.4`, `-Xmx8G` | `android/*.gradle.kts`, `gradle.properties` |
| iOS native env keys | `FB_APP_ID`, `FB_CLIENT_TOKEN` (`$(…)` in `Info.plist`) | `sync_native_env.dart`, `Env.xcconfig` |
| Phone size | `Size(1170, 2532)` @ `devicePixelRatio = 3` (iPhone 12/13/14-class) | every page test |
| Dev-tooling allowlist | `dart analyze *`, `flutter test *`, `dart format *`, `python -` | `.claude/settings.json` |

---

## 7. Gotchas

1. **`sl` is process-global.** Every test file that registers anything must `tearDown(sl.reset)`; forgetting it makes the *next* file's `registerSingleton` throw "already registered". Register fakes with `registerSingleton` (instances) and then call the production `register<Feature>Feature()`; never re-implement the use-case/bloc wiring in a test.
2. **`App` reads `sl<KoEngagementService>()` and `sl<AnalyticsService>()` in `RepositoryProvider`s and provides `CartBloc`/`CouponBloc` with `lazy: false`.** Without `registerFakeEngagement()` (or `registerSignedInApp`) and without `CartRepository`/`CouponRepository` fakes, `pumpWidget(App(...))` throws before the first frame.
3. **Static state leaks between tests.** `PrefUtils._sharedPreferences` (static) → always `SharedPreferences.setMockInitialValues({...})`, then `PrefUtils()..init()..clearAll()`. `DeviceSecureStorage._memory` (static map) → `DeviceSecureStorage.resetMemory()` in `setUp`. `PushPermissionPrompt._asked` → `PushPermissionPrompt.resetForTest()`. `OrderPlacedPage.reportedOrders` (static set). `Env.allowTestPayments` → reset in `tearDown`.
4. **The splash is a 2600 ms timer.** `pumpAndSettle` alone does not pass it reliably in the intended way; the tests always `pump(SplashPage.displayDuration)` first, then `pumpAndSettle()`.
5. **Do not `pumpAndSettle` while a gate holds a skeleton on screen** — `skeletonizer`'s shimmer animates forever and `pumpAndSettle` times out. Pump fixed durations (`referral_page_test.dart` `settle: false`). With saved data on screen (no skeleton) `pumpAndSettle` is fine (`categories_page_test.dart`). `SlideActionButton`'s chevrons stop after a few sweeps precisely so `pumpAndSettle` works (AGENTS.md §21).
6. **`enterText` then `pump()` before tapping a button whose enabled state depends on the input** (AGENTS.md §14; `submitDetails` in `widget_test.dart`). Type into `find.descendant(of: find.byKey(Key(k)), matching: find.byType(EditableText))`, not into the `KeyedSubtree` itself.
7. **Subscribe before you `add`.** `final states = bloc.stream.take(n).toList(); bloc.add(event); await states;` — adding first loses synchronous emissions. `bloc.stream.first` after `add` is only safe when exactly one emission follows.
8. **`FakeNetworking.error` wins over `response` and `queued`;** `queued` is consumed one answer per call and then falls back to `response`; `lastCall` throws on an empty list. `putAPICall`/`graphqlQueryCall` are not implemented (NoSuchMethodError).
9. **`okResponse`/`errorResponse` carry status codes as Strings** (`'200'`, `'401'`), matching `SuccessResponse.statusCode`/`ErrorResponse.errorCode` types; the data source parses `errorCode` to an int.
10. **Two `ServerException`s.** Import `core/app/exceptions/app_exceptions.dart` `as app` in tests that need `app.InternetException()`/`app.RequestTimeoutException()`/`app.AppException(message, prefix)`; the repository-visible one is `core/app/exceptions/api_exceptions.dart`.
11. **`FakeLocalCache` JSON-encodes values** so a model whose `toJson()` contains a non-JSON type (e.g. `DateTime`) fails in the fake exactly as in Hive (`write(DateTime(2026))` throws). Expiry compares against the fake's mutable `now`; a version mismatch deletes the entry (as Hive does), an expired entry is kept.
12. **`HiveLocalCache` tests must call `Hive.init(dir)` + `HiveLocalCache.openBoxes()`**, not `HiveLocalCache.init()` (which calls `Hive.initFlutter()` and needs the path_provider plugin).
13. **Generic widget tests run on the default 800×600 surface**; page tests set 1170×2532 @3 (390×844 logical). A width assertion like `expect(size.width, 800)` only holds without the phone-size view. Always `addTearDown(tester.view.reset)`.
14. **`flutter test --reporter compact` on Windows emits `\r`-separated lines**: pipe through `tr '\r' '\n'` before `grep`, and use `[0-9]` rather than `\d`. Python is not installed on the dev machine; use `dart run` for JSON munging.
15. **`.env` is a bundled asset**: `Env.load()` works in the app, not in tests; tests use `dotenv.loadFromString`. A missing key throws `StateError('Missing X in .env (see .env.example).')`, so never read an `Env` getter in a test without loading its key.
16. **`.env` must hold only client-safe values** (anon/publishable keys); `.mcp.json` holds a real token and is git-ignored — never copy it into a skill.
17. **Firebase files are tracked** despite comments saying otherwise; decide explicitly for a new app (and add them to `.gitignore` if they are to be downloaded per machine). `key.properties`/`*.jks` are ignored only because `android/.gitignore` (template) says so — do not delete that file.
18. **`#include? "Env.xcconfig"`** (with the `?`) is what lets iOS build without running `sync_native_env.dart`; a plain `#include` would break every build until the script runs.
19. **`android/app/build.gradle.kts` resolves `.env` relative to `rootProject.projectDir.parentFile`**, i.e. the Flutter project root, and needs `buildFeatures { resValues = true }` for `resValue` to be honoured under AGP 9.
20. **`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`** is required by `flutter_local_notifications` 22.x; dropping the notifications package lets both go.
21. **The analyzer excludes every platform folder**, so `dart analyze` never sees Kotlin/Swift; it still analyses `test/` and `tool/`.
22. **`toastification` is in pubspec but must not be used**: user feedback is `SnackBar` via `ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(key: Key('<screen>_<x>Message'), content: Text(...)))` for passing notes, `AppInfoSheet.show` for anything acknowledged, `AppPickerSheet.show<T>` for choices, `ReloadWidget` for `status == failure`, a field's `errorText` for input errors. The only `AlertDialog` is the legacy OTP dialog in `LoginPage`.
23. **`registerHomeFeature({String imageBaseUrl = ''})`**: production passes `Env.medusaBaseUrl`; tests omit it. Any new feature function that needs an `Env` value must take it as a parameter the same way, or page tests will hit `Env` without a loaded `.env`.
24. **`AppRouter` is a class with a `late final router`, not a function**; create it once per test and keep the reference when the test will `pushNamed` (`router = AppRouter().router; … router.pushNamed(AppRoute.productDetail.name, pathParameters: {ProductDetailPage.idParam: 'prod_01'})`).
25. **Fixture dates are fixed UTC values** (`DateTime.utc(2026, 10, 1)`, `DateTime.utc(2030)`) and clocks are injected; a fake that defaults to `DateTime.now()` (`notificationNamed`) is the exception, and it exists for sort-order tests only.
26. **AGENTS.md is stale in two places that a skill must not copy**: the "warehouse paused / `_warehousePaused`" claim (the calls are live, nothing is skipped) and the §14 widget-test setup snippet (too small to boot `App`).
