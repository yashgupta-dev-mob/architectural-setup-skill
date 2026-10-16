# Inventory — followup (gaps and repairs)

Area: **followup**. This file (a) covers the files no other inventory names
(`lib/core/app/bloc/connectivity_bloc/*`, read in full) and (b) repairs the weak
spots the completeness critic found in the ten inventories, one
"Follow-up: <topic>" section each, with the exact text from the source. The other
inventory files were **not edited**; where this file corrects a row elsewhere it
names the file and line (`di-bootstrap-app.md:165`) and gives the replacement.

**Reading rule for the skill (see "Follow-up: cross-inventory duplication"):**
every core signature is taken from its *owning* inventory only; every other
mention of it in another inventory is a paraphrase and is ignored. This file is
the owner for everything it quotes verbatim below.

Everything named in §1 was read **in full** from
`C:/Users/Katyayani/Documents/flutter/mymali` unless the row says otherwise.
Dart SDK constraint of the repo: `sdk: ^3.13.4` (`pubspec.yaml:8`). The code uses
Dart features that need a recent SDK: private named constructor parameters
(`required this._storage`), null-aware collection elements (`'email': ?email`,
`[?_tracker?.observer()]`), `if (x case final y? when …)` patterns and switch
expressions. A target app must pin at least the same SDK.

---

## 1. Files

### 1.1 Uncovered files (the legacy connectivity bloc)

| path | role (one line) | class | placeholders |
|---|---|---|---|
| `lib/core/app/bloc/connectivity_bloc/connectivity_bloc.dart` | `ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState>`; builds its own `Connectivity()` and `InternetConnectionChecker()`; **imported by nothing** in `lib/` or `test/` | LEGACY — **EXCLUDE** (AGENTS.md §16 "don't imitate"); never install | — |
| `lib/core/app/bloc/connectivity_bloc/connectivity_event.dart` | `ConnectivityEvent` (concrete, not abstract) + `ConectivityInit` (sic), `NetworkStatusChanged(bool isOnline)`, `AppWentToBackground`, `AppCameToForeground` | LEGACY — **EXCLUDE** (companion; only exists so the whole folder is dropped) | — |
| `lib/core/app/bloc/connectivity_bloc/connectivity_state.dart` | `ConnectivityState extends Equatable` (non-const ctor, `props => []`) + `AppNetworkState(String message)` and three subclasses; `message` **not** in `props` | LEGACY — **EXCLUDE** (companion) | — |

The folder is the only consumer of `connectivity_plus` and
`internet_connection_checker`; dropping it lets the skill drop both packages (§5).
No test exists for it (`test/core/app/` does not exist).

### 1.2 Files read in full for the follow-up sections

| path | role (one line) | class | placeholders |
|---|---|---|---|
| `lib/core/repositories/shared_pref_repository.dart` | `SharePrefRepo extends BaseApiRepo`: 24 ad-hoc prefs getters/setters over its own `PrefUtils()`; **imported by nothing** | LEGACY — **EXCLUDE** (AGENTS.md §16); enumerated in "Follow-up: shared_pref_repository.dart" | — |
| `lib/core/repositories/base_api_repository.dart` | `BaseApiRepo`: one `Dio` per host (`dioSupabse`, `dioMedusa`, `dioKoUtils`, `dioStockship`) | ALWAYS (load-bearing; see networking.md §3.2) | host list and base URLs |
| `lib/core/utils/string_constants.dart` | `abstract class StringConstants`: one live `static const String appAuthToken = 'auth.access_token'` + 24 legacy non-const `static String` keys used only by `SharePrefRepo` | ALWAYS (the one const) / LEGACY (the rest) | the token key name |
| `lib/core/services/pref_utils.dart` | `PrefUtils` over a static `SharedPreferences` | ALWAYS (owner: storage-secrets-cache.md §3.12) | — |
| `lib/core/services/secure_storage/secure_storage.dart` | `abstract interface class SecureStorage { read, write, delete }` | CONDITIONAL(app stores tokens) | — |
| `lib/core/services/secure_storage/device_secure_storage.dart` | `DeviceSecureStorage implements SecureStorage` (the only `flutter_secure_storage` import) | CONDITIONAL(app stores tokens) | `installedKey = 'secure_storage.installed'` |
| `lib/core/services/secure_storage/secure_session_storage.dart` | `SecureSessionStorage extends LocalStorage` (supabase_flutter) | CONDITIONAL(app uses Supabase Auth) | `supabaseUrl` → `Env.supabaseUrl` |
| `lib/core/services/katyayani_core/ko_engagement_service.dart` | `abstract interface class KoEngagementService` (18 methods) | MYMALI-SPECIFIC (shape: the "engagement SDK" interface template) | the SDK's name in the class name |
| `lib/core/services/katyayani_core/ko_engagement_service_impl.dart` | `KoEngagementServiceImpl` over `katyayani_core` (the only import) | MYMALI-SPECIFIC | `siteId`, `apiBase`, `broadcastTopic = 'all_users'`, log prefix `[kc]` |
| `lib/core/services/katyayani_core/kc_identity.dart` | `KcIdentity` + `kcIdentityFor(...)`: the RN app's traits | MYMALI-SPECIFIC | trait keys, default country code `'91'` |
| `lib/core/services/analytics/analytics_service.dart`, `ko_analytics_service.dart`, `analytics_item.dart` | the analytics contract the engagement service mirrors | CONDITIONAL(analytics) (owner: analytics-engagement-platform.md P-2/P-7) | — |
| `lib/core/services/payments/payment_gateway.dart` | `GatewayCheckout`, `GatewayPayment`, `GatewayPaymentError`, `GatewayPaymentException`, `PaymentGateway` | CONDITIONAL(app has an online payment sheet) | `GatewayCheckout.description` text is what the merchant's webhook matches on |
| `lib/core/services/payments/razorpay_payment_gateway.dart` | `RazorpayPaymentGateway implements PaymentGateway` (the only `razorpay_flutter` import) + top-level `classifyRazorpayError`, `_readable`, `_reasons` | CONDITIONAL(Razorpay) | `themeColor = '#225542'`, `'currency': 'INR'`, log prefix `[razorpay]` |
| `lib/core/services/networking/networking.dart` | `ApiHost`, `Networking`, `NetworkingService` | ALWAYS (owner: networking.md §3.1) | hosts |
| `lib/core/widgets/form_helper/universal_form_field.dart` (lines 1–124 + the `case UFFType.*` labels; body verbatim in theme-and-widgets.md §2c) | `UniversalFormField` constructor and the 20-parameter `build()` | ALWAYS | — |
| `lib/core/widgets/form_helper/field_config.dart` (the `enum UFFType` only) | 27 `UFFType` values | ALWAYS | — |
| `lib/features/location/domain/failures/location_failures.dart` | five location failures incl. `LocationStorageFailure` | MYMALI-SPECIFIC (shape: feature failure file) | messages |
| `lib/features/location/data/repositories/location_repository_impl.dart` | `LocationRepositoryImpl` with the `_guard` exception→failure map | MYMALI-SPECIFIC (shape ALWAYS) | — |
| `lib/features/gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart` | `showGstinSheet`, `_GstinSheet`, `_VerifiedLine`, `gstinSheetCloseDelay` (previously "first 45 lines") | MYMALI-SPECIFIC (pattern: a sheet with its own bloc) | texts, keys |
| `lib/features/wishlist/presentation/bloc/wishlist_bloc.dart` | `WishlistBloc` (previously "excerpt" / "the device-first parts") | CONDITIONAL(device-first user list) template | `AppEvents.addToFavorite/removeFromFavorite`, catalog use cases |
| `lib/features/cart/presentation/cart/pages/cart_page.dart` | `CartPage`, `_CartView` (stateful), `_CartBody`, `_CartFailure`, `_hasContent` (previously "excerpt") | MYMALI-SPECIFIC (pattern: page bloc seeded from app-wide bloc) | texts, keys |
| `lib/features/home/presentation/home/pages/home_page.dart` | `HomePage`, `_HomeView`, `_HomeFailure`, `_EmptyHome` (previously "excerpt") | MYMALI-SPECIFIC (pattern ALWAYS) | hint text, keys |
| `lib/features/product/presentation/product_detail/pages/product_detail_page.dart` | `ProductDetailPage` (+ `idParam`, `open`), `_ProductDetailView`, `_ProductBody`, `_CouponNoteSlot`, `_SimilarSlot`, `_ProductFailure`, top-level `_back`, `_reportViewed` (previously "excerpt") | MYMALI-SPECIFIC | keys, texts |
| `lib/features/checkout/presentation/order_placed/pages/order_placed_page.dart` | `OrderPlacedArgs`, `OrderPlacedPage` (stateful; `reportedOrders`), `_OrderPlacedView`, `_SummaryRow` (previously "excerpt") | MYMALI-SPECIFIC | keys, texts |
| `lib/features/checkout/presentation/review_pay/pages/review_pay_page.dart` | `ReviewPayPage`, `_ReviewPayView` (12 listeners), `_ReviewPayBody`, `_PayBar`, `placingOrderNote` (previously "excerpt") | MYMALI-SPECIFIC (pattern: composing page) | keys, texts |
| `lib/features/orders/data/datasources/ref_order_remote_data_source.dart` | KO `GET /order/ref-orders` with optional bearer (previously "excerpt") | MYMALI-SPECIFIC (pattern: optional-token data source) | `KoUtilsEndpoints.refOrders`, `'+91'` |
| `lib/features/checkout/data/datasources/ko_order_remote_data_source.dart` | KO order POSTs with `x-request-id`, `_postWithToken`, `_toServerException` (previously "excerpt") | MYMALI-SPECIFIC (pattern: idempotent POST, vendor envelope) | header name, codes |
| `lib/core/router/app_router.dart` | `AppRouter`, `_observers`, `router` (previously "excerpt relevant here") | ALWAYS (owner: router-navigation.md §3.1, verified complete) | routes |
| `test/helpers/*.dart` (all 28 files) | every fake and the `registerSignedInApp` harness | see "Follow-up: test helper fakes" | test data |
| `test/core/services/secure_storage/secure_session_storage_test.dart` | the `SecureSessionStorage` test (call site `storage:`/`prefs:`) | CONDITIONAL(Supabase) | `sb-abcd1234-auth-token` |
| `test/core/services/katyayani_core/kc_identity_test.dart` | `kcIdentityFor` cases | MYMALI-SPECIFIC | — |
| `test/core/services/payments/razorpay_payment_gateway_test.dart` | `classifyRazorpayError` + `optionsFor` (previously "(head)") | CONDITIONAL(Razorpay) | — |
| `test/core/services/analytics/meta_analytics_destination_test.dart` | method-channel mock of `facebook_app_events` (previously "(head)") | CONDITIONAL(Meta) | — |
| `test/features/checkout/data/repositories/checkout_repository_impl_test.dart` (922 lines) | four file-private fakes + `FakePaymentGateway`; `now`/`wait`/`newRequestId` injection (previously "(head)") | MYMALI-SPECIFIC (patterns ALWAYS) | — |
| `test/features/product/presentation/product_detail/pages/product_detail_page_test.dart` (491) | hand-rolled registration of 11 fakes + `registerAccountFakes()`; pushes a path-parameter route (previously "(head)") | MYMALI-SPECIFIC (patterns ALWAYS) | — |
| `test/features/checkout/presentation/order_placed/bloc/order_placed_bloc_test.dart` (508) | timed bloc over `now`/`wait`; poll cadence asserts (previously "(head)") | MYMALI-SPECIFIC (pattern ALWAYS) | — |
| `test/features/invoice/presentation/invoice/pages/invoice_page_test.dart` (169) | `share_plus` + `path_provider` channel mocks; `tester.runAsync` for file I/O (previously "(head)") | CONDITIONAL(share/PDF) | — |
| `test/features/referral/presentation/refer/pages/referral_page_test.dart` (181) | `registerSignedInApp(referral:, engagement:)`; `dotenv.loadFromString` (previously "(head)") | MYMALI-SPECIFIC (patterns ALWAYS) | — |
| `test/features/home/presentation/home/pages/home_page_test.dart` (475) | the Home page test (previously "consulted by grep only") | MYMALI-SPECIFIC (pattern ALWAYS) | — |
| `test/features/wishlist/presentation/pages/wishlist_page_test.dart` (470) | the wishlist page + heart tests (previously "consulted by grep only") | MYMALI-SPECIFIC (pattern ALWAYS) | — |
| `pubspec.yaml`, `pubspec.lock` (grep) | package versions for §5 | — | — |

---

## 2. Names

### 2.1 Legacy names another app must **not** create (so a reviewer can grep for them)

| name | kind | file | exact shape |
|---|---|---|---|
| `ConnectivityBloc` | class | `connectivity_bloc.dart` | `class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> { ConnectivityBloc() : super(InitNetworkState('Initializing...')) {…} }` |
| `ConnectivityEvent` | class (concrete) | `connectivity_event.dart` | `class ConnectivityEvent {}` |
| `ConectivityInit` (sic) | class | same | `class ConectivityInit extends ConnectivityEvent {}` |
| `NetworkStatusChanged` | class | same | `class NetworkStatusChanged extends ConnectivityEvent { final bool isOnline; NetworkStatusChanged(this.isOnline); }` |
| `AppWentToBackground`, `AppCameToForeground` | classes | same | `class AppWentToBackground extends ConnectivityEvent { AppWentToBackground(); }` (same for the other) |
| `ConnectivityState` | class | `connectivity_state.dart` | `class ConnectivityState extends Equatable { ConnectivityState(); @override List<Object?> get props => []; }` |
| `AppNetworkState` | class | same | `class AppNetworkState extends ConnectivityState { final String message; AppNetworkState(this.message); }` (no `props` override) |
| `InitNetworkState`, `NetworkConnected`, `NetworkDisconnected` | classes | same | `class X extends AppNetworkState { X(String message) : super(message); }` |
| `SharePrefRepo` | class | `shared_pref_repository.dart` | `class SharePrefRepo extends BaseApiRepo { PrefUtils prefUtils = PrefUtils(); SharePrefRepo(); … }` (24 methods, "Follow-up: shared_pref_repository.dart") |
| `StringConstants.jwtToken … appVersion` | non-const `static String` / `static var` | `string_constants.dart` | 24 legacy members (listed in the same follow-up); only `appAuthToken` is live |
| `PrefUtils.getUserToken()` | method | `pref_utils.dart` | `String? getUserToken() { return _sharedPreferences?.getString('xx-token'); }` (legacy; nothing calls it) |

### 2.2 Names repaired or first quoted verbatim by this file

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `SecureSessionStorage` | class `extends LocalStorage` | `secure_session_storage.dart` | `SecureSessionStorage({required this._storage, required this._prefs, required String supabaseUrl}) : key = keyFor(supabaseUrl);` — call site `SecureSessionStorage(storage: …, prefs: …, supabaseUrl: …)` |
| `SecureSessionStorage.keyFor` | static | same | `static String keyFor(String supabaseUrl) => 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';` |
| `KoEngagementService` | `abstract interface class` | `ko_engagement_service.dart` | 18 methods, quoted in full in "Follow-up: KoEngagementService" |
| `KoEngagementServiceImpl` | class | `ko_engagement_service_impl.dart` | `KoEngagementServiceImpl({required String siteId, required String apiBase}) : _siteId = siteId, _apiBase = apiBase;` `static const String broadcastTopic = 'all_users';` |
| `KcIdentity` | class | `kc_identity.dart` | `const KcIdentity({required this.userId, required this.traits}); final String userId; final Map<String, dynamic> traits;` |
| `kcIdentityFor` | top-level function | same | `KcIdentity? kcIdentityFor({required String phone, String? fullName, String? email})` |
| `GatewayCheckout` | class | `payment_gateway.dart` | `const GatewayCheckout({required this.keyId, required this.orderId, required this.amountPaise, required this.merchantName, required this.description, this.contact, this.email}); final String keyId; final String orderId; final int amountPaise; final String merchantName; final String description; final String? contact; final String? email;` |
| `GatewayPayment` | class | same | `const GatewayPayment({required this.paymentId, required this.orderId, this.signature = ''}); final String paymentId; final String orderId; final String signature;` |
| `GatewayPaymentError` | enum | same | `enum GatewayPaymentError { cancelled, upiTimeout, network, insufficientFunds, incorrectOtp, timeout, invalidVpa, cardDeclined, cardExpired, invalidCard, bankDown, limitExceeded, notConfigured, unknown; bool get isCancellation => this == cancelled \|\| this == upiTimeout; }` |
| `GatewayPaymentException` | class `implements Exception` | same | `const GatewayPaymentException(this.error, {this.detail}); final GatewayPaymentError error; final String? detail; @override String toString() => 'GatewayPaymentException($error: $detail)';` |
| `PaymentGateway` | `abstract interface class` | same | `Future<GatewayPayment> collect(GatewayCheckout checkout);` |
| `RazorpayPaymentGateway` | class `implements PaymentGateway` | `razorpay_payment_gateway.dart` | `RazorpayPaymentGateway({Razorpay Function()? newSdk}) : _newSdk = newSdk ?? Razorpay.new;` `static const String themeColor = '#225542';` `static Map<String, dynamic> optionsFor(GatewayCheckout checkout)`; private `static String _keyLabel(String keyId)`, `static void _trace(String message)`, `Completer<GatewayPayment>? _inFlight` |
| `classifyRazorpayError` | top-level function | same | `GatewayPaymentException classifyRazorpayError({int? code, String? message, Map<dynamic, dynamic>? error})` |
| `_readable`, `_reasons` | top-level private | same | `String? _readable(String text)`; `const List<(String, GatewayPaymentError)> _reasons = [...]` (10 entries, verbatim below) |
| `Networking.patchAPICall` | method | `networking.dart` | `Future<dynamic> patchAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, dynamic data, Map<String, String>? headers, ApiHost host = ApiHost.supabase});` |
| `Networking.deleteAPICall` | method | same | `Future<dynamic> deleteAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, dynamic data, Map<String, String>? headers, ApiHost host = ApiHost.supabase});` |
| `Networking.putAPICall` | method | same | `Future<dynamic> putAPICall({required String endpoint, Map<String, dynamic>? queryParameters, Map<String, dynamic>? pathParameters, dynamic data, ApiHost host = ApiHost.supabase});` (**no `headers`**) |
| `UniversalFormField` | class (plain, not a widget) | `universal_form_field.dart` | constructor and `build()` quoted in "Follow-up: UniversalFormField.build()" |
| `UFFType` | enum (27 values) | `field_config.dart` | `enum UFFType { text, phone, date, time, year, address, radio, switchBtn, multiSelect, dropdown, multiText, slider, search, checkbox, upload, singleCheckbox, incDec, dateTimePicker, locationWithTextSearch, multiChipField, richTextEditor, multiDocumentSelect, chatTextBox, dropdownMultiChip, otp, choiceChips, rating }` |
| `LocationStorageFailure` | class `extends Failure` | `location_failures.dart` | `class LocationStorageFailure extends Failure { LocationStorageFailure({super.message = 'Could not save the location.'}); }` |
| `registerSignedInApp`, `launchSignedInApp`, `openAccountTab`, `scrollAccountTo` | top-level functions | `test/helpers/signed_in_app.dart` | verbatim in "Follow-up: test helper fakes" |
| `registerAccountFakes` | top-level function | `test/helpers/fake_account_repository.dart` | `void registerAccountFakes({FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account})` (body verbatim below) |
| `Fake<X>Repository` ×20, `FakeCartRemoteDataSource`, test constants | classes / consts | `test/helpers/` | every constructor and field verbatim in "Follow-up: test helper fakes" |

---

## 3. Patterns

### P-F1 — The legacy connectivity bloc, complete, as the anti-pattern (EXCLUDE)

The three files, verbatim. They are quoted so the skill can recognise and refuse
the shape; nothing here is reproduced in another app.

`lib/core/app/bloc/connectivity_bloc/connectivity_event.dart`:

```dart
class ConnectivityEvent {}

class ConectivityInit extends ConnectivityEvent {}

class NetworkStatusChanged extends ConnectivityEvent {
  final bool isOnline;
  NetworkStatusChanged(this.isOnline);
}

class AppWentToBackground extends ConnectivityEvent {
  AppWentToBackground();
}

class AppCameToForeground extends ConnectivityEvent {
  AppCameToForeground();
}
```

`lib/core/app/bloc/connectivity_bloc/connectivity_state.dart`:

```dart
import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  ConnectivityState();

  @override
  List<Object?> get props => [];
}

class AppNetworkState extends ConnectivityState {
  final String message;

  AppNetworkState(this.message);
}

class InitNetworkState extends AppNetworkState {
  InitNetworkState(String message) : super(message);
}

class NetworkConnected extends AppNetworkState {
  NetworkConnected(String message) : super(message);
}

class NetworkDisconnected extends AppNetworkState {
  NetworkDisconnected(String message) : super(message);
}
```

`lib/core/app/bloc/connectivity_bloc/connectivity_bloc.dart`:

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'connectivity_state.dart';
import 'connectivity_event.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _checker = InternetConnectionChecker();

  StreamSubscription? _connSub;
  StreamSubscription? _internetSub;

  bool? _lastIsOnline; // <- track last emitted status
  bool _watching = false; // prevents starting watchers / re-init on resume
  bool _paused = false;
  DateTime? _ignoreDisconnectUntil; // ignore transient disconnects around background/resume

  ConnectivityBloc() : super(InitNetworkState('Initializing...')) {
    on<ConectivityInit>(_onInitApp);
    on<NetworkStatusChanged>(_onNetworkStatusChanged);
    on<AppWentToBackground>(_onAppBackgrounded);
    on<AppCameToForeground>(_onAppForegrounded);
  }

  Future<void> _onInitApp(
    ConectivityInit event,
    Emitter<ConnectivityState> emit,
  ) async {
    // Guard: init can be triggered multiple times (e.g., when widget tree rebuilds on resume)
    if (_watching) return;

    final hasInternet = await _checker.hasConnection;

    // Only emit if status actually changed (or first time)
    if (_lastIsOnline != hasInternet) {
      _lastIsOnline = hasInternet;
      emit(
        hasInternet
            ? NetworkConnected('Online')
            : NetworkDisconnected('No internet connection'),
      );
    } else {
      _lastIsOnline = hasInternet;
    }

    _startNetworkWatch();
  }

  void _onNetworkStatusChanged(
    NetworkStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    // DISTINCT: don’t emit if same as last time
    if (_lastIsOnline == event.isOnline) return;
    _lastIsOnline = event.isOnline;

    emit(
      event.isOnline
          ? NetworkConnected('Back online')
          : NetworkDisconnected('No internet connection'),
    );
  }

  Future<void> _onAppBackgrounded(
    AppWentToBackground event,
    Emitter<ConnectivityState> emit,
  ) async {
    _paused = true;
    // When the app is backgrounded, active internet checks can fail / be paused by OS.
    // Cancel checker stream so it doesn't emit a false "disconnected".
    await _internetSub?.cancel();
    _internetSub = null;

    // Small grace period to ignore any late "disconnected" events that race in.
    _ignoreDisconnectUntil = DateTime.now().add(const Duration(seconds: 2));
  }

  Future<void> _onAppForegrounded(
    AppCameToForeground event,
    Emitter<ConnectivityState> emit,
  ) async {
    _paused = false;

    // Give the OS a moment to restore network sockets after resume.
    _ignoreDisconnectUntil = DateTime.now().add(const Duration(seconds: 2));

    // Re-attach internet checker stream if needed.
    _internetSub ??= _checker.onStatusChange.listen((status) {
      final now = DateTime.now();
      final ignoreUntil = _ignoreDisconnectUntil;
      if (ignoreUntil != null && now.isBefore(ignoreUntil)) {
        // Ignore transient disconnects right after background/resume.
        if (status == InternetConnectionStatus.disconnected) return;
      }
      add(NetworkStatusChanged(status == InternetConnectionStatus.connected));
    });

    // Force a fresh check once on resume.
    final hasInternet = await _checker.hasConnection;
    add(NetworkStatusChanged(hasInternet));
  }

  void _startNetworkWatch() {
    if (_watching) return;
    _watching = true;

    _connSub = _connectivity.onConnectivityChanged.listen((_) async {
      final hasInternet = await _checker.hasConnection;
      add(NetworkStatusChanged(hasInternet));
    });

    _internetSub = _checker.onStatusChange.listen((status) {
      final now = DateTime.now();
      final ignoreUntil = _ignoreDisconnectUntil;
      if (ignoreUntil != null && now.isBefore(ignoreUntil)) {
        if (status == InternetConnectionStatus.disconnected) return;
      }
      add(NetworkStatusChanged(status == InternetConnectionStatus.connected));
    });
  }

  @override
  Future<void> close() async {
    _watching = false;
    await _connSub?.cancel();
    await _internetSub?.cancel();
    _ignoreDisconnectUntil = null;
    return super.close();
  }
}
```

**Why it is excluded (every rule it breaks, from the code):**

1. `final Connectivity _connectivity = Connectivity();` and
   `final InternetConnectionChecker _checker = InternetConnectionChecker();` —
   the bloc creates its own dependencies (AGENTS.md §9: constructor injection
   everywhere; §10: blocs receive use cases).
2. It talks to two SDKs directly; there is no use case, repository or data source
   between them (§3: "Skipping a layer is not allowed").
3. `ConnectivityState()` and every subclass have non-`const` constructors;
   `AppNetworkState.message` is **not** in `props`, so
   `NetworkConnected('Online') == NetworkConnected('Back online')` is `true`
   under `Equatable` and `Bloc` swallows the second emit. AGENTS.md §10: states
   are `const`, immutable, "every field in props".
4. The state hierarchy is neither `sealed` nor `abstract` (`class ConnectivityState`
   is concrete) and there is no `copyWith`.
5. `ConnectivityEvent` is a concrete class, not `abstract class ConnectivityEvent {}`
   (§10 shows `abstract`). The events themselves do follow §10 (plain Dart, no
   Equatable).
6. Misspelt public name `ConectivityInit`.
7. `_paused` is written and never read; `DateTime.now()` is called inside the
   bloc, so nothing about it is testable with an injected clock (compare
   `OrderPlacedBloc(… now: () => now, wait: (duration) async {…})`).
8. It is registered nowhere (`grep ConnectivityBloc lib test` → only its own
   folder), so it is dead code kept alive only by the two packages in `pubspec.yaml`.

**If a target app needs connectivity**, build it per §10: a
`ConnectivityRepository` contract in `domain/`, a data source that owns the SDK
(`connectivity_plus` injected through the constructor), a `WatchConnectivity`
stream use case (AGENTS.md §20 "Going local-first later" step 1 names
`StreamUseCase<T, Params>` as the shape to add), a `const`, `Equatable` state with
`props => [isOnline]`, and `registerFactory(() => ConnectivityBloc(watch: sl()))`.
Ask the user before adding the package (§1).

### P-F2 — The legacy prefs facade, complete, as the anti-pattern (EXCLUDE)

`lib/core/repositories/shared_pref_repository.dart` is quoted in full in
"Follow-up: shared_pref_repository.dart". The rule it breaks: AGENTS.md §16
"`SharePrefRepo` mixes storage with the API base class; use `PrefUtils` through a
data source". The correct shape is a feature's local data source that receives
`PrefUtils` in its constructor (storage-secrets-cache.md §3.6,
`location_local_data_source.dart`).

### P-F3 — A feature failure file: default message, an extra typed field, and the repository `_guard` (verbatim)

`lib/features/location/domain/failures/location_failures.dart`:

```dart
import '../../../../core/app/failure.dart';

/// The user did not let the app read the device's location.
class LocationPermissionDeniedFailure extends Failure {
  LocationPermissionDeniedFailure({
    this.isPermanent = false,
    super.message = 'Location permission denied.',
  });

  /// The system will not ask again: only the app's settings can allow it.
  final bool isPermanent;
}

/// Location is switched off on the device.
class LocationServiceDisabledFailure extends Failure {
  LocationServiceDisabledFailure({super.message = 'Location is turned off.'});
}

/// The search text, or the device's position, matches no known place.
class PlaceNotFoundFailure extends Failure {
  PlaceNotFoundFailure({super.message = 'No place found.'});
}

/// The device could not work out a position or look a place up, e.g. it
/// timed out or has no geocoder.
class LocationUnavailableFailure extends Failure {
  LocationUnavailableFailure({super.message = 'Location is unavailable.'});
}

/// The chosen place could not be read from or written to this device.
class LocationStorageFailure extends Failure {
  LocationStorageFailure({super.message = 'Could not save the location.'});
}
```

The repository side (`lib/features/location/data/repositories/location_repository_impl.dart`),
complete — one private `_guard<T>` maps every typed exception to its failure, and
every public method is a one-liner through it:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/failure.dart';
import '../../domain/entities/place.dart';
import '../../domain/failures/location_failures.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/device_location_data_source.dart';
import '../datasources/location_local_data_source.dart';
import '../exceptions/location_exceptions.dart';
import '../models/place_model.dart';

/// Finds places through the device's geocoder and GPS, and keeps the
/// chosen one on the device.
class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl({
    required DeviceLocationDataSource device,
    required LocationLocalDataSource local,
  }) : _device = device,
       _local = local;

  final DeviceLocationDataSource _device;
  final LocationLocalDataSource _local;

  @override
  Future<Either<Failure, Place>> searchPlace(String query) {
    return _guard(() async => (await _device.findPlace(query)).toEntity());
  }

  @override
  Future<Either<Failure, Place>> getCurrentPlace() {
    return _guard(() async => (await _device.currentPlace()).toEntity());
  }

  @override
  Future<Either<Failure, Place?>> getSelectedPlace() {
    return _guard(() async => (await _local.readSelectedPlace())?.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> saveSelectedPlace(Place place) {
    return _guard(() async {
      await _local.writeSelectedPlace(PlaceModel.fromEntity(place));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> clearSelectedPlace() {
    return _guard(() async {
      await _local.clearSelectedPlace();
      return unit;
    });
  }

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
}
```

