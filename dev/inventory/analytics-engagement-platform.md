# Inventory: analytics-engagement-platform

Source repo: `C:/Users/Katyayani/Documents/flutter/mymali` (read-only; commit `2aef62a`). Every
`lib/`, `test/`, native and tool file named below was read in full unless marked "(excerpt)".

The area is four services in `lib/core/services/` plus the router's screen tracker:

| Sub-area | Generic contract (ALWAYS) | SDK wrapper (CONDITIONAL / MYMALI) |
|---|---|---|
| Analytics | `AnalyticsService`, `AnalyticsItem`, `AppEvents`, `AnalyticsDestination`, `MultiDestinationAnalyticsService`, `analytics_event_mapper.dart`, `AnalyticsScreenTracker` + `AnalyticsRouteObserver` | `KoAnalyticsService` (Katyayani Core), `FirebaseAnalyticsDestination` (GA4), `MetaAnalyticsDestination` (Meta) |
| Engagement / push | — (interface shape is reusable, the SDK is not) | `KoEngagementService` + `KoEngagementServiceImpl` + `kc_identity.dart` (Katyayani Core) |
| Local notifications | `LocalNotificationService` interface | `LocalNotificationServiceImpl` (`flutter_local_notifications`) |
| Payments | `PaymentGateway`, `GatewayCheckout`, `GatewayPayment`, `GatewayPaymentError`, `GatewayPaymentException` | `RazorpayPaymentGateway`, `classifyRazorpayError` (`razorpay_flutter`) |
| Third-party bearer token | — (pattern is reusable: "mint, cache until skew, share one mint, 401 → invalidate + refresh once") | `KoTokenService` / `KoTokenServiceImpl` (KO-Tech) |

The **one rule all of them share** (the "wrap an SDK" template, section 3 pattern P-1): an
`abstract interface class` in `lib/core/services/<name>/<name>.dart`, one `…Impl` in
`<name>_impl.dart` (or `<vendor>_<name>.dart`) that is **the only file importing the SDK**,
every method safe to call before/without init (logs, never throws), registered once in
`injection_container.dart` as `registerLazySingleton<Interface>(…)`, reached by blocs through
constructor injection and by widgets through `RepositoryProvider<Interface>` in `app.dart` /
`context.read<Interface>()`, never from `build`, and tested with a hand-written
`Fake<Interface> implements Interface` in `test/helpers/`.

---

## 1. Files

Legend: **ALWAYS** = generic architecture, install in every app. **CONDITIONAL(cap)** = install
only when the target app has that capability. **MYMALI-SPECIFIC** = MyMali business.
"Placeholders" = the exact MyMali values a target app substitutes while keeping the file.

| path | role | class | placeholders |
|---|---|---|---|
| `lib/core/services/analytics/analytics_service.dart` | `abstract interface class AnalyticsService`: what features call; never an SDK | ALWAYS | method names fixed. `checkNudges(BuildContext, String route)` and `capturePayment(double, {orderId})` are Katyayani-Core concepts kept on the interface; a target app keeps the signatures and makes its core a no-op for them |
| `lib/core/services/analytics/analytics_item.dart` | `AnalyticsItem` value class (one product line) | ALWAYS | doc comment says "in rupees": currency wording only |
| `lib/core/services/analytics/app_events.dart` | `abstract final class AppEvents` — every event name as `static const String` | ALWAYS (class + rule) | **every constant value** is a MyMali / React-Native-app name (`'Added To Cart'`, `'Nav Bar Icon Tapped'`, …). Target app keeps the class name, the `static const String` shape, the "never type a name at a call site" rule, and substitutes its own names and groups |
| `lib/core/services/analytics/analytics_destination.dart` | `abstract interface class AnalyticsDestination`: one third-party sink (`log`, `setUserId`, `requestTrackingPermission`) | ALWAYS | doc comment names GA4/Meta only |
| `lib/core/services/analytics/multi_destination_analytics_service.dart` | `MultiDestinationAnalyticsService implements AnalyticsService`: fans `track` (and 3 typed calls) out to every destination; the registered `AnalyticsService` | ALWAYS | the three forwarded typed calls name `AppEvents.addToCart`, `AppEvents.removeFromCart`, `AppEvents.productSearch`; `_itemProperties` keys (`item_id`, `item_name`, `price`, `quantity`, `currency`) |
| `lib/core/services/analytics/analytics_event_mapper.dart` | pure Dart: `Ga4Event`, `MetaEvent`, `defaultCurrency`, `ga4NameFor`, `ga4EventFor`, `metaEventFor`, `_ga4Names`, `_metaStandardNames`, `_scalars`, `_snake`, `_clip` | ALWAYS for the GA4 half (CONDITIONAL(Meta) for `MetaEvent`/`metaEventFor`) | `defaultCurrency = 'INR'`; the two name tables are keyed by MyMali `AppEvents`; the Meta special cases (`productSearch`, `orderRated`, `paymentStarted`, `orderPlaced`) |
| `lib/core/services/analytics/firebase_analytics_destination.dart` | `FirebaseAnalyticsDestination implements AnalyticsDestination`: GA4; the only file importing `firebase_analytics` | CONDITIONAL(app uses Firebase/GA4) | log prefix `[ga4]` |
| `lib/core/services/analytics/meta_analytics_destination.dart` | `MetaAnalyticsDestination implements AnalyticsDestination`: Meta App Events + ATT; only file importing `facebook_app_events` and `app_tracking_transparency` | CONDITIONAL(app uses Meta ads) | log prefix `[meta]`; `_promptDelay` 1 s |
| `lib/core/services/analytics/ko_analytics_service.dart` | `KoAnalyticsService implements AnalyticsService`: the "core" that forwards to `KoEngagementService`; no-op `setUserId`/`requestTrackingPermission` | MYMALI-SPECIFIC (Katyayani Core). Its *shape* (an `AnalyticsService` that is the primary sink and is wrapped as `core:` by `MultiDestination…`) is the ALWAYS pattern | — |
| `lib/core/router/analytics_screen_tracker.dart` | `analyticsScreenNames`, `analyticsTabs`, `AnalyticsScreenTracker`, `AnalyticsRouteObserver`: router-driven screen views + "Screen Load" + `checkNudges` + "Nav Bar Icon Tapped" | ALWAYS | map values (`'ShopTab'`, `'Cart'`, …) and keys (route names); tab list; `AppEvents.navBarIconTapped` / `AppEvents.screenLoad`; property keys `tab`, `screen_name`; `_ignored = {AppRoute.splash.name}` |
| `lib/core/router/app_router.dart` (excerpt relevant here) | `AppRouter({AnalyticsService? analytics})` creates one `AnalyticsScreenTracker`; `_observers()` gives one new observer to the root `GoRouter` and to **each** `StatefulShellBranch`; passes `_tracker?.tabSelected` to the shell scaffold | ALWAYS (wiring) | route list |
| `lib/core/router/navigator_keys.dart` | `rootNavigatorKey` (+ one key per tab) — tracker reads `rootNavigatorKey.currentContext` for nudges | ALWAYS | tab key names |
| `lib/core/router/app_routes.dart` | `enum AppRoute(path)`; the tracker keys `analyticsScreenNames` by `AppRoute.x.name` | ALWAYS | route names/paths |
| `lib/core/services/katyayani_core/ko_engagement_service.dart` | `abstract interface class KoEngagementService`: init, identify, resetIdentity, requestPushPermission, registerPush, plus the same typed event methods as `AnalyticsService` | MYMALI-SPECIFIC (vendor SDK). Shape reusable as "engagement/push service interface" | — |
| `lib/core/services/katyayani_core/ko_engagement_service_impl.dart` | `KoEngagementServiceImpl`: only file importing `katyayani_core`; `_starting ??= _start()`, `_guard`, `_log`, `_kcItems`, `broadcastTopic = 'all_users'` | MYMALI-SPECIFIC | `KCConfig(siteId:, apiBase:, debug: kDebugMode, enablePush: true, autoRequestPush: false, androidNotificationIcon: LocalNotificationServiceImpl.androidIcon)`; log prefix `[kc]` |
| `lib/core/services/katyayani_core/kc_identity.dart` | `KcIdentity`, `kcIdentityFor(phone:, fullName:, email:)`: RN-app traits, phone-keyed | MYMALI-SPECIFIC | trait keys `name`, `firstName`, `lastName`, `phone`, `country_code`, `phone_number`, `email`; default dial code `'91'` |
| `lib/core/services/local_notifications/local_notification_service.dart` | `abstract interface class LocalNotificationService { Future<void> init(); }` | CONDITIONAL(app receives push) | doc mentions `push_campaigns` |
| `lib/core/services/local_notifications/local_notification_service_impl.dart` | `LocalNotificationServiceImpl`: only file importing `flutter_local_notifications`; creates the Android channel | CONDITIONAL(app receives push) | `pushChannelId = 'push_campaigns'`, `pushChannelName = 'MY Mali'`, `pushSound = 'notification'`, `androidIcon = '@drawable/notification_icon'`, `_ledColor = Color(0xFF163E33)`, vibration `[0, 250, 250, 250]`, log prefix `[notifications]` |
| `lib/core/services/payments/payment_gateway.dart` | `GatewayCheckout`, `GatewayPayment`, `enum GatewayPaymentError`, `GatewayPaymentException`, `abstract interface class PaymentGateway { Future<GatewayPayment> collect(GatewayCheckout); }` | CONDITIONAL(app takes online payments) — generic across gateways | field docs say paise / `+91` / "KO's webhook"; `amountPaise` name is INR-specific (a target app may keep the name as "minor units") |
| `lib/core/services/payments/razorpay_payment_gateway.dart` | `RazorpayPaymentGateway implements PaymentGateway`, `classifyRazorpayError`, `_readable`, `_reasons`; only file importing `razorpay_flutter` | CONDITIONAL(app pays through Razorpay) | `themeColor = '#225542'`; `'currency': 'INR'`; `'retry': {'enabled': false}`; log prefix `[razorpay]` |
| `lib/core/services/kotech/ko_token_service.dart` | `KoTokenService` / `KoTokenServiceImpl`: mint a third-party bearer via an Edge Function, cache until `expirySkew`, share one in-flight mint, `invalidate()` | MYMALI-SPECIFIC (KO-Tech). The caching/sharing/401 pattern is reusable for any "token for a third-party host" | `Endpoints.kotechToken = '/functions/v1/kotech-token'`; body `{'refresh': bool, 'env': KoEnv.name}`; header `{'apikey': anonKey}`; response keys `access_token`, `expires_at`; `expirySkew` 5 min, `fallbackLifetime` 30 min; log prefix `[ko-token]` |
| `lib/core/di/injection_container.dart` (`_registerCore`, `_analyticsDestinations`, bloc factories with `analytics: sl()`) | registrations for all of the above | ALWAYS (shape) | `Env.kcSiteId`, `Env.kcApiUrl`, `Env.fbAppId`, `Env.fbClientToken`, `Env.supabaseAnonKey`, `Env.koEnv`; which blocs take `analytics: sl()` |
| `lib/core/config/env.dart` (the getters this area uses) | `Env.kcSiteId`, `Env.kcApiUrl` (`_require`); `Env.fbAppId`, `Env.fbClientToken` (`_optional`); `Env.razorpayKeyId`, `Env.razorpayMode`, `Env.allowTestPayments`; `Env.koEnv`; `enum KoEnv`, `enum RazorpayMode` | ALWAYS (`Env` + `_require`/`_optional` shape); the specific keys are MYMALI | `.env` key names |
| `lib/core/utils/json_readers.dart` | `asMap`, `asString`, … lenient JSON readers used by `KoTokenServiceImpl` | ALWAYS | — |
| `lib/core/services/networking/networking.dart` (`Networking`, `ApiHost`) | the abstraction `KoTokenServiceImpl` and the 401-retry data sources depend on | ALWAYS (another area owns it) | `ApiHost` values |
| `lib/core/app/api/api_response.dart`, `lib/core/app/exceptions/app_exceptions.dart` | `SuccessResponse`/`ErrorResponse`/`AppException` read by `KoTokenServiceImpl` | ALWAYS (another area owns it) | — |
| `lib/app/app.dart` (the two `RepositoryProvider`s, the KC/analytics `BlocListener<AuthBloc>`, the `BlocListener<ThemeBloc>` track) | composition: how widgets reach the services and where identity is set | ALWAYS (shape) | `AppEvents.themeChanged`, property `theme` |
| `lib/app/bootstrap.dart` | `unawaited(_initEngagement())` (channel then SDK), `unawaited(sl<AnalyticsService>().requestTrackingPermission())`, `AppRouter(analytics: sl<AnalyticsService>())` | ALWAYS (shape) | — |
| `lib/features/home/presentation/home/widgets/push_permission_prompt.dart` | `PushPermissionPrompt`: asks for push once per launch from Home, after the location prompt; calls `KoEngagementService.registerPush()` | CONDITIONAL(app receives push) — the "ask once per launch at a chosen screen" pattern; the KC call is MyMali | `settleDelay` 1 s, `locationWait` 30 s, the `LocationBloc` wait |
| `lib/features/cart/presentation/utils/cart_analytics.dart` | `analyticsItemsFor(List<CartItem>)` → `List<AnalyticsItem>` | ALWAYS pattern (feature helper that maps entities to `AnalyticsItem`) | cart entity names |
| `lib/features/checkout/presentation/review_pay/utils/checkout_analytics.dart` | `paymentMethodName`, `paymentTypeName`, `failureReasonName(Failure)` | ALWAYS pattern ("never raw text; a failure is its type name") | `cod`/`online`, `COD`/`Online`, `upi_timeout` |
| `lib/features/checkout/presentation/review_pay/widgets/review_pay_analytics.dart` | `ReviewPayAnalytics`: a `StatefulWidget` of `BlocListener`s that draws nothing and reports a page's moments once | ALWAYS pattern | event names/properties |
| Call sites read: `login_bloc.dart`, `auth_bloc.dart`, `cart_bloc.dart`, `coupon_bloc.dart`, `wishlist_bloc.dart` (excerpt), `account_page.dart`, `garden_home_page.dart`, `cart_page.dart` (excerpt), `product_detail_page.dart` (excerpt), `order_placed_page.dart` (excerpt), `review_pay_page.dart` (excerpt), `home_page.dart` (excerpt), `app_shell_scaffold.dart` | where events are reported | ALWAYS (patterns), MYMALI (names) | — |
| `lib/features/orders/data/datasources/stockship_remote_data_source.dart`, `ref_order_remote_data_source.dart` (excerpt), `lib/features/checkout/data/datasources/ko_order_remote_data_source.dart` (excerpt) | consumers of `KoTokenService` (the 401 → `invalidate()` → `token(refresh: true)` → retry once pattern) | MYMALI-SPECIFIC hosts; pattern ALWAYS | — |
| `lib/features/checkout/data/repositories/checkout_repository_impl.dart` | the only consumer of `PaymentGateway`; `collectPayment` builds `GatewayCheckout`, maps `GatewayPaymentException` → domain failures (`_paymentFailure`) | MYMALI-SPECIFIC business; the "repository is the only caller of the gateway" rule is ALWAYS | `paymentMerchant = 'Katyayani Organics'`, `paymentDescription = 'Order from My Mali App'`, `(total * 100).round()` paise |
| `test/helpers/fake_ko_engagement_service.dart` | `FakeKoEngagementService implements KoEngagementService` + `registerFakeEngagement()` (registers both `KoEngagementService` and `AnalyticsService`) | MYMALI-SPECIFIC class; ALWAYS pattern ("fake of the core sink, recorded `events`/`tracked`/`screens`") | — |
| `test/helpers/fake_payment_gateway.dart` | `FakePaymentGateway implements PaymentGateway` (`payment`, `error`, `gate`, `checkouts`) | CONDITIONAL(payments) | default ids `pay_01`, `order_01`, `sig_01` |
| `test/helpers/fake_networking.dart` | `FakeNetworking`, `RecordedCall`, `okResponse`, `errorResponse` | ALWAYS (another area owns it) | — |
| `test/helpers/signed_in_app.dart` | `registerSignedInApp({… FakeKoEngagementService? engagement})`, `launchSignedInApp` (pumps `App(router: AppRouter(analytics: sl<AnalyticsService>()).router)`) | ALWAYS (shape) | the fakes list |
| `test/core/services/analytics/multi_destination_analytics_service_test.dart` | `_FakeDestination implements AnalyticsDestination` + fan-out tests | ALWAYS | — |
| `test/core/services/analytics/analytics_event_mapper_test.dart` | mapper tests (GA4 names/params, Meta names/params) | ALWAYS | MyMali names |
| `test/core/services/analytics/meta_analytics_destination_test.dart` | mocks the `facebook_app_events` method channel (`channelName`) | CONDITIONAL(Meta) | — |
| `test/core/services/analytics/ko_analytics_service_test.dart` | every method forwards to the fake core | MYMALI-SPECIFIC | — |
| `test/core/router/analytics_screen_tracker_test.dart` | tracker over a plain `MaterialApp` with `onGenerateRoute` | ALWAYS | screen names |
| `test/core/services/katyayani_core/kc_identity_test.dart` | identity traits | MYMALI-SPECIFIC | — |
| `test/core/services/kotech/ko_token_service_test.dart` | mint/cache/skew/share/invalidate/refuse | MYMALI-SPECIFIC (pattern ALWAYS) | — |
| `test/core/services/payments/razorpay_payment_gateway_test.dart` | `classifyRazorpayError` + `optionsFor` | CONDITIONAL(Razorpay) | — |
| `test/app/app_engagement_test.dart` | identify on restore, reset on sign-out, router reports screens/tabs, Home asks push once | ALWAYS (shape) | — |
| `test/features/cart/presentation/bloc/cart_bloc_analytics_test.dart`, `.../auth/presentation/bloc/auth_login_analytics_test.dart`, `.../coupons/presentation/bloc/coupon_bloc_analytics_test.dart`, `.../wishlist/presentation/bloc/wishlist_bloc_analytics_test.dart` | bloc analytics tests: bloc built directly with `analytics: KoAnalyticsService(core)` over a fake repository | ALWAYS (shape) | — |
| `tool/sync_native_env.dart` | copies `FB_APP_ID`, `FB_CLIENT_TOKEN` from `.env` into `ios/Flutter/Env.xcconfig` | CONDITIONAL(Meta on iOS) — generic "native needs an .env value" tool | `_keys` |
| `android/app/build.gradle.kts` (the `.env` → `resValue` block) | reads `.env` in Gradle; `facebook_app_id`, `facebook_client_token`, `facebook_auto_init` resources; `resValues = true`; core-library desugaring for `flutter_local_notifications` | CONDITIONAL(Meta) / CONDITIONAL(push) | resource names |
| `android/app/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS`, `VIBRATE`; FCM `default_notification_channel_id`=`push_campaigns`, `default_notification_icon`; `com.facebook.sdk.*` meta-data; `<queries>` for `upi:` | CONDITIONAL(push / Meta / UPI payments) | channel id, icon, schemes |
| `android/app/src/main/res/raw/keep.xml` | `tools:keep="@raw/notification,@drawable/notification_icon"` | CONDITIONAL(push) | resource names |
| `android/app/src/main/res/raw/notification.wav`, `res/drawable-xxxhdpi/notification_icon.png`, `res/drawable-night-*/notification_icon.png` | the channel sound and small icon | CONDITIONAL(push) | the assets |
| `ios/Runner/Info.plist` (Facebook keys, `NSUserTrackingUsageDescription`, `LSApplicationQueriesSchemes`, `CFBundleURLTypes fb$(FB_APP_ID)`) | native Meta + ATT + UPI | CONDITIONAL(Meta / payments) | display name `My Mali`, the ATT sentence, scheme list |
| `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` | `#include? "Env.xcconfig"` | CONDITIONAL(Meta on iOS) | — |
| `.env.example` (`KC_API_URL`, `KC_SITE_ID`, `FB_APP_ID`, `FB_CLIENT_TOKEN`, `RAZORPAY_*`, `KO_ENV`) | key names | ALWAYS (file), keys MYMALI | key names |
| `pubspec.yaml` (`firebase_core`, `firebase_analytics`, `facebook_app_events`, `app_tracking_transparency`, `katyayani_core`, `flutter_local_notifications`, `razorpay_flutter`) | package versions | see section 5 | — |

