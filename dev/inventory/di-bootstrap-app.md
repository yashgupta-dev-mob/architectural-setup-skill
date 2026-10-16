# Inventory: di-bootstrap-app

Source repo: `C:/Users/Katyayani/Documents/flutter/mymali` (Dart package name `mymali`). Area: `lib/main.dart`, `lib/app/bootstrap.dart`, `lib/app/app.dart`, `lib/core/di/injection_container.dart`, plus everything they construct, the app-wide blocs they provide, and how pages create blocs. Every code block below is verbatim from the repo unless marked "shape".

Classification key: **ALWAYS** = generic architecture, install in every app (placeholders listed); **CONDITIONAL(capability)** = install only when the target app has that capability; **MYMALI-SPECIFIC** = this app's business logic.

---

## 1. Files

### 1.1 The four files of the area

| path | role | class | placeholders |
|---|---|---|---|
| `lib/main.dart` | Only calls `bootstrap()` | ALWAYS | none |
| `lib/app/bootstrap.dart` | Startup sequence: binding, portrait lock, `Env.load`, Firebase, secure storage wipe-on-fresh-install, `Supabase.initialize` with secure session storage, Hive cache, `configureDependencies()`, non-blocking engagement/notification init, iOS tracking prompt, `runApp(App(router: AppRouter(analytics:).router))` | ALWAYS (shape) with CONDITIONAL steps: `_initFirebase` (Firebase), `DeviceSecureStorage.init` + `SecureSessionStorage` (tokens/Supabase session), `Supabase.initialize` (Supabase), `HiveLocalCache.init` (cache), `_initEngagement` (push + engagement SDK), `requestTrackingPermission` (Meta/ATT) | `Env.supabaseUrl`, `Env.supabaseAnonKey`; the services started; log prefixes `[firebase]` |
| `lib/app/app.dart` | `App` widget: `MultiBlocProvider` of app-wide blocs + `RepositoryProvider`s for services, `MultiBlocListener` wiring sign-in/out fan-out and cross-bloc links, `MaterialApp.router` with theme, themeMode, text-scale clamp | ALWAYS (shape); the bloc list and listener bodies are MYMALI-SPECIFIC | `title: 'MyMali'`, `maxTextScaleFactor = 1.1`, the eight blocs, the two services, every listener |
| `lib/core/di/injection_container.dart` | `final GetIt sl`, `configureDependencies()`, `_registerCore()`, `_analyticsDestinations()`, one `_register<Feature>Data()` + `register<Feature>Feature()` pair per feature | ALWAYS (shape: `sl`, `configureDependencies`, `_registerCore`, naming convention, lazy-singleton/factory split, abstract-type registration); every feature block is MYMALI-SPECIFIC | the feature list, every `Env.*` read, host/key names |

### 1.2 Core files the area constructs or depends on