What to copy: a feature's failures live in one file `domain/failures/<feature>_failures.dart`,
each `extends Failure` with `{super.message = '…'}` (and `super.code` only when an
HTTP status exists); a data-carrying failure adds a `final` field with a default
(`isPermanent = false`). The repository never lets an exception out: every public
method returns through one `_guard`. What varies: the exception and failure names.
Tests: `location_repository_impl_test.dart` ("maps storage errors to
LocationStorageFailure": both `read` and `write` → `isA<LocationStorageFailure>()`)
and `location_bloc_test.dart` (`repository.saveFailure = LocationStorageFailure();`).

---

## 4. Rules observed in code (not in AGENTS.md, or stated differently)

| # | observed | AGENTS.md says | where |
|---|---|---|---|
| 1 | `ConnectivityBloc` is referenced by **nothing**: `grep -rn "ConnectivityBloc\|connectivity_bloc" lib test` matches only its own folder. It is dead code, not merely legacy. | §16 "creates its own dependencies, and its states are not `const` and leave `message` out of `props`; don't imitate" — true, but it does not say the bloc is unused | `lib/core/app/bloc/connectivity_bloc/` |
| 2 | `connectivity_plus ^6.0.5` (lock 6.1.5; transitive `connectivity_plus_platform_interface 2.1.0`, `nm 0.5.0`, `dbus 0.7.15`) and `internet_connection_checker ^1.0.0+1` (lock 1.0.0+1) are declared and imported **only** by the legacy bloc | §1 stack table does not list them; "Do not add a package without asking the user first" | `pubspec.yaml:23-24` |
| 3 | `core/app/` holds a `bloc/` folder | §2 layout: `core/app/ # Failure, API response types, AppException` | `lib/core/app/bloc/` |
| 4 | `SharePrefRepo` has **24** methods (not "20" as storage-secrets-cache.md §1 says), creates `PrefUtils()` itself, and `await`s synchronous `PrefUtils` calls (`getString`, `getBool`, `getAllData`). Nothing imports it. | §16 legacy row | `shared_pref_repository.dart` |
| 5 | `SharePrefRepo.setUserTokenToStorage` / `getUserTokenFromStorage` / `deleteUserTokenFromStorage` read and write `StringConstants.appAuthToken` (`'auth.access_token'`) **in SharedPreferences** — the very prefs copy `AuthLocalDataSource.readTokens` migrates away from. Calling them would resurrect a token in prefs. | §7 "Where tokens live: only in `SecureStorage`, never in `PrefUtils`" | same |
| 6 | `StringConstants` is `abstract class` with 24 **non-const** `static String` members and one `static var appVersion = "2.0.3"`; only `appAuthToken` is `static const` and used (`networking.dart`, `auth_local_data_source.dart`). | §8 "Never hardcode … IDs in Dart code" (the legacy members are unused) | `string_constants.dart` |
| 7 | `SecureSessionStorage`'s constructor uses private named parameters (`required this._storage`); two inventories paraphrased it with public parameter names, which would compile only with a different initializer list. | §7 names the class only | `secure_session_storage.dart:13-17` |
| 8 | `FakeNetworking` implements only `getAPICall`, `postAPICall`, `deleteAPICall`, `patchAPICall` and forwards everything else to `noSuchMethod` (so `putAPICall`/`graphqlQueryCall` throw at run time, not compile time) | §14 "hand-written fakes that `implements` the interface" (implies every member) | `test/helpers/fake_networking.dart:136-137` |
| 9 | `NetworkingService.patchAPICall` always sends `Content-Type` (`_optionsFor(host)` with `hasBody` defaulting to `true`), `deleteAPICall` sends it only when `data != null`, `getAPICall` never (`hasBody: false`), `putAPICall` has no per-call `headers` at all. | §6 "Pass `headers:` to add or override headers for that call only" (true for get/post/patch/delete only) | `networking.dart` |
| 10 | `KoEngagementService` is **not** a superset of `AnalyticsService`: it lacks `setUserId` and `requestTrackingPermission` and adds `init`, `identify`, `resetIdentity`, `requestPushPermission`, `registerPush`. `KoAnalyticsService` adapts one to the other with two no-ops. | §23 table describes both; the exact method sets are nowhere | `ko_engagement_service.dart`, `ko_analytics_service.dart` |
| 11 | `RazorpayPaymentGateway.optionsFor` hard-codes `'currency': 'INR'` and `'retry': {'enabled': false}`; `GatewayCheckout` has no currency field. | §Reference: paying online describes the sheet; the currency is not named | `razorpay_payment_gateway.dart:134-144` |
| 12 | `UniversalFormField.build` has **20** config parameters (three more are commented out) but only **11** `case UFFType.*` branches (`text, phone, search, dropdown, multiChipField, radio, date, time, otp, choiceChips, rating`) + `default`; 16 enum values fall to `default`. | §13 lists 9 config classes and says "add a `case UFFType.<name>:`" | `universal_form_field.dart:125-292` |
| 13 | `gstin_sheet.dart` (a `widgets/` file) calls `sl<GstinSheetBloc>()` inside `BlocProvider.create` | §9 allows `sl` in `app.dart` and **pages** | `gstin_sheet.dart:26` |
| 14 | `order_placed_page.dart:180` and `review_pay_page.dart:483` read state with `context.watch<…>().state` | §10 "Read state with `context.select`" | those lines |
| 15 | `OrderPlacedPage.reportedOrders` is a **static mutable `Set<String>`** on a widget class (process-wide memory so a rebuilt route never reports a purchase twice); tests must clear it. | §10 does not cover process-wide de-duplication | `order_placed_page.dart:59-60` |
| 16 | `LocationStorageFailure` exists and is mapped from `LocationStorageException` in `_guard` (storage-secrets-cache.md:156 had recorded it "not read"). | — | `location_failures.dart:31-33` |

---

## 5. Packages

| package | version (pubspec → lock) | files | class |
|---|---|---|---|
| `connectivity_plus` | `^6.0.5` → 6.1.5 | `lib/core/app/bloc/connectivity_bloc/connectivity_bloc.dart` only | LEGACY — **DROP** with the folder (also drops transitive `connectivity_plus_platform_interface 2.1.0`, `nm 0.5.0`, `dbus 0.7.15`) |
| `internet_connection_checker` | `^1.0.0+1` → 1.0.0+1 | same file only | LEGACY — **DROP** |
| `flutter_bloc` / `bloc` | `^9.1.0` / `^9.0.0` | the legacy bloc, every live bloc | ALWAYS |
| `equatable` | `^2.0.7` | the legacy state, every live state | ALWAYS |
| `shared_preferences` | `^2.0.5` | `lib/core/services/pref_utils.dart` only (the legacy `SharePrefRepo` goes through `PrefUtils`) | ALWAYS |
| `supabase_flutter` | `^2.17.2` | `secure_session_storage.dart` (`LocalStorage`), bootstrap, auth session data source | CONDITIONAL(Supabase) |
| `flutter_secure_storage` | `^11.2.0` | `device_secure_storage.dart` only | CONDITIONAL(tokens) |
| `katyayani_core` | `^2.0.7` | `ko_engagement_service_impl.dart` only | MYMALI-SPECIFIC |
| `razorpay_flutter` | `^1.4.7` | `razorpay_payment_gateway.dart` only | CONDITIONAL(Razorpay) |
| `dio` | `^5.11.1` | `networking.dart`, `base_api_repository.dart`, `curl_logger_interceptor.dart` | ALWAYS |
| `flutter/foundation.dart` (`kDebugMode`, `debugPrint`, `visibleForTesting`, `defaultTargetPlatform`, `kIsWeb`) | SDK | `device_secure_storage.dart`, `ko_engagement_service_impl.dart`, `razorpay_payment_gateway.dart`, `networking.dart` | SDK |
| `dart:developer` (`log`) | SDK | `device_secure_storage.dart`, `ko_engagement_service_impl.dart`, `pref_utils.dart`, `networking.dart` | SDK |
| `go_router` | `^18.0.2` | `app_router.dart`, the five pages read here | ALWAYS |
| `share_plus` | `^13.3.1` | `product_detail_page.dart` (`SharePlus.instance.share(ShareParams(...))`) | CONDITIONAL(share) |
| `url_launcher` | `^6.2.5` | `home_page.dart` (`launchUrl(uri, mode: LaunchMode.externalApplication)`) | CONDITIONAL(external links) |
| `flutter_dotenv` | `^6.0.1` | `referral_page_test.dart` (`dotenv.loadFromString`) | ALWAYS (through `Env`) |
| `flutter_test` | sdk | every test | ALWAYS |

---

## 6. What varies per app

| what | where it appears | MyMali value |
|---|---|---|
| Whether a connectivity feature exists at all | `pubspec.yaml`, (a new) `features/connectivity/` | none (legacy folder dropped) |
| Supabase project URL → session key | `SecureSessionStorage.keyFor(Env.supabaseUrl)` | `sb-<project-ref>-auth-token` |
| Engagement SDK and its credentials | `KoEngagementServiceImpl({siteId, apiBase})` ← `Env.kcSiteId`, `Env.kcApiUrl` (`KC_SITE_ID`, `KC_API_URL`) | Katyayani Core |
| Broadcast push topic | `KoEngagementServiceImpl.broadcastTopic` | `'all_users'` |
| Identity traits and default dial code | `kcIdentityFor` (`'name'`, `'firstName'`, `'lastName'`, `'phone'`, `'country_code'`, `'phone_number'`, `'email'`; `'91'`) | RN app's traits |
| Log prefixes | `_log` / `_trace` | `[kc]`, `[razorpay]`, `[secure_storage]` |
| Payment sheet brand colour, currency, retry | `RazorpayPaymentGateway.themeColor`, `optionsFor` | `'#225542'`, `'INR'`, `{'enabled': false}` |
| Merchant name / description on the sheet | `GatewayCheckout.merchantName` / `.description` (set by `CheckoutRepositoryImpl.paymentMerchant` / `paymentDescription`) | "Order from My Mali App" (webhook matches on "my mali") |
| Test key prefix of a Razorpay key | `_keyLabel` (`rzp_test_` / `rzp_live_`) | Razorpay's |
| The `package:` import prefix in every test helper | `package:mymali/…` | `mymali` |
| Test data in the fakes | every `test<Thing>` constant | Bhopal addresses, `prod_01`, `Activated Neem Oil`, … |
| Which repositories `App` needs registered before it can pump | `registerSignedInApp` (8 repos + `KoEngagementService` + `AnalyticsService`, 12 `register<X>Feature()` calls + `registerAccountFakes`) | MyMali's list |
| Route list, tab branches | `app_router.dart` | 24 `GoRoute`s, 5 branches |
| Widget placeholder texts | see theme-and-widgets.md §1/§6 and "Follow-up: theme widgets" | — |

---

## 7. Gotchas

1. **Do not port `lib/core/app/bloc/`.** It compiles only because two packages are
   still declared; remove the folder *and* `connectivity_plus` +
   `internet_connection_checker` from `pubspec.yaml`, then `flutter pub get` (the
   lock loses `connectivity_plus_platform_interface`, `nm`, `dbus`).
2. **`SecureSessionStorage({required this._storage, required this._prefs, …})`** —
   the parameters are private fields initialised directly; callers write
   `storage:` / `prefs:`. Writing the constructor with public parameter names (as
   two inventories did) compiles only if the fields are initialised in the
   initializer list (`: _storage = storage, _prefs = prefs, key = keyFor(…)`).
   Private named parameters need a recent Dart; the repo pins `^3.13.4`.
3. **`KoEngagementService` ≠ `AnalyticsService`.** Reproducing "the same methods
   minus two" from memory loses `init`/`identify`/`resetIdentity`/
   `requestPushPermission`/`registerPush` and their exact signatures; take them
   from the verbatim block below.
4. **`GatewayCheckout.amountPaise` is `int`**, rupees × 100, and the only place
   paise exist; `GatewayPayment.signature` defaults to `''`; the untyped
   `GatewayCheckout({required keyId, …})` rows elsewhere lose both facts.
5. **`optionsFor` uses null-aware map elements** (`'contact': ?checkout.contact`),
   so a blank contact/email leaves the key out (the test asserts
   `options['prefill']` is empty). An older Dart cannot compile it; rewrite as
   `if (checkout.contact != null) 'contact': checkout.contact` there.
6. **The Razorpay error table is ordered.** `_reasons` is scanned top to bottom and
   the first regex wins; `network|internet|connection|unreachable` is last on
   purpose (a `code == Razorpay.NETWORK_ERROR` is caught earlier). Keep the order.
7. **`Networking.putAPICall` has no `headers`.** `FakeNetworking` does not implement
   it (nor `graphqlQueryCall`); a data source that starts using `put` needs both
   added, in the service (§6 "extend it in place") and in the fake.
8. **Widget bodies are not in any inventory for ~40 of the 53 widget files.** The
   skill must ship those files and copy them verbatim; only the files listed as
   "REPRODUCE" in "Follow-up: theme widgets" can be regenerated from text.
9. **`UFFType` order is load-bearing** only by parity (no persisted indices), but
   AGENTS.md §13 says new values go "at the end"; keep the 27 values and their
   order even though 16 fall through to `default`.
10. **`FakeNetworking` records `host`** and defaults it to `ApiHost.supabase`; a
    target app with a different default host enum value must change
    `RecordedCall.host`'s default and every `expect(call.host, …)`.
11. **`registerSignedInApp` and the hand-rolled `setUp` blocks must agree.**
    `product_detail_page_test.dart`, `home_page_test.dart`,
    `wishlist_page_test.dart` register the same eight repositories by hand (plus
    their own extras) and call `registerAccountFakes()`; a repository added to
    `App` must be added in all four places or every page test fails with a
    `get_it` "not registered" error.
12. **`OrderPlacedPage.reportedOrders` is process-wide state** — clear it in
    `setUp` of any test that places two orders with the same id.
13. **`gstin_sheet.dart` is the one `widgets/` file that calls `sl`**; AGENTS.md
    §9's "pages" rule is applied to "the widget that owns the `BlocProvider`" in
    practice. A skill that forbids `sl` outside `pages/` would break this sheet.
14. **`AnalyticsItem.quantity` and `.price` are `num`**, not `int`/`double`; the
    KC SDK's `KCItem(sku:, qty:, rate:, name:, category:)` takes them as is.

---

## Follow-up: SecureSessionStorage constructor

**Wrong rows to ignore:** `di-bootstrap-app.md:165` and `tests-tooling-config.md:185`
both write `SecureSessionStorage({required SecureStorage storage, required PrefUtils prefs, required String supabaseUrl})`.
That is **not** the declaration. `storage-secrets-cache.md` §3.8 (line 727) and its
Gotcha 2 (line 1335) are correct and remain the owner; this section repeats the
whole file so no reader needs to cross-check.

`lib/core/services/secure_storage/secure_session_storage.dart`, complete:

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

The declaration uses **private named parameters**: `required this._storage` and
`required this._prefs` initialise the private fields directly, and the public
parameter names the call site uses are the field names without the underscore.
Both call sites agree:

`lib/app/bootstrap.dart` (lines 30–40):

```dart
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
```

`test/core/services/secure_storage/secure_session_storage_test.dart` (lines 16–30):

```dart
  Future<void> build(Map<String, String> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    prefUtils = PrefUtils();
    await prefUtils.init();
    await prefUtils.clearAll();
    for (final entry in prefs.entries) {
      await prefUtils.setString(key: entry.key, value: entry.value);
    }
    secure = FakeSecureStorage();
    storage = SecureSessionStorage(
      storage: secure,
      prefs: prefUtils,
      supabaseUrl: url,
    );
  }
```

The test's four cases, which a port must keep green: `keyFor('https://abcd1234.supabase.co') == 'sb-abcd1234-auth-token'`;
persist → `secure.values[key]` holds the string, `hasAccessToken()` true, `accessToken()` returns it, remove → false;
a prefs copy under the key is moved into secure storage on `initialize()` and
removed from prefs; a secure copy already present wins over the prefs copy and the
prefs copy is still removed.

**Equivalent for a Dart SDK without private named parameters** (storage-secrets-cache.md §3.8 already gives it; repeated so the two spellings are never mixed):

```dart
  SecureSessionStorage({
    required SecureStorage storage,
    required PrefUtils prefs,
    required String supabaseUrl,
  }) : _storage = storage,
       _prefs = prefs,
       key = keyFor(supabaseUrl);
```

Either spelling keeps the call sites unchanged. The repo's own spelling is the
first one; the repo pins `sdk: ^3.13.4`.

The two sibling files, for completeness of the folder (both already verbatim in
storage-secrets-cache.md §3.7 and §2):

`secure_storage.dart`:

```dart
/// Encrypted key-value storage for secrets: the auth tokens and the Supabase
/// session. Everything else stays in `PrefUtils` or `LocalCache`.
///
/// It never throws: a value that cannot be read is `null`, and a value that
/// cannot be saved is kept in memory for this run and logged.
abstract interface class SecureStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
```

`device_secure_storage.dart` — constructor and statics only (body in storage-secrets-cache.md §3.7):

```dart
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
  }) async { … }

  @visibleForTesting
  static void resetMemory() => _memory.clear();
```

---

## Follow-up: KoEngagementService / KoEngagementServiceImpl / KcIdentity (verbatim)

**Rows to ignore:** `analytics-engagement-platform.md:156-158` and
`di-bootstrap-app.md:143-145` describe the interface as "+ the same typed event
methods as `AnalyticsService` except `setUserId`/`requestTrackingPermission`".
Accurate, but not reproducible. The three files follow in full; this section is
their owner. (analytics-engagement-platform.md P-1 line 215 and P-10 line 1623
keep the *pattern* commentary; they quote only `_guard` and the constructor.)

### The exact relation to `AnalyticsService`

| in `AnalyticsService` (15) | in `KoEngagementService` (18) |
|---|---|
| — | `Future<void> init()` |
| — | `Future<void> identify({required String phone, String? fullName, String? email})` |
| — | `void resetIdentity()` |
| — | `Future<bool> requestPushPermission()` |
| — | `Future<bool> registerPush()` |
| `void setUserId(String? userId)` | — (`KoAnalyticsService.setUserId` is `{}`) |
| `Future<void> requestTrackingPermission()` | — (`KoAnalyticsService.requestTrackingPermission` is `async {}`) |
| the 13 shared: `track`, `screenView`, `viewItem`, `addToCart`, `removeFromCart`, `viewCart`, `beginCheckout`, `purchase`, `search`, `login`, `addPaymentInfo`, `capturePayment`, `checkNudges` | identical signatures, character for character |

### `lib/core/services/katyayani_core/ko_engagement_service.dart`

```dart
import 'package:flutter/widgets.dart';

import '../analytics/analytics_item.dart';

/// Katyayani Core: who the user is, events, push and attribution.
///
/// The SDK registers every Firebase Messaging listener itself (foreground,
/// opened, initial message and the background handler). Firebase keeps
/// **one** background handler, so the app never registers its own.
///
/// Every method is safe to call before or without a successful [init]: it
/// then does nothing.
abstract interface class KoEngagementService {
  /// Starts the SDK and listens for its callbacks. Never throws.
  Future<void> init();

  /// Tells KC who is signed in, keyed by [phone] only. Does nothing when
  /// [phone] has no digits.
  Future<void> identify({
    required String phone,
    String? fullName,
    String? email,
  });

  /// Forgets the signed-in user. Called on sign-out.
  void resetIdentity();

  /// Asks the user to allow notifications. False when refused or unavailable.
  Future<bool> requestPushPermission();

  /// Asks for the notification permission, then ties this device to the
  /// signed-in user and subscribes it to the broadcast topic, as the React
  /// Native app's `registerPush` does. False when refused or unavailable.
  Future<bool> registerPush();

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

  /// Attributes a collected payment's revenue to the install source.
  void capturePayment(double amount, {String? orderId});

  /// Shows an in-app nudge set up for [route], if there is one.
  void checkNudges(BuildContext context, String route);
}
```

### `lib/core/services/katyayani_core/ko_engagement_service_impl.dart`

```dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:katyayani_core/katyayani_core.dart';

import '../analytics/analytics_item.dart';
import '../local_notifications/local_notification_service_impl.dart';
import 'kc_identity.dart';
import 'ko_engagement_service.dart';

/// [KoEngagementService] on the `katyayani_core` SDK. The only file that
/// imports it.
class KoEngagementServiceImpl implements KoEngagementService {
  /// The FCM topic every device joins, for broadcast campaigns.
  static const String broadcastTopic = 'all_users';

  KoEngagementServiceImpl({required String siteId, required String apiBase})
    : _siteId = siteId,
      _apiBase = apiBase;

  final String _siteId;
  final String _apiBase;

  /// Logs for developers: to the debug console, and in debug builds to
  /// logcat too (`dart:developer` output never reaches it).
  static void _log(String message) {
    log(message);
    if (kDebugMode) debugPrint(message);
  }

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

  void _listen() {
    try {
      KatyayaniCore.onNotificationAction((notification, action) {
        // TODO(push): route the tap in the next phase.
        _log('[kc] notification ${action.name}: ${notification.id}');
      });
      KatyayaniCore.onNotificationButtonAction((notification, buttonId) {
        // TODO(push): act on the button in the next phase.
        _log('[kc] notification button $buttonId: ${notification.id}');
      });
      KatyayaniCore.onDeferredDeepLink((deepLink, attribution) {
        // TODO(push): open the deep link in the next phase.
        _log('[kc] deferred deep link: $deepLink');
      });
      KatyayaniCore.onReferral((referralCode, params) {
        // TODO(push): apply the referral code in the next phase.
        _log('[kc] referral: $referralCode');
      });
      KatyayaniCore.onNudgeNavigation((url) {
        // TODO(push): open the nudge's link in the next phase.
        _log('[kc] nudge navigation: $url');
      });
    } catch (e) {
      // The SDK started without push (e.g. no Firebase).
      _log('[kc] listeners not set: $e');
    }
  }

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

  @override
  Future<bool> requestPushPermission() async {
    if (!_started) {
      _log('[kc] push permission skipped: SDK not started');
      return false;
    }
    try {
      final granted = await KatyayaniCore.requestPushPermission();
      _log('[kc] push permission granted: $granted');
      return granted;
    } catch (e) {
      _log('[kc] push permission failed: $e');
      return false;
    }
  }

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

  @override
  void track(String name, {Map<String, dynamic>? properties}) =>
      _guard(name, () => KatyayaniCore.track(name, properties: properties));

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      _guard(
        'screen_view',
        () => KatyayaniCore.screenView(screenName, properties: properties),
      );

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) => _guard(
    'view_item',
    () => KatyayaniCore.viewItem(items: _kcItems(items), value: value),
  );

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) => _guard(
    'add_to_cart',
    () => KatyayaniCore.addToCart(items: _kcItems(items), value: value),
  );

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      _guard(
        'remove_from_cart',
        () =>
            KatyayaniCore.removeFromCart(items: _kcItems(items), value: value),
      );

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) => _guard(
    'view_cart',
    () => KatyayaniCore.viewCart(items: _kcItems(items), value: value),
  );

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => _guard(
    'begin_checkout',
    () => KatyayaniCore.beginCheckout(
      items: _kcItems(items),
      value: value,
      coupon: coupon,
    ),
  );

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => _guard(
    'purchase',
    () => KatyayaniCore.purchase(
      transactionId: transactionId,
      items: _kcItems(items),
      value: value,
      shipping: shipping,
      coupon: coupon,
    ),
  );

  @override
  void search(String searchTerm) =>
      _guard('search', () => KatyayaniCore.search(searchTerm: searchTerm));

  @override
  void login({String? method}) =>
      _guard('login', () => KatyayaniCore.login(method: method));

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => _guard(
    'add_payment_info',
    () => KatyayaniCore.addPaymentInfo(
      items: _kcItems(items),
      value: value,
      paymentType: paymentType,
    ),
  );

  @override
  void capturePayment(double amount, {String? orderId}) => _guard(
    'capturePayment',
    () => unawaited(
      KatyayaniCore.capturePayment(
        amount,
        orderId: orderId,
      ).catchError((Object e) => _log('[kc] capturePayment failed: $e')),
    ),
  );

  @override
  void checkNudges(BuildContext context, String route) => _guard(
    'checkNudges',
    () => unawaited(
      KatyayaniCore.checkNudges(
        context,
        route,
      ).catchError((Object e) => _log('[kc] checkNudges failed: $e')),
    ),
  );

  /// Runs an SDK call when started; an SDK error never reaches the app.
  void _guard(String what, void Function() call) {
    if (!_started) return;
    try {
      call();
    } catch (e) {
      _log('[kc] $what failed: $e');
    }
  }

  static List<KCItem> _kcItems(List<AnalyticsItem> items) => [
    for (final item in items)
      KCItem(
        sku: item.sku,
        qty: item.quantity,
        rate: item.price,
        name: item.name,
        category: item.category,
      ),
  ];
}
```

What the template encodes (for a different engagement SDK): the SDK is imported in
one file; `init()` memoises its own future (`_starting ??= _start()`) so a second
call is free and `identify`/`resetIdentity` can `await` it; `_started` gates every
other call through `_guard`; the two SDK calls that return a `Future` are
`unawaited(...).catchError(...)` inside `_guard`; the phone-only platform gate; the
`[kc]` prefixed `_log` that also reaches logcat in debug; configuration comes in by
constructor (read from `Env` in `injection_container.dart`:
`KoEngagementServiceImpl(siteId: Env.kcSiteId, apiBase: Env.kcApiUrl)`). The
SDK-specific pieces are the `KCConfig(...)` literal, the five `KatyayaniCore.on…`
callbacks (all `TODO(push)`), `broadcastTopic`, and `_kcItems`.

### `lib/core/services/katyayani_core/kc_identity.dart`

```dart
/// Who the signed-in user is to Katyayani Core: the id and the profile
/// details sent with `identify`.
class KcIdentity {
  const KcIdentity({required this.userId, required this.traits});

  /// The phone in E.164, e.g. `+916261414316`. KC keys its profiles by it.
  final String userId;
  final Map<String, dynamic> traits;
}

/// The identity the React Native app sends (`RootNavigator.tsx`), built from
/// the user's [phone] and profile. Null when there is no phone: the user is
/// identified by phone only, never by another id.
///
/// KC stores the name in two fields, so it is sent split as well as whole.
/// Missing values are left out.
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

Its test (`test/core/services/katyayani_core/kc_identity_test.dart`, read in full)
pins: `'+916261414316'` with `'  Ram  Kumar Singh '` → traits
`{'name': 'Ram  Kumar Singh', 'firstName': 'Ram', 'lastName': 'Kumar Singh', 'phone': '+916261414316', 'country_code': '+91', 'phone_number': '6261414316', 'email': 'ram@example.com'}`
(note the double space inside `name` is kept: only the ends are trimmed);
`'916261414316'` → `'+916261414316'`; a 10-digit `'6261414316'` → userId
`'+6261414316'` with `country_code '+91'`; one-word name → no `lastName`, blank
email → no `email`; `''` and `'+ -'` → `null`.

### The three analytics files the interface mirrors (owner: analytics-engagement-platform.md P-2 / P-7; repeated because the diff above depends on them)

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

`lib/core/services/analytics/ko_analytics_service.dart` (the adapter; two no-ops):

```dart
import 'package:flutter/widgets.dart';

import '../katyayani_core/ko_engagement_service.dart';
import 'analytics_item.dart';
import 'analytics_service.dart';

/// [AnalyticsService] that reports to Katyayani Core only. The app uses it
/// inside [MultiDestinationAnalyticsService], which adds Google Analytics
/// and Meta.
class KoAnalyticsService implements AnalyticsService {
  const KoAnalyticsService(this._core);

  final KoEngagementService _core;

  @override
  void track(String name, {Map<String, dynamic>? properties}) =>
      _core.track(name, properties: properties);

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      _core.screenView(screenName, properties: properties);

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      _core.viewItem(items: items, value: value);

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) =>
      _core.addToCart(items: items, value: value);

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      _core.removeFromCart(items: items, value: value);

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
  void search(String searchTerm) => _core.search(searchTerm);

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
  void setUserId(String? userId) {}

  @override
  Future<void> requestTrackingPermission() async {}

  @override
  void checkNudges(BuildContext context, String route) =>
      _core.checkNudges(context, route);
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

The test double `FakeKoEngagementService` (every method, plus
`registerFakeEngagement()`) is quoted in "Follow-up: test helper fakes".

---

## Follow-up: RazorpayPaymentGateway and the payment contract (verbatim, both files)

**Rows to ignore:** `di-bootstrap-app.md:168` and `tests-tooling-config.md:189`
give `GatewayCheckout({required keyId, …})` / `GatewayPayment({required paymentId, …})`
without types or defaults. analytics-engagement-platform.md P-12 (line 1864) has
`GatewayPaymentError`, `GatewayPaymentException`, `PaymentGateway`, `collect()`,
`optionsFor` and most of `classifyRazorpayError` verbatim but describes `_reasons`,
`_keyLabel` and `_trace` in prose. Both files follow complete; this section is
their owner.

### `lib/core/services/payments/payment_gateway.dart` (CONDITIONAL(payments); gateway-neutral)

```dart
/// What the payment sheet is opened with: the gateway order to collect
/// against, the key of the account it was created in, and who is paying.
class GatewayCheckout {
  const GatewayCheckout({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.merchantName,
    required this.description,
    this.contact,
    this.email,
  });

  /// The public key of the account the order was created in. The gateway
  /// looks the order up inside that account, so another account's key
  /// fails at the gateway.
  final String keyId;

  /// The gateway's order id, e.g. `order_…`.
  final String orderId;

  /// The amount in paise (rupees × 100): the only place the app deals in
  /// paise.
  final int amountPaise;
  final String merchantName;

  /// Shown on the sheet. KO's payment webhook recognises this app's orders
  /// by it, so the caller must pass the text KO expects.
  final String description;

  /// `+91XXXXXXXXXX`, to prefill the sheet; null leaves it blank.
  final String? contact;
  final String? email;
}

/// A payment the sheet reported as collected. The gateway's success says
/// the sheet closed happily; whether the money was captured is for the
/// server to confirm.
class GatewayPayment {
  const GatewayPayment({
    required this.paymentId,
    required this.orderId,
    this.signature = '',
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

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

### `lib/core/services/payments/razorpay_payment_gateway.dart` (CONDITIONAL(Razorpay))

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_gateway.dart';

/// The Razorpay checkout sheet. The only file that imports
/// `razorpay_flutter`.
///
/// The SDK reports through events, so each [collect] registers the three
/// handlers, opens the sheet and completes with the first event, then
/// clears them. The sheet owns the screen while it is up; it has its own
/// back and close.
class RazorpayPaymentGateway implements PaymentGateway {
  RazorpayPaymentGateway({Razorpay Function()? newSdk})
    : _newSdk = newSdk ?? Razorpay.new;

  final Razorpay Function() _newSdk;
  Completer<GatewayPayment>? _inFlight;

  /// The brand colour of the sheet, Razorpay's own default otherwise.
  static const String themeColor = '#225542';

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

  /// The key's mode and first characters: enough to tell a test key from a
  /// live one, or one account's key from another's. A key id is public
  /// (it ships in the app), but the whole of it is not needed here.
  static String _keyLabel(String keyId) {
    final mode = keyId.startsWith('rzp_test_')
        ? 'TEST'
        : keyId.startsWith('rzp_live_')
        ? 'LIVE'
        : 'UNKNOWN';
    final head = keyId.length > 14 ? '${keyId.substring(0, 14)}…' : keyId;
    return '$head ($mode)';
  }

  /// Writes to the console in debug builds, so a payment that goes wrong
  /// can be read with `adb logcat -s flutter` (`dart:developer`'s `log`
  /// reaches only an attached debugger). Silent in release.
  static void _trace(String message) {
    if (kDebugMode) debugPrint('[razorpay] $message');
  }

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
}

/// What a Razorpay failure means, read the previous app's way
/// (`paymentErrors.ts`): a cancellation first (code 2, or "cancel" in the
/// text), then the network code, then the gateway's own `reason` or
/// description. The plugin hands the gateway's error object over as
/// [error] (`{ "code", "description", "reason", "step", … }`) with its
/// description as [message]; an older build sends the whole envelope as
/// JSON text in [message] instead, so both are read.
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

What the test pins (`test/core/services/payments/razorpay_payment_gateway_test.dart`,
147 lines, read in full; previously "(head)"): code `2` → `cancelled` whatever the
text; the "delay in response from the UPI app" text → `upiTimeout`; code `0` with
"Network error" → `network`; each `reason` in the gateway's error object maps
(`insufficient_funds`, `incorrect_otp`, `payment_timeout`, `invalid_vpa`,
`card_declined`, `expired_card`, `incorrect_cvv` → `invalidCard`, `gateway_error`
→ `bankDown`, `limit_exceeded`); the same reason inside a JSON envelope in
`message`; codes `1`, `3`, `4` → `notConfigured`; an unknown reason keeps a short
plain `detail`, never JSON, never ≥160 chars; `optionsFor` reproduces the exact map
(`'key'`, `'order_id'`, `'amount'`, `'currency': 'INR'`, `'name'`, `'description'`,
`'retry': {'enabled': false}`, `'prefill': {'contact', 'email'}`,
`'theme': {'color': RazorpayPaymentGateway.themeColor}`); a blank contact and email
leave `options['prefill']` **empty**. The plugin constants used:
`Razorpay.PAYMENT_CANCELLED` (= 2), `Razorpay.NETWORK_ERROR` (= 0),
`Razorpay.INVALID_OPTIONS` (= 1), `Razorpay.TLS_ERROR` (= 3),
`Razorpay.INCOMPATIBLE_PLUGIN` (= 4), as the test's literal codes show.

How the repository uses it (owner: data-strategies.md / networking.md for
`CheckoutRepositoryImpl`): `collectPayment(registered, {contact, email})` builds
`GatewayCheckout(keyId: registered.keyId, orderId: registered.razorpayOrderId, amountPaise: (total × 100).round(), merchantName: CheckoutRepositoryImpl.paymentMerchant, description: CheckoutRepositoryImpl.paymentDescription, contact:, email:)`,
maps `GatewayPaymentError.cancelled`/`upiTimeout` → `PaymentCancelledFailure(upiTimeout:)`,
`notConfigured` → `PaymentNotConfiguredFailure`, every other value →
`PaymentFailedFailure(reason: PaymentFailureReason.<same name>, detail:)` (asserted
in `checkout_repository_impl_test.dart` group `collectPayment`, quoted in
"Follow-up: self-declared partial reads"). The DI line is
`..registerLazySingleton<PaymentGateway>(RazorpayPaymentGateway.new)`.

---

## Follow-up: theme widgets — copy-only vs reproduce-from-text

theme-and-widgets.md §2a gives every public constructor exactly, but a widget's
*look* lives in its `build`. Only the files marked **REPRODUCE** below have their
body quoted verbatim in an inventory; every other file is **COPY**: the skill ships
the file from this repo and copies it character for character (then substitutes
the placeholders theme-and-widgets.md §6 lists). Line counts are the repo's
(`wc -l`). "test" is the file under `test/core/widgets/` that mirrors the path.
"wired" says whether anything outside the form system reaches the widget today.

| file | lines | inventory status | test | class | action |
|---|---|---|---|---|---|
| `lib/core/theme/app_colors.dart` | 66 | verbatim, theme-and-widgets.md §2c line 386 | — | ALWAYS | **REPRODUCE** (substitute hex values) |
| `lib/core/theme/app_theme.dart` | 105 | verbatim, §2c line 460 | — | ALWAYS | **REPRODUCE** |
| `lib/core/theme/app_tones.dart` | 74 | verbatim, §2c line 595 | — | ALWAYS | **REPRODUCE** |
| `lib/core/widgets/app_card.dart` | 168 | ctor only (§2a) | `app_card_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/app_logo.dart` | 42 | ctor only | — | ALWAYS | **COPY** |
| `lib/core/widgets/app_network_image.dart` | 95 | ctor only | `app_network_image_test.dart` | CONDITIONAL(network images) | **COPY** |
| `lib/core/widgets/buttons/add_button.dart` | 60 | ctor only | `buttons/add_button_test.dart` | CONDITIONAL(cart) | **COPY** |
| `lib/core/widgets/buttons/circle_icon_button.dart` | 93 | ctor only | — | ALWAYS | **COPY** |
| `lib/core/widgets/buttons/dashed_outline_button.dart` | 127 | ctor only | `buttons/dashed_outline_button_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/buttons/heart_toggle_button.dart` | 92 | ctor only | `buttons/heart_toggle_button_test.dart` | CONDITIONAL(wishlist) | **COPY** |
| `lib/core/widgets/buttons/primary_button.dart` | 124 | verbatim, §3 P1 line 1732 | `buttons/primary_button_test.dart` | ALWAYS | **REPRODUCE** |
| `lib/core/widgets/buttons/secondary_button.dart` | 115 | ctor only | `buttons/secondary_button_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/buttons/slide_action_button.dart` | 546 | ctor only (+ `completeAt` const) | `buttons/slide_action_button_test.dart` | CONDITIONAL(slide-to-confirm) | **COPY** (stateful, animation controllers; do not attempt from prose) |
| `lib/core/widgets/cart/cart_summary_bar.dart` | 144 | ctor only | `cart/cart_summary_bar_test.dart` | CONDITIONAL(cart) | **COPY** |
| `lib/core/widgets/chips/category_chip.dart` | 139 | ctor only | — | CONDITIONAL(category strip) | **COPY** |
| `lib/core/widgets/chips/filter_chip_button.dart` | 95 | ctor only | `chips/filter_chip_button_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/chips/info_chip.dart` | 105 | ctor only (+ `heightFor` in P3) | — | ALWAYS | **COPY** |
| `lib/core/widgets/form_section_title.dart` | 66 | ctor only | `form_section_title_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/icon_list_tile.dart` | 228 | ctor only | `icon_list_tile_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/page_header.dart` | 157 | ctor only (+ `contentHeightFor` in P3) | `page_header_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/product/explore_more_card.dart` | 186 | ctor only | `product/explore_more_card_test.dart` | CONDITIONAL(product lists) | **COPY** |
| `lib/core/widgets/product/order_line_tile.dart` | 80 | ctor only | `product/order_line_tile_test.dart` | CONDITIONAL(orders) | **COPY** |
| `lib/core/widgets/product/product_card.dart` | 374 | header + ctor verbatim (§2b line 161); body prose | `product/product_card_test.dart` | CONDITIONAL(product lists) | **COPY** |
| `lib/core/widgets/product/product_grid.dart` | 75 | ctor only | — | CONDITIONAL(product lists) | **COPY** |
| `lib/core/widgets/product/product_list_tile.dart` | 552 | header + ctor verbatim (§2b line 219); body prose | `product/product_list_tile_test.dart` | CONDITIONAL(product lists / cart) | **COPY** |
| `lib/core/widgets/product/product_rail.dart` | 57 | ctor only | `product/product_rail_test.dart` | CONDITIONAL(product lists) | **COPY** |
| `lib/core/widgets/product/quantity_stepper.dart` | 222 | ctor only | `product/quantity_stepper_test.dart` | CONDITIONAL(cart) | **COPY** |
| `lib/core/widgets/progress_indecator.dart` | 31 | ctor only | — | ALWAYS (mobile; `dart:io`) | **COPY** (keep the misspelt name; used by `universal_form_field.dart`, `categories_page.dart`, `payment_gate_overlay.dart`, `my_orders_page.dart`, `reviews_section.dart`) |
| `lib/core/widgets/reload_widget.dart` | 45 | ctor only (`Key('reload_button')`) | — | ALWAYS | **COPY** |
| `lib/core/widgets/rich_text.dart` | 162 | — | — | LEGACY (AGENTS.md §16; imported by nothing) | **EXCLUDE** |
| `lib/core/widgets/search/app_search_bar.dart` | 65 | ctor only | — | CONDITIONAL(search input) | **COPY** |
| `lib/core/widgets/search/search_trigger_bar.dart` | 92 | ctor only | `search/search_trigger_bar_test.dart` | CONDITIONAL(search screen) | **COPY** |
| `lib/core/widgets/section_header.dart` | 79 | ctor only | — | ALWAYS | **COPY** |
| `lib/core/widgets/section_label.dart` | 54 | ctor only | `section_label_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/sheets/app_info_sheet.dart` | 180 | ctor only (+ `show` pattern in P5) | `sheets/app_info_sheet_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/sheets/app_picker_sheet.dart` | 131 | ctor only (+ `show<T>` pattern in P5) | `sheets/app_picker_sheet_test.dart` | ALWAYS | **COPY** |
| `lib/core/widgets/sheets/option_tile.dart` | 137 | ctor only | — | ALWAYS | **COPY** |
| `lib/core/widgets/form_helper/universal_form_field.dart` | 322 | verbatim, §2c line 1191 (`build()` at 1224) | `form_helper/universal_form_field_test.dart`, `form_helper/field_theme_colors_test.dart` | ALWAYS | **REPRODUCE** |
| `lib/core/widgets/form_helper/field_config.dart` | 507 | verbatim, §2c lines 667–1190 | — | ALWAYS | **REPRODUCE** (whole file, dead configs included, for the enum order) |
| `lib/core/widgets/form_helper/field_title.dart` | 30 | verbatim, §2c line 1509 | — | ALWAYS | **REPRODUCE** |
| `lib/core/widgets/form_helper/decorator/field_decorator.dart` | 120 | verbatim, §2c line 1542 | — | ALWAYS | **REPRODUCE** |
| `lib/core/widgets/form_helper/fields/custom_text_form_field.dart` | 243 | fields + ctor verbatim (§2b line 266); body prose | (through `universal_form_field_test`) | ALWAYS (`UFFType.text`, 13 uses) | **COPY** |
| `lib/core/widgets/form_helper/fields/phone_text_form_field.dart` | 208 | fields + ctor verbatim (§2b line 341); body prose | (through `universal_form_field_test`) | CONDITIONAL(phone) (`UFFType.phone`, 2 uses) | **COPY** |
| `lib/core/widgets/form_helper/fields/otp_input_field.dart` | 232 | ctor only | — | CONDITIONAL(OTP) (`UFFType.otp`, 1 use) | **COPY** |
| `lib/core/widgets/form_helper/fields/dropdown_fields.dart` | 147 | ctor only | — | ALWAYS (`UFFType.dropdown`, 1 use) | **COPY** |
| `lib/core/widgets/form_helper/fields/choice_chips_field.dart` | 90 | ctor only | — | ALWAYS (`UFFType.choiceChips`, 2 uses) | **COPY** |
| `lib/core/widgets/form_helper/fields/custom_search_field.dart` | 208 | ctor only | — | CONDITIONAL(search) (`UFFType.search`, 4 uses via `AppSearchBar`) | **COPY** |
| `lib/core/widgets/form_helper/fields/rating_field.dart` | 102 | ctor only | `form_helper/fields/rating_field_test.dart` | CONDITIONAL(ratings) (`UFFType.rating`, 1 use) | **COPY** |
| `lib/core/widgets/form_helper/fields/chip_input_field.dart` | 136 | ctor only | — | wired (`case UFFType.multiChipField`) but **unused by features** | **COPY** (or drop with its `case`) |
| `lib/core/widgets/form_helper/fields/date_slector_field.dart` (sic) | 209 | ctor only | — | wired (`case UFFType.date`), unused | **COPY** (or drop with its `case`) |
| `lib/core/widgets/form_helper/fields/time_selector_field.dart` | 234 | ctor only | — | wired (`case UFFType.time`), unused | **COPY** (or drop with its `case`) |
| `lib/core/widgets/form_helper/fields/radio_toggle.dart` | 24 | ctor only | — | wired (`case UFFType.radio`), unused | **COPY** (or drop with its `case`) |
| `lib/core/widgets/form_helper/fields/drop_down_multi_chip.dart` | 124 | ctor only | — | **not wired** (no `case UFFType.dropdownMultiChip`), unused | **EXCLUDE**-able (dead) |
| `lib/core/widgets/form_helper/chips/primary_chip.dart` | 50 | — | — | dependency of `chip_input_field.dart` and `drop_down_multi_chip.dart` only | **COPY** only if those are kept |
| `lib/core/widgets/form_helper/chips/activity_chip.dart` | 75 | — | — | LEGACY, imported by nothing | **EXCLUDE** |
| `lib/core/widgets/form_helper/chips/icon_labled_chip.dart` (sic) | 51 | — | — | LEGACY, imported by nothing | **EXCLUDE** |
| `lib/core/widgets/form_helper/chips/simple_info_chip.dart` | 27 | — | — | LEGACY, imported by nothing | **EXCLUDE** |

Totals: 56 files under `lib/core/widgets/` + `lib/core/theme/`; **8 REPRODUCE**
(3 theme files, `primary_button.dart`, `universal_form_field.dart`,
`field_config.dart`, `field_title.dart`, `field_decorator.dart`), **5 EXCLUDE**
(`rich_text.dart`, the three legacy chips, `drop_down_multi_chip.dart`), the
remaining **43 COPY**. Of the COPY set, 26 have a widget test under
`test/core/widgets/` (list in theme-and-widgets.md §1, "Tests read"); the skill
copies those tests too, with the same `package:mymali/` → `package:<app>/` rewrite.

Which `UFFType` values reach a widget today (`universal_form_field.dart`
`switch (fieldType)`): `text`, `phone`, `search`, `dropdown`, `multiChipField`,
`radio`, `date`, `time`, `otp`, `choiceChips`, `rating`; every other value hits
`default`. The `build()` imports exactly these field files:
`chip_input_field.dart`, `date_slector_field.dart`, `radio_toggle.dart`,
`time_selector_field.dart`, `progress_indecator.dart`, `field_config.dart`,
`field_title.dart`, `fields/choice_chips_field.dart`,
`fields/custom_search_field.dart`, `fields/custom_text_form_field.dart`,
`fields/dropdown_fields.dart`, `fields/otp_input_field.dart`,
`fields/phone_text_form_field.dart`, `fields/rating_field.dart` (note the mixed
`package:mymali/…` and relative import styles in one file).

Rule for the skill: *a widget file is reproducible from an inventory only when
that inventory quotes its `build` method.* Constructors, theme roles (§2d) and
paddings in prose are enough to **use** a widget, not to **re-create** its look.

---

## Follow-up: Networking.patchAPICall and deleteAPICall (verbatim signatures)

**Rows to ignore:** `networking.md:70` and `networking.md:72` ("same parameter list
as `postAPICall`"); the complete file is in networking.md §3.1 (lines 132–664) and
remains the owner. The abstract declarations, exactly as the file has them
(`lib/core/services/networking/networking.dart` lines 31–84):

```dart
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
```

The two implementations (lines 333–415), which differ from `postAPICall` in **when
`Content-Type` is sent** and in the order of logging:

```dart
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
```

For contrast, `putAPICall` (lines 417–450) has no `headers` parameter and passes
`options: await _optionsFor(host)` straight to Dio; `getAPICall` passes
`_optionsFor(host, hasBody: false)`; `postAPICall` passes
`_optionsFor(host, contentType: data is FormData ? Headers.multipartFormDataContentType : null)`.
The abstract class declares `Future<dynamic>`, the implementations return
`Future<APIResponse>` (a covariant narrowing); data sources type the result as
`Object?` and test it with `is SuccessResponse` / `is ErrorResponse`.

`FakeNetworking` (`test/helpers/fake_networking.dart`, verbatim in
networking.md §3.17 and in "Follow-up: test helper fakes") overrides exactly
`getAPICall`, `postAPICall`, `deleteAPICall`, `patchAPICall`, records each as a
`RecordedCall(method: 'GET' | 'POST' | 'DELETE' | 'PATCH', …)`, and leaves
`putAPICall` and `graphqlQueryCall` to `noSuchMethod`.

Callers of the two methods in `lib/`: `deleteAPICall` is used by the address
remote data source (`networking.md:1834`), `patchAPICall` by the same file
(`networking.md:1845`); both are PostgREST calls on `ApiHost.supabase` with
`_restHeaders` (`{'apikey': _anonKey}`).

---

## Follow-up: cross-inventory duplication — take each signature from its owner only

The ten inventories repeat core signatures; only one file per signature was
written from the source with the file open, the rest paraphrase (`…`, `[dynamic data]`,
"same", untyped parameter lists). The skill reads a signature **only** from the
owner named here. Every other mention is commentary.

| signature / file | owner (inventory § / line) | paraphrases to ignore (file:line) |
|---|---|---|
| `enum ApiHost`, `abstract class Networking`, `NetworkingService` (complete file) | networking.md §3.1 (132–664; `abstract class Networking` at 166) + this file's "Follow-up: Networking.patchAPICall…" | domain-data-shapes.md:152; tests-tooling-config.md:168; data-strategies.md:174; di-bootstrap-app.md:153; networking.md:70,72 |
| `BaseApiRepo` | networking.md §3.2 (664) | di-bootstrap-app.md:155 (spelling note only) |
| `Endpoints`, `MedusaEndpoints`, `KoUtilsEndpoints`, `StockshipEndpoints` (complete file) | networking.md §3.3 (683; classes at 688, 762, 779, 801) | di-bootstrap-app.md:156-157, :1467 ("see file"); data-strategies.md:176-177 (the subset it uses) |
| `CurlLoggerInterceptor` | networking.md §3.4 (810) | — |
| `APIResponse`, `SuccessResponse`, `ErrorResponse`, `InvalidResponse` | networking.md §3.5 (924) | di-bootstrap-app.md:159; tests-tooling-config.md:170-171; domain-data-shapes.md:145-148 |
| `AppException` family, `ServerException`/`ConnectionException`, `Failure` family | networking.md §3.6 (1058) | di-bootstrap-app.md:160-161,174; tests-tooling-config.md:172-178 |
| `Env`, `KoEnv`, `RazorpayMode`, `.env.example` | networking.md §3.7 (1200) | domain-data-shapes.md:163; di-bootstrap-app.md:1464 (the key list is a useful index, not the source) |
| `StringConstants` (live part) | networking.md §3.8 (1374); the legacy members: this file, "Follow-up: shared_pref_repository.dart" | di-bootstrap-app.md:158; domain-data-shapes.md:150 |
| `KoTokenService` / `KoTokenServiceImpl` | networking.md §3.9 (1389) | di-bootstrap-app.md:166; analytics-engagement-platform.md P-13 (pattern commentary) |
| `json_readers.dart`, `currency_format.dart` | networking.md §3.10 (1497) | domain-data-shapes.md:149; data-strategies.md:170 |
| `FakeNetworking`, `RecordedCall`, `okResponse`, `errorResponse` | networking.md §3.17 (2297) = tests-tooling-config.md Pattern 3 (439) = this file's fakes section (identical text) | tests-tooling-config.md:16 (role row) |
| `PrefUtils` (complete file) | storage-secrets-cache.md §3.12 (999; `class PrefUtils` at 1006) | domain-data-shapes.md:162 (ends in `…`); data-strategies.md:173; di-bootstrap-app.md:162; tests-tooling-config.md:186 |
| `LocalCache` | storage-secrets-cache.md §3.1 (165; at 174) | di-bootstrap-app.md:148; tests-tooling-config.md:180; domain-data-shapes.md:160 |
| `HiveLocalCache` | storage-secrets-cache.md §3.2 (207) | di-bootstrap-app.md:149; tests-tooling-config.md:182 |
| `CacheBoxes` | storage-secrets-cache.md §3.3 (361; at 365) | di-bootstrap-app.md:150; tests-tooling-config.md:181; domain-data-shapes.md:161 |
| `DeviceSecureStorage` | storage-secrets-cache.md §3.7 (628) | di-bootstrap-app.md:164; tests-tooling-config.md:184 |
| `SecureSessionStorage` | storage-secrets-cache.md §3.8 (727) + this file's follow-up | **di-bootstrap-app.md:165 and tests-tooling-config.md:185 are wrong** (public parameter names) |
| `AuthLocalDataSource` (keys, migration) | storage-secrets-cache.md §3.9 (783) | di-bootstrap-app.md:1468 |
| `FakeLocalCache`, `FakeSecureStorage` | storage-secrets-cache.md §3.13 (1077) = this file's fakes section | tests-tooling-config.md:18-19 |
| `AnalyticsService` (complete) | analytics-engagement-platform.md P-2 (316) (+ this file, follow-up B) | di-bootstrap-app.md:135; tests-tooling-config.md:191; presentation-bloc-pages.md:112 |
| `AppEvents` (complete) | analytics-engagement-platform.md P-3 (433; `abstract final class AppEvents` at 441) | di-bootstrap-app.md:141 (`… static const String themeChanged`); presentation-bloc-pages.md:113 |
| `MultiDestinationAnalyticsService`, `AnalyticsDestination` | analytics-engagement-platform.md P-4 (540) | di-bootstrap-app.md:136-137 |
| `analytics_event_mapper.dart` | analytics-engagement-platform.md P-5 (716) | — |
| `FirebaseAnalyticsDestination`, `MetaAnalyticsDestination` | analytics-engagement-platform.md P-6 (924) | di-bootstrap-app.md:139-140 |
| `KoAnalyticsService` | analytics-engagement-platform.md P-7 (1141) (+ this file, follow-up B) | di-bootstrap-app.md:138; tests-tooling-config.md:192 |
| `AnalyticsScreenTracker`, `AnalyticsRouteObserver`, `analyticsScreenNames`, `analyticsTabs` | analytics-engagement-platform.md P-8 (1172) | router-navigation.md (commentary) |
| `KoEngagementService`, `KoEngagementServiceImpl`, `KcIdentity`, `kcIdentityFor` | **this file, "Follow-up: KoEngagementService…"** (first verbatim) | analytics-engagement-platform.md:156-158, P-10 (1623: constructor + `_guard` only); di-bootstrap-app.md:143-145; tests-tooling-config.md:191; presentation-bloc-pages.md:114 |
| `LocalNotificationService(Impl)` | analytics-engagement-platform.md P-11 (1757) | di-bootstrap-app.md:146-147 |
| `PaymentGateway`, `GatewayCheckout`, `GatewayPayment`, `GatewayPaymentError`, `GatewayPaymentException`, `RazorpayPaymentGateway`, `classifyRazorpayError`, `_reasons`, `_readable` | **this file, "Follow-up: RazorpayPaymentGateway…"** (both files complete) | analytics-engagement-platform.md P-12 (1864: partial); di-bootstrap-app.md:167-169; tests-tooling-config.md:189 |
| `AppColors`, `AppTheme`, `AppTones` | theme-and-widgets.md §2c (386, 460, 595) | di-bootstrap-app.md:170-172 |
| `UFFType`, every `*Config`, `UniversalFormField` (incl. `build()`), `FieldTitle`, `FieldDecorator` | theme-and-widgets.md §2c (667–1663; `class UniversalFormField` 1191, `Widget build({` 1224) (+ this file, "Follow-up: UniversalFormField.build()") | presentation-bloc-pages.md:114 (`build({…, otpConfig, …})`) |
| `PrimaryButton` | theme-and-widgets.md P1 (1732) | — |
| `ProductCard`, `ProductListTile`, `CustomTextFormField`, `PhoneTextFormField` constructors | theme-and-widgets.md §2b (157) | — |
| every other widget | **the repo file itself** (COPY; see "Follow-up: theme widgets") | theme-and-widgets.md §2a (constructors, correct but not sufficient) |
| `AppRouter` (complete) | router-navigation.md §3.1 (364; `class AppRouter` 367) — verified complete against the source: 5 `StatefulShellBranch`, 24 `GoRoute` | analytics-engagement-platform.md:45,135; di-bootstrap-app.md:25,128; presentation-bloc-pages.md:102,332 |
| `AppRoute` enum, `navigator_keys.dart`, `AppShellScaffold`, `AppBottomNavBar` | router-navigation.md §3 | — |
| `bootstrap.dart`, `configureDependencies()` / `_registerCore()` / `register<X>Feature()`, `App` | di-bootstrap-app.md §3.2 (224), §3.4 (329), §3.5–3.11, §3.12 (835) | storage-secrets-cache.md §3.10–3.11 (storage lines only); analytics-engagement-platform.md P-1 item 5 (excerpt) |
| `UseCase`, `NoParams` | domain-data-shapes.md §3 | data-strategies.md:171-172; di-bootstrap-app.md:173; tests-tooling-config.md:188 |
| `signed_in_app.dart`, `fake_account_repository.dart`, the 20 fake repositories | **this file, "Follow-up: test helper fakes"** (complete) = tests-tooling-config.md Pattern 9 (994) for `signed_in_app.dart` | tests-tooling-config.md §1a (16–48, role rows), :163-166 |
| `wishlist_bloc.dart`, `ref_order_remote_data_source.dart`, `ko_order_remote_data_source.dart`, `gstin_sheet.dart`, `cart_page.dart`, `home_page.dart` (complete) | **this file, "Follow-up: self-declared partial reads"** | data-strategies.md 3.F.3 (2630: "the device-first parts"); networking.md:2054 (excerpt); analytics-engagement-platform.md:67-68; di-bootstrap-app.md:84-88 |

Working rule: when two inventories disagree, the owner wins; when the owner is
not verbatim (a table row), the repo file wins and the skill should say so.

---

## Follow-up: Endpoint paths

`di-bootstrap-app.md:1467` ("Endpoint paths | `Endpoints`, `MedusaEndpoints`,
`KoUtilsEndpoints`, `StockshipEndpoints` | see file") is an index entry, not a
source. The complete `lib/core/services/networking/endpoints.dart` is verbatim in
**networking.md §3.3 (lines 683–810)**: `class Endpoints` (688) with the four
`static String` base-URL getters over `Env` and the Supabase `static const String`
paths (`/functions/v1/...`, `/rest/v1/...`), `class MedusaEndpoints` (762),
`class KoUtilsEndpoints` (779: `codOrder = '/order/my-mali'`,
`createOrder = '/order/create-order'`, `paymentStatus = '/order/payment-status-ksr'`,
`refOrders = '/order/ref-orders'`), `class StockshipEndpoints` (801:
`orders = '/api/orders'`). The two data sources quoted in this file use
`KoUtilsEndpoints.refOrders`, `KoUtilsEndpoints.codOrder`,
`KoUtilsEndpoints.createOrder` and `KoUtilsEndpoints.paymentStatus`; those member
names are confirmed against the source of both data sources.

---

## Follow-up: UniversalFormField.build()

`presentation-bloc-pages.md:114` elides the parameter list
(`build({textInputConfig, dropdownConfig, …, otpConfig, choiceChipsConfig, ratingConfig})`).
The complete file is verbatim in theme-and-widgets.md §2c (`class UniversalFormField`
at line 1191, `Widget build({` at 1224). The class header, constructor and the full
`build()` signature, from the source (`lib/core/widgets/form_helper/universal_form_field.dart`
lines 17–69):

```dart
class UniversalFormField {
  final Key? key;
  final bool updateKey;
  final UFFType fieldType;
  final String label;
  final dynamic initialValue;
  final void Function(dynamic val) onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final bool hide;
  final bool fullWidth;
  final bool useController;
  final bool withTitle;
  final TextStyle? labelStyle;

  UniversalFormField({
    this.key,
    this.updateKey = false,
    required this.fieldType,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.controller,
    this.hide = false,
    this.fullWidth = false,
    this.useController = false,
    this.withTitle = false,
    this.labelStyle,
  });

  TextEditingController textEditingController = TextEditingController();

  Widget build({
    TextInputConfig textInputConfig = const TextInputConfig(),
    DropdownConfig dropdownConfig = const DropdownConfig(),
    MultiChipDropdownConfig multiChipDropdownConfig =
        const MultiChipDropdownConfig(),
    // MultiTextConfig multiTextConfig = const MultiTextConfig(),
    // MultiSelectConfig multiSelectConfig = const MultiSelectConfig(),
    DatePickerConfig datePickerConfig = const DatePickerConfig(),
    TimePickerConfig timePickerConfig = const TimePickerConfig(),
    SearchConfig searchConfig = const SearchConfig(),
    RadioConfig radioConfig = const RadioConfig(),
    SingleCheckboxConfig singleCheckboxConfig = const SingleCheckboxConfig(),
    CheckboxConfig checkboxConfig = const CheckboxConfig(),
    // SliderConfig sliderConfig = const SliderConfig(),
    SwitchConfig switchConfig = const SwitchConfig(),
    WrapperConfig wrapperConfig = const WrapperConfig(),
    // IncDecConfig incDecConfig = const IncDecConfig(),
    MultiChipConfig multiChipConfig = const MultiChipConfig(),
    UploadConfig uploadConfig = const UploadConfig(),
    ChatTextBoxConfig chatTextBoxConfig = const ChatTextBoxConfig(),
    OtpConfig otpConfig = const OtpConfig(),
    ChoiceChipsConfig choiceChipsConfig = const ChoiceChipsConfig(),
    RatingConfig ratingConfig = const RatingConfig(),
  }) {
```

Facts the elided row loses: `UniversalFormField` is a **plain class**, not a
`Widget` (`build()` is called by hand and returns the widget); `onChanged` takes
`dynamic`; `initialValue` is `dynamic`; the 17 active config parameters are all
`const` defaults, three more are commented out in place (keep the comments: they
hold the enum-parity history); the field `textEditingController` is a public
mutable `TextEditingController` created per instance (which is why AGENTS.md §13
insists on `initialValue: ''` or `useController: true`); and the `switch (fieldType)`
has 11 `case` labels plus `default` (listed in "Follow-up: theme widgets").

The `UFFType` enum, verbatim from `field_config.dart`:

```dart
enum UFFType {
  text,
  phone,
  date,
  time,
  year,
  address,
  radio,
  switchBtn,
  multiSelect,
  dropdown,
  multiText,
  slider,
  search,
  checkbox,
  upload,
  singleCheckbox,
  incDec,
  dateTimePicker,
  locationWithTextSearch,
  multiChipField,
  richTextEditor,
  multiDocumentSelect,
  chatTextBox,
  dropdownMultiChip,
  otp,
  choiceChips,
  rating,
}
```

Feature usage today (`grep UFFType.` outside `form_helper/`): `text` ×13, `search`
×4 (via `AppSearchBar`), `phone` ×2, `choiceChips` ×2, `dropdown` ×1, `otp` ×1,
`rating` ×1.

---

## Follow-up: LocationStorageFailure

`storage-secrets-cache.md:156` recorded `LocationStorageFailure` as "(not read;
referenced by `LocationRepositoryImpl._guard`)". The file
`lib/features/location/domain/failures/location_failures.dart` (33 lines) and
`lib/features/location/data/repositories/location_repository_impl.dart` (71 lines)
are now read in full and quoted verbatim in P-F3 above. The name is
MYMALI-SPECIFIC (feature level); what the skill keeps is the shape: a feature's
failures in one `domain/failures/<feature>_failures.dart`, `extends Failure` with
`{super.message = '…'}`, one `_guard<T>` in the repository that maps every typed
exception (`LocationStorageException` → `LocationStorageFailure`). The exception
side is in storage-secrets-cache.md:153
(`const LocationStorageException([this.message]); final String? message;`).

---

## Follow-up: test helper fakes (every file under `test/helpers/`, verbatim)

**Rows this replaces:** `tests-tooling-config.md:166` ("Other fakes … by name only")
and the §1a role rows (lines 16–48), which name constructors such as
`FakeMaliCoinsRepository({balance, rules})` without types, fields or bodies. All
28 files under `test/helpers/` follow in full (28 files; tests-tooling-config.md
§1a says "all 29" — the directory holds 28 `.dart` files). The *harness* —
`signed_in_app.dart`, `fake_account_repository.dart`'s `registerAccountFakes`,
`fake_ko_engagement_service.dart`'s `registerFakeEngagement`, `fake_networking.dart`,
`fake_local_cache.dart`, `fake_secure_storage.dart`, `fake_payment_gateway.dart` —
is ALWAYS in shape; every `Fake<X>Repository`'s *content* is MYMALI-SPECIFIC, but
its shape is the §14 contract: `class Fake<Interface> implements <Interface>`, one
`Failure? <call>Failure` per failable call, `int <call>Calls` / `List<…>` recorders,
`Completer<void>? gate` (or `<call>Gate`) awaited at the top of the call, and a
public `test<Thing>` constant for data. Import prefix everywhere: `package:mymali/…`.

### `test/helpers/signed_in_app.dart` (ALWAYS shape; the list of registrations is MyMali's)

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

### `test/helpers/fake_account_repository.dart` (holds `registerAccountFakes`)

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/core/di/injection_container.dart';
import 'package:mymali/features/account/domain/entities/app_version.dart';
import 'package:mymali/features/account/domain/repositories/account_repository.dart';
import 'package:mymali/features/profile/domain/repositories/profile_repository.dart';
import 'package:mymali/features/referral/domain/repositories/referral_repository.dart';

import 'fake_profile_repository.dart';
import 'fake_referral_repository.dart';

/// In-memory [AccountRepository] for tests; a null [version] fails.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({
    this.version = const AppVersion(version: '1.0.1', buildNumber: '9'),
  });

  AppVersion? version;

  @override
  Future<Either<Failure, AppVersion>> getAppVersion() async {
    final version = this.version;
    return version == null
        ? Left(Failure(message: 'No version'))
        : Right(version);
  }
}

/// Registers fakes for the profile, referral and account features and
/// their use cases and blocs, as every test that pumps `App` needs. Call
/// it after `registerMaliCoinsFeature()`. Pass a fake to inspect it.
void registerAccountFakes({
  FakeProfileRepository? profile,
  FakeReferralRepository? referral,
  FakeAccountRepository? account,
}) {
  sl
    ..registerSingleton<ProfileRepository>(profile ?? FakeProfileRepository())
    ..registerSingleton<ReferralRepository>(
      referral ?? FakeReferralRepository(),
    )
    ..registerSingleton<AccountRepository>(account ?? FakeAccountRepository());
  registerProfileFeature();
  registerReferralFeature();
  registerAccountFeature();
}
```

### `test/helpers/fake_address_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/address/domain/entities/saved_address.dart';
import 'package:mymali/features/address/domain/repositories/address_repository.dart';
import 'package:mymali/features/address/domain/utils/address_list.dart';

/// A saved address for tests.
const testAddress = SavedAddress(
  id: 'addr_01',
  label: 'Home',
  houseNo: 'Y',
  area: 'Arera colony',
  city: 'Bhopal',
  district: 'Bhopal',
  state: 'Madhya Pradesh',
  country: 'India',
  pincode: '462016',
  receiverName: 'Asha',
  receiverPhone: '9876543210',
  latitude: 23.2156,
  longitude: 77.4304,
  isDefault: true,
);

/// In-memory [AddressRepository] for tests.
///
/// [addresses] is what the "server" has. [getCachedAddresses] misses until
/// [cachedAddresses] is set. Set [loadFailure] to make the load fail, and
/// [saveFailure] / [removeFailure] to make a change fail. Accepted changes
/// update [addresses] and are recorded in [saved] / [removed].
class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository({List<SavedAddress> addresses = const []})
    : addresses = List.of(addresses);

  List<SavedAddress> addresses;

  /// What the device has saved; null is a cache miss.
  List<SavedAddress>? cachedAddresses;

  Failure? loadFailure;
  int loadCalls = 0;

  /// Completes [getAddresses] only when completed, to hold a load open.
  Completer<void>? gate;

  Failure? saveFailure;
  Failure? removeFailure;

  /// Every address the server accepted, in order.
  final List<SavedAddress> saved = [];

  /// Every id the server deleted, in order.
  final List<String> removed = [];

  /// Completes [saveAddress] / [removeAddress] only when completed.
  Completer<void>? changeGate;

  @override
  Future<Either<Failure, List<SavedAddress>>> getAddresses() async {
    loadCalls++;
    await gate?.future;
    final failure = loadFailure;
    return failure == null ? Right(addresses) : Left(failure);
  }

  @override
  Future<Either<Failure, List<SavedAddress>>> getCachedAddresses() async {
    final cached = cachedAddresses;
    return cached == null ? Left(CacheMissFailure()) : Right(cached);
  }

  @override
  Future<Either<Failure, SavedAddress>> saveAddress(
    SavedAddress address,
  ) async {
    await changeGate?.future;
    final failure = saveFailure;
    if (failure != null) return Left(failure);
    saved.add(address);
    addresses = withSavedAddress(addresses, address);
    return Right(address);
  }

  @override
  Future<Either<Failure, Unit>> removeAddress(String id) async {
    await changeGate?.future;
    final failure = removeFailure;
    if (failure != null) return Left(failure);
    removed.add(id);
    addresses = withoutAddress(addresses, id);
    return const Right(unit);
  }
}
```

### `test/helpers/fake_app_config_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/app_config/domain/entities/app_state.dart';
import 'package:mymali/features/app_config/domain/entities/app_state_request.dart';
import 'package:mymali/features/app_config/domain/entities/banner.dart';
import 'package:mymali/features/app_config/domain/entities/version_settings.dart';
import 'package:mymali/features/app_config/domain/repositories/app_config_repository.dart';

const testAppState = AppState(
  releaseId: 'rel_01',
  banners: [Banner(title: 'Monsoon sale', imageUrl: '/banners/monsoon.jpg')],
  version: VersionSettings(latest: '1.0.2', minSupported: '1.0.0'),
);

/// In-memory [AppConfigRepository] for tests.
///
/// Set [appStateFailure] to make the call fail, or [appState] to change
/// what it returns.
class FakeAppConfigRepository implements AppConfigRepository {
  Failure? appStateFailure;
  AppState appState = testAppState;

  final List<AppStateRequest> requests = [];

  @override
  Future<Either<Failure, AppState>> getAppState(AppStateRequest request) async {
    requests.add(request);
    final failure = appStateFailure;
    return failure == null ? Right(appState) : Left(failure);
  }
}
```

### `test/helpers/fake_cart_remote_data_source.dart` (the one data-source fake shared by tests)

```dart
import 'dart:async';

import 'package:mymali/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:mymali/features/cart/data/models/server_cart_line_model.dart';

/// In-memory [CartRemoteDataSource] for repository tests. [lines] is the
/// server's copy; [replaced] records every list sent to [replaceLines].
class FakeCartRemoteDataSource implements CartRemoteDataSource {
  FakeCartRemoteDataSource({List<ServerCartLineModel> lines = const []})
    : lines = List.of(lines);

  List<ServerCartLineModel> lines;
  Object? fetchError;
  Object? replaceError;

  /// Answers [fetchLines] only when completed, to hold a sync's fetch open
  /// as a slow network does.
  Completer<void>? fetchGate;

  final List<({String userId, List<ServerCartLineModel> lines})> replaced = [];

  @override
  Future<List<ServerCartLineModel>> fetchLines() async {
    await fetchGate?.future;
    final error = fetchError;
    if (error != null) throw error;
    return List.of(lines);
  }

  @override
  Future<void> replaceLines({
    required String userId,
    required List<ServerCartLineModel> lines,
  }) async {
    replaced.add((userId: userId, lines: List.of(lines)));
    final error = replaceError;
    if (error != null) throw error;
    this.lines = List.of(lines);
  }
}
```

### `test/helpers/fake_cart_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/cart/domain/entities/cart.dart';
import 'package:mymali/features/cart/domain/entities/cart_item.dart';
import 'package:mymali/features/cart/domain/entities/cart_stock_check.dart';
import 'package:mymali/features/cart/domain/repositories/cart_repository.dart';
import 'package:mymali/features/cart/domain/utils/cart_stock.dart';
import 'package:mymali/features/cart/domain/utils/merge_cart.dart';
import 'package:mymali/features/catalog/domain/entities/catalog_product.dart';
import 'package:mymali/features/cart/domain/utils/saved_for_later.dart';

const testCartItem = CartItem(
  productId: 'prod_01',
  variantId: 'variant_01',
  title: 'Activated Neem Oil',
  variantLabel: '250 ml',
  thumbnail: 'https://cdn.example.com/neem.jpg',
  unitPrice: 269,
  quantity: 1,
);

/// In-memory [CartRepository] for tests.
///
/// Set [loadFailure] / [saveFailure] to make those calls fail. [items] is
/// the stored cart and [savedForLater] the stored saved list; both can be
/// preset.
class FakeCartRepository implements CartRepository {
  FakeCartRepository({
    List<CartItem> items = const [],
    List<CartItem> savedForLater = const [],
  }) : items = List.of(items),
       savedForLater = List.of(savedForLater);

  List<CartItem> items;
  List<CartItem> savedForLater;
  Failure? loadFailure;

  /// Fails every call that writes: lines and the saved list alike.
  Failure? saveFailure;

  /// Completes [loadCart] only when completed, to hold a load open.
  Completer<void>? gate;

  /// Completes [syncCart] only when completed, to hold a sync open, as a
  /// slow network does.
  Completer<void>? syncGate;

  int loadCalls = 0;
  final List<CartItem> saved = [];

  /// Variant ids passed to [saveForLater], [moveToCart] and [removeSaved].
  final List<String> savedForLaterCalls = [];
  final List<String> moveToCartCalls = [];
  final List<String> removeSavedCalls = [];

  /// The server's lines, merged in by [syncCart].
  List<CartItem> serverItems = const [];
  Failure? syncFailure;
  Failure? pushFailure;

  /// User ids passed to [syncCart] and [pushCart].
  final List<String> syncCalls = [];
  final List<String> pushCalls = [];

  Cart get _cart =>
      Cart(items: List.of(items), savedForLater: List.of(savedForLater));

  @override
  Future<Either<Failure, Cart>> syncCart(String userId) async {
    syncCalls.add(userId);
    // As the real repository: a line changed while the sync runs keeps the
    // device's value.
    final before = _cart;
    await syncGate?.future;
    // As on the device: a cart that cannot be read cannot be synced.
    final failure = syncFailure ?? loadFailure;
    if (failure != null) return Left(failure);

    final now = _cart;
    final merged = mergeServerLines(
      now,
      serverItems,
      deviceWins: changedVariants(before, now),
    );
    items = List.of(merged.items);
    return Right(_cart);
  }

  @override
  Future<Either<Failure, Unit>> pushCart(String userId) async {
    pushCalls.add(userId);
    final failure = pushFailure;
    return failure == null ? Right(unit) : Left(failure);
  }

  @override
  Future<Either<Failure, Cart>> loadCart() async {
    loadCalls++;
    await gate?.future;
    final failure = loadFailure;
    return failure == null ? Right(_cart) : Left(failure);
  }

  @override
  Future<Either<Failure, Cart>> saveItem(CartItem item) async {
    saved.add(item);
    final failure = saveFailure;
    if (failure != null) return Left(failure);

    final index = items.indexWhere((i) => i.variantId == item.variantId);
    if (item.quantity <= 0) {
      if (index >= 0) items.removeAt(index);
    } else if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    return Right(_cart);
  }

  /// Every [removeItems] call, in order.
  final List<List<String>> removed = [];

  @override
  Future<Either<Failure, Cart>> removeItems(List<String> variantIds) async {
    removed.add(List.of(variantIds));
    final failure = saveFailure;
    if (failure != null) return Left(failure);
    items.removeWhere((i) => variantIds.contains(i.variantId));
    return Right(_cart);
  }

  @override
  Future<Either<Failure, Cart>> saveForLater(String variantId) {
    savedForLaterCalls.add(variantId);
    return _change((cart) => saveLineForLater(cart, variantId));
  }

  @override
  Future<Either<Failure, Cart>> moveToCart(String variantId) {
    moveToCartCalls.add(variantId);
    return _change((cart) => moveSavedLineToCart(cart, variantId));
  }

  @override
  Future<Either<Failure, Cart>> removeSaved(String variantId) {
    removeSavedCalls.add(variantId);
    return _change((cart) => removeSavedLine(cart, variantId));
  }

  /// The products passed to each [checkStock] call.
  final List<List<CatalogProduct>> stockChecks = [];

  @override
  Future<Either<Failure, CartStockCheck>> checkStock(
    List<CatalogProduct> products,
  ) async {
    stockChecks.add(products);
    final failure = loadFailure ?? saveFailure;
    if (failure != null) return Left(failure);

    final check = checkCartStock(_cart, products);
    items = List.of(check.cart.items);
    savedForLater = List.of(check.cart.savedForLater);
    return Right(check);
  }

  Future<Either<Failure, Cart>> _change(Cart Function(Cart cart) change) async {
    final failure = saveFailure;
    if (failure != null) return Left(failure);

    final updated = change(_cart);
    items = List.of(updated.items);
    savedForLater = List.of(updated.savedForLater);
    return Right(_cart);
  }
}
```

### `test/helpers/fake_charge_rules_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/cart/domain/entities/charge_rules.dart';
import 'package:mymali/features/cart/domain/repositories/charge_rules_repository.dart';

/// The charge rules the cart page sees in a test.
const testChargeRules = ChargeRules(
  freeDeliveryThreshold: 199,
  smallCartThreshold: 199,
  smallCartCharge: 20,
  smallCartTiers: [
    SmallCartTier(under: 99, fee: 20),
    SmallCartTier(under: 149, fee: 15),
    SmallCartTier(under: 199, fee: 10),
  ],
);

/// In-memory [ChargeRulesRepository] for tests.
///
/// [rules] is what the server returns and [cached] what the device holds;
/// null means nothing. Set [remoteFailure] to make the server call fail.
class FakeChargeRulesRepository implements ChargeRulesRepository {
  FakeChargeRulesRepository({this.rules, this.cached});

  ChargeRules? rules;
  ChargeRules? cached;
  Failure? remoteFailure;

  int remoteCalls = 0;
  int cachedCalls = 0;

  @override
  Future<Either<Failure, ChargeRules>> getChargeRules() async {
    remoteCalls++;
    final failure = remoteFailure;
    if (failure != null) return Left(failure);
    final current = rules;
    return current == null
        ? Left(Failure(message: 'No rules'))
        : Right(current);
  }

  @override
  Future<Either<Failure, ChargeRules>> getCachedChargeRules() async {
    cachedCalls++;
    final saved = cached;
    return saved == null ? Left(CacheMissFailure()) : Right(saved);
  }
}
```

### `test/helpers/fake_checkout_repository.dart` (a fake that *prices* like the server)

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/cart/domain/utils/cart_charges.dart';
import 'package:mymali/features/checkout/domain/entities/checkout_quote.dart';
import 'package:mymali/features/checkout/domain/entities/collected_payment.dart';
import 'package:mymali/features/checkout/domain/entities/ko_order.dart';
import 'package:mymali/features/checkout/domain/entities/medusa_customer_identity.dart';
import 'package:mymali/features/checkout/domain/entities/order_record.dart';
import 'package:mymali/features/checkout/domain/entities/payment_method.dart';
import 'package:mymali/features/checkout/domain/entities/placed_order.dart';
import 'package:mymali/features/checkout/domain/entities/quote_request.dart';
import 'package:mymali/features/checkout/domain/entities/registered_order.dart';
import 'package:mymali/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:mymali/features/coupons/domain/entities/coupon.dart';

import 'fake_charge_rules_repository.dart';
import 'fake_coupon_repository.dart';

/// In-memory [CheckoutRepository] for tests: a stand-in for the server's
/// `checkout-quote`, pricing a cart the way that function does. Every
/// number here is test data.
///
/// [prices] are the server's unit prices by variant id. Coupons in
/// [coupons] apply when the cart meets their minimum; codes in
/// [rejectedCoupons] are always dropped. Coins: at most [redeemCap] of a
/// bill of at least [minOrderToRedeem], never more than [coinsAvailable].
/// Set [failure] to make every call fail, or [gate] to hold calls open.
class FakeCheckoutRepository implements CheckoutRepository {
  FakeCheckoutRepository({
    Map<String, double>? prices,
    this.coinsAvailable = 50,
    this.codCharge = 25,
  }) : prices = {...?prices};

  final Map<String, double> prices;
  int coinsAvailable;
  double codCharge;
  double minOrderToRedeem = 249;
  double redeemCap = 0.2;

  List<Coupon> coupons = const [welcome10, mali50];
  Set<String> rejectedCoupons = {};

  Failure? failure;
  Completer<void>? gate;

  /// Every request, in order.
  final List<QuoteRequest> requests = [];

  QuoteRequest get lastRequest => requests.last;

  @override
  Future<Either<Failure, CheckoutQuote>> getQuote(QuoteRequest request) async {
    requests.add(request);
    await gate?.future;
    final failure = this.failure;
    if (failure != null) return Left(failure);

    final subtotal = request.items.fold<double>(
      0,
      (sum, item) => sum + (prices[item.productId] ?? 0) * item.quantity,
    );
    final fee = smallCartFee(subtotal, testChargeRules);
    final cod = request.paymentMethod == PaymentMethod.cashOnDelivery
        ? codCharge
        : 0.0;

    Coupon? coupon;
    for (final candidate in coupons) {
      if (candidate.code == request.couponCode &&
          !rejectedCoupons.contains(candidate.code) &&
          subtotal >= candidate.minSubtotal) {
        coupon = candidate;
      }
    }
    final discount = (coupon?.discountFor(subtotal) ?? 0).toDouble();

    final beforeCoins = subtotal - discount + fee + cod;
    var coins = 0;
    if (request.redeemCoins && beforeCoins >= minOrderToRedeem) {
      final cap = (beforeCoins * redeemCap).floor();
      coins = coinsAvailable < cap ? coinsAvailable : cap;
    }

    return Right(
      CheckoutQuote(
        quoteId: 'quote_${requests.length}',
        subtotal: subtotal,
        discount: discount,
        couponCode: coupon?.code,
        smallCartCharge: fee,
        codCharge: cod,
        coinsRedeemed: coins,
        coinsAvailable: coinsAvailable,
        total: beforeCoins - coins,
        lines: [
          for (final item in request.items)
            QuoteLine(
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: prices[item.productId] ?? 0,
              lineTotal: (prices[item.productId] ?? 0) * item.quantity,
            ),
        ],
      ),
    );
  }

  /// Set to make every order fail, or [placeGate] to hold orders open.
  Failure? placeFailure;
  Completer<void>? placeGate;

  /// The `display_id` KO answers with.
  String displayId = '10345';

  /// Every order placed, in order.
  final List<KoOrder> placedOrders = [];

  @override
  Future<Either<Failure, PlacedOrder>> placeCodOrder(
    KoOrder order,
    CheckoutQuote quote,
  ) async {
    placedOrders.add(order);
    await placeGate?.future;
    final failure = placeFailure;
    if (failure != null) return Left(failure);
    return Right(PlacedOrder(displayId: displayId, quote: quote));
  }

  /// Set to make every registration fail, or [registerGate] to hold
  /// registrations open.
  Failure? registerFailure;
  Completer<void>? registerGate;

  /// The Razorpay order id and key KO answers with, and whether it calls
  /// the attempt a duplicate it had already found paid.
  String razorpayOrderId = 'order_01';
  String razorpayKeyId = 'rzp_test_key';
  bool registeredIsPaid = false;

  /// The order number `create-order` gives; empty, as it usually is.
  String registeredOrderId = '';

  /// Every order registered, in order.
  final List<KoOrder> registeredOrders = [];

  @override
  Future<Either<Failure, RegisteredOrder>> registerOnlineOrder(
    KoOrder order,
    CheckoutQuote quote,
  ) async {
    registeredOrders.add(order);
    await registerGate?.future;
    final failure = registerFailure;
    if (failure != null) return Left(failure);
    return Right(
      RegisteredOrder(
        razorpayOrderId: razorpayOrderId,
        orderId: registeredOrderId,
        keyId: razorpayKeyId,
        duplicate: registeredIsPaid,
        isPaid: registeredIsPaid,
        order: order,
        quote: quote,
      ),
    );
  }

  /// Set to make the sheet close without a payment, or [paymentGate] to
  /// hold the sheet open.
  Failure? paymentFailure;
  Completer<void>? paymentGate;

  /// The payment id the sheet reports.
  String paymentId = 'pay_01';

  /// Every sheet opened, in order: the order and who it was prefilled for.
  final List<({RegisteredOrder registered, String? contact, String? email})>
  payments = [];

  @override
  Future<Either<Failure, CollectedPayment>> collectPayment(
    RegisteredOrder registered, {
    String? contact,
    String? email,
  }) async {
    payments.add((registered: registered, contact: contact, email: email));
    await paymentGate?.future;
    final failure = paymentFailure;
    if (failure != null) return Left(failure);
    return Right(
      CollectedPayment(
        paymentId: paymentId,
        razorpayOrderId: registered.razorpayOrderId,
        signature: 'sig_01',
      ),
    );
  }

  /// Set to make every record fail.
  Failure? recordFailure;

  /// Every record saved, in order.
  final List<OrderRecord> records = [];

  @override
  Future<Either<Failure, Unit>> recordOrder(OrderRecord record) async {
    records.add(record);
    final failure = recordFailure;
    return failure == null ? const Right(unit) : Left(failure);
  }

  /// The Medusa customer id every lookup answers with; null for none.
  String? medusaCustomer = 'cus_01';

  /// Every identity looked up, in order.
  final List<MedusaCustomerIdentity> identities = [];

  @override
  Future<String?> medusaCustomerId(MedusaCustomerIdentity identity) async {
    identities.add(identity);
    return medusaCustomer;
  }
}
```

### `test/helpers/fake_coupon_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/coupons/domain/entities/applied_coupon.dart';
import 'package:mymali/features/coupons/domain/entities/coupon.dart';
import 'package:mymali/features/coupons/domain/failures/coupon_failures.dart';
import 'package:mymali/features/coupons/domain/repositories/coupon_repository.dart';
import 'package:mymali/features/coupons/domain/utils/coupon_validation.dart';

/// The two live coupons, as test data.
const Coupon welcome10 = Coupon(
  code: 'WELCOME10',
  type: CouponType.percentage,
  value: 10,
  minSubtotal: 199,
  description: '10% off your first order.',
);

const Coupon mali50 = Coupon(
  code: 'MALI50',
  type: CouponType.fixed,
  value: 50,
  minSubtotal: 299,
  description: 'Flat ₹50 off on orders above ₹299.',
);

/// In-memory [CouponRepository] for tests.
///
/// [coupons] is what the "server" holds; a check finds a code there and
/// runs the real validation at [now]. Set a `…Failure` to make that call
/// fail instead.
class FakeCouponRepository implements CouponRepository {
  FakeCouponRepository({
    List<Coupon> coupons = const [welcome10, mali50],
    DateTime? now,
  }) : coupons = [...coupons],
       now = now ?? DateTime.utc(2026, 10, 1);

  List<Coupon> coupons;
  DateTime now;

  Failure? listFailure;
  Failure? checkFailure;

  int listCalls = 0;
  int checkCalls = 0;

  /// The code of every check, as the bloc sent it.
  final List<String> checkedCodes = [];

  /// Completes a check only when completed, to hold it open.
  Completer<void>? gate;

  @override
  Future<Either<Failure, List<Coupon>>> getActiveCoupons({
    required bool refresh,
  }) async {
    listCalls++;
    final failure = listFailure;
    if (failure != null) return Left(failure);
    return Right(List.unmodifiable(coupons));
  }

  @override
  Future<Either<Failure, AppliedCoupon>> checkCoupon({
    required String code,
    required double subtotal,
  }) async {
    checkCalls++;
    checkedCodes.add(code);
    await gate?.future;
    final failure = checkFailure;
    if (failure != null) return Left(failure);
    final normalized = normalizeCouponCode(code);
    if (normalized.isEmpty) return Left(CouponCodeEmptyFailure());
    for (final coupon in coupons) {
      if (coupon.code == normalized) {
        return validateCoupon(coupon, subtotal, now);
      }
    }
    return Left(InvalidCouponFailure());
  }
}
```

### `test/helpers/fake_delivery_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/delivery/domain/entities/serviceable_pincode.dart';
import 'package:mymali/features/delivery/domain/repositories/delivery_repository.dart';

/// In-memory [DeliveryRepository] for tests: [rows] are the listed
/// pincodes. Set [failure] to make every lookup fail.
class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository({Map<String, ServiceablePincode>? rows})
    : rows = rows ?? {};

  final Map<String, ServiceablePincode> rows;
  Failure? failure;
  final List<String> lookups = [];

  @override
  Future<Either<Failure, Option<ServiceablePincode>>> findServiceablePincode(
    String pincode,
  ) async {
    lookups.add(pincode);
    final failure = this.failure;
    if (failure != null) return Left(failure);
    return Right(Option.fromNullable(rows[pincode]));
  }
}
```

### `test/helpers/fake_gstin_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/gstin/domain/entities/gstin.dart';
import 'package:mymali/features/gstin/domain/repositories/gstin_repository.dart';
import 'package:mymali/features/gstin/domain/utils/gstin_validation.dart';

/// A real, well-formed GSTIN, as test data.
const String validGstinNumber = '27AAPFU0939F1ZV';

const Gstin savedGstin = Gstin(
  number: validGstinNumber,
  stateName: 'Maharashtra',
);

/// In-memory [GstinRepository] for tests. A verify runs the real check and
/// records what was saved in [saved].
class FakeGstinRepository implements GstinRepository {
  /// Every GSTIN verified, with the user key it was saved for.
  final List<({String userKey, Gstin gstin})> saved = [];

  int verifyCalls = 0;

  /// Completes a verify only when completed, to hold it open.
  Completer<void>? gate;

  @override
  Future<Either<Failure, Gstin>> verifyGstin({
    required String userKey,
    required String number,
  }) async {
    verifyCalls++;
    await gate?.future;
    return validateGstin(number).map((gstin) {
      final verified = Gstin(number: gstin, stateName: gstinStateName(gstin));
      saved.add((userKey: userKey, gstin: verified));
      return verified;
    });
  }

  /// What the "server" holds for every user key, newest first.
  List<Gstin> savedGstins = [];

  /// Set to make listing the saved GSTINs fail.
  Failure? listFailure;

  final List<String> listedKeys = [];

  @override
  Future<Either<Failure, List<Gstin>>> getSavedGstins(String userKey) async {
    listedKeys.add(userKey);
    final failure = listFailure;
    return failure != null ? Left(failure) : Right(savedGstins);
  }
}
```

### `test/helpers/fake_location_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/location/domain/entities/place.dart';
import 'package:mymali/features/location/domain/failures/location_failures.dart';
import 'package:mymali/features/location/domain/repositories/location_repository.dart';

/// A place for tests, as the device's geocoder would describe it.
const testPlace = Place(
  area: 'Arera Colony',
  city: 'Bhopal',
  district: 'Bhopal',
  state: 'Madhya Pradesh',
  pincode: '462016',
  latitude: 23.2156,
  longitude: 77.4304,
);

/// In-memory [LocationRepository] for tests.
///
/// A search finds [searchResult], and the GPS finds [currentPlace]; each
/// fails with its `…Failure` when that is set. By default the search
/// matches nothing and the GPS is unavailable, so an app under test never
/// detects a place by itself. [selectedPlace] is what the device has
/// stored.
class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository({this.selectedPlace});

  Place? searchResult;
  Failure? searchFailure;

  Place? currentPlace;
  Failure? currentFailure;

  /// The place stored on the "device".
  Place? selectedPlace;
  Failure? saveFailure;

  final List<String> searches = [];
  int currentCalls = 0;
  int clearCalls = 0;

  /// Completes [searchPlace] only when completed, to hold a search open.
  Completer<void>? searchGate;

  /// Completes [getCurrentPlace] only when completed, to hold it open.
  Completer<void>? currentGate;

  @override
  Future<Either<Failure, Place>> searchPlace(String query) async {
    searches.add(query);
    await searchGate?.future;
    final result = searchResult;
    if (searchFailure != null) return Left(searchFailure!);
    return result == null ? Left(PlaceNotFoundFailure()) : Right(result);
  }

  @override
  Future<Either<Failure, Place>> getCurrentPlace() async {
    currentCalls++;
    await currentGate?.future;
    final place = currentPlace;
    if (currentFailure != null) return Left(currentFailure!);
    return place == null ? Left(LocationUnavailableFailure()) : Right(place);
  }

  @override
  Future<Either<Failure, Place?>> getSelectedPlace() async {
    return Right(selectedPlace);
  }

  @override
  Future<Either<Failure, Unit>> saveSelectedPlace(Place place) async {
    final failure = saveFailure;
    if (failure != null) return Left(failure);

    selectedPlace = place;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearSelectedPlace() async {
    clearCalls++;
    selectedPlace = null;
    return const Right(unit);
  }
}
```

### `test/helpers/fake_mali_coins_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/mali_coins/domain/entities/coin_balance.dart';
import 'package:mymali/features/mali_coins/domain/entities/coin_earn_way.dart';
import 'package:mymali/features/mali_coins/domain/entities/coin_ledger_entry.dart';
import 'package:mymali/features/mali_coins/domain/entities/coin_rules.dart';
import 'package:mymali/features/mali_coins/domain/entities/coin_welcome.dart';
import 'package:mymali/features/mali_coins/domain/repositories/mali_coins_repository.dart';

/// The rules a test server answers with. Every number here is test data,
/// standing in for the server's `coin_rules` row.
const CoinRules testCoinRules = CoinRules(
  earnRate: 0.05,
  redeemCap: 0.2,
  minOrderToRedeem: 249,
  expiryMonths: 6,
  welcomeCoins: 50,
  referralReward: 100,
  referralBonus: 100,
  earnWays: [
    CoinEarnWay(
      key: 'order_earn',
      icon: 'shoppingBag',
      title: 'Shop products',
      description: 'Earn 5% back in coins when your order is delivered',
      coins: '+5%',
    ),
    CoinEarnWay(
      key: 'welcome',
      icon: 'gift',
      title: 'Welcome gift',
      description: 'Credited once when you first sign in',
      coins: '+50',
    ),
    CoinEarnWay(
      key: 'referral',
      icon: 'users',
      title: 'Refer a friend',
      description: "Credited when your friend's first order is delivered",
      coins: '+100',
    ),
  ],
);

/// A ledger with one welcome gift, as a new user's looks.
final CoinBalance testCoinBalance = CoinBalance(
  balance: 50,
  expiringNext: CoinExpiry(amount: 50, at: DateTime.utc(2027, 3, 29)),
  history: [
    CoinLedgerEntry(
      delta: 50,
      reason: 'welcome',
      createdAt: DateTime.utc(2026, 9, 29, 10),
    ),
  ],
);

/// In-memory [MaliCoinsRepository] for tests.
///
/// [balance] is what the "server" answers, [cachedBalance] what the device
/// has saved (null is a miss), [rules] what the server's rules are. Set a
/// `…Failure` to make that call fail.
class FakeMaliCoinsRepository implements MaliCoinsRepository {
  FakeMaliCoinsRepository({CoinBalance? balance, this.rules = testCoinRules})
    : balance = balance ?? testCoinBalance;

  CoinBalance balance;
  CoinRules? rules;

  /// What the device has saved; null is a cache miss.
  int? cachedBalance;

  /// Whether the next welcome claim is the first one.
  bool welcomed = false;

  Failure? welcomeFailure;
  Failure? balanceFailure;
  Failure? rulesFailure;

  int welcomeCalls = 0;
  int balanceCalls = 0;
  int rulesCalls = 0;

  /// The `refresh` flag of every rules call, in order.
  final List<bool> rulesRefreshes = [];

  /// Completes the balance call only when completed, to hold a load open.
  Completer<void>? gate;

  @override
  Future<Either<Failure, CoinWelcome>> claimWelcome() async {
    welcomeCalls++;
    final failure = welcomeFailure;
    if (failure != null) return Left(failure);
    cachedBalance = balance.balance;
    return Right(CoinWelcome(balance: balance.balance, welcomed: welcomed));
  }

  @override
  Future<Either<Failure, CoinBalance>> getBalance() async {
    balanceCalls++;
    await gate?.future;
    final failure = balanceFailure;
    if (failure != null) return Left(failure);
    cachedBalance = balance.balance;
    return Right(balance);
  }

  @override
  Future<Either<Failure, int>> getCachedBalance() async {
    final cached = cachedBalance;
    return cached == null ? Left(CacheMissFailure()) : Right(cached);
  }

  @override
  Future<Either<Failure, CoinRules>> getRules({required bool refresh}) async {
    rulesCalls++;
    rulesRefreshes.add(refresh);
    final failure = rulesFailure;
    if (failure != null) return Left(failure);
    final rules = this.rules;
    if (rules == null) return Left(ServerFailure(errorCode: 'NOT_CONFIGURED'));
    return Right(rules);
  }
}
```

### `test/helpers/fake_notifications_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/notifications/domain/entities/app_notification.dart';
import 'package:mymali/features/notifications/domain/repositories/notifications_repository.dart';

AppNotification notificationNamed(
  String id, {
  bool isRead = false,
  NotificationCategory category = NotificationCategory.order,
  DateTime? createdAt,
}) => AppNotification(
  id: id,
  title: 'Title $id',
  body: 'Body $id',
  category: category,
  createdAt: createdAt ?? DateTime.now().toUtc(),
  isRead: isRead,
);

/// In-memory [NotificationsRepository] for tests.
class FakeNotificationsRepository implements NotificationsRepository {
  /// What the "server" holds, newest first.
  List<AppNotification> notifications = [];

  /// Set to make loading fail.
  Failure? listFailure;

  /// Set to make marking read fail.
  Failure? markFailure;

  /// Completes a load only when completed, to hold it open.
  Completer<void>? gate;

  int listCalls = 0;

  /// Every list of ids sent to be marked read.
  final List<List<String>> markedRead = [];

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    listCalls++;
    await gate?.future;
    final failure = listFailure;
    return failure != null ? Left(failure) : Right(notifications);
  }

  @override
  Future<Either<Failure, Unit>> markRead(List<String> ids) async {
    markedRead.add(ids);
    final failure = markFailure;
    return failure != null ? Left(failure) : const Right(unit);
  }
}
```

### `test/helpers/fake_orders_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/orders/domain/entities/orders_page.dart';
import 'package:mymali/features/orders/domain/entities/ref_order_lookup.dart';
import 'package:mymali/features/orders/domain/entities/warehouse_order.dart';
import 'package:mymali/features/orders/domain/repositories/orders_repository.dart';

/// In-memory [OrdersRepository] for tests: a stand-in for the warehouse.
/// [found] is what the poll answers with once [findCallsBeforeMatch] polls
/// have gone by; [byId] answers the single lookup. Set [failure] to make
/// every call fail; [pages] serves My Orders.
class FakeOrdersRepository implements OrdersRepository {
  WarehouseOrder? found;
  WarehouseOrder? byId;
  int findCallsBeforeMatch = 0;

  /// My Orders' pages, in order: page 1 first. A page past the end is
  /// empty.
  List<List<WarehouseOrder>> pages = const [];
  Failure? failure;

  /// Every poll, in order: the phone and the time asked about.
  final List<({String phone, DateTime placedAt})> finds = [];

  /// Every single lookup, in order: the phone and the order number.
  final List<({String phone, String orderId})> gets = [];

  /// Every page asked for, in order: the phone and the page number.
  final List<({String phone, int page})> pageCalls = [];

  @override
  Future<Either<Failure, WarehouseOrder?>> findOrderPlacedAfter({
    required String phone,
    required DateTime placedAt,
  }) async {
    finds.add((phone: phone, placedAt: placedAt));
    final failure = this.failure;
    if (failure != null) return Left(failure);
    return Right(finds.length > findCallsBeforeMatch ? found : null);
  }

  @override
  Future<Either<Failure, WarehouseOrder?>> getOrder({
    required String phone,
    required String orderId,
  }) async {
    gets.add((phone: phone, orderId: orderId));
    final failure = this.failure;
    if (failure != null) return Left(failure);
    return Right(byId);
  }

  /// KO's record by ref id; a ref id not listed is unknown to KO. It is
  /// answered only once [refCallsBeforeMatch] lookups have gone by;
  /// before that KO has no record.
  final Map<String, RefOrderLookup> refOrders = {};
  int refCallsBeforeMatch = 0;

  /// Every ref-order lookup, in order.
  final List<String> refLookups = [];

  @override
  Future<Either<Failure, RefOrderLookup?>> getRefOrder({
    required String refId,
  }) async {
    refLookups.add(refId);
    final failure = this.failure;
    if (failure != null) return Left(failure);
    return Right(
      refLookups.length > refCallsBeforeMatch ? refOrders[refId] : null,
    );
  }

  @override
  Future<Either<Failure, OrdersPage>> getOrders({
    required String phone,
    int page = 1,
  }) async {
    pageCalls.add((phone: phone, page: page));
    final failure = this.failure;
    if (failure != null) return Left(failure);
    final orders = page <= pages.length ? pages[page - 1] : <WarehouseOrder>[];
    return Right(
      OrdersPage(orders: orders, page: page, hasMore: page < pages.length),
    );
  }
}
```

### `test/helpers/fake_product_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/catalog/domain/entities/product_variant.dart';
import 'package:mymali/features/product/domain/entities/product_category.dart';
import 'package:mymali/features/product/domain/entities/product_detail.dart';
import 'package:mymali/features/product/domain/entities/product_review.dart';
import 'package:mymali/features/product/domain/entities/product_spec.dart';
import 'package:mymali/features/product/domain/entities/review_draft.dart';
import 'package:mymali/features/product/domain/repositories/product_repository.dart';

import 'fake_catalog_repository.dart';

/// A second, bigger pack of [testDetail].
const testLargeVariant = ProductVariant(
  id: 'variant_02',
  sku: 'MM-NEEM-1L',
  label: '1 l',
  price: 799,
  mrp: 999,
  stock: 3,
);

/// The catalog's [testProduct] as its product page shows it.
const testDetail = ProductDetail(
  id: 'prod_01',
  title: 'Activated Neem Oil',
  handle: 'activated-neem-oil',
  description: 'Cold-pressed neem oil for leaves and soil.',
  thumbnail: 'https://cdn.example.com/neem.jpg',
  imageUrls: [
    'https://cdn.example.com/neem.jpg',
    'https://cdn.example.com/neem-2.jpg',
  ],
  status: 'published',
  variants: [testVariant, testLargeVariant],
  categories: [ProductCategory(id: 'pcat_01', name: 'Liquid Tonics')],
  collectionTitle: 'Plant Care',
  sowingGuide: '1. Shake well. 2. Mix 5 ml in a litre of water.',
  specs: [ProductSpec(key: ProductSpec.sunlight, value: 'Full sun')],
);

final testReview = ProductReview(
  id: 'review_01',
  rating: 5,
  productId: testVariant.id,
  sku: testVariant.sku,
  userName: 'Ravi',
  userId: 'user_01',
  body: 'Works well.',
  createdAt: DateTime.utc(2026, 9, 30),
);

/// In-memory [ProductRepository] for tests.
///
/// [product] is what the server returns and [cached] what the device holds
/// (null = a miss). Set a `…Failure` to make that call fail, and [gate] to
/// hold [getProduct] open until it completes.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({this.product = testDetail, this.cached});

  ProductDetail product;
  ProductDetail? cached;
  List<ProductReview> reviews = [testReview];

  Failure? productFailure;
  Failure? reviewsFailure;
  Failure? writeFailure;
  Completer<void>? gate;

  int productCalls = 0;
  final List<String> reviewCallsForVariant = [];
  final List<NewReview> submitted = [];
  final List<ReviewEdit> edits = [];
  final List<String> deleted = [];

  @override
  Future<Either<Failure, ProductDetail>> getProduct(String productId) async {
    productCalls++;
    await gate?.future;
    final failure = productFailure;
    return failure == null ? Right(product) : Left(failure);
  }

  @override
  Future<Either<Failure, ProductDetail>> getCachedProduct(
    String productId,
  ) async {
    final saved = cached;
    return saved == null ? Left(CacheMissFailure()) : Right(saved);
  }

  @override
  Future<Either<Failure, List<ProductReview>>> getReviews({
    required String variantId,
    required String sku,
  }) async {
    reviewCallsForVariant.add(variantId);
    final failure = reviewsFailure;
    return failure == null ? Right(List.of(reviews)) : Left(failure);
  }

  @override
  Future<Either<Failure, Unit>> submitReview(NewReview review) async {
    submitted.add(review);
    return _write();
  }

  @override
  Future<Either<Failure, Unit>> updateReview(ReviewEdit edit) async {
    edits.add(edit);
    return _write();
  }

  @override
  Future<Either<Failure, Unit>> deleteReview(String reviewId) async {
    deleted.add(reviewId);
    return _write();
  }

  Either<Failure, Unit> _write() {
    final failure = writeFailure;
    return failure == null ? const Right(unit) : Left(failure);
  }
}

/// [testDetail] with none of its one pack left.
const testDetailSoldOut = ProductDetail(
  id: 'prod_01',
  title: 'Activated Neem Oil',
  handle: 'activated-neem-oil',
  variants: [
    ProductVariant(
      id: 'variant_01',
      sku: 'MM-NEEM-250',
      label: '250 ml',
      price: 269,
      mrp: 595,
      stock: 0,
    ),
  ],
  categories: [ProductCategory(id: 'pcat_01', name: 'Liquid Tonics')],
);
```

### `test/helpers/fake_profile_repository.dart`

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/profile/domain/entities/profile_update.dart';
import 'package:mymali/features/profile/domain/entities/user_profile.dart';
import 'package:mymali/features/profile/domain/repositories/profile_repository.dart';

/// In-memory [ProfileRepository] for tests.
///
/// [profile] is what the "server" holds (null: no row yet), [avatars] the
/// photos "on the device" by user id, and [picked] what the next photo
/// pick returns (null: the user cancelled). Set a `…Failure` to make that
/// call fail.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile});

  UserProfile? profile;
  final Map<String, Uint8List> avatars = {};
  Uint8List? picked;

  Failure? getFailure;
  Failure? saveFailure;
  Failure? pickFailure;

  final List<ProfileUpdate> saved = [];
  final List<String> fetchedKeys = [];

  /// Completes the save only when completed, to hold it open.
  Completer<void>? saveGate;

  @override
  Future<Either<Failure, UserProfile?>> getProfile(String userKey) async {
    fetchedKeys.add(userKey);
    final failure = getFailure;
    return failure != null ? Left(failure) : Right(profile);
  }

  @override
  Future<Either<Failure, Unit>> saveProfile(ProfileUpdate update) async {
    await saveGate?.future;
    final failure = saveFailure;
    if (failure != null) return Left(failure);
    saved.add(update);
    profile = update.profile;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Uint8List?>> loadAvatar(String userId) async {
    return Right(avatars[userId]);
  }

  @override
  Future<Either<Failure, Option<Uint8List>>> pickAvatar(String userId) async {
    final failure = pickFailure;
    if (failure != null) return Left(failure);
    final bytes = picked;
    if (bytes == null) return const Right(None());
    avatars[userId] = bytes;
    return Right(Some(bytes));
  }
}
```

### `test/helpers/fake_referral_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/referral/domain/entities/referral_claim.dart';
import 'package:mymali/features/referral/domain/entities/referral_summary.dart';
import 'package:mymali/features/referral/domain/repositories/referral_repository.dart';

/// A new user's summary. Every number here is test data, standing in for
/// the server's answer.
const ReferralSummary testReferralSummary = ReferralSummary(
  code: 'EE3W6A',
  reward: 100,
  bonus: 100,
  joined: 3,
  credited: 1,
  pending: 2,
  coinsEarned: 100,
);

/// In-memory [ReferralRepository] for tests.
///
/// [summary] is what the "server" answers; a claim of [validCode] succeeds
/// with [claim] and records the code on the summary. Set a `…Failure` to
/// make that call fail.
class FakeReferralRepository implements ReferralRepository {
  FakeReferralRepository({this.summary = testReferralSummary});

  ReferralSummary summary;
  String validCode = 'FRIEND1';
  ReferralClaim claim = const ReferralClaim(bonus: 100, balance: 150);

  Failure? summaryFailure;
  Failure? claimFailure;

  int summaryCalls = 0;
  final List<String> claimedCodes = [];

  /// Completes the summary call only when completed, to hold a load open.
  Completer<void>? gate;

  @override
  Future<Either<Failure, ReferralSummary>> getSummary() async {
    summaryCalls++;
    await gate?.future;
    final failure = summaryFailure;
    return failure != null ? Left(failure) : Right(summary);
  }

  @override
  Future<Either<Failure, ReferralClaim>> claimCode(String code) async {
    claimedCodes.add(code);
    final failure = claimFailure;
    if (failure != null) return Left(failure);
    summary = ReferralSummary(
      code: summary.code,
      reward: summary.reward,
      bonus: summary.bonus,
      claimedCode: code,
      joined: summary.joined,
      credited: summary.credited,
      pending: summary.pending,
      coinsEarned: summary.coinsEarned,
    );
    return Right(claim);
  }
}
```

### `test/helpers/fake_seller_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/invoice/domain/entities/seller_identity.dart';
import 'package:mymali/features/invoice/domain/repositories/seller_repository.dart';

/// The seller the "server" answers with. Test data.
const testSeller = SellerIdentity(
  legalName: 'Katyayani Organics',
  addressLines: ['Plot 12, Industrial Area', 'Bhopal, Madhya Pradesh'],
  phone: '+91 755 400 0000',
  gstin: '23ABCDE1234F1Z5',
  gstRate: 18,
);

/// [seller] is what the server answers, [cachedSeller] what the device
/// holds (null = a miss). Set [failure] to make the server call fail.
class FakeSellerRepository implements SellerRepository {
  FakeSellerRepository({this.seller = testSeller, this.cachedSeller});

  SellerIdentity seller;
  SellerIdentity? cachedSeller;
  Failure? failure;
  int calls = 0;

  @override
  Future<Either<Failure, SellerIdentity>> getSeller() async {
    calls++;
    final error = failure;
    return error == null ? Right(seller) : Left(error);
  }

  @override
  Future<Either<Failure, SellerIdentity>> getCachedSeller() async {
    final saved = cachedSeller;
    return saved == null ? Left(CacheMissFailure()) : Right(saved);
  }
}
```

### `test/helpers/fake_support_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/support/domain/entities/support_content.dart';
import 'package:mymali/features/support/domain/repositories/support_repository.dart';

/// The content the "server" answers with. Test data.
const testSupportContent = SupportContent(
  intro: 'Questions about an order, a plant or your account?',
  channels: [
    SupportChannel(
      kind: SupportChannelKind.email,
      label: 'General',
      value: 'support@example.com',
      url: 'mailto:support@example.com',
    ),
    SupportChannel(
      kind: SupportChannelKind.phone,
      label: 'Phone',
      value: '+91 90000 00000',
      url: 'tel:+919000000000',
    ),
    SupportChannel(
      kind: SupportChannelKind.whatsapp,
      label: 'WhatsApp',
      value: 'Chat with us',
      url: 'https://wa.me/919000000000',
    ),
  ],
  faqs: [
    SupportFaq(
      question: 'How soon will I get a reply?',
      answer: 'Within one business day.',
    ),
    SupportFaq(
      question: 'Where is my order?',
      answer: 'You will get a tracking link once it ships.',
    ),
  ],
);

/// [content] is what the server answers, [cachedContent] what the device
/// holds (null = a miss). Set [failure] to make the server call fail, and
/// [gate] to hold the server's answer until it completes.
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    this.content = testSupportContent,
    this.cachedContent,
  });

  SupportContent content;
  SupportContent? cachedContent;
  Failure? failure;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<Either<Failure, SupportContent>> getSupportContent() async {
    calls++;
    await gate?.future;
    final error = failure;
    return error == null ? Right(content) : Left(error);
  }

  @override
  Future<Either<Failure, SupportContent>> getCachedSupportContent() async {
    final saved = cachedContent;
    return saved == null ? Left(CacheMissFailure()) : Right(saved);
  }
}
```

### `test/helpers/fake_wishlist_repository.dart`

```dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mymali/core/app/failure.dart';
import 'package:mymali/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:mymali/features/wishlist/domain/repositories/wishlist_repository.dart';