---

## 2. Names

Every public name another app must reproduce exactly (ALWAYS ones first; CONDITIONAL / MYMALI
after, since the skill needs their exact spelling when it installs them).

### Analytics contract (ALWAYS)

| name | kind | file | exact signature / shape |
|---|---|---|---|
| `AnalyticsService` | `abstract interface class` | `lib/core/services/analytics/analytics_service.dart` | see P-2 (full file) |
| `AnalyticsService.track` | method | same | `void track(String name, {Map<String, dynamic>? properties});` |
| `AnalyticsService.screenView` | method | same | `void screenView(String screenName, {Map<String, dynamic>? properties});` |
| `AnalyticsService.viewItem` | method | same | `void viewItem({required List<AnalyticsItem> items, num? value});` |
| `AnalyticsService.addToCart` | method | same | `void addToCart({required List<AnalyticsItem> items, num? value});` |
| `AnalyticsService.removeFromCart` | method | same | `void removeFromCart({required List<AnalyticsItem> items, num? value});` |
| `AnalyticsService.viewCart` | method | same | `void viewCart({required List<AnalyticsItem> items, num? value});` |
| `AnalyticsService.beginCheckout` | method | same | `void beginCheckout({required List<AnalyticsItem> items, num? value, String? coupon});` |
| `AnalyticsService.purchase` | method | same | `void purchase({required String transactionId, required List<AnalyticsItem> items, num? value, num? shipping, String? coupon});` |
| `AnalyticsService.search` | method | same | `void search(String searchTerm);` |
| `AnalyticsService.login` | method | same | `void login({String? method});` |
| `AnalyticsService.addPaymentInfo` | method | same | `void addPaymentInfo({required List<AnalyticsItem> items, num? value, String? paymentType});` |
| `AnalyticsService.capturePayment` | method | same | `void capturePayment(double amount, {String? orderId});` |
| `AnalyticsService.setUserId` | method | same | `void setUserId(String? userId);` |
| `AnalyticsService.requestTrackingPermission` | method | same | `Future<void> requestTrackingPermission();` |
| `AnalyticsService.checkNudges` | method | same | `void checkNudges(BuildContext context, String route);` |
| `AnalyticsItem` | class | `analytics_item.dart` | `const AnalyticsItem({required this.sku, required this.quantity, required this.price, this.name, this.category});` fields `String sku; num quantity; num price; String? name; String? category;` |
| `AppEvents` | `abstract final class` | `app_events.dart` | `static const String <camelCase> = '<Title Case Words>';` (full list in P-3) |
| `AnalyticsDestination` | `abstract interface class` | `analytics_destination.dart` | `void log(String eventName, Map<String, Object?>? properties); void setUserId(String? userId); Future<void> requestTrackingPermission();` |
| `MultiDestinationAnalyticsService` | class `implements AnalyticsService` | `multi_destination_analytics_service.dart` | `const MultiDestinationAnalyticsService({required AnalyticsService core, required List<AnalyticsDestination> destinations})`; private `_send(String name, Map<String, Object?>? properties)`, `_itemProperties(List<AnalyticsItem>)` |
| `Ga4Event` | class | `analytics_event_mapper.dart` | `const Ga4Event(this.name, this.parameters); final String name; final Map<String, Object> parameters;` |
| `MetaEvent` | class | same | `const MetaEvent(this.name, this.parameters, {this.valueToSum, this.isPurchase = false, this.currency = defaultCurrency});` fields `String name; Map<String, Object> parameters; double? valueToSum; bool isPurchase; String currency;` |
| `defaultCurrency` | top-level `const String` | same | `const String defaultCurrency = 'INR';` |
| `ga4NameFor` | top-level function | same | `String ga4NameFor(String eventName) => _ga4Names[eventName] ?? _snake(eventName);` |
| `ga4EventFor` | top-level function | same | `Ga4Event ga4EventFor(String eventName, Map<String, Object?>? properties)` |
| `metaEventFor` | top-level function | same | `MetaEvent metaEventFor(String eventName, Map<String, Object?>? properties)` |
| `AnalyticsScreenTracker` | class | `lib/core/router/analytics_screen_tracker.dart` | `AnalyticsScreenTracker(this._analytics)`; `NavigatorObserver observer()`; `void tabSelected(int index)`; `void routeShown(Route<dynamic> route, {BuildContext? context})`; `static String _screenNameFor(String routeName)`; `static final Set<String> _ignored` |
| `AnalyticsRouteObserver` | class `extends NavigatorObserver` | same | `AnalyticsRouteObserver(this._tracker)`; overrides `didPush`, `didReplace`, `didPop` |
| `analyticsScreenNames` | top-level `const Map<String, String>` | same | route name → dashboard screen name |
| `analyticsTabs` | top-level `const List<AppRoute>` | same | bottom tabs in tab order |
| `AppRouter` | class | `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics}) : _tracker = analytics == null ? null : AnalyticsScreenTracker(analytics);` `List<NavigatorObserver> _observers() => [?_tracker?.observer()];` `late final GoRouter router` |
| `rootNavigatorKey` | top-level `final GlobalKey<NavigatorState>` | `navigator_keys.dart` | `GlobalKey<NavigatorState>(debugLabel: 'root')` |
| `App` provides | `RepositoryProvider<AnalyticsService>`, `RepositoryProvider<KoEngagementService>` | `lib/app/app.dart` | `RepositoryProvider<AnalyticsService>(create: (_) => sl<AnalyticsService>())` |
| `_analyticsDestinations` | private function in DI | `injection_container.dart` | `List<AnalyticsDestination> _analyticsDestinations()` (phones only; Meta only with both credentials) |
| bloc ctor parameter | named optional | `LoginBloc`, `AuthBloc`, `CartBloc`, `WishlistBloc`, `CouponBloc` | `AnalyticsService? analytics` → `final AnalyticsService? _analytics;` doc: "Null reports nothing." |
| `analyticsItemsFor` | top-level function | `lib/features/cart/presentation/utils/cart_analytics.dart` | `List<AnalyticsItem> analyticsItemsFor(List<CartItem> items)` |
| `paymentMethodName`, `paymentTypeName`, `failureReasonName` | top-level functions | `lib/features/checkout/presentation/review_pay/utils/checkout_analytics.dart` | `String paymentMethodName(PaymentMethod)`, `String paymentTypeName(PaymentMethod)`, `String failureReasonName(Failure)` |
| `ReviewPayAnalytics` | `StatefulWidget` | `review_pay/widgets/review_pay_analytics.dart` | `const ReviewPayAnalytics({super.key, required this.child});` |

### Analytics SDK wrappers (CONDITIONAL / MYMALI)

| name | kind | file | exact signature / shape |
|---|---|---|---|
| `FirebaseAnalyticsDestination` | class `implements AnalyticsDestination` | `firebase_analytics_destination.dart` | `FirebaseAnalyticsDestination([FirebaseAnalytics Function()? analytics]) : _analytics = analytics ?? (() => FirebaseAnalytics.instance);` private `_run(String what, Future<void> Function(FirebaseAnalytics) call)`, `_fail(String what, Object error)` |
| `MetaAnalyticsDestination` | class `implements AnalyticsDestination` | `meta_analytics_destination.dart` | `MetaAnalyticsDestination([FacebookAppEvents? facebook]) : _facebook = facebook ?? FacebookAppEvents();` `static const Duration _promptDelay = Duration(seconds: 1);` private `_run(String what, Future<void> Function() call)`, `_fail` |
| `KoAnalyticsService` | class `implements AnalyticsService` | `ko_analytics_service.dart` | `const KoAnalyticsService(this._core); final KoEngagementService _core;` |

### Engagement / push (MYMALI-SPECIFIC; shape reusable)

| name | kind | file | exact signature / shape |
|---|---|---|---|
| `KoEngagementService` | `abstract interface class` | `katyayani_core/ko_engagement_service.dart` | `Future<void> init(); Future<void> identify({required String phone, String? fullName, String? email}); void resetIdentity(); Future<bool> requestPushPermission(); Future<bool> registerPush();` + the same typed event methods as `AnalyticsService` except `setUserId`/`requestTrackingPermission` |
| `KoEngagementServiceImpl` | class | `ko_engagement_service_impl.dart` | `KoEngagementServiceImpl({required String siteId, required String apiBase})`; `static const String broadcastTopic = 'all_users';` private `_started`, `_starting`, `_start()`, `_listen()`, `_guard(String what, void Function() call)`, `static _log(String)`, `static List<KCItem> _kcItems(List<AnalyticsItem>)` |
| `KcIdentity` | class | `kc_identity.dart` | `const KcIdentity({required this.userId, required this.traits}); final String userId; final Map<String, dynamic> traits;` |
| `kcIdentityFor` | top-level function | same | `KcIdentity? kcIdentityFor({required String phone, String? fullName, String? email})` |
| `PushPermissionPrompt` | `StatefulWidget` | `features/home/presentation/home/widgets/push_permission_prompt.dart` | `const PushPermissionPrompt({required this.child, super.key});` `static const Duration settleDelay = Duration(seconds: 1); static const Duration locationWait = Duration(seconds: 30); static bool _asked = false; @visibleForTesting static void resetForTest()` |

### Local notifications (CONDITIONAL(push))

| name | kind | file | exact signature / shape |
|---|---|---|---|
| `LocalNotificationService` | `abstract interface class` | `local_notifications/local_notification_service.dart` | `Future<void> init();` |
| `LocalNotificationServiceImpl` | class | `local_notification_service_impl.dart` | `LocalNotificationServiceImpl([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();` `static const String pushChannelId = 'push_campaigns'; static const String pushChannelName = 'MY Mali'; static const String pushSound = 'notification'; static const String androidIcon = '@drawable/notification_icon'; static const Color _ledColor = Color(0xFF163E33);` |