| path | role | class | placeholders |
|---|---|---|---|
| `lib/core/config/env.dart` | `abstract final class Env` typed `.env` access: `load()`, `_require`, `_optional`, `_koValue`, enums `KoEnv`, `RazorpayMode` | ALWAYS (shape); `koEnv`, `_koValue`, `razorpayKeyId`, `razorpayMode`, `allowTestPayments`, `mktpId`, `kcSiteId`, `kcApiUrl`, `fbAppId`, `fbClientToken`, `medusa*`, `utilsUrl`, `stockshipUrl` are MYMALI-SPECIFIC | every getter name and `.env` key; `_fileName = '.env'` |
| `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics})` with `late final GoRouter router`, one `AnalyticsRouteObserver` per navigator, `StatefulShellRoute.indexedStack` tabs, root-navigator full-screen routes | ALWAYS (shape) | route list, tab branches, `AppShellScaffold` |
| `lib/core/router/app_routes.dart` | `enum AppRoute { ...; const AppRoute(this.path); final String path; }` | ALWAYS (shape) | every value |
| `lib/core/router/navigator_keys.dart` | `rootNavigatorKey` + one `GlobalKey<NavigatorState>` per tab | ALWAYS (shape) | tab key names |
| `lib/core/router/analytics_screen_tracker.dart` | `AnalyticsScreenTracker`, `AnalyticsRouteObserver`, `analyticsScreenNames`, `analyticsTabs` | CONDITIONAL(app reports screen views) | the name map, the tab list |
| `lib/core/services/analytics/analytics_service.dart` | `abstract interface class AnalyticsService` | CONDITIONAL(app reports analytics) | the ecommerce method set mirrors Katyayani Core |
| `lib/core/services/analytics/analytics_destination.dart` | `abstract interface class AnalyticsDestination` (`log`, `setUserId`, `requestTrackingPermission`) | CONDITIONAL(analytics with a second SDK) | none |
| `lib/core/services/analytics/multi_destination_analytics_service.dart` | `MultiDestinationAnalyticsService({required AnalyticsService core, required List<AnalyticsDestination> destinations})` fan-out | CONDITIONAL(analytics with >1 destination) | which typed calls also `_send` (`addToCart`, `removeFromCart`, `search`) |
| `lib/core/services/analytics/ko_analytics_service.dart` | `KoAnalyticsService(KoEngagementService)` adapter used as the `core` | MYMALI-SPECIFIC (Katyayani Core) | — |
| `lib/core/services/analytics/firebase_analytics_destination.dart` | GA4 destination; only importer of `firebase_analytics`; no-ops while `Firebase.apps.isEmpty` | CONDITIONAL(GA4) | log prefix `[ga4]` |
| `lib/core/services/analytics/meta_analytics_destination.dart` | Meta destination; only importer of `facebook_app_events` + `app_tracking_transparency` | CONDITIONAL(Meta) | log prefix `[meta]`, `_promptDelay` 1 s |
| `lib/core/services/analytics/app_events.dart` | `abstract final class AppEvents` static const event names | CONDITIONAL(analytics) | every constant value (MyMali's RN app names) |
| `lib/core/services/analytics/analytics_item.dart` | `AnalyticsItem({required sku, required quantity, required price, name, category})` | CONDITIONAL(ecommerce analytics) | none |
| `lib/core/services/katyayani_core/ko_engagement_service.dart` | `abstract interface class KoEngagementService` | MYMALI-SPECIFIC | — |
| `lib/core/services/katyayani_core/ko_engagement_service_impl.dart` | Only importer of `katyayani_core`; `init()` memoised in `_starting`; `_guard` | MYMALI-SPECIFIC (the never-throw/guard shape is reusable) | `broadcastTopic = 'all_users'`, log prefix `[kc]` |
| `lib/core/services/katyayani_core/kc_identity.dart` | `KcIdentity`, `kcIdentityFor(...)` | MYMALI-SPECIFIC | — |
| `lib/core/services/local_notifications/local_notification_service.dart` | `abstract interface class LocalNotificationService { Future<void> init(); }` | CONDITIONAL(push notifications) | none |
| `lib/core/services/local_notifications/local_notification_service_impl.dart` | Creates the Android channel; only importer of `flutter_local_notifications` | CONDITIONAL(push) | `pushChannelId = 'push_campaigns'`, `pushChannelName = 'MY Mali'`, `pushSound = 'notification'`, `androidIcon = '@drawable/notification_icon'`, `_ledColor = Color(0xFF163E33)` |
| `lib/core/services/local_cache/local_cache.dart` | `abstract interface class LocalCache` | CONDITIONAL(app caches server data) | none |
| `lib/core/services/local_cache/hive_local_cache.dart` | `HiveLocalCache({DateTime Function() now = DateTime.now})`, `static init()`, `static openBoxes()`; only Hive importer | CONDITIONAL(cache) | none |
| `lib/core/services/local_cache/cache_boxes.dart` | `abstract final class CacheBoxes` with `all`, `userScoped` | CONDITIONAL(cache) | every box name |
| `lib/core/app/exceptions/cache_exceptions.dart` | `CacheException([String? message])` | CONDITIONAL(cache) | none |
| `lib/core/services/networking/networking.dart` | `enum ApiHost`, `abstract class Networking`, `NetworkingService extends BaseApiRepo implements Networking` | ALWAYS (HTTP); `ApiHost.medusa/koUtils/stockship` MYMALI-SPECIFIC | `ApiHost` values, `_thirdPartyHosts`, default header set |
| `lib/core/services/networking/endpoints.dart` | `Endpoints` (static base URLs from `Env` + const paths), `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | ALWAYS (shape); paths MYMALI-SPECIFIC | every path, `baseUrlMain`, per-host base URL fields |
| `lib/core/repositories/base_api_repository.dart` | `BaseApiRepo` with one `Dio` per host (`dioSupabse`, `dioMedusa`, `dioKoUtils`, `dioStockship`) | ALWAYS (NetworkingService extends it) although AGENTS §16 lists it as legacy | host Dio fields |
| `lib/core/utils/string_constants.dart` | legacy constants; the live one is `appAuthToken = 'auth.access_token'` | ALWAYS for `appAuthToken` only; rest legacy | the key |
| `lib/core/app/api/api_response.dart` | `APIResponse`, `SuccessResponse`, `ErrorResponse`, `InvalidResponse` | ALWAYS (live response types) although AGENTS §16 lists it as legacy | none |
| `lib/core/app/exceptions/app_exceptions.dart` | `AppException(message, prefix)` + `InternetException`, `RequestTimeoutException`, `ServerException`, `InvalidUrlException`, `FetchDataException`, `UnAuthorizedException`, `AuthException` (thrown only when no response arrived) | ALWAYS | none |
| `lib/core/app/exceptions/api_exceptions.dart` | `ServerException({required String code, required int status, String? detail})`, `ConnectionException([String? message])` (the typed exceptions data sources throw) | ALWAYS | none |
| `lib/core/services/pref_utils.dart` | `PrefUtils` SharedPreferences wrapper with a static instance | ALWAYS | none (legacy `getUserToken` reads `'xx-token'`) |
| `lib/core/services/secure_storage/secure_storage.dart` | `abstract interface class SecureStorage { read; write; delete }` | CONDITIONAL(app stores tokens) | none |
| `lib/core/services/secure_storage/device_secure_storage.dart` | `DeviceSecureStorage` with static in-memory mirror, `static init({prefs, storage})` wipe-on-fresh-install; only importer of `flutter_secure_storage` | CONDITIONAL(tokens) | `installedKey = 'secure_storage.installed'`, log prefix `[secure_storage]` |
| `lib/core/services/secure_storage/secure_session_storage.dart` | `SecureSessionStorage extends LocalStorage` (Supabase) with legacy prefs migration | CONDITIONAL(Supabase session in secure storage) | `keyFor(url) => 'sb-<ref>-auth-token'` |
| `lib/core/services/kotech/ko_token_service.dart` | `KoTokenService`, `KoTokenServiceImpl` (memoised token, shared in-flight mint) | MYMALI-SPECIFIC (the memoised-token shape is reusable) | `Endpoints.kotechToken`, `expirySkew`, `fallbackLifetime` |
| `lib/core/services/payments/payment_gateway.dart` | `GatewayCheckout`, `GatewayPayment`, `GatewayPaymentError`, `GatewayPaymentException`, `abstract interface class PaymentGateway` | CONDITIONAL(app has payments) | none |
| `lib/core/services/payments/razorpay_payment_gateway.dart` | `RazorpayPaymentGateway({Razorpay Function()? newSdk})`, `classifyRazorpayError`; only importer of `razorpay_flutter` | CONDITIONAL(Razorpay) | `themeColor = '#225542'`, `'currency': 'INR'`, log prefix `[razorpay]` |
| `lib/core/theme/app_theme.dart` | `abstract final class AppTheme { light; dark; fontSizeFactor = 0.88; displayFontFamily = 'Marcellus'; _build }` | ALWAYS (shape) | colours mapped, factor, font |
| `lib/core/theme/app_colors.dart` | `abstract final class AppColors` brand values | ALWAYS (shape) | every colour |
| `lib/core/theme/app_tones.dart` | `AppTones extends ThemeExtension<AppTones>` with `light`, `dark`, `of(context)` | ALWAYS (shape) | tone values |
| `lib/core/usecases/usecase.dart` | `abstract interface class UseCase<T, Params> { Future<Either<Failure, T>> call(Params params); }`, `class NoParams extends Equatable` | ALWAYS | none |
| `lib/core/app/failure.dart` | `Failure({required String message, int? code})`, `NetworkFailure`, `ServerFailure({required errorCode, ...})`, `CacheMissFailure` | ALWAYS | default messages |

### 1.3 App-wide blocs provided in `app.dart`

| path | role | class | placeholders |
|---|---|---|---|
| `lib/features/auth/presentation/bloc/auth_bloc.dart`, `auth_event.dart`, `auth_state.dart` | `AuthBloc({required RestoreSession restoreSession, required SignOut signOut, AnalyticsService? analytics})`; abstract state hierarchy `AuthInitial/AuthLoading/Authenticated(user)/Unauthenticated/AuthFailure(message)` | CONDITIONAL(app has sign-in) — the reference app-wide bloc | `AppEvents.logout` |
| `lib/features/settings/presentation/bloc/theme_bloc.dart`, `theme_event.dart`, `theme_state.dart` | `ThemeBloc()` zero-dependency bloc; `ThemeState({mode = ThemeMode.system})` | ALWAYS | none (TODO: persistence) |
| `lib/features/cart/presentation/bloc/cart_bloc.dart`, `cart_event.dart`, `cart_state.dart` | `CartBloc(...)` 9 use cases + `AnalyticsService?`; `_serial` queue; `lazy: false` + `CartStarted()` in `App` | MYMALI-SPECIFIC (device-first list pattern reusable) | — |
| `lib/features/wishlist/presentation/bloc/wishlist_bloc.dart`, `_event`, `_state` | `WishlistBloc(...)` 7 use cases + analytics; `_session` guard | MYMALI-SPECIFIC | — |
| `lib/features/location/presentation/bloc/location_bloc.dart`, `_event`, `_state` | `LocationBloc(...)` 4 use cases; `_session` guard | MYMALI-SPECIFIC | — |
| `lib/features/mali_coins/presentation/bloc/mali_coins_bloc.dart`, `_event`, `_state` | `MaliCoinsBloc({required ClaimWelcomeCoins claimWelcome, required GetCachedCoinBalance getCachedBalance})` | MYMALI-SPECIFIC | — |
| `lib/features/profile/presentation/bloc/profile_bloc.dart`, `_event`, `_state` | `ProfileBloc({required GetProfile getProfile, required LoadAvatar loadAvatar, required PickAvatar pickAvatar})` | MYMALI-SPECIFIC (profile shape reusable) | — |
| `lib/features/coupons/presentation/bloc/coupon_bloc.dart`, `_event`, `_state` | `CouponBloc({required CheckCoupon checkCoupon, AnalyticsService? analytics, DateTime Function() now = DateTime.now})`; `lazy: false` in `App` | MYMALI-SPECIFIC | — |

### 1.4 Pages / blocs read as the four "how a page creates its bloc" examples

| path | role | class |
|---|---|---|
| `lib/features/auth/presentation/login/pages/login_page.dart` + `login/bloc/login_bloc.dart` | page bloc with `AnalyticsService?`; `BlocProvider<LoginBloc>(create: (_) => sl<LoginBloc>(), child: const _LoginView())`; reports to `AuthBloc` with `AuthLoggedIn`; navigates in a `BlocListener<AuthBloc, AuthState>` | CONDITIONAL(auth); OTP flow MYMALI-SPECIFIC |
| `lib/features/home/presentation/home/pages/home_page.dart` + `home/bloc/home_bloc.dart` | page bloc with 7 use cases + `imageBaseUrl`; `create: (context) => sl<HomeBloc>()..add(HomeStarted(language: ...))` | MYMALI-SPECIFIC content; pattern ALWAYS |
| `lib/features/cart/presentation/cart/pages/cart_page.dart` | page bloc seeded from an app-wide bloc's state inside `create:`; `BlocListener`s forward app-wide changes to the page bloc | pattern ALWAYS |
| `lib/features/checkout/presentation/review_pay/pages/review_pay_page.dart` | page composing four app-wide blocs without owning them | pattern ALWAYS |
| `lib/features/account/presentation/account/pages/account_page.dart` | tab page; `BlocListener<AuthBloc>` → `goNamed(login)` on `Unauthenticated`; sign-out through `AuthLogoutRequested` | pattern ALWAYS |
| `lib/features/gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart` (first 45 lines) | a **sheet** that owns a bloc: `AppPickerSheet.show<Gstin>(context, builder: (context) => BlocProvider<GstinSheetBloc>(create: (_) => sl<GstinSheetBloc>(), ...))` | pattern ALWAYS |
| `lib/features/auth/presentation/splash/pages/splash_page.dart` | dispatches `AuthStatusRequested`, waits `displayDuration` (2600 ms) and for a resolved `AuthState`, then `goNamed(home|login)` | CONDITIONAL(auth) |
| `lib/features/home/presentation/widgets/app_shell_scaffold.dart` | `AppShellScaffold({required StatefulNavigationShell navigationShell, ValueChanged<int>? onTabSelected})` | ALWAYS (shape) |
| `lib/features/auth/domain/entities/auth_user.dart` | `AuthUser` + `withProfile` | CONDITIONAL(auth) |
| `lib/features/auth/data/repositories/auth_repository_impl.dart`, `data/datasources/auth_local_data_source.dart`, `auth_session_data_source.dart` | the one repository with a `dispose()` (stream subscription); positional 3-arg local data source; `SupabaseClient` consumer | CONDITIONAL(Supabase auth) |
| `lib/features/checkout/domain/usecases/place_cod_order.dart`, `register_online_order.dart`, `lib/features/delivery/domain/usecases/check_delivery.dart` | use cases that take **two** repositories (positional / named) | MYMALI-SPECIFIC (shape reusable) |

### 1.5 Tests and config read

| path | role | class |
|---|---|---|
| `test/helpers/signed_in_app.dart` | `registerSignedInApp({...})`, `launchSignedInApp(tester)`, `openAccountTab`, `scrollAccountTo` — registers fakes by abstract type then calls the public `register<X>Feature()` functions | ALWAYS (test convention) |
| `test/helpers/fake_ko_engagement_service.dart` | `FakeKoEngagementService`, `registerFakeEngagement()` | MYMALI-SPECIFIC name; the "App needs these two services registered" rule is ALWAYS |
| `test/helpers/fake_account_repository.dart` | `registerAccountFakes({profile, referral, account})` | MYMALI-SPECIFIC |
| `test/widget_test.dart` | end-to-end splash → login → home with real use cases/blocs over fakes | ALWAYS (shape) |
| `test/app/app_engagement_test.dart` | identify/reset on sign-in/out, router screen reporting, push prompt | MYMALI-SPECIFIC |
| `pubspec.yaml` | packages, `assets: - .env`, Marcellus font | — |
| `.env.example` | every key with placeholder values | — |

---

## 2. Names

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `main` | function | `lib/main.dart` | `void main() { bootstrap(); }` |
| `bootstrap` | function | `lib/app/bootstrap.dart` | `Future<void> bootstrap() async` |
| `_initEngagement` | private function | `lib/app/bootstrap.dart` | `Future<void> _initEngagement() async { await sl<LocalNotificationService>().init(); await sl<KoEngagementService>().init(); }` |
| `_initFirebase` | private function | `lib/app/bootstrap.dart` | `Future<void> _initFirebase() async` (platform guard + try/catch + log) |
| `App` | widget | `lib/app/app.dart` | `class App extends StatelessWidget { const App({super.key, required this.router}); final GoRouter router; static const double maxTextScaleFactor = 1.1; }` |
| `sl` | top-level final | `lib/core/di/injection_container.dart` | `final GetIt sl = GetIt.instance;` |
| `configureDependencies` | function | same | `void configureDependencies()` (synchronous) |
| `_registerCore` | private function | same | `void _registerCore()` |
| `_analyticsDestinations` | private function | same | `List<AnalyticsDestination> _analyticsDestinations()` |
| `_register<Feature>Data` | private functions | same | `_registerAuthData`, `_registerCatalogData`, `_registerAppConfigData`, `_registerCartData`, `_registerWishlistData`, `_registerAddressData`, `_registerLocationData`, `_registerMaliCoinsData`, `_registerCouponsData`, `_registerOrdersData`, `_registerCheckoutData`, `_registerInvoiceData`, `_registerGstinData`, `_registerNotificationsData`, `_registerDeliveryData`, `_registerProductData`, `_registerProfileData`, `_registerReferralData`, `_registerAccountData`, `_registerSupportData` — all `void f()` |
| `register<Feature>Feature` | public functions | same | `registerAuthFeature`, `registerCatalogFeature`, `registerAppConfigFeature`, `registerHomeFeature({String imageBaseUrl = ''})`, `registerCategoriesFeature`, `registerCartFeature`, `registerWishlistFeature`, `registerSettingsFeature`, `registerGardenFeature`, `registerAddressFeature`, `registerLocationFeature`, `registerMaliCoinsFeature`, `registerCouponsFeature`, `registerOrdersFeature`, `registerCheckoutFeature`, `registerInvoiceFeature`, `registerGstinFeature`, `registerNotificationsFeature`, `registerDeliveryFeature`, `registerProductFeature`, `registerReferralFeature`, `registerAccountFeature`, `registerSupportFeature` — all `void f()` except Home |
| `Env` | class | `lib/core/config/env.dart` | `abstract final class Env { static const String _fileName = '.env'; static Future<void> load() => dotenv.load(fileName: _fileName); static String get supabaseUrl => _require('SUPABASE_URL'); ... static String _require(String key); static String? _optional(String key); }` |
| `KoEnv` | enum | same | `enum KoEnv { production, beta }` |
| `RazorpayMode` | enum | same | `enum RazorpayMode { live, test }` |
| `Env.allowTestPayments` | static mutable | same | `@visibleForTesting static bool allowTestPayments = kDebugMode;` |
| `AppRouter` | class | `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics}) : _tracker = analytics == null ? null : AnalyticsScreenTracker(analytics);` `late final GoRouter router = GoRouter(navigatorKey: rootNavigatorKey, observers: _observers(), initialLocation: AppRoute.splash.path, routes: [...])` |
| `AppRoute` | enum | `lib/core/router/app_routes.dart` | `enum AppRoute { splash('/splash'), login('/login'), home('/home'), categories('/categories'), garden('/garden'), wishlist('/wishlist'), account('/account'), cart('/cart'), selectLocation('/select-location'), coins('/coins'), reviewPay('/review-pay'), orderPlaced('/order-placed'), invoice('/invoice'), applyCoupon('/apply-coupon'), savedAddresses('/saved-addresses'), addressForm('/address-form'), editProfile('/edit-profile'), referral('/refer'), gstClaims('/gst-claims'), notifications('/notifications'), helpSupport('/help'), productDetail('/product/:id'), myOrders('/orders'), orderDetails('/orders/:id'); const AppRoute(this.path); final String path; }` |
| `rootNavigatorKey`, `homeNavigatorKey`, `categoriesNavigatorKey`, `gardenNavigatorKey`, `wishlistNavigatorKey`, `accountNavigatorKey` | top-level finals | `lib/core/router/navigator_keys.dart` | `final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');` etc. |
| `AnalyticsScreenTracker` | class | `lib/core/router/analytics_screen_tracker.dart` | `AnalyticsScreenTracker(this._analytics); NavigatorObserver observer(); void tabSelected(int index); void routeShown(Route<dynamic> route, {BuildContext? context});` |
| `AnalyticsRouteObserver` | class | same | `class AnalyticsRouteObserver extends NavigatorObserver { AnalyticsRouteObserver(this._tracker); }` |
| `analyticsScreenNames` | const map | same | `const Map<String, String> analyticsScreenNames = {'login': 'PhoneEntry', 'home': 'ShopTab', ...}` |
| `analyticsTabs` | const list | same | `const List<AppRoute> analyticsTabs = [AppRoute.home, AppRoute.categories, AppRoute.garden, AppRoute.wishlist, AppRoute.account];` |
| `AnalyticsService` | interface | `lib/core/services/analytics/analytics_service.dart` | methods: `track(String name, {Map<String, dynamic>? properties})`, `screenView(String screenName, {Map<String, dynamic>? properties})`, `viewItem({required List<AnalyticsItem> items, num? value})`, `addToCart(...)`, `removeFromCart(...)`, `viewCart(...)`, `beginCheckout({required items, num? value, String? coupon})`, `purchase({required String transactionId, required items, num? value, num? shipping, String? coupon})`, `search(String searchTerm)`, `login({String? method})`, `addPaymentInfo({required items, num? value, String? paymentType})`, `capturePayment(double amount, {String? orderId})`, `setUserId(String? userId)`, `Future<void> requestTrackingPermission()`, `checkNudges(BuildContext context, String route)` |
| `AnalyticsDestination` | interface | `analytics_destination.dart` | `void log(String eventName, Map<String, Object?>? properties); void setUserId(String? userId); Future<void> requestTrackingPermission();` |
| `MultiDestinationAnalyticsService` | class | `multi_destination_analytics_service.dart` | `const MultiDestinationAnalyticsService({required AnalyticsService core, required List<AnalyticsDestination> destinations})` |
| `KoAnalyticsService` | class | `ko_analytics_service.dart` | `const KoAnalyticsService(this._core);` (`KoEngagementService _core`) |
| `FirebaseAnalyticsDestination` | class | `firebase_analytics_destination.dart` | `FirebaseAnalyticsDestination([FirebaseAnalytics Function()? analytics])` |
| `MetaAnalyticsDestination` | class | `meta_analytics_destination.dart` | `MetaAnalyticsDestination([FacebookAppEvents? facebook])` |
| `AppEvents` | class | `app_events.dart` | `abstract final class AppEvents { static const String loginStarted = 'Login Started'; ... static const String themeChanged = 'Theme Changed'; }` (full list in the file; `themeChanged` is the one `app.dart` uses) |
| `AnalyticsItem` | class | `analytics_item.dart` | `const AnalyticsItem({required this.sku, required this.quantity, required this.price, this.name, this.category});` |
| `KoEngagementService` | interface | `katyayani_core/ko_engagement_service.dart` | `Future<void> init(); Future<void> identify({required String phone, String? fullName, String? email}); void resetIdentity(); Future<bool> requestPushPermission(); Future<bool> registerPush();` + the same event methods as `AnalyticsService` minus `setUserId`/`requestTrackingPermission` |
| `KoEngagementServiceImpl` | class | `ko_engagement_service_impl.dart` | `KoEngagementServiceImpl({required String siteId, required String apiBase}); static const String broadcastTopic = 'all_users';` |
| `KcIdentity`, `kcIdentityFor` | class, function | `kc_identity.dart` | `KcIdentity? kcIdentityFor({required String phone, String? fullName, String? email})` |
| `LocalNotificationService` | interface | `local_notifications/local_notification_service.dart` | `Future<void> init();` |
| `LocalNotificationServiceImpl` | class | `local_notification_service_impl.dart` | `LocalNotificationServiceImpl([FlutterLocalNotificationsPlugin? plugin]); static const String pushChannelId = 'push_campaigns'; static const String pushChannelName = 'MY Mali'; static const String pushSound = 'notification'; static const String androidIcon = '@drawable/notification_icon';` |
| `LocalCache` | interface | `local_cache/local_cache.dart` | `Future<Object?> read({required String box, required String key, required int version, Duration? maxAge}); Future<void> write({required String box, required String key, required int version, required Object json}); Future<void> delete({required String box, required String key}); Future<void> clearBox(String box); Future<void> clearUserScoped();` |
| `HiveLocalCache` | class | `hive_local_cache.dart` | `HiveLocalCache({DateTime Function() now = DateTime.now}); static Future<void> init(); static Future<void> openBoxes();` |
| `CacheBoxes` | class | `cache_boxes.dart` | `abstract final class CacheBoxes { static const String catalog = 'catalog'; chargeRules = 'charge_rules'; addresses = 'addresses'; maliCoins = 'mali_coins'; coinRules = 'coin_rules'; coupons = 'coupons'; product = 'product'; seller = 'seller'; support = 'support'; static const List<String> all = [...]; static const List<String> userScoped = [addresses, maliCoins]; }` |
| `CacheException` | class | `lib/core/app/exceptions/cache_exceptions.dart` | `const CacheException([this.message]); final String? message;` |
| `ApiHost` | enum | `networking/networking.dart` | `enum ApiHost { supabase, medusa, koUtils, stockship }` |
| `Networking` | abstract class | same | `getAPICall / postAPICall / patchAPICall / putAPICall / deleteAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, [dynamic data], [Map<String, String>? headers], ApiHost host = ApiHost.supabase})`, `graphqlQueryCall(...)` (put has no `headers`) |
| `NetworkingService` | class | same | `NetworkingService({this.options, SecureStorage? secureStorage}) : _secureStorage = secureStorage ?? DeviceSecureStorage()` ; `static const Set<ApiHost> _thirdPartyHosts = {ApiHost.medusa, ApiHost.koUtils, ApiHost.stockship};` |
| `BaseApiRepo` | class | `lib/core/repositories/base_api_repository.dart` | `Dio dioSupabse = Dio(BaseOptions(baseUrl: Endpoints.baseUrlMain)); Dio dioMedusa = ...; Dio dioKoUtils = ...; Dio dioStockship = ...;` (note the spelling `dioSupabse`) |
| `Endpoints` | class | `networking/endpoints.dart` | `static String baseUrlMain = Env.supabaseUrl; static String medusaBaseUrl = Env.medusaBaseUrl; static String koUtilsBaseUrl = Env.utilsUrl; static String stockshipBaseUrl = Env.stockshipUrl;` + `static const String` paths (`phoneLogin = '/functions/v1/phone-login'`, `kotechToken = '/functions/v1/kotech-token'`, …) |
| `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | classes | same | `static const String` paths per host |
| `StringConstants.appAuthToken` | static const | `lib/core/utils/string_constants.dart` | `static const String appAuthToken = 'auth.access_token';` |
| `APIResponse`, `SuccessResponse`, `ErrorResponse`, `InvalidResponse` | classes | `lib/core/app/api/api_response.dart` | `SuccessResponse({required successMessage, required statusCode, required rawData, required data})`, `ErrorResponse({required errorMessage, required errorCode, rawData, required data})` |
| `AppException` and subclasses | classes | `lib/core/app/exceptions/app_exceptions.dart` | `AppException(this.message, this.prefix)`; `InternetException([String? message])`, `RequestTimeoutException`, `ServerException`, `InvalidUrlException`, `FetchDataException`, `UnAuthorizedException`, `AuthException(this.message)` |
| `ServerException`, `ConnectionException` | classes | `lib/core/app/exceptions/api_exceptions.dart` | `const ServerException({required this.code, required this.status, this.detail}); const ConnectionException([this.message]);` |
| `PrefUtils` | class | `pref_utils.dart` | `PrefUtils()` (kicks off `init()`), `Future<void> init()`, `setString({required key, required value})`, `getString({required key})`, `setJsonString({required key, required jsonValue})`, `getJsonString({required key})`, `remove({required key})`, `setBool`, `getBool`, `getAllData`, `clearAll`, `clearPreferencesData` |
| `SecureStorage` | interface | `secure_storage/secure_storage.dart` | `Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key);` |
| `DeviceSecureStorage` | class | `device_secure_storage.dart` | `DeviceSecureStorage({FlutterSecureStorage storage = _storage}); static const String installedKey = 'secure_storage.installed'; static Future<void> init({PrefUtils? prefs, FlutterSecureStorage storage = _storage}); @visibleForTesting static void resetMemory();` |
| `SecureSessionStorage` | class | `secure_session_storage.dart` | `SecureSessionStorage({required SecureStorage storage, required PrefUtils prefs, required String supabaseUrl}) : key = keyFor(supabaseUrl); static String keyFor(String supabaseUrl) => 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';` |
| `KoTokenService`, `KoTokenServiceImpl` | interface, class | `kotech/ko_token_service.dart` | `Future<String?> token({bool refresh = false}); void invalidate();` / `KoTokenServiceImpl({required Networking networking, required String anonKey, required KoEnv env, DateTime Function() now = DateTime.now}); static const Duration expirySkew = Duration(minutes: 5); static const Duration fallbackLifetime = Duration(minutes: 30);` |
| `PaymentGateway` | interface | `payments/payment_gateway.dart` | `Future<GatewayPayment> collect(GatewayCheckout checkout);` |
| `GatewayCheckout`, `GatewayPayment`, `GatewayPaymentError`, `GatewayPaymentException` | classes/enum | same | `const GatewayCheckout({required keyId, required orderId, required amountPaise, required merchantName, required description, contact, email})`; `const GatewayPayment({required paymentId, required orderId, signature = ''})`; `enum GatewayPaymentError { cancelled, upiTimeout, network, insufficientFunds, incorrectOtp, timeout, invalidVpa, cardDeclined, cardExpired, invalidCard, bankDown, limitExceeded, notConfigured, unknown; bool get isCancellation }`; `const GatewayPaymentException(this.error, {this.detail})` |
| `RazorpayPaymentGateway` | class | `razorpay_payment_gateway.dart` | `RazorpayPaymentGateway({Razorpay Function()? newSdk}); static const String themeColor = '#225542'; static Map<String, dynamic> optionsFor(GatewayCheckout checkout);` + top-level `GatewayPaymentException classifyRazorpayError({int? code, String? message, Map<dynamic, dynamic>? error})` |
| `AppTheme` | class | `theme/app_theme.dart` | `abstract final class AppTheme { static ThemeData get light; static ThemeData get dark; static const double fontSizeFactor = 0.88; static const String displayFontFamily = 'Marcellus'; }` |
| `AppColors` | class | `theme/app_colors.dart` | `abstract final class AppColors { static const Color primary = Color(0xFF225542); ... }` |
| `AppTones` | ThemeExtension | `theme/app_tones.dart` | `const AppTones({required success, required info, required warning, rating = AppColors.star}); static const AppTones light; static const AppTones dark; static AppTones of(BuildContext context)` |
| `UseCase`, `NoParams` | interface, class | `lib/core/usecases/usecase.dart` | `abstract interface class UseCase<T, Params> { Future<Either<Failure, T>> call(Params params); }` / `class NoParams extends Equatable { const NoParams(); }` |
| `Failure`, `NetworkFailure`, `ServerFailure`, `CacheMissFailure` | classes | `lib/core/app/failure.dart` | `Failure({required this.message, this.code});` `ServerFailure({required this.errorCode, super.message = 'Something went wrong.', super.code})` |
| `AuthBloc` | bloc | `features/auth/presentation/bloc/auth_bloc.dart` | `AuthBloc({required RestoreSession restoreSession, required SignOut signOut, AnalyticsService? analytics})`; handles `AuthStatusRequested`, `AuthLoggedIn`, `AuthLogoutRequested`, `AuthProfileChanged` |
| `AuthEvent` family | events | `auth_event.dart` | `abstract class AuthEvent {}`, `AuthStatusRequested`, `AuthLoggedIn(this.user)`, `AuthLogoutRequested`, `AuthProfileChanged({this.fullName, this.email})` |
| `AuthState` family | states | `auth_state.dart` | `abstract class AuthState extends Equatable { const AuthState(); props => []; }`, `AuthInitial()`, `AuthLoading()`, `Authenticated(this.user)` (props `[user]`), `Unauthenticated()`, `AuthFailure(this.message)` |
| `AuthUser` | entity | `features/auth/domain/entities/auth_user.dart` | `const AuthUser({required id, required phone, fullName, email, required roles, required activeRole, required userKey}); AuthUser withProfile({String? fullName, String? email})` |
| `ThemeBloc`, `ThemeModeToggled`, `ThemeModeChanged`, `ThemeState` | bloc/events/state | `features/settings/presentation/bloc/` | `ThemeBloc() : super(const ThemeState())`; `ThemeModeToggled({required this.isDark})`; `ThemeModeChanged(this.mode)`; `const ThemeState({this.mode = ThemeMode.system}); ThemeState copyWith({ThemeMode? mode})` |
| `CartBloc` | bloc | `features/cart/presentation/bloc/cart_bloc.dart` | `CartBloc({required LoadCart loadCart, required SaveCartItem saveCartItem, required SaveForLater saveForLater, required MoveToCart moveToCart, required RemoveSaved removeSaved, required RemoveCartItems removeCartItems, required SyncCart syncCart, required PushCart pushCart, required CheckCartStock checkCartStock, AnalyticsService? analytics})` |
| `CartEvent` family | events | `cart_event.dart` | `CartStarted`, `CartSignedIn(this.userId)`, `CartSyncFinished(this.userId, this.result, {required this.syncId})`, `CartSignedOut`, `CartItemAdded(this.item, {this.maxQuantity})`, `CartItemIncremented(this.variantId, {this.maxQuantity})`, `CartItemDecremented`, `CartItemRemoved`, `CartItemsRemoved(this.variantIds)`, `CartItemSavedForLater`, `SavedItemMovedToCart`, `SavedItemRemoved`, `CartStockChecked(this.products)`, `CartStockChangesSeen` |
| `CartState`, `CartStatus` | state, enum | `cart_state.dart` | `enum CartStatus { initial, loading, ready, failure }`; `const CartState({status = initial, items = const [], savedForLater = const [], failure, stockLimits = const {}, stockChanges})`; getters `totalQuantity`, `subtotal`, `itemSavings`, `isEmpty`, `savedCount`, `thumbnails`; `copyWith` with `Failure? Function()? failure`, `CartStockChanges? Function()? stockChanges` |
| `WishlistBloc` | bloc | `features/wishlist/presentation/bloc/wishlist_bloc.dart` | `WishlistBloc({required LoadWishlist loadWishlist, required SyncWishlist syncWishlist, required PushWishlist pushWishlist, required AddToWishlist addToWishlist, required RemoveFromWishlist removeFromWishlist, required GetCatalog getCatalog, required GetCachedCatalog getCachedCatalog, AnalyticsService? analytics})` |
| `WishlistEvent` family | events | `wishlist_event.dart` | `WishlistStarted(this.userId)`, `WishlistRefreshed`, `WishlistToggled(this.productId)`, `WishlistCleared` |
| `WishlistState`, `WishlistStatus` | state, enum | `wishlist_state.dart` | non-const constructor computing `ids` and `products`; fields `status, items, ids, pendingIds, catalog, products, isStale, isRefreshing, failure, toggleFailure`; `count`, `contains(id)`, `isBusy` |
| `LocationBloc` | bloc | `features/location/presentation/bloc/location_bloc.dart` | `LocationBloc({required GetSelectedPlace getSelectedPlace, required GetCurrentPlace getCurrentPlace, required SelectPlace selectPlace, required ClearSelectedPlace clearSelectedPlace})` |
| `LocationEvent` family, `LocationState` | events, state | `location_event.dart`, `location_state.dart` | `LocationStarted`, `LocationPlaceSelected(this.place)`, `LocationCleared`; `const LocationState({this.place, this.isDetecting = false}); copyWith({Place? Function()? place, bool? isDetecting})` |
| `MaliCoinsBloc` | bloc | `features/mali_coins/presentation/bloc/mali_coins_bloc.dart` | `MaliCoinsBloc({required ClaimWelcomeCoins claimWelcome, required GetCachedCoinBalance getCachedBalance})` |
| `MaliCoinsEvent` family, `MaliCoinsState` | events, state | `mali_coins_event.dart`, `mali_coins_state.dart` | `MaliCoinsStarted`, `MaliCoinsBalanceChanged(this.balance)`, `MaliCoinsSpent(this.coins)`, `MaliCoinsCleared`; `const MaliCoinsState({this.balance}); copyWith({int? Function()? balance})` |
| `ProfileBloc` | bloc | `features/profile/presentation/bloc/profile_bloc.dart` | `ProfileBloc({required GetProfile getProfile, required LoadAvatar loadAvatar, required PickAvatar pickAvatar})` |
| `ProfileEvent` family, `ProfileState` | events, state | `profile_event.dart`, `profile_state.dart` | `ProfileStarted({required this.userId, required this.userKey})`, `ProfileSaved(this.profile)`, `ProfileAvatarPickRequested`, `ProfileCleared`; `const ProfileState({userId, profile, avatar, isPickingAvatar = false, avatarFailure})` with getter-style clearable `copyWith` |
| `CouponBloc` | bloc | `features/coupons/presentation/bloc/coupon_bloc.dart` | `CouponBloc({required CheckCoupon checkCoupon, AnalyticsService? analytics, DateTime Function() now = DateTime.now})` |
| `CouponEvent` family, `CouponState` | events, state | `coupon_event.dart`, `coupon_state.dart` | `CouponApplied(this.code)`, `CouponRemoved`, `CouponCartChanged(this.subtotal)`, `CouponDroppedByServer(this.warning)`, `CouponCleared`, `CouponFailureDismissed`; `const CouponState({applied, isApplying = false, failure, serverWarning, subtotal = 0})` |
| `LoginBloc` | bloc | `features/auth/presentation/login/bloc/login_bloc.dart` | `LoginBloc({required SendOtp sendOtp, required VerifyOtp verifyOtp, AnalyticsService? analytics})` |
| `HomeBloc` | bloc | `features/home/presentation/home/bloc/home_bloc.dart` | `HomeBloc({required GetHomeSections getHomeSections, required GetCachedHomeSections getCachedHomeSections, required GetAppState getAppState, required GetSoldCounts getSoldCounts, required GetCachedSoldCounts getCachedSoldCounts, required GetLowStockThresholds getLowStockThresholds, required GetCachedLowStockThresholds getCachedLowStockThresholds, String imageBaseUrl = ''})` |
| `SplashPage` | page | `features/auth/presentation/splash/pages/splash_page.dart` | `const SplashPage({super.key}); static const Duration displayDuration = Duration(milliseconds: 2600);` |
| `AppShellScaffold` | widget | `features/home/presentation/widgets/app_shell_scaffold.dart` | `const AppShellScaffold({required this.navigationShell, this.onTabSelected, super.key}); final StatefulNavigationShell navigationShell; final ValueChanged<int>? onTabSelected;` |
| `AuthRepositoryImpl` | repository | `features/auth/data/repositories/auth_repository_impl.dart` | `AuthRepositoryImpl({required AuthRemoteDataSource remote, required AuthSessionDataSource session, required AuthLocalDataSource local})`; `Future<void> dispose() => _refreshSubscription.cancel();` |
| `AuthLocalDataSourceImpl` | data source | `features/auth/data/datasources/auth_local_data_source.dart` | `AuthLocalDataSourceImpl(this._secure, this._prefs, this._cache);` (`SecureStorage`, `PrefUtils`, `LocalCache`); `static const String accessTokenKey = StringConstants.appAuthToken; refreshTokenKey = 'auth.refresh_token'; userIdKey = 'auth.user_id';` |
| `AuthSessionDataSourceImpl` | data source | `auth_session_data_source.dart` | `const AuthSessionDataSourceImpl(this._client);` (`supabase.SupabaseClient`) |
| `PlaceCodOrder`, `RegisterOnlineOrder` | use cases | `features/checkout/domain/usecases/` | `const PlaceCodOrder(this._checkout, this._catalog);` (`CheckoutRepository`, `CatalogRepository`, positional) |
| `CheckDelivery` | use case | `features/delivery/domain/usecases/check_delivery.dart` | `const CheckDelivery({required DeliveryRepository delivery, required ChargeRulesRepository chargeRules})` |
| `registerSignedInApp` | test helper | `test/helpers/signed_in_app.dart` | `void registerSignedInApp({FakeAuthRepository? auth, FakeMaliCoinsRepository? coins, FakeWishlistRepository? wishlist, FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account, FakeKoEngagementService? engagement})` |
| `launchSignedInApp`, `openAccountTab`, `scrollAccountTo` | test helpers | same | `Future<void> launchSignedInApp(WidgetTester tester)` etc. |
| `FakeKoEngagementService`, `registerFakeEngagement` | test helper | `test/helpers/fake_ko_engagement_service.dart` | `FakeKoEngagementService registerFakeEngagement()` registers `KoEngagementService` and `AnalyticsService` (as `KoAnalyticsService(fake)`) |
| `registerAccountFakes` | test helper | `test/helpers/fake_account_repository.dart` | `void registerAccountFakes({FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account})` |

