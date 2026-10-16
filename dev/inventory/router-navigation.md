# Inventory: router-navigation (MyMali Flutter app)

Source of truth: the code at `C:/Users/Katyayani/Documents/flutter/mymali` (read-only), checked against AGENTS.md. Where the two differ, both are recorded in section 4.

Package: `go_router` `^18.0.2` in `pubspec.yaml`, resolved to `18.0.2` in `pubspec.lock`.

---

## 1. Files

Classification key: **ALWAYS** = generic architecture, install in every app. **CONDITIONAL(x)** = install only when the target app has capability x. **MYMALI-SPECIFIC** = this app's business. Files marked ALWAYS may carry MyMali values; the "placeholders" column lists exactly what another app substitutes.

| Path | Role | Class | Placeholders |
|---|---|---|---|
| `lib/core/router/app_routes.dart` | `enum AppRoute` — the single source of route names (`.name`) and paths (`.path`), with doc comments on routes that take parameters or `extra`. | ALWAYS | Every enum value (name + path + doc comment). Keep the shape: `value('/path')`, `const AppRoute(this.path); final String path;`. |
| `lib/core/router/app_router.dart` | `class AppRouter` — builds the one `GoRouter`: `navigatorKey: rootNavigatorKey`, observers, `initialLocation`, the splash and login `GoRoute`s, one `StatefulShellRoute.indexedStack` with a branch per tab, then every full-screen `GoRoute` with `parentNavigatorKey: rootNavigatorKey`. Also the two `extra` type-guard `redirect`s. | ALWAYS (the shell route part is CONDITIONAL(bottom tabs)) | Page imports; the tab branches and their keys; every `GoRoute`; the args types in the `redirect` guards; `initialLocation: AppRoute.splash.path`. |
| `lib/core/router/navigator_keys.dart` | Top-level `GlobalKey<NavigatorState>`s: `rootNavigatorKey` plus one per tab. | ALWAYS for `rootNavigatorKey`; the tab keys are CONDITIONAL(bottom tabs) | Tab key names and `debugLabel`s (`home`, `categories`, `garden`, `wishlist`, `account`). |
| `lib/core/router/analytics_screen_tracker.dart` | `analyticsScreenNames` map, `analyticsTabs` list, `AnalyticsScreenTracker` (dedupes and reports screens, handles tab taps) and `AnalyticsRouteObserver extends NavigatorObserver`. | CONDITIONAL(app reports screen views to analytics) | Map values (the RN screen names); `analyticsTabs`; `AppEvents.navBarIconTapped` / `AppEvents.screenLoad`; the `checkNudges` call (Katyayani Core nudges — MYMALI-SPECIFIC line inside a generic file). |
| `lib/features/home/presentation/widgets/app_shell_scaffold.dart` | `AppShellScaffold` — the `StatefulShellRoute` builder's widget: `Scaffold(extendBody: true, body: navigationShell, bottomNavigationBar: AppBottomNavBar(...))`; `goBranch` + `onTabSelected`. | CONDITIONAL(bottom tabs) | The `BlocListener<WishlistBloc>` toggle-failure snackbar and the `wishlistCount` badge are MYMALI-SPECIFIC; the rest is the generic shell. |
| `lib/features/home/presentation/widgets/app_bottom_nav_bar.dart` | `AppBottomNavBar` — the floating five-tab pill, `_NavItem(id, label, icon)` list, keys `shell_<id>Tab` / `shell_<id>Badge`, raised centre tab with a custom sprout painter. | CONDITIONAL(bottom tabs); the look is MYMALI-SPECIFIC | `_items` (ids/labels/icons, in branch order), `_centerIndex = 2`, `_wishlistIndex = 3`, the badge source, `_SproutPainter`, bar sizes. |
| `lib/app/app.dart` | `App({required this.router})` — `MultiBlocProvider` → `MultiBlocListener` → `MaterialApp.router(routerConfig: router, …)`. | ALWAYS in shape | `title: 'MyMali'`, `AppTheme.light/dark`, `maxTextScaleFactor = 1.1`, every provider and listener (all MYMALI-SPECIFIC). The router contract (`final GoRouter router`) is generic. |
| `lib/app/bootstrap.dart` | Start-up; the one line that creates the router: `runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router));` | ALWAYS for that line; the rest belongs to other areas | Drop `analytics:` when there is no analytics. |
| `lib/main.dart` | `void main() { bootstrap(); }` | ALWAYS | none |
| `lib/features/auth/presentation/splash/pages/splash_page.dart` | `SplashPage` — dispatches `AuthStatusRequested`, waits `displayDuration`, waits for a resolved `AuthState`, then `goNamed(home | login)`. The only place the first destination is decided. | CONDITIONAL(app has auth with session restore); shape ALWAYS | `displayDuration` (2600 ms), destinations `AppRoute.home` / `AppRoute.login`, the brand widgets (`BrandBackdrop`, `BrandMark`, `LoadingAnimationWidget.staggeredDotsWave`). |
| `lib/core/widgets/sheets/app_picker_sheet.dart` | `AppPickerSheet.show<T>` — `showModalBottomSheet(useRootNavigator: true, …)`; the sheet pops a value. | ALWAYS (widgets area; listed here for the root-navigator rule) | none (generic) |
| `lib/core/widgets/sheets/app_info_sheet.dart` | `AppInfoSheet.show` — `showModalBottomSheet<bool>(useRootNavigator: true, …)`; `true` when the button was pressed. | ALWAYS (widgets area; listed here for the root-navigator rule) | none (generic) |
| `lib/core/widgets/page_header.dart` | `PageHeader` — the app bar of every pushed page; `onBack`, `backKey`. The back pattern (section 3.10) is wired through it. | ALWAYS (widgets area) | none (generic) |
| `lib/core/services/analytics/analytics_service.dart` | `abstract interface class AnalyticsService` — the tracker calls `track`, `screenView`, `checkNudges`. | CONDITIONAL(analytics) (analytics area) | `checkNudges(BuildContext, String route)` is a Katyayani Core concept. |
| `lib/core/services/analytics/app_events.dart` | `abstract final class AppEvents` — `navBarIconTapped = 'Nav Bar Icon Tapped'`, `screenLoad = 'Screen Load'` are the two the router uses. | CONDITIONAL(analytics) | Event name strings (RN app's names). |
| `lib/core/services/analytics/ko_analytics_service.dart` | `KoAnalyticsService implements AnalyticsService` over `KoEngagementService`; tests wrap the fake engagement in it. | MYMALI-SPECIFIC (Katyayani Core) | — |
| `lib/core/services/analytics/analytics_item.dart` | `AnalyticsItem` value class (imported by the service interface). | CONDITIONAL(analytics) | — |
| `lib/features/home/presentation/home/pages/home_page.dart` | Call site: tab-to-tab `goNamed(categories, queryParameters: …)` (search nonce, banner targets). | MYMALI-SPECIFIC (pattern 3.6, 3.8) | — |
| `lib/features/home/presentation/home/widgets/home_section_view.dart` | Call site: `goNamed(categories, queryParameters: {stockParam | categoryParam})`. | MYMALI-SPECIFIC (pattern 3.6) | — |
| `lib/features/home/presentation/home/widgets/home_header.dart` | Call sites: `pushNamed(notifications)`, `pushNamed(selectLocation)`, `pushNamed(coins)` — full-screen pushes over the bar. | MYMALI-SPECIFIC (pattern 3.4, 3.8) | — |
| `lib/features/catalog/presentation/categories/pages/categories_page.dart` | The tab page that *reads* query parameters: `categoryParam`, `stockParam`, `searchParam`, `newSearchRequest()`, `didUpdateWidget` re-entry. | MYMALI-SPECIFIC (pattern 3.6) | — |
| `lib/features/product/presentation/product_detail/pages/product_detail_page.dart` | Path-parameter page: `static const idParam = 'id'`, `static void open(context, productId)` → `pushNamed(pathParameters:)`; back helper `_back`. | MYMALI-SPECIFIC (pattern 3.5, 3.10) | — |
| `lib/features/product/presentation/product_detail/widgets/product_image_viewer.dart` | Imperative full-screen push on the root navigator: `Navigator.of(context, rootNavigator: true).push<int>(PageRouteBuilder(...))`, `PopScope<int>`. | MYMALI-SPECIFIC (pattern 3.12) | — |
| `lib/features/address/presentation/address_form/pages/address_form_page.dart` | `class AddressFormArgs` (the `extra` of `addressForm`) lives at the top of the page file; `_close` pops with a typed result. | MYMALI-SPECIFIC (pattern 3.7) | — |
| `lib/features/checkout/presentation/order_placed/pages/order_placed_page.dart` | `class OrderPlacedArgs` (the `extra` of `orderPlaced`) at the top of the page file; `PopScope(canPop: false)` → `_goHome`; `pushNamed(invoice, extra:)`, `pushNamed(orderDetails, pathParameters:, extra:)`. | MYMALI-SPECIFIC (patterns 3.5, 3.7, 3.11) | — |
| `lib/features/checkout/presentation/review_pay/pages/review_pay_page.dart` | `goNamed(orderPlaced, extra: OrderPlacedArgs(...))` (stack replace), `pushNamed<SavedAddress>(addressForm, extra: AddressFormArgs(...))` awaiting a result, `PopScope(canPop: !isPlacing)`, sheets on the root navigator. | MYMALI-SPECIFIC (patterns 3.7, 3.8, 3.11, 3.12) | — |
| `lib/features/checkout/presentation/review_pay/widgets/delivery_address_sheet.dart`, `payment_method_sheet.dart` | `showXSheet(context, …)` functions wrapping `AppPickerSheet.show<T>`; choices pop a value with `Navigator.of(context).pop(value)`. `DeliveryAddressPick` result class. | MYMALI-SPECIFIC (pattern 3.12) | — |
| `lib/features/gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart` | A sheet with its *own* `BlocProvider` inside the root-navigator builder (page blocs are not reachable there). | MYMALI-SPECIFIC (pattern 3.12) | — |
| `lib/features/catalog/presentation/categories/widgets/catalog_filter_sheets.dart` | Generic-shaped `showCatalogOptionSheet<T>` / `showCatalogChipsSheet<T>` / `showCatalogPriceSheet` over `AppPickerSheet.show`. | MYMALI-SPECIFIC (pattern 3.12) | — |
| `lib/features/invoice/presentation/invoice/pages/invoice_page.dart` | Page whose `extra` is a domain entity (`Invoice`) directly; back pattern. | MYMALI-SPECIFIC (pattern 3.7, 3.10) | — |
| `lib/features/orders/presentation/order_details/pages/order_details_page.dart` | Path param (`idParam = 'id'`) **and** optional `extra` (`WarehouseOrder? initial`). | MYMALI-SPECIFIC (pattern 3.5, 3.7) | — |
| `lib/features/orders/presentation/my_orders/pages/my_orders_page.dart` | `pushNamed(orderDetails, pathParameters: {OrderDetailsPage.idParam: order.id}, extra: order)`. | MYMALI-SPECIFIC (pattern 3.5) | — |
| `lib/features/orders/presentation/utils/buy_again_to_cart.dart` | Navigation from a free function given a `BuildContext` (`context.pushNamed(AppRoute.cart.name)`). | MYMALI-SPECIFIC | — |
| `lib/features/cart/presentation/widgets/cart_bar_overlay.dart` | `pushNamed(cart)` from a floating pill; `MediaQuery.paddingOf(context).bottom` as the bar height contract. | MYMALI-SPECIFIC (pattern 3.4, 3.16) | — |
| `lib/features/wishlist/presentation/pages/wishlist_page.dart` | A tab page's back → `goNamed(home)`; empty state → `goNamed(categories)`. | MYMALI-SPECIFIC (pattern 3.8, 3.10) | — |
| `lib/features/account/presentation/account/pages/account_page.dart` | `push(AppRoute route) => context.pushNamed(route.name)` local helper; `goNamed(wishlist)` to a tab; sign-out `BlocListener<AuthBloc>` → `goNamed(login)`. | MYMALI-SPECIFIC (patterns 3.8, 3.14) | — |
| `lib/features/auth/presentation/login/pages/login_page.dart` | `BlocListener<AuthBloc>` → `goNamed(home)` once `Authenticated`; `PopScope` to step back inside the page. | MYMALI-SPECIFIC (pattern 3.14) | — |
| `lib/features/notifications/presentation/notifications/pages/notifications_page.dart` | Back pattern with fallback home; the one route **missing** from `analyticsScreenNames`. | MYMALI-SPECIFIC | — |
| `lib/features/cart/presentation/cart/widgets/cart_header.dart`, `lib/features/wishlist/presentation/widgets/wishlist_header.dart` | Feature wrappers of `PageHeader` passing `backKey: Key('cart_backButton')` / `Key('wishlist_backButton')`. | MYMALI-SPECIFIC (shape ALWAYS) | — |
| `lib/core/di/injection_container.dart` | Registers `AnalyticsService` (`MultiDestinationAnalyticsService`). The router is **not** registered in `get_it`. | ALWAYS (DI area) | — |
| `test/core/router/analytics_screen_tracker_test.dart` | Tracker unit/widget tests over a plain `MaterialApp` with one navigator. | CONDITIONAL(analytics) | Screen names asserted (`'Cart'`, `'ShopTab'`, …). |
| `test/features/home/presentation/widgets/app_shell_scaffold_test.dart` | Full-app tests: signed-in launch lands home with the bar; each tab; tabs stay alive (`IndexedStack`); cart covers the bar and pops back to its tab. | CONDITIONAL(bottom tabs) | Fakes registered, tab ids. |
| `test/features/home/presentation/widgets/app_bottom_nav_bar_test.dart` | Bar-only tests: tap indices, badge, semantics labels. | CONDITIONAL(bottom tabs) | Tab ids/labels. |
| `test/helpers/signed_in_app.dart` | `registerSignedInApp(...)`, `launchSignedInApp(tester)` (`AppRouter(analytics: sl<AnalyticsService>()).router`), `openAccountTab`, `scrollAccountTo`. | MYMALI-SPECIFIC content; shape ALWAYS | Fakes list. |
| `test/helpers/fake_ko_engagement_service.dart` | `FakeKoEngagementService` recording `events`, `tracked`, `screens`; `registerFakeEngagement()`. | MYMALI-SPECIFIC (Katyayani Core) | — |
| `test/widget_test.dart` | Splash → login (no session) / home (stored session); sign-out from Account returns to login. | CONDITIONAL(auth) | — |
| `pubspec.yaml` | `go_router: ^18.0.2` | ALWAYS | version |

---

## 2. Names

| Name | Kind | File | Exact signature / shape |
|---|---|---|---|
| `AppRoute` | enum | `lib/core/router/app_routes.dart` | see block below; `const AppRoute(this.path); final String path;` — go_router's `name:` is the enum's built-in `.name` |
| `AppRouter` | class | `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics}) : _tracker = analytics == null ? null : AnalyticsScreenTracker(analytics);` |
| `AppRouter.router` | field | same | `late final GoRouter router = GoRouter(navigatorKey: rootNavigatorKey, observers: _observers(), initialLocation: AppRoute.splash.path, routes: [...]);` |
| `AppRouter._tracker` | private field | same | `final AnalyticsScreenTracker? _tracker;` |
| `AppRouter._observers` | private method | same | `List<NavigatorObserver> _observers() => [?_tracker?.observer()];` (a **new** observer per call: one per navigator) |
| `rootNavigatorKey` | top-level final | `lib/core/router/navigator_keys.dart` | `final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');` |
| `homeNavigatorKey`, `categoriesNavigatorKey`, `gardenNavigatorKey`, `wishlistNavigatorKey`, `accountNavigatorKey` | top-level finals | same | `GlobalKey<NavigatorState>(debugLabel: '<tab>')` |
| `analyticsScreenNames` | `const Map<String, String>` | `lib/core/router/analytics_screen_tracker.dart` | keyed by `AppRoute.<x>.name` **strings**, value = screen name reported |
| `analyticsTabs` | `const List<AppRoute>` | same | `[AppRoute.home, AppRoute.categories, AppRoute.garden, AppRoute.wishlist, AppRoute.account]` — must match branch order |
| `AnalyticsScreenTracker` | class | same | `AnalyticsScreenTracker(this._analytics); final AnalyticsService _analytics;` |
| `AnalyticsScreenTracker._ignored` | `static final Set<String>` | same | `{AppRoute.splash.name}` |
| `AnalyticsScreenTracker._current`, `_tab` | `String?` fields | same | last reported route name; the tab on show |
| `AnalyticsScreenTracker.observer` | method | same | `NavigatorObserver observer() => AnalyticsRouteObserver(this);` |
| `AnalyticsScreenTracker.tabSelected` | method | same | `void tabSelected(int index)` |
| `AnalyticsScreenTracker.routeShown` | method | same | `void routeShown(Route<dynamic> route, {BuildContext? context})` |
| `AnalyticsScreenTracker._show` | private | same | `void _show(String name, BuildContext? context)` |
| `AnalyticsScreenTracker._screenNameFor` | private static | same | `static String _screenNameFor(String routeName) => analyticsScreenNames[routeName] ?? routeName;` |
| `AnalyticsRouteObserver` | class | same | `class AnalyticsRouteObserver extends NavigatorObserver { AnalyticsRouteObserver(this._tracker); ... didPush, didReplace, didPop }` |
| `AppShellScaffold` | widget | `lib/features/home/presentation/widgets/app_shell_scaffold.dart` | `const AppShellScaffold({required this.navigationShell, this.onTabSelected, super.key}); final StatefulNavigationShell navigationShell; final ValueChanged<int>? onTabSelected;` |
| `AppBottomNavBar` | widget | `lib/features/home/presentation/widgets/app_bottom_nav_bar.dart` | `const AppBottomNavBar({required this.currentIndex, required this.onTap, this.wishlistCount = 0, super.key}); final int currentIndex; final ValueChanged<int> onTap; final int wishlistCount;` |
| `_NavItem` | private class | same | `const _NavItem(this.id, this.label, this.icon); final String id; final String label; final IconData? icon;` |
| tab keys | `Key` | same | `Key('shell_${item.id}Tab')`, `Key('shell_${item.id}Badge')` → `shell_homeTab`, `shell_categoriesTab`, `shell_gardenTab`, `shell_wishlistTab`, `shell_accountTab`, `shell_wishlistBadge` |
| `App` | widget | `lib/app/app.dart` | `const App({super.key, required this.router}); final GoRouter router; static const double maxTextScaleFactor = 1.1;` |
| `bootstrap` | function | `lib/app/bootstrap.dart` | `Future<void> bootstrap() async { ... runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router)); }` |
| `SplashPage` | widget | `lib/features/auth/presentation/splash/pages/splash_page.dart` | `const SplashPage({super.key}); static const Duration displayDuration = Duration(milliseconds: 2600);` |
| `_SplashPageState._isResolved` | private static | same | `static bool _isResolved(AuthState state) => state is Authenticated || state is Unauthenticated;` |
| `ProductDetailPage.idParam` | `static const String` | `lib/features/product/presentation/product_detail/pages/product_detail_page.dart` | `'id'` |
| `ProductDetailPage.open` | static method | same | `static void open(BuildContext context, String productId)` |
| `OrderDetailsPage.idParam` | `static const String` | `lib/features/orders/presentation/order_details/pages/order_details_page.dart` | `'id'` |
| `OrderDetailsPage` ctor | widget | same | `const OrderDetailsPage({super.key, required this.orderId, this.initial}); final String orderId; final WarehouseOrder? initial;` |
| `CategoriesPage.categoryParam`, `stockParam`, `searchParam` | `static const String` | `lib/features/catalog/presentation/categories/pages/categories_page.dart` | `'category'`, `'stock'`, `'search'` |
| `CategoriesPage.newSearchRequest` | static method | same | `static String newSearchRequest() => DateTime.now().microsecondsSinceEpoch.toString();` |
| `CategoriesPage` ctor | widget | same | `const CategoriesPage({super.key, this.categoryName, this.stockFilter, this.searchRequest});` |
| `AddressFormArgs` | class (route `extra`) | `lib/features/address/presentation/address_form/pages/address_form_page.dart` | `const AddressFormArgs({this.address, this.makeDefault = false}); final SavedAddress? address; final bool makeDefault;` |
| `OrderPlacedArgs` | class (route `extra`) | `lib/features/checkout/presentation/order_placed/pages/order_placed_page.dart` | `const OrderPlacedArgs({required this.order, this.items = const [], this.address, this.gstin = ''});` |
| `DeliveryAddressPick` | class (sheet result) | `lib/features/checkout/presentation/review_pay/widgets/delivery_address_sheet.dart` | `const DeliveryAddressPick.saved(SavedAddress this.address); const DeliveryAddressPick.addNew() : address = null; final SavedAddress? address;` |
| `AppPickerSheet.show` | static method | `lib/core/widgets/sheets/app_picker_sheet.dart` | `static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder})` |
| `AppPickerSheet.closeKey` | `static const Key` | same | `Key('appPickerSheet_closeButton')` |
| `AppInfoSheet.show` | static method | `lib/core/widgets/sheets/app_info_sheet.dart` | `static Future<bool> show(BuildContext context, {required String title, required String message, AppInfoSheetTone tone = AppInfoSheetTone.info, IconData? icon, String actionLabel = defaultActionLabel, Key? key})` |
| `AppInfoSheet.actionKey`, `closeKey`, `defaultActionLabel` | statics | same | `Key('appInfoSheet_actionButton')`, `Key('appInfoSheet_closeButton')`, `'Got it'` |
| `AppInfoSheetTone` | enum | same | `info, success, error` |
| `PageHeader` | widget | `lib/core/widgets/page_header.dart` | `const PageHeader({super.key, required this.title, required this.onBack, this.subtitle, this.subtitleKey, this.backKey, this.backTooltip = 'Back', this.trailing, this.bottom});` |
| `AppEvents.navBarIconTapped` | `static const String` | `lib/core/services/analytics/app_events.dart` | `'Nav Bar Icon Tapped'` |
| `AppEvents.screenLoad` | `static const String` | same | `'Screen Load'` |
| `AnalyticsService.track` | method | `lib/core/services/analytics/analytics_service.dart` | `void track(String name, {Map<String, dynamic>? properties});` |
| `AnalyticsService.screenView` | method | same | `void screenView(String screenName, {Map<String, dynamic>? properties});` |
| `AnalyticsService.checkNudges` | method | same | `void checkNudges(BuildContext context, String route);` |
| `registerSignedInApp` | test helper | `test/helpers/signed_in_app.dart` | `void registerSignedInApp({FakeAuthRepository? auth, FakeMaliCoinsRepository? coins, FakeWishlistRepository? wishlist, FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account, FakeKoEngagementService? engagement})` |
| `launchSignedInApp` | test helper | same | `Future<void> launchSignedInApp(WidgetTester tester)` |
| `openAccountTab` | test helper | same | `Future<void> openAccountTab(WidgetTester tester)` — taps `Key('shell_accountTab')` |
| `registerFakeEngagement` | test helper | `test/helpers/fake_ko_engagement_service.dart` | `FakeKoEngagementService registerFakeEngagement()` — registers `KoEngagementService` and `AnalyticsService` (`KoAnalyticsService(fake)`) |
| `FakeKoEngagementService.screens` / `.tracked` / `.events` | fields | same | `List<String> screens`, `List<({String name, Map<String, dynamic>? properties})> tracked`, `List<String> events` |
| `cart_backButton`, `wishlist_backButton`, `invoice_backButton`, `product_failureBackButton` | test keys | feature headers/pages | `backKey: const Key('cart_backButton')` etc. |

### 2.1 The `AppRoute` enum, verbatim

```dart
/// Single source of truth for route names and paths.
///
/// Navigate with `context.goNamed(AppRoute.login.name)` rather than
/// hardcoding path strings in widgets.
enum AppRoute {
  splash('/splash'),
  login('/login'),

  // Bottom-navigation tabs, in tab order.
  home('/home'),
  categories('/categories'),
  garden('/garden'),
  wishlist('/wishlist'),
  account('/account'),

  // Full-screen routes that cover the bottom navigation bar.
  cart('/cart'),
  selectLocation('/select-location'),
  coins('/coins'),
  reviewPay('/review-pay'),
  orderPlaced('/order-placed'),
  invoice('/invoice'),
  applyCoupon('/apply-coupon'),
  savedAddresses('/saved-addresses'),

  /// Add or edit an address; pass an `AddressFormArgs` as `extra`.
  addressForm('/address-form'),

  /// Change the name, email and photo; the phone number is locked.
  editProfile('/edit-profile'),

  /// The user's referral code, their referral stats and a friend's code.
  referral('/refer'),

  /// The saved GSTIN and how to claim GST on orders.
  gstClaims('/gst-claims'),

  /// The in-app notification inbox.
  notifications('/notifications'),

  /// How to reach support, and answers to common questions.
  helpSupport('/help'),

  /// One product; pass its id as the `id` path parameter.
  productDetail('/product/:id'),

  /// The customer's orders, from the warehouse.
  myOrders('/orders'),

  /// One order; pass its number as the `id` path parameter, and the
  /// `WarehouseOrder` already in hand, if any, as `extra`.
  orderDetails('/orders/:id');

  const AppRoute(this.path);

  final String path;
}
```

Shape rules encoded: (1) three groups in this order — pre-auth (`splash`, `login`), tabs "in tab order", full-screen routes; (2) a route that takes a path parameter, query parameters or `extra` gets a `///` doc comment naming the parameter and the args type; (3) paths are kebab-case; names are the enum identifiers (camelCase); (4) nested resources use `'/orders/:id'` under `'/orders'`.

### 2.2 `navigator_keys.dart`, verbatim

```dart
import 'package:flutter/widgets.dart';

/// The app's top-level navigator. Routes registered with
/// `parentNavigatorKey: rootNavigatorKey` cover the bottom navigation bar.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

// One navigator per bottom-navigation tab, so each tab keeps its own stack.
final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
final GlobalKey<NavigatorState> categoriesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'categories');
final GlobalKey<NavigatorState> gardenNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'garden',
);
final GlobalKey<NavigatorState> wishlistNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'wishlist');
final GlobalKey<NavigatorState> accountNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'account',
);
```

### 2.3 `analytics_screen_tracker.dart`, verbatim (complete file)

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

Note: the route `notifications` is **absent** from `analyticsScreenNames`, so it is reported as `notifications` (fallback to its own name). See section 4.

---

## 3. Patterns

### 3.1 The router class (complete `app_router.dart` skeleton with every route)

```dart
class AppRouter {
  /// [analytics] reports every screen the user lands on (see
  /// [AnalyticsScreenTracker]); without it nothing is reported.
  AppRouter({AnalyticsService? analytics})
    : _tracker = analytics == null ? null : AnalyticsScreenTracker(analytics);

  final AnalyticsScreenTracker? _tracker;

  /// One observer per navigator: the root and each tab have their own.
  List<NavigatorObserver> _observers() => [?_tracker?.observer()];

  // Authentication guards will be added here as a `redirect` once
  // AuthBloc exposes real session state.
  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: _observers(),
    initialLocation: AppRoute.splash.path,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginPage(),
      ),
      // The signed-in app: one branch per bottom-navigation tab. Each branch
      // keeps its own navigator, and IndexedStack keeps every visited tab
      // alive while another is shown.
      // TODO(routing): nested sub-routes per branch (product/:id, etc.) come
      // with each feature's implementation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShellScaffold(
          navigationShell: navigationShell,
          onTabSelected: _tracker?.tabSelected,
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            observers: _observers(),
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: categoriesNavigatorKey,
            observers: _observers(),
            routes: [
              GoRoute(
                path: AppRoute.categories.path,
                name: AppRoute.categories.name,
                // Home's "View All" passes the rail's category name, or
                // the Coming Soon availability filter; its search bar
                // passes a search request.
                builder: (context, state) => CategoriesPage(
                  categoryName:
                      state.uri.queryParameters[CategoriesPage.categoryParam],
                  stockFilter:
                      StockFilter.values.asNameMap()[state
                          .uri
                          .queryParameters[CategoriesPage.stockParam]],
                  searchRequest:
                      state.uri.queryParameters[CategoriesPage.searchParam],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: gardenNavigatorKey,
            observers: _observers(),
            routes: [
              GoRoute(
                path: AppRoute.garden.path,
                name: AppRoute.garden.name,
                builder: (context, state) => const GardenHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: wishlistNavigatorKey,
            observers: _observers(),
            routes: [
              GoRoute(
                path: AppRoute.wishlist.path,
                name: AppRoute.wishlist.name,
                builder: (context, state) => const WishlistPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: accountNavigatorKey,
            observers: _observers(),
            routes: [
              GoRoute(
                path: AppRoute.account.path,
                name: AppRoute.account.name,
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen: pushed on the root navigator, so it covers the bar.
      GoRoute(
        path: AppRoute.cart.path,
        name: AppRoute.cart.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: AppRoute.selectLocation.path,
        name: AppRoute.selectLocation.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SelectLocationPage(),
      ),
      GoRoute(
        path: AppRoute.coins.path,
        name: AppRoute.coins.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CoinsPage(),
      ),
      GoRoute(
        path: AppRoute.reviewPay.path,
        name: AppRoute.reviewPay.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReviewPayPage(),
      ),
      GoRoute(
        path: AppRoute.orderPlaced.path,
        name: AppRoute.orderPlaced.name,
        parentNavigatorKey: rootNavigatorKey,
        // Only reachable with the order just placed.
        redirect: (context, state) =>
            state.extra is OrderPlacedArgs ? null : AppRoute.home.path,
        builder: (context, state) =>
            OrderPlacedPage(args: state.extra! as OrderPlacedArgs),
      ),
      GoRoute(
        path: AppRoute.invoice.path,
        name: AppRoute.invoice.name,
        parentNavigatorKey: rootNavigatorKey,
        // Only reachable with the invoice to show.
        redirect: (context, state) =>
            state.extra is Invoice ? null : AppRoute.home.path,
        builder: (context, state) =>
            InvoicePage(invoice: state.extra! as Invoice),
      ),
      GoRoute(
        path: AppRoute.applyCoupon.path,
        name: AppRoute.applyCoupon.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ApplyCouponPage(),
      ),
      GoRoute(
        path: AppRoute.savedAddresses.path,
        name: AppRoute.savedAddresses.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SavedAddressesPage(),
      ),
      GoRoute(
        path: AppRoute.addressForm.path,
        name: AppRoute.addressForm.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is AddressFormArgs
              ? extra
              : const AddressFormArgs();
          return AddressFormPage(
            address: args.address,
            makeDefault: args.makeDefault,
          );
        },
      ),
      GoRoute(
        path: AppRoute.editProfile.path,
        name: AppRoute.editProfile.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoute.referral.path,
        name: AppRoute.referral.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReferralPage(),
      ),
      GoRoute(
        path: AppRoute.gstClaims.path,
        name: AppRoute.gstClaims.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GstClaimsPage(),
      ),
      GoRoute(
        path: AppRoute.notifications.path,
        name: AppRoute.notifications.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoute.helpSupport.path,
        name: AppRoute.helpSupport.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoute.productDetail.path,
        name: AppRoute.productDetail.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ProductDetailPage(
          // A new page per product, so opening a similar product from
          // this one starts afresh.
          key: state.pageKey,
          productId: state.pathParameters[ProductDetailPage.idParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoute.myOrders.path,
        name: AppRoute.myOrders.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: AppRoute.orderDetails.path,
        name: AppRoute.orderDetails.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OrderDetailsPage(
          key: state.pageKey,
          orderId: state.pathParameters[OrderDetailsPage.idParam] ?? '',
          initial: state.extra is WarehouseOrder
              ? state.extra! as WarehouseOrder
              : null,
        ),
      ),
    ],
  );
}
```

Rules it encodes (copy): one `GoRouter`, built eagerly as a `late final` field; `navigatorKey: rootNavigatorKey`; `observers: _observers()` on the root **and** `observers: _observers()` on every branch (a fresh observer each time); `initialLocation` is the splash **path**; every `GoRoute` has `path: AppRoute.x.path` and `name: AppRoute.x.name` (never literals); every route outside the shell has `parentNavigatorKey: rootNavigatorKey`; `const` page constructors wherever there are no params; the router is **not** in `get_it` — `bootstrap` constructs it and hands `.router` to `App`.

What varies: the imports, the branches, the list of full-screen routes, which routes guard `extra`.

Imports of `app_router.dart` are `package:flutter/widgets.dart`, `package:go_router/go_router.dart`, every page, two domain entities used as `extra` (`Invoice`, `WarehouseOrder`), one domain enum decoded from a query param (`StockFilter` in `catalog_filters.dart`), `AnalyticsService`, and the three router siblings.

### 3.2 The shell widget (complete `app_shell_scaffold.dart`)

```dart
/// Wraps the signed-in tabs: shows the active branch behind the floating
/// bottom bar. Hearts can be tapped on any tab, so the message for a
/// wishlist change the server refused is shown from here.
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.navigationShell,
    this.onTabSelected,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// Called with the tab's index when the user taps the bottom bar.
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final wishlistCount = context.select(
      (WishlistBloc bloc) => bloc.state.count,
    );

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
      child: Scaffold(
        // The bar floats, so each tab's content runs underneath it; pages
        // get the bar's height as bottom MediaQuery padding.
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          wishlistCount: wishlistCount,
          // Tapping the active tab again pops it back to its root.
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
            onTabSelected?.call(index);
          },
        ),
      ),
    );
  }
}
```

Generic core to copy: `Scaffold(extendBody: true, body: navigationShell, bottomNavigationBar: <bar>(currentIndex: navigationShell.currentIndex, onTap: (index) { navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex); onTabSelected?.call(index); }))`. MyMali-specific: the `WishlistBloc` listener and `wishlistCount`.

### 3.3 The bottom bar's data shape (from `app_bottom_nav_bar.dart`)

```dart
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.wishlistCount = 0,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Shown as a badge on the Wishlist tab when greater than zero.
  final int wishlistCount;

  static const int _centerIndex = 2;
  static const int _wishlistIndex = 3;

  static const double _barHeight = 64;
  static const double _centerSize = 64;

  /// How far the centre button rises above the bar's top edge.
  static const double _centerLift = 24;

  static const List<_NavItem> _items = [
    _NavItem('home', 'Home', Icons.home_outlined),
    _NavItem('categories', 'Categories', Icons.grid_view_outlined),
    _NavItem('garden', 'Garden', null),
    _NavItem('wishlist', 'Wishlist', Icons.favorite_border_rounded),
    _NavItem('account', 'Account', Icons.person_outline_rounded),
  ];
  // ...
}

class _NavItem {
  const _NavItem(this.id, this.label, this.icon);

  /// Used for the tab's test key, e.g. `shell_homeTab`.
  final String id;
  final String label;

  /// Null for the centre tab, which draws its own sprout.
  final IconData? icon;
}
```

Per tab: `Semantics(label: item.label, selected: selected, button: true, excludeSemantics: true, child: InkResponse(key: Key('shell_${item.id}Tab'), onTap: onTap, ...))`, badge `Badge(key: Key('shell_${item.id}Badge'), isLabelVisible: badgeCount > 0, label: Text(badgeCount > 99 ? '99+' : '$badgeCount'), ...)`. Colours only from `Theme.of(context).colorScheme` (`inverseSurface`, `onInverseSurface`, `secondaryContainer`, `onSecondaryContainer`, `shadow`). `_items` order **must equal** the branch order in `app_router.dart` and `analyticsTabs`. `MediaQuery.viewPaddingOf(context).bottom` is used for the home-indicator gap: `math.max(12.0, bottomInset - 12)`.

### 3.4 Full-screen route over the bar + push call site

Route (every full-screen route):

```dart
      // Full-screen: pushed on the root navigator, so it covers the bar.
      GoRoute(
        path: AppRoute.cart.path,
        name: AppRoute.cart.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CartPage(),
      ),
```

Call sites use `pushNamed` (so `pop` returns to the tab it was pushed over):

```dart
// lib/features/cart/presentation/widgets/cart_bar_overlay.dart
          onPressed: () => context.pushNamed(AppRoute.cart.name),
// lib/features/home/presentation/home/widgets/home_header.dart
                onPressed: () => context.pushNamed(AppRoute.notifications.name),
        onTap: () => context.pushNamed(AppRoute.selectLocation.name),
          onTap: () => context.pushNamed(AppRoute.coins.name),
// lib/features/account/presentation/account/pages/account_page.dart
    void push(AppRoute route) => context.pushNamed(route.name);
```

Verified by `app_shell_scaffold_test.dart` "cart covers the bottom bar and pops back to its tab": after `router.pushNamed(AppRoute.cart.name)` from the wishlist tab, `find.byType(AppBottomNavBar)` is `findsNothing`; tapping `Key('cart_backButton')` returns to `WishlistPage` with `selectedIndex == 3`.

### 3.5 Path parameter (`/product/:id`, `/orders/:id`)

The page owns the parameter name and (for product) a static opener:

```dart
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  /// The path parameter that carries [productId].
  static const String idParam = 'id';

  final String productId;

  /// Opens the page for [productId] above the current screen.
  static void open(BuildContext context, String productId) {
    context.pushNamed(
      AppRoute.productDetail.name,
      pathParameters: {idParam: productId},
    );
  }
  // ...
}
```

Callers: `ProductDetailPage.open(context, product.id)` in `catalog_product_card.dart`, `wishlist_product_tile.dart`, `cart_line_tile.dart`.

Route reads it and keys the page by `state.pageKey`:

```dart
        builder: (context, state) => ProductDetailPage(
          // A new page per product, so opening a similar product from
          // this one starts afresh.
          key: state.pageKey,
          productId: state.pathParameters[ProductDetailPage.idParam] ?? '',
        ),
```

Path parameter **plus** optional `extra` (My Orders → Order Details):

```dart
// my_orders_page.dart
      context.pushNamed(
        AppRoute.orderDetails.name,
        pathParameters: {OrderDetailsPage.idParam: order.id},
        extra: order,
      );
// order_placed_page.dart
    context.pushNamed(
      AppRoute.orderDetails.name,
      pathParameters: {OrderDetailsPage.idParam: orderNumber},
      extra: context.read<OrderPlacedBloc>().state.warehouseOrder,
    );
```

Tests push the same way: `router.pushNamed(AppRoute.productDetail.name, pathParameters: {ProductDetailPage.idParam: 'prod_01'});`.

### 3.6 Query parameters on a tab route (`/categories?category=…&stock=…&search=…`)

Page owns the parameter names and a nonce helper:

```dart
  /// Query parameter names the route reads for the fields above.
  static const String categoryParam = 'category';
  static const String stockParam = 'stock';
  static const String searchParam = 'search';

  /// A [searchParam] value that differs from every earlier one.
  static String newSearchRequest() =>
      DateTime.now().microsecondsSinceEpoch.toString();
```

Route decodes them (`asNameMap()` for an enum):

```dart
                builder: (context, state) => CategoriesPage(
                  categoryName:
                      state.uri.queryParameters[CategoriesPage.categoryParam],
                  stockFilter:
                      StockFilter.values.asNameMap()[state
                          .uri
                          .queryParameters[CategoriesPage.stockParam]],
                  searchRequest:
                      state.uri.queryParameters[CategoriesPage.searchParam],
                ),
```

Call sites use `goNamed` (tab to tab):

```dart
// home_page.dart
    context.goNamed(
      AppRoute.categories.name,
      queryParameters: {
        CategoriesPage.searchParam: CategoriesPage.newSearchRequest(),
      },
    );
// home_section_view.dart
    context.goNamed(
      AppRoute.categories.name,
      queryParameters: section.isComingSoon
          ? {CategoriesPage.stockParam: StockFilter.comingSoon.name}
          : {CategoriesPage.categoryParam: section.title},
    );
```

Because the tab stays alive in the `IndexedStack`, the page's inner `StatefulWidget` applies new parameters in `didUpdateWidget`:

```dart
  @override
  void didUpdateWidget(covariant _CategoriesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab stays alive, so a later "View All" arrives as new params.
    final bloc = context.read<CategoriesBloc>();
    if (widget.categoryName != oldWidget.categoryName &&
        widget.categoryName != null) {
      bloc.add(CategorySelectedByName(widget.categoryName!));
    }
    if (widget.stockFilter != oldWidget.stockFilter &&
        widget.stockFilter != null) {
      bloc
        ..add(CategorySelected(null))
        ..add(StockFilterChanged(widget.stockFilter!));
    }
    if (widget.searchRequest != oldWidget.searchRequest &&
        widget.searchRequest != null) {
      bloc.add(CatalogSearchOpened());
    }
  }
```

### 3.7 `extra` — args classes, guards, typed results

Args classes are plain classes (no `Equatable`), `const` constructors, declared **at the top of the page file that consumes them** (not in `core/router/`, not in domain), named `<Page>Args`:

```dart
/// What the address form route is opened with, as its `extra`.
class AddressFormArgs {
  const AddressFormArgs({this.address, this.makeDefault = false});

  /// The address to edit; null adds a new one.
  final SavedAddress? address;

  /// Whether a new address is saved as the default, e.g. the first one.
  final bool makeDefault;
}
```

```dart
/// What the Thank You page is opened with: ...
class OrderPlacedArgs {
  const OrderPlacedArgs({
    required this.order,
    this.items = const [],
    this.address,
    this.gstin = '',
  });

  final PlacedOrder order;
  final List<CartItem> items;
  final SavedAddress? address;
  final String gstin;
}
```

A single domain entity may be the `extra` directly (`Invoice`, `WarehouseOrder`).

Three guard styles, chosen by whether the page can exist without the extra:

```dart
// (a) Required: redirect home when missing or of the wrong type.
        redirect: (context, state) =>
            state.extra is OrderPlacedArgs ? null : AppRoute.home.path,
        builder: (context, state) =>
            OrderPlacedPage(args: state.extra! as OrderPlacedArgs),

// (b) Optional with defaults: fall back to a const args instance.
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is AddressFormArgs
              ? extra
              : const AddressFormArgs();
          return AddressFormPage(
            address: args.address,
            makeDefault: args.makeDefault,
          );
        },

// (c) Optional hint beside a path parameter: null when absent.
          initial: state.extra is WarehouseOrder
              ? state.extra! as WarehouseOrder
              : null,
```

Tests for (a): `order_placed_page_test.dart` "opened without an order it goes Home" and `invoice_page_test.dart` "opened without an invoice it goes Home" push the route with no `extra` and assert the page is absent / `HomePage` is shown.

Typed result from a pushed route:

```dart
// review_pay_page.dart (caller)
    final saved = await context.pushNamed<SavedAddress>(
      AppRoute.addressForm.name,
      extra: AddressFormArgs(address: address, makeDefault: makeDefault),
    );
    if (saved != null && !bloc.isClosed) {
      bloc.add(ReviewPayAddressChanged(saved));
    }
// address_form_page.dart (callee)
  void _close(BuildContext context, [SavedAddress? saved]) {
    if (context.canPop()) {
      context.pop(saved);
    } else {
      context.goNamed(AppRoute.savedAddresses.name);
    }
  }
```

### 3.8 `goNamed` vs `pushNamed` (the rule the code follows)

| Situation | Call | Example |
|---|---|---|
| Tab → another tab | `context.goNamed(AppRoute.<tab>.name[, queryParameters: …])` | `wishlist_page.dart`: `onBack: () => context.goNamed(AppRoute.home.name)`; `account_page.dart`: `context.goNamed(AppRoute.wishlist.name)` |
| Any screen → a full-screen page | `context.pushNamed(AppRoute.<page>.name[, pathParameters: …][, extra: …])` | `home_header.dart`, `cart_bar_overlay.dart`, `my_orders_page.dart`, `review_pay_page.dart` (`applyCoupon`) |
| Flow end that must **replace** the stack | `context.goNamed(...)` | `review_pay_page.dart`: `context.goNamed(AppRoute.orderPlaced.name, extra: OrderPlacedArgs(...))` ("Thank You replaces this page") |
| Auth transitions | `context.goNamed(AppRoute.home.name)` / `context.goNamed(AppRoute.login.name)` | `splash_page.dart`, `login_page.dart`, `account_page.dart` |
| Leaving a full-screen page to a tab | `context.goNamed(AppRoute.home.name)` | `order_placed_page.dart` `_goHome`; `my_orders_page.dart` "Start Shopping" |

### 3.9 The tab-to-tab `go` (one complete call site)

```dart
// lib/features/wishlist/presentation/pages/wishlist_page.dart
                WishlistHeader(
                  itemCount: count,
                  // The wishlist is a tab, so "back" is the Home tab.
                  onBack: () => context.goNamed(AppRoute.home.name),
                ),
```

### 3.10 The back pattern (every pushed page)

```dart
/// Back to the previous screen, or Home when the page was opened directly.
void _back(BuildContext context) =>
    context.canPop() ? context.pop() : context.goNamed(AppRoute.home.name);
```

Inline form used by most headers:

```dart
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.goNamed(AppRoute.account.name),
```

The fallback is the screen that normally opens the page: `home` (cart, coins, notifications, invoice, product, saved addresses, select location), `account` (edit profile, referral, GST claims, help, my orders), `cart` (review & pay, apply coupon), `myOrders` (order details), `savedAddresses` (address form). The fallback also makes a cold deep-link open navigable.

### 3.11 Pages that intercept system back (`PopScope`)

```dart
// order_placed_page.dart — back and "Continue shopping" both go Home
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(...),
    );

// review_pay_page.dart — cannot leave while an order is being placed
        child: PopScope(
          canPop: !isPlacing,
          child: Stack(...),
        ),

// login_page.dart — system back steps the in-page PageView back
      child: PopScope(
        // On the OTP step, system back returns to the details step.
        canPop: step == LoginStep.details,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.read<LoginBloc>().add(EditPhoneNumber());
        },
```

### 3.12 Sheets and imperative pushes on the **root** navigator

The two generic sheets open with `useRootNavigator: true` so they cover the bottom bar:

```dart
// app_picker_sheet.dart
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      // Lets the sheet take the height its choices need.
      isScrollControlled: true,
      showDragHandle: true,
      builder: builder,
    );
  }

// app_info_sheet.dart
    final acted = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      // Lets a long message take the height it needs.
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => AppInfoSheet(
        key: key,
        title: title,
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: () => Navigator.of(sheetContext).pop(true),
        onClose: () => Navigator.of(sheetContext).pop(false),
      ),
    );
    return acted ?? false;
```

Feature wrapper: a top-level `show<Thing>Sheet(context, {...}) => AppPickerSheet.show<T>(context, builder: ...)` function; choices pop with `Navigator.of(context).pop(value)`:

```dart
Future<PaymentMethod?> showPaymentMethodSheet(
  BuildContext context, {
  required double? total,
  required PaymentMethod selected,
  double codCharge = 0,
}) {
  return AppPickerSheet.show<PaymentMethod>(
    context,
    builder: (context) => _PaymentMethodSheet(
      total: total,
      selected: selected,
      codCharge: codCharge,
    ),
  );
}
// inside: onTap: () => Navigator.of(context).pop(method),
```

A sheet that needs a bloc provides its **own** (the root navigator sits above a page's `BlocProvider`s; app-wide blocs provided in `App` remain reachable):

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

Imperative full-screen route on the root navigator (not a `GoRoute`; the only such case):

```dart
  static Future<int?> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context, rootNavigator: true).push<int>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, _, _) => ProductImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
  // and, to return the index on system back:
    return PopScope<int>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_index);
      },
```

Observer note: this `PageRouteBuilder` has no `settings.name`, so `routeShown` treats it as "back at the tab on show" (re-reports `_tab`, deduped by `_current`). Sheets and dialogs are not `PageRoute`s and are ignored by the observer.

### 3.13 The splash decides the first destination

```dart
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const Duration displayDuration = Duration(milliseconds: 2600);
  // ...
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
```

There is **no** `GoRouter.redirect` auth guard. Routing on auth changes happens in three UI listeners: splash (above), `LoginPage` (`BlocListener<AuthBloc, AuthState>(listener: _onAuthStateChanged)` → `if (state is Authenticated) context.goNamed(AppRoute.home.name);`), and `AccountPage` (`BlocListener<AuthBloc, AuthState>(listenWhen: (_, current) => current is Unauthenticated, listener: (context, _) => context.goNamed(AppRoute.login.name), ...)`).

### 3.14 Navigation lives in the UI, in `BlocListener`s or tap handlers

```dart
// account_page.dart
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, current) => current is Unauthenticated,
        listener: (context, _) => context.goNamed(AppRoute.login.name),
        child: const Scaffold(key: Key('account_page'), body: _AccountBody()),
      ),

// review_pay_page.dart
        BlocListener<ReviewPayBloc, ReviewPayState>(
          listenWhen: (previous, current) =>
              previous.placedOrder == null && current.placedOrder != null,
          listener: _finishOrder,
        ),
  void _finishOrder(BuildContext context, ReviewPayState state) {
    final cart = context.read<CartBloc>();
    final coupons = context.read<CouponBloc>();
    final variantIds = [for (final item in state.items) item.variantId];
    context.goNamed(
      AppRoute.orderPlaced.name,
      extra: OrderPlacedArgs(
        order: state.placedOrder!,
        items: state.items,
        address: state.address,
        gstin: state.gstin?.number ?? '',
      ),
    );
    cart.add(CartItemsRemoved(variantIds));
    if (coupons.state.applied != null) coupons.add(CouponRemoved());
  }
```

Verified: no file under any `bloc/` folder imports `go_router`; the `GoRouter` type appears only in `app.dart` and `app_router.dart`.

### 3.15 Wiring the router into the app

```dart
// bootstrap.dart
  runApp(App(router: AppRouter(analytics: sl<AnalyticsService>()).router));

// app.dart
class App extends StatelessWidget {
  const App({super.key, required this.router});

  final GoRouter router;

  /// Largest system font scale the app follows. Larger settings overflow
  /// fixed-height layouts such as the product tiles.
  static const double maxTextScaleFactor = 1.1;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [ /* app-wide blocs and RepositoryProvider<AnalyticsService> */ ],
      child: MultiBlocListener(
        listeners: [ /* cross-bloc wiring; none of them navigate */ ],
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

The providers sit **above** `MaterialApp.router`, which is why sheets opened on the root navigator can still `context.read` app-wide blocs, and why `AppShellScaffold` can `context.select` the `WishlistBloc`.

### 3.16 The bar-height contract between shell and pages

`AppShellScaffold` uses `Scaffold(extendBody: true)`, so a tab page receives the floating bar's height as `MediaQuery.paddingOf(context).bottom`. Pages therefore pad their scroll views:

```dart
// home_page.dart / categories_page.dart / wishlist_page.dart
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + CartBarOverlay.height;
    // ...
          SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
// cart_bar_overlay.dart — the floating pill sits above the bar
      bottom: MediaQuery.paddingOf(context).bottom + _bottomGap,
```

### 3.17 Screen analytics through the router (what a page never does)

- `AppRouter(analytics:)` creates one `AnalyticsScreenTracker`; `_observers()` makes a **new** `AnalyticsRouteObserver` for the root navigator and for each branch navigator.
- `onTabSelected: _tracker?.tabSelected` is passed to the shell; the bar calls it after `goBranch`.
- `_show` dedupes consecutive identical screens, records the tab on show, maps the route name through `analyticsScreenNames`, calls `screenView(screen)` and `track(AppEvents.screenLoad, {'screen_name': screen})`, then `checkNudges(context, '/$screen')` after the frame.
- The splash is never reported (`_ignored`). Sheets/dialogs are never reported (`route is! PageRoute`).
- No page calls `screenView` (grep: `screenView(` appears only in the analytics services and the tracker).

Test-proven behaviours (`analytics_screen_tracker_test.dart`): pushed page reported once by its RN name; pop reports the page on top again; `pushReplacementNamed` of the same name reports once; a dialog opening/closing reports nothing; a nameless route then pop re-reports the tab; `tabSelected` reports `navBarIconTapped` with `{'tab': <screen>}` even when revisiting, and the screen only on change; out-of-range index ignored; `check_nudges` is called after the frame; every tab has a screen name.

### 3.18 Router in widget tests

```dart
// Without analytics (most page tests):
    router = AppRouter().router;
    await tester.pumpWidget(App(router: router));
    await tester.pump(SplashPage.displayDuration);
    await tester.pumpAndSettle();
    unawaited(router.pushNamed(AppRoute.invoice.name, extra: _invoice));
    await tester.pumpAndSettle();

// With analytics (test/helpers/signed_in_app.dart):
  await tester.pumpWidget(
    App(router: AppRouter(analytics: sl<AnalyticsService>()).router),
  );

// Asserting the location:
    expect(router.state.matchedLocation, AppRoute.home.path);

// Tapping a tab:
    await tester.tap(find.byKey(Key('shell_${id}Tab')));

// System back:
    final popped = await tester.binding.handlePopRoute();
```

A fresh `AppRouter` per test (new tracker state, new `GlobalKey` owners). Phone view: `tester.view.physicalSize = const Size(1170, 2532); tester.view.devicePixelRatio = 3; addTearDown(tester.view.reset);`.

---

## 4. Rules observed in code (and differences from AGENTS.md)

1. **`pushNamed` is the norm for full-screen pages.** AGENTS.md §11 says only "Navigate with `context.goNamed(AppRoute.x.name)`. Never hardcode a path string." The code uses `context.pushNamed(AppRoute.x.name)` for every page that covers the bar and `goNamed` for tabs, the post-order replacement and auth transitions (section 3.8). AGENTS.md's reference sections do say "pushed by the cart's slide" and "Track Order pushes `AppRoute.orderDetails`", so the two agree in spirit; §11's wording is incomplete.
2. **`core/router/` holds four files, not two.** AGENTS.md §2: `router/ # app_router.dart, app_routes.dart`. Code adds `navigator_keys.dart` and `analytics_screen_tracker.dart` (the latter is described in §23).
3. **No auth `redirect` exists.** The code comment "Authentication guards will be added here as a `redirect` once AuthBloc exposes real session state." is stale: `AuthBloc` does expose `Authenticated` / `Unauthenticated` / `AuthLoading`, and routing is done by the splash and by UI listeners (section 3.13). AGENTS.md §17 describes exactly the splash flow and never mentions a redirect. Only two `redirect`s exist, both `extra` type guards.
4. **The `TODO(routing)` about nested sub-routes per branch was never followed.** Every feature route (`product/:id`, `orders/:id`, …) is a top-level `GoRoute` with `parentNavigatorKey: rootNavigatorKey`, so no tab has a nested stack. The actual rule: *a page that covers the bar is a root-level route*. A target app should not treat the TODO as a plan.
5. **`parentNavigatorKey: rootNavigatorKey` is on every top-level non-shell route.** These routes are siblings of the shell route, which by itself places them on the root navigator; the key is explicit belt-and-braces matching the `navigator_keys.dart` doc comment. Keep it, as the code does.
6. **`analyticsScreenNames` is missing `notifications`.** AGENTS.md §23: "add the name when you add a route". The route reports as `notifications`. The tracker test only asserts the five tabs have names, so this is not caught.
7. **Tab order is kept in four places by hand:** the branches in `app_router.dart`, the keys in `navigator_keys.dart`, `_items` (+ `_centerIndex`, `_wishlistIndex`) in `app_bottom_nav_bar.dart`, and `analyticsTabs` in `analytics_screen_tracker.dart`. Nothing enforces agreement except the shell test (ids ↔ pages ↔ indices).
8. **`redirect` returns a path, not a name:** `AppRoute.home.path`.
9. **Param routes are keyed by `state.pageKey`** (`productDetail`, `orderDetails`) so a push of the same route with another id builds a fresh page and bloc.
10. **Args classes live in the page file, not in `core/router/` or `domain/`.** Plain classes, `const`, no `Equatable`, named `<Page>Args`. Domain entities (`Invoice`, `WarehouseOrder`) may be the `extra` directly.
11. **Three `extra` guard styles** (section 3.7): required → `redirect` home; optional-with-defaults → `const Args()` fallback; optional hint → `null`.
12. **Back fallback per page:** `canPop() ? pop() : goNamed(<natural parent>)` (section 3.10); a tab page's back goes to `home`.
13. **Blocs never navigate**: confirmed by grep (no `go_router` import under any `bloc/`). Navigation is in `BlocListener`s (with `listenWhen`) or tap handlers. Free helper functions may navigate when handed a `BuildContext` (`addBuyAgainToCart`).
14. **Observers:** one `AnalyticsRouteObserver` instance per navigator, created by `_observers()` each time; the root has one and each branch has one. The tracker is one instance shared by all observers.
15. **Sign-out navigation lives only in `AccountPage`.** `app.dart`'s auth listener does not navigate; a sign-out triggered from elsewhere would not route to login (not an observed bug, a structural fact).
16. **`LoginPage`'s auth listener has no `listenWhen`**: `BlocListener<AuthBloc, AuthState>(listener: _onAuthStateChanged)`; it navigates on every `Authenticated` emission while the page is mounted.
17. **The `?` null-aware collection element** (`[?_tracker?.observer()]`) needs a Dart SDK with null-aware elements (Dart ≥ 3.8). `pubspec.yaml` has `sdk: ^3.13.4`. Older SDKs need `[if (_tracker != null) _tracker!.observer()]`.
18. **Router not in DI:** `AppRouter` is built in `bootstrap()` and the `GoRouter` is passed to `App(router:)`; `App` depends on `GoRouter`, not `AppRouter`.
19. **Page header back buttons use `PageHeader`** via feature wrappers (`CartHeader`, `WishlistHeader`); the product page's **failure** state uses a Material `BackButton` (`Key('product_failureBackButton')`) and the product page's loaded state uses its own `ProductImageHeader` — deviations from AGENTS.md §11 "every page with a back button … uses `PageHeader`" (widgets area; noted because the back pattern runs through them).
20. **`AppPickerSheet`/`AppInfoSheet` use `useRootNavigator: true`** and `isScrollControlled: true, useSafeArea: true, showDragHandle: true` — fixed; call sites never pass sheet options.
21. **Tracker ignores non-`PageRoute`s** both on push and pop; `didReplace` reports the new route. `didPop` reports `previousRoute` (the page that comes back on top).
22. **`tabSelected` is called after `goBranch`** and uses `rootNavigatorKey.currentContext` for nudges.
23. **AGENTS.md §22 vs code:** the OTP verify `AlertDialog` in `LoginPage` is the acknowledged legacy; the code still has it.
24. **`initialLocation` is the splash**, never home; the splash always runs `displayDuration` even with a stored session (tests must `pump(SplashPage.displayDuration)`).

---

## 5. Packages

| Package | Files (this area) | Class |
|---|---|---|
| `go_router` `^18.0.2` (lock `18.0.2`) | `lib/core/router/app_router.dart`, `lib/app/app.dart` (`GoRouter` type), `lib/features/home/presentation/widgets/app_shell_scaffold.dart` (`StatefulNavigationShell`, `goBranch`), every page/widget that navigates (`context.goNamed/pushNamed/canPop/pop`): `splash_page.dart`, `login_page.dart`, `home_page.dart`, `home_section_view.dart`, `home_header.dart`, `wishlist_page.dart`, `account_page.dart`, `cart_bar_overlay.dart`, `cart_page.dart`, `review_pay_page.dart`, `order_placed_page.dart`, `invoice_page.dart`, `my_orders_page.dart`, `order_details_page.dart`, `product_detail_page.dart`, `address_form_page.dart`, `saved_addresses_page.dart`, `select_location_page.dart`, `edit_profile_page.dart`, `referral_page.dart`, `gst_claims_page.dart`, `help_support_page.dart`, `coins_page.dart`, `notifications_page.dart`, `apply_coupon_page.dart`, `buy_again_to_cart.dart`; tests `app_shell_scaffold_test.dart` and every page test that builds `AppRouter().router` | ALWAYS |
| `flutter` (`widgets.dart` / `material.dart`) | all | ALWAYS |
| `flutter_bloc` | `app.dart`, `app_shell_scaffold.dart`, `splash_page.dart`, `login_page.dart`, pages | ALWAYS (stack) |
| `get_it` | `app.dart` (`sl<…>()` in `create:`), `bootstrap.dart` | ALWAYS (stack) |
| `loading_animation_widget` | `splash_page.dart` (`LoadingAnimationWidget.staggeredDotsWave`) | CONDITIONAL(splash spinner); MyMali look, substitutable |
| `url_launcher` | `home_page.dart` (banner web links) | MYMALI-SPECIFIC call site |
| `katyayani_core` (indirect, via `KoEngagementService.checkNudges`) | none of the router files import it; `analytics_screen_tracker.dart` calls `AnalyticsService.checkNudges` | MYMALI-SPECIFIC (drop the nudge call without KC) |
| `supabase_flutter`, `firebase_core`, `flutter_dotenv` (via `Env`) | `bootstrap.dart` only | CONDITIONAL (other areas) |
| `flutter_test` | tests | ALWAYS |

No `dev_dependencies` are specific to routing. No code generation (`go_router_builder` is **not** used; routes are hand-written).

---

## 6. What varies per app

| Item | Where it appears |
|---|---|
| Route names and paths (enum values, doc comments, the three groups) | `lib/core/router/app_routes.dart` |
| `initialLocation` (`AppRoute.splash.path`) | `app_router.dart` |
| Pre-auth routes (`splash`, `login`) | `app_router.dart` first two `GoRoute`s; `splash_page.dart` destinations |
| The tabs: count, order, pages | `app_router.dart` branches; `navigator_keys.dart` tab keys + `debugLabel`s; `app_bottom_nav_bar.dart` `_items`, `_centerIndex`, `_wishlistIndex`, badge source; `analytics_screen_tracker.dart` `analyticsTabs` |
| Tab test-key ids (`shell_<id>Tab`, `shell_<id>Badge`) | `app_bottom_nav_bar.dart` `_NavItem.id`; tests `app_shell_scaffold_test.dart`, `signed_in_app.dart`, `widget_test.dart` |
| Full-screen routes and their pages | `app_router.dart` after the shell route |
| Which routes guard `extra`, and the args types (`OrderPlacedArgs`, `Invoice`, `AddressFormArgs`, `WarehouseOrder`) | `app_router.dart` `redirect:` / `builder:`; the args classes in each page file |
| Path-parameter names (`idParam = 'id'`) and openers (`ProductDetailPage.open`) | page files |
| Query-parameter names (`categoryParam`, `stockParam`, `searchParam`) and nonce helper | `categories_page.dart` |
| Back fallbacks per page (`home`, `account`, `cart`, `myOrders`, `savedAddresses`) | each page's `onBack` |
| Screen names reported (`analyticsScreenNames` values) and the two event names (`AppEvents.navBarIconTapped`, `AppEvents.screenLoad`) | `analytics_screen_tracker.dart`, `app_events.dart` |
| Nudges (`checkNudges(context, '/$screen')`) | `analytics_screen_tracker.dart` `_show`; drop without Katyayani Core |
| `App` title, themes, `maxTextScaleFactor`, providers, listeners | `app.dart` |
| `SplashPage.displayDuration` and brand widgets | `splash_page.dart` |
| The shell's extra behaviour (wishlist toggle snackbar, badge count) | `app_shell_scaffold.dart`, `app_bottom_nav_bar.dart` |
| The bottom bar look (raised centre tab, sprout painter, sizes) | `app_bottom_nav_bar.dart` |
| `MaterialApp.router` title `'MyMali'` | `app.dart` |

---

## 7. Gotchas

1. **An observer serves one navigator.** Do not create one `AnalyticsRouteObserver` and reuse it: `_observers()` must build a new list (and observer) for the root and for each `StatefulShellBranch`. Dropping a branch's `observers:` silently stops reporting pages pushed inside that tab.
2. **`redirect` must return a location (path), never a route name.** The code returns `AppRoute.home.path`.
3. **`extra` is in-memory only.** It survives neither deep links nor restoration, hence the `redirect` guards for pages that cannot exist without it; `addressForm` and `orderDetails` tolerate a missing extra instead.
4. **`state.pageKey` on parameterised routes.** Without it, pushing `/product/B` from `/product/A` reuses the widget (and its bloc) for the new id.
5. **Tabs stay alive (`IndexedStack`).** A tab page that accepts query parameters must handle them in `didUpdateWidget`, and a repeatable request (open search) needs a changing value (`newSearchRequest()` nonce); the same value twice is not a change.
6. **`goBranch(index, initialLocation: index == navigationShell.currentIndex)`** — tapping the active tab pops that tab to its root; a different tab keeps its own stack.
7. **`goNamed` to a tab from a full-screen page clears the pushed pages** (the location changes); `pushNamed` keeps them. Use `goNamed` only for tabs and stack-replacing flow ends.
8. **Root-navigator sheets cannot read page blocs.** `AppPickerSheet.show` / `AppInfoSheet.show` use `useRootNavigator: true`; pass values in and pop results out, or provide a bloc inside the builder (`showGstinSheet`). App-wide blocs (provided in `App`, above `MaterialApp.router`) are readable.
9. **Sheets/dialogs are not screens.** The observer ignores non-`PageRoute`s on push and pop, so do not report them and do not expect them in `screens`.
10. **The shell's own route has no name.** `routeShown` treats a nameless `PageRoute` as "back at the tab on show" and re-reports `_tab`; a custom `PageRouteBuilder` without `settings.name` (the image viewer) goes down the same path.
11. **`analyticsScreenNames` is keyed by `AppRoute.x.name` strings**, not enum values: renaming an enum value silently drops the mapping (the route then reports under its new name). The tracker test asserts only the tabs.
12. **Four places define the tab order** (section 4.7). Changing one without the others breaks selection highlighting, analytics tab names or branch keys.
13. **`Scaffold(extendBody: true)` in the shell** means tab pages must add `MediaQuery.paddingOf(context).bottom` to their bottom padding (plus `CartBarOverlay.height` where the pill shows); forgetting it hides the last row behind the bar.
14. **Splash timing in tests:** always `await tester.pump(SplashPage.displayDuration)` before `pumpAndSettle()`; the timer runs even with a stored session.
15. **Build a fresh `AppRouter` per test.** The tracker holds `_current`/`_tab`; `GlobalKey`s are top-level finals shared by every router instance, so two live routers in one test would clash.
16. **`App` takes a `GoRouter`, not `AppRouter`**; tests call `AppRouter().router` (no analytics) or `AppRouter(analytics: sl<AnalyticsService>()).router`.
17. **`parentNavigatorKey: rootNavigatorKey` on top-level routes is redundant but intentional**; keep it so a route moved under a branch later still covers the bar.
18. **The `?` null-aware element** in `_observers()` needs Dart ≥ 3.8; on older SDKs write `[if (_tracker != null) _tracker!.observer()]`.
19. **`PopScope.canPop` is read at build time** (`canPop: !isPlacing`); the page must rebuild when the condition changes (`context.select`).
20. **Stale comments in `app_router.dart`** ("Authentication guards will be added … redirect", `TODO(routing): nested sub-routes per branch`) do not describe the actual design; copy the code, not the TODOs.
21. **`notifications` has no analytics screen name** — add one in the target app if the dashboards need it, and extend the tracker test to assert every `AppRoute` except `splash` has a mapping if that is wanted.

---

## 8. Target app WITHOUT bottom tabs — what to drop (derived from the code)

The tracker test (`analytics_screen_tracker_test.dart`) already runs the tracker against a plain `MaterialApp` with a single navigator and `navigatorObservers: [tracker.observer()]`, which shows the tracker needs no shell. From the code, a tab-less app:

- **Keeps** `app_routes.dart` (`AppRoute` enum; just no "tabs" group), `rootNavigatorKey` (drop the per-tab keys from `navigator_keys.dart`), `AppRouter` with `GoRouter(navigatorKey: rootNavigatorKey, observers: _observers(), initialLocation: AppRoute.splash.path, routes: [...])`, `AnalyticsScreenTracker` + `AnalyticsRouteObserver` + `analyticsScreenNames` + `_ignored = {splash}`, the `extra` guard styles, `state.pageKey` on param routes, the back pattern (`canPop ? pop : goNamed(home)`), the root-navigator sheets, `App(router:)`, the `bootstrap` line, and the splash flow.
- **Drops** `StatefulShellRoute.indexedStack` and its `StatefulShellBranch`es (each former tab becomes a plain top-level `GoRoute`), `AppShellScaffold`, `AppBottomNavBar` (and their tests), the tab navigator keys, `onTabSelected`, and `analyticsTabs` becomes `const <AppRoute>[]` — `tabSelected` then has no caller and is a no-op by its own range check (`index >= analyticsTabs.length`), so it can be deleted along with the `_tab` re-report branch in `routeShown` (that branch only fires for nameless `PageRoute`s; keeping it is harmless).
- `parentNavigatorKey: rootNavigatorKey` becomes unnecessary on every route (there is only one navigator); keeping it is harmless and matches the code.
- `_observers()` is then called once (for the root); the shape `List<NavigatorObserver> _observers() => [?_tracker?.observer()];` is unchanged.
- Pages no longer receive a bar height through `MediaQuery.paddingOf(context).bottom` beyond the system inset, so the `+ CartBarOverlay.height`-style additions are only needed for an app's own floating widgets.
- The home page's back semantics change: with no tab, "home" is the `initialLocation` target after the splash and the universal `goNamed(AppRoute.home.name)` fallback; nothing else in the router depends on it being a tab.