### Payments (CONDITIONAL(payments); Razorpay impl CONDITIONAL(Razorpay))

| name | kind | file | exact signature / shape |
|---|---|---|---|
| `GatewayCheckout` | class | `payments/payment_gateway.dart` | `const GatewayCheckout({required this.keyId, required this.orderId, required this.amountPaise, required this.merchantName, required this.description, this.contact, this.email});` types `String keyId; String orderId; int amountPaise; String merchantName; String description; String? contact; String? email;` |
| `GatewayPayment` | class | same | `const GatewayPayment({required this.paymentId, required this.orderId, this.signature = ''});` |
| `GatewayPaymentError` | enum | same | `cancelled, upiTimeout, network, insufficientFunds, incorrectOtp, timeout, invalidVpa, cardDeclined, cardExpired, invalidCard, bankDown, limitExceeded, notConfigured, unknown;` getter `bool get isCancellation => this == cancelled \|\| this == upiTimeout;` |
| `GatewayPaymentException` | class `implements Exception` | same | `const GatewayPaymentException(this.error, {this.detail}); final GatewayPaymentError error; final String? detail; toString() => 'GatewayPaymentException($error: $detail)'` |
| `PaymentGateway` | `abstract interface class` | same | `Future<GatewayPayment> collect(GatewayCheckout checkout);` |
| `RazorpayPaymentGateway` | class `implements PaymentGateway` | `razorpay_payment_gateway.dart` | `RazorpayPaymentGateway({Razorpay Function()? newSdk}) : _newSdk = newSdk ?? Razorpay.new;` `static const String themeColor = '#225542';` `static Map<String, dynamic> optionsFor(GatewayCheckout checkout)`; private `Completer<GatewayPayment>? _inFlight`, `static _keyLabel`, `static _trace` |
| `classifyRazorpayError` | top-level function | same | `GatewayPaymentException classifyRazorpayError({int? code, String? message, Map<dynamic, dynamic>? error})` |
| `FakePaymentGateway` | test helper | `test/helpers/fake_payment_gateway.dart` | fields `GatewayPayment payment`, `GatewayPaymentException? error`, `Completer<void>? gate`, `List<GatewayCheckout> checkouts`, getter `lastCheckout` |
| `CheckoutRepositoryImpl.paymentMerchant` / `paymentDescription` | `static const String` | `checkout_repository_impl.dart` | `'Katyayani Organics'`, `'Order from My Mali App'` |

### Third-party token (MYMALI-SPECIFIC; pattern reusable)

| name | kind | file | exact signature / shape |
|---|---|---|---|
| `KoTokenService` | `abstract interface class` | `kotech/ko_token_service.dart` | `Future<String?> token({bool refresh = false}); void invalidate();` |
| `KoTokenServiceImpl` | class | same | `KoTokenServiceImpl({required Networking networking, required String anonKey, required KoEnv env, DateTime Function() now = DateTime.now})`; `static const Duration expirySkew = Duration(minutes: 5); static const Duration fallbackLifetime = Duration(minutes: 30);` private `({String token, DateTime expiresAt})? _cached; Future<String?>? _inFlight; Map<String, String> get _edgeFunctionHeaders => {'apikey': _anonKey}; Future<String?> _mint(bool refresh)` |
| `Endpoints.kotechToken` | `static const String` | `networking/endpoints.dart` | `'/functions/v1/kotech-token'` |

### Env / DI names used here

| name | kind | file | shape |
|---|---|---|---|
| `Env.kcSiteId`, `Env.kcApiUrl` | `static String get` (required) | `env.dart` | `_require('KC_SITE_ID')`, `_require('KC_API_URL')` |
| `Env.fbAppId`, `Env.fbClientToken` | `static String? get` (optional) | same | `_optional('FB_APP_ID')`, `_optional('FB_CLIENT_TOKEN')` |
| `Env.razorpayKeyId`, `Env.razorpayMode`, `Env.allowTestPayments` | getters / `@visibleForTesting static bool` | same | see P-14 |
| `Env.koEnv`, `enum KoEnv { production, beta }`, `enum RazorpayMode { live, test }` | | same | |
| `sl` | `final GetIt sl = GetIt.instance;` | `injection_container.dart` | |
| `configureDependencies()`, `_registerCore()` | functions | same | |

### Test helpers

| name | kind | file | shape |
|---|---|---|---|
| `FakeKoEngagementService` | `implements KoEngagementService` | `test/helpers/fake_ko_engagement_service.dart` | records `identified` (phones), `resetCount`, `initCount`, `events`, `tracked` (`({String name, Map<String, dynamic>? properties})`), `screens`, `registerPushCount` |
| `registerFakeEngagement()` | function | same | registers `KoEngagementService` and `AnalyticsService` (as `KoAnalyticsService(fake)`), returns the fake |
| `registerSignedInApp({… FakeKoEngagementService? engagement})`, `launchSignedInApp(tester)` | functions | `test/helpers/signed_in_app.dart` | |
| `_FakeDestination` | private test class | `multi_destination_analytics_service_test.dart` | `logged`, `users`, `trackingRequests` |

---

## 3. Patterns

### P-1 — "Wrap an SDK behind an interface in `core/services`, register in `get_it`" (the template every sub-area follows)

What to copy (every item below is observed in all four wrappers):

1. Folder `lib/core/services/<name>/`. Interface file `<name>.dart` holding
   `abstract interface class <Name>Service` (or `<Name>Gateway`). Implementation file
   `<name>_impl.dart` (`KoEngagementServiceImpl`, `LocalNotificationServiceImpl`,
   `KoTokenServiceImpl` live in the same or `_impl` file) or `<vendor>_<name>.dart`
   (`RazorpayPaymentGateway`, `firebase_analytics_destination.dart`,
   `meta_analytics_destination.dart`). The doc comment of the impl says literally
   "The only file that imports `<package>`."
2. The impl's constructor takes **the SDK as an optional positional factory/instance with a
   default**, so tests inject a fake without a mocking package:
   `FirebaseAnalyticsDestination([FirebaseAnalytics Function()? analytics])`,
   `MetaAnalyticsDestination([FacebookAppEvents? facebook])`,
   `LocalNotificationServiceImpl([FlutterLocalNotificationsPlugin? plugin])`,
   `RazorpayPaymentGateway({Razorpay Function()? newSdk})`. Configuration values come in as
   named required strings read from `Env` **only in DI**: `KoEngagementServiceImpl({required String siteId, required String apiBase})`,
   `KoTokenServiceImpl({required Networking networking, required String anonKey, required KoEnv env, DateTime Function() now = DateTime.now})`.
3. **Never throws.** Every SDK call goes through a private guard that logs with a bracketed
   prefix and swallows:

```dart
  void _run(String what, Future<void> Function(FirebaseAnalytics) call) {
    if (Firebase.apps.isEmpty) return;
    try {
      unawaited(call(_analytics()).catchError((Object e) => _fail(what, e)));
    } catch (e) {
      _fail(what, e);
    }
  }

  void _fail(String what, Object error) {
    final message = '[ga4] $what failed: $error';
    developer.log(message);
    if (kDebugMode) debugPrint(message);
  }
```

```dart
  /// Runs an SDK call when started; an SDK error never reaches the app.
  void _guard(String what, void Function() call) {
    if (!_started) return;
    try {
      call();
    } catch (e) {
      _log('[kc] $what failed: $e');
    }
  }
```

   Log prefixes in use: `[ga4]`, `[meta]`, `[kc]`, `[notifications]`, `[razorpay]`,
   `[ko-token]`, `[firebase]`, `[checkout]`. Logging is `dart:developer`'s `log` **plus**
   `if (kDebugMode) debugPrint(message)` (so it reaches logcat), as a `static void _log` /
   `_fail` / `_trace`.
4. **Platform gate** where the SDK is phone-only, repeated verbatim in `KoEngagementServiceImpl._start`,
   `LocalNotificationServiceImpl.init`, `bootstrap._initFirebase`, `_analyticsDestinations`:

```dart
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;
```

5. **DI**: one `registerLazySingleton<Interface>(…)` in `_registerCore()`, by the abstract type:

```dart
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
```

6. **Who may call it**: a bloc gets it by constructor (`analytics: sl()` in the bloc factory);
   a widget gets it from a `RepositoryProvider<Interface>` in `app.dart` via
   `context.read<Interface>()` inside a `BlocListener`/tap handler/`addPostFrameCallback`, never
   in `build`; a data source / repository gets it by constructor (`tokens: sl()`, `gateway: sl()`).
   `bootstrap.dart` and `injection_container.dart` are the only places calling `sl<…>()` for these.
7. **Test double**: `test/helpers/fake_<name>.dart` → `class Fake<Name> implements <Interface>`
   with public recording fields (`events`, `tracked`, `checkouts`, …), optional steering fields
   (`error`, `payment`), and optional `Completer<void>? gate` to hold a call open.

### P-2 — The analytics contract (ALWAYS; full file)

`lib/core/services/analytics/analytics_service.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'analytics_item.dart';

/// The events the app reports. Features call this, never an analytics SDK.
abstract interface class AnalyticsService {
  void track(String name, {Map<String, dynamic>? properties});

  void screenView(String screenName, {Map<String, dynamic>? properties});

  void viewItem({required List<AnalyticsItem> items, num? value});

  void addToCart({required List<AnalyticsItem> items, num? value});

  void removeFromCart({required List<AnalyticsItem> items, num? value});

  void viewCart({required List<AnalyticsItem> items, num? value});

  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  });

  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  });

  void search(String searchTerm);

  void login({String? method});

  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  });

  /// Attributes a collected payment's revenue to the install source, as the
  /// React Native app does after an online payment.
  void capturePayment(double amount, {String? orderId});

  /// Ties the events sent to Google Analytics and Meta to the signed-in user,
  /// or to nobody (sign-out) when [userId] is null. Katyayani Core knows the
  /// user through `KoEngagementService.identify`, not through this.
  void setUserId(String? userId);

  /// Asks for the iOS App Tracking Transparency permission and passes the
  /// answer to Meta. Does nothing on Android.
  Future<void> requestTrackingPermission();

  /// Lets Katyayani Core show an in-app nudge set up for [route]. [context]
  /// must sit under the navigator.
  void checkNudges(BuildContext context, String route);
}
```

`lib/core/services/analytics/analytics_item.dart`:

```dart
/// One product line in an analytics event.
class AnalyticsItem {
  const AnalyticsItem({
    required this.sku,
    required this.quantity,
    required this.price,
    this.name,
    this.category,
  });

  final String sku;
  final num quantity;

  /// The price of one unit, in rupees.
  final num price;
  final String? name;
  final String? category;
}
```

`lib/core/services/analytics/analytics_destination.dart`:

```dart
/// A third-party place events are sent to besides Katyayani Core (Google
/// Analytics 4, Meta). Each one wraps one SDK and is the only file that
/// imports it. Every method is safe to call when the SDK is not running: it
/// then does nothing, and never throws.
abstract interface class AnalyticsDestination {
  /// Sends one event by its app name (an `AppEvents` value); the destination
  /// shapes the name and the parameters its own way.
  void log(String eventName, Map<String, Object?>? properties);

  /// Ties the events to the signed-in user, or to nobody when [userId] is null.
  void setUserId(String? userId);

  /// Asks for the iOS App Tracking Transparency permission and tells the
  /// destination the answer. Does nothing on Android and where the
  /// destination has no use for it.
  Future<void> requestTrackingPermission();
}
```

Rule encoded: **two layers**. `AnalyticsService` is the rich, typed API features call (typed
ecommerce calls with `AnalyticsItem` lists, plus `track`). `AnalyticsDestination` is the thin,
untyped sink an extra SDK implements (`log(name, properties)`), so adding a destination never
touches a feature. `track` properties are `Map<String, dynamic>?` on the service and
`Map<String, Object?>?` on the destination (the service passes them straight through).

### P-3 — `AppEvents`: every event name is a `static const` on one `abstract final class` (ALWAYS shape; values MYMALI)

```dart
/// The names of the events the app reports through `AnalyticsService.track`.
///
/// They are the React Native app's `AppEvents` (`services/analytics/events.ts`)
/// word for word, so both apps feed the same Katyayani Core dashboards. Add a
/// name here before using it; never type an event name at a call site.
abstract final class AppEvents {
  // Sign-in and profile.
  static const String loginStarted = 'Login Started';
  static const String login = 'Login';
  static const String otpSent = 'OTP Sent';
  static const String otpResent = 'OTP Resent';
  static const String otpError = 'OTP Error';
  static const String verified = 'Verified';
  static const String profileUpdate = 'Profile Update';
  static const String logout = 'Logout';

  // Navigation.
  static const String navBarIconTapped = 'Nav Bar Icon Tapped';
  static const String screenLoad = 'Screen Load';

  // Cart.
  static const String addToCart = 'Added To Cart';
  static const String removeFromCart = 'Removed From Cart';
  static const String cartVisit = 'Cart Visit';
  static const String productSavedForLater = 'Product Saved For Later';
  static const String productMovedToCart = 'Product Moved To Cart';

  // Wishlist.
  static const String addToFavorite = 'Added To Favorite';
  static const String removeFromFavorite = 'Removed From Favorite';

  // Catalog.
  static const String productView = 'Product View';
  static const String productQuantityChanged = 'Product Quantity Changed';
  static const String productVariantChanged = 'Product Variant Changed';
  static const String viewedAllProducts = 'Viewed All Products';
  static const String categoryIconTapped = 'Category Icon Tapped';
  static const String productSearch = 'Product Search';
  static const String searchResultTapped = 'Search Result Tapped';
  static const String searchNoResults = 'Search No Results';
  static const String cameraSearchTapped = 'Camera Search Tapped';
  static const String filterApplied = 'Filter Applied';
  static const String notifyMeTapped = 'Notify Me Tapped';
  static const String bannerClicked = 'Banner Clicked';

  // Coupons.
  static const String couponApplyTapped = 'Coupon Apply Tapped';
  static const String couponApplied = 'Coupon Applied';
  static const String couponRemoved = 'Coupon Removed';

  // Checkout.
  static const String checkoutStepViewed = 'Checkout Step Viewed';
  static const String checkoutStarted = 'Checkout Started';
  static const String paymentStarted = 'Payment Started';
  static const String paymentSuccessful = 'Payment Successful';
  static const String paymentUnsuccessful = 'Payment Unsuccessful';
  static const String paymentCancelled = 'Payment Cancelled';
  static const String processingOrder = 'Processing Order';
  static const String orderUnsuccessful = 'Order Unsuccessful';
  static const String orderPlaced = 'Order Placed';

  // Addresses.
  static const String changeAddressTapped = 'Change Address Tapped';
  static const String addressChanged = 'Address Changed';
  static const String editAddressTapped = 'Edit Address Tapped';
  static const String addAddressTapped = 'Add Address Tapped';
  static const String addressAdded = 'Address Added';

  // Garden.
  static const String gardenWaitlistJoined = 'Garden Waitlist Joined';

  // Referral.
  static const String referralCodeShared = 'Referral Code Shared';
  static const String referralCodeClaimed = 'Referral Code Claimed';
  static const String referralClaimFailed = 'Referral Claim Failed';

  // Support.
  static const String supportChannelTapped = 'Support Channel Tapped';
  static const String callButtonTapped = 'Call Button Tapped';

  // Orders.
  static const String orderOpened = 'Order Opened';
  static const String orderFilterChanged = 'Order Filter Changed';
  static const String buyAgainTapped = 'Buy Again Tapped';
  static const String invoiceDownloaded = 'Invoice Downloaded';
  static const String orderHelpTapped = 'Order Help Tapped';
  static const String orderRated = 'Order Rated';

  // Account.
  static const String accountMenuTapped = 'Account Menu Item Tapped';
  static const String avatarUpdated = 'Avatar Updated';
  static const String editProfileTapped = 'Edit Profile Tapped';
  static const String themeChanged = 'Theme Changed';
}
```