/// In-memory [WishlistRepository] for tests.
///
/// [ids] is the wishlist a sync returns, newest first, and can be preset;
/// a heart tap changes it too. [loadWishlist] returns [cachedIds], the
/// device's copy, which is empty until set. Set a `…Failure` to make that
/// call fail.
class FakeWishlistRepository implements WishlistRepository {
  FakeWishlistRepository({List<String> ids = const []}) : ids = List.of(ids);

  List<String> ids;

  /// What the device holds; null reads as an empty wishlist.
  List<String>? cachedIds;

  /// Fails [syncWishlist].
  Failure? loadFailure;
  Failure? addFailure;
  Failure? removeFailure;
  Failure? pushFailure;

  /// How many times [syncWishlist] ran.
  int loadCalls = 0;
  final List<String> added = [];
  final List<String> removed = [];

  /// The user of every [pushWishlist], in order.
  final List<String> pushes = [];

  /// The user of the last call.
  String? lastUserId;

  /// Completes [syncWishlist] only when completed, to hold a sync open.
  Completer<void>? gate;

  /// Completes the add and remove calls only when completed, to hold a
  /// toggle open.
  Completer<void>? toggleGate;

  @override
  Future<Either<Failure, List<WishlistItem>>> loadWishlist(
    String userId,
  ) async {
    lastUserId = userId;
    return Right(_items(cachedIds ?? const []));
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> syncWishlist(
    String userId,
  ) async {
    lastUserId = userId;
    loadCalls++;
    await gate?.future;
    final failure = loadFailure;
    return failure == null ? Right(_items(ids)) : Left(failure);
  }

  @override
  Future<Either<Failure, Unit>> pushWishlist(String userId) async {
    pushes.add(userId);
    final failure = pushFailure;
    return failure == null ? const Right(unit) : Left(failure);
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> addToWishlist(
    String userId,
    String productId,
  ) async {
    lastUserId = userId;
    added.add(productId);
    await toggleGate?.future;
    final failure = addFailure;
    if (failure != null) return Left(failure);

    ids = [productId, ...ids.where((id) => id != productId)];
    return Right(_items(ids));
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> removeFromWishlist(
    String userId,
    String productId,
  ) async {
    lastUserId = userId;
    removed.add(productId);
    await toggleGate?.future;
    final failure = removeFailure;
    if (failure != null) return Left(failure);

    ids = ids.where((id) => id != productId).toList();
    return Right(_items(ids));
  }

  static List<WishlistItem> _items(List<String> ids) => [
    for (final id in ids) WishlistItem(productId: id),
  ];
}
```

### The seven helpers other inventories already quote (repeated so this section is the complete `test/helpers/`)

`test/helpers/fake_auth_repository.dart` (ALWAYS as the template of a fake; body CONDITIONAL(phone-OTP auth)):

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

`test/helpers/fake_catalog_repository.dart` (the cache-first fake template):

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

`test/helpers/fake_ko_engagement_service.dart` (CONDITIONAL(engagement/analytics); the shape — one recording fake plus one `register…()` that satisfies every `sl<…>()` `App` performs — is ALWAYS):

```dart
import 'package:flutter/widgets.dart';
import 'package:mymali/core/di/injection_container.dart';
import 'package:mymali/core/services/analytics/analytics_item.dart';
import 'package:mymali/core/services/analytics/analytics_service.dart';
import 'package:mymali/core/services/analytics/ko_analytics_service.dart';
import 'package:mymali/core/services/katyayani_core/ko_engagement_service.dart';

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

`test/helpers/fake_local_cache.dart` (CONDITIONAL(cache)):

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

`test/helpers/fake_networking.dart` (ALWAYS):

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

`test/helpers/fake_payment_gateway.dart` (CONDITIONAL(payments)):

```dart
import 'dart:async';

import 'package:mymali/core/services/payments/payment_gateway.dart';

/// In-memory [PaymentGateway] for tests: the sheet reports [payment], or
/// throws [error] when set; [gate] holds the sheet open. Every opening is
/// recorded in [checkouts].
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

`test/helpers/fake_secure_storage.dart` (CONDITIONAL(tokens)):

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

### The shape every fake repository shares (derived from the 20 above)

| element | spelling in the fakes | examples |
|---|---|---|
| class | `class Fake<Interface> implements <Interface>` | all 20 |
| constructor | named, defaulted, copies lists (`: items = List.of(items)`) | `FakeCartRepository({List<CartItem> items = const [], List<CartItem> savedForLater = const []})`, `FakeCouponRepository({List<Coupon> coupons = const [welcome10, mali50], DateTime? now})`, `FakeMaliCoinsRepository({CoinBalance? balance, this.rules = testCoinRules})`, `FakeWishlistRepository({List<String> ids = const []})`, `FakeLocationRepository({this.selectedPlace})`, `FakeProfileRepository({this.profile})`, `FakeReferralRepository({this.summary = testReferralSummary})`, `FakeAccountRepository({this.version = const AppVersion(version: '1.0.1', buildNumber: '9')})`, `FakeCheckoutRepository({Map<String, double>? prices, this.coinsAvailable = 50, this.codCharge = 25})`, `FakeSellerRepository({this.seller = testSeller, this.cachedSeller})`, `FakeSupportRepository({this.content = testSupportContent, this.cachedContent})`, `FakeProductRepository({this.product = testDetail, this.cached})`, `FakeChargeRulesRepository({this.rules, this.cached})`, `FakeDeliveryRepository({Map<String, ServiceablePincode>? rows})`, `FakeAddressRepository({List<SavedAddress> addresses = const []})`; no constructor at all: `FakeAppConfigRepository`, `FakeCatalogRepository`, `FakeGstinRepository`, `FakeNotificationsRepository`, `FakeOrdersRepository` |
| one failure switch per failable call | `Failure? <call>Failure` (`loadFailure`, `saveFailure`, `syncFailure`, `pushFailure`, `listFailure`, `checkFailure`, `summaryFailure`, `claimFailure`, `getFailure`, `pickFailure`, `welcomeFailure`, `balanceFailure`, `rulesFailure`, `appStateFailure`, `remoteFailure`, `recordFailure`, `placeFailure`, `registerFailure`, `paymentFailure`, `productFailure`, `reviewsFailure`, `writeFailure`, `markFailure`, `searchFailure`, `currentFailure`, `removeFailure`, `addFailure`); a single `Failure? failure` when every call fails together (`FakeOrdersRepository`, `FakeDeliveryRepository`, `FakeSellerRepository`, `FakeSupportRepository`, `FakeCheckoutRepository.getQuote`) | — |
| gate | `Completer<void>? gate;` awaited as `await gate?.future;` as the **first** statement after recording; a second gate when two calls must be held separately: `syncGate`, `changeGate`, `toggleGate`, `saveGate`, `searchGate`, `currentGate`, `placeGate`, `registerGate`, `paymentGate`, `fetchGate` | — |
| recorders | `int <call>Calls = 0;` or `final List<X> <pastParticiple> = [];` (`saved`, `removed`, `added`, `pushes`, `requests`, `records`, `identities`, `payments`, `registrations`, `finds`, `gets`, `pageCalls`, `refLookups`, `checkedCodes`, `claimedCodes`, `listedKeys`, `fetchedKeys`, `lookups`, `markedRead`, `stockChecks`, `submitted`, `edits`, `deleted`); records as Dart records `List<({String phone, DateTime placedAt})>` | — |
| cache-first pair | `X? cached<X>` (null = miss) answered by `getCached<X>()` → `Left(CacheMissFailure())` | `cachedAddresses`, `cachedBalance`, `cachedCatalog`, `cachedSections`, `cachedSoldCounts`, `cachedLowStockThresholds`, `cached` (product, charge rules), `cachedSeller`, `cachedContent`, `cachedIds` |
| realism | re-use the real domain helpers so the fake behaves like the repository | `mergeServerLines`/`changedVariants` (cart sync), `checkCartStock`, `saveLineForLater`/`moveSavedLineToCart`/`removeSavedLine`, `normalizeCouponCode`/`validateCoupon`, `validateGstin`/`gstinStateName`, `smallCartFee`, `Coupon.discountFor`, `withSavedAddress`/`withoutAddress` |
| test data | top-level `const`/`final` named `test<Thing>` (or a domain name: `welcome10`, `mali50`, `validGstinNumber`, `savedGstin`) and factory functions (`notificationNamed`) | — |
| "not configured" | `ServerFailure(errorCode: 'NOT_CONFIGURED')` when the fake's rules are null | `FakeMaliCoinsRepository.getRules` |
| private helpers | `_cached<T>`, `_change`, `_write`, `_items`, `_cart` | — |

---

## Follow-up: self-declared partial reads

Every file an inventory marked "(excerpt)", "(head)", "(first 45 lines)" or
"consulted by grep only" was read **in full** for this section. The table names
the inventory whose description is authoritative for each file and what the full
read adds; the smaller files that carry a reusable pattern follow verbatim, the
pages are given as their exact public surface plus a listener/key table, and
each test file is summarised with the exact helper shapes it contributes.

| file | lines | previously | authoritative description | what the full read adds (below) |
|---|---|---|---|---|
| `lib/features/wishlist/presentation/bloc/wishlist_bloc.dart` | 322 | analytics-engagement-platform.md:67 "(excerpt)"; data-strategies.md 3.F.3 "the device-first parts" | **this file** (complete); data-strategies.md 3.F.3 for the device-first commentary; presentation-bloc-pages.md:41 for the §20 role | the complete class |
| `lib/features/orders/data/datasources/ref_order_remote_data_source.dart` | 86 | analytics-engagement-platform.md:68 "(excerpt)" | networking.md:35/:112 (role, ctor) + **this file** (complete) | `_get` / `_send`, the 401 retry only when a token was sent |
| `lib/features/checkout/data/datasources/ko_order_remote_data_source.dart` | 226 | analytics-engagement-platform.md:68 "(excerpt)"; networking.md:2054 (excerpt) | networking.md:36/:113 + **this file** (complete) | `isPaymentCaptured`, `_postWithToken`, `_post`, `_toServerException`, `_detailOf`, `_codeOf`, `_read` |
| `lib/features/gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart` | 158 | di-bootstrap-app.md:88 "(first 45 lines)" | presentation-bloc-pages.md:126/:348 (role, signature) + **this file** (complete) | `_GstinSheet` body (the `BlocListener` that pops the sheet after `gstinSheetCloseDelay`), `_formatters`, `_VerifiedLine`, keys |
| `lib/features/cart/presentation/cart/pages/cart_page.dart` | 295 | analytics-engagement-platform.md:67 "(excerpt)" | di-bootstrap-app.md §3.14 (1114) for the create/forward pattern + **this file** (complete) | 6 listeners, `_CartViewState._reportOpened`, `_hasContent`, keys |
| `lib/features/home/presentation/home/pages/home_page.dart` | 216 | "(excerpt)" | presentation-bloc-pages.md:53 (role; `class HomePage` verbatim at 957), di-bootstrap-app.md:84 (1056) + **this file** (complete) | `_HomeView._onBannerTap` switch over `bannerTargetFor`, `_HomeFailure`, `_EmptyHome` |
| `lib/features/product/presentation/product_detail/pages/product_detail_page.dart` | 362 | "(excerpt)" | presentation-bloc-pages.md:124/:345; router-navigation.md:36/:95 (`idParam`, `open`; `class ProductDetailPage` verbatim at 763) | surface + listener table below |
| `lib/features/checkout/presentation/order_placed/pages/order_placed_page.dart` | 426 | "(excerpt)" | presentation-bloc-pages.md:125/:347; router-navigation.md:39/:103 | surface + `_reportPurchase` de-duplication below |
| `lib/features/checkout/presentation/review_pay/pages/review_pay_page.dart` | 593 | "(excerpt)" | presentation-bloc-pages.md:73 (12 listeners) and :282; router-navigation.md:40 | surface + the 12-listener table below |
| `lib/core/router/app_router.dart` | 278 | analytics-engagement-platform.md:45 "(excerpt relevant here)" | router-navigation.md §3.1 (364–615), **verified complete**: 5 `StatefulShellBranch`, 24 `GoRoute`, both `redirect` guards, `key: state.pageKey` on `productDetail` and `orderDetails` | nothing missing; import list below |
| `test/features/checkout/data/repositories/checkout_repository_impl_test.dart` | 922 | tests-tooling-config.md:75 "(head)" | **this file** | four private fakes verbatim; constructor injection of `now`/`wait`/`newRequestId`; group list |
| `test/features/product/presentation/product_detail/pages/product_detail_page_test.dart` | 491 | tests-tooling-config.md:76 "(head)" | **this file** | hand-rolled `setUp` verbatim; the test list |
| `test/features/checkout/presentation/order_placed/bloc/order_placed_bloc_test.dart` | 508 | tests-tooling-config.md:77 "(head)" | **this file** | `OrderPlacedBloc` constructor; poll cadence facts |
| `test/features/invoice/presentation/invoice/pages/invoice_page_test.dart` | 169 | tests-tooling-config.md:78 "(head)" | **this file** | channel mocks verbatim; `tester.runAsync` polling for the shared file |
| `test/features/referral/presentation/refer/pages/referral_page_test.dart` | 181 | tests-tooling-config.md:79 "(head)" | **this file** | `openReferral(settle:)`; `tracked(name)` helper; analytics asserts |
| `test/core/services/analytics/meta_analytics_destination_test.dart` | 73 | tests-tooling-config.md:80 "(head)" | **this file** | `channelName`, `settle()`, the four tests |
| `test/core/services/payments/razorpay_payment_gateway_test.dart` | 147 | tests-tooling-config.md:81 "(head)" | "Follow-up: RazorpayPaymentGateway…" above | — |
| `test/features/home/presentation/home/pages/home_page_test.dart` | 475 | data-strategies.md:144 "consulted by grep only" | **this file** | `setUp` registration list; the 20 tests by group |
| `test/features/wishlist/presentation/pages/wishlist_page_test.dart` | 470 | data-strategies.md:144 "consulted by grep only" | **this file** | `setUp`; `bloc(tester)`, `isHeartOn`, `wishlistBadge`, `saveOnDevice()`; the 22 tests |

### `lib/features/wishlist/presentation/bloc/wishlist_bloc.dart`, complete (CONDITIONAL template: app-wide, user-scoped, device-first bloc)

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/app/failure.dart';
import '../../../../core/services/analytics/analytics_service.dart';
import '../../../../core/services/analytics/app_events.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../catalog/domain/entities/catalog_snapshot.dart';
import '../../../catalog/domain/usecases/get_cached_catalog.dart';
import '../../../catalog/domain/usecases/get_catalog.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/failures/wishlist_failures.dart';
import '../../domain/usecases/add_to_wishlist.dart';
import '../../domain/usecases/load_wishlist.dart';
import '../../domain/usecases/push_wishlist.dart';
import '../../domain/usecases/remove_from_wishlist.dart';
import '../../domain/usecases/sync_wishlist.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

export 'wishlist_event.dart';
export 'wishlist_state.dart';

/// Owns the app-wide wishlist: which products the signed-in user saved.
/// Product cards on any screen read a single bool from it and toggle
/// through [WishlistToggled]; the wishlist page shows the saved products.
///
/// The server keeps only product ids, so the bloc also holds the catalog
/// and looks the products up in it.
///
/// The wishlist lives on the device, as the cart does. On sign-in the
/// device's copy shows at once, then a sync with the server replaces it. A
/// sync that fails keeps the wishlist on screen and only sets
/// [WishlistState.failure]. A toggle is saved on the device, shows at once
/// and is then sent to the server without waiting; a send that fails is
/// retried by the next send or sync. A toggle is undone only when the
/// device refuses it (the wishlist is full, or storage failed).
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc({
    required LoadWishlist loadWishlist,
    required SyncWishlist syncWishlist,
    required PushWishlist pushWishlist,
    required AddToWishlist addToWishlist,
    required RemoveFromWishlist removeFromWishlist,
    required GetCatalog getCatalog,
    required GetCachedCatalog getCachedCatalog,
    AnalyticsService? analytics,
  }) : _loadWishlist = loadWishlist,
       _syncWishlist = syncWishlist,
       _pushWishlist = pushWishlist,
       _addToWishlist = addToWishlist,
       _removeFromWishlist = removeFromWishlist,
       _getCatalog = getCatalog,
       _getCachedCatalog = getCachedCatalog,
       _analytics = analytics,
       super(WishlistState()) {
    on<WishlistStarted>(_onStarted);
    on<WishlistRefreshed>(_onRefreshed);
    on<WishlistToggled>(_onToggled);
    on<WishlistCleared>(_onCleared);
  }

  final LoadWishlist _loadWishlist;
  final SyncWishlist _syncWishlist;
  final PushWishlist _pushWishlist;
  final AddToWishlist _addToWishlist;
  final RemoveFromWishlist _removeFromWishlist;
  final GetCatalog _getCatalog;
  final GetCachedCatalog _getCachedCatalog;

  /// Reports hearts turned on and off. Null reports nothing.
  final AnalyticsService? _analytics;

  /// Bumped on every sign-in and sign-out. An answer that arrives for an
  /// earlier user is dropped.
  int _session = 0;

  /// The signed-in user, or null. Toggles need one.
  String? _userId;

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

  Future<void> _onRefreshed(
    WishlistRefreshed event,
    Emitter<WishlistState> emit,
  ) async {
    await _refresh(emit, _session, freshCatalog: true);
  }

  void _onCleared(WishlistCleared event, Emitter<WishlistState> emit) {
    _session++;
    _userId = null;
    _reset(emit);
  }

  /// Back to the empty state. Emits nothing when already there.
  void _reset(Emitter<WishlistState> emit) {
    final empty = WishlistState();
    if (state != empty) emit(empty);
  }

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

  /// Syncs the wishlist with the server. With a wishlist already on screen
  /// it stays there while this runs and if it fails.
  Future<void> _refresh(
    Emitter<WishlistState> emit,
    int session, {
    required bool freshCatalog,
  }) async {
    final userId = _userId;
    if (session != _session || userId == null || state.isBusy) return;

    final hasData = state.status == WishlistStatus.loaded;
    emit(
      hasData
          ? state.copyWith(isRefreshing: true, failure: () => null)
          : state.copyWith(status: WishlistStatus.loading, failure: () => null),
    );

    final wishlist = await _syncWishlist(SyncWishlistParams(userId: userId));
    if (session != _session) return;

    // The catalog is only needed to show saved products.
    final hasItems = wishlist.match((_) => false, (items) => items.isNotEmpty);
    final catalog = hasItems ? await _loadCatalog(fresh: freshCatalog) : null;
    if (session != _session) return;

    // A catalog that failed keeps the one already held.
    final snapshot = catalog?.toNullable() ?? state.catalog;
    // Saved products cannot be shown without a catalog.
    final result = catalog != null && snapshot == null
        ? catalog.flatMap((_) => wishlist)
        : wishlist;

    emit(
      result.match(
        (failure) => hasData
            ? state.copyWith(isRefreshing: false, failure: () => failure)
            : state.copyWith(
                status: WishlistStatus.failure,
                failure: () => failure,
              ),
        (items) => state.copyWith(
          status: WishlistStatus.loaded,
          items: _keepPending(items),
          catalog: () => snapshot,
          isStale: false,
          isRefreshing: false,
        ),
      ),
    );
  }

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

  /// The catalog to look products up in: the saved copy, or the server
  /// when [fresh] is asked for or nothing is saved.
  Future<Either<Failure, CatalogSnapshot>> _loadCatalog({
    required bool fresh,
  }) async {
    if (!fresh) {
      final cached = await _getCachedCatalog(const NoParams());
      if (cached.isRight()) return cached;
    }
    return _getCatalog(const NoParams());
  }

  /// A product saved from a screen that loaded the catalog after this bloc
  /// did may be missing from the catalog held here. Picks up the newer
  /// catalog so the wishlist page can show it.
  Future<void> _ensureCatalogHas(
    String productId,
    Emitter<WishlistState> emit,
    int session,
  ) async {
    final held = state.catalog;
    if (held != null && held.products.any((p) => p.id == productId)) return;

    final catalog = await _loadCatalog(fresh: false);
    if (session != _session) return;

    final snapshot = catalog.toNullable();
    if (snapshot != null) emit(state.copyWith(catalog: () => snapshot));
  }

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

  static List<WishlistItem> _without(List<WishlistItem> items, String id) => [
    for (final item in items)
      if (item.productId != id) item,
  ];

  /// [items] with [id] back at [index], or at the end when the list has
  /// shrunk since.
  static List<WishlistItem> _restored(
    List<WishlistItem> items,
    String id,
    int index,
  ) {
    if (items.any((item) => item.productId == id)) return items;
    return [...items]
      ..insert(index.clamp(0, items.length), WishlistItem(productId: id));
  }
}
```

Facts a port keeps: `super(WishlistState())` is **not** `const` (the state has a
default `Set`/`List`); `_session` is an `int` bumped on `Started` and `Cleared`
and compared after every `await`; `_showSaved` awaits two futures together with
the record-`.wait` extension (`(f1, f2).wait`); `copyWith` clears nullable fields
through getters (`failure: () => null`, `catalog: () => snapshot`); analytics is
reported only on `result.isRight()`; the push is `unawaited`.

### `lib/features/orders/data/datasources/ref_order_remote_data_source.dart`, complete (pattern: third-party GET with an *optional* bearer)

```dart
import '../../../../core/app/api/api_response.dart';
import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;
import '../../../../core/services/kotech/ko_token_service.dart';
import '../../../../core/services/networking/endpoints.dart';
import '../../../../core/services/networking/networking.dart';
import '../../../../core/utils/json_readers.dart';
import '../exceptions/orders_exceptions.dart';
import '../models/ref_order_model.dart';

/// KO's `GET /order/ref-orders`, as the previous app calls it
/// (`refOrders.api.ts`): the orders KO registered, which an order paid
/// online passes through before the warehouse has it. The route has no
/// auth gate; the KO bearer is sent when one can be minted, and once more
/// with a fresh one after a 401. Throws [RefOrdersException].
abstract interface class RefOrderRemoteDataSource {
  /// `?user_phone=+91XXXXXXXXXX`: every row for the customer, from every
  /// KO-Tech storefront. The only parameter KO filters by on purpose; any
  /// other is read as a field filter and matches nothing.
  Future<List<RefOrderModel>> listByPhone({required String tenDigitPhone});

  /// `?ref_id=`: the row registered under [refId], or null when KO holds
  /// none.
  Future<RefOrderModel?> getByRefId({required String refId});
}

class RefOrderRemoteDataSourceImpl implements RefOrderRemoteDataSource {
  const RefOrderRemoteDataSourceImpl({
    required Networking networking,
    required KoTokenService tokens,
  }) : _networking = networking,
       _tokens = tokens;

  final Networking _networking;
  final KoTokenService _tokens;

  @override
  Future<List<RefOrderModel>> listByPhone({
    required String tenDigitPhone,
  }) async {
    final body = await _get({'user_phone': '+91$tenDigitPhone'});
    return [
      for (final row in asMapList(body['data'])) RefOrderModel.fromJson(row),
    ];
  }

  @override
  Future<RefOrderModel?> getByRefId({required String refId}) async {
    final body = await _get({'ref_id': refId});
    final rows = asMapList(body['data']);
    return rows.isEmpty ? null : RefOrderModel.fromJson(rows.first);
  }

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
}
```

### `lib/features/checkout/data/datasources/ko_order_remote_data_source.dart`, complete (pattern: idempotent POST with `x-request-id`, vendor error envelope, optional bearer)

```dart
import '../../../../core/app/api/api_response.dart';
import '../../../../core/app/exceptions/api_exceptions.dart';
import '../../../../core/app/exceptions/app_exceptions.dart' show AppException;
import '../../../../core/services/kotech/ko_token_service.dart';
import '../../../../core/services/networking/endpoints.dart';
import '../../../../core/services/networking/networking.dart';
import '../../../../core/utils/json_readers.dart';
import '../exceptions/checkout_exceptions.dart';
import '../models/ko_order_model.dart';
import '../models/placed_order_model.dart';
import '../models/registered_order_model.dart';

/// Talks to KO-Tech's Utils service, where orders are placed. Returns a
/// model or throws [OrderInProgressException],
/// [OrderNotRegisteredException], [ServerException] or
/// [ConnectionException].
abstract interface class KoOrderRemoteDataSource {
  /// Places [order] (`POST /order/my-mali`), which takes ~44 s. KO
  /// remembers [requestId]: sending it again returns the same order.
  Future<PlacedOrderModel> placeCodOrder(
    KoOrderModel order, {
    required String requestId,
  });

  /// Registers [order], paid online (`POST /order/create-order`), which
  /// creates its Razorpay order and answers in well under a second. KO
  /// remembers [requestId] here too: a known id returns the same Razorpay
  /// order, `duplicate: true`. Throws [OrderNotRegisteredException] when
  /// the answer carries no Razorpay order id.
  Future<RegisteredOrderModel> registerOnlineOrder(
    KoOrderModel order, {
    required String requestId,
  });

  /// Whether the money for [razorpayOrderId] was captured
  /// (`POST /order/payment-status-ksr`). Only an explicit
  /// `paymentResult.success: true` is true; a refusal, a missing envelope
  /// or no answer is false, never an exception.
  Future<bool> isPaymentCaptured(String razorpayOrderId, {String? paymentId});
}

class KoOrderRemoteDataSourceImpl implements KoOrderRemoteDataSource {
  const KoOrderRemoteDataSourceImpl(this._networking, {KoTokenService? tokens})
    : _tokens = tokens;

  final Networking _networking;

  /// Mints the bearer the prepaid routes take. They have no auth gate, so
  /// a call goes out without one when none can be minted, as the previous
  /// app's `koFetch` does. `/order/my-mali` takes none.
  final KoTokenService? _tokens;

  /// The header KO recognises a repeated attempt by.
  static const String requestIdHeader = 'x-request-id';

  /// `source` on the payment check: marks it read-only. Without it KO
  /// re-runs its order processing, as it does for the payment webhook.
  static const String paymentStatusSource = 'app';

  @override
  Future<PlacedOrderModel> placeCodOrder(
    KoOrderModel order, {
    required String requestId,
  }) async {
    final Object? response;
    try {
      response = await _networking.postAPICall(
        endpoint: KoUtilsEndpoints.codOrder,
        data: order.toJson(),
        headers: {requestIdHeader: requestId},
        host: ApiHost.koUtils,
      );
    } on AppException catch (e) {
      throw ConnectionException(e.toString());
    }

    if (response is SuccessResponse) {
      final body = asMap(response.rawData);
      final status = int.tryParse(response.statusCode) ?? 200;
      // A 2xx that says it failed: the order's fate is unknown, not refused.
      if (body['success'] == false || body['status'] == false) {
        throw ServerException(
          code: 'NOT_CONFIRMED',
          status: status,
          detail: _detailOf(body),
        );
      }
      return PlacedOrderModel.fromJson(body);
    }
    if (response is ErrorResponse) throw _toServerException(response);
    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  @override
  Future<RegisteredOrderModel> registerOnlineOrder(
    KoOrderModel order, {
    required String requestId,
  }) async {
    final response = await _postWithToken(
      endpoint: KoUtilsEndpoints.createOrder,
      data: order.toJson(),
      headers: {requestIdHeader: requestId},
    );

    if (response is SuccessResponse) {
      final body = asMap(response.rawData);
      final status = int.tryParse(response.statusCode) ?? 200;
      final model = RegisteredOrderModel.fromJson(body);
      // No Razorpay order id means no order was registered, whatever the
      // status says: the sheet must not open for an order that does not
      // exist.
      if (model.razorpayOrderId.isEmpty) {
        throw OrderNotRegisteredException(
          status: status,
          detail: _detailOf(body),
        );
      }
      return model;
    }
    if (response is ErrorResponse) throw _toServerException(response);
    throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
  }

  @override
  Future<bool> isPaymentCaptured(
    String razorpayOrderId, {
    String? paymentId,
  }) async {
    final Object? response;
    try {
      response = await _postWithToken(
        endpoint: KoUtilsEndpoints.paymentStatus,
        data: {
          'payment_id': ?paymentId,
          'rzp_order_id': razorpayOrderId,
          'source': paymentStatusSource,
        },
      );
    } on ConnectionException {
      return false;
    }
    if (response is! SuccessResponse) return false;
    final body = asMap(response.rawData);
    final result =
        body['paymentResult'] ?? asMap(body['data'])['paymentResult'];
    return result is Map && result['success'] == true;
  }

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

  /// KO's refusal code, e.g. [couponNotApplicableCode] on a 422.
  static const String couponNotApplicableCode = 'COUPON_NOT_APPLICABLE';
  static const String unbuyableItemCode = 'UNBUYABLE_ITEM';

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
}
```

### `lib/features/gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart`, complete (pattern: a sheet that owns its bloc and pops with a value)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_tones.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/form_helper/field_config.dart';
import '../../../../../core/widgets/form_helper/universal_form_field.dart';
import '../../../../../core/widgets/sheets/app_picker_sheet.dart';
import '../../../domain/entities/gstin.dart';
import '../../../domain/utils/gstin_validation.dart';
import '../../utils/gstin_failure_message.dart';
import '../bloc/gstin_sheet_bloc.dart';

/// How long "Verified" shows before the sheet closes with the GSTIN.
const Duration gstinSheetCloseDelay = Duration(milliseconds: 650);

/// The Add GSTIN sheet: one field, checked and saved by "Verify & Save".
/// Completes with the verified GSTIN, saved against [userKey], or null
/// when the sheet was closed.
Future<Gstin?> showGstinSheet(BuildContext context, {required String userKey}) {
  return AppPickerSheet.show<Gstin>(
    context,
    builder: (context) => BlocProvider<GstinSheetBloc>(
      create: (_) => sl<GstinSheetBloc>(),
      child: _GstinSheet(userKey: userKey),
    ),
  );
}

class _GstinSheet extends StatelessWidget {
  const _GstinSheet({required this.userKey});

  final String userKey;

  static final List<TextInputFormatter> _formatters = [
    FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z]')),
    TextInputFormatter.withFunction(
      (oldValue, newValue) =>
          newValue.copyWith(text: newValue.text.toUpperCase()),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bloc = context.read<GstinSheetBloc>();
    final failure = context.select((GstinSheetBloc b) => b.state.failure);
    final isVerifying = context.select(
      (GstinSheetBloc b) => b.state.isVerifying,
    );
    final verified = context.select((GstinSheetBloc b) => b.state.verified);
    final canVerify = context.select((GstinSheetBloc b) => b.state.canVerify);

    return BlocListener<GstinSheetBloc, GstinSheetState>(
      listenWhen: (previous, current) =>
          current.verified != null && previous.verified == null,
      // "Verified" shows for a moment, then the sheet closes with it.
      listener: (context, state) async {
        await Future<void>.delayed(gstinSheetCloseDelay);
        if (context.mounted) Navigator.of(context).pop(state.verified);
      },
      child: AppPickerSheet(
        key: const Key('gstinSheet'),
        title: 'Add GSTIN',
        footer: PrimaryButton(
          key: const Key('gstinSheet_verifyButton'),
          label: verified != null
              ? 'Verified'
              : isVerifying
              ? 'Verifying GSTIN…'
              : 'Verify & Save',
          leadingIcon: verified != null ? Icons.check_circle_rounded : null,
          isLoading: isVerifying,
          onPressed: canVerify || verified != null
              ? () => bloc.add(GstinVerifyPressed(userKey: userKey))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your business GSTIN to receive a GST invoice for this '
              'order.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: const Key('gstinSheet_numberField'),
              child:
                  UniversalFormField(
                    fieldType: UFFType.text,
                    label: 'GSTIN',
                    withTitle: true,
                    initialValue: '',
                    onChanged: (value) =>
                        bloc.add(GstinNumberChanged(value as String)),
                  ).build(
                    textInputConfig: TextInputConfig(
                      hintText: '29ABCDE1234F1Z5',
                      textInputType: TextInputType.visiblePassword,
                      maxLength: gstinLength,
                      showCounter: false,
                      autofocus: true,
                      inputFormatters: _formatters,
                      enabled: verified == null && !isVerifying,
                      onFieldSubmitted: (_) =>
                          bloc.add(GstinVerifyPressed(userKey: userKey)),
                      errorText: failure == null
                          ? null
                          : gstinFailureMessage(failure),
                    ),
                  ),
            ),
            if (verified != null) _VerifiedLine(gstin: verified),
          ],
        ),
      ),
    );
  }
}

/// "✓ Verified · Karnataka" under the field.
class _VerifiedLine extends StatelessWidget {
  const _VerifiedLine({required this.gstin});