---

## 3. Patterns

### 3.1 `main` does nothing but call `bootstrap`

```dart
import 'app/bootstrap.dart';

void main() {
  bootstrap();
}
```

Rule: no `runApp`, no `WidgetsFlutterBinding`, no `await` in `main`. Everything is in `bootstrap()` so tests can pump `App` without the startup sequence.

### 3.2 The startup sequence (`bootstrap.dart`, complete)

```dart
import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/di/injection_container.dart';
import '../core/router/app_router.dart';
import '../core/services/analytics/analytics_service.dart';
import '../core/services/katyayani_core/ko_engagement_service.dart';
import '../core/services/local_cache/hive_local_cache.dart';
import '../core/services/local_notifications/local_notification_service.dart';
import '../core/services/pref_utils.dart';
import '../core/services/secure_storage/device_secure_storage.dart';
import '../core/services/secure_storage/secure_session_storage.dart';
import 'app.dart';

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
  unawaited(_initEngagement());
  // iOS only: the App Tracking Transparency prompt, whose answer decides
  // whether Meta may collect the advertising id.
  unawaited(sl<AnalyticsService>().requestTrackingPermission());

  runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router));
}

/// Starts the notification channel, then Katyayani Core, without holding up
/// the first frame. The channel comes first: both set up the same
/// notifications plugin, and the SDK's tap handler must be the one kept.
/// Neither ever throws.
Future<void> _initEngagement() async {
  await sl<LocalNotificationService>().init();
  await sl<KoEngagementService>().init();
}

/// Connects the app to Firebase on Android and iOS.
///
/// The settings come from the platform files downloaded from the Firebase
/// console: `android/app/google-services.json` and
/// `ios/Runner/GoogleService-Info.plist`. Firebase is never required: when
/// a file is missing (or on any other platform) this logs and the app runs
/// without it.
Future<void> _initFirebase() async {
  final supported =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!supported) return;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    log('[firebase] not started: $e');
    if (kDebugMode) debugPrint('[firebase] not started: $e');
  }
}
```