Rule: names are **Title Case with spaces** (the primary dashboard's convention); the identifier
is camelCase of the words (`accountMenuTapped = 'Account Menu Item Tapped'` is the one that is
not a 1:1 transliteration); grouped by feature with a `// Comment.` header. Property keys at call
sites are snake_case (`item_id`, `item_name`, `price`, `quantity`, `currency`, `value`, `amount`,
`items_count`, `order_id`, `search_term`, `screen_name`, `tab`, `code`, `discount`, `stage`,
`reason`, `channel`, `method`, `payment_method`, `step`, `total`, `theme`, `item`, `source`,
`title`, `cta_link`, `rating`). What varies: every value, the groups.

### P-4 — `MultiDestinationAnalyticsService`: fan-out + "no double counting" (ALWAYS; full file)

```dart
import 'package:flutter/widgets.dart';

import 'analytics_destination.dart';
import 'analytics_item.dart';
import 'analytics_service.dart';
import 'analytics_event_mapper.dart';
import 'app_events.dart';

/// The one [AnalyticsService] the app uses: every event goes to Katyayani
/// Core ([_core]) and to each [AnalyticsDestination] (Google Analytics 4 and
/// Meta), so no screen or bloc ever calls an SDK.
///
/// `track` sends the event under its app name to every destination, and each
/// destination shapes the name and parameters its own way
/// (`analytics_event_mapper.dart`).
///
/// The typed calls (`addToCart`, `viewItem`, …) are Katyayani Core's
/// ecommerce events, with its item lists. Only three of them also have a
/// plain event the other destinations need and nothing else sends:
/// `addToCart` ("Added To Cart"), `removeFromCart` ("Removed From Cart") and
/// `search` ("Product Search"). The rest (`viewItem`, `viewCart`,
/// `beginCheckout`, `addPaymentInfo`, `purchase`, `login`, `screenView`) are
/// always sent beside a `track` of the same moment ("Product View", "Cart
/// Visit", "Checkout Started", "Payment Started", "Order Placed", "Login",
/// "Screen Load"), so they stay with Katyayani Core: forwarding them too
/// would count the moment twice.
class MultiDestinationAnalyticsService implements AnalyticsService {
  const MultiDestinationAnalyticsService({
    required AnalyticsService core,
    required List<AnalyticsDestination> destinations,
  }) : _core = core,
       _destinations = destinations;

  final AnalyticsService _core;
  final List<AnalyticsDestination> _destinations;

  @override
  void track(String name, {Map<String, dynamic>? properties}) {
    _core.track(name, properties: properties);
    _send(name, properties);
  }

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      _core.screenView(screenName, properties: properties);

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      _core.viewItem(items: items, value: value);

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) {
    _core.addToCart(items: items, value: value);
    _send(AppEvents.addToCart, _itemProperties(items));
  }

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) {
    _core.removeFromCart(items: items, value: value);
    _send(AppEvents.removeFromCart, _itemProperties(items));
  }

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) =>
      _core.viewCart(items: items, value: value);

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => _core.beginCheckout(items: items, value: value, coupon: coupon);

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => _core.purchase(
    transactionId: transactionId,
    items: items,
    value: value,
    shipping: shipping,
    coupon: coupon,
  );

  @override
  void search(String searchTerm) {
    _core.search(searchTerm);
    _send(AppEvents.productSearch, {'search_term': searchTerm});
  }

  @override
  void login({String? method}) => _core.login(method: method);

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => _core.addPaymentInfo(
    items: items,
    value: value,
    paymentType: paymentType,
  );

  @override
  void capturePayment(double amount, {String? orderId}) =>
      _core.capturePayment(amount, orderId: orderId);

  @override
  void checkNudges(BuildContext context, String route) =>
      _core.checkNudges(context, route);

  @override
  void setUserId(String? userId) {
    _core.setUserId(userId);
    for (final destination in _destinations) {
      destination.setUserId(userId);
    }
  }

  @override
  Future<void> requestTrackingPermission() async {
    await _core.requestTrackingPermission();
    await Future.wait([
      for (final destination in _destinations)
        destination.requestTrackingPermission(),
    ]);
  }

  void _send(String name, Map<String, Object?>? properties) {
    for (final destination in _destinations) {
      destination.log(name, properties);
    }
  }

  /// The first line's fields, as the cart events carry them. Money is the
  /// price of one unit; the quantity says how many.
  Map<String, Object?> _itemProperties(List<AnalyticsItem> items) {
    if (items.isEmpty) return const {};
    final item = items.first;
    return {
      'item_id': item.sku,
      'item_name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'currency': defaultCurrency,
    };
  }
}
```

Rule: the **core** is itself an `AnalyticsService` (so the wrapper can delegate every method
1:1); destinations receive **only** `track` plus the three typed calls that have no `track`
twin. `setUserId` and `requestTrackingPermission` go to core and every destination.
**How a new destination is added:** write `class XDestination implements AnalyticsDestination`
(only file importing SDK X; `log` maps the `AppEvents` name through a pure mapper function;
guard + `_fail`), add it to the list returned by `_analyticsDestinations()` in DI. Nothing in
`MultiDestinationAnalyticsService`, `AppEvents`, blocs or pages changes.
**What a target app with a different primary SDK does:** if its SDK is "just another sink"
(Mixpanel, Amplitude, Segment, Firebase-only) it implements `AnalyticsDestination`, and passes
as `core:` either an `AnalyticsService` for its primary SDK (shape of `KoAnalyticsService`:
every method one forwarding expression, `setUserId`/`requestTrackingPermission` no-ops) or a
no-op `AnalyticsService` when it has none. It does **not** install `KoEngagementService`,
`KoAnalyticsService`, `kc_identity.dart` or `katyayani_core`. With a no-op core,
`screenView`, `viewItem`, `viewCart`, `beginCheckout`, `addPaymentInfo`, `purchase`, `login`,
`capturePayment`, `checkNudges` reach nothing: the target app must then either forward them to
its destinations (and remove the paired `track` call sites) or accept that only `track` events
reach the sinks. Record that decision as an open question (section 7 / JSON).

### P-5 — The mapper: pure Dart naming rules per destination (ALWAYS for GA4; full file)

```dart
import 'app_events.dart';

/// One event as Google Analytics 4 (Firebase Analytics) takes it.
class Ga4Event {
  const Ga4Event(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}

/// One event as Meta (Facebook) App Events takes it.
class MetaEvent {
  const MetaEvent(
    this.name,
    this.parameters, {
    this.valueToSum,
    this.isPurchase = false,
    this.currency = defaultCurrency,
  });

  /// Meta's standard event name where there is one, else the app's own.
  final String name;
  final Map<String, Object> parameters;

  /// The money (or rating) the event carries. Meta reads it as the
  /// `valueToSum` argument; a `_valueToSum` parameter key is ignored.
  final double? valueToSum;

  /// Whether it is sent with `logPurchase`, which logs Meta's standard
  /// Purchase with its revenue. The only event that is.
  final bool isPurchase;
  final String currency;
}

const String defaultCurrency = 'INR';

/// GA4's own names for the events it has a recommended event for; GA4 only
/// builds its ecommerce reports from these exact names. Anything else gets
/// its name derived by [ga4NameFor].
const Map<String, String> _ga4Names = {
  AppEvents.login: 'login_completed',
  AppEvents.verified: 'login',
  AppEvents.addToCart: 'add_to_cart',
  AppEvents.removeFromCart: 'remove_from_cart',
  AppEvents.addToFavorite: 'add_to_wishlist',
  AppEvents.productView: 'view_item',
  AppEvents.productSearch: 'search',
  AppEvents.checkoutStarted: 'begin_checkout',
  AppEvents.paymentStarted: 'add_payment_info',
  AppEvents.orderPlaced: 'purchase',
  AppEvents.orderRated: 'order_rated',
};

/// Meta's standard names for the events it has one for. Meta optimises ads
/// and builds audiences only from its standard events. "Order Placed" is not
/// here on purpose: it goes through `logPurchase`, and mapping it as well
/// would log Purchase twice.
const Map<String, String> _metaStandardNames = {
  AppEvents.verified: 'fb_mobile_complete_registration',
  AppEvents.addToCart: 'fb_mobile_add_to_cart',
  AppEvents.addToFavorite: 'fb_mobile_add_to_wishlist',
  AppEvents.productView: 'fb_mobile_content_view',
  AppEvents.productSearch: 'fb_mobile_search',
  AppEvents.checkoutStarted: 'fb_mobile_initiated_checkout',
  AppEvents.paymentStarted: 'fb_mobile_add_payment_info',
  AppEvents.orderRated: 'fb_mobile_rate',
};

const int _maxNameLength = 40;
const int _maxValueLength = 100;
const int _maxRating = 5;

/// GA4's name for [eventName]: lowercase snake_case, at most 40 characters,
/// no spaces ("Added To Cart" becomes `added_to_cart`).
String ga4NameFor(String eventName) =>
    _ga4Names[eventName] ?? _snake(eventName);

/// [eventName] as GA4 takes it, with its parameters cleaned: snake_case keys,
/// text cut to 100 characters, only text and numbers, no nulls. When the
/// event carries `value` or `amount`, GA4 also gets `value` and `currency`.
Ga4Event ga4EventFor(String eventName, Map<String, Object?>? properties) {
  final parameters = <String, Object>{};
  _scalars(properties).forEach((key, value) {
    final name = _snake(key);
    if (name.isEmpty) return;
    parameters[name] = value is String && value.length > _maxValueLength
        ? value.substring(0, _maxValueLength)
        : value;
  });
  final money = _moneyOf(properties);
  if (money != null) {
    parameters['value'] = money;
    parameters['currency'] = _currencyOf(properties);
  }
  return Ga4Event(ga4NameFor(eventName), parameters);
}

/// [eventName] as Meta takes it: its standard name where it has one, the
/// money as `valueToSum`, and the product and special-case parameters the
/// standard events ask for.
MetaEvent metaEventFor(String eventName, Map<String, Object?>? properties) {
  final standard = _metaStandardNames[eventName];
  final name = _clip(standard ?? eventName);
  final parameters = <String, Object>{..._scalars(properties)};
  final currency = _currencyOf(properties);
  double? valueToSum = _moneyOf(properties);

  if (valueToSum != null) parameters['fb_currency'] = currency;

  final itemId = properties?['item_id'];
  if (itemId is String || itemId is num) {
    parameters['fb_content_id'] = '$itemId';
    parameters['fb_content_type'] = 'product';
  }

  switch (eventName) {
    case AppEvents.productSearch:
      final term = properties?['search_term'];
      if (term is String) parameters['fb_search_string'] = term;
    case AppEvents.orderRated:
      parameters['fb_max_rating_value'] = _maxRating;
      final rating = properties?['rating'];
      if (rating is num) valueToSum = rating.toDouble();
      parameters['fb_content_type'] = 'order';
    case AppEvents.paymentStarted:
      parameters['fb_success'] = 1;
  }

  if (eventName == AppEvents.orderPlaced) {
    return MetaEvent(
      name,
      parameters,
      valueToSum: valueToSum ?? 0,
      isPurchase: true,
      currency: currency,
    );
  }
  return MetaEvent(
    name,
    parameters,
    valueToSum: valueToSum,
    currency: currency,
  );
}

/// The text and numbers in [properties]. Booleans become 1 and 0, a list of
/// them is joined with commas, and nulls and anything else are left out.
Map<String, Object> _scalars(Map<String, Object?>? properties) {
  final out = <String, Object>{};
  if (properties == null) return out;
  properties.forEach((key, value) {
    final scalar = _scalar(value);
    if (scalar != null) {
      out[key] = scalar;
    } else if (value is Iterable) {
      final parts = [for (final item in value) ?_scalar(item)];
      if (parts.isNotEmpty) out[key] = parts.join(',');
    }
  });
  return out;
}

Object? _scalar(Object? value) => switch (value) {
  String() || num() => value,
  bool() => value ? 1 : 0,
  _ => null,
};

double? _moneyOf(Map<String, Object?>? properties) {
  final raw = properties?['value'] ?? properties?['amount'];
  return raw is num ? raw.toDouble() : null;
}

String _currencyOf(Map<String, Object?>? properties) {
  final raw = properties?['currency'];
  return raw is String && raw.isNotEmpty ? raw : defaultCurrency;
}

String _snake(String text) => _clip(
  text
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), ''),
);

String _clip(String text) =>
    text.length > _maxNameLength ? text.substring(0, _maxNameLength) : text;
```

Rules encoded (all tested in `analytics_event_mapper_test.dart`):
- GA4 name: table hit, else `_snake` (camelCase split, lowercase, non-alphanumerics → `_`,
  trimmed), **cut to 40 chars**. Keys snake_cased too; values: text cut to 100; `bool` → 1/0;
  `Iterable` → comma-joined scalars; `null`/maps dropped. `value` **or** `amount` (num) →
  `value` (double) + `currency` (default `'INR'`).
- Meta name: table hit (`fb_mobile_*`), else the name **as written** (spaces kept), clipped to
  40. Money → `valueToSum` argument + `fb_currency` param (never a `_valueToSum` key);
  `item_id` → `fb_content_id` + `fb_content_type: 'product'`; `search_term` →
  `fb_search_string`; rating → `valueToSum` + `fb_max_rating_value: 5` + `fb_content_type: 'order'`;
  `paymentStarted` → `fb_success: 1`; `orderPlaced` → `isPurchase: true`, `valueToSum ?? 0`.
- The mapper imports only `app_events.dart` (pure Dart, no Flutter) so it is unit-tested with
  plain `test()`.
What varies per app: both name tables (keys are the app's `AppEvents`; values are the vendor's
recommended names), `defaultCurrency`, the special cases.

### P-6 — A destination (CONDITIONAL; both full files)

`firebase_analytics_destination.dart`:

```dart
import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'analytics_destination.dart';
import 'analytics_event_mapper.dart';

/// Google Analytics 4 through Firebase Analytics. The only file that imports
/// `firebase_analytics`.
///
/// It sends nothing until Firebase has started (`bootstrap.dart`), so a build
/// without `google-services.json` runs without it.
class FirebaseAnalyticsDestination implements AnalyticsDestination {
  FirebaseAnalyticsDestination([FirebaseAnalytics Function()? analytics])
    : _analytics = analytics ?? (() => FirebaseAnalytics.instance);

  final FirebaseAnalytics Function() _analytics;

  @override
  void log(String eventName, Map<String, Object?>? properties) {
    final event = ga4EventFor(eventName, properties);
    _run('logEvent ${event.name}', (analytics) {
      return analytics.logEvent(
        name: event.name,
        parameters: event.parameters.isEmpty ? null : event.parameters,
      );
    });
  }

  @override
  void setUserId(String? userId) =>
      _run('setUserId', (analytics) => analytics.setUserId(id: userId));

  @override
  Future<void> requestTrackingPermission() async {}

  void _run(String what, Future<void> Function(FirebaseAnalytics) call) {
    if (Firebase.apps.isEmpty) return;
    try {
      unawaited(call(_analytics()).catchError((Object e) => _fail(what, e)));
    } catch (e) {
      _fail(what, e);
    }
  }

  void _fail(String what, Object error) {
    final message = '[ga4] $what failed: $error';
    developer.log(message);
    if (kDebugMode) debugPrint(message);
  }
}
```

`meta_analytics_destination.dart`:

```dart
import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import 'analytics_destination.dart';
import 'analytics_event_mapper.dart';

/// Meta (Facebook) App Events. The only file that imports
/// `facebook_app_events` and `app_tracking_transparency`.
///
/// Create it only when the Meta app id and client token are set
/// (`Env.fbAppId`, `Env.fbClientToken`): the native SDK needs both and fails
/// without them. `bootstrap`'s dependency setup leaves it out otherwise.
class MetaAnalyticsDestination implements AnalyticsDestination {
  MetaAnalyticsDestination([FacebookAppEvents? facebook])
    : _facebook = facebook ?? FacebookAppEvents();

  /// Android needs no prompt, and iOS shows its own only once.
  static const Duration _promptDelay = Duration(seconds: 1);

  final FacebookAppEvents _facebook;

  @override
  void log(String eventName, Map<String, Object?>? properties) {
    final event = metaEventFor(eventName, properties);
    if (event.isPurchase) {
      // Purchase has its own call, with the revenue. It is not also sent as
      // an event, or Meta would count it twice.
      _run(
        'logPurchase',
        () => _facebook.logPurchase(
          amount: event.valueToSum ?? 0,
          currency: event.currency,
          parameters: event.parameters,
        ),
      );
      return;
    }
    _run(
      'logEvent ${event.name}',
      () => _facebook.logEvent(
        name: event.name,
        parameters: event.parameters.isEmpty ? null : event.parameters,
        valueToSum: event.valueToSum,
      ),
    );
  }

  @override
  void setUserId(String? userId) => _run(
    'setUserId',
    () =>
        userId == null ? _facebook.clearUserID() : _facebook.setUserID(userId),
  );

  /// iOS 14.5+: asks for the App Tracking Transparency permission and tells
  /// Meta whether it may collect the advertising id. Android has nothing to
  /// ask.
  @override
  Future<void> requestTrackingPermission() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      // The prompt only shows once the app is active.
      await Future<void>.delayed(_promptDelay);
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      await _facebook.setAdvertiserIdCollectionEnabled(
        status == TrackingStatus.authorized,
      );
    } catch (e) {
      _fail('requestTrackingPermission', e);
    }
  }

  void _run(String what, Future<void> Function() call) {
    try {
      unawaited(call().catchError((Object e) => _fail(what, e)));
    } catch (e) {
      _fail(what, e);
    }
  }

  void _fail(String what, Object error) {
    final message = '[meta] $what failed: $error';
    developer.log(message);
    if (kDebugMode) debugPrint(message);
  }
}
```

Rule: `log` = `mapper(eventName, properties)` → one SDK call through `_run`; `setUserId(null)`
clears; `requestTrackingPermission` is a no-op where the SDK has no use for it (GA4) and
platform-gated to iOS where it has (Meta). Destinations are created only when they can run:

```dart
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

Test double shape (from `multi_destination_analytics_service_test.dart`):

```dart
class _FakeDestination implements AnalyticsDestination {
  final List<({String name, Map<String, Object?>? properties})> logged = [];
  final List<String?> users = [];
  int trackingRequests = 0;

  @override
  void log(String eventName, Map<String, Object?>? properties) =>
      logged.add((name: eventName, properties: properties));

  @override
  void setUserId(String? userId) => users.add(userId);

  @override
  Future<void> requestTrackingPermission() async => trackingRequests++;
}
```

Meta's destination test mocks the plugin's method channel instead of injecting a fake:

```dart
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), (
          call,
        ) async {
          calls.add(call);
          return null;
        });
    meta = MetaAnalyticsDestination();