  final Gstin gstin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = AppTones.of(context).success;

    return Padding(
      key: const Key('gstinSheet_verifiedLine'),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: success),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Verified · ${gstin.stateName ?? gstin.number}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

What the first 45 lines missed: the sheet pops **from a `BlocListener`** with the
verified value after `gstinSheetCloseDelay` (the only `Navigator.of(context).pop`
in the file; `AppPickerSheet.show<Gstin>` resolves to it), the field is disabled
while verifying or once verified (`enabled: verified == null && !isVerifying`),
the button is enabled when `canVerify || verified != null` and swaps its label
through three states, `TextInputType.visiblePassword` is used to keep autocorrect
off a GSTIN, and the two `TextInputFormatter`s force `[0-9A-Za-z]` and upper case.

### `lib/features/cart/presentation/cart/pages/cart_page.dart`, complete (pattern: a page bloc seeded from an app-wide bloc; `BlocListener`s forward changes; a stateful view that reports once)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/services/analytics/analytics_service.dart';
import '../../../../../core/services/analytics/app_events.dart';
import '../../../../../core/widgets/reload_widget.dart';
import '../../../../../core/widgets/sheets/app_info_sheet.dart';
import '../../../../coupons/presentation/bloc/coupon_bloc.dart';
import '../../../../coupons/presentation/utils/coupon_failure_message.dart';
import '../../../../coupons/presentation/widgets/coupon_row.dart';
import '../../bloc/cart_bloc.dart';
import '../bloc/cart_page_bloc.dart';
import '../../utils/cart_analytics.dart';
import '../utils/failure_message.dart';
import '../utils/stock_changes_message.dart';
import '../widgets/cart_charge_notes.dart';
import '../widgets/cart_empty_state.dart';
import '../widgets/cart_header.dart';
import '../widgets/cart_items_section.dart';
import '../widgets/cart_loading_skeleton.dart';
import '../widgets/cart_pay_bar.dart';
import '../widgets/cart_recommendations.dart';
import '../widgets/cart_savings_banner.dart';

/// The cart: its lines, what is saved for later, suggestions, and the
/// slide to review and pay. The app-wide [CartBloc] owns the cart itself;
/// [CartPageBloc] owns what only this page shows.
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

class _CartView extends StatefulWidget {
  const _CartView();