Exact order, purpose and optionality of each step:

| # | step | purpose | optional? |
|---|---|---|---|
| 1 | `WidgetsFlutterBinding.ensureInitialized()` | platform channels before any plugin | required |
| 2 | `await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` | portrait-only app | per-app choice (AGENTS §11 says portrait-only, also set in manifest/plist) |
| 3 | `await Env.load()` | `.env` into `dotenv`; every `Env` getter throws `StateError` if missing | required (everything below reads `Env`) |
| 4 | `await _initFirebase()` | `Firebase.initializeApp()` with no options (platform files); Android/iOS only; never throws, logs `[firebase] not started` | CONDITIONAL(Firebase). Must come before anything using GA4/FCM; `FirebaseAnalyticsDestination` checks `Firebase.apps.isEmpty` at call time |
| 5 | `await DeviceSecureStorage.init()` | on a fresh install (no `secure_storage.installed` pref flag) wipes the Keychain/Keystore store and the static memory mirror; never throws | CONDITIONAL(tokens). Must run before `Supabase.initialize` because the session lives in secure storage |
| 6 | `await Supabase.initialize(url:, anonKey:, authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage(storage: DeviceSecureStorage(), prefs: PrefUtils(), supabaseUrl:)))` | the one place Supabase is initialised; session persisted through `SecureStorage`; `SecureSessionStorage.initialize()` migrates a legacy prefs session | CONDITIONAL(Supabase). Note: `DeviceSecureStorage()` and `PrefUtils()` are constructed directly here (DI is not configured yet); both classes keep static state so the later `sl` instances see the same data |
| 7 | `await HiveLocalCache.init()` | `Hive.initFlutter()` then open every box in `CacheBoxes.all`; never throws; a box that fails is deleted and reopened, else left closed | CONDITIONAL(cache) |
| 8 | `configureDependencies()` | synchronous registration of everything in `sl` | required |
| 9 | `unawaited(_initEngagement())` | `LocalNotificationService.init()` then `KoEngagementService.init()`, in that order, off the critical path | CONDITIONAL(push/engagement) |
| 10 | `unawaited(sl<AnalyticsService>().requestTrackingPermission())` | iOS ATT prompt for Meta (1 s delay inside the destination) | CONDITIONAL(Meta) |
| 11 | `runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router))` | the router is built once with the analytics tracker; `App` takes a `GoRouter` so tests can pass `AppRouter().router` | required |

### 3.3 An optional subsystem is started by a private `_initX()` that never throws

`_initFirebase` above is the template: a platform guard (`!kIsWeb && (android || iOS)`), one `try { await Sdk.init(); } catch (e) { log('[tag] not started: $e'); if (kDebugMode) debugPrint(...); }`, and no return value the caller depends on. The same shape appears inside `KoEngagementServiceImpl._start()` (`[kc] not started`), `LocalNotificationServiceImpl.init()` (`[notifications] channel setup failed…`), `DeviceSecureStorage.init()` (`[secure_storage] init failed`) and `HiveLocalCache.init()` (swallows and returns). Rule: an optional subsystem is logged with a bracketed tag and the app runs without it; nothing in `bootstrap` awaits something that may hang after `configureDependencies()`.

### 3.4 The service locator and `configureDependencies()` (complete)

```dart
/// The app's service locator.
final GetIt sl = GetIt.instance;

/// Registers every dependency. Call once at startup, after `Env.load()`,
/// `Supabase.initialize()` and `HiveLocalCache.init()`.
void configureDependencies() {
  _registerCore();
  _registerAuthData();
  registerAuthFeature();
  _registerCatalogData();
  registerCatalogFeature();
  _registerAppConfigData();
  registerAppConfigFeature();
  registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl);
  registerCategoriesFeature();
  _registerCartData();
  registerCartFeature();
  _registerWishlistData();
  registerWishlistFeature();
  registerSettingsFeature();
  registerGardenFeature();
  _registerAddressData();
  registerAddressFeature();
  _registerLocationData();
  registerLocationFeature();
  _registerMaliCoinsData();
  registerMaliCoinsFeature();
  _registerCouponsData();
  registerCouponsFeature();
  _registerOrdersData();
  registerOrdersFeature();
  _registerCheckoutData();
  registerCheckoutFeature();
  _registerInvoiceData();
  registerInvoiceFeature();
  _registerGstinData();
  registerGstinFeature();
  _registerNotificationsData();
  registerNotificationsFeature();
  _registerDeliveryData();
  registerDeliveryFeature();
  _registerProductData();
  registerProductFeature();
  _registerProfileData();
  registerProfileFeature();
  _registerAccountData();
  registerAccountFeature();
  _registerSupportData();
  registerSupportFeature();
}
```

Naming convention and call order:

- `_registerCore()` first, always.
- Per feature, **two** functions, called back to back: a **private** `_register<Feature>Data()` (data sources + repository, registered by abstract type, reads `Env`) and a **public** `register<Feature>Feature()` (use cases + blocs, depends only on repositories and other features' use cases, never reads `Env` except through a parameter). The public one is public so tests can register a fake repository and call it.
- Features with no data layer have only the public function (`registerHomeFeature`, `registerCategoriesFeature`, `registerSettingsFeature`, `registerGardenFeature`).
- Order is data-before-feature within a feature, and features whose blocs use another feature's use cases come after that feature. The dependency is written in the function's doc comment ("call [registerCatalogFeature] first"). Resolution is lazy, so the order matters for readability and for tests, not for GetIt.
- `configureDependencies` is `void` and synchronous: nothing in DI is awaited.
- The one `Env` read at `configureDependencies()` time (eager) is `registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl)`; every other `Env.*` is inside a factory lambda (lazy, read on first `sl<T>()`).

### 3.5 `_registerCore()`: core services by abstract type, `registerLazySingleton`, `Env` read only here

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
    ..registerLazySingleton<PaymentGateway>(RazorpayPaymentGateway.new)
    ..registerLazySingleton<LocalNotificationService>(
      LocalNotificationServiceImpl.new,
    )
    ..registerLazySingleton<KoEngagementService>(
      () =>
          KoEngagementServiceImpl(siteId: Env.kcSiteId, apiBase: Env.kcApiUrl),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => MultiDestinationAnalyticsService(
        core: KoAnalyticsService(sl()),
        destinations: _analyticsDestinations(),
      ),
    );
}

/// Google Analytics 4 and Meta, on the phones only. Meta joins only with its
/// app id and client token set: its native SDK fails without them.
List<AnalyticsDestination> _analyticsDestinations() {
  final onPhone =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!onPhone) return const [];
  return [
    FirebaseAnalyticsDestination(),
    if (Env.fbAppId != null && Env.fbClientToken != null)
      MetaAnalyticsDestination(),
  ];
}
```

Rules: the registered type is always the **abstract** one (`<SecureStorage>`, `<Networking>`, `<LocalCache>`, …) and the value is the implementation; a zero-argument implementation is passed as a constructor tear-off (`DeviceSecureStorage.new`); `sl()` inside a lambda is resolved by the parameter's type (inference, no type argument); `Env` is read inside the lambda. Classification per line: `SecureStorage`, `Networking`, `PrefUtils` ALWAYS/CONDITIONAL(tokens); `LocalCache` CONDITIONAL(cache); `SupabaseClient` CONDITIONAL(Supabase); `KoTokenService`, `KoEngagementService`, `KoAnalyticsService` MYMALI-SPECIFIC; `PaymentGateway` CONDITIONAL(payments); `LocalNotificationService` CONDITIONAL(push); `AnalyticsService` CONDITIONAL(analytics).

### 3.6 `_register<Feature>Data()`: data sources and repository by abstract type, optional `dispose:`

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
```

Rules: remote data sources take `networking: sl()` plus the keys they need (`anonKey: Env.supabaseAnonKey`, `medusaPublishableKey: Env.medusaApiKey`, `publishableKey:`, `mktpId: Env.mktpId`), never `Env` inside the class; local data sources take `sl()` positionally (`LocalCache` or `PrefUtils`); the repository takes named `remote:`/`local:` (or `session:`, `device:`, `avatars:`, `picker:`, `koOrders:`, `attempts:`, `medusaCustomers:`, `gateway:`, `stockship:`, `refOrders:`, `appInfo:`). A repository that holds a subscription gets `dispose:` so `sl.reset()` (tests) closes it. The cascade `sl..registerLazySingleton(...)..registerLazySingleton(...)` is the house style; a single registration uses `sl.registerLazySingleton(...)`.

The canonical two-data-source cache-first block (AGENTS §20 step 8), as the code has it:

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
```

### 3.7 `register<Feature>Feature()`: use cases as lazy singletons, blocs as factories, doc comment states the contract

```dart
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

Rules: use cases are registered **without** a type argument (GetIt infers the concrete class, e.g. `SendOtp`); a bloc's constructor takes use cases by named parameter and each is `sl()`; `analytics: sl()` passes the `AnalyticsService` to blocs that report events; the doc comment names the repository(ies) the block depends on and, when the bloc uses another feature's use cases, which `register<X>Feature()` must be called first. Use cases with two dependencies are written positionally or named exactly as their constructor: `PlaceCodOrder(sl(), sl())`, `RegisterOnlineOrder(sl(), sl())`, `CheckDelivery(delivery: sl(), chargeRules: sl())`.

### 3.8 A feature registration that takes a parameter so tests avoid `Env`

```dart
/// Home blocs. They depend on the catalog and app-config use cases, so
/// call [registerCatalogFeature] and [registerAppConfigFeature] first.
/// [imageBaseUrl] is the origin that relative banner image paths are joined
/// to; tests leave it out.
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

Called as `registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl)` in production and `registerHomeFeature()` in tests.

### 3.9 Zero-dependency blocs and zero-argument services use constructor tear-offs

```dart
/// App-wide settings blocs (theme mode). No data dependencies yet.
void registerSettingsFeature() {
  sl.registerFactory(ThemeBloc.new);
}