```

(`channelName` is exported by `package:facebook_app_events`.) It asserts `['logPurchase']` for
`orderPlaced`, `arguments['_valueToSum']` for a value event, `['setUserID', 'clearUserID']`, and
that a `PlatformException` from the channel never reaches the caller.

### P-7 — The "core" `AnalyticsService` that wraps the primary SDK (MYMALI; shape ALWAYS)

```dart
class KoAnalyticsService implements AnalyticsService {
  const KoAnalyticsService(this._core);

  final KoEngagementService _core;

  @override
  void track(String name, {Map<String, dynamic>? properties}) =>
      _core.track(name, properties: properties);
  // … every other typed method is one forwarding expression …

  @override
  void setUserId(String? userId) {}

  @override
  Future<void> requestTrackingPermission() async {}

  @override
  void checkNudges(BuildContext context, String route) =>
      _core.checkNudges(context, route);
}
```

Rule: the core knows the user by its own means (`KoEngagementService.identify` by phone), so
`setUserId` is a no-op there; tracking permission belongs to destinations. The same object is
what tests register as the whole `AnalyticsService` (`registerFakeEngagement()` →
`sl.registerSingleton<AnalyticsService>(KoAnalyticsService(fake))`), so widget tests never
construct GA4/Meta.

### P-8 — Router-driven screen tracking (ALWAYS; full file)

```dart
import 'package:flutter/widgets.dart';

import '../services/analytics/analytics_service.dart';
import '../services/analytics/app_events.dart';
import 'app_routes.dart';
import 'navigator_keys.dart';

/// The name a screen is reported under: the React Native app's screen names,
/// so both apps fill the same dashboards. A route not listed here is
/// reported by its own name.
const Map<String, String> analyticsScreenNames = {
  'login': 'PhoneEntry',
  'home': 'ShopTab',
  'categories': 'CategoriesTab',
  'garden': 'GardenTab',
  'wishlist': 'WishlistTab',
  'account': 'ProfileTab',
  'cart': 'Cart',
  'selectLocation': 'Location',
  'coins': 'MaliCoins',
  'reviewPay': 'ReviewPay',
  'orderPlaced': 'OrderConfirmation',
  'invoice': 'Invoice',
  'applyCoupon': 'Coupons',
  'savedAddresses': 'AddressList',
  'addressForm': 'AddressForm',
  'editProfile': 'EditProfile',
  'referral': 'Referral',
  'gstClaims': 'GstClaim',
  'helpSupport': 'Support',
  'productDetail': 'ProductDetail',
  'myOrders': 'Orders',
  'orderDetails': 'OrderDetail',
};

/// The bottom-navigation tabs, in tab order.
const List<AppRoute> analyticsTabs = [
  AppRoute.home,
  AppRoute.categories,
  AppRoute.garden,
  AppRoute.wishlist,
  AppRoute.account,
];

/// Reports every screen the user lands on, once.
///
/// Fed by [AnalyticsRouteObserver] (pushes, replaces and pops) and by the
/// bottom bar ([tabSelected]): the tabs live in an `IndexedStack`, so
/// switching back to a tab already visited pushes nothing the observers could
/// see. The same screen twice in a row is reported once.
class AnalyticsScreenTracker {
  AnalyticsScreenTracker(this._analytics);

  final AnalyticsService _analytics;

  /// Route names that are not screens.
  static final Set<String> _ignored = {AppRoute.splash.name};

  /// The route name last reported.
  String? _current;

  /// The route name of the tab on show, to report again when a pushed page
  /// is popped back to the tab.
  String? _tab;

  /// A new observer for one navigator. A [NavigatorObserver] can serve only
  /// one navigator, and the root and each tab have their own.
  NavigatorObserver observer() => AnalyticsRouteObserver(this);

  /// The user tapped the bottom bar's [index]th tab.
  void tabSelected(int index) {
    if (index < 0 || index >= analyticsTabs.length) return;
    final route = analyticsTabs[index];
    _analytics.track(
      AppEvents.navBarIconTapped,
      properties: {'tab': _screenNameFor(route.name)},
    );
    _show(route.name, rootNavigatorKey.currentContext);
  }

  /// A page route was pushed, replaced in, or came back on top after a pop.
  void routeShown(Route<dynamic> route, {BuildContext? context}) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) {
      // The tabs' shell: back at the tab that was on show.
      final tab = _tab;
      if (tab != null) _show(tab, context);
      return;
    }
    _show(name, context);
  }

  void _show(String name, BuildContext? context) {
    if (_ignored.contains(name)) return;
    if (analyticsTabs.any((tab) => tab.name == name)) _tab = name;
    if (name == _current) return;
    _current = name;
    final screen = _screenNameFor(name);
    _analytics
      ..screenView(screen)
      ..track(AppEvents.screenLoad, properties: {'screen_name': screen});
    if (context != null) {
      // After the frame, so a nudge never opens in the middle of a build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _analytics.checkNudges(context, '/$screen');
      });
    }
  }

  static String _screenNameFor(String routeName) =>
      analyticsScreenNames[routeName] ?? routeName;
}

/// A go_router observer that tells an [AnalyticsScreenTracker] which screen
/// is on top. Pages opened by `GoRoute` carry the route's `name`.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._tracker);

  final AnalyticsScreenTracker _tracker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _tracker.routeShown(route, context: navigator?.context);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _tracker.routeShown(newRoute, context: navigator?.context);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // A sheet or dialog closing leaves the screen under it unchanged.
    if (route is! PageRoute || previousRoute == null) return;
    _tracker.routeShown(previousRoute, context: navigator?.context);
  }
}
```

Wiring in `AppRouter`:

```dart
  AppRouter({AnalyticsService? analytics})
    : _tracker = analytics == null ? null : AnalyticsScreenTracker(analytics);

  final AnalyticsScreenTracker? _tracker;

  /// One observer per navigator: the root and each tab have their own.
  List<NavigatorObserver> _observers() => [?_tracker?.observer()];

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: _observers(),
    …
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShellScaffold(
          navigationShell: navigationShell,
          onTabSelected: _tracker?.tabSelected,
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            observers: _observers(),
            routes: [ GoRoute(path: AppRoute.home.path, name: AppRoute.home.name, …) ],
          ),
          … one branch per tab, each with `observers: _observers()` …
```

and in `AppShellScaffold.onTap`:

```dart
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
            onTabSelected?.call(index);
          },
```

`bootstrap.dart`: `runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router));`
and tests: `App(router: AppRouter(analytics: sl<AnalyticsService>()).router)`.

Rules: pages never call `screenView`; every `GoRoute` has a `name:` (= `AppRoute.x.name`);
only `PageRoute`s count (dialogs/sheets ignored on push and pop); the unnamed shell route means
"back to `_tab`"; same name twice in a row is reported once (so `pushReplacementNamed` of the
same route is silent, but `tabSelected` of the current tab still tracks the tap); splash is in
`_ignored`; nudges are checked after the frame with `'/$screen'`; `tabSelected` validates the
index. The tracker test pumps a bare `MaterialApp(navigatorKey:, navigatorObservers: [tracker.observer()], initialRoute: AppRoute.splash.name, onGenerateRoute: …MaterialPageRoute(settings: settings…))`
— no go_router needed to test it.

### P-9 — Call sites: where events are reported (ALWAYS patterns)

**(a) A bloc takes `AnalyticsService? analytics` (optional, nullable, documented "Null reports nothing") and reports where intent is known** — `LoginBloc`:

```dart
  LoginBloc({
    required SendOtp sendOtp,
    required VerifyOtp verifyOtp,
    AnalyticsService? analytics,
  }) : _sendOtp = sendOtp,
       _verifyOtp = verifyOtp,
       _analytics = analytics,
       super(const LoginState()) {
```
```dart
  /// Reports the steps of signing in. Null reports nothing.
  final AnalyticsService? _analytics;
```
```dart
    final result = await _sendOtp(request);
    if (result.isRight()) _lastSubmittedOtp = null;
    result.match(
      (failure) => _analytics?.track(
        AppEvents.otpError,
        properties: {
          'stage': resend ? 'resend' : 'send',
          'reason': failure.runtimeType.toString(),
        },
      ),
      (_) => _analytics?.track(
        resend ? AppEvents.otpResent : AppEvents.otpSent,
        properties: resend ? null : {'channel': 'sms'},
      ),
    );
```
```dart
    final result = await _verifyOtp(request);
    result.match(
      (failure) => _analytics?.track(
        AppEvents.otpError,
        properties: {
          'stage': 'verify',
          'reason': failure.runtimeType.toString(),
        },
      ),
      (_) => _analytics
        ?..track(AppEvents.verified)
        ..track(AppEvents.login, properties: {'method': 'phone_otp'}),
    );
```

`AuthBloc` reports **before** the session ends: `_analytics?.track(AppEvents.logout); emit(const AuthLoading()); final result = await _signOut(const NoParams());`.

`CartBloc` derives the typed event from a quantity delta (only the first unit added is not also a
quantity change; a line stepped to zero is a removal only):

```dart
  /// Reports the change from [before] units of [item] to what the cart holds
  /// now: units added or removed, and a quantity change when the line stays.
  void _reportQuantity(CartItem item, int before) {
    final analytics = _analytics;
    if (analytics == null) return;
    final after = state.quantityOf(item.variantId);
    final delta = after - before;
    if (delta == 0) return;
    final items = [
      AnalyticsItem(
        sku: item.variantId,
        quantity: delta.abs(),
        price: item.unitPrice,
        name: item.title,
      ),
    ];
    if (delta > 0) {
      analytics.addToCart(items: items);
    } else {
      analytics.removeFromCart(items: items);
    }
    if (before > 0 && after > 0) {
      analytics.track(
        AppEvents.productQuantityChanged,
        properties: {'item_id': item.variantId, 'quantity': after},
      );
    }
  }
```

`CouponBloc` reports the tap before the check and the apply only if the coupon was kept
(`AppEvents.couponApplyTapped {'code': event.code.trim().toUpperCase()}`, then
`AppEvents.couponApplied {'code': kept.coupon.code, 'discount': kept.discount}`,
`AppEvents.couponRemoved` only when something was applied). `WishlistBloc` reports
`wasSaved ? AppEvents.removeFromFavorite : AppEvents.addToFavorite` with `{'item_id': id}` only
when the device write succeeded. DI: `registerFactory(() => LoginBloc(sendOtp: sl(), verifyOtp: sl(), analytics: sl()))`.
Tests build the bloc directly with `analytics: KoAnalyticsService(core)` over a fake repository
and assert `core.tracked.map((e) => e.name)` / `core.events`.

**(b) A page tap handler** (`AccountPage`): read the service inside the callback, report, then act.

```dart
    // Every menu tap is reported with the row's id, then acted on.
    void tapped(String item, VoidCallback action) {
      context.read<AnalyticsService>().track(
        AppEvents.accountMenuTapped,
        properties: {'item': item},
      );
      action();
    }
```
```dart
          onEditProfile: () {
            context.read<AnalyticsService>().track(AppEvents.editProfileTapped);
            push(AppRoute.editProfile);
          },
```

**(c) A `BlocListener` with a precise `listenWhen`** (`GardenHomePage`):

```dart
    return BlocListener<GardenBloc, GardenState>(
      // The user has just joined the list.
      listenWhen: (previous, current) =>
          !previous.isOnWaitlist && current.isOnWaitlist,
      listener: (context, state) {
        context.read<AnalyticsService>().track(
          AppEvents.gardenWaitlistJoined,
          properties: {'source': 'garden_home'},
        );
        _showOnTheList(context);
      },
```

A page with several moments wraps them in a draw-nothing `StatefulWidget` of listeners
(`ReviewPayAnalytics`): `listenWhen: previous.quote == null && current.quote != null` →
`_onBill` (guarded by `bool _billReported`), `!previous.isPlacing && current.isPlacing` →
`_onProcessing`, `current.placeFailure != null && current.placeFailure != previous.placeFailure`
→ `_onFailure`, which branches on the failure **type** and reports `failureReasonName(failure)`.

**(d) "Once per visit" with state that may already be loaded** (`CartPage`, `ProductDetailPage`, `OrderPlacedPage`):

```dart
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    // The cart may already be loaded when the page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportOpened(context.read<CartBloc>().state);
    });
  }

  /// Reports the cart once per visit, when it first has something in it.
  void _reportOpened(CartState cart) {
    if (_opened || cart.items.isEmpty) return;
    _opened = true;
    final items = analyticsItemsFor(cart.items);
    final properties = {
      'items_count': cart.totalQuantity,
      'value': cart.subtotal,
    };
    context.read<AnalyticsService>()
      ..viewCart(items: items, value: cart.subtotal)
      ..track(
        AppEvents.cartVisit,
        properties: {...properties, 'currency': 'INR'},
      )
      ..track(
        AppEvents.checkoutStepViewed,
        properties: {'step': 'your_cart', ...properties},
      );
  }