  @override
  State<_CartView> createState() => _CartViewState();
}

class _CartViewState extends State<_CartView> {
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

  @override
  Widget build(BuildContext context) {
    final count = context.select((CartBloc bloc) => bloc.state.totalQuantity);
    final subtotal = context.select((CartBloc bloc) => bloc.state.subtotal);

    return MultiBlocListener(
      listeners: [
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              previous.items.isEmpty && current.items.isNotEmpty,
          listener: (context, state) => _reportOpened(state),
        ),
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
        // The current catalog arrived: check the cart against its stock.
        BlocListener<CartPageBloc, CartPageState>(
          listenWhen: (previous, current) =>
              current.catalogIsCurrent &&
              (!previous.catalogIsCurrent ||
                  previous.catalog != current.catalog),
          listener: (context, state) =>
              context.read<CartBloc>().add(CartStockChecked(state.catalog)),
        ),
        // The check removed or cut down lines: tell the shopper.
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              current.stockChanges != null &&
              current.stockChanges != previous.stockChanges,
          listener: (context, state) async {
            final bloc = context.read<CartBloc>();
            await AppInfoSheet.show(
              context,
              key: const Key('cart_stockChangesSheet'),
              icon: Icons.inventory_2_outlined,
              title: stockChangesTitle,
              message: stockChangesMessage(state.stockChanges!),
            );
            bloc.add(CartStockChangesSeen());
          },
        ),
        // The applied coupon was dropped because the cart changed: a
        // passing note, since the cart itself is what the shopper is
        // working on.
        BlocListener<CouponBloc, CouponState>(
          listenWhen: (previous, current) =>
              previous.applied != null &&
              current.applied == null &&
              current.failure != null &&
              current.failure != previous.failure,
          listener: (context, state) => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('cart_couponRemovedMessage'),
                content: Text(
                  'Coupon removed: ${couponFailureMessage(state.failure!)}',
                ),
              ),
            ),
        ),
        // A change that could not be saved while the cart stays on screen.
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              current.status == CartStatus.failure &&
              current.failure != previous.failure &&
              _hasContent(current),
          listener: (context, state) => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('cart_updateFailedMessage'),
                content: Text(cartUpdateFailureMessage(state.failure)),
              ),
            ),
        ),
      ],
      child: Scaffold(
        key: const Key('cart_page'),
        // The list runs under the pay bar's rounded corners.
        extendBody: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CartHeader(
              itemCount: count,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.goNamed(AppRoute.home.name),
            ),
            const Expanded(child: _CartBody()),
          ],
        ),
        bottomNavigationBar: count == 0
            ? null
            : CartPayBar(
                subtotal: subtotal,
                onPay: () => context.pushNamed(AppRoute.reviewPay.name),
              ),
      ),
    );
  }
}