/// The Garden tab's bloc. No data dependencies yet.
void registerGardenFeature() {
  sl.registerFactory(GardenBloc.new);
}
```

Also `registerLazySingleton<DeviceLocationDataSource>(DeviceLocationDataSourceImpl.new)`, `<AvatarPickerDataSource>(AvatarPickerDataSourceImpl.new)`, `<AppInfoDataSource>(AppInfoDataSourceImpl.new)`: the implementation's constructor has only optional parameters (an injectable SDK handle for tests, e.g. `AppInfoDataSourceImpl([Future<PackageInfo> Function()? read])`).

### 3.10 A registration block with a second statement when one bloc belongs to another page

```dart
void registerCheckoutFeature() {
  sl
    ..registerLazySingleton(() => GetCheckoutQuote(sl()))
    ..registerLazySingleton(() => PlaceCodOrder(sl(), sl()))
    ..registerLazySingleton(() => RegisterOnlineOrder(sl(), sl()))
    ..registerLazySingleton(() => CollectPayment(sl()))
    ..registerLazySingleton(() => RecordPlacedOrder(sl()))
    ..registerFactory(
      () => ReviewPayBloc(
        getCheckoutQuote: sl(),
        getChargeRules: sl(),
        getCachedChargeRules: sl(),
        getCoinRules: sl(),
        getActiveCoupons: sl(),
        getAddresses: sl(),
        getCachedAddresses: sl(),
        placeCodOrder: sl(),
        registerOnlineOrder: sl(),
        collectPayment: sl(),
      ),
    );
  // Thank You asks the warehouse for its copy of the order, so call
  // [registerOrdersFeature] first.
  sl.registerFactory(
    () => OrderPlacedBloc(
      getWarehouseOrder: sl(),
      findOrderPlacedAfter: sl(),
      getRefOrder: sl(),
      recordPlacedOrder: sl(),
      getCachedCatalog: sl(),
      getCatalog: sl(),
    ),
  );
}
```

### 3.11 Every registration in the container (resolved)

LS = `registerLazySingleton`, F = `registerFactory`. "→" shows what each `sl()` resolves to (verified against the constructors).

**`_registerCore()`**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `SecureStorage` | LS | `DeviceSecureStorage.new` |
| `Networking` | LS | `NetworkingService(secureStorage: sl() → SecureStorage)` |
| `PrefUtils` | LS | `PrefUtils.new` |
| `LocalCache` | LS | `HiveLocalCache.new` |
| `SupabaseClient` | LS | `Supabase.instance.client` |
| `KoTokenService` | LS | `KoTokenServiceImpl(networking: sl() → Networking, anonKey: Env.supabaseAnonKey, env: Env.koEnv)` |
| `PaymentGateway` | LS | `RazorpayPaymentGateway.new` |
| `LocalNotificationService` | LS | `LocalNotificationServiceImpl.new` |
| `KoEngagementService` | LS | `KoEngagementServiceImpl(siteId: Env.kcSiteId, apiBase: Env.kcApiUrl)` |
| `AnalyticsService` | LS | `MultiDestinationAnalyticsService(core: KoAnalyticsService(sl() → KoEngagementService), destinations: _analyticsDestinations())` |

**auth** (`_registerAuthData` / `registerAuthFeature`)

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `AuthRemoteDataSource` | LS | `AuthRemoteDataSourceImpl(networking: sl() → Networking, anonKey: Env.supabaseAnonKey)` |
| `AuthSessionDataSource` | LS | `AuthSessionDataSourceImpl(sl() → SupabaseClient)` |
| `AuthLocalDataSource` | LS | `AuthLocalDataSourceImpl(sl() → SecureStorage, sl() → PrefUtils, sl() → LocalCache)` (positional, this order) |
| `AuthRepository` | LS | `AuthRepositoryImpl(remote: sl(), session: sl(), local: sl())`, `dispose: (repository) => (repository as AuthRepositoryImpl).dispose()` |
| `SendOtp`, `VerifyOtp`, `RestoreSession`, `SignOut` | LS | each `(sl() → AuthRepository)` |
| `AuthBloc` | F | `AuthBloc(restoreSession: sl(), signOut: sl(), analytics: sl() → AnalyticsService)` |
| `LoginBloc` | F | `LoginBloc(sendOtp: sl(), verifyOtp: sl(), analytics: sl())` |

**catalog**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `CatalogRemoteDataSource` | LS | `CatalogRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey, medusaPublishableKey: Env.medusaApiKey)` |
| `CatalogLocalDataSource` | LS | `CatalogLocalDataSourceImpl(sl() → LocalCache)` |
| `CatalogRepository` | LS | `CatalogRepositoryImpl(remote: sl(), local: sl())` |
| `GetCatalog`, `GetCachedCatalog`, `GetHomeSections`, `GetCachedHomeSections`, `GetSoldCounts`, `GetCachedSoldCounts`, `GetLowStockThresholds`, `GetCachedLowStockThresholds` | LS | each `(sl() → CatalogRepository)` |

**app_config**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `AppConfigRemoteDataSource` | LS | `AppConfigRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `AppConfigRepository` | LS | `AppConfigRepositoryImpl(remote: sl())` |
| `GetAppState` | LS | `GetAppState(sl() → AppConfigRepository)` (registered with `sl.registerLazySingleton(...)`, single statement) |

**home / categories** (no data layer)

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `HomeBloc` | F | `HomeBloc(getHomeSections:, getCachedHomeSections:, getAppState:, getSoldCounts:, getCachedSoldCounts:, getLowStockThresholds:, getCachedLowStockThresholds:, imageBaseUrl: imageBaseUrl)` |
| `CategoriesBloc` | F | `CategoriesBloc(getCatalog: sl(), getCachedCatalog: sl(), getSoldCounts: sl(), getCachedSoldCounts: sl())` |

**cart** (two repositories in one block)

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `CartLocalDataSource` | LS | `CartLocalDataSourceImpl(sl() → PrefUtils)` |
| `CartRemoteDataSource` | LS | `CartRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `CartRepository` | LS | `CartRepositoryImpl(local: sl(), remote: sl())` |
| `ChargeRulesRemoteDataSource` | LS | `ChargeRulesRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `ChargeRulesLocalDataSource` | LS | `ChargeRulesLocalDataSourceImpl(sl() → LocalCache)` |
| `ChargeRulesRepository` | LS | `ChargeRulesRepositoryImpl(remote: sl(), local: sl())` |
| `LoadCart`, `SaveCartItem`, `SaveForLater`, `MoveToCart`, `RemoveSaved`, `RemoveCartItems`, `SyncCart`, `PushCart`, `CheckCartStock` | LS | each `(sl())` on the cart repository |
| `GetChargeRules`, `GetCachedChargeRules` | LS | each `(sl())` on the charge-rules repository |
| `CartBloc` | F | `CartBloc(loadCart:, saveCartItem:, saveForLater:, moveToCart:, removeSaved:, removeCartItems:, syncCart:, pushCart:, checkCartStock:, analytics: sl())` |
| `CartPageBloc` | F | `CartPageBloc(getCatalog: sl(), getCachedCatalog: sl(), getChargeRules: sl(), getCachedChargeRules: sl())` |

**wishlist**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `WishlistRemoteDataSource` | LS | `WishlistRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `WishlistLocalDataSource` | LS | `WishlistLocalDataSourceImpl(sl() → PrefUtils)` |
| `WishlistRepository` | LS | `WishlistRepositoryImpl(remote: sl(), local: sl())` |
| `LoadWishlist`, `SyncWishlist`, `PushWishlist`, `AddToWishlist`, `RemoveFromWishlist` | LS | each `(sl())` |
| `WishlistBloc` | F | `WishlistBloc(loadWishlist:, syncWishlist:, pushWishlist:, addToWishlist:, removeFromWishlist:, getCatalog:, getCachedCatalog:, analytics: sl())` |

**settings / garden**: `ThemeBloc` F (`ThemeBloc.new`), `GardenBloc` F (`GardenBloc.new`).

**address**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `AddressRemoteDataSource` | LS | `AddressRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `AddressLocalDataSource` | LS | `AddressLocalDataSourceImpl(sl() → LocalCache)` |
| `AddressRepository` | LS | `AddressRepositoryImpl(remote: sl(), local: sl())` |
| `GetAddresses`, `GetCachedAddresses`, `SaveAddress`, `RemoveAddress` | LS | each `(sl())` |
| `SavedAddressesBloc` | F | `SavedAddressesBloc(getAddresses:, getCachedAddresses:, saveAddress:, removeAddress:)` |
| `AddressFormBloc` | F | `AddressFormBloc(saveAddress: sl(), getCurrentPlace: sl())` (cross-feature: `GetCurrentPlace` from location) |

**location**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `DeviceLocationDataSource` | LS | `DeviceLocationDataSourceImpl.new` |
| `LocationLocalDataSource` | LS | `LocationLocalDataSourceImpl(sl() → PrefUtils)` |
| `LocationRepository` | LS | `LocationRepositoryImpl(device: sl(), local: sl())` |
| `SearchPlace`, `GetCurrentPlace`, `GetSelectedPlace`, `SelectPlace`, `ClearSelectedPlace` | LS | each `(sl())` |
| `LocationBloc` | F | `LocationBloc(getSelectedPlace:, getCurrentPlace:, selectPlace:, clearSelectedPlace:)` |
| `SelectLocationBloc` | F | `SelectLocationBloc(searchPlace:, getCurrentPlace:, getAddresses:, getCachedAddresses:)` (cross-feature: address) |

**mali_coins**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `MaliCoinsRemoteDataSource` | LS | `MaliCoinsRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `MaliCoinsLocalDataSource` | LS | `MaliCoinsLocalDataSourceImpl(sl() → LocalCache)` |
| `MaliCoinsRepository` | LS | `MaliCoinsRepositoryImpl(remote: sl(), local: sl())` |
| `ClaimWelcomeCoins`, `GetCachedCoinBalance`, `GetCoinBalance`, `GetCoinRules` | LS | each `(sl())` |
| `MaliCoinsBloc` | F | `MaliCoinsBloc(claimWelcome: sl(), getCachedBalance: sl())` |
| `CoinsPageBloc` | F | `CoinsPageBloc(getRules: sl(), getBalance: sl())` |

**coupons**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `CouponRemoteDataSource` | LS | `CouponRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `CouponLocalDataSource` | LS | `CouponLocalDataSourceImpl(sl() → LocalCache)` |
| `CouponRepository` | LS | `CouponRepositoryImpl(remote: sl(), local: sl())` |
| `GetActiveCoupons`, `CheckCoupon` | LS | each `(sl())` |
| `CouponBloc` | F | `CouponBloc(checkCoupon: sl(), analytics: sl())` |
| `ApplyCouponBloc` | F | `ApplyCouponBloc(getActiveCoupons: sl())` |

**orders**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `StockshipRemoteDataSource` | LS | `StockshipRemoteDataSourceImpl(networking: sl(), tokens: sl() → KoTokenService, mktpId: Env.mktpId)` |
| `RefOrderRemoteDataSource` | LS | `RefOrderRemoteDataSourceImpl(networking: sl(), tokens: sl() → KoTokenService)` |
| `OrdersRepository` | LS | `OrdersRepositoryImpl(stockship: sl(), refOrders: sl())` |
| `GetWarehouseOrder`, `FindOrderPlacedAfter`, `GetRefOrder`, `GetMyOrders`, `GetOrderProducts`, `BuyAgainOrder` | LS | each `(sl())` |
| `MyOrdersBloc` | F | `MyOrdersBloc(getMyOrders:, getOrderProducts:, buyAgainOrder:)` |
| `OrderDetailsBloc` | F | `OrderDetailsBloc(getWarehouseOrder:, getOrderProducts:, buyAgainOrder:)` |

**checkout**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `CheckoutRemoteDataSource` | LS | `CheckoutRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `KoOrderRemoteDataSource` | LS | `KoOrderRemoteDataSourceImpl(sl() → Networking, tokens: sl() → KoTokenService)` (positional + named) |
| `OrderAttemptLocalDataSource` | LS | `OrderAttemptLocalDataSourceImpl(sl() → PrefUtils)` |
| `MedusaCustomerDataSource` | LS | `MedusaCustomerDataSourceImpl(networking: sl(), publishableKey: Env.medusaApiKey)` |
| `CheckoutRepository` | LS | `CheckoutRepositoryImpl(remote: sl(), koOrders: sl(), attempts: sl(), medusaCustomers: sl(), gateway: sl() → PaymentGateway, razorpayKeyId: Env.razorpayKeyId, useAppKey: Env.razorpayMode == RazorpayMode.test)` |
| `GetCheckoutQuote`, `CollectPayment`, `RecordPlacedOrder` | LS | each `(sl() → CheckoutRepository)` |
| `PlaceCodOrder`, `RegisterOnlineOrder` | LS | `(sl() → CheckoutRepository, sl() → CatalogRepository)` positional |
| `ReviewPayBloc` | F | 10 named use cases (see 3.10) |
| `OrderPlacedBloc` | F | `OrderPlacedBloc(getWarehouseOrder:, findOrderPlacedAfter:, getRefOrder:, recordPlacedOrder:, getCachedCatalog:, getCatalog:)` |

**invoice**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `SellerRemoteDataSource` | LS | `SellerRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `SellerLocalDataSource` | LS | `SellerLocalDataSourceImpl(sl() → LocalCache)` |
| `SellerRepository` | LS | `SellerRepositoryImpl(remote: sl(), local: sl())` |
| `GetSellerIdentity`, `GetCachedSellerIdentity` | LS | each `(sl())` |
| `InvoiceBloc` | F | `InvoiceBloc(getCachedSeller: sl(), getSeller: sl())` |

**gstin**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `GstinRemoteDataSource` | LS | `GstinRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `GstinRepository` | LS | `GstinRepositoryImpl(remote: sl())` |
| `VerifyGstin`, `GetSavedGstins` | LS | each `(sl())` |
| `GstinSheetBloc` | F | `GstinSheetBloc(verifyGstin: sl())` |
| `GstClaimsBloc` | F | `GstClaimsBloc(getSavedGstins: sl())` |

**notifications**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `NotificationsRemoteDataSource` | LS | `NotificationsRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `NotificationsRepository` | LS | `NotificationsRepositoryImpl(remote: sl())` |
| `GetNotifications`, `MarkNotificationsRead` | LS | each `(sl())` |
| `NotificationsBloc` | F | `NotificationsBloc(getNotifications: sl(), markNotificationsRead: sl())` |

**delivery** (a use case with no bloc)

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `DeliveryRemoteDataSource` | LS | `DeliveryRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `DeliveryRepository` | LS | `DeliveryRepositoryImpl(remote: sl())` |
| `CheckDelivery` | LS | `CheckDelivery(delivery: sl() → DeliveryRepository, chargeRules: sl() → ChargeRulesRepository)` |

**product**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `ProductRemoteDataSource` | LS | `ProductRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey, medusaPublishableKey: Env.medusaApiKey)` |
| `ProductLocalDataSource` | LS | `ProductLocalDataSourceImpl(sl() → LocalCache)` |
| `ProductRepository` | LS | `ProductRepositoryImpl(remote: sl(), local: sl())` |
| `GetProductDetail`, `GetCachedProductDetail`, `GetProductReviews`, `SubmitReview`, `UpdateReview`, `DeleteReview` | LS | each `(sl())` |
| `ProductDetailBloc` | F | 14 named: `getProductDetail, getCachedProductDetail, getProductReviews, submitReview, updateReview, deleteReview, checkDelivery, getCatalog, getCachedCatalog, getSoldCounts, getCachedSoldCounts, getLowStockThresholds, getCachedLowStockThresholds, getAppState` |

**profile**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `ProfileRemoteDataSource` | LS | `ProfileRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `AvatarLocalDataSource` | LS | `AvatarLocalDataSourceImpl(sl() → PrefUtils)` |
| `AvatarPickerDataSource` | LS | `AvatarPickerDataSourceImpl.new` |
| `ProfileRepository` | LS | `ProfileRepositoryImpl(remote: sl(), avatars: sl(), picker: sl())` |
| `GetProfile`, `SaveProfile`, `LoadAvatar`, `PickAvatar` | LS | each `(sl())` |
| `ProfileBloc` | F | `ProfileBloc(getProfile: sl(), loadAvatar: sl(), pickAvatar: sl())` |
| `EditProfileBloc` | F | `EditProfileBloc(saveProfile: sl())` |