```
plus `BlocListener<CartBloc, CartState>(listenWhen: (p, c) => p.items.isEmpty && c.items.isNotEmpty, listener: (context, state) => _reportOpened(state))`.
Across route rebuilds the guard is a static set: `@visibleForTesting static final Set<String> reportedOrders = {};` and `if (!OrderPlacedPage.reportedOrders.add(key)) return;`.
Note the **typed call + `track` pair** at the same moment (`viewCart` + `cartVisit`, `viewItem` + `productView`, `beginCheckout` + `checkoutStarted`, `addPaymentInfo` + `paymentStarted`, `purchase` + `orderPlaced`): that is why `MultiDestination…` forwards only `addToCart`/`removeFromCart`/`search`.

**(e) `app.dart`: identity and sign-out** — a `BlocListener<AuthBloc, AuthState>` whose
`listenWhen` fires on sign-in, on any user change (profile edit) and on the first `Unauthenticated`:

```dart
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
```

and an app-wide bloc change reported from `app.dart` too:

```dart
          BlocListener<ThemeBloc, ThemeState>(
            listenWhen: (previous, current) => previous.mode != current.mode,
            listener: (context, state) =>
                context.read<AnalyticsService>().track(
                  AppEvents.themeChanged,
                  properties: {'theme': state.mode.name},
                ),
          ),
```

The providers that make `context.read` work:

```dart
        RepositoryProvider<KoEngagementService>(
          create: (_) => sl<KoEngagementService>(),
        ),
        // Screens report what the shopper does through this; blocs get it by
        // constructor injection.
        RepositoryProvider<AnalyticsService>(
          create: (_) => sl<AnalyticsService>(),
        ),
```

**(f) `bootstrap.dart`**:

```dart
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
```

### P-10 — Engagement SDK wrapper with memoised start (MYMALI; shape reusable)

```dart
  /// Whether [init] finished. The SDK keeps its own flag private, and its
  /// push calls throw when it never started.
  bool _started = false;

  /// The running or finished [init]. Start-up does not wait for it, so
  /// [identify] and [resetIdentity] do, or a restored session would be lost.
  Future<void>? _starting;

  @override
  Future<void> init() => _starting ??= _start();

  Future<void> _start() async {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;
    try {
      await KatyayaniCore.init(
        KCConfig(
          siteId: _siteId,
          apiBase: _apiBase,
          // The SDK's own logs, in debug builds only.
          debug: kDebugMode,
          enablePush: true,
          autoRequestPush: false,
          androidNotificationIcon: LocalNotificationServiceImpl.androidIcon,
        ),
      );
      _started = true;
      _log('[kc] started');
      _listen();
    } catch (e) {
      _log('[kc] not started: $e');
    }
  }
```
```dart
  @override
  Future<void> identify({
    required String phone,
    String? fullName,
    String? email,
  }) async {
    await _starting;
    if (!_started) return;
    final identity = kcIdentityFor(
      phone: phone,
      fullName: fullName,
      email: email,
    );
    if (identity == null) {
      _log('[kc] identify skipped: no phone');
      return;
    }
    try {
      await KatyayaniCore.identify(identity.userId, traits: identity.traits);
      _log('[kc] identified ${identity.userId}');
    } catch (e) {
      _log('[kc] identify failed: $e');
    }
  }

  @override
  void resetIdentity() {
    final starting = _starting;
    if (starting == null) return;
    unawaited(
      starting.then(
        (_) => _guard('resetIdentity', KatyayaniCore.resetIdentity),
      ),
    );
  }
```
```dart
  @override
  Future<bool> registerPush() async {
    final granted = await requestPushPermission();
    if (!granted) return false;
    try {
      await KatyayaniCore.subscribeToTopic(broadcastTopic);
      _log('[kc] subscribed to $broadcastTopic');
    } catch (e) {
      _log('[kc] subscribe to $broadcastTopic failed: $e');
    }
    return true;
  }
```
Futures returned by the SDK are run inside `_guard` as `unawaited(… .catchError((Object e) => _log(…)))`
(`capturePayment`, `checkNudges`). Items convert through `static List<KCItem> _kcItems(List<AnalyticsItem> items)`
(`KCItem(sku:, qty:, rate:, name:, category:)`). Callbacks registered in `_listen()` (`onNotificationAction`,
`onNotificationButtonAction`, `onDeferredDeepLink`, `onReferral`, `onNudgeNavigation`) only log
with `// TODO(push): …`.

The identity helper is pure Dart and tested on its own:

```dart
KcIdentity? kcIdentityFor({
  required String phone,
  String? fullName,
  String? email,
}) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  final phoneE164 = '+$digits';
  final phoneNumber = digits.length >= 10
      ? digits.substring(digits.length - 10)
      : null;
  final countryCode = phoneNumber == null
      ? null
      : '+${digits.length > 10 ? digits.substring(0, digits.length - 10) : '91'}';

  final name = fullName?.trim() ?? '';
  final parts = name.isEmpty ? const <String>[] : name.split(RegExp(r'\s+'));
  final trimmedEmail = email?.trim() ?? '';

  return KcIdentity(
    userId: phoneE164,
    traits: {
      if (name.isNotEmpty) 'name': name,
      if (parts.isNotEmpty) 'firstName': parts.first,
      if (parts.length > 1) 'lastName': parts.skip(1).join(' '),
      'phone': phoneE164,
      'country_code': ?countryCode,
      'phone_number': ?phoneNumber,
      if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
    },
  );
}
```

### P-11 — Local notification channel (CONDITIONAL(push); full impl)

```dart
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notification_service.dart';

/// [LocalNotificationService] on `flutter_local_notifications`.
///
/// The channel copies the React Native app's (`app.config.ts`,
/// `pushDisplay.ts`). Its id must stay `push_campaigns`: Katyayani Core puts
/// that id in every campaign, and FCM falls back to the manifest's
/// `default_notification_channel_id` only when a message names none. Android
/// freezes a channel's sound when it is created, so a new sound needs a
/// reinstall, not a new value here.
///
/// Run [init] before `KatyayaniCore.init`: the plugin keeps one tap
/// callback, and the SDK's must be the last one set.
class LocalNotificationServiceImpl implements LocalNotificationService {
  LocalNotificationServiceImpl([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String pushChannelId = 'push_campaigns';
  static const String pushChannelName = 'MY Mali';

  /// `android/app/src/main/res/raw/notification.wav`, without the extension.
  static const String pushSound = 'notification';

  /// The small icon, `res/drawable*/notification_icon.png`.
  static const String androidIcon = '@drawable/notification_icon';

  /// The brand green the RN app lights the LED with.
  static const Color _ledColor = Color(0xFF163E33);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> init() async {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          // Permission is asked at a chosen moment, never at start-up.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              pushChannelId,
              pushChannelName,
              importance: Importance.max,
              sound: const RawResourceAndroidNotificationSound(pushSound),
              vibrationPattern: Int64List.fromList(const [0, 250, 250, 250]),
              enableLights: true,
              ledColor: _ledColor,
            ),
          );
    } catch (e) {
      log('[notifications] channel setup failed, pushes stay silent: $e');
    }
  }
}
```

Native counterparts that must agree with the constants: manifest
`<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="push_campaigns" />`,
`<meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/notification_icon" />`,
`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`, `VIBRATE`;
`res/raw/notification.wav`; `res/drawable-xxxhdpi/notification_icon.png` and
`res/drawable-night-{m,h,xh,xxh,xxxh}dpi/notification_icon.png`;
`res/raw/keep.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Push notifications name these by string (channel sound, small icon),
     so the resource shrinker cannot see them used. -->
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@raw/notification,@drawable/notification_icon" />
```

and in `build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` with
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` ("flutter_local_notifications
needs the newer Java APIs on old Androids").

The "ask once per launch, at a chosen screen, after another system prompt" pattern is
`PushPermissionPrompt` (P-section 1 table): `static bool _asked`, a `Timer(settleDelay, _ask)`
in `initState`, waits `location.stream.firstWhere((s) => !s.isDetecting).timeout(locationWait)`
catching `TimeoutException` and `StateError`, then `unawaited(engagement.registerPush())`; Home
wraps its view: `child: const PushPermissionPrompt(child: _HomeView())`.

### P-12 — Payment gateway behind an interface (CONDITIONAL(payments))

Interface file (`payment_gateway.dart`) is quoted in section 2 shapes; the two things to copy
character for character are the enum and the exception:

```dart
/// Why the sheet closed without a payment, as far as the gateway says.
/// [cancelled] and [upiTimeout] are not faults: no money moved.
enum GatewayPaymentError {
  /// The customer backed out of the sheet.
  cancelled,

  /// The gateway could not tell a cancellation from a UPI app that never
  /// answered.
  upiTimeout,
  network,
  insufficientFunds,
  incorrectOtp,
  timeout,
  invalidVpa,
  cardDeclined,
  cardExpired,
  invalidCard,
  bankDown,
  limitExceeded,

  /// The sheet could not open: a missing key, an outdated plugin, TLS.
  notConfigured,
  unknown;

  /// The customer, not the bank, ended the payment.
  bool get isCancellation => this == cancelled || this == upiTimeout;
}

/// Thrown by [PaymentGateway.collect] when no payment was collected.
class GatewayPaymentException implements Exception {
  const GatewayPaymentException(this.error, {this.detail});

  final GatewayPaymentError error;

  /// The gateway's own text, when it was short and readable; null
  /// otherwise. Never shown as it is.
  final String? detail;

  @override
  String toString() => 'GatewayPaymentException($error: $detail)';
}

/// The payment sheet. One payment at a time: a second [collect] while one
/// is open fails with [GatewayPaymentError.unknown].
abstract interface class PaymentGateway {
  /// Opens the sheet for [checkout] and completes with the payment it
  /// collected, or throws [GatewayPaymentException].
  Future<GatewayPayment> collect(GatewayCheckout checkout);
}
```

The event-driven SDK → `Future` adapter (`RazorpayPaymentGateway.collect`):

```dart
  @override
  Future<GatewayPayment> collect(GatewayCheckout checkout) {
    if (_inFlight != null) {
      return Future.error(
        const GatewayPaymentException(
          GatewayPaymentError.unknown,
          detail: 'A payment is already open.',
        ),
      );
    }
    final completer = _inFlight = Completer<GatewayPayment>();
    final sdk = _newSdk();

    void finish(void Function() complete) {
      sdk.clear();
      _inFlight = null;
      if (!completer.isCompleted) complete();
    }

    sdk
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
        final paymentId = response.paymentId ?? '';
        if (paymentId.isEmpty) {
          finish(
            () => completer.completeError(
              const GatewayPaymentException(
                GatewayPaymentError.unknown,
                detail: 'The sheet closed without a payment id.',
              ),
            ),
          );
          return;
        }
        _trace('paid $paymentId for ${checkout.orderId}');
        finish(
          () => completer.complete(
            GatewayPayment(
              paymentId: paymentId,
              orderId: response.orderId ?? checkout.orderId,
              signature: response.signature ?? '',
            ),
          ),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        final failure = classifyRazorpayError(
          code: response.code,
          message: response.message,
          error: response.error,
        );
        // Everything Razorpay said: the code, its text and the gateway's
        // error object (`reason`, `step`, `source`, `metadata`). The
        // customer is shown only the classified message.
        _trace(
          '${failure.error.isCancellation ? "cancelled" : "FAILED"} for '
          '${checkout.orderId} → ${failure.error.name}\n'
          '  code: ${response.code}\n'
          '  message: ${response.message}\n'
          '  error: ${response.error}',
        );
        finish(() => completer.completeError(failure));
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        // The customer chose a wallet the sheet hands off to; Razorpay
        // reports no payment for it, so none is confirmed here.
        _trace('external wallet ${response.walletName}');
        finish(
          () => completer.completeError(
            const GatewayPaymentException(
              GatewayPaymentError.unknown,
              detail: 'The payment moved to an external wallet.',
            ),
          ),
        );
      });

    _trace(
      'opening ${checkout.orderId} for ₹'
      '${(checkout.amountPaise / 100).toStringAsFixed(2)} '
      'with key ${_keyLabel(checkout.keyId)}',
    );
    sdk.open(optionsFor(checkout));
    return completer.future;
  }
```
```dart
  /// The SDK's options, as the previous app opens its sheet: no retry
  /// inside the sheet, the brand colour, the customer prefilled.
  static Map<String, dynamic> optionsFor(GatewayCheckout checkout) => {
    'key': checkout.keyId,
    'order_id': checkout.orderId,
    'amount': checkout.amountPaise,
    'currency': 'INR',
    'name': checkout.merchantName,
    'description': checkout.description,
    'retry': {'enabled': false},
    'theme': {'color': themeColor},
    'prefill': {'contact': ?checkout.contact, 'email': ?checkout.email},
  };