bool _hasContent(CartState state) =>
    state.items.isNotEmpty || state.savedForLater.isNotEmpty;

class _CartBody extends StatelessWidget {
  const _CartBody();

  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final status = context.select((CartBloc bloc) => bloc.state.status);
    final items = context.select((CartBloc bloc) => bloc.state.items);
    final saved = context.select((CartBloc bloc) => bloc.state.savedForLater);
    final count = context.select((CartBloc bloc) => bloc.state.totalQuantity);
    final savings = context.select((CartBloc bloc) => bloc.state.itemSavings);
    final subtotal = context.select((CartBloc bloc) => bloc.state.subtotal);
    final rules = context.select((CartPageBloc bloc) => bloc.state.chargeRules);
    final coupon = context.select((CouponBloc bloc) => bloc.state.applied);
    final hasContent = items.isNotEmpty || saved.isNotEmpty;
    // The pay bar reports its height as bottom padding.
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

    return CustomScrollView(
      key: const Key('cart_scrollView'),
      slivers: [
        if (!hasContent &&
            (status == CartStatus.initial || status == CartStatus.loading))
          const CartLoadingSkeleton(key: Key('cart_loadingSkeleton'))
        else if (!hasContent && status == CartStatus.failure)
          const SliverFillRemaining(hasScrollBody: false, child: _CartFailure())
        else
          SliverPadding(
            padding: CartLoadingSkeleton.padding,
            sliver: SliverList.list(
              children: [
                if (items.isEmpty)
                  CartEmptyState(
                    key: const Key('cart_emptyState'),
                    onBrowse: () => context.goNamed(AppRoute.categories.name),
                  )
                else ...[
                  if (savings > 0) ...[
                    CartSavingsBanner(
                      key: const Key('cart_savingsBanner'),
                      amount: savings,
                    ),
                    const SizedBox(height: _gap),
                  ],
                  CartItemsSection(items: items, totalQuantity: count),
                  if (rules != null) ...[
                    const SizedBox(height: _gap),
                    CartChargeNotes(subtotal: subtotal, rules: rules),
                  ],
                  const SizedBox(height: _gap),
                  CouponRow(
                    coupon: coupon,
                    onView: () => context.pushNamed(AppRoute.applyCoupon.name),
                    onRemove: () =>
                        context.read<CouponBloc>().add(CouponRemoved()),
                  ),
                ],
                if (saved.isNotEmpty) ...[
                  const SizedBox(height: _gap),
                  CartSavedSection(
                    key: const Key('cart_savedSection'),
                    items: saved,
                  ),
                ],
                if (items.isNotEmpty) ...[
                  const SizedBox(height: _gap),
                  const CartRecommendations(),
                ],
              ],
            ),
          ),
        SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
      ],
    );
  }
}