**referral**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `ReferralRemoteDataSource` | LS | `ReferralRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `ReferralRepository` | LS | `ReferralRepositoryImpl(remote: sl())` |
| `GetReferralSummary`, `ClaimReferralCode` | LS | each `(sl())` |
| `ReferralBloc` | F | `ReferralBloc(getSummary: sl(), claimCode: sl())` |

**account**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `AppInfoDataSource` | LS | `AppInfoDataSourceImpl.new` |
| `AccountRepository` | LS | `AccountRepositoryImpl(appInfo: sl())` |
| `GetAppVersion` | LS | `GetAppVersion(sl())` |
| `AccountBloc` | F | `AccountBloc(getAppVersion: sl(), getCoinRules: sl())` (cross-feature: mali_coins) |

**support**

| registered type | kind | implementation and injected dependencies |
|---|---|---|
| `SupportRemoteDataSource` | LS | `SupportRemoteDataSourceImpl(networking: sl(), anonKey: Env.supabaseAnonKey)` |
| `SupportLocalDataSource` | LS | `SupportLocalDataSourceImpl(sl() → LocalCache)` |
| `SupportRepository` | LS | `SupportRepositoryImpl(remote: sl(), local: sl())` |
| `GetSupportContent`, `GetCachedSupportContent` | LS | each `(sl())` |
| `HelpSupportBloc` | F | `HelpSupportBloc(getCachedSupportContent: sl(), getSupportContent: sl())` |

### 3.12 The `App` widget (complete)

```dart
class App extends StatelessWidget {
  const App({super.key, required this.router});

  final GoRouter router;

  /// Largest system font scale the app follows. Larger settings overflow
  /// fixed-height layouts such as the product tiles.
  static const double maxTextScaleFactor = 1.1;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ThemeBloc>(create: (_) => sl<ThemeBloc>()),
        // Eager, so the stored cart is loaded before any screen needs it.
        BlocProvider<CartBloc>(
          lazy: false,
          create: (_) => sl<CartBloc>()..add(CartStarted()),
        ),
        BlocProvider<WishlistBloc>(create: (_) => sl<WishlistBloc>()),
        BlocProvider<LocationBloc>(create: (_) => sl<LocationBloc>()),
        BlocProvider<MaliCoinsBloc>(create: (_) => sl<MaliCoinsBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
        // Eager, so it hears every cart change from the first load on.
        BlocProvider<CouponBloc>(lazy: false, create: (_) => sl<CouponBloc>()),
        RepositoryProvider<KoEngagementService>(
          create: (_) => sl<KoEngagementService>(),
        ),
        // Screens report what the shopper does through this; blocs get it by
        // constructor injection.
        RepositoryProvider<AnalyticsService>(
          create: (_) => sl<AnalyticsService>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          // The wishlist, the cart's server copy, the chosen location and
          // the coin balance belong to the signed-in user: load them when
          // one signs in (or a session is restored), and stop using them on
          // sign-out. A profile edit changes the signed-in user's name, not
          // who is signed in, so it does not start them again.
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                (current is Authenticated &&
                    (previous is! Authenticated ||
                        previous.user.id != current.user.id)) ||
                (current is Unauthenticated && previous is! Unauthenticated),
            listener: (context, state) {
              // The saved name and email, and the photo on this device.
              context.read<ProfileBloc>().add(
                state is Authenticated
                    ? ProfileStarted(
                        userId: state.user.id,
                        userKey: state.user.userKey,
                      )
                    : ProfileCleared(),
              );
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
              // With no place chosen yet, this detects where the device is.
              context.read<LocationBloc>().add(
                state is Authenticated ? LocationStarted() : LocationCleared(),
              );
              // Claims the one-time welcome gift and loads the balance; a
              // failure there never gets in the way of signing in.
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
          // Katyayani Core knows the user by phone, with their name and
          // email, as the React Native app does: sent on sign-in and on every
          // profile edit, and forgotten on sign-out.
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                (current is Authenticated &&
                    (previous is! Authenticated ||
                        previous.user != current.user)) ||
                (current is Unauthenticated && previous is! Unauthenticated),
            listener: (context, state) {
              final engagement = context.read<KoEngagementService>();
              final analytics = context.read<AnalyticsService>();
              if (state is Authenticated) {
                unawaited(
                  engagement.identify(
                    phone: state.user.phone,
                    fullName: state.user.fullName,
                    email: state.user.email,
                  ),
                );
                // Google Analytics and Meta know the user by id, never by phone.
                analytics.setUserId(state.user.id);
              } else {
                engagement.resetIdentity();
                analytics.setUserId(null);
              }
            },
          ),
          // The theme the user picked, from any toggle in the app.
          BlocListener<ThemeBloc, ThemeState>(
            listenWhen: (previous, current) => previous.mode != current.mode,
            listener: (context, state) =>
                context.read<AnalyticsService>().track(
                  AppEvents.themeChanged,
                  properties: {'theme': state.mode.name},
                ),
          ),
          // The applied coupon follows the cart: every subtotal change
          // re-checks it, and an emptied cart drops it.
          BlocListener<CartBloc, CartState>(
            listenWhen: (previous, current) =>
                previous.subtotal != current.subtotal,
            listener: (context, state) => context.read<CouponBloc>().add(
              CouponCartChanged(state.subtotal),
            ),
          ),
          // The saved profile wins over the name the session started with,
          // so an edit shows on every screen and survives a restart.
          BlocListener<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) =>
                current.profile != null && current.profile != previous.profile,
            listener: (context, state) => context.read<AuthBloc>().add(
              AuthProfileChanged(
                fullName: state.profile!.fullName,
                email: state.profile!.email,
              ),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final themeMode = context.select(
              (ThemeBloc bloc) => bloc.state.mode,
            );
            return MaterialApp.router(
              title: 'MyMali',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                maxScaleFactor: maxTextScaleFactor,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

The providers, in order, and why each is where it is:

| provider | lazy | created as | reason |
|---|---|---|---|
| `BlocProvider<AuthBloc>` | default (lazy) | `sl<AuthBloc>()` | session owner; `SplashPage` sends `AuthStatusRequested` |
| `BlocProvider<ThemeBloc>` | lazy | `sl<ThemeBloc>()` | read by the `Builder` below for `themeMode` |
| `BlocProvider<CartBloc>` | `lazy: false` | `sl<CartBloc>()..add(CartStarted())` | loads the stored cart before any screen |
| `BlocProvider<WishlistBloc>` | lazy | `sl<WishlistBloc>()` | started by the auth listener |
| `BlocProvider<LocationBloc>` | lazy | `sl<LocationBloc>()` | started by the auth listener |
| `BlocProvider<MaliCoinsBloc>` | lazy | `sl<MaliCoinsBloc>()` | started by the auth listener |
| `BlocProvider<ProfileBloc>` | lazy | `sl<ProfileBloc>()` | started by the auth listener |
| `BlocProvider<CouponBloc>` | `lazy: false` | `sl<CouponBloc>()` | must hear `CouponCartChanged` from the first cart load |
| `RepositoryProvider<KoEngagementService>` | — | `sl<KoEngagementService>()` | read by the identity listener and Home's push prompt |
| `RepositoryProvider<AnalyticsService>` | — | `sl<AnalyticsService>()` | screens call `context.read<AnalyticsService>()`; blocs get it by constructor |

The listeners:

| # | listener | `listenWhen` | dispatches |
|---|---|---|---|
| 1 | `BlocListener<AuthBloc, AuthState>` (user-scoped data) | `(current is Authenticated && (previous is! Authenticated || previous.user.id != current.user.id)) || (current is Unauthenticated && previous is! Unauthenticated)` | Authenticated: `ProfileStarted(userId:, userKey:)`, `WishlistStarted(id)`, `CartSignedIn(id)`, `LocationStarted()`, `MaliCoinsStarted()`. Otherwise: `ProfileCleared()`, `WishlistCleared()`, `CartSignedOut()`, `LocationCleared()`, `MaliCoinsCleared()`, `CouponCleared()` |
| 2 | `BlocListener<AuthBloc, AuthState>` (identity) | same but `previous.user != current.user` (any field) | Authenticated: `unawaited(engagement.identify(phone:, fullName:, email:))`, `analytics.setUserId(user.id)`. Otherwise: `engagement.resetIdentity()`, `analytics.setUserId(null)` |
| 3 | `BlocListener<ThemeBloc, ThemeState>` | `previous.mode != current.mode` | `analytics.track(AppEvents.themeChanged, properties: {'theme': state.mode.name})` |
| 4 | `BlocListener<CartBloc, CartState>` | `previous.subtotal != current.subtotal` | `CouponBloc.add(CouponCartChanged(state.subtotal))` |
| 5 | `BlocListener<ProfileBloc, ProfileState>` | `current.profile != null && current.profile != previous.profile` | `AuthBloc.add(AuthProfileChanged(fullName:, email:))` |

Rules encoded: app-wide blocs are provided once at the root and never re-provided; `lazy: false` only when a bloc must act before any screen reads it; services the UI reads go in `RepositoryProvider`s; cross-bloc wiring happens only here with a precise `listenWhen`; a bloc never reads another bloc; the `Builder` is needed so `context.select` runs under the providers; theming is `AppTheme.light`/`AppTheme.dark` with the mode from `ThemeBloc`; text scale is clamped in `MaterialApp.router.builder`.

### 3.13 A page creates its own bloc with `BlocProvider<XBloc>(create: (_) => sl<XBloc>()…)`

Simplest form (page bloc, start event, private view):

```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => sl<LoginBloc>(),
      child: const _LoginView(),
    );
  }
}
```

With a start event whose data does not come from a bloc (Home):

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => sl<HomeBloc>()
        ..add(
          // The bloc never sees a BuildContext. Read the device locale without
          // one: inherited widgets cannot be listened to from `create`.
          HomeStarted(
            language:
                WidgetsBinding.instance.platformDispatcher.locale.languageCode,
          ),
        ),
      child: const PushPermissionPrompt(child: _HomeView()),
    );
  }
}
```

Seeded from an app-wide bloc's current state (Cart; Review & Pay does the same with `CartBloc` and `CouponBloc`):

```dart
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CartPageBloc>(
      create: (context) {
        final cart = context.read<CartBloc>().state;
        return sl<CartPageBloc>()..add(
          CartPageStarted(items: cart.items, savedForLater: cart.savedForLater),
        );
      },
      child: const _CartView(),
    );
  }
}
```

A sheet that owns a bloc:

```dart
Future<Gstin?> showGstinSheet(BuildContext context, {required String userKey}) {
  return AppPickerSheet.show<Gstin>(
    context,
    builder: (context) => BlocProvider<GstinSheetBloc>(
      create: (_) => sl<GstinSheetBloc>(),
      child: _GstinSheet(userKey: userKey),
    ),
  );
}
```

Rules: the page widget is a `StatelessWidget` whose `build` returns exactly `BlocProvider<XBloc>(create: ..., child: const _XView())`; the type argument is always written; `sl<XBloc>()` is called only inside `create:` (a factory, so the provider owns and closes it); the start event is cascaded with `..add(...)`; when the start event needs an app-wide bloc's state, `create: (context) { final x = context.read<YBloc>().state; return sl<XBloc>()..add(...); }`; the view is a private `_XView` widget in the same file. All 24 `BlocProvider` call sites in `lib/features` (grep) follow this: 23 pages + 1 sheet; every one uses `sl<...>()` exactly once.

### 3.14 A page bloc never reads an app-wide bloc; the page forwards changes with `BlocListener`s

```dart
        // The page bloc never reads the cart bloc: tell it what changed.
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              previous.items != current.items ||
              previous.savedForLater != current.savedForLater,
          listener: (context, state) => context.read<CartPageBloc>().add(
            CartPageCartChanged(
              items: state.items,
              savedForLater: state.savedForLater,
            ),
          ),
        ),
```

And the reverse direction (page bloc result → app-wide bloc), from Review & Pay:

```dart
        BlocListener<ReviewPayBloc, ReviewPayState>(
          listenWhen: (previous, current) =>
              current.coinsAvailable != null &&
              current.coinsAvailable != previous.coinsAvailable,
          listener: (context, state) => context.read<MaliCoinsBloc>().add(
            MaliCoinsBalanceChanged(state.coinsAvailable!),
          ),
        ),
```

### 3.15 An app-wide bloc's constructor: required use cases, optional `AnalyticsService?`, private finals, `super(const InitialState())`, `on<>` registrations

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RestoreSession restoreSession,
    required SignOut signOut,
    AnalyticsService? analytics,
  }) : _restoreSession = restoreSession,
       _signOut = signOut,
       _analytics = analytics,
       super(const AuthInitial()) {
    on<AuthStatusRequested>(_onStatusRequested);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileChanged>(_onProfileChanged);
  }

  final RestoreSession _restoreSession;
  final SignOut _signOut;

  /// Reports sign-outs. Null reports nothing.
  final AnalyticsService? _analytics;
```

Rules: use cases are `required` named parameters typed by the concrete use-case class; `AnalyticsService? analytics` is optional and null in tests that do not care (`_analytics?.track(...)`); fields are private finals assigned in the initializer list; the initial state is `const`; handlers are private `_onX` methods registered in the constructor body. The bloc file `export`s its event and state files (`export 'auth_event.dart'; export 'auth_state.dart';`) so pages import only `auth_bloc.dart`. A bloc that depends on the clock takes `DateTime Function() now = DateTime.now` last (`CouponBloc`, `AddressFormBloc`, `OrderPlacedBloc`).

### 3.16 A bloc with many use cases plus a plain configuration value (Home)

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetHomeSections getHomeSections,
    required GetCachedHomeSections getCachedHomeSections,
    required GetAppState getAppState,
    required GetSoldCounts getSoldCounts,
    required GetCachedSoldCounts getCachedSoldCounts,
    required GetLowStockThresholds getLowStockThresholds,
    required GetCachedLowStockThresholds getCachedLowStockThresholds,
    String imageBaseUrl = '',
  }) : _getHomeSections = getHomeSections,
       _getCachedHomeSections = getCachedHomeSections,
       _getAppState = getAppState,
       _getSoldCounts = getSoldCounts,
       _getCachedSoldCounts = getCachedSoldCounts,
       _getLowStockThresholds = getLowStockThresholds,
       _getCachedLowStockThresholds = getCachedLowStockThresholds,
       _imageBaseUrl = imageBaseUrl,
       super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<HomeRefreshed>(_onHomeRefreshed);
  }