```

Error classification is a **public pure function**, tested without the SDK:

```dart
GatewayPaymentException classifyRazorpayError({
  int? code,
  String? message,
  Map<dynamic, dynamic>? error,
}) {
  final raw = (message ?? '').trim();
  Map<dynamic, dynamic> inner = error ?? const {};
  if (inner.isEmpty && raw.startsWith('{')) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        final nested = parsed['error'];
        inner = nested is Map<String, dynamic> ? nested : parsed;
      }
    } on FormatException {
      // Not JSON after all: read the text as it is.
    }
  }
  final reason = '${inner['reason'] ?? ''}';
  final description = '${inner['description'] ?? ''}';
  final text = '$reason $description $raw';

  bool has(String pattern) =>
      RegExp(pattern, caseSensitive: false).hasMatch(text);

  if (code == Razorpay.PAYMENT_CANCELLED ||
      has('cancel|dismiss|user_cancel|back')) {
    // Razorpay's own text for this case is "You may have cancelled the
    // payment or there was a delay in response from the UPI app".
    return GatewayPaymentException(
      has('delay in response|upi app')
          ? GatewayPaymentError.upiTimeout
          : GatewayPaymentError.cancelled,
    );
  }
  if (code == Razorpay.NETWORK_ERROR) {
    return const GatewayPaymentException(GatewayPaymentError.network);
  }
  if (code == Razorpay.INVALID_OPTIONS ||
      code == Razorpay.TLS_ERROR ||
      code == Razorpay.INCOMPATIBLE_PLUGIN) {
    return GatewayPaymentException(
      GatewayPaymentError.notConfigured,
      detail: _readable(raw),
    );
  }

  for (final (pattern, error) in _reasons) {
    if (has(pattern)) return GatewayPaymentException(error);
  }
  return GatewayPaymentException(
    GatewayPaymentError.unknown,
    detail: _readable(description.isNotEmpty ? description : raw),
  );
}

/// The gateway's text when it is short, plain and not JSON.
String? _readable(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.startsWith('{') || trimmed.length >= 160) {
    return null;
  }
  return trimmed;
}

const List<(String, GatewayPaymentError)> _reasons = [
  (
    r'insufficient[_ ]funds|insufficient balance',
    GatewayPaymentError.insufficientFunds,
  ),
  (
    r'incorrect[_ ]otp|invalid[_ ]otp|otp[_ ]failed',
    GatewayPaymentError.incorrectOtp,
  ),
  (r'payment[_ ]timeout|timed[_ ]out|timeout', GatewayPaymentError.timeout),
  (r'invalid[_ ]vpa|vpa|upi[_ ]id', GatewayPaymentError.invalidVpa),
  (
    r'card[_ ]declined|declined by (the )?bank|do not honou?r|transaction not permitted',
    GatewayPaymentError.cardDeclined,
  ),
  (r'expired[_ ]card|card[_ ]expired', GatewayPaymentError.cardExpired),
  (
    r'incorrect[_ ]cvv|invalid[_ ]cvv|incorrect[_ ]card|invalid[_ ]card',
    GatewayPaymentError.invalidCard,
  ),
  (
    r'gateway[_ ]error|bank[_ ]?(is )?down|issuer[_ ]down|server[_ ]error|internal[_ ]error',
    GatewayPaymentError.bankDown,
  ),
  (r'limit[_ ]exceeded|exceeds', GatewayPaymentError.limitExceeded),
  (r'network|internet|connection|unreachable', GatewayPaymentError.network),
];
```

Consumer rule: **only a repository** calls the gateway, builds `GatewayCheckout` from domain
values, converts rupees to minor units there (`amountPaise: (registered.quote.total * 100).round()`),
and maps `GatewayPaymentException` to domain failures by `error` (`_paymentFailure`: `cancelled`
→ `PaymentCancelledFailure()`, `upiTimeout` → `PaymentCancelledFailure(upiTimeout: true)`,
`notConfigured` → `PaymentNotConfiguredFailure()`, the rest → `PaymentFailedFailure(reason:, detail: e.detail)`).
DI: `registerLazySingleton<PaymentGateway>(RazorpayPaymentGateway.new)`; the repository gets
`gateway: sl()`. Fake:

```dart
class FakePaymentGateway implements PaymentGateway {
  GatewayPayment payment = const GatewayPayment(
    paymentId: 'pay_01',
    orderId: 'order_01',
    signature: 'sig_01',
  );
  GatewayPaymentException? error;
  Completer<void>? gate;

  final List<GatewayCheckout> checkouts = [];

  GatewayCheckout get lastCheckout => checkouts.last;

  @override
  Future<GatewayPayment> collect(GatewayCheckout checkout) async {
    checkouts.add(checkout);
    await gate?.future;
    final error = this.error;
    if (error != null) throw error;
    return payment;
  }
}
```

### P-13 — Third-party bearer token: mint, cache with skew, share one mint, 401 retry (MYMALI; pattern reusable)

```dart
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

Consumer pattern (StockShip; the same shape in `RefOrderRemoteDataSourceImpl._get` and
`KoOrderRemoteDataSourceImpl._postWithToken`, where the token is optional):

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
    …
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

Tests inject `now: () => now` and a `FakeNetworking` (`okResponse(const {'access_token': 'ko_1', 'expires_at': '…'})`,
`errorResponse(const {'code': 'UNAUTHORIZED'}, '401')`, `..response = null ..error = app.AppException('offline', 'Timeout')`),
asserting call count, `call.data == {'refresh': false, 'env': 'beta'}`, `call.headers == {'apikey': 'anon'}`.

### P-14 — Env getters for optional vs required credentials, and a debug-only switch

```dart
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
```
```dart
  static String get razorpayKeyId => razorpayMode == RazorpayMode.test
      ? _require('RAZORPAY_TEST_KEY_ID')
      : _koValue('RAZORPAY_KEY_ID');

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
```
```dart
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
```

### P-15 — Getting a `.env` value into the native projects (CONDITIONAL(Meta))

Android (`android/app/build.gradle.kts`):

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
```
```kotlin
    // The Meta ids below are generated string resources.
    buildFeatures {
        resValues = true
    }
    defaultConfig {
        …
        // Read by the manifest's com.facebook.sdk.* meta-data.
        resValue("string", "facebook_app_id", fbAppId.ifEmpty { "0" })
        resValue("string", "facebook_client_token", fbClientToken.ifEmpty { "0" })
        resValue("bool", "facebook_auto_init", metaEnabled.toString())
    }
```

`AndroidManifest.xml`:

```xml
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id" />
        <meta-data
            android:name="com.facebook.sdk.ClientToken"
            android:value="@string/facebook_client_token" />
        <meta-data
            android:name="com.facebook.sdk.AutoInitEnabled"
            android:value="@bool/facebook_auto_init" />
        <meta-data
            android:name="com.facebook.sdk.AutoLogAppEventsEnabled"
            android:value="true" />
        <meta-data
            android:name="com.facebook.sdk.AdvertiserIDCollectionEnabled"
            android:value="true" />
```

iOS: `ios/Flutter/Debug.xcconfig` and `Release.xcconfig` are exactly

```
#include "Generated.xcconfig"
#include? "Env.xcconfig"
```

`ios/Flutter/Env.xcconfig` is git-ignored (`.gitignore` line `ios/Flutter/Env.xcconfig`) and
written by `tool/sync_native_env.dart` (full file):

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

`Info.plist` keys: `FacebookAppID` `$(FB_APP_ID)`, `FacebookClientToken` `$(FB_CLIENT_TOKEN)`,
`FacebookDisplayName` `My Mali`, `FacebookAutoLogAppEventsEnabled` true,
`FacebookAdvertiserIDCollectionEnabled` true, `FacebookAutoInitEnabled` true,
`CFBundleURLTypes` → `CFBundleURLSchemes` → `fb$(FB_APP_ID)`, `NSUserTrackingUsageDescription`
("My Mali uses this to show you more relevant offers and measure ad performance. Your data is
never sold."), and `LSApplicationQueriesSchemes` = `tez, gpay, phonepe, paytm, paytmmp, bhim,
credpay, amazonpay, upi, fbapi, fb-messenger-share-api` (the first nine for the Razorpay UPI
intent, the last two for Meta). Android's manifest `<queries>` adds
`<intent><action android:name="android.intent.action.VIEW"/><data android:scheme="upi"/></intent>`.

### P-16 — Test helpers for this area

`FakeKoEngagementService` (full):

```dart
/// Records what the app asked of Katyayani Core.
class FakeKoEngagementService implements KoEngagementService {
  /// The phone of every `identify`, in order.
  final List<String> identified = [];
  int resetCount = 0;
  int initCount = 0;

  /// Every event name sent through [track] and the typed events.
  final List<String> events = [];

  /// Every [track] call with its properties, in order.
  final List<({String name, Map<String, dynamic>? properties})> tracked = [];

  /// The name of every screen reported, in order.
  final List<String> screens = [];

  @override
  Future<void> init() async => initCount++;

  /// How many times [registerPush] was asked.
  int registerPushCount = 0;

  @override
  Future<bool> registerPush() async {
    registerPushCount++;
    return true;
  }

  @override
  Future<void> identify({
    required String phone,
    String? fullName,
    String? email,
  }) async => identified.add(phone);

  @override
  void resetIdentity() => resetCount++;

  @override
  Future<bool> requestPushPermission() async => true;

  @override
  void track(String name, {Map<String, dynamic>? properties}) {
    events.add(name);
    tracked.add((name: name, properties: properties));
  }

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) {
    events.add('screen_view');
    screens.add(screenName);
  }

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      events.add('view_item');

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) =>
      events.add('add_to_cart');

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      events.add('remove_from_cart');

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) =>
      events.add('view_cart');

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => events.add('begin_checkout');

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => events.add('purchase');

  @override
  void search(String searchTerm) => events.add('search');

  @override
  void login({String? method}) => events.add('login');

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => events.add('add_payment_info');

  @override
  void capturePayment(double amount, {String? orderId}) =>
      events.add('capture_payment');

  @override
  void checkNudges(BuildContext context, String route) =>
      events.add('check_nudges');
}