class _CartFailure extends StatelessWidget {
  const _CartFailure();

  @override
  Widget build(BuildContext context) {
    final failure = context.select((CartBloc bloc) => bloc.state.failure);

    return ReloadWidget(
      key: const Key('cart_retryButton'),
      errorMessage: cartLoadFailureMessage(failure),
      onReload: () => context.read<CartBloc>().add(CartStarted()),
    );
  }
}
```

### `lib/features/home/presentation/home/pages/home_page.dart`, complete (pattern: a tab page with cache-first status switch, refresh listener, `RefreshIndicator` awaiting `!isBusy`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/services/analytics/analytics_service.dart';
import '../../../../../core/services/analytics/app_events.dart';
import '../../../../../core/widgets/reload_widget.dart';
import '../../../../../core/widgets/search/search_trigger_bar.dart';
import '../../../../cart/presentation/widgets/cart_bar_overlay.dart';
import '../../../../catalog/presentation/categories/pages/categories_page.dart';
import '../../../../mali_coins/presentation/bloc/mali_coins_bloc.dart';
import '../../../domain/entities/banner_target.dart';
import '../../../domain/entities/home_banner.dart';
import '../../../domain/utils/build_home_banners.dart';
import '../bloc/home_bloc.dart';
import '../utils/failure_message.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_header.dart';
import '../widgets/home_loading_skeleton.dart';
import '../widgets/home_section_view.dart';
import '../widgets/push_permission_prompt.dart';

/// Home tab for signed-in users: greeting, search, banners and one product
/// rail per category.
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

class _HomeView extends StatelessWidget {
  const _HomeView();

  /// Tap on the search bar: opens the catalog with its search field ready.
  void _onSearchTap(BuildContext context) {
    context.goNamed(
      AppRoute.categories.name,
      queryParameters: {
        CategoriesPage.searchParam: CategoriesPage.newSearchRequest(),
      },
    );
  }

  /// Tap on the search bar's camera button.
  void _onCameraTap(BuildContext context) {
    context.read<AnalyticsService>().track(AppEvents.cameraSearchTapped);
    // TODO(search): visual search through analyze-plant.
  }

  /// Tap on a banner: opens the place its link names.
  Future<void> _onBannerTap(BuildContext context, HomeBanner banner) async {
    context.read<AnalyticsService>().track(
      AppEvents.bannerClicked,
      properties: {'title': banner.title, 'cta_link': banner.link},
    );
    switch (bannerTargetFor(banner.link)) {
      case BannerCatalogTarget():
        context.goNamed(AppRoute.categories.name);
      case BannerCategoryTarget(:final name):
        context.goNamed(
          AppRoute.categories.name,
          queryParameters: {CategoriesPage.categoryParam: name},
        );
      case BannerWebTarget(:final url):
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } on Exception {
          // No app can open the link; the banner stays as it is.
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select((HomeBloc bloc) => bloc.state.status);
    final sections = context.select((HomeBloc bloc) => bloc.state.sections);
    final banners = context.select((HomeBloc bloc) => bloc.state.banners);
    final coins = context.select((MaliCoinsBloc bloc) => bloc.state.balance);
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + CartBarOverlay.height;

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
      child: Scaffold(
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<HomeBloc>()..add(HomeRefreshed());
                await bloc.stream.firstWhere((s) => !s.isBusy);
              },
              child: CustomScrollView(
                key: const Key('home_scrollView'),
                slivers: [
                  SliverToBoxAdapter(child: HomeHeader(coinBalance: coins)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: KeyedSubtree(
                        key: const Key('home_searchField'),
                        child: SearchTriggerBar(
                          hintText: 'Try "tomato seeds", "neem oil"...',
                          onTap: () => _onSearchTap(context),
                          onCameraTap: () => _onCameraTap(context),
                        ),
                      ),
                    ),
                  ),
                  // Hidden while loading (the skeleton stands in for it)
                  // and whenever there is no banner to show.
                  if (status == HomeStatus.loaded && banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: HomeBannerCarousel(
                        banners: banners,
                        onBannerTap: (banner) => _onBannerTap(context, banner),
                      ),
                    ),
                  switch (status) {
                    HomeStatus.initial ||
                    HomeStatus.loading => const HomeLoadingSkeleton(
                      key: Key('home_loadingSkeleton'),
                    ),
                    HomeStatus.failure => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _HomeFailure(),
                    ),
                    HomeStatus.loaded when sections.isEmpty =>
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyHome(),
                      ),
                    HomeStatus.loaded => SliverList.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, index) =>
                          HomeSectionView(section: sections[index]),
                    ),
                  },
                  SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
                ],
              ),
            ),
            const CartBarOverlay(),
          ],
        ),
      ),
    );
  }
}

class _HomeFailure extends StatelessWidget {
  const _HomeFailure();

  @override
  Widget build(BuildContext context) {
    final failure = context.select((HomeBloc bloc) => bloc.state.failure);

    return ReloadWidget(
      key: const Key('home_retryButton'),
      errorMessage: homeFailureMessage(failure),
      onReload: () => context.read<HomeBloc>().add(HomeRefreshed()),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nothing on the shelves yet. Check back soon.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

### `product_detail_page.dart` — exact public surface and listeners (MYMALI-SPECIFIC; read in full, 362 lines)

Public: `class ProductDetailPage extends StatelessWidget { const ProductDetailPage({super.key, required this.productId}); static const String idParam = 'id'; final String productId; static void open(BuildContext context, String productId) { context.pushNamed(AppRoute.productDetail.name, pathParameters: {idParam: productId}); } }`.
`build` reads `Localizations.maybeLocaleOf(context)?.languageCode` and creates
`sl<ProductDetailBloc>()..add(ProductDetailStarted(productId, pincode: context.read<LocationBloc>().state.place?.pincode ?? '', language: language))`
over `const _ProductDetailView()`.

Private: `_ProductDetailView` (the `MultiBlocListener` + `Scaffold(key: Key('product_page'), extendBody: true, body: switch (status) {…}, bottomNavigationBar: status == loaded ? const ProductBuyBar() : null)`),
`_ProductBody` (`static const EdgeInsets _padding = EdgeInsets.all(16)`; a local
`section(Widget child, {EdgeInsets padding = _padding})` wrapping in
`ColoredBox(color: colors.surface)`; an 8 px `surfaceContainerLowest` `gap`;
`CustomScrollView(key: Key('product_scrollView'))`; `_share` through
`SharePlus.instance.share(ShareParams(subject: product.title, text: productShareText(productId:, title:, price: state.selectedVariant?.price ?? 0, description:, webOrigin: Env.webOrigin)))`),
`_CouponNoteSlot` (`context.select((CouponBloc b) => b.state.hasCoupon)`),
`_SimilarSlot`, `_ProductFailure` (`SafeArea` → `BackButton(key: Key('product_failureBackButton'))` + `ReloadWidget(key: Key('product_retryButton'), errorMessage: productLoadFailureMessage(failure), onReload: … ProductDetailRefreshed())`),
top-level `void _back(BuildContext context) => context.canPop() ? context.pop() : context.goNamed(AppRoute.home.name);`
and `void _reportViewed(BuildContext context, ProductDetailState state)`
(`viewItem(items: [AnalyticsItem(sku: variant?.sku ?? product.id, quantity: 1, price: variant?.price ?? 0, name: product.title, category: product.categoryName)], value: price)` then `track(AppEvents.productView, properties: {'item_id': sku, 'item_name': product.title, 'price': price, 'currency': 'INR'})`).

| listener | `listenWhen` | action | key |
|---|---|---|---|
| `ProductDetailBloc` | `previous.product == null && current.product != null` | `_reportViewed` (once, saved copy or fresh) | — |
| `ProductDetailBloc` | `current.status == loaded && current.failure != null && current.failure is! CacheMissFailure && current.failure != previous.failure` | `SnackBar(productRefreshFailureMessage(state.failure))` | `product_refreshFailedMessage` |
| `ProductDetailBloc` | `current.reviewFailure != null && current.reviewFailure != previous.reviewFailure` | `AppInfoSheet.show(tone: error, title: "Couldn't save your review", message: reviewFailureMessage(state.reviewFailure))` | `product_reviewFailedSheet` |
| `CartBloc` | `current.status == CartStatus.failure && current.failure != previous.failure` | `SnackBar(cartUpdateFailureMessage(state.failure))` | `product_cartUpdateFailedMessage` |

Status switch: `loading` → `ProductDetailSkeleton(key: Key('product_loadingSkeleton'), onBack: () => _back(context))`; `failure` → `_ProductFailure`; `loaded` → `Stack(children: [_ProductBody(), CartBarOverlay()])`.
Note the `is! CacheMissFailure` guard: AGENTS.md §20 "never show a message for `CacheMissFailure`" is enforced in the page's `listenWhen`, not in the bloc.

### `order_placed_page.dart` — exact public surface (MYMALI-SPECIFIC; read in full, 426 lines)

```dart
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

class OrderPlacedPage extends StatefulWidget {
  const OrderPlacedPage({super.key, required this.args});

  final OrderPlacedArgs args;

  /// The orders already reported, so a page opened again for the same order
  /// (a rebuilt route) never reports its purchase twice.
  @visibleForTesting
  static final Set<String> reportedOrders = {};

  @override
  State<OrderPlacedPage> createState() => _OrderPlacedPageState();
}
```

`_OrderPlacedPageState`: `initState` → `addPostFrameCallback` → `_reportPurchase()`,
which derives `transactionId = order.warehouseOrderId ?? [order.refId, order.medusaOrderId, order.payment?.paymentId].firstWhere((id) => id != null && id.isNotEmpty, orElse: () => '')!`,
a de-duplication `key = transactionId.isEmpty ? order.quote.hashCode.toString() : transactionId`,
returns if `!OrderPlacedPage.reportedOrders.add(key)`, then
`purchase(transactionId:, items: analyticsItemsFor(args.items), value: total, coupon: order.quote.couponCode)` + `track(AppEvents.orderPlaced, {'order_id', 'value', 'items_count', 'currency': 'INR'})`,
and for `order.isPaidOnline` also `capturePayment(total, orderId: transactionId)` + `track(AppEvents.paymentSuccessful, {'order_id', 'amount', 'method': paymentMethodName(order.paymentMethod), 'currency': 'INR'})`.
`build`: `BlocProvider<OrderPlacedBloc>(create: … sl<OrderPlacedBloc>()..add(OrderPlacedStarted(order: args.order, items: args.items, phone: auth is Authenticated ? auth.user.phone : '', address: args.address, customerName: auth is Authenticated ? auth.user.fullName ?? '' : '', gstin: args.gstin)))`
wrapping one `BlocListener` (`listenWhen: current.spentCoins > 0 && current.spentCoins != previous.spentCoins` → `context.read<MaliCoinsBloc>().add(MaliCoinsSpent(state.spentCoins))`) over `const _OrderPlacedView()`.
`_OrderPlacedView`: `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) _goHome(context); })`; `_goHome` = `context.goNamed(AppRoute.home.name)`; `_openInvoice` = `context.pushNamed(AppRoute.invoice.name, extra: invoice)` when `state.invoice != null`; `_trackOrder(context, orderNumber)` = `context.pushNamed(AppRoute.orderDetails.name, pathParameters: {OrderDetailsPage.idParam: orderNumber}, extra: state.warehouseOrder)`; it reads the whole state with `context.watch<OrderPlacedBloc>().state` (rule 14).
Keys: `orderPlaced_page`, `orderPlaced_title`, `orderPlaced_orderNumber`, `orderPlaced_total`, `orderPlaced_paymentMethod`, `orderPlaced_estimatedDelivery`, `orderPlaced_paymentStatus`, `orderPlaced_itemsPending`, `orderPlaced_line_$i`, `orderPlaced_trackButton` (disabled while `orderNumber == null`), `orderPlaced_invoiceButton` (`SecondaryButton`), `orderPlaced_continueButton` (`TextButton`).
Texts: `'Order Confirmed!'`, `'Thank you for shopping with My Mali 🌱'`, `'Order #$orderNumber'` / `'Order number on its way'`, `'Amount Paid'` / `'Amount Payable'`, `'Payment Method'`, `'Estimated Delivery'`, `'Payment Status'`, `'Paid'` / `'Pay on Delivery'` (coloured `tones.success` / `tones.warning`), `'Order Items'`, `'The items will show once the warehouse has your order.'`, `'Track Order'`, `'Download Invoice'`, `'Continue Shopping'`. Private `_SummaryRow({required icon, required label, required value, valueKey, valueColor})`.

### `review_pay_page.dart` — exact public surface and the 12 listeners (MYMALI-SPECIFIC; read in full, 593 lines)

Public: `class ReviewPayPage extends StatelessWidget { const ReviewPayPage({super.key}); }` whose `build` creates
`sl<ReviewPayBloc>()..add(ReviewPayStarted(items: cart.items, subtotal: cart.subtotal, coupon: context.read<CouponBloc>().state.applied))`
with `cart = context.read<CartBloc>().state`; and
`const String placingOrderNote = 'Placing your order, this can take up to a minute. Please keep the app open.';`
Private: `_ReviewPayView` (`static const double _gap = 8; static const EdgeInsets _padding = EdgeInsets.fromLTRB(12, 10, 12, 0);`; methods `_viewCoupons`, `_changePaymentMethod` (`showPaymentMethodSheet(context, total:, selected:, codCharge: bloc.state.chargeRules?.codCharge ?? 0)` → `ReviewPayMethodChanged`), `_placeOrder` (no address → `_chooseAddress`; not `Authenticated` → `AppInfoSheet` `reviewPay_orderSignInSheet`; else `_reportPaymentStarted` then `ReviewPayOrderRequested(phone:, userKey:, fullName:, email:)`), `_reportPaymentStarted` (`track(AppEvents.paymentStarted, {'value', 'method': paymentMethodName(…), 'currency': 'INR'})` + `addPaymentInfo(items: analyticsItemsFor(state.items), value: total, paymentType: paymentTypeName(…))`), `_chooseAddress` (`showDeliveryAddressSheet` → `ReviewPayAddressChanged` or `_editAddress`), `_editAddress({SavedAddress? address, bool makeDefault = false})` (`context.pushNamed<SavedAddress>(AppRoute.addressForm.name, extra: AddressFormArgs(address:, makeDefault:))`), `_showPlaceFailure` (a `switch (failure)` over `OrderAddressFailure(issue: OrderAddressIssue.missing)` → `('Choose address', _chooseAddress)`, `OrderAddressFailure()` → `('Edit address', _editAddress(address: state.address))`, `OrderOutcomeUnknownFailure() || OrderStillProcessingFailure() || OrderNotRegisteredFailure() || PaymentFailedFailure()` → `('Try again', _placeOrder)`, `PaymentNotConfiguredFailure()` → `('Pay on delivery', ReviewPayMethodChanged(PaymentMethod.cashOnDelivery))`, `_` → `('Got it', null)`; then `AppInfoSheet.show(key: Key('reviewPay_placeFailedSheet'), tone: isPlaceOrderCancellation(failure) ? info : error, title: placeOrderFailureTitle(failure), message: placeOrderFailureMessage(failure, items: state.items), actionLabel: action)` and `if (pressed && next != null && context.mounted) await next();`), `_finishOrder` (`context.goNamed(AppRoute.orderPlaced.name, extra: OrderPlacedArgs(order: state.placedOrder!, items: state.items, address: state.address, gstin: state.gstin?.number ?? ''))`, then `cart.add(CartItemsRemoved(variantIds))` and `if (coupons.state.applied != null) coupons.add(CouponRemoved())`), `_chooseGstin` (sign-in sheet `reviewPay_gstinSignInSheet`, else `showGstinSheet(context, userKey:)` → `ReviewPayGstinChanged`), `_showNote(context, key, text)` (`ScaffoldMessenger..hideCurrentSnackBar()..showSnackBar(SnackBar(key:, content: Text(text)))`)); `_ReviewPayBody({required onViewCoupons, required onChooseGstin, required onChangeAddress})` (`context.watch<ReviewPayBloc>().state`; `ListView(key: Key('reviewPay_scrollView'))` of `CouponNudgeBanner` (`reviewPay_couponNudge`), `CouponRow`, `MaliCoinsRow`, `BillDetailsCard` (`reviewPay_billCard`), `GstinRow`, `DeliveryAddressCard` (`reviewPay_addressCard`)); `_PayBar({required onChangeMethod, required onPay})` → `ReviewPayBar(total:, paymentMethod:, onChangeMethod: isPlacing ? null : …, onPay: canPay ? onPay : null, isLoading: isPlacing, note: isPlacing && method == PaymentMethod.cashOnDelivery ? placingOrderNote : null)`.
Shell: `ReviewPayAnalytics(child: PopScope(canPop: !isPlacing, child: Stack(fit: StackFit.expand, children: [Scaffold(key: Key('reviewPay_page'), extendBody: true, body: AbsorbPointer(absorbing: isPlacing, …)), if (paymentPhase != null) PaymentGateOverlay(key: Key('reviewPay_paymentGate'), phase:, total:, onCancel: … ReviewPayPaymentCancelled())])))`.

| # | bloc | `listenWhen` | action |
|---|---|---|---|
| 1 | `ReviewPayBloc` | `previous.placedOrder == null && current.placedOrder != null` | `_finishOrder` |
| 2 | `ReviewPayBloc` | `current.placeFailure != null && current.placeFailure != previous.placeFailure` | `_showPlaceFailure` |
| 3 | `CartBloc` | `previous.items != current.items` | `ReviewPayCartChanged(items:, subtotal:)` |
| 4 | `CouponBloc` | `previous.applied != current.applied` | `ReviewPayCouponChanged(state.applied)` |
| 5 | `CouponBloc` | `current.applied != null && current.applied?.code != previous.applied?.code` | `_showNote(reviewPay_couponAppliedMessage, '${code} applied')` |
| 6 | `CouponBloc` | `previous.applied != null && current.applied == null && current.failure != null && current.failure != previous.failure` | `AppInfoSheet(reviewPay_couponRemovedSheet, error, 'Coupon removed', couponFailureMessage(state.failure!))` |
| 7 | `ReviewPayBloc` | `current.rejectedCouponCode != null && current.rejectedCouponCode != previous.rejectedCouponCode` | if `coupons.state.applied?.code == state.rejectedCouponCode` → `CouponDroppedByServer("${code} can't be used on this order, so it was removed from your bill.")` |
| 8 | `CouponBloc` | `current.serverWarning != null && current.serverWarning != previous.serverWarning` | `AppInfoSheet(reviewPay_couponDroppedSheet, error, 'Coupon removed', state.serverWarning!)` |
| 9 | `ReviewPayBloc` | `current.coinsRefused && !previous.coinsRefused` | `_showNote(reviewPay_coinsRefusedMessage, "Coins can't be used on this bill.")` |
| 10 | `ReviewPayBloc` | `current.coinsApplied > 0 && current.coinsApplied != previous.coinsApplied` | `_showNote(reviewPay_coinsAppliedMessage, '${coins} Mali Coins applied · ${formatRupees(coins)} off')` |
| 11 | `ReviewPayBloc` | `current.coinsAvailable != null && current.coinsAvailable != previous.coinsAvailable` | `context.read<MaliCoinsBloc>().add(MaliCoinsBalanceChanged(state.coinsAvailable!))` |
| 12 | (in the body) `AnalyticsService.track(AppEvents.changeAddressTapped)` on the address card's Change | — | then `_chooseAddress` |

(presentation-bloc-pages.md:73 counts 12 listeners; the `MultiBlocListener` holds
11 `BlocListener`s and the twelfth report is the tap handler above.)

### `lib/core/router/app_router.dart` — verification of router-navigation.md §3.1

The source (278 lines) has exactly: imports of `flutter/widgets.dart`,
`go_router`, 27 page/entity files (`account_page`, `address_form_page`,
`saved_addresses_page`, `login_page`, `splash_page`, `cart_page`,
`catalog_filters` (for `StockFilter`), `categories_page`, `order_placed_page`,
`review_pay_page`, `apply_coupon_page`, `garden_home_page`, `gst_claims_page`,
`notifications_page`, `home_page`, `app_shell_scaffold`, `invoice.dart`,
`invoice_page`, `select_location_page`, `coins_page`, `warehouse_order.dart`,
`my_orders_page`, `order_details_page`, `product_detail_page`, `edit_profile_page`,
`referral_page`, `help_support_page`, `wishlist_page`), `../services/analytics/analytics_service.dart`,
`analytics_screen_tracker.dart`, `app_routes.dart`, `navigator_keys.dart`;

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
    routes: [ … ],
  );
}
```

with 24 `GoRoute`s (`splash`, `login`; branches `home`, `categories` (query
parameters `CategoriesPage.categoryParam`, `stockParam` decoded with
`StockFilter.values.asNameMap()[…]`, `searchParam`), `garden`, `wishlist`,
`account`; root-navigator `cart`, `selectLocation`, `coins`, `reviewPay`,
`orderPlaced` (`redirect: state.extra is OrderPlacedArgs ? null : AppRoute.home.path`),
`invoice` (`redirect: state.extra is Invoice ? null : AppRoute.home.path`),
`applyCoupon`, `savedAddresses`, `addressForm` (`extra is AddressFormArgs ? extra : const AddressFormArgs()`),
`editProfile`, `referral`, `gstClaims`, `notifications`, `helpSupport`,
`productDetail` (`key: state.pageKey`, `productId: state.pathParameters[ProductDetailPage.idParam] ?? ''`),
`myOrders`, `orderDetails` (`key: state.pageKey`, `orderId: state.pathParameters[OrderDetailsPage.idParam] ?? ''`, `initial: state.extra is WarehouseOrder ? state.extra! as WarehouseOrder : null`)).
router-navigation.md §3.1 reproduces all of it (5 `StatefulShellBranch`, 24 `GoRoute`
occurrences counted in both); it stays the owner. The shell builder is
`AppShellScaffold(navigationShell: navigationShell, onTabSelected: _tracker?.tabSelected)`
and every branch passes `observers: _observers()` (a fresh observer each).

### The nine test files, read in full

#### `test/features/checkout/data/repositories/checkout_repository_impl_test.dart` (922 lines)

The repository under test is built with every clock and id injected:

```dart
    repository = CheckoutRepositoryImpl(
      remote: remote,
      koOrders: ko,
      attempts: attempts,
      medusaCustomers: medusa,
      gateway: gateway,
      razorpayKeyId: 'rzp_live_app',
      now: () => now,
      wait: (duration) async {
        waits.add(duration);
        now = now.add(duration);
      },
      newRequestId: () => 'req_${++ids}',
    );
```

(two tests rebuild it with `razorpayKeyId: 'rzp_test_app', useAppKey: true` and
with `razorpayKeyId: ' '`). Its four file-private fakes, verbatim — the "list of
answers, the last repeats" and "map of answers per method" shapes:

```dart
class _FakeRemote implements CheckoutRemoteDataSource {
  Object? error;
  QuoteRequestModel? lastRequest;
  Object? recordError;
  final List<OrderRecordModel> records = [];

  @override
  Future<CheckoutQuoteModel> fetchQuote(QuoteRequestModel request) async {
    lastRequest = request;
    final error = this.error;
    if (error != null) throw error;
    return const CheckoutQuoteModel(
      quoteId: 'q_1',
      subtotal: 400,
      coinsRedeemed: 50,
      coinsAvailable: 50,
      total: 350,
    );
  }

  @override
  Future<void> recordOrder(OrderRecordModel record) async {
    records.add(record);
    final error = recordError;
    if (error != null) throw error;
  }
}

/// KO: answers each call with the next of [answers] (a model, or an
/// exception to throw); the last answer repeats.
class _FakeKoOrders implements KoOrderRemoteDataSource {
  _FakeKoOrders(this.answers);

  List<Object> answers;
  final List<({Map<String, dynamic> body, String requestId})> calls = [];

  @override
  Future<PlacedOrderModel> placeCodOrder(
    KoOrderModel order, {
    required String requestId,
  }) async {
    final answer = answers[calls.length.clamp(0, answers.length - 1)];
    calls.add((body: order.toJson(), requestId: requestId));
    if (answer is PlacedOrderModel) return answer;
    throw answer;
  }

  /// `create-order`: a model, or an exception to throw.
  Object registerAnswer = const RegisteredOrderModel(
    razorpayOrderId: 'order_01',
  );
  final List<({Map<String, dynamic> body, String requestId})> registrations =
      [];

  @override
  Future<RegisteredOrderModel> registerOnlineOrder(
    KoOrderModel order, {
    required String requestId,
  }) async {
    registrations.add((body: order.toJson(), requestId: requestId));
    final answer = registerAnswer;
    if (answer is RegisteredOrderModel) return answer;
    throw answer;
  }

  /// `payment-status-ksr`'s answer, and every order asked about.
  bool paymentCaptured = false;
  final List<String> statusChecks = [];

  @override
  Future<bool> isPaymentCaptured(
    String razorpayOrderId, {
    String? paymentId,
  }) async {
    statusChecks.add(razorpayOrderId);
    return paymentCaptured;
  }
}

class _FakeAttempts implements OrderAttemptLocalDataSource {
  OrderAttemptModel? saved;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<OrderAttemptModel?> readAttempt() async {
    if (failReads) throw const OrderAttemptStorageException('read');
    return saved;
  }

  @override
  Future<void> writeAttempt(OrderAttemptModel attempt) async {
    if (failWrites) throw const OrderAttemptStorageException('write');
    saved = attempt;
  }

  @override
  Future<void> clearAttempt() async => saved = null;
}

/// Medusa: each method answers with its entry in [answers] (a value, or an
/// exception to throw) and records the call.
class _FakeMedusaCustomers implements MedusaCustomerDataSource {
  final Map<String, Object> answers = {
    'login': 'tok_login',
    'register': 'tok_register',
    'createCustomer': 'ok',
    'customerId': 'cus_01',
    'refreshToken': 'tok_refreshed',
  };
  final List<String> calls = [];
  final Map<String, Object?> lastArgs = {};

  T _answer<T>(String call, [Map<String, Object?> args = const {}]) {
    calls.add(call);
    lastArgs[call] = args;
    final answer = answers[call];
    if (answer is Exception) throw answer;
    return answer as T;
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async => _answer('login', {'email': email, 'password': password});

  @override
  Future<String> register({
    required String email,
    required String password,
  }) async => _answer('register', {'email': email, 'password': password});

  @override
  Future<void> createCustomer({
    required String token,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async => _answer<String>('createCustomer', {
    'token': token,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
  });

  @override
  Future<String> customerId({required String token}) async =>
      _answer('customerId', {'token': token});

  @override
  Future<String> refreshToken({required String token}) async =>
      _answer('refreshToken', {'token': token});
}
```

Groups and the facts they pin (all MYMALI-SPECIFIC behaviour of
`CheckoutRepositoryImpl`): `getQuote` maps `ServerException('UNAUTHORIZED', 401)` →
`QuoteAuthRequiredFailure`, `'ITEM_UNAVAILABLE'` 409 → `QuoteItemUnavailableFailure`
(and `QuoteItemsUnavailableException(productIds:)` keeps the ids), `'NOT_CONFIGURED'`
/ `'UPSTREAM'` 503 → `QuoteUnavailableFailure`, `ConnectionException` →
`NetworkFailure`, anything else → `ServerFailure(errorCode:, code: status)`;
`placeCodOrder` sends `const KoOrderModel(_order).toJson()` with `x-request-id`
`req_1`, forgets the attempt on success, retries `OrderInProgressException` every
`CheckoutRepositoryImpl.retryInterval` with the same id (20 calls in the 60 s
budget → `OrderStillProcessingFailure`, id kept), 400/422 → `OrderRefusedFailure`
(`reason` from `COUPON_NOT_APPLICABLE` / `UNBUYABLE_ITEM` / `HTTP_422` → `other`,
attempt forgotten), `NOT_CONFIRMED` 201 / 500 / offline → `OrderOutcomeUnknownFailure`
with the id kept and replayed, a saved `OrderAttemptModel(signature: const KoOrderModel(_order).attemptSignature, requestId:, savedAt:)`
is reused within `attemptLifetime`, failing attempt storage never stops an order;
`recordOrder` → `ServerFailure` / `NetworkFailure`; `medusaCustomerId` →
`CheckoutRepositoryImpl.medusaPassword(email)` is the first 32 hex chars of
SHA-256(`"my-mali-customer:<email>:v1"`) (`'a@b.c'` → `'d49c7412c85cc1235fd7e7b65e4c91de'`),
login → customerId, 401 on customerId → createCustomer → refreshToken → customerId,
refused login → register, a different identity never reuses the remembered id;
`registerOnlineOrder` keeps the attempt, falls back to the app key, `useAppKey`
wins, blank key → `PaymentNotConfiguredFailure`, COD and online attempts never
share an id, `duplicate: true` asks `isPaymentCaptured` (`statusChecks`) and a paid
duplicate forgets the attempt; `collectPayment` opens the sheet with
`amountPaise: 21250` for `212.5`, `merchantName: CheckoutRepositoryImpl.paymentMerchant`,
`description: CheckoutRepositoryImpl.paymentDescription` (contains `'my mali'`
lower-cased), maps `cancelled`/`upiTimeout` → `PaymentCancelledFailure(upiTimeout:)`,
`insufficientFunds` → `PaymentFailedFailure(reason: PaymentFailureReason.insufficientFunds)`,
`unknown` keeps `detail`, `notConfigured` → `PaymentNotConfiguredFailure`, and a
failed payment keeps the attempt.