```

Rule: a value that is environment in production and blank in tests is a defaulted constructor parameter, injected by the registration function's parameter (3.8), never read from `Env` in the bloc.

### 3.17 The splash dispatches the restore event and routes on the resolved state

```dart
  @override
  void initState() {
    super.initState();
    // Restore a saved session so a signed-in user stays signed in.
    final authBloc = context.read<AuthBloc>()..add(AuthStatusRequested());

    // Show the splash for a moment, then go wherever the session points.
    _timer = Timer(SplashPage.displayDuration, () async {
      final state = _isResolved(authBloc.state)
          ? authBloc.state
          : await authBloc.stream.firstWhere(_isResolved);
      if (!mounted) return;
      final route = state is Authenticated ? AppRoute.home : AppRoute.login;
      context.goNamed(route.name);
    });
  }

  static bool _isResolved(AuthState state) =>
      state is Authenticated || state is Unauthenticated;
```

### 3.18 Sign-in/out fan-out is received by a `Started`/`Cleared` event pair and guarded by a session counter

```dart
  /// Bumped on every sign-in and sign-out. An answer that arrives for an
  /// earlier user is dropped.
  int _session = 0;

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
    ...
  }

  void _onCleared(MaliCoinsCleared event, Emitter<MaliCoinsState> emit) {
    _session++;
    _reset(emit);
  }

  /// Back to the empty state. Emits nothing when already there.
  void _reset(Emitter<MaliCoinsState> emit) {
    const empty = MaliCoinsState();
    if (state != empty) emit(empty);
  }
```

Rule: every app-wide bloc that `app.dart` starts on sign-in has `XStarted` (+ user id where needed) and `XCleared`; `_session` is incremented on both and checked after every `await`; `_reset` emits the empty state only when it differs. `WishlistBloc`, `LocationBloc`, `MaliCoinsBloc` and `CouponBloc` all carry `_session`; `CartBloc` uses `_syncCount` with the same meaning.

### 3.19 `copyWith` with clearable nullable fields as getters

```dart
  /// Nullable fields take a getter so they can be explicitly cleared,
  /// e.g. `copyWith(failure: () => null)`.
  CartState copyWith({
    CartStatus? status,
    List<CartItem>? items,
    List<CartItem>? savedForLater,
    Failure? Function()? failure,
    Map<String, int>? stockLimits,
    CartStockChanges? Function()? stockChanges,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      savedForLater: savedForLater ?? this.savedForLater,
      failure: failure != null ? failure() : this.failure,
      stockLimits: stockLimits ?? this.stockLimits,
      stockChanges: stockChanges != null ? stockChanges() : this.stockChanges,
    );
  }
```

Rule: non-nullable fields `T?` with `?? this.x`; nullable fields `T? Function()?` with `x != null ? x() : this.x`; the doc comment above `copyWith` is copied verbatim in every state (`CartState`, `WishlistState`, `LocationState`, `MaliCoinsState`, `CouponState`, `ProfileState`).

### 3.20 Typed environment access

```dart
abstract final class Env {
  static const String _fileName = '.env';