/// Registers a [FakeKoEngagementService] in `sl`, as every test that pumps
/// `App` needs, and returns it.
FakeKoEngagementService registerFakeEngagement() {
  final fake = FakeKoEngagementService();
  sl.registerSingleton<KoEngagementService>(fake);
  sl.registerSingleton<AnalyticsService>(KoAnalyticsService(fake));
  return fake;
}
```

Rule: typed calls record a **snake_case marker** in `events` (`'add_to_cart'`, `'screen_view'`,
…) while `track` records the raw name in both `events` and `tracked`; tests therefore assert
`core.events == ['add_to_cart']` for typed calls and `core.tracked.map((e) => e.name)` for
`track`. `registerSignedInApp` does the same two registrations
(`sl..registerSingleton<KoEngagementService>(core)..registerSingleton<AnalyticsService>(KoAnalyticsService(core))`)
**before** calling the `register<Feature>Feature()` functions whose bloc factories take `analytics: sl()`.

---

## 4. Rules observed in code (not in AGENTS.md, or stated differently)

1. **40-character name limit.** `_maxNameLength = 40` is applied to every GA4 name (`_snake` →
   `_clip`) **and** to every Meta name (`_clip(standard ?? eventName)`). AGENTS.md section 23
   mentions only "text cut to 100" for values.
2. **Meta special cases** not in AGENTS.md: `search_term` → `fb_search_string`; `Order Rated` →
   `valueToSum = rating`, `fb_max_rating_value = 5`, `fb_content_type = 'order'`; `Payment Started`
   → `fb_success = 1`; a purchase with no money logs `0`.
3. **GA4 destination guard** is `Firebase.apps.isEmpty` — so `firebase_analytics_destination.dart`
   also imports `firebase_core`. AGENTS.md section 1 lists `firebase_core` as "started in
   `bootstrap.dart`" only.
4. **Destinations are created only on Android/iOS** (`_analyticsDestinations()` returns
   `const []` elsewhere). AGENTS.md says Meta joins only with credentials; it does not state the
   phone-only gate for GA4.
5. **ATT prompt is delayed one second** (`MetaAnalyticsDestination._promptDelay`) and skipped
   when already determined. AGENTS.md: "asks (App Tracking Transparency) once".
6. **`KoAnalyticsService.setUserId` and `requestTrackingPermission` are no-ops** — AGENTS.md says
   the core "knows the user by phone", which is why; the no-op shape is what a target app copies.
7. **Reporting from `initState` + `addPostFrameCallback`** is a third sanctioned place beside
   "a `BlocListener` or a tap handler" (AGENTS.md: "never from `build`"): `CartPage._reportOpened`,
   `ProductDetailPage`, `OrderPlacedPage._reportPurchase` all report a state that may already be
   loaded when the page opens. `OrderPlacedPage.reportedOrders` is a `static final Set<String>`
   (`@visibleForTesting`) that dedupes across route rebuilds.
8. **`AnalyticsService` and `KoEngagementService` reach widgets through `RepositoryProvider`s in
   `app.dart`**; AGENTS.md only says "through `context.read<AnalyticsService>()`".
9. **`bootstrap.dart` calls `sl<…>()`** (`sl<AnalyticsService>()`, `sl<LocalNotificationService>()`,
   `sl<KoEngagementService>()`). AGENTS.md section 9 lists only `injection_container.dart` and
   `BlocProvider` `create:`s as places that may call `sl`.
10. **Edge Function headers differ for a user-authenticated function.** AGENTS.md section 6 rule 4
    prescribes `{'apikey': anon, 'Authorization': 'Bearer $anon'}`; `KoTokenServiceImpl` sends
    **only** `{'apikey': _anonKey}` so the default `Authorization: Bearer <session token>` stays and
    the function can read the user. Its test asserts `call.headers == {'apikey': 'anon'}`.
11. **`KoTokenServiceImpl` is a service, not a data source:** it returns `null` and logs instead of
    throwing a typed exception, and has no `_toServerException`. Consumers (`StockshipRemoteDataSourceImpl`)
    throw their own `KoTokenException` when `token()` is null.
12. **Hardcoded colours outside the theme exist in this area:** `LocalNotificationServiceImpl._ledColor = Color(0xFF163E33)`
    and `RazorpayPaymentGateway.themeColor = '#225542'` (the SDKs take raw colours). AGENTS.md
    section 11 forbids `Color(0x…)` "inside widgets"; these are services. Note the two "brand
    green" values differ.
13. **Blocs receive a core service** (`AnalyticsService? analytics`) alongside use cases; AGENTS.md
    section 9 says "Blocs receive use cases, never repositories or data sources" — consistent, but
    section 23 is the only place that allows the service.
14. **`KoEngagementServiceImpl` depends on `LocalNotificationServiceImpl.androidIcon`** (one impl
    importing another impl) so the KC SDK and the channel share the small icon.
15. **The tracker reports `tabSelected` even when the tab is already on show** (the tap event is
    always tracked; only the screen is deduped), and **ignores indices outside `analyticsTabs`**.
16. **Debug tracing in payments/checkout uses `debugPrint` only** (`_trace`, "`dart:developer`'s
    `log` reaches only an attached debugger"), whereas destinations use `developer.log` + `debugPrint`.
17. **Dart language features relied on:** null-aware collection elements (`[?_tracker?.observer()]`,
    `'contact': ?checkout.contact`, `'country_code': ?countryCode`, `[for (…) ?_scalar(item)]`),
    records (`({String token, DateTime expiresAt})?`, `({String name, Map<String, dynamic>? properties})`),
    `switch` expressions with patterns, `if (… case final id?)`, `abstract interface class`,
    `abstract final class`. `pubspec.yaml` has `sdk: ^3.13.4`; the null-aware elements need Dart ≥ 3.8.
18. **Notification small icon assets** exist in `drawable-xxxhdpi` and `drawable-night-{m,h,xh,xxh,xxxh}dpi`
    only (no `drawable-mdpi…xxhdpi` light copies); AGENTS.md says "`@drawable/notification_icon` (plus `drawable-night-*`)".
19. **`KoEngagementService.registerPush()`** exists on the interface (AGENTS.md section 23's
    service table lists `init`, `identify`, `resetIdentity`, `requestPushPermission` and callbacks;
    `registerPush()` appears only in the "Permission" bullet).
20. **Tests never construct `MultiDestinationAnalyticsService` with real destinations**; widget
    tests register `KoAnalyticsService(fake)` as the `AnalyticsService` (so GA4/Meta are exercised
    only by their own unit tests with a mocked method channel).

---

## 5. Packages

| package | version (pubspec) | files that import it | ALWAYS / CONDITIONAL |
|---|---|---|---|
| `flutter` (`widgets.dart`, `foundation.dart`, `material.dart`) | sdk | all area files (`BuildContext`, `NavigatorObserver`, `kDebugMode`, `defaultTargetPlatform`, `debugPrint`, `WidgetsBinding`) | ALWAYS |
| `flutter_bloc` | ^9.1.0 | call sites (`BlocListener`, `RepositoryProvider`, `context.read`), blocs | ALWAYS |
| `get_it` | ^8.0.3 | `injection_container.dart`, `test/helpers/*` | ALWAYS |
| `go_router` | ^18.0.2 | `app_router.dart` (tracker itself needs only `NavigatorObserver`) | ALWAYS |
| `flutter_dotenv` | ^6.0.1 | `env.dart` | ALWAYS |
| `firebase_core` | ^4.15.0 | `lib/app/bootstrap.dart`, `lib/core/services/analytics/firebase_analytics_destination.dart` | CONDITIONAL(Firebase) |
| `firebase_analytics` | ^12.6.0 | `lib/core/services/analytics/firebase_analytics_destination.dart` | CONDITIONAL(GA4) |
| `facebook_app_events` | ^0.30.5 | `lib/core/services/analytics/meta_analytics_destination.dart`; `test/core/services/analytics/meta_analytics_destination_test.dart` (for `channelName`) | CONDITIONAL(Meta) |
| `app_tracking_transparency` | ^2.0.7 | `lib/core/services/analytics/meta_analytics_destination.dart` | CONDITIONAL(Meta on iOS) |
| `katyayani_core` | ^2.0.7 | `lib/core/services/katyayani_core/ko_engagement_service_impl.dart` (brings `firebase_messaging` transitively; nothing imports `firebase_messaging` directly) | MYMALI-SPECIFIC |
| `flutter_local_notifications` | ^22.3.1 | `lib/core/services/local_notifications/local_notification_service_impl.dart` | CONDITIONAL(push) |
| `razorpay_flutter` | ^1.4.7 | `lib/core/services/payments/razorpay_payment_gateway.dart` | CONDITIONAL(Razorpay) |
| `dio` | ^5.11.1 | `networking.dart` (another area); `KoTokenServiceImpl` sees only `Networking` | ALWAYS (networking area) |
| `equatable` | ^2.0.7 | `api_response.dart` | ALWAYS (networking area) |
| `crypto` | ^3.0.6 | `checkout_repository_impl.dart` (Medusa password; not this area's concern) | MYMALI-SPECIFIC |
| `flutter_test` | sdk | all tests | ALWAYS |
| Dart SDK libs used | — | `dart:async` (`unawaited`, `Completer`), `dart:developer` (`log`), `dart:convert` (`jsonDecode`), `dart:ui` (`Color`, `Int64List` in the notifications impl), `dart:io` (tool) | ALWAYS |

Android Gradle: `com.google.gms.google-services` (applied only if `google-services.json` exists),
`com.android.tools:desugar_jdk_libs:2.1.4`.

---

## 6. What varies per app

| what | where it appears | MyMali value |
|---|---|---|
| Event names and groups | `AppEvents` constants; the `_ga4Names` / `_metaStandardNames` keys; `MultiDestination…` (`AppEvents.addToCart`, `removeFromCart`, `productSearch`); tracker (`navBarIconTapped`, `screenLoad`); every call site | React-Native-app Title Case names |
| Default currency | `defaultCurrency` in the mapper; `'currency': 'INR'` literals at call sites; `optionsFor` `'currency': 'INR'` | `'INR'` |
| Vendor name tables | `_ga4Names`, `_metaStandardNames` values | GA4 recommended events, Meta `fb_mobile_*` |
| Screen names | `analyticsScreenNames` (route name → dashboard name); `analyticsTabs` (order = branch order = bottom-bar index) | `ShopTab`, `Cart`, … |
| Ignored routes | `AnalyticsScreenTracker._ignored` | `{AppRoute.splash.name}` |
| Route enum | `AppRoute` names used as map keys | `home`, `cart`, … |
| Which blocs take `analytics: sl()` | `register<Feature>Feature()` factories | `AuthBloc`, `LoginBloc`, `CartBloc`, `WishlistBloc`, `CouponBloc` |
| Core sink | `core:` argument of `MultiDestinationAnalyticsService` in `_registerCore` | `KoAnalyticsService(sl())` |
| Destinations | `_analyticsDestinations()` body | `FirebaseAnalyticsDestination()`, `MetaAnalyticsDestination()` (credential-gated) |
| Identity rules | the `BlocListener<AuthBloc>` in `app.dart`: what `setUserId` gets (`user.id`) and what the engagement SDK gets (`phone`, `fullName`, `email`) | id for GA4/Meta, phone for KC |
| Env keys | `Env` getters + `.env.example` | `KC_SITE_ID`, `KC_API_URL`, `FB_APP_ID`, `FB_CLIENT_TOKEN`, `RAZORPAY_KEY_ID_{PROD,BETA}`, `RAZORPAY_TEST_KEY_ID`, `RAZORPAY_MODE`, `KO_ENV`, `SUPABASE_ANON_KEY` |
| Token mint endpoint and body | `Endpoints.kotechToken`; `{'refresh', 'env'}`; response `access_token`/`expires_at`; `expirySkew`, `fallbackLifetime` | `/functions/v1/kotech-token`, 5 min, 30 min |
| Hosts the token is sent to | `ApiHost.stockship`, `ApiHost.koUtils` consumers | StockShip, KO Utils |
| Push channel | `pushChannelId`, `pushChannelName`, `pushSound`, `androidIcon`, `_ledColor`, vibration pattern; manifest `default_notification_channel_id`/`default_notification_icon`; `res/raw/notification.wav`; `keep.xml`; `drawable*/notification_icon.png` | `push_campaigns`, `MY Mali`, `notification`, `@drawable/notification_icon`, `0xFF163E33`, `[0,250,250,250]` |
| Broadcast topic | `KoEngagementServiceImpl.broadcastTopic` | `all_users` |
| Where/when push permission is asked | `PushPermissionPrompt` (Home, after location, once per launch; `settleDelay`, `locationWait`) | 1 s, 30 s |
| Payment sheet | `themeColor`; `optionsFor` keys; `paymentMerchant`, `paymentDescription` (repository); `amountPaise` conversion; UPI `<queries>` / `LSApplicationQueriesSchemes` | `#225542`, `Katyayani Organics`, `Order from My Mali App` |
| Payment error vocabulary | `GatewayPaymentError` values (UPI-specific `upiTimeout`, `invalidVpa`), `_reasons` regexes | Razorpay / India |
| Log prefixes | `[ga4]`, `[meta]`, `[kc]`, `[notifications]`, `[razorpay]`, `[ko-token]`, `[firebase]`, `[checkout]` | — |
| Native Meta config | gradle `resValue`s, manifest `com.facebook.sdk.*`, plist `Facebook*`, `fb$(FB_APP_ID)` scheme, `NSUserTrackingUsageDescription` text, `FacebookDisplayName` | `My Mali` |
| Test double names | `FakeKoEngagementService`, `registerFakeEngagement`, `registerSignedInApp(engagement:)` | — |

---

## 7. Gotchas

1. **Double counting is the design constraint.** Only `track`, `addToCart`, `removeFromCart`,
   `search` reach destinations. If a target app's core is a no-op, `viewItem`/`viewCart`/
   `beginCheckout`/`addPaymentInfo`/`purchase`/`login`/`screenView` vanish; if it forwards them
   to destinations too, the paired `track` at the same call site double counts. Decide once.
2. **Meta `logPurchase` vs `logEvent`.** `Order Placed` must not be in `_metaStandardNames`; the
   destination branches on `event.isPurchase`. `valueToSum` is an SDK argument, never a parameter
   key (the mapper test asserts `containsKey('_valueToSum') == false`, while the channel test
   asserts the plugin itself sends `_valueToSum`).
3. **`parameters: event.parameters.isEmpty ? null : event.parameters`** for both SDKs: an empty
   map is passed as `null`.
4. **`Firebase.apps.isEmpty`** short-circuits GA4 so a build without `google-services.json`
   runs; forgetting it makes every event throw inside the SDK.
5. **One `NavigatorObserver` per navigator.** `_observers()` must be *called* per branch (a
   fresh `AnalyticsRouteObserver` each time) — sharing one instance across navigators breaks
   `navigator?.context`.
6. **Every `GoRoute` needs `name:`** or the tracker treats it as the unnamed shell route and
   re-reports the current tab.
7. **`analyticsTabs` order = `StatefulShellRoute` branch order = bottom-bar index**; the shell
   calls `onTabSelected?.call(index)` after `goBranch`.
8. **`_show` dedupes by route name, not by screen name**; `tabSelected` tracks the tap event
   before the dedupe, so re-tapping the current tab produces a tap event and no screen view.
9. **Nudges after the frame**: `WidgetsBinding.instance.addPostFrameCallback` + `context.mounted`;
   `tabSelected` uses `rootNavigatorKey.currentContext`, observers use `navigator?.context`.
10. **`identify` awaits `_starting`; `resetIdentity` chains on it; `init()` is memoised with
    `_starting ??= _start()`** — start-up does not await init, so a restored session's identify
    must wait or be lost. `requestPushPermission` does *not* wait (returns false if not started).
11. **Init order:** `LocalNotificationService.init()` **then** `KoEngagementService.init()`; both
    use the same notifications plugin and the last tap handler set wins.
12. **Never register a Firebase background message handler** yourself when the engagement SDK
    does; nothing in the app imports `firebase_messaging`.
13. **Permission is never requested at start-up**: `autoRequestPush: false` and all three
    `DarwinInitializationSettings.request*Permission: false`; `PushPermissionPrompt` asks once per
    launch with a static flag (`resetForTest()` in tests).
14. **`requestTrackingPermission()` in bootstrap is `unawaited`** and resolves `sl<AnalyticsService>()`
    immediately after `configureDependencies()` — which is when `_analyticsDestinations()` runs
    and reads `Env.fbAppId`/`fbClientToken` (so `Env.load()` must precede it, as it does).
15. **Meta needs credentials on all three sides** (Dart `Env`, Gradle `resValue`, iOS
    `Env.xcconfig` via `dart run tool/sync_native_env.dart`); with any blank the Dart side skips
    the destination and Android keeps `facebook_auto_init=false`, but iOS fails at launch if the
    plist values resolve to empty — run the sync tool before an iOS build.
16. **Gradle reads `.env` from `rootProject.projectDir.parentFile`** (the Flutter project root,
    one level above `android/`).
17. **`PaymentGateway.collect` is single-flight**: a second call while one is open fails
    immediately with `unknown`; `finish()` clears the SDK handlers and `_inFlight` **before**
    completing; a success without `paymentId` is an `unknown` error; `EVENT_EXTERNAL_WALLET` is an
    error (no payment confirmed).
18. **`classifyRazorpayError` reads two envelope shapes** (the plugin's `error` map, or JSON in
    `message`) and checks cancellation first (`Razorpay.PAYMENT_CANCELLED == 2` or regex), then
    `NETWORK_ERROR`, then `INVALID_OPTIONS/TLS_ERROR/INCOMPATIBLE_PLUGIN` → `notConfigured`, then the
    `_reasons` table in order (so `'timeout'` matches before `'network'`), and `detail` is kept
    only when short (<160), non-JSON text.
19. **Minor units only in the repository**: `amountPaise: (registered.quote.total * 100).round()`;
    the gateway never converts.
20. **Token skew and sharing**: `token()` returns the cached token only while
    `now < expiresAt - 5 min`; concurrent callers await the same `_inFlight`, which clears itself
    in `whenComplete`; `invalidate()` only drops the cache. Consumers retry **once** after a 401
    with `refresh: true`, and only if a token was sent in the first place (`token != null &&`).
21. **The optional-SDK constructor idiom** (`[FirebaseAnalytics Function()? analytics]`,
    `{Razorpay Function()? newSdk}`) is how tests avoid mocking packages; keep factories (not
    instances) where the SDK must be created lazily (Razorpay creates a new `Razorpay()` per
    `collect`; Firebase reads `FirebaseAnalytics.instance` only after `Firebase.apps` is checked).
22. **`Int64List` and `Color` come from `import 'dart:ui';`** in the notifications impl — keep the
    import list exactly.
23. **Properties never carry raw API text**: `'reason': failure.runtimeType.toString()` or
    `failureReasonName(failure)`; coupon codes are normalised (`trim().toUpperCase()`) before
    reporting.
24. **`AnalyticsItem.quantity` in cart events is the delta** (`delta.abs()`), not the line
    quantity; `_itemProperties` forwards only the **first** item to destinations.
25. **Two different brand greens** are hardcoded for SDKs (`0xFF163E33` LED, `#225542` Razorpay
    theme); a target app substitutes both from its own palette, and cannot read the theme there.
26. **`registerFakeEngagement()` registers `AnalyticsService` as `KoAnalyticsService(fake)`**, not
    the multi-destination service, so widget tests assert against `fake.tracked`/`fake.screens` and
    never touch platform channels; `tearDown(sl.reset)` is required.
27. **Dart ≥ 3.8 syntax** (null-aware elements) is used in the tracker, the mapper, the gateway
    options, and `kcIdentityFor`; an older target SDK must rewrite those four spots
    (`if (x != null) key: x`).