#### `test/features/product/presentation/product_detail/pages/product_detail_page_test.dart` (491 lines)

The hand-rolled registration it uses instead of `registerSignedInApp` (so the
test can hold its own `FakeProductRepository`, `FakeCartRepository`,
`FakeAppConfigRepository`):

```dart
  setUp(() {
    products = FakeProductRepository();
    cart = FakeCartRepository();
    appConfig = FakeAppConfigRepository();
    sl
      ..registerSingleton<AuthRepository>(
        FakeAuthRepository()..hasActiveSession = true,
      )
      ..registerSingleton<CatalogRepository>(FakeCatalogRepository())
      ..registerSingleton<AppConfigRepository>(appConfig)
      ..registerSingleton<CartRepository>(cart)
      ..registerSingleton<ChargeRulesRepository>(
        FakeChargeRulesRepository(
          rules: const ChargeRules(
            freeDeliveryThreshold: 499,
            smallCartThreshold: 199,
            smallCartCharge: 30,
            serviceabilityMode: ServiceabilityMode.allowlist,
            defaultEtaDays: 4,
          ),
        ),
      )
      ..registerSingleton<WishlistRepository>(FakeWishlistRepository())
      ..registerSingleton<LocationRepository>(FakeLocationRepository())
      ..registerSingleton<MaliCoinsRepository>(FakeMaliCoinsRepository())
      ..registerSingleton<CouponRepository>(FakeCouponRepository())
      ..registerSingleton<DeliveryRepository>(
        FakeDeliveryRepository(
          rows: {
            '411001': const ServiceablePincode(
              pincode: '411001',
              etaDays: 3,
              cod: true,
            ),
          },
        ),
      )
      ..registerSingleton<ProductRepository>(products);
    engagement = registerFakeEngagement();
    registerAuthFeature();
    registerCatalogFeature();
    registerAppConfigFeature();
    registerHomeFeature();
    registerCategoriesFeature();
    registerCartFeature();
    registerWishlistFeature();
    registerLocationFeature();
    registerSettingsFeature();
    registerMaliCoinsFeature();
    registerAccountFakes();
    registerCouponsFeature();
    registerDeliveryFeature();
    registerProductFeature();
  });
  tearDown(sl.reset);
```

Helpers: `launchHome(tester)` (view 1170×2532 @3, `router = AppRouter().router`,
`pump(SplashPage.displayDuration)`, `pumpAndSettle`, `expect(find.byType(HomePage), findsOneWidget)`),
`openProduct(tester)` (`router.pushNamed(AppRoute.productDetail.name, pathParameters: {ProductDetailPage.idParam: 'prod_01'})` then `expect(find.byKey(const Key('product_page')), findsOneWidget)`),
`pageScrollable()` (`find.descendant(of: find.byKey(const Key('product_scrollView')), matching: find.byType(Scrollable)).first`),
`scrollTo(tester, finder)` (`scrollUntilVisible(finder, 300, scrollable: pageScrollable())`).
Tests (18): card on Home opens the page; price/savings/stock/pack sizes
(`'₹269'`, `'55% OFF'`, `'You save ₹326'`, `'In Stock'`, `'12 bought'`,
`product_variant_variant_02`); picking a pack reprices (`'₹799'`, `'20% OFF'`);
Add to Cart → `product_cartStepper`, `'IN CART'`, `cart_summaryBar`, `'1 ITEM'` →
`product_cartIncrement` → `'2 ITEMS'`; the price-row `product_addButton` ↔
`product_quantityStepper` / `product_quantityIncrement` / `product_quantityDecrement`;
Add to Cart while `cart.syncGate` holds the sign-in sync open and the line survives
the merge (`'3 ITEMS'`); `cart.saveFailure` → `product_cartUpdateFailedMessage` and
the bar stays; `testDetailSoldOut` → `product_unavailable`, no add button; pincode
check (`product_pincodeField`, `product_checkPincodeButton`, `product_deliveryAnswer`,
`'Delivers by'`, `'Cash on delivery available'`); reviews summary
(`product_ratingChip`, `'(1 review)'`, `product_ratingSummary`, `'Ravi'`); writing a
review (`product_writeReviewButton`, `product_reviewStar_4`, `product_reviewForm`,
`product_submitReviewButton`; `posted.userName == 'Asha'`); a refused review →
`product_reviewFailedSheet` + `AppInfoSheet.actionKey`; app-state badges
(`product_badges`, `'Bestseller'`); the skeleton with a live back button
(`product_loadingSkeleton`, `product_backButton`, pumped by fixed durations);
the saved copy shows while loading (`products.cached = testDetail; products.gate = Completer()`);
a failed refresh keeps the saved copy (`product_refreshFailedMessage`, no
`product_retryButton`); nothing to show → `product_retryButton` and `reload_button`
retries; analytics: one `'view_item'`, `AppEvents.productView` with
`item_name`/`currency: 'INR'`/`item_id`, `AppEvents.productVariantChanged` on a pack
change and no second `view_item`.

#### `test/features/checkout/presentation/order_placed/bloc/order_placed_bloc_test.dart` (508 lines)

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

with `FakeOrdersRepository`, `FakeCheckoutRepository`,
`FakeCatalogRepository()..catalog = CatalogSnapshot(categories: const [], products: const [])`,
`now = DateTime.utc(2026, 10, 8, 10)`, `tearDown(() => bloc.close())`, and a
`start({PlacedOrder order = _placed, SavedAddress? address})` helper that adds
`OrderPlacedStarted(order:, items: const [_chilli], phone: '+919876543210', address:)`
and awaits `bloc.stream.firstWhere((s) => !s.isSearching)`. Facts pinned:
warehouse lines take the saved catalog's picture by SKU without a server call
(`catalog.catalogCalls == 0`), a missing SKU asks the server once; `place-order`
is sent with `quoteId`, the address and `QuoteItem(productId: 'variant_chilli', quantity: 2)`,
`spentCoins == 20` once recorded, `0` when the record fails or the bill has no
coins, not sent without an address; first state has `orderNumber 'KMM-10345'`,
`total 213`, `isPaid false`, `isSearching true`, the cart line and image; the
lookup by number happens once and the poll runs **4 s apart for the first minute
(15 waits) then 5 s** (`OrderPlacedBloc.earlyInterval` / `laterInterval`), gives up
after ten minutes (`15 + 108 = 123` asks) keeping the number, a failing warehouse
is re-asked and never shown; no KMM number → no lookup by number; paid online →
`isPaid true`, `orderNumber null`, `refOrderNumber null`, the record carries the
payment; ref-orders: the warehouse's order stops KO's poll
(`refLookups.length <= 5`), KO's completed `orderId 'KMM-77'` wins, pending or
number-less completed records keep polling, ten-minute cap, failing KO re-asked,
no ref id → no KO ask, a COD order with `refId: 'ref_9'` polls it and
`'KMM-10345-A'` wins over `KMM-<display_id>`.

#### `test/features/invoice/presentation/invoice/pages/invoice_page_test.dart` (169 lines)

Setup and teardown, verbatim (the plugin-channel pattern):

```dart
const MethodChannel _share = MethodChannel('dev.fluttercommunity.plus/share');
const MethodChannel _paths = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    engagement = FakeKoEngagementService();
    registerSignedInApp(engagement: engagement);
    sl.registerSingleton<SellerRepository>(FakeSellerRepository());
    registerInvoiceFeature();
    shared = [];
    temp = Directory.systemTemp.createTempSync('invoice_test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger
      ..setMockMethodCallHandler(_paths, (call) async => temp.path)
      ..setMockMethodCallHandler(_share, (call) async {
        shared.add(call);
        return 'shared';
      });
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger
      ..setMockMethodCallHandler(_paths, null)
      ..setMockMethodCallHandler(_share, null);
    temp.deleteSync(recursive: true);
    sl.reset();
  });
```

`open(tester)` pumps `App(router: router)` with `router = AppRouter().router`, then
`unawaited(router.pushNamed(AppRoute.invoice.name, extra: _invoice))`. The download
test runs the tap inside `tester.runAsync` and polls `for (var i = 0; i < 50 && shared.isEmpty; i++) await Future<void>.delayed(const Duration(milliseconds: 100));`
(real file I/O); it asserts `call.method == 'share'`, `args['title'] == 'Invoice INV-010345'`,
`args['mimeTypes'] == ['application/pdf']`, the path ends with
`'KMM-10345_08-10-2026.pdf'`, the file starts with `'%PDF-'`, and one
`AppEvents.invoiceDownloaded` was tracked. Other asserts: `invoice_number`
`'INV-010345'`, `invoice_sellerName` `'Katyayani Organics'`, `'GSTIN ${testSeller.gstin}'`,
`'MADHYA PRADESH'`, `invoice_toCollect` `'213.00'`, `invoice_total` `'₹ 213.00'`,
`invoice_amountInWords` `'Amount in words: Two Hundred Thirteen Rupees Only'`,
no `invoice_provisional`; opened without an `extra` the route redirects Home
(`find.byType(InvoicePage)` → nothing).

#### `test/features/referral/presentation/refer/pages/referral_page_test.dart` (181 lines)

`setUp`: `referral = FakeReferralRepository(); engagement = FakeKoEngagementService(); registerSignedInApp(referral: referral, engagement: engagement);`
`tearDown(sl.reset)`. Helper `tracked(String name)` returns the properties of every
`engagement.tracked` entry with that name. `openReferral(tester, {bool settle = true})`:
`launchSignedInApp` → `openAccountTab` → tap `account_referralBanner` → either
`pumpAndSettle()` or (`settle: false`, a skeleton shimmering) `pump(); pump(const Duration(milliseconds: 400));`
→ `expect(find.byKey(const Key('referral_page')), findsOneWidget)`. Tests: code
`'EE3W6A'`, rich text `'Your friend gets 100 coins'`, stats in `referral_joinedStat` /
`referral_pendingStat` / `referral_coinsEarnedStat`, `referral_pendingNote`;
`referral.gate` → `referral_skeleton`; `summaryFailure = NetworkFailure()` →
`referral_reload` whose inner `InkWell` retries; Apply disabled until text,
`ValueKey('referral_codeField_0')` + `EditableText`, code normalised to upper
case (`'ee3w6a'` → `['EE3W6A']`), `SelfReferralFailure` text
`"You can't use your own referral code."` and
`tracked(AppEvents.referralClaimFailed) == [{'code': 'EE3W6A', 'reason': 'SelfReferralFailure'}]`
(the failure **type name**, never a message); sharing: `dotenv.loadFromString(envString: 'APP_WEB_ORIGIN=https://example.com/app')`
plus a `dev.fluttercommunity.plus/share` channel mock reset in `addTearDown`, one
`AppEvents.referralCodeShared` with a non-empty `code`; an accepted `'friend1'` →
`referral_appliedSheet`, `MaliCoinsBloc` balance `150`
(`BlocProvider.of<MaliCoinsBloc>(tester.element(find.byType(MaterialApp)))`),
`referral_claimedCode`, `tracked(AppEvents.referralCodeClaimed) == [{'code': 'FRIEND1', 'bonus': 100}]`.

#### `test/core/services/analytics/meta_analytics_destination_test.dart` (73 lines)

`TestWidgetsFlutterBinding.ensureInitialized();` in a plain `test` file; the
`facebook_app_events` channel is mocked through its exported `channelName`
(`setMockMethodCallHandler(const MethodChannel(channelName), (call) async { calls.add(call); return null; })`);
`settle()` is `Future<void>.delayed(Duration.zero)`. Tests: `AppEvents.orderPlaced`
→ exactly `['logPurchase']` with `arguments['amount'] == 899.0`,
`arguments['currency'] == 'INR'`; `AppEvents.checkoutStarted` → one `logEvent` named
`'fb_mobile_initiated_checkout'` with `_valueToSum == 350.0` (the plugin's own
argument name, received on the channel); `setUserId('user-1')` then `setUserId(null)`
→ `['setUserID', 'clearUserID']`; a `PlatformException` from the channel never
reaches the caller (`meta.log(AppEvents.otpSent, null)` completes).

#### `test/features/home/presentation/home/pages/home_page_test.dart` (475 lines)

`setUp` registers by hand: `FakeAuthRepository()..hasActiveSession = true`,
`catalog = FakeCatalogRepository()`, `appConfig = FakeAppConfigRepository()`,
`cart = FakeCartRepository()`, `FakeWishlistRepository()`, `registerFakeEngagement()`,
then `registerAuthFeature(); registerCatalogFeature(); registerAppConfigFeature(); registerHomeFeature(); registerCategoriesFeature(); registerCartFeature(); registerWishlistFeature();`
then `FakeLocationRepository()` + `registerLocationFeature(); registerSettingsFeature();`
then `FakeMaliCoinsRepository()` + `registerMaliCoinsFeature(); registerAccountFakes();`
then `FakeCouponRepository()` + `registerCouponsFeature();` (`tearDown(sl.reset)`).
Helpers `launchHome(tester)` and `tapKey(tester, key)` (`ensureVisible` → `tap` →
`pumpAndSettle`). Tests: greeting `'Hi Asha'`, one rail `'Liquid Tonics'`, no
`home_categoryStrip`, `'₹269'`, `'55% OFF'`, `'12 sold'`, no `cart_summaryBar`;
`product_prod_01_add` after dragging `home_scrollView` by `-200` → `cart_summaryBar`,
`'1 ITEM'`, `cart.items.single.variantId == 'variant_01'`, increment/decrement keys;
the search bar is a `SearchTriggerBar`, not an `EditableText`, and its camera icon
changes nothing; `home_searchField` opens `CategoriesPage` with `catalog_searchField`
and `CategoriesBloc.state.isSearchVisible`, re-openable after `catalog_searchButton`
and `shell_homeTab`; `home_viewAll_Liquid Tonics` → `selectedCategoryId 'pcat_01'`;
banner carousel group (`home_bannerCarousel`, `'Monsoon sale'`, `'Shop now'`, no
`home_bannerDots` for one slide; `HomeHero` first with dots; hidden on
`appStateFailure` without `home_refreshFailedMessage` / `home_retryButton`; hidden
without a titled banner; `home_bannerSkeleton` while `catalog.gate` holds, pumped
by fixed durations; `home_banner_0` with `ctaLink: '/categories/Liquid Tonics'` →
that category; no link → the catalog); explore more group
(`home_exploreMore_Liquid Tonics` reached with `scrollUntilVisible(…, 200, scrollable: descendant of ProductRail)` then one `pump()`, `'+15 products'`; absent when the rail shows every product);
cache-first group (saved rails show while `catalog.gate` holds, no
`home_loadingSkeleton`, fresh rails replace them; `homeSectionsFailure` keeps the
saved rails with `'No internet connection. Showing saved products.'` and no
`home_retryButton`; nothing saved → `home_retryButton`, no
`home_refreshFailedMessage`); `home_themeToggle` → `ThemeBloc.state.mode == ThemeMode.dark`
and `Theme.of(...).brightness == Brightness.dark`; analytics
(`AppEvents.viewedAllProducts` with `{'seed_type': 'Liquid Tonics'}`,
`AppEvents.bannerClicked` with `{'title': 'Tonics week', 'cta_link': '/categories/Liquid Tonics'}`).

#### `test/features/wishlist/presentation/pages/wishlist_page_test.dart` (470 lines)

`setUp` registers by hand (same eight repositories as above, `wishlist`, `catalog`,
`cart` kept as locals; `registerFakeEngagement()`), `tearDown(sl.reset)`. Helpers:
`launchHome`, `tapKey`, `openWishlist` (tap `shell_wishlistTab` → `wishlist_page`),
`WishlistBloc bloc(WidgetTester tester) => BlocProvider.of<WishlistBloc>(tester.element(find.byType(Scaffold).last));`,
`bool isHeartOn(tester, key) => tester.widget<HeartToggleButton>(find.byKey(Key(key))).isActive;`,
`Badge wishlistBadge(tester) => tester.widget<Badge>(find.byKey(const Key('shell_wishlistBadge')));`,
`void saveOnDevice() { wishlist..ids = ['prod_01']..cachedIds = ['prod_01']; catalog.cachedCatalog = testCatalog; }`.
Groups: heart on a product card (`product_prod_01_wishlist`: off / on with the badge
`'1'` / tap adds then removes / fills at once with `pendingIds == {'prod_01'}` while
`toggleGate` holds and a second tap does nothing / `WishlistStorageFailure` undoes
with `wishlist_toggleFailedMessage` `"Couldn't update your wishlist. Please try again."`
/ `WishlistAuthRequiredFailure(code: 401)` → `'Please sign in again to update your wishlist.'`
and no navigation / `WishlistFullFailure` →
`'Your wishlist is full. Remove a product to save another.'`); wishlist page
(`'My Wishlist'`, `'1 item saved · hold a card to remove'`, `wishlist_item_prod_01`,
`'LIQUID TONICS'`, `'₹595'`, `wishlist_toggle_prod_01`; `wishlist_emptyState` with
`'Your wishlist is empty'` / `'Save the plants you love'` and `wishlist_browseButton`
→ `CategoriesPage`; `wishlist_loadingSkeleton` while `gate` holds (pumped by hand);
saved data shows with `isStale` true and `isRefreshing` true, then `isStale` false
and no `wishlist_refreshFailedMessage`; a failed refresh (`loadFailure` set after
open, `bloc.add(WishlistRefreshed())`) → `'No internet connection. Showing your saved wishlist.'`
and no `wishlist_retryButton`; pull-to-refresh (`fling` of `wishlist_scrollView` by
`Offset(0, 300)`, velocity 1000) adds one `loadCalls`; a failed first load →
`wishlist_retryButton` with `'No internet connection. Check your connection and try again.'`
and `reload_button` retries; the heart and a long-press remove; a refused removal
puts it back; `product_prod_01_add` → `cart_summaryBar`, `Icons.delete_outline_rounded`
at one unit; a product saved on Home shows on the page; `wishlist_backButton` goes
Home); signing out (`shell_accountTab` → scroll `account_scrollView` to
`account_footer` → `account_signOutButton` → `AppInfoSheet.actionKey`) lands on
`LoginPage` and `bloc(tester).state == WishlistState()`.

---

## Follow-up: connectivity_bloc.dart — the exclusion, stated in the inventory

Before this file the folder was covered by one row (`tests-tooling-config.md:137`:
"legacy; imports `connectivity_plus` + `internet_connection_checker`; not referenced
anywhere outside its folder") and package-table footnotes
(`tests-tooling-config.md:1776, :1803`, `networking.md:2526`, `di-bootstrap-app.md:1450`,
`data-strategies.md:3740`, `presentation-bloc-pages.md:2195`). None named the two
companion files or the §10 violations. §1.1, §2.1 and P-F1 above now hold the
three files verbatim and the eight concrete violations. For the skill:

- **Exclude** `lib/core/app/bloc/` entirely (three files: `connectivity_bloc.dart`
  134 lines, `connectivity_event.dart` 16, `connectivity_state.dart` 26).
- **Drop** `connectivity_plus` and `internet_connection_checker` from
  `pubspec.yaml`; nothing else imports them (verified by
  `grep -rn "connectivity_plus\|internet_connection_checker" lib test` → only
  `connectivity_bloc.dart`).
- **Grep-guard** for the eleven legacy names in §2.1 so a port never recreates
  them from AGENTS.md §16's mention.
- AGENTS.md §16's rationale ("creates its own dependencies, and its states are not
  `const` and leave `message` out of `props`") is confirmed by the code and is
  incomplete: the bloc is also unreferenced, skips every layer, uses
  `DateTime.now()` directly, has a concrete event base class and a misspelt event.

---

## Follow-up: shared_pref_repository.dart (complete, LEGACY — never install)

storage-secrets-cache.md §1 (line 77) and networking.md §1 (line 24) describe
`SharePrefRepo` in one line ("20 ad-hoc getters/setters"); here is the whole file,
so the exclusion is checkable and nobody rebuilds a "prefs repository" from the
description. It has **24** methods. Nothing imports it
(`grep -rn "SharePrefRepo\|shared_pref_repository" lib test` → only itself).

`lib/core/repositories/shared_pref_repository.dart`:

```dart
import 'package:mymali/core/services/pref_utils.dart';
import 'package:mymali/core/utils/string_constants.dart';

import 'base_api_repository.dart';

class SharePrefRepo extends BaseApiRepo {
  PrefUtils prefUtils = PrefUtils();
  SharePrefRepo();

  Future<String?> getUserTokenFromStorage() async {
    return await prefUtils.getString(key: StringConstants.appAuthToken);
  }

  Future<bool?> setUserTokenToStorage(String value) async {
    return await prefUtils.setString(
      key: StringConstants.appAuthToken,
      value: value,
    );
  }

  Future<bool?> setConversationWalkThrew(bool value) async {
    return await prefUtils.setBool(
      key: StringConstants.conversationWalkThrew,
      value: value,
    );
  }

  Future<bool?> getConversationWalkThrew() async {
    return await prefUtils.getBool(key: StringConstants.conversationWalkThrew);
  }

  Future<bool?> setHomeWalkThrew(bool value) async {
    return await prefUtils.setBool(
      key: StringConstants.homeWalkThrew,
      value: value,
    );
  }

  Future<bool?> getHomeWalkThrew() async {
    return await prefUtils.getBool(key: StringConstants.homeWalkThrew);
  }

  Future<bool?> deleteUserTokenFromStorage() async {
    return await prefUtils.remove(key: StringConstants.appAuthToken);
  }

  Future<bool?> setAuthTokenSocial(String idToken) async {
    return await prefUtils.setString(
      key: StringConstants.authTokenSocial,
      value: idToken,
    );
  }

  Future<bool?> setUserPhoneNumber(String phoneNumber) async {
    return await prefUtils.setString(
      key: StringConstants.userPhoneNumber,
      value: phoneNumber,
    );
  }

  Future<bool?> setUserEmail(String email) async {
    return await prefUtils.setString(
      key: StringConstants.userEmail,
      value: email,
    );
  }

  Future<bool?> setUserPassword(String password) async {
    return await prefUtils.setString(
      key: StringConstants.userPwd,
      value: password,
    );
  }

  Future<bool?> setUserName(String name) async {
    return await prefUtils.setString(
      key: StringConstants.userName,
      value: name,
    );
  }

  Future<bool?> setUsertId(String id) async {
    return await prefUtils.setString(key: StringConstants.userId, value: id);
  }

  Future<bool?> setIsUserRegistered(bool isRegistered) async {
    return await prefUtils.setBool(
      key: StringConstants.isUserRegistered,
      value: isRegistered,
    );
  }

  Future<bool?> setAppTokenIsEmpty(bool value) async {
    return await prefUtils.setBool(
      key: StringConstants.appTokenIsEmpty,
      value: value,
    );
  }

  Future<Map<String, dynamic>> getAllStoredData() async {
    return await prefUtils.getAllData();
  }

  Future<String?> getFcmToken() async {
    return await prefUtils.getString(key: StringConstants.fcmToken);
  }

  Future<bool> clearAll() async {
    return await prefUtils.clearAll();
  }

  Future<bool?> setNotificationDataFromBackground(String data) async {
    return await prefUtils.setString(
      key: StringConstants.notificationDataFromBackground,
      value: data,
    );
  }

  Future<String?> getNotificationDataFromBackground() async {
    return await prefUtils.getString(
      key: StringConstants.notificationDataFromBackground,
    );
  }

  Future<bool?> clearNotificationDataFromBackground() async {
    return await prefUtils.remove(
      key: StringConstants.notificationDataFromBackground,
    );
  }

  Future<bool> setCallNotificationSetupShown() async {
    return await prefUtils.setBool(
      key: StringConstants.askSetupCallNotification,
      value: false,
    );
  }

  Future<bool> setShowCallNotificationSetup() async {
    return await prefUtils.setBool(
      key: StringConstants.askSetupCallNotification,
      value: true,
    );
  }

  Future<bool> showCallNotificationSetup() async {
    return await prefUtils.getBool(
          key: StringConstants.askSetupCallNotification,
        ) ??
        true;
  }
}
```

The 24 methods: `getUserTokenFromStorage`, `setUserTokenToStorage`,
`setConversationWalkThrew`, `getConversationWalkThrew`, `setHomeWalkThrew`,
`getHomeWalkThrew`, `deleteUserTokenFromStorage`, `setAuthTokenSocial`,
`setUserPhoneNumber`, `setUserEmail`, `setUserPassword`, `setUserName`,
`setUsertId` (sic), `setIsUserRegistered`, `setAppTokenIsEmpty`, `getAllStoredData`,
`getFcmToken`, `clearAll`, `setNotificationDataFromBackground`,
`getNotificationDataFromBackground`, `clearNotificationDataFromBackground`,
`setCallNotificationSetupShown`, `setShowCallNotificationSetup`,
`showCallNotificationSetup`. Everything it touches that the live app does not: a
password in prefs (`setUserPassword`), a social token, "walk-through" flags, FCM
token, call-notification flags — all leftovers of the project this codebase was
started from (a CRM with calls, see `StringConstants.audioCall` / `videoCall`).

The constants it reads (`lib/core/utils/string_constants.dart`, complete; only
`appAuthToken` is live — used by `networking.dart` and `auth_local_data_source.dart`):

```dart
abstract class StringConstants {
  //SharePreferences
  static String jwtToken = "jwtToken";
  static String firebaseToken = "firebaseToken";
  static String authTokenSocial = "socialAuthToken";
  static String userName = "userName";
  static String conversationWalkThrew = "conversationWalkThrew";
  static String homeWalkThrew = "homeWalkThrew";
  static String userEmail = "userEmail";
  static String userPhoneNumber = "userPhoneNumber";

  static String userPwd = "userPwd";

  /// The signed-in user's access token, saved by `AuthLocalDataSource` and
  /// sent by `NetworkingService` as the default `Authorization` header.
  static const String appAuthToken = 'auth.access_token';
  static String appAuthResponse = "appAuthResponse";
  static String frombackgroundCall = "frombackgroundCall";
  static String frombackgroundMessage = "frombackgroundMessage";
  static String notificationDataFromBackground =
      "notificationDataFromBackground";
  static String fcmToken = "FcmToken";
  static String userId = "userId";
  static String activeClientId = "activeClientId";

  //App Preferences
  static String appTokenIsEmpty = "isAppTokenEmpty";
  static String isFirstTimeUser = "isFirstTimeUser";
  static String isUserRegistered = "isUserRegistered";

  static String audioCall = "audio_call";
  static String videoCall = "video_call";
  static String endCall = "Call Dropped";
  static String askSetupCallNotification = "ask_setup_call_notification";
  static String callAcceptedByOtherAgent = "Call Accepted By Other Agent";

  static var appVersion = "2.0.3";
}
```

For a new app the file shrinks to the one constant (networking.md §3.8 shows that
"live part"); `StringConstants.appVersion = "2.0.3"` is **not** the app's version
(`pubspec.yaml` says `1.0.1+21`; `Env.appVersion` / `package_info_plus` are the live
sources) and must not be copied.

`lib/core/services/pref_utils.dart` is the storage both the legacy facade and the
live local data sources use; it is verbatim in storage-secrets-cache.md §3.12 and
is repeated here only for the one legacy member another app drops:

```dart
  String? getUserToken() {
    return _sharedPreferences?.getString('xx-token');
  }
```

(and `getAllData()` ends in `log("ALL PREFERNECE DATA"); print(allData);` — a
`print` the analyzer flags under `flutter_lints`; keep or remove per the target
app's lint settings, but never read tokens through it).

---

## Open questions (for the orchestrator / user)

1. Should the skill *delete* `connectivity_plus` and `internet_connection_checker`
   from the target `pubspec.yaml`, or ask first (AGENTS.md §1 covers adding, not
   removing)? This file recommends dropping both with the folder.
2. Which Dart SDK floor should the skill declare? The repo pins `^3.13.4` and uses
   private named parameters, null-aware collection elements and record `.wait`;
   the older-SDK spelling of `SecureSessionStorage` is given above, the
   `optionsFor` / `kcIdentityFor` / `isPaymentCaptured` map literals would also need
   rewriting on an older SDK.
3. `FakeNetworking.noSuchMethod`: keep (AGENTS.md §14 "hand-written fakes") or
   implement `putAPICall` / `graphqlQueryCall` explicitly in the skill's copy?
4. The ~43 COPY-only widget files cannot be regenerated from any inventory; the
   skill must ship them as files. Confirm that shipping source files (and their
   26 widget tests) is acceptable for a "self-contained, shareable skill".
5. `UFFType`'s 16 dead values and the dead `*Config` classes (`SingleCheckboxConfig`,
   `CheckboxConfig`, `SwitchConfig`, `UploadConfig`, `ChatTextBoxConfig`, …): keep
   for parity with this repo, or prune in the skill with a note that AGENTS.md §13
   says new values go "at the end"?
6. `SharePrefRepo` and the non-const `StringConstants` members are dead in this
   repo too; should the skill's "legacy" list become a deletion PR here?