  static Future<void> load() => dotenv.load(fileName: _fileName);

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  ...
  static String? get fbAppId => _optional('FB_APP_ID');
  static String? get fbClientToken => _optional('FB_CLIENT_TOKEN');
  ...
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

Rule: one getter per key, required keys through `_require` (throws `StateError`), optional ones through `_optional` (null when blank); an enum-valued key is parsed in its getter with a `switch` that throws on an unknown value (`koEnv`, `razorpayMode`); a key with environment variants is read through a helper that appends the suffix (`_koValue` → `${key}_PROD` / `${key}_BETA`). `.env` is a bundled asset (`pubspec.yaml` → `assets: - .env`).

### 3.21 Test registration mirrors production: fakes by abstract type, then the public `register<X>Feature()`

```dart
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
```

A page test adds its own feature on top:

```dart
  setUp(() {
    engagement = FakeKoEngagementService();
    registerSignedInApp(engagement: engagement);
    repository = FakeSupportRepository();
    sl.registerSingleton<SupportRepository>(repository);
    registerSupportFeature();
  });
  tearDown(sl.reset);
```

Rules: tests use `registerSingleton<Abstract>(fake)` (eager) where production uses `registerLazySingleton`; the `_register<X>Data()` functions are never called in tests (that is why they are private); every test that pumps `App` must register `KoEngagementService` and `AnalyticsService` (`registerFakeEngagement()` or `registerSignedInApp`) because `App`'s `RepositoryProvider`s resolve them; `tearDown(sl.reset)` also runs the `dispose:` callbacks.

---

## 4. Rules observed in code (not in AGENTS.md, or stated differently)

1. **Startup has more steps than AGENTS lists.** AGENTS §2 describes `bootstrap.dart` as "orientation, Env, Supabase, cache, DI, runApp" and §9 says `bootstrap()` calls `configureDependencies()` "after `Env.load()`, `Supabase.initialize()` and `HiveLocalCache.init()`". The code also runs `_initFirebase()` (after `Env.load()`) and `DeviceSecureStorage.init()` (before `Supabase.initialize`), then after DI `unawaited(_initEngagement())`, `unawaited(sl<AnalyticsService>().requestTrackingPermission())`. §7 and §23 mention these individually; §2/§9 do not.
2. **`configureDependencies()` is synchronous** (`void`), not awaited; AGENTS does not say so. Nothing in DI does I/O; every service that needs I/O exposes `init()` called from `bootstrap`.
3. **`bootstrap.dart` calls `sl<…>()` directly** (4 times). AGENTS §9 allows `sl` only in `injection_container.dart` and `BlocProvider` `create:`s in `app.dart` and pages. Also `gstin_sheet.dart` (a `widgets/` file, not a page) calls `sl<GstinSheetBloc>()` inside a `BlocProvider.create`. Grep of `lib/`: `injection_container.dart` 243, `app.dart` 10, `bootstrap.dart` 4, 23 pages + 1 sheet widget with 1 each. No bloc, use case, repository or data source calls `sl`.
4. **`App` provides services through `RepositoryProvider`**, not just blocs (AGENTS §23 says screens use `context.read<AnalyticsService>()`, but §9/§10 never say how it gets into the tree).
5. **Feature registration functions depend on other features' use cases**, not "only on the repository" (AGENTS §9: "They should depend only on the repository"). `registerHomeFeature` (catalog + app_config), `registerCategoriesFeature` (catalog), `registerCartFeature` (`CartPageBloc` uses catalog), `registerWishlistFeature` (catalog), `registerAddressFeature` (`AddressFormBloc` uses `GetCurrentPlace`), `registerLocationFeature` (`SelectLocationBloc` uses addresses), `registerCheckoutFeature` (cart, mali_coins, coupons, address, orders, catalog), `registerProductFeature` (catalog, delivery, app_config), `registerAccountFeature` (`GetCoinRules`), `registerDeliveryFeature` (`ChargeRulesRepository`). The dependency is declared in the doc comment and honoured by the call order in `configureDependencies()` and in tests.
6. **A repository may need `dispose:`**: `AuthRepositoryImpl` subscribes to `AuthSessionDataSource.refreshedSessions` in its constructor, and DI registers it with `dispose: (repository) => (repository as AuthRepositoryImpl).dispose()`. AGENTS does not mention `dispose`.
7. **Use cases are registered by concrete type** (no `<T>` on `registerLazySingleton(() => SendOtp(sl()))`); only data sources, repositories and core services are registered by abstract type. AGENTS §9 says "Register a data source or repository by its abstract type" and is silent on use cases.
8. **`NetworkingService` falls back to constructing `DeviceSecureStorage()` itself** when no `SecureStorage` is injected (`secureStorage ?? DeviceSecureStorage()`); DI always injects `secureStorage: sl()`.
9. **`BaseApiRepo` is live infrastructure**: `NetworkingService extends BaseApiRepo` and `_dioFor(host)` picks its `dioSupabse`/`dioMedusa`/`dioKoUtils`/`dioStockship` fields, while AGENTS §16 lists `lib/core/repositories/base_api_repository.dart` under "Legacy code — do not copy". §18 itself says "BaseApiRepo creates one Dio per host". The field name `dioSupabse` (sic) must be reproduced as is.
10. **`api_response.dart` is live** (`SuccessResponse`/`ErrorResponse` are the only response types) while AGENTS §16 lists it as legacy "contains analyzer warnings".
11. **Typed data-source exceptions live in `core`, not per feature**: `lib/core/app/exceptions/api_exceptions.dart` holds `ServerException({code, status, detail})` and `ConnectionException` used by every feature; AGENTS §2/§5 say `features/<feature>/data/exceptions/`. A second, unrelated `ServerException([String? message]) extends AppException` exists in `lib/core/app/exceptions/app_exceptions.dart`; data sources import the `api_exceptions.dart` one.
12. **Two instances of `PrefUtils` and `DeviceSecureStorage` exist by design**: `bootstrap` constructs both directly for `SecureSessionStorage` before DI exists, and DI registers singletons later; both classes keep static state (`PrefUtils._sharedPreferences`, `DeviceSecureStorage._memory`) so this is safe. `PrefUtils()` starts `init()` unawaited; every reader `await _prefs.init()` first.
13. **`Env` is read eagerly in exactly one place**: `registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl)`; every other `Env.*` in DI is inside a lazy lambda. `Endpoints.baseUrlMain` etc. are `static String` fields initialised from `Env` on first use of `Endpoints` (which happens when `BaseApiRepo` is constructed, i.e. first `sl<Networking>()`).
14. **The sign-in listener keys on `user.id`, the identity listener on the whole `AuthUser`**: a profile edit (same id, new name) re-identifies the user to Katyayani Core and GA4/Meta but does not restart the user-scoped blocs. AGENTS §23 says "on every profile edit" without saying how the two listeners differ.
15. **At cold start with no session the "clear" branch fires once** (`AuthInitial → Unauthenticated` satisfies `current is Unauthenticated && previous is! Unauthenticated`), dispatching every `XCleared`/`CartSignedOut`/`CouponCleared` on an already-empty app. Harmless, but any new app-wide bloc must tolerate `Cleared` before `Started`.
16. **`AuthFailure` on a failed sign-out is not `Unauthenticated`**: `AuthBloc` emits `AuthFailure(failure.message)`, so neither listener fires and the user-scoped blocs are not cleared, although `AuthRepositoryImpl.signOut()` clears the tokens in `finally`. No listener handles `AuthFailure`. (AGENTS does not specify.)
17. **`LoginPage` navigates from a `BlocListener<AuthBloc, AuthState>` with no `listenWhen`** (`BlocListener<AuthBloc, AuthState>(listener: _onAuthStateChanged)` → `if (state is Authenticated) goNamed(home)`), and `AccountPage` uses `listenWhen: (_, current) => current is Unauthenticated` ignoring `previous`. AGENTS §10 asks for "a precise `listenWhen`".
18. **`LoginPage` still shows an `AlertDialog`** for verify failures (AGENTS §22 acknowledges this as pre-`AppInfoSheet` legacy).
19. **`App` requires `KoEngagementService` and `AnalyticsService` in `sl`** even though AGENTS §14's widget-test recipe only registers `AuthRepository` + `registerAuthFeature()`; §23 adds `registerFakeEngagement()`. Without it `RepositoryProvider.create` throws on first read.
20. **`AppRouter` only reports screens when built with `analytics:`**; `test/widget_test.dart` builds `AppRouter().router` (no reporting), `signed_in_app.dart` builds `AppRouter(analytics: sl<AnalyticsService>()).router`. One `AnalyticsRouteObserver` is created per navigator by calling `_observers()` for the root and for each `StatefulShellBranch`.
21. **`ThemeBloc` is not persisted** (`// TODO(settings): persist the chosen mode through a settings repository.`); AGENTS does not say either way.
22. **The `Networking.putAPICall` has no `headers:` parameter** while the other verbs do (AGENTS §6 says to extend in place when needed).
23. **`Env.allowTestPayments` is a mutable `@visibleForTesting static bool`**, not a const, so tests can flip `RAZORPAY_MODE=test` handling; `Env.razorpayMode` defaults to `live` when absent.
24. **`PrefUtils.getUserToken()` reads `'xx-token'`** — dead legacy; the live token key is `StringConstants.appAuthToken = 'auth.access_token'`, shared by `AuthLocalDataSourceImpl.accessTokenKey` and `NetworkingService._getOptions`.
25. **Repo files mix CRLF and LF line endings**: greps anchored on `$` miss most constructors. A skill that scans the repo must not rely on `$`.
26. **`networking.dart` and `endpoints.dart` use absolute `package:mymali/...` imports** while the rest of `lib/` uses relative imports; a port must rewrite the package name there.

---

## 5. Packages

| package (pubspec constraint) | files in this area that import it | ALWAYS / CONDITIONAL |
|---|---|---|
| `get_it: ^8.0.3` | `lib/core/di/injection_container.dart` (also `test/helpers/*` through `sl`) | ALWAYS |
| `flutter_bloc: ^9.1.0` (+ `bloc: ^9.0.0`) | `lib/app/app.dart`, every bloc, every page, `app_shell_scaffold.dart` | ALWAYS |
| `equatable: ^2.0.7` | every state, `NoParams`, `APIResponse` | ALWAYS |
| `fpdart: ^1.1.1` | `usecase.dart`, blocs (`Either`), `cart_event.dart` | ALWAYS |
| `go_router: ^18.0.2` | `lib/app/app.dart` (`GoRouter` type), `lib/core/router/app_router.dart`, pages (`goNamed`/`pushNamed`), `app_shell_scaffold.dart` | ALWAYS |
| `flutter_dotenv: ^6.0.1` | `lib/core/config/env.dart` | ALWAYS |
| `dio: ^5.11.1` | `lib/core/services/networking/networking.dart`, `lib/core/repositories/base_api_repository.dart` | ALWAYS |
| `shared_preferences: ^2.0.5` | `lib/core/services/pref_utils.dart` | ALWAYS |
| `supabase_flutter: ^2.17.2` | `lib/app/bootstrap.dart`, `lib/core/di/injection_container.dart` (`SupabaseClient`, `Supabase.instance`), `lib/core/services/secure_storage/secure_session_storage.dart` (`LocalStorage`), `features/auth/data/datasources/auth_session_data_source.dart` | CONDITIONAL(Supabase backend) |
| `flutter_secure_storage: ^11.2.0` | `lib/core/services/secure_storage/device_secure_storage.dart` only | CONDITIONAL(app stores tokens) |
| `hive_ce_flutter: ^2.4.0` (+ `hive_ce: ^2.20.1`) | `lib/core/services/local_cache/hive_local_cache.dart` only | CONDITIONAL(app caches server data) |
| `firebase_core: ^4.15.0` | `lib/app/bootstrap.dart`, `lib/core/services/analytics/firebase_analytics_destination.dart` | CONDITIONAL(Firebase) |
| `firebase_analytics: ^12.6.0` | `firebase_analytics_destination.dart` only | CONDITIONAL(GA4) |
| `facebook_app_events: ^0.30.5`, `app_tracking_transparency: ^2.0.7` | `meta_analytics_destination.dart` only | CONDITIONAL(Meta) |
| `katyayani_core: ^2.0.7` | `lib/core/services/katyayani_core/ko_engagement_service_impl.dart` only | MYMALI-SPECIFIC |
| `flutter_local_notifications: ^22.3.1` | `lib/core/services/local_notifications/local_notification_service_impl.dart` only | CONDITIONAL(push) |
| `razorpay_flutter: ^1.4.7` | `lib/core/services/payments/razorpay_payment_gateway.dart` only | CONDITIONAL(Razorpay payments) |
| `loading_animation_widget: ^1.3.0` | `features/auth/presentation/splash/pages/splash_page.dart` | CONDITIONAL(splash spinner; replaceable) |
| `url_launcher: ^6.2.5` | `features/home/presentation/home/pages/home_page.dart` | CONDITIONAL(opens links) |
| `geocoding: ^5.0.0`, `geolocator: ^14.1.1` | `features/location/data/datasources/device_location_data_source.dart` (registered in `_registerLocationData`) | CONDITIONAL(location) |
| `image_picker: ^1.2.4` | `features/profile/data/datasources/avatar_picker_data_source.dart` (registered in `_registerProfileData`) | CONDITIONAL(avatar picking) |
| `package_info_plus: ^10.2.2` | `features/account/data/datasources/app_info_data_source.dart` (registered in `_registerAccountData`) | CONDITIONAL(shows app version) |
| Flutter SDK (`flutter/foundation`, `services`, `widgets`, `material`) | `bootstrap.dart`, `app.dart`, `injection_container.dart`, theme, blocs | ALWAYS |
| In `pubspec.yaml` but not imported by this area | `cupertino_icons`, `gap`, `intl`, `toastification`, `connectivity_plus`, `internet_connection_checker`, `crypto`, `intl_phone_field`, `skeletonizer`, `cached_network_image`, `share_plus`, `pdf`; dev: `flutter_lints`, `flutter_launcher_icons` | — |

Also in `pubspec.yaml` and load-bearing for this area: `flutter: assets: - .env` (the env file is a bundled asset), fonts `Marcellus` (`AppTheme.displayFontFamily`), `environment: sdk: ^3.13.4`.

---

## 6. What varies per app

| what | where it appears | MyMali value |
|---|---|---|
| App title | `app.dart` → `MaterialApp.router(title:)` | `'MyMali'` |
| Max text scale | `App.maxTextScaleFactor` | `1.1` |
| Orientation lock | `bootstrap.dart` `SystemChrome.setPreferredOrientations` (+ manifest/plist) | `[DeviceOrientation.portraitUp]` |
| Dart package name | `package:mymali/...` imports in `networking.dart`, `endpoints.dart`, `string_constants.dart`, `base_api_repository.dart`, all tests | `mymali` |
| `.env` keys and `Env` getters | `lib/core/config/env.dart`, `.env.example` | `SUPABASE_URL`→`supabaseUrl`, `SUPABASE_ANON_KEY`→`supabaseAnonKey`, `MEDUSA_URL`→`medusaBaseUrl`, `MEDUSA_PUBLISHABLE_KEY`→`medusaApiKey`, `APP_WEB_ORIGIN`→`webOrigin`, `KO_ENV`→`koEnv`, `UTILS_URL_{PROD,BETA}`→`utilsUrl`, `STOCKSHIP_URL_{PROD,BETA}`→`stockshipUrl`, `RAZORPAY_KEY_ID_{PROD,BETA}`/`RAZORPAY_TEST_KEY_ID`/`RAZORPAY_MODE`→`razorpayKeyId`/`razorpayMode`, `MKTP_ID`→`mktpId`, `KC_SITE_ID`→`kcSiteId`, `KC_API_URL`→`kcApiUrl`, `FB_APP_ID`→`fbAppId`, `FB_CLIENT_TOKEN`→`fbClientToken`, `APP_VERSION`→`appVersion`. (`.env.example` also lists `PINCODE_HOST`, `GST_HOST` with no getter.) |
| Which optional subsystems start in `bootstrap` | `bootstrap.dart` | Firebase, secure storage, Supabase, Hive, notifications + Katyayani Core, ATT |
| Hosts | `ApiHost` enum, `BaseApiRepo` Dio fields, `NetworkingService._thirdPartyHosts`, `Endpoints.*BaseUrl`, endpoint classes | `supabase`, `medusa`, `koUtils`, `stockship` |
| Endpoint paths | `Endpoints`, `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` | see file |
| Default auth header token key | `StringConstants.appAuthToken`, `AuthLocalDataSourceImpl.accessTokenKey` | `'auth.access_token'` (+ `'auth.refresh_token'`, `'auth.user_id'`) |
| Secure-storage install flag | `DeviceSecureStorage.installedKey` | `'secure_storage.installed'` |
| Supabase session key | `SecureSessionStorage.keyFor` | `'sb-<project-ref>-auth-token'` |
| Cache boxes | `CacheBoxes` (`all`, `userScoped`) | `catalog, charge_rules, addresses, mali_coins, coin_rules, coupons, product, seller, support`; user-scoped `addresses, mali_coins` |
| PrefUtils keys | local data sources | `cart.items`, `wishlist.saved`, `location.selected_place`, `checkout.order_attempt`, `profile.avatar.<userId>` |
| Routes | `AppRoute` enum, `AppRouter` route list, `navigator_keys.dart`, `analyticsScreenNames`, `analyticsTabs` | 24 routes, 5 tabs |
| Analytics event names | `AppEvents` | React Native app names (`'Login Started'`, `'Theme Changed'`, …) |
| Analytics `core` and destinations | `_registerCore` → `MultiDestinationAnalyticsService(core: KoAnalyticsService(sl()), destinations: _analyticsDestinations())` | Katyayani Core + GA4 + Meta |
| App-wide blocs | `App.providers` | `AuthBloc, ThemeBloc, CartBloc (eager), WishlistBloc, LocationBloc, MaliCoinsBloc, ProfileBloc, CouponBloc (eager)` |
| Services exposed to widgets | `App.providers` `RepositoryProvider`s | `KoEngagementService`, `AnalyticsService` |
| Sign-in/out fan-out and cross-bloc links | `App.listeners` | 5 listeners (3.12) |
| Feature list and call order | `configureDependencies()` | 24 blocks (3.4) |
| Registration parameter from `Env` | `registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl)` | Medusa origin |
| Notification channel | `LocalNotificationServiceImpl` | id `push_campaigns`, name `MY Mali`, sound `notification`, icon `@drawable/notification_icon`, LED `0xFF163E33` |
| Broadcast topic | `KoEngagementServiceImpl.broadcastTopic` | `all_users` |
| Payment sheet colour / currency / merchant text | `RazorpayPaymentGateway.themeColor`, `optionsFor` | `'#225542'`, `'INR'` |
| Theme | `AppColors`, `AppTheme.fontSizeFactor` (0.88), `AppTheme.displayFontFamily` (`'Marcellus'`), `AppTones` | brand greens |
| Splash duration | `SplashPage.displayDuration` | 2600 ms |
| Firebase platform guard and ids | `_initFirebase`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | Android + iOS, `com.katyayani.mymali` |
| Log tags | `[firebase]`, `[kc]`, `[notifications]`, `[secure_storage]`, `[ko-token]`, `[ga4]`, `[meta]`, `[razorpay]` | — |
| Test helper names | `registerSignedInApp`, `launchSignedInApp`, `registerFakeEngagement`, `registerAccountFakes` | — |

---

## 7. Gotchas

1. **`configureDependencies()` must run after `Env.load()` and the SDK inits**, but it does no I/O itself; the first `sl<Networking>()` constructs `BaseApiRepo`, whose field initialisers read `Endpoints.baseUrlMain = Env.supabaseUrl` etc. A missing `.env` key surfaces as a `StateError` at that first resolution, not at startup.
2. **Blocs are factories; never cache `sl<XBloc>()`**. Call it only inside `BlocProvider.create` so the provider closes it. `lazy: false` is used only for `CartBloc` and `CouponBloc`.
3. **Provider order matters inside `App`**: the `MultiBlocListener` reads `ProfileBloc`, `WishlistBloc`, `CartBloc`, `LocationBloc`, `MaliCoinsBloc`, `CouponBloc`, `KoEngagementService`, `AnalyticsService`, `AuthBloc` through `context.read`, so every one of them must be in `MultiBlocProvider.providers` above it; `MaterialApp.router` sits inside a `Builder` so `context.select((ThemeBloc b) => b.state.mode)` sees the providers.
4. **Two different `listenWhen`s on the same `AuthBloc`**: `previous.user.id != current.user.id` (restart user data) vs `previous.user != current.user` (re-identify). Copy both; merging them either re-syncs the cart on every profile edit or stops re-identifying.
5. **`Unauthenticated` fires the clear branch at cold start** (from `AuthInitial`). Every `XCleared` handler must be safe to receive first (`_reset` emits only when state differs).
6. **`AuthFailure` is a dead end** for the listeners: a failed `signOut()` leaves the app in `AuthFailure`, tokens cleared, user-scoped blocs untouched. Reproduce as is or decide explicitly.
7. **`DeviceSecureStorage.init()` before `Supabase.initialize`**, and `_initFirebase()` before DI: both orders are load-bearing (session storage wipe; `Firebase.apps` checked by the GA4 destination).
8. **`_initEngagement()` order is fixed**: `LocalNotificationService.init()` first, then `KoEngagementService.init()`, because both configure the same notifications plugin and the SDK's tap handler must be the last set.
9. **`KoEngagementServiceImpl.identify()` awaits `_starting`** (the in-flight `init()`), so a restored session identified before the SDK finished starting is not lost; `resetIdentity()` chains on `_starting` too. Any replacement engagement service needs the same memoised `init()` future.
10. **`PrefUtils()` and `DeviceSecureStorage()` are constructed directly in `bootstrap`** (DI not ready) and again by DI; this only works because both keep static state. Do not "fix" by moving `Supabase.initialize` after DI without also moving the storage classes to instances.
11. **`AuthLocalDataSourceImpl(sl(), sl(), sl())` is positional**: `SecureStorage`, `PrefUtils`, `LocalCache` in that order. `KoOrderRemoteDataSourceImpl(sl(), tokens: sl())` is positional + named. `PlaceCodOrder(sl(), sl())` / `RegisterOnlineOrder(sl(), sl())` are `(CheckoutRepository, CatalogRepository)`. GetIt infers each `sl()` from the parameter type, so these compile only while the constructors keep those types.
12. **The `dispose:` on `AuthRepository`** is what makes `sl.reset()` in `tearDown` cancel the refresh subscription; omit it and tests leak a stream listener on the Supabase client.
13. **`registerHomeFeature(imageBaseUrl:)` is the one registration with a parameter**; tests call it without arguments. Any other value a bloc needs from `Env` should follow this shape rather than reading `Env` in the bloc.
14. **`App` cannot be pumped without `KoEngagementService` and `AnalyticsService` registered**; `registerFakeEngagement()` registers both (`AnalyticsService` as `KoAnalyticsService(fake)`), bypassing `MultiDestinationAnalyticsService`.
15. **`AppRouter` needs `analytics:` for screen reporting**, and each navigator (root + every `StatefulShellBranch`) needs its own observer (`observers: _observers()` repeated); one `NavigatorObserver` instance cannot serve two navigators.
16. **`HiveLocalCache.init()` opens only `CacheBoxes.all`**: a new box not added to `all` makes reads miss and writes throw `CacheException`; a user-scoped box not added to `userScoped` survives sign-out.
17. **`Networking.putAPICall` has no `headers:`**; add it in place if a data source needs it (AGENTS §6).
18. **Field spelling `dioSupabse`** in `BaseApiRepo` is referenced by `NetworkingService`; renaming one without the other breaks the build.
19. **Two classes named `ServerException`** (`core/app/exceptions/api_exceptions.dart` with `{code, status, detail}`; `core/app/exceptions/app_exceptions.dart` extending `AppException`). Data sources and repositories import the first; `NetworkingService.convertDioExceptionToAppException` throws from the second family (`InternetException`, `RequestTimeoutException`, `FetchDataException`).
20. **`.env` is a bundled asset** (`pubspec.yaml`), git-ignored, loaded by `Env.load()`; a build without it fails at `Env.load()`. Only client-safe values belong in it.
21. **`Env.razorpayMode == RazorpayMode.test` is honoured only when `Env.allowTestPayments` (`kDebugMode`)** — the DI line `useAppKey: Env.razorpayMode == RazorpayMode.test` is therefore always `false` in release.
22. **`MetaAnalyticsDestination` is created only when both `FB_APP_ID` and `FB_CLIENT_TOKEN` are set**, and only on Android/iOS (`_analyticsDestinations()`); `FirebaseAnalyticsDestination` is always created on phones but no-ops while `Firebase.apps.isEmpty`.
23. **CRLF**: parts of the repo use CRLF line endings; regex `$` anchors in `rg`/`grep` miss lines there. Verified constructors with a non-anchored pattern.
24. **Package imports**: `networking.dart`, `endpoints.dart` use `package:mymali/...`; a target app with another package name must rewrite them (and every `package:mymali/` in `test/`).
25. **`AppInfoDataSourceImpl([Future<PackageInfo> Function()? read])`, `AvatarPickerDataSourceImpl([ImagePicker? picker])`, `DeviceLocationDataSourceImpl({geocoder.Geocoding? geocoding})`, `LocalNotificationServiceImpl([FlutterLocalNotificationsPlugin? plugin])`, `RazorpayPaymentGateway({Razorpay Function()? newSdk})`, `FirebaseAnalyticsDestination([FirebaseAnalytics Function()? analytics])`, `MetaAnalyticsDestination([FacebookAppEvents? facebook])`, `HiveLocalCache({DateTime Function() now = DateTime.now})`** — the convention for an SDK-wrapping class is an optional constructor parameter for the SDK handle (or clock) so tests inject a fake and DI uses the `.new` tear-off.
