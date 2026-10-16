# Inventory: presentation-bloc-pages

Area: the presentation layer of the MyMali Flutter app (`c:/Users/Katyayani/Documents/flutter/mymali`), read in full on 2026-10-14:
`lib/features/auth/presentation/**`, `lib/features/wishlist/presentation/**`, `lib/features/home/presentation/home/**`,
`lib/features/garden/presentation/**`, `lib/features/checkout/presentation/review_pay/**` (page, bloc, utils, widgets),
`lib/features/address/presentation/address_form/**`, plus every file they import from `core/` and from other features, and the
tests under `test/features/{auth,wishlist,home,garden,address,checkout}/presentation/**` and `test/helpers/`.

Legend for classification: **ALWAYS** = generic architecture, install in every app (placeholders listed);
**CONDITIONAL(x)** = install only when the target app has capability x; **MYMALI-SPECIFIC** = this app's business content.
A file marked ALWAYS whose *content* is MyMali's is ALWAYS *as a shape to copy*, with the placeholders column saying what to rename.

---

## 1. Files

### 1.1 Files in the area

| path | role | class | placeholders |
|---|---|---|---|
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | App-wide `AuthBloc`: restores the session, receives `AuthLoggedIn` from the login screen, signs out, keeps the user's profile fields in step. Takes use cases + optional `AnalyticsService`. | ALWAYS | `AppEvents.logout` event name; `RestoreSession`/`SignOut` use-case names; `AuthUser.withProfile` |
| `lib/features/auth/presentation/bloc/auth_event.dart` | Plain event classes `AuthStatusRequested`, `AuthLoggedIn(user)`, `AuthLogoutRequested`, `AuthProfileChanged({fullName, email})`. | ALWAYS | entity type `AuthUser` |
| `lib/features/auth/presentation/bloc/auth_state.dart` | Abstract-class state hierarchy (`AuthInitial`, `AuthLoading`, `Authenticated(user)`, `Unauthenticated`, `AuthFailure(message)`), each `const`, Equatable. | ALWAYS | `AuthUser` |
| `lib/features/auth/presentation/login/bloc/login_bloc.dart` | Screen bloc `LoginBloc` for the two-step name+phone / OTP form: `_send`, `_verify`, auto-submit guard `_lastSubmittedOtp`, `_withoutFailure`, `_validateOtp`. | ALWAYS as the reference *screen bloc*; CONDITIONAL(phone-OTP sign-in) as content | `otpLength = 4`, `normalizeIndianMobile`, `AppEvents.loginStarted/otpSent/otpResent/otpError/verified/login`, `'phone_otp'`, `'sms'` |
| `lib/features/auth/presentation/login/bloc/login_event.dart` | Plain events + `typedef` aliases (`FullNameChanged`, `PhoneChanged`, `SendOtpPressed`, `OtpSubmitted`); legacy `SubmissionFailed`, `ClearError`. | ALWAYS (shape) / CONDITIONAL(phone-OTP) | event names |
| `lib/features/auth/presentation/login/bloc/login_state.dart` | `LoginStep`, `LoginStatus` enums; `LoginState` with `copyWith` clearable getters, statics `countryDialCode '+91'`, `minNameLength 2`, `phoneNumberLength 10`. | ALWAYS (shape) / CONDITIONAL(phone-OTP) | `'+91'`, `2`, `10`, field names |
| `lib/features/auth/presentation/login/pages/login_page.dart` | Reference page: `LoginPage` (BlocProvider only) → `_LoginView` (StatefulWidget, `PageController`) with `MultiBlocListener` (4 listeners, precise `listenWhen`), `PopScope`, `AnnotatedRegion`, `_StepPage` keep-alive. Verify failure shown with `showDialog`/`AlertDialog` (legacy, AGENTS §22). | ALWAYS (shape) / CONDITIONAL(phone-OTP) | `AppRoute.home`, text `'OTP sent to …'`, 380 ms animation |
| `lib/features/auth/presentation/login/utils/failure_message.dart` | `friendlyMessageFor(Failure)` → String; `verifyFailureText(Failure)` → `(String, String)` record. Maps failure **types** with `switch` patterns. | ALWAYS (pattern) | the feature's `Failure` subclasses and texts |
| `lib/features/auth/presentation/login/widgets/login_details_step.dart` | Step 1 body: headline, `NameField`, `PhoneNumberField`, `PrimaryButton(key: Key('login_getOtpButton'))` with `context.select` for `isLoading`/`canSubmit`. Uses `gap`. | CONDITIONAL(phone-OTP) | copy, keys |
| `lib/features/auth/presentation/login/widgets/login_otp_step.dart` | Step 2 body: `OtpCodeField`, `ResendCountdown(key: ValueKey(requestCount))`, `LoginErrorBanner`, verify `PrimaryButton`, `TextButton` "Edit". | CONDITIONAL(phone-OTP) | copy, keys |
| `lib/features/auth/presentation/login/widgets/login_header.dart` | Brand header above the sheet; shrinks when keyboard open; shows back `IconButton.filledTonal(key: Key('login_backButton'))` on OTP step. Contains hardcoded `Colors.white`, `fontSize: 26/14` (rule deviation). | MYMALI-SPECIFIC (branding) | all |
| `lib/features/auth/presentation/login/widgets/login_error_banner.dart` | Legacy error banner reading `state.errorMessage` (AGENTS §16 says keep, don't copy). | legacy, do not install | — |
| `lib/features/auth/presentation/login/widgets/name_field.dart` | Field wrapper: `KeyedSubtree(key: Key('login_nameField'))` + `UniversalFormField(UFFType.text, initialValue: '')` + `errorText` via `context.select`. | ALWAYS (pattern) | label/hint/key |
| `lib/features/auth/presentation/login/widgets/phone_number_field.dart` | Field wrapper for `UFFType.phone` with `initialCountryCode: 'IN'`, `lockCountryCode: true`, `_IndianMobileFormatter` (`TextInputFormatter`). | CONDITIONAL(phone input) | `'IN'`, normaliser |
| `lib/features/auth/presentation/login/widgets/otp_code_field.dart` | Field wrapper for `UFFType.otp`; outer `KeyedSubtree(Key('login_otpField'))`, inner `KeyedSubtree(ValueKey(requestCount))` resets the boxes. | CONDITIONAL(OTP) | `LoginBloc.otpLength` |
| `lib/features/auth/presentation/login/widgets/otp_field.dart` | Unused legacy text-OTP field (AGENTS §16). | legacy, do not install | — |
| `lib/features/auth/presentation/login/widgets/resend_countdown.dart` | `ResendCountdown({required onResend, duration = 60 s})` StatefulWidget with `Timer.periodic`; restarted by giving it a new key. | CONDITIONAL(OTP) | 60 s, copy |
| `lib/features/auth/presentation/splash/pages/splash_page.dart` | `SplashPage` StatefulWidget: `context.read<AuthBloc>()..add(AuthStatusRequested())` in `initState`, `Timer(displayDuration)` then `goNamed(home|login)` after `stream.firstWhere(_isResolved)`; `_Entrance` animation; `LoadingAnimationWidget.staggeredDotsWave`. | ALWAYS (shape) | `displayDuration = 2600 ms`, `BrandMark`, `loading_animation_widget`, `AppRoute.home/login` |
| `lib/features/auth/presentation/widgets/brand_backdrop.dart` | Brand-green backdrop with decorative circles (feature-shared widget). | MYMALI-SPECIFIC | — |
| `lib/features/auth/presentation/widgets/brand_mark.dart` | `BrandMark({tileSize = 96})` with `tagline = 'Plants & garden care, delivered'`, `BrandLogoTile({size})` over `AppLogo(asset: AppAssets.appLogo)`. Hardcoded `Colors.white/black`, `fontSize`. | MYMALI-SPECIFIC | — |
| `lib/features/wishlist/presentation/bloc/wishlist_bloc.dart` | App-wide, user-scoped, device-first `WishlistBloc`: `_session` counter, `_userId`, `_reset`, `_showSaved` (stale), `_refresh` (`isBusy` guard), `_onToggled` optimistic update + rollback + `unawaited(push)`, `_loadCatalog`, `_ensureCatalogHas`, `_keepPending`. | CONDITIONAL(app has a user-owned list synced device-first) ; ALWAYS as the pattern for an app-wide user-scoped bloc | `AppEvents.addToFavorite/removeFromFavorite`, `'item_id'`, catalog use cases |
| `lib/features/wishlist/presentation/bloc/wishlist_event.dart` | `WishlistStarted(userId)`, `WishlistRefreshed`, `WishlistToggled(productId)`, `WishlistCleared`. | ALWAYS (shape of Started/Refreshed/Cleared) | names |
| `lib/features/wishlist/presentation/bloc/wishlist_state.dart` | `WishlistStatus`; **non-const** `WishlistState` whose constructor derives `ids` and `products`; `isStale`, `isRefreshing`, `failure`, `toggleFailure`, `pendingIds`; `isBusy`, `count`, `contains`, `categoryNameOf`. | CONDITIONAL / ALWAYS (shape) | catalog types |
| `lib/features/wishlist/presentation/pages/wishlist_page.dart` | Reference *tab page* with no own bloc: `BlocListener` (refresh-failure SnackBar) → `Scaffold(key: 'wishlist_page')` → header + `_WishlistBody` (`RefreshIndicator` + `CustomScrollView` + `switch (status)` sliver) + `CartBarOverlay`; `_WishlistFailure` → `ReloadWidget`. | ALWAYS (shape) | route names, keys, texts |
| `lib/features/wishlist/presentation/utils/failure_message.dart` | Three helpers: `wishlistFailureMessage`, `wishlistRefreshFailureMessage`, `wishlistToggleFailureMessage` (all `Failure?`). | ALWAYS (pattern) | failure types, texts |
| `lib/features/wishlist/presentation/widgets/wishlist_empty_state.dart` | Empty state: `CustomPaint` illustration + title in `AppTheme.displayFontFamily` + `PrimaryButton(expand: false, height: 48, leadingIcon)`. | ALWAYS (shape) / MYMALI (illustration) | copy, painter |
| `lib/features/wishlist/presentation/widgets/wishlist_header.dart` | `WishlistHeader({itemCount, onBack})` wraps `PageHeader` (title, subtitle, `subtitleKey`, `backKey`, `trailing`). | ALWAYS (pattern) | texts, keys |
| `lib/features/wishlist/presentation/widgets/wishlist_loading_skeleton.dart` | `Skeletonizer.sliver` over 4 real `ProductListTile`s; statics `spacing = 13`, `padding = EdgeInsets.fromLTRB(16, 24, 16, 0)` shared with the loaded list. | ALWAYS (pattern) / CONDITIONAL(product tiles) | tile widget |
| `lib/features/wishlist/presentation/widgets/wishlist_product_tile.dart` | Feature widget wrapping generic `ProductListTile`, reading `CartBloc` and `WishlistBloc` with `context.select`, dispatching `CartItemAdded/Incremented/Decremented`, `WishlistToggled`. | ALWAYS (pattern "feature widget wraps generic") / CONDITIONAL(cart+wishlist) | — |
| `lib/features/home/presentation/home/bloc/home_bloc.dart` | Cache-first screen bloc `HomeBloc` (AGENTS §20 recipe): `HomeStarted({language})`, `HomeRefreshed({language})`, `_showCached`, `_refresh(forceRefresh:)`, parallel `.wait`, "decorations that fail keep what is on screen". | ALWAYS (pattern) / CONDITIONAL(caches server data) | 7 use cases, `imageBaseUrl`, `buildHomeBanners` |
| `lib/features/home/presentation/home/bloc/home_event.dart` | `HomeStarted({language})`, `HomeRefreshed({language})`. | ALWAYS (shape) | `language` |
| `lib/features/home/presentation/home/bloc/home_state.dart` | `HomeStatus` + const `HomeState` with `isStale`, `isRefreshing`, `failure`, `isLoading`, `isBusy`, clearable `copyWith`. | ALWAYS (shape) | data fields |
| `lib/features/home/presentation/home/pages/home_page.dart` | `HomePage`: `BlocProvider(create: (context) => sl<HomeBloc>()..add(HomeStarted(language: WidgetsBinding.instance.platformDispatcher.locale.languageCode)))`; `_HomeView` with refresh-failure `BlocListener`, `RefreshIndicator`, `CustomScrollView` + `switch (status)`, banner tap via `url_launcher`, analytics from tap handlers. | ALWAYS (shape) / MYMALI content | `AppRoute.categories`, `CategoriesPage.*Param`, `AppEvents.cameraSearchTapped/bannerClicked`, hint text |
| `lib/features/home/presentation/home/utils/failure_message.dart` | `homeFailureMessage(Failure?)`, `refreshFailureMessage(Failure?)`. | ALWAYS (pattern) | texts |
| `lib/features/home/presentation/home/widgets/home_banner_carousel.dart` | `HomeBannerCarousel({banners, onBannerTap, autoAdvanceEvery = 5 s})`: `PageView.builder`, auto-advance `Timer`, dots; statics `horizontalPadding 16`, `topPadding 16`, `cardRadius 24`, `dotsHeight 18`, `cardHeightFor`, `heightFor`. | CONDITIONAL(promo banners) | sizes |
| `lib/features/home/presentation/home/widgets/home_loading_skeleton.dart` | `Skeletonizer.sliver` of real `SectionHeader` + `ProductRail` of `ProductCard`s, **plus one `Bone(...)`** for the banner (rule deviation, see §4). | ALWAYS (pattern) | counts 2×3 |
| `lib/features/home/presentation/home/widgets/home_section_view.dart` | One rail: `SectionHeader(actionKey: Key('home_viewAll_${section.title}'))`, `ProductRail(key: PageStorageKey('home_rail_…'))` of `CatalogProductCard`, `ExploreMoreCard`; reads `HomeBloc` with `context.select`; tracks `AppEvents.viewedAllProducts`. | MYMALI-SPECIFIC (pattern: section widget reading its screen bloc) | — |
| `lib/features/home/presentation/home/widgets/push_permission_prompt.dart` | `PushPermissionPrompt({child})`: invisible StatefulWidget; `static bool _asked`, `settleDelay 1 s`, `locationWait 30 s`, `@visibleForTesting resetForTest()`; waits for `LocationBloc` to stop detecting, then `KoEngagementService.registerPush()`. | MYMALI-SPECIFIC (Katyayani Core); shape reusable for "ask once per launch" | — |
| `lib/features/home/presentation/home/widgets/home_header.dart` | Greeting header reading `AuthBloc` (`switch` on `Authenticated(:final user)`), `LocationBloc`, `ThemeBloc`; `CircleIconButton`s; `pushNamed` to notifications/location/coins. | MYMALI-SPECIFIC (pattern: `context.select` with a type switch) | — |
| `lib/features/garden/presentation/bloc/garden_bloc.dart` | Smallest bloc: `GardenBloc()` with no dependencies; two sync handlers. | ALWAYS (reference "small bloc") / MYMALI content | names |
| `lib/features/garden/presentation/bloc/garden_event.dart` | `GardenFeatureToggled(feature)`, `GardenWaitlistJoined`. | MYMALI (shape ALWAYS) | — |
| `lib/features/garden/presentation/bloc/garden_state.dart` | `const GardenState({picked = const {}, isOnWaitlist = false})` + simple `copyWith`. | MYMALI (shape ALWAYS) | — |
| `lib/features/garden/presentation/pages/garden_home_page.dart` | Reference for `AppInfoSheet.show` from a `BlocListener` with `listenWhen: !previous.isOnWaitlist && current.isOnWaitlist`; analytics in the listener. | ALWAYS (pattern) | copy, `AppEvents.gardenWaitlistJoined` |
| `lib/features/garden/presentation/widgets/garden_feature_card.dart` | Selectable card (`Semantics(checked:)`, `_Tick`). | MYMALI-SPECIFIC | — |
| `lib/features/garden/presentation/widgets/garden_feature_poll.dart` | Two-column grid of cards; `_textFor(GardenFeature)` record switch. | MYMALI-SPECIFIC | — |
| `lib/features/garden/presentation/widgets/garden_hero.dart` | Hero with `CustomPainter` plant. | MYMALI-SPECIFIC | — |
| `lib/features/address/presentation/address_form/bloc/address_form_bloc.dart` | Form bloc: `AddressFormStarted` builds a new `SavedAddress(id: 'addr_<ms>')` or normalises the edited one; `seed`/`revision`; `_onFieldChanged` switch over `AddressFormField`; `_onLocateRequested`; `_onSubmitted` validates (`showErrors`), trims, saves. Injected clock `DateTime Function() now`. | ALWAYS (pattern: long form bloc) / CONDITIONAL(addresses) | `'addr_'`, `AddressLabels`, `normalizeIndianMobile`, `matchIndianState` |
| `lib/features/address/presentation/address_form/bloc/address_form_event.dart` | `enum AddressFormField` (11 fields) + `AddressFormStarted({address, contactName='', contactPhone='', makeDefault=false})`, `AddressFormFieldChanged(field, value)`, `AddressFormLabelChanged(label)`, `AddressFormLocateRequested`, `AddressFormSubmitted`. | ALWAYS (pattern: one `FieldChanged(field, value)` event) | field list |
| `lib/features/address/presentation/address_form/bloc/address_form_state.dart` | `AddressFormStatus {editing, saving, saved}`; state with `address`, `seed`, `revision`, `isNew`, `showErrors`, `isLocating`, `locateFailure`, `saveFailure`; `problems` from domain `addressProblems`, `shows(problem)`. | ALWAYS (pattern) | domain validation |
| `lib/features/address/presentation/address_form/pages/address_form_page.dart` | `AddressFormArgs` (route `extra`); `AddressFormPage` reads `AuthBloc` in `build` to seed the bloc; `MultiBlocListener`: saved → analytics + `_close(context, state.address)` (`context.pop(saved)` or `goNamed` fallback); `saveFailure` → `AppInfoSheet` with "Try again" retry; `locateFailure` → `AppInfoSheet` with icon override. `_SaveBar` pinned. | ALWAYS (pattern) | copy, `AppEvents.addressAdded/addressChanged`, `AppRoute.savedAddresses` |
| `lib/features/address/presentation/address_form/widgets/address_form_fields.dart` | The long form: filled `IconListTile`, `FormSectionTitle`s, `_SeededField` (outer `Key('addressForm_<name>Field')`, inner `ValueKey('addressForm_<name>_<revision>')`), `_AddressTextField`, `_PhoneField`, `_StateField` (dropdown), `_CountryField` (read-only), `_LabelField` (`UFFType.choiceChips`). | ALWAYS (pattern) / MYMALI labels | labels, `indianStates`, `AddressLabels.all`, `addressLabelIcon` |
| `lib/features/address/presentation/address_form/widgets/address_form_header.dart` | `AddressFormHeader({isNew, onBack})` → `PageHeader`. | ALWAYS (pattern) | texts |
| `lib/features/checkout/presentation/review_pay/pages/review_pay_page.dart` | Reference *composing* page: `BlocProvider(create:)` reads `CartBloc`/`CouponBloc` state; `MultiBlocListener` with 12 listeners (finish, failure sheet with next-step action, forward `CartBloc`/`CouponBloc` changes as `ReviewPayCartChanged`/`ReviewPayCouponChanged`, SnackBar notes, `MaliCoinsBalanceChanged` upstream); `PopScope(canPop: !isPlacing)`, `AbsorbPointer`, overlay in `Stack`; `const String placingOrderNote`. | ALWAYS (shape) / MYMALI content | everything textual, bloc names |
| `lib/features/checkout/presentation/review_pay/bloc/review_pay_bloc.dart` | Page bloc owning the server bill: `_request` counter drops stale quotes; `_cancelRequested` flag; inline `on<>` lambdas for trivial handlers; `Future.wait` on start; best-effort `_loadExtras`; address choice; `_onOrderRequested` with `switch (paymentMethod)`. | MYMALI-SPECIFIC (checkout); patterns ALWAYS | — |
| `lib/features/checkout/presentation/review_pay/bloc/review_pay_event.dart` | 10 plain events incl. `ReviewPayStarted({required items, required subtotal, coupon})`, `ReviewPayOrderRequested({required phone, required userKey, fullName, email})`. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/bloc/review_pay_state.dart` | `enum OnlinePaymentPhase {preparing, paying, placing}`; 20-field const state; getters `unlockedCoupon`, `nextCoupon`, `coinsAvailable`, `coinsApplied`, `canRedeemCoins`, `canPay`. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/utils/charge_notes.dart` | `deliveryChargeNote`, `smallCartFeeNote`, `codChargeNote` built from `ChargeRules`. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/utils/payment_gate_texts.dart` | `paymentGateTitle(phase)`, `paymentGateBody(phase, {total})`, `paymentGateCancelLabel`. | MYMALI-SPECIFIC (pattern: enum → text helpers in `utils/`) | — |
| `lib/features/checkout/presentation/review_pay/utils/payment_method_text.dart` | `paymentMethodLabel`, `paymentMethodDescription(method, {codCharge})`, `paymentMethodIcon`. | MYMALI-SPECIFIC (pattern) | — |
| `lib/features/checkout/presentation/review_pay/utils/place_order_failure_message.dart` | `placeOrderFailureTitle`, `isPlaceOrderCancellation`, `placeOrderFailureMessage(failure, {items})` with field patterns (`OrderAddressFailure(:final issue)`, `PaymentCancelledFailure(upiTimeout: true)`), falls back to `quoteFailureMessage`. | ALWAYS (pattern: title+message helpers) / MYMALI content | — |
| `lib/features/checkout/presentation/review_pay/utils/quote_failure_message.dart` | `quoteFailureMessage(Failure?, {items})`; `_unavailableMessage` list-pattern switch. | MYMALI-SPECIFIC (pattern) | — |
| `lib/features/checkout/presentation/review_pay/utils/checkout_analytics.dart` | `paymentMethodName`, `paymentTypeName`, `failureReasonName(failure)` (`runtimeType.toString()` fallback). | MYMALI-SPECIFIC / CONDITIONAL(analytics) | — |
| `lib/features/checkout/presentation/review_pay/widgets/review_pay_analytics.dart` | `ReviewPayAnalytics({child})`: invisible StatefulWidget wrapping a `MultiBlocListener` that reports analytics once (`_billReported`). | ALWAYS (pattern) / CONDITIONAL(analytics) | event names |
| `lib/features/checkout/presentation/review_pay/widgets/review_pay_header.dart` | `ReviewPayHeader({itemCount, onBack})` → `PageHeader(trailing: InfoChip)`. | ALWAYS (pattern) | texts |
| `lib/features/checkout/presentation/review_pay/widgets/review_pay_bar.dart` | Bottom bar: method picker tile + `SlideActionButton(prefixLabel, label, onPressed, isLoading)`; `note`. | MYMALI-SPECIFIC / CONDITIONAL(checkout) | — |
| `lib/features/checkout/presentation/review_pay/widgets/payment_gate_overlay.dart` | `ModalBarrier(dismissible: false)` + `AppCard` + `ProgressIndecator` + conditional destructive `SecondaryButton`. | CONDITIONAL(payments) | — |
| `lib/features/checkout/presentation/review_pay/widgets/payment_method_sheet.dart` | `showPaymentMethodSheet(context, {required total, required selected, codCharge = 0}) → Future<PaymentMethod?>` via `AppPickerSheet.show<T>`; `OptionTile`s pop the value. | ALWAYS (pattern: sheet helper) / MYMALI content | — |
| `lib/features/checkout/presentation/review_pay/widgets/delivery_address_sheet.dart` | `DeliveryAddressPick.saved(address)` / `.addNew()` result class; `showDeliveryAddressSheet(context, {required addresses, required selected})`; `DashedOutlineButton` + `OptionTile`s. | ALWAYS (pattern: typed sheet result) / CONDITIONAL(addresses) | — |
| `lib/features/checkout/presentation/review_pay/widgets/delivery_address_card.dart` | `DeliveryAddressCard({address, onChange})` on `CartSectionCard`. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/widgets/bill_details_card.dart` | `BillDetailsCard({quote, rules, isLoading, failureMessage, onRetry})` StatefulWidget (note toggles); grid constants `iconSize 18`, `iconGap 10`, `textInset`. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/widgets/coupon_nudge_banner.dart` | `CouponNudgeBanner({opportunity, subtotal, onApply})`. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/widgets/gstin_row.dart` | `GstinRow({onTap, gstin, onRemove})` of `IconListTile`s. | MYMALI-SPECIFIC | — |
| `lib/features/checkout/presentation/review_pay/widgets/mali_coins_row.dart` | `MaliCoinsRow({balance, minOrder, canRedeem, coinsApplied, isBusy, onToggle})`. | MYMALI-SPECIFIC | — |

### 1.2 Files read for context (owned by other areas; what this area relies on)

| path | role | class |
|---|---|---|
| `lib/app/app.dart` | `App({router})`: `MultiBlocProvider` of the app-wide blocs (`AuthBloc`, `ThemeBloc`, `CartBloc` lazy:false, `WishlistBloc`, `LocationBloc`, `MaliCoinsBloc`, `ProfileBloc`, `CouponBloc` lazy:false) + `RepositoryProvider<KoEngagementService>`, `RepositoryProvider<AnalyticsService>`; `MultiBlocListener` wiring sign-in/out to every user-scoped bloc; `MaterialApp.router`; `maxTextScaleFactor = 1.1`. | ALWAYS (list of blocs varies) |
| `lib/core/di/injection_container.dart` | `final GetIt sl`; `configureDependencies()`; `register<Feature>Feature()` functions; blocs `registerFactory`, everything else `registerLazySingleton`. | ALWAYS |
| `lib/core/router/app_routes.dart` | `enum AppRoute { splash('/splash'), login('/login'), home, categories, garden, wishlist, account, cart, selectLocation, coins, reviewPay, orderPlaced, invoice, applyCoupon, savedAddresses, addressForm, editProfile, referral, gstClaims, notifications, helpSupport, productDetail('/product/:id'), myOrders, orderDetails('/orders/:id') }` with `final String path`. | ALWAYS (values vary) |
| `lib/core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics})`, `late final GoRouter router`, `StatefulShellRoute.indexedStack` of 5 branches, root-navigator full-screen routes, `redirect` guards for `extra`-only routes, `AddressFormArgs` decoding. | ALWAYS |
| `lib/core/router/navigator_keys.dart` | `rootNavigatorKey`, `homeNavigatorKey`, `categoriesNavigatorKey`, `gardenNavigatorKey`, `wishlistNavigatorKey`, `accountNavigatorKey`. | ALWAYS (tab names vary) |
| `lib/core/router/analytics_screen_tracker.dart` | `analyticsScreenNames` map, `analyticsTabs`, `AnalyticsScreenTracker`, `AnalyticsRouteObserver`. Pages never call `screenView`. | CONDITIONAL(analytics) |
| `lib/core/app/failure.dart` | `Failure({required message, int? code})` (not Equatable), `NetworkFailure`, `ServerFailure({required errorCode, …})`, `CacheMissFailure`. | ALWAYS |
| `lib/core/usecases/usecase.dart` | `abstract interface class UseCase<T, Params> { Future<Either<Failure, T>> call(Params params); }`, `class NoParams extends Equatable`. | ALWAYS |
| `lib/core/widgets/sheets/app_info_sheet.dart` | `AppInfoSheetTone {info, success, error}`; `AppInfoSheet.show(context, {required title, required message, tone, icon, actionLabel = 'Got it', Key? key}) → Future<bool>`; `actionKey = Key('appInfoSheet_actionButton')`, `closeKey = Key('appInfoSheet_closeButton')`. | ALWAYS |
| `lib/core/widgets/sheets/app_picker_sheet.dart` | `AppPickerSheet({title, icon, child, footer, onClose})`; `static Future<T?> show<T>(context, {required WidgetBuilder builder})` (root navigator, `isScrollControlled`, drag handle); `closeKey = Key('appPickerSheet_closeButton')`. | ALWAYS |
| `lib/core/widgets/page_header.dart` | `PageHeader({required title, required onBack, subtitle, subtitleKey, backKey, backTooltip = 'Back', trailing, bottom})`; `contentHeightFor(context)`. | ALWAYS |
| `lib/core/widgets/reload_widget.dart` | `ReloadWidget({required errorMessage, required onReload, color})`; its retry `IconButton` has fixed `Key('reload_button')`. | ALWAYS |
| `lib/core/services/analytics/analytics_service.dart` | `abstract interface class AnalyticsService` (`track`, `screenView`, `viewItem`, `addToCart`, `removeFromCart`, `viewCart`, `beginCheckout`, `purchase`, `search`, `login`, `addPaymentInfo`, `capturePayment`, `setUserId`, `requestTrackingPermission`, `checkNudges`). | CONDITIONAL(analytics) |
| `lib/core/services/analytics/app_events.dart` | `abstract final class AppEvents` with `static const String` names (RN app's words). | CONDITIONAL(analytics) (values MYMALI) |
| `lib/core/services/katyayani_core/ko_engagement_service.dart` | `KoEngagementService` (`init`, `identify`, `resetIdentity`, `requestPushPermission`, `registerPush`, analytics methods). | MYMALI-SPECIFIC |
| `lib/core/widgets/form_helper/universal_form_field.dart`, `field_config.dart` | `UniversalFormField({key, updateKey, required fieldType, required label, initialValue, required onChanged, validator, controller, hide, fullWidth, useController, withTitle, labelStyle}).build({textInputConfig, dropdownConfig, …, otpConfig, choiceChipsConfig, ratingConfig})`; `UFFType`, `TextInputConfig`, `OtpConfig`, `DropdownConfig`, `DropdownOption`, `ChoiceChipsConfig`, `ChoiceChipOption`. | ALWAYS |
| `lib/core/utils/currency_format.dart` | `formatRupees(num)` via `intl` `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)`. | CONDITIONAL(money) (locale MYMALI) |
| `lib/features/cart/presentation/bloc/{cart_bloc,cart_event,cart_state}.dart` | App-wide `CartBloc` (serialised handlers `_serial`; `CartStarted`, `CartSignedIn`, `CartSyncFinished`, `CartSignedOut`, `CartItemAdded(item, {maxQuantity})`, `CartItemIncremented`, `CartItemDecremented`, `CartItemRemoved`, `CartItemsRemoved(variantIds)`, …); `CartState.quantityOf`, `totalQuantity`, `subtotal`, `thumbnails`. | CONDITIONAL(cart) |
| `lib/features/coupons/presentation/bloc/{coupon_bloc,coupon_event,coupon_state}.dart` | App-wide `CouponBloc`: `CouponApplied(code)`, `CouponRemoved`, `CouponCartChanged(subtotal)`, `CouponDroppedByServer(warning)`, `CouponCleared`, `CouponFailureDismissed`; state `applied`, `isApplying`, `failure`, `serverWarning`, `subtotal`. | MYMALI-SPECIFIC |
| `lib/features/mali_coins/presentation/bloc/*` | App-wide `MaliCoinsBloc`: `MaliCoinsStarted`, `MaliCoinsBalanceChanged(balance)`, `MaliCoinsSpent(coins)`, `MaliCoinsCleared`; `MaliCoinsState({balance})`. | MYMALI-SPECIFIC |
| `lib/features/location/presentation/bloc/*` | App-wide `LocationBloc`: `LocationStarted`, `LocationPlaceSelected(place)`, `LocationCleared`; `LocationState({place, isDetecting})`. | CONDITIONAL(location) |
| `lib/features/settings/presentation/bloc/*` | `ThemeBloc()`: `ThemeModeToggled({required isDark})`, `ThemeModeChanged(mode)`; `ThemeState({mode = ThemeMode.system})`. | ALWAYS |
| `lib/features/home/presentation/widgets/app_shell_scaffold.dart`, `app_bottom_nav_bar.dart` | `AppShellScaffold({navigationShell, onTabSelected})` with the wishlist toggle-failure `BlocListener`; `AppBottomNavBar` tab keys `Key('shell_${id}Tab')`, `Key('shell_${id}Badge')`. | ALWAYS (shape) |
| `lib/features/catalog/presentation/widgets/catalog_product_card.dart` | `CatalogProductCard({product, soldCount, lowStockThreshold, onOpened})` wraps generic `ProductCard` (the AGENTS §21 example). | CONDITIONAL(catalog) |
| `lib/features/catalog/presentation/categories/pages/categories_page.dart` | `static const String categoryParam = 'category'`, `stockParam = 'stock'`, `searchParam = 'search'`; `static String newSearchRequest()`. | pattern ALWAYS |
| `lib/features/product/presentation/product_detail/pages/product_detail_page.dart` | `static const String idParam = 'id'`; `static void open(BuildContext context, String productId)` → `context.pushNamed(AppRoute.productDetail.name, pathParameters: {idParam: productId})`. | pattern ALWAYS |
| `lib/features/checkout/presentation/order_placed/pages/order_placed_page.dart` | `class OrderPlacedArgs { const OrderPlacedArgs({required order, items = const [], address, gstin}); }`; `@visibleForTesting static final Set<String> reportedOrders`. | pattern ALWAYS |
| `lib/features/gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart` | `showGstinSheet(context, {required userKey}) → Future<Gstin?>`: `AppPickerSheet.show<Gstin>` whose builder returns `BlocProvider<GstinSheetBloc>(create: (_) => sl<GstinSheetBloc>(), child: _GstinSheet(...))`; `const Duration gstinSheetCloseDelay = 650 ms`. | pattern ALWAYS (sheet with its own bloc) |
| `lib/features/cart/presentation/widgets/cart_bar_overlay.dart` | `CartBarOverlay` with `static const double height`; placed last in a page `Stack`. | CONDITIONAL(cart) |
| `lib/features/cart/presentation/cart/widgets/cart_section_card.dart` | `CartSectionCard({child})`, `CartRowDivider`. | MYMALI (should be an `AppCard` per AGENTS §21) |
| `lib/features/coupons/presentation/widgets/coupon_row.dart`, `utils/coupon_failure_message.dart` | `CouponRow({coupon, onView, onRemove})`; `couponFailureMessage(Failure)`. | MYMALI-SPECIFIC |
| `lib/features/address/presentation/utils/address_failure_message.dart`, `address_label_icon.dart` | `addressesLoadFailureMessage`, `addressesRefreshFailureMessage`, `addressSaveFailureMessage`, `addressRemoveFailureMessage`, `addressProblemMessage(AddressProblem)`; `addressLabelIcon(label)`. | ALWAYS (pattern) |
| `lib/features/location/presentation/select_location/utils/failure_message.dart` | `placeSearchFailureMessage`, `locateFailureTitle`, `locateFailureMessage` (pattern `LocationPermissionDeniedFailure(isPermanent: true)`), `addressesFailureMessage`, `addressesRefreshFailureMessage` (duplicated from address utils). | CONDITIONAL(location) |
| domain files: `auth_user.dart`, `auth_session.dart`, `otp_request.dart`, `verify_otp_request.dart`, `auth_failures.dart`, `wishlist_failures.dart`, `wishlist_products.dart`, `home_banner.dart`, `banner_target.dart`, `build_home_banners.dart`, `garden_feature.dart`, `address_labels.dart`, `address_validation.dart`, `address_failures.dart`, `indian_states.dart`, `phone_normalizer.dart`, `saved_address.dart`, `checkout_failures.dart`, `location_failures.dart`, `payment_method.dart` | Entities, failures and pure helpers the presentation layer maps to text. | per feature |
| tests: `test/features/auth/presentation/bloc/auth_bloc_test.dart`, `auth_login_analytics_test.dart`, `login/bloc/login_bloc_test.dart`, `test/features/wishlist/presentation/bloc/wishlist_bloc_test.dart`, `wishlist_bloc_analytics_test.dart`, `pages/wishlist_page_test.dart`, `test/features/home/presentation/home/bloc/home_bloc_test.dart`, `pages/home_page_test.dart`, `widgets/home_loading_skeleton_test.dart`, `widgets/home_banner_carousel_test.dart`, `test/features/garden/presentation/bloc/garden_bloc_test.dart`, `pages/garden_home_page_test.dart`, `test/features/address/presentation/address_form/bloc/address_form_bloc_test.dart`, `test/features/checkout/presentation/review_pay/{pages/review_pay_page_test,bloc/review_pay_bloc_test,utils/*_test,widgets/*_test}.dart`, `test/helpers/{signed_in_app,fake_ko_engagement_service,fake_auth_repository,fake_wishlist_repository,fake_catalog_repository,fake_account_repository}.dart` | How the area is tested (see §3 P29). | ALWAYS (shape) |

### 1.3 Feature folder layout observed

```
lib/features/<feature>/presentation/
├── bloc/                 # ONLY for an app-wide bloc (AuthBloc, WishlistBloc, CartBloc, CouponBloc, MaliCoinsBloc, LocationBloc, ThemeBloc, ProfileBloc)
│   ├── <x>_bloc.dart     # exports the two files below
│   ├── <x>_event.dart
│   └── <x>_state.dart
├── <screen>/             # one folder per screen: login, splash, home, address_form, review_pay, order_placed, select_location, gstin_sheet…
│   ├── bloc/             # the screen bloc (LoginBloc, HomeBloc, AddressFormBloc, ReviewPayBloc) – same three files
│   ├── pages/            # <screen>_page.dart: XPage (BlocProvider) + private _XView
│   ├── widgets/          # widgets of that screen only (steps, fields, header wrapper, skeleton, cards, sheets)
│   └── utils/            # failure_message.dart and other pure text helpers (<x>_texts.dart, charge_notes.dart)
├── widgets/              # widgets shared by the feature's screens (auth: brand_backdrop, brand_mark; home: app_shell_scaffold, app_bottom_nav_bar; cart: cart_bar_overlay; coupons: coupon_row)
└── utils/                # feature-wide presentation helpers (address: address_failure_message.dart, address_label_icon.dart; coupons: coupon_label.dart, coupon_failure_message.dart)
```

Single-screen features flatten the `<screen>` level: `wishlist/presentation/{bloc,pages,widgets,utils}` and
`garden/presentation/{bloc,pages,widgets}` sit directly under `presentation/` (the wishlist's `bloc/` is also its
app-wide bloc). The address form keeps `presentation/address_form/{bloc,pages,widgets}` and puts the shared text helpers
in `presentation/utils/`. Test files mirror `lib/` exactly (`test/features/home/presentation/home/bloc/home_bloc_test.dart`).

---

## 2. Names

Every public name another app must reproduce exactly. "Shape" quotes the declaration as written in the repo.

### 2.1 Auth presentation

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `AuthEvent` | abstract class | `auth/presentation/bloc/auth_event.dart` | `abstract class AuthEvent {}` |
| `AuthStatusRequested` | event | same | `class AuthStatusRequested extends AuthEvent {}` |
| `AuthLoggedIn` | event | same | `class AuthLoggedIn extends AuthEvent { AuthLoggedIn(this.user); final AuthUser user; }` |
| `AuthLogoutRequested` | event | same | `class AuthLogoutRequested extends AuthEvent {}` |
| `AuthProfileChanged` | event | same | `class AuthProfileChanged extends AuthEvent { AuthProfileChanged({this.fullName, this.email}); final String? fullName; final String? email; }` |
| `AuthState` | abstract state | `auth/presentation/bloc/auth_state.dart` | `abstract class AuthState extends Equatable { const AuthState(); @override List<Object?> get props => []; }` |
| `AuthInitial`, `AuthLoading`, `Unauthenticated` | states | same | `class AuthInitial extends AuthState { const AuthInitial(); }` (same shape for the other two) |
| `Authenticated` | state | same | `class Authenticated extends AuthState { const Authenticated(this.user); final AuthUser user; @override List<Object?> get props => [user]; }` |
| `AuthFailure` | state | same | `class AuthFailure extends AuthState { const AuthFailure(this.message); final String message; @override List<Object?> get props => [message]; }` |
| `AuthBloc` | app-wide bloc | `auth/presentation/bloc/auth_bloc.dart` | `AuthBloc({required RestoreSession restoreSession, required SignOut signOut, AnalyticsService? analytics})` → `super(const AuthInitial())`; handlers `_onStatusRequested`, `_onLoggedIn`, `_onLogoutRequested`, `_onProfileChanged` |
| `LoginEvent` | abstract class | `auth/presentation/login/bloc/login_event.dart` | `abstract class LoginEvent {}` |
| `NameChanged` | event | same | `class NameChanged extends LoginEvent { NameChanged(this.name); final String name; }` |
| `PhoneNumberChanged` | event | same | `class PhoneNumberChanged extends LoginEvent { PhoneNumberChanged(this.phoneNumber); final String phoneNumber; }` |
| `SubmitDetails` | event | same | `class SubmitDetails extends LoginEvent {}` |
| `FullNameChanged`, `PhoneChanged`, `SendOtpPressed`, `OtpSubmitted` | typedefs | same | `typedef FullNameChanged = NameChanged; typedef PhoneChanged = PhoneNumberChanged; typedef SendOtpPressed = SubmitDetails; typedef OtpSubmitted = SubmitOtp;` |
| `OtpChanged` | event | same | `class OtpChanged extends LoginEvent { OtpChanged(this.otp); final String otp; }` |
| `SubmitOtp`, `ResendOtpRequested`, `EditPhoneNumber`, `ClearError` | events | same | `class SubmitOtp extends LoginEvent {}` (same shape) |
| `SubmissionFailed` | event (legacy) | same | `class SubmissionFailed extends LoginEvent { SubmissionFailed(this.message); final String message; }` |
| `LoginStep` | enum | `auth/presentation/login/bloc/login_state.dart` | `enum LoginStep { details, otp }` |
| `LoginStatus` | enum | same | `enum LoginStatus { idle, requestingOtp, otpSent, failure, verifyingOtp, loggedIn }` |
| `LoginState` | state | same | `const LoginState({this.step = LoginStep.details, this.status = LoginStatus.idle, this.name = '', this.phoneNumber = '', this.otp = '', this.nameError, this.phoneNumberError, this.otpError, this.errorMessage, this.otpRequestCount = 0, this.failure, this.otpRequest, this.session})`; `static const String countryDialCode = '+91'; static const int minNameLength = 2; static const int phoneNumberLength = 10;`; getters `canSubmit`, `isSubmitting`, `fullPhoneNumber`; `copyWith` (see §3 P2) |
| `LoginBloc` | screen bloc | `auth/presentation/login/bloc/login_bloc.dart` | `LoginBloc({required SendOtp sendOtp, required VerifyOtp verifyOtp, AnalyticsService? analytics})`; `static const int minNameLength = LoginState.minNameLength; static const int phoneNumberLength = LoginState.phoneNumberLength; static const int otpLength = 4;` |
| `LoginPage` | page | `auth/presentation/login/pages/login_page.dart` | `class LoginPage extends StatelessWidget { const LoginPage({super.key}); … BlocProvider<LoginBloc>(create: (_) => sl<LoginBloc>(), child: const _LoginView()) }` |
| `friendlyMessageFor` | function | `auth/presentation/login/utils/failure_message.dart` | `String friendlyMessageFor(Failure failure)` |
| `verifyFailureText` | function | same | `(String, String) verifyFailureText(Failure failure)` |
| `LoginDetailsStep`, `LoginOtpStep`, `LoginErrorBanner`, `NameField`, `PhoneNumberField`, `OtpCodeField`, `OtpField` | widgets | `auth/presentation/login/widgets/` | all `const X({super.key})` StatelessWidgets reading `LoginBloc` |
| `LoginHeader` | widget | `login_header.dart` | `const LoginHeader({super.key, this.compact = false}); final bool compact;` |
| `ResendCountdown` | widget | `resend_countdown.dart` | `const ResendCountdown({super.key, required this.onResend, this.duration = const Duration(seconds: 60)}); final VoidCallback onResend; final Duration duration;` |
| `SplashPage` | page | `auth/presentation/splash/pages/splash_page.dart` | `class SplashPage extends StatefulWidget { const SplashPage({super.key}); static const Duration displayDuration = Duration(milliseconds: 2600); … }` |
| `BrandBackdrop` | widget | `auth/presentation/widgets/brand_backdrop.dart` | `const BrandBackdrop({super.key, required this.child});` |
| `BrandMark`, `BrandLogoTile` | widgets | `auth/presentation/widgets/brand_mark.dart` | `const BrandMark({super.key, this.tileSize = 96}); static const String tagline = 'Plants & garden care, delivered';` / `const BrandLogoTile({super.key, required this.size});` |

### 2.2 Wishlist presentation

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `WishlistEvent` | abstract class | `wishlist/presentation/bloc/wishlist_event.dart` | `abstract class WishlistEvent {}` |
| `WishlistStarted` | event | same | `class WishlistStarted extends WishlistEvent { WishlistStarted(this.userId); final String userId; }` |
| `WishlistRefreshed`, `WishlistCleared` | events | same | `class WishlistRefreshed extends WishlistEvent {}` |
| `WishlistToggled` | event | same | `class WishlistToggled extends WishlistEvent { WishlistToggled(this.productId); final String productId; }` |
| `WishlistStatus` | enum | `wishlist_state.dart` | `enum WishlistStatus { initial, loading, loaded, failure }` |
| `WishlistState` | state (non-const) | same | `WishlistState({this.status = WishlistStatus.initial, this.items = const [], this.pendingIds = const {}, this.catalog, this.isStale = false, this.isRefreshing = false, this.failure, this.toggleFailure}) : ids = {for (final item in items) item.productId}, products = wishlistProducts(items, catalog);`; getters `isLoading`, `isBusy`, `count`; `bool contains(String productId)`; `String? categoryNameOf(CatalogProduct product)`; `copyWith({status, items, pendingIds, CatalogSnapshot? Function()? catalog, isStale, isRefreshing, Failure? Function()? failure, Failure? Function()? toggleFailure})`; props `[status, items, ids, pendingIds, catalog, products, isStale, isRefreshing, failure, toggleFailure]` |
| `WishlistBloc` | app-wide bloc | `wishlist_bloc.dart` | `WishlistBloc({required LoadWishlist loadWishlist, required SyncWishlist syncWishlist, required PushWishlist pushWishlist, required AddToWishlist addToWishlist, required RemoveFromWishlist removeFromWishlist, required GetCatalog getCatalog, required GetCachedCatalog getCachedCatalog, AnalyticsService? analytics})` → `super(WishlistState())` |
| `WishlistPage` | page (no own bloc) | `wishlist/presentation/pages/wishlist_page.dart` | `class WishlistPage extends StatelessWidget { const WishlistPage({super.key}); … }` |
| `wishlistFailureMessage`, `wishlistRefreshFailureMessage`, `wishlistToggleFailureMessage` | functions | `wishlist/presentation/utils/failure_message.dart` | each `String f(Failure? failure)` |
| `WishlistEmptyState` | widget | `wishlist_empty_state.dart` | `const WishlistEmptyState({super.key, required this.onBrowse}); final VoidCallback? onBrowse;` |
| `WishlistHeader` | widget | `wishlist_header.dart` | `const WishlistHeader({super.key, required this.itemCount, required this.onBack}); final int itemCount; final VoidCallback? onBack;` |
| `WishlistLoadingSkeleton` | widget (sliver) | `wishlist_loading_skeleton.dart` | `const WishlistLoadingSkeleton({super.key}); static const double spacing = 13; static const EdgeInsets padding = EdgeInsets.fromLTRB(16, 24, 16, 0);` |
| `WishlistProductTile` | widget | `wishlist_product_tile.dart` | `const WishlistProductTile({super.key, required this.product}); final CatalogProduct product;` |

### 2.3 Home presentation

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `HomeEvent` | abstract class | `home/presentation/home/bloc/home_event.dart` | `abstract class HomeEvent {}` |
| `HomeStarted` | event | same | `class HomeStarted extends HomeEvent { HomeStarted({this.language}); final String? language; }` |
| `HomeRefreshed` | event | same | `class HomeRefreshed extends HomeEvent { HomeRefreshed({this.language}); final String? language; }` |
| `HomeStatus` | enum | `home_state.dart` | `enum HomeStatus { initial, loading, loaded, failure }` |
| `HomeState` | state | same | see §3 P2 (complete file) |
| `HomeBloc` | screen bloc | `home_bloc.dart` | `HomeBloc({required GetHomeSections getHomeSections, required GetCachedHomeSections getCachedHomeSections, required GetAppState getAppState, required GetSoldCounts getSoldCounts, required GetCachedSoldCounts getCachedSoldCounts, required GetLowStockThresholds getLowStockThresholds, required GetCachedLowStockThresholds getCachedLowStockThresholds, String imageBaseUrl = ''})` → `super(const HomeState())` |
| `HomePage` | page | `home_page.dart` | `class HomePage extends StatelessWidget { const HomePage({super.key}); … }` |
| `homeFailureMessage`, `refreshFailureMessage` | functions | `home/presentation/home/utils/failure_message.dart` | `String homeFailureMessage(Failure? failure)`, `String refreshFailureMessage(Failure? failure)` |
| `HomeHeader` | widget | `home_header.dart` | `const HomeHeader({super.key, this.coinBalance}); final int? coinBalance;` |
| `HomeSectionView` | widget | `home_section_view.dart` | `const HomeSectionView({super.key, required this.section}); final HomeSection section;` |
| `HomeBannerCarousel` | widget | `home_banner_carousel.dart` | `const HomeBannerCarousel({super.key, required this.banners, required this.onBannerTap, this.autoAdvanceEvery = const Duration(seconds: 5)});` statics `horizontalPadding = 16`, `topPadding = 16`, `cardRadius = 24`, `dotsHeight = 18`, `static double cardHeightFor(BuildContext context)`, `static double heightFor(BuildContext context, {bool withDots = true})` |
| `HomeLoadingSkeleton` | widget (sliver) | `home_loading_skeleton.dart` | `const HomeLoadingSkeleton({super.key});` |
| `PushPermissionPrompt` | widget | `push_permission_prompt.dart` | `const PushPermissionPrompt({required this.child, super.key}); static const Duration settleDelay = Duration(seconds: 1); static const Duration locationWait = Duration(seconds: 30); @visibleForTesting static void resetForTest()` |

### 2.4 Garden presentation

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `GardenEvent` | abstract class | `garden/presentation/bloc/garden_event.dart` | `abstract class GardenEvent {}` |
| `GardenFeatureToggled` | event | same | `class GardenFeatureToggled extends GardenEvent { GardenFeatureToggled(this.feature); final GardenFeature feature; }` |
| `GardenWaitlistJoined` | event | same | `class GardenWaitlistJoined extends GardenEvent {}` |
| `GardenState` | state | `garden_state.dart` | `const GardenState({this.picked = const {}, this.isOnWaitlist = false}); final Set<GardenFeature> picked; final bool isOnWaitlist; GardenState copyWith({Set<GardenFeature>? picked, bool? isOnWaitlist})` |
| `GardenBloc` | screen bloc | `garden_bloc.dart` | `GardenBloc() : super(const GardenState())` |
| `GardenHomePage` | page | `garden/presentation/pages/garden_home_page.dart` | `const GardenHomePage({super.key})` |
| `GardenHero`, `GardenFeaturePoll` | widgets | `garden/presentation/widgets/` | `const X({super.key})` |
| `GardenFeatureCard` | widget | `garden_feature_card.dart` | `const GardenFeatureCard({super.key, required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap}); final VoidCallback? onTap;` |

### 2.5 Address form presentation

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `AddressFormField` | enum | `address/presentation/address_form/bloc/address_form_event.dart` | `enum AddressFormField { receiverName, receiverPhone, houseNo, building, area, landmark, pincode, city, district, state, customLabel }` |
| `AddressFormEvent` | abstract class | same | `abstract class AddressFormEvent {}` |
| `AddressFormStarted` | event | same | `AddressFormStarted({this.address, this.contactName = '', this.contactPhone = '', this.makeDefault = false}); final SavedAddress? address; final String contactName; final String contactPhone; final bool makeDefault;` |
| `AddressFormFieldChanged` | event | same | `AddressFormFieldChanged(this.field, this.value); final AddressFormField field; final String value;` |
| `AddressFormLabelChanged` | event | same | `AddressFormLabelChanged(this.label); final String label;` |
| `AddressFormLocateRequested`, `AddressFormSubmitted` | events | same | `class AddressFormLocateRequested extends AddressFormEvent {}` |
| `AddressFormStatus` | enum | `address_form_state.dart` | `enum AddressFormStatus { editing, saving, saved }` |
| `AddressFormState` | state | same | `const AddressFormState({this.address = const SavedAddress(id: ''), this.seed = const SavedAddress(id: ''), this.revision = 0, this.isNew = true, this.status = AddressFormStatus.editing, this.showErrors = false, this.isLocating = false, this.locateFailure, this.saveFailure});` getters `isSaving`, `Set<AddressProblem> get problems => addressProblems(address)`, `bool shows(AddressProblem problem) => showErrors && problems.contains(problem)`; `copyWith(... Failure? Function()? locateFailure, Failure? Function()? saveFailure)` |
| `AddressFormBloc` | screen bloc | `address_form_bloc.dart` | `AddressFormBloc({required SaveAddress saveAddress, required GetCurrentPlace getCurrentPlace, DateTime Function() now = DateTime.now})` |
| `AddressFormArgs` | route args | `address_form_page.dart` | `class AddressFormArgs { const AddressFormArgs({this.address, this.makeDefault = false}); final SavedAddress? address; final bool makeDefault; }` |
| `AddressFormPage` | page | same | `const AddressFormPage({super.key, this.address, this.makeDefault = false}); final SavedAddress? address; final bool makeDefault;` |
| `AddressFormFields` | widget | `address_form_fields.dart` | `const AddressFormFields({super.key})` |
| `AddressFormHeader` | widget | `address_form_header.dart` | `const AddressFormHeader({super.key, required this.isNew, required this.onBack}); final bool isNew; final VoidCallback onBack;` |

### 2.6 Review & Pay presentation

| name | kind | file | exact signature or shape |
|---|---|---|---|
| `ReviewPayEvent` | abstract class | `checkout/presentation/review_pay/bloc/review_pay_event.dart` | `abstract class ReviewPayEvent {}` |
| `ReviewPayStarted` | event | same | `ReviewPayStarted({required this.items, required this.subtotal, this.coupon}); final List<CartItem> items; final double subtotal; final AppliedCoupon? coupon;` |
| `ReviewPayCartChanged` | event | same | `ReviewPayCartChanged({required this.items, required this.subtotal});` |
| `ReviewPayCouponChanged` | event | same | `ReviewPayCouponChanged(this.coupon); final AppliedCoupon? coupon;` |
| `ReviewPayMethodChanged` | event | same | `ReviewPayMethodChanged(this.method); final PaymentMethod method;` |
| `ReviewPayCoinsToggled`, `ReviewPayRetried`, `ReviewPayPaymentCancelled` | events | same | `class ReviewPayCoinsToggled extends ReviewPayEvent {}` |
| `ReviewPayGstinChanged` | event | same | `ReviewPayGstinChanged(this.gstin); final Gstin? gstin;` |
| `ReviewPayAddressChanged` | event | same | `ReviewPayAddressChanged(this.address); final SavedAddress address;` |
| `ReviewPayOrderRequested` | event | same | `ReviewPayOrderRequested({required this.phone, required this.userKey, this.fullName, this.email});` |
| `OnlinePaymentPhase` | enum | `review_pay_state.dart` | `enum OnlinePaymentPhase { preparing, paying, placing }` |
| `ReviewPayState` | state | same | `const ReviewPayState({this.items = const [], this.subtotal = 0, this.chargeRules, this.coinRules, this.coupons = const [], this.coupon, this.paymentMethod = PaymentMethod.online, this.redeemCoins = false, this.quote, this.isQuoting = false, this.quoteFailure, this.rejectedCouponCode, this.coinsRefused = false, this.gstin, this.addresses = const [], this.address, this.isPlacing = false, this.paymentPhase, this.placeFailure, this.placedOrder});` getters `unlockedCoupon`, `nextCoupon`, `coinsAvailable`, `coinsApplied`, `canRedeemCoins`, `canPay` |
| `ReviewPayBloc` | screen bloc | `review_pay_bloc.dart` | `ReviewPayBloc({required GetCheckoutQuote getCheckoutQuote, required GetChargeRules getChargeRules, required GetCachedChargeRules getCachedChargeRules, required GetCoinRules getCoinRules, required GetActiveCoupons getActiveCoupons, required GetAddresses getAddresses, required GetCachedAddresses getCachedAddresses, required PlaceCodOrder placeCodOrder, required RegisterOnlineOrder registerOnlineOrder, required CollectPayment collectPayment})` |
| `ReviewPayPage` | page | `review_pay_page.dart` | `const ReviewPayPage({super.key})` |
| `placingOrderNote` | top-level const | same | `const String placingOrderNote = 'Placing your order, this can take up to a minute. Please keep the app open.';` |
| `ReviewPayHeader` | widget | `review_pay_header.dart` | `const ReviewPayHeader({super.key, required this.itemCount, required this.onBack}); final int itemCount; final VoidCallback? onBack;` |
| `ReviewPayBar` | widget | `review_pay_bar.dart` | `const ReviewPayBar({super.key, required this.total, required this.paymentMethod, required this.onChangeMethod, required this.onPay, this.isLoading = false, this.note});` |
| `PaymentGateOverlay` | widget | `payment_gate_overlay.dart` | `const PaymentGateOverlay({super.key, required this.phase, required this.total, required this.onCancel});` |
| `showPaymentMethodSheet` | function | `payment_method_sheet.dart` | `Future<PaymentMethod?> showPaymentMethodSheet(BuildContext context, {required double? total, required PaymentMethod selected, double codCharge = 0})` |
| `DeliveryAddressPick` | result class | `delivery_address_sheet.dart` | `class DeliveryAddressPick { const DeliveryAddressPick.saved(SavedAddress this.address); const DeliveryAddressPick.addNew() : address = null; final SavedAddress? address; }` |
| `showDeliveryAddressSheet` | function | same | `Future<DeliveryAddressPick?> showDeliveryAddressSheet(BuildContext context, {required List<SavedAddress> addresses, required SavedAddress? selected})` |
| `DeliveryAddressCard` | widget | `delivery_address_card.dart` | `const DeliveryAddressCard({super.key, required this.address, required this.onChange}); final SavedAddress? address; final VoidCallback? onChange;` |
| `BillDetailsCard` | widget | `bill_details_card.dart` | `const BillDetailsCard({super.key, required this.quote, required this.rules, this.isLoading = false, this.failureMessage, this.onRetry}); static const double iconSize = 18; static const double iconGap = 10; static const double textInset = iconSize + iconGap;` |
| `CouponNudgeBanner` | widget | `coupon_nudge_banner.dart` | `const CouponNudgeBanner({super.key, required this.opportunity, required this.subtotal, this.onApply});` |
| `GstinRow` | widget | `gstin_row.dart` | `const GstinRow({super.key, required this.onTap, this.gstin, this.onRemove});` |
| `MaliCoinsRow` | widget | `mali_coins_row.dart` | `const MaliCoinsRow({super.key, required this.balance, required this.minOrder, required this.canRedeem, required this.coinsApplied, required this.isBusy, required this.onToggle});` |
| `ReviewPayAnalytics` | widget | `review_pay_analytics.dart` | `const ReviewPayAnalytics({super.key, required this.child});` |
| `deliveryChargeNote`, `smallCartFeeNote` | functions | `utils/charge_notes.dart` | `String deliveryChargeNote(ChargeRules rules)`, `String smallCartFeeNote(ChargeRules rules)` |
| `codChargeNote` | function | same | `String? codChargeNote(ChargeRules rules)` |
| `paymentGateTitle`, `paymentGateBody`, `paymentGateCancelLabel` | functions/const | `utils/payment_gate_texts.dart` | `String paymentGateTitle(OnlinePaymentPhase phase)`, `String paymentGateBody(OnlinePaymentPhase phase, {required double total})`, `const String paymentGateCancelLabel = 'Cancel payment';` |
| `paymentMethodLabel`, `paymentMethodDescription`, `paymentMethodIcon` | functions | `utils/payment_method_text.dart` | `String paymentMethodLabel(PaymentMethod method)`, `String paymentMethodDescription(PaymentMethod method, {double codCharge = 0})`, `IconData paymentMethodIcon(PaymentMethod method)` |
| `placeOrderFailureTitle`, `isPlaceOrderCancellation`, `placeOrderFailureMessage` | functions | `utils/place_order_failure_message.dart` | `String placeOrderFailureTitle(Failure failure)`, `bool isPlaceOrderCancellation(Failure failure)`, `String placeOrderFailureMessage(Failure failure, {List<CartItem> items = const []})` |
| `quoteFailureMessage` | function | `utils/quote_failure_message.dart` | `String quoteFailureMessage(Failure? failure, {List<CartItem> items = const []})` |
| `paymentMethodName`, `paymentTypeName`, `failureReasonName` | functions | `utils/checkout_analytics.dart` | `String paymentMethodName(PaymentMethod method)` (`'cod'`/`'online'`), `String paymentTypeName(PaymentMethod method)` (`'COD'`/`'Online'`), `String failureReasonName(Failure failure)` |

### 2.7 Widget `Key` names (the test contract)

Scheme: `Key('<screenPrefix>_<element>')`, camelCase after the underscore; dynamic ids appended with a second underscore
(`'wishlist_item_${product.id}'`, `'home_viewAll_${section.title}'`, `'reviewPay_payment_${method.name}'`, `'garden_feature_${feature.name}'`,
`'addressForm_${field.name}Field'`). Fixed suffixes: `_page` (the `Scaffold`), `_scrollView`, `_loadingSkeleton`, `_retryButton` (the `ReloadWidget`),
`_refreshFailedMessage` / `…Message` (a `SnackBar`), `…Sheet` (an `AppInfoSheet` / `AppPickerSheet`), `_backButton`, `_subtitle`, `…Button`, `…Field`.
Generic components seed their own keys from `testId` (`product_<id>_add` / `_increment` / `_decrement` / `_wishlist`) and fixed ids
(`reload_button`, `appInfoSheet_actionButton`, `appInfoSheet_closeButton`, `appPickerSheet_closeButton`, `cart_summaryBar`, `shell_<tab>Tab`, `shell_<tab>Badge`).

| screen prefix | keys used |
|---|---|
| `login` | `login_getOtpButton`, `login_verifyButton`, `login_editNumberButton`, `login_backButton`, `login_errorBanner`, `login_nameField`, `login_phoneNumberField`, `login_otpField` |
| `wishlist` | `wishlist_page`, `wishlist_scrollView`, `wishlist_loadingSkeleton`, `wishlist_emptyState`, `wishlist_retryButton`, `wishlist_refreshFailedMessage`, `wishlist_toggleFailedMessage` (shown by the shell), `wishlist_browseButton`, `wishlist_subtitle`, `wishlist_backButton`, `wishlist_item_<productId>`, `wishlist_toggle_<productId>`; skeleton tiles `testId: 'skeleton_$index'` |
| `home` | `home_scrollView`, `home_searchField`, `home_loadingSkeleton`, `home_retryButton`, `home_refreshFailedMessage`, `home_bannerCarousel`, `home_banner_<index>`, `home_bannerDots`, `home_bannerSkeleton`, `home_viewAll_<sectionTitle>`, `home_exploreMore_<sectionTitle>`, `PageStorageKey('home_rail_<sectionTitle>')`, `home_themeToggle`, `home_notificationsButton`, `home_locationButton`, `home_locationLabel`, `home_coinsButton`, `home_coinBalance`; skeleton cards `testId: 'skeleton_${index}_$product'` |
| `garden` | `garden_page`, `garden_scrollView`, `garden_notifyButton`, `garden_onTheListSheet`, `garden_pickedCount`, `garden_statusChip`, `garden_feature_<GardenFeature.name>` |
| `addressForm` | `addressForm_page`, `addressForm_scrollView`, `addressForm_saveButton`, `addressForm_backButton`, `addressForm_useCurrentLocation`, `addressForm_<field>Field` (outer) + `ValueKey('addressForm_<field>_<revision>')` (inner), `addressForm_countryField`, `addressForm_labelField`, chips `addressForm_label_home` / `_work` / `_other` (`keyPrefix: 'addressForm_label'`, `keyId: option.toLowerCase()`), `addressForm_saveFailedSheet`, `addressForm_locateFailedSheet` |
| `reviewPay` | `reviewPay_page`, `reviewPay_scrollView`, `reviewPay_backButton`, `reviewPay_itemCount`, `reviewPay_couponNudge`, `reviewPay_couponNudgeText`, `reviewPay_couponNudgeProgress`, `reviewPay_couponRow`, `reviewPay_couponSubtitle`, `reviewPay_viewCouponsButton`, `reviewPay_removeCouponButton`, `reviewPay_coinsSubtitle`, `reviewPay_coinsApplyButton`, `reviewPay_coinsRemoveButton`, `reviewPay_billCard`, `reviewPay_billLoading`, `reviewPay_itemsTotal`, `reviewPay_deliveryCharge`, `reviewPay_deliveryInfoButton`, `reviewPay_smallCartFee`, `reviewPay_smallCartInfoButton`, `reviewPay_codCharge`, `reviewPay_codInfoButton`, `reviewPay_couponDiscount`, `reviewPay_coinsDiscount`, `reviewPay_grandTotal`, `reviewPay_billFailure`, `reviewPay_billRetryButton`, `reviewPay_gstinRow`, `reviewPay_removeGstinButton`, `reviewPay_addressCard`, `reviewPay_deliveryPlace`, `reviewPay_deliveryAddressLine`, `reviewPay_changeAddressButton`, `reviewPay_payUsingButton`, `reviewPay_payUsingLabel`, `reviewPay_payButton`, `reviewPay_payNote`, `reviewPay_paymentGate`, `reviewPay_paymentGateTitle`, `reviewPay_paymentGateBody`, `reviewPay_paymentCancelButton`, `reviewPay_paymentSheet`, `reviewPay_payment_<PaymentMethod.name>`, `reviewPay_addressSheet`, `reviewPay_addAddressButton`, `reviewPay_address_<addressId>`, `reviewPay_orderSignInSheet`, `reviewPay_gstinSignInSheet`, `reviewPay_placeFailedSheet`, `reviewPay_couponAppliedMessage`, `reviewPay_couponRemovedSheet`, `reviewPay_couponDroppedSheet`, `reviewPay_coinsRefusedMessage`, `reviewPay_coinsAppliedMessage` |
| `gstinSheet` | `gstinSheet`, `gstinSheet_numberField`, `gstinSheet_verifyButton`, `gstinSheet_verifiedLine` |
| `shell` | `shell_homeTab`, `shell_categoriesTab`, `shell_gardenTab`, `shell_wishlistTab`, `shell_accountTab`, `shell_<tab>Badge` |

### 2.8 Core / composition names the pages depend on (reproduce exactly)

| name | kind | file | shape |
|---|---|---|---|
| `sl` | global | `core/di/injection_container.dart` | `final GetIt sl = GetIt.instance;` |
| `configureDependencies` | function | same | `void configureDependencies()` calling `_registerCore()` then per feature `_register<Feature>Data()` + `register<Feature>Feature()` |
| `registerAuthFeature`, `registerCatalogFeature`, `registerAppConfigFeature`, `registerHomeFeature({String imageBaseUrl = ''})`, `registerCategoriesFeature`, `registerCartFeature`, `registerWishlistFeature`, `registerSettingsFeature`, `registerGardenFeature`, `registerAddressFeature`, `registerLocationFeature`, `registerMaliCoinsFeature`, `registerCouponsFeature`, `registerOrdersFeature`, `registerCheckoutFeature`, `registerInvoiceFeature`, `registerGstinFeature`, `registerNotificationsFeature`, `registerDeliveryFeature`, `registerProductFeature`, `registerProfileFeature`, `registerReferralFeature`, `registerAccountFeature`, `registerSupportFeature` | functions | same | public, `void`, register use cases (`registerLazySingleton`) and blocs (`registerFactory`) only; tests call them after registering fake repositories |
| `AppRoute` | enum | `core/router/app_routes.dart` | `enum AppRoute { splash('/splash'), …; const AppRoute(this.path); final String path; }`; navigate with `AppRoute.x.name` |
| `AppRouter` | class | `core/router/app_router.dart` | `AppRouter({AnalyticsService? analytics}); late final GoRouter router` |
| `rootNavigatorKey`, `<tab>NavigatorKey` | globals | `core/router/navigator_keys.dart` | `final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');` |
| `App` | widget | `app/app.dart` | `const App({super.key, required this.router}); final GoRouter router; static const double maxTextScaleFactor = 1.1;` |
| `AppInfoSheet`, `AppInfoSheetTone` | sheet | `core/widgets/sheets/app_info_sheet.dart` | `static Future<bool> show(BuildContext context, {required String title, required String message, AppInfoSheetTone tone = AppInfoSheetTone.info, IconData? icon, String actionLabel = defaultActionLabel, Key? key})`; `static const String defaultActionLabel = 'Got it'; static const Key actionKey = Key('appInfoSheet_actionButton'); static const Key closeKey = Key('appInfoSheet_closeButton');` |
| `AppPickerSheet` | sheet | `core/widgets/sheets/app_picker_sheet.dart` | `static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder})`; `static const Key closeKey = Key('appPickerSheet_closeButton');` |
| `PageHeader` | widget | `core/widgets/page_header.dart` | `const PageHeader({super.key, required this.title, required this.onBack, this.subtitle, this.subtitleKey, this.backKey, this.backTooltip = 'Back', this.trailing, this.bottom});` |
| `ReloadWidget` | widget | `core/widgets/reload_widget.dart` | `const ReloadWidget({super.key, required this.errorMessage, required this.onReload, this.color});` retry key `Key('reload_button')` |
| `Failure`, `NetworkFailure`, `ServerFailure`, `CacheMissFailure` | classes | `core/app/failure.dart` | `class Failure { final String message; final int? code; Failure({required this.message, this.code}); }` (NOT Equatable) |
| `UseCase<T, Params>`, `NoParams` | classes | `core/usecases/usecase.dart` | `abstract interface class UseCase<T, Params> { Future<Either<Failure, T>> call(Params params); }`, `class NoParams extends Equatable { const NoParams(); … }` |
| `AnalyticsService` | interface | `core/services/analytics/analytics_service.dart` | reached in widgets by `context.read<AnalyticsService>()` (a `RepositoryProvider` in `app.dart`) |
| `AppEvents` | constants | `core/services/analytics/app_events.dart` | `abstract final class AppEvents { static const String loginStarted = 'Login Started'; … }` |
| `analyticsScreenNames`, `analyticsTabs`, `AnalyticsScreenTracker`, `AnalyticsRouteObserver` | router analytics | `core/router/analytics_screen_tracker.dart` | `const Map<String, String> analyticsScreenNames = {'login': 'PhoneEntry', 'home': 'ShopTab', …}` |
| `UniversalFormField`, `UFFType`, `TextInputConfig`, `OtpConfig`, `DropdownConfig`, `DropdownOption`, `ChoiceChipsConfig`, `ChoiceChipOption` | form kit | `core/widgets/form_helper/` | `UFFType.text`, `.phone`, `.otp`, `.dropdown`, `.choiceChips` used here; `TextInputConfig({lockCountryCode = false, errorText, hintText, prefixIcon, showCounter = true, textInputType, inputFormatters, initialCountryCode, readOnly = false, maxLines = 1, maxLength, …, autofillHints, enabled, autofocus = false, onFieldSubmitted, suffix})`; `OtpConfig({length = 4, onCompleted, errorText, autofocus = false, enabled = true, obscureText = false})`; `DropdownConfig({dropdownOptions = const [], dropdownValidator, isLoading = false, hintText, prefixIcon, errorText})`; `DropdownOption({required key, required value, color})`; `ChoiceChipsConfig({options = const [], keyPrefix, enabled = true, errorText})`; `ChoiceChipOption({required value, required label, icon, keyId})` |
| `ProductDetailPage.open`, `ProductDetailPage.idParam` | statics | `product/presentation/product_detail/pages/product_detail_page.dart` | `static const String idParam = 'id'; static void open(BuildContext context, String productId)` |
| `CategoriesPage.categoryParam`, `.stockParam`, `.searchParam`, `.newSearchRequest()` | statics | `catalog/presentation/categories/pages/categories_page.dart` | `static const String categoryParam = 'category'; static const String stockParam = 'stock'; static const String searchParam = 'search'; static String newSearchRequest() => DateTime.now().microsecondsSinceEpoch.toString();` |
| `OrderPlacedArgs` | route args | `checkout/presentation/order_placed/pages/order_placed_page.dart` | `const OrderPlacedArgs({required this.order, this.items = const [], this.address, this.gstin = ''})` (gstin passed as `state.gstin?.number ?? ''`) |
| `showGstinSheet`, `gstinSheetCloseDelay` | sheet + const | `gstin/presentation/gstin_sheet/widgets/gstin_sheet.dart` | `Future<Gstin?> showGstinSheet(BuildContext context, {required String userKey})`; `const Duration gstinSheetCloseDelay = Duration(milliseconds: 650);` |
| `CartBarOverlay.height` | static | `cart/presentation/widgets/cart_bar_overlay.dart` | `static const double height = CartSummaryBar.height + _bottomGap + 8;` — pages add it to their bottom padding |

### 2.9 Test helper names

| name | kind | file | shape |
|---|---|---|---|
| `FakeKoEngagementService` | fake | `test/helpers/fake_ko_engagement_service.dart` | `implements KoEngagementService`; records `identified`, `events`, `tracked` (`List<({String name, Map<String, dynamic>? properties})>`), `screens`, `registerPushCount` |
| `registerFakeEngagement` | function | same | `FakeKoEngagementService registerFakeEngagement()` → registers `KoEngagementService` and `AnalyticsService` (`KoAnalyticsService(fake)`) in `sl` |
| `registerSignedInApp`, `launchSignedInApp`, `openAccountTab`, `scrollAccountTo` | functions | `test/helpers/signed_in_app.dart` | `void registerSignedInApp({FakeAuthRepository? auth, FakeMaliCoinsRepository? coins, FakeWishlistRepository? wishlist, FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account, FakeKoEngagementService? engagement})`; `Future<void> launchSignedInApp(WidgetTester tester)` |
| `registerAccountFakes` | function | `test/helpers/fake_account_repository.dart` | `void registerAccountFakes({FakeProfileRepository? profile, FakeReferralRepository? referral, FakeAccountRepository? account})` |
| `testSession` | fixture | `test/helpers/fake_auth_repository.dart` | `AuthUser(id: 'user-1', phone: '+919876543210', fullName: 'Asha', roles: ['CUSTOMER'], activeRole: 'CUSTOMER', userKey: '91987654-3210-0000-0000-000000000000')` |
| `FakeAuthRepository` | fake | same | `hasActiveSession`, `sendOtpFailure`, `verifyOtpFailure`, `sendOtpGate`, `verifyOtpGate` (`Completer<void>?`), `sentOtps`, `verifiedOtps` |
| `FakeWishlistRepository` | fake | `test/helpers/fake_wishlist_repository.dart` | `ids`, `cachedIds`, `loadFailure`, `addFailure`, `removeFailure`, `pushFailure`, `loadCalls`, `added`, `removed`, `pushes`, `lastUserId`, `gate`, `toggleGate` |
| `FakeCatalogRepository`, `testVariant`, `testProduct` (`prod_01`, 'Activated Neem Oil'), `testCategory` (`pcat_01`, 'Liquid Tonics'), `testCatalog`, `testSections`, `testSoldCounts`, `testLowStockThresholds` | fake + fixtures | `test/helpers/fake_catalog_repository.dart` | `catalogFailure`, `homeSectionsFailure`, …, `cachedCatalog`, `cachedSections`, `cachedSoldCounts`, `cachedLowStockThresholds`, `gate`; `_cached<T>(T? value) => value == null ? Left(CacheMissFailure()) : Right(value)` |

---

## 3. Patterns

Each pattern: a verbatim example from the repo, then the rule it encodes (what to copy, what varies).

### P1. Event file: plain classes, no Equatable, no `const`, no `props`

Complete file `lib/features/wishlist/presentation/bloc/wishlist_event.dart`:

```dart
abstract class WishlistEvent {}

/// Loads [userId]'s wishlist: the device's copy at once, then a sync with
/// the server. Sent when a user signs in or a session is restored.
class WishlistStarted extends WishlistEvent {
  WishlistStarted(this.userId);

  final String userId;
}

/// Syncs with the server again, e.g. after a failure or a pull to refresh.
class WishlistRefreshed extends WishlistEvent {}

/// Saves the product if it isn't in the wishlist, removes it if it is.
class WishlistToggled extends WishlistEvent {
  WishlistToggled(this.productId);

  final String productId;
}

/// Empties the state. Sent on sign-out; the device keeps the user's list.
class WishlistCleared extends WishlistEvent {}
```

Complete file `lib/features/home/presentation/home/bloc/home_event.dart` (named optional field):

```dart
abstract class HomeEvent {}

/// Loads the Home page for the first time.
class HomeStarted extends HomeEvent {
  HomeStarted({this.language});

  /// The device locale's language code, read by the page. The bloc keeps
  /// it for later refreshes.
  final String? language;
}

/// Reloads everything, e.g. after a failure or a pull to refresh.
class HomeRefreshed extends HomeEvent {
  HomeRefreshed({this.language});

  /// The device locale's language code, read by the page. The bloc keeps
  /// it for later refreshes.
  final String? language;
}
```

Rule: `abstract class <X>Event {}` at the top; one class per event, `extends <X>Event`; a single-value event takes it
positionally (`WishlistToggled(this.productId)`), several values are named (`AddressFormStarted({this.address, this.contactName = '', …})`,
`ReviewPayCartChanged({required this.items, required this.subtotal})`); a two-value event whose values form a pair is positional
(`AddressFormFieldChanged(this.field, this.value)`). Fields are `final`, declared after the constructor. Constructors are never `const`
(pages write `HomeRefreshed()` and `WishlistCleared()` without `const`). Every event has a doc comment that says when it is sent.
Standard verbs: `<X>Started`, `<X>Refreshed`, `<X>Cleared` (sign-out), `<X>Toggled`, `<X>Changed`, `<X>Requested`, `<X>Submitted`,
`<X>Retried`, `<X>Pressed`. Aliases to a spec's names are `typedef`s (`typedef SendOtpPressed = SubmitDetails;`). An enum that
names the fields of a form lives in the event file (`enum AddressFormField { … }`).

### P2. State file: status enum + Equatable + clearable `copyWith` getters

Complete file `lib/features/home/presentation/home/bloc/home_state.dart`:

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

Rule: the enum `<X>Status` is declared in the state file, first value `initial` (or `idle` / `editing` for forms), every value
documented. The state is `class <X>State extends Equatable` with a `const` constructor whose defaults are `const []` / `const {}` /
`false` / `0` / `''`. Every nullable field is cleared through a getter parameter `T? Function()? x` with the body
`x: x != null ? x() : this.x`; non-nullable fields use `x ?? this.x`. The doc comment on `copyWith` is always the same sentence.
`props` lists **every** field in declaration order. Derived values are getters (`isLoading`, `isBusy`, `canSubmit`, `canPay`).
A state whose constructor derives collections is non-const (`WishlistState(...) : ids = {for (final item in items) item.productId}, products = wishlistProducts(items, catalog);`)
and the derived fields are **also** in `props`. The three cache-first fields are always named `isStale`, `isRefreshing`, `failure`
and `isBusy` is always `isLoading || isRefreshing`. A second, independent failure gets its own field (`toggleFailure`, `locateFailure`, `saveFailure`, `quoteFailure`, `placeFailure`).

### P3. Abstract-class state hierarchy (app-wide status without data to copy)

Complete file `lib/features/auth/presentation/bloc/auth_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is signed in; [user] holds everything known about them.
class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

Rule: used only by `AuthBloc` (the states are mutually exclusive and carry little data). Readers test with `is`
(`state is Authenticated`) or a `switch` (`Authenticated(:final user) => user.fullName, _ => null`). The base is `abstract class`,
not `sealed` (the domain's `BannerTarget` is `sealed class`; blocs use `abstract`). Everywhere else the app uses the P2 shape; follow the style of the bloc being extended.

### P4. Bloc file: imports, `export`s of event and state, constructor, handlers

The head of every bloc file (`lib/features/home/presentation/home/bloc/home_bloc.dart`):

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
// … the use cases it takes …
import 'home_event.dart';
import 'home_state.dart';

export 'home_event.dart';
export 'home_state.dart';
```

Constructor shape (`AuthBloc`):

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

Rule: the bloc file re-exports its event and state files, so pages and tests import only `…/bloc/<x>_bloc.dart`. Use cases come in as
`required` named parameters, stored in private finals assigned in the initializer list, then `super(const <X>State())`, then every
`on<Event>(_onEvent)` in the constructor body. Handlers are `Future<void> _onEventName(EventName event, Emitter<XState> emit) async`
(or `void` when synchronous). Trivial handlers may be inline lambdas (`on<ReviewPayRetried>((event, emit) => _quote(emit));`,
`on<ReviewPayGstinChanged>((event, emit) => emit(state.copyWith(gstin: () => event.gstin)));`). Shared flows are private verbs
(`_send`, `_verify`, `_refresh`, `_showCached`/`_showSaved`, `_quote`, `_reset`, `_loadExtras`). An optional
`AnalyticsService? analytics` is always the last named parameter and stored as `final AnalyticsService? _analytics;` with the doc
"Reports …. Null reports nothing."; a failure is reported as `failure.runtimeType.toString()`, never its text. Use cases are called
as functions: `await _sendOtp(request)`, `await _restoreSession(const NoParams())`.

### P5. The smallest bloc (no use cases)

Complete file `lib/features/garden/presentation/bloc/garden_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'garden_event.dart';
import 'garden_state.dart';

export 'garden_event.dart';
export 'garden_state.dart';

/// Owns the My Garden "coming soon" screen: which planned features the
/// user picked, and whether they asked to be told when it opens.
// TODO(garden): nothing is sent to the server yet. The picks and the
// waitlist live only in this bloc, so they are lost when the app closes
// and no message is ever sent. Add use cases for both once there is an
// endpoint.
class GardenBloc extends Bloc<GardenEvent, GardenState> {
  GardenBloc() : super(const GardenState()) {
    on<GardenFeatureToggled>(_onFeatureToggled);
    on<GardenWaitlistJoined>(_onWaitlistJoined);
  }

  void _onFeatureToggled(
    GardenFeatureToggled event,
    Emitter<GardenState> emit,
  ) {
    final picked = {...state.picked};
    if (!picked.remove(event.feature)) picked.add(event.feature);
    emit(state.copyWith(picked: picked));
  }

  void _onWaitlistJoined(
    GardenWaitlistJoined event,
    Emitter<GardenState> emit,
  ) {
    emit(state.copyWith(isOnWaitlist: true));
  }
}
```

Registered as `sl.registerFactory(GardenBloc.new);` (same for `ThemeBloc`). Rule: a bloc with no dependencies still gets the
three files, the exports, a class doc comment, and a `TODO(<feature>)` naming what is not built.

### P6. The cache-first screen bloc (AGENTS §20 recipe as implemented)

From `HomeBloc` (verbatim):

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

Rule: `Started` = (remember args) → `isBusy` guard → `_showCached` when nothing is loaded → `_refresh`. `_showCached` emits
`loaded` + `isStale: true` only when there is something to show, otherwise nothing (the skeleton stays). `_refresh` = `isBusy` guard →
emit `isRefreshing: true` when data is on screen else `loading`, clearing `failure` → parallel use cases through a record `.wait` →
`result.match(failure → keep data + failure | status failure, data → loaded, isStale false, isRefreshing false)`; optional
extras use `getOrElse((_) => state.<current>)`. The user-scoped variant (`WishlistBloc._showSaved` / `_refresh`) adds the
`_session` counter check `if (session != _session) return;` after every `await` (see P24).

### P7. Page skeleton: `XPage` provides, `_XView` builds (BlocProvider + BlocListener + body switch)

Complete file `lib/features/wishlist/presentation/pages/wishlist_page.dart` (a tab page over an app-wide bloc):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/reload_widget.dart';
import '../../../cart/presentation/widgets/cart_bar_overlay.dart';
import '../bloc/wishlist_bloc.dart';
import '../utils/failure_message.dart';
import '../widgets/wishlist_empty_state.dart';
import '../widgets/wishlist_header.dart';
import '../widgets/wishlist_loading_skeleton.dart';
import '../widgets/wishlist_product_tile.dart';

/// Wishlist tab: the products the signed-in user saved. The app-wide
/// [WishlistBloc] loads them when the user signs in; this page only shows
/// its state and refreshes on pull.
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select(
      (WishlistBloc bloc) => bloc.state.status == WishlistStatus.loaded
          ? bloc.state.products.length
          : 0,
    );

    return BlocListener<WishlistBloc, WishlistState>(
      // A refresh that failed while the wishlist stays on screen.
      listenWhen: (previous, current) =>
          current.status == WishlistStatus.loaded &&
          current.failure != null &&
          current.failure != previous.failure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('wishlist_refreshFailedMessage'),
            content: Text(wishlistRefreshFailureMessage(state.failure)),
          ),
        ),
      child: Scaffold(
        key: const Key('wishlist_page'),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WishlistHeader(
                  itemCount: count,
                  // The wishlist is a tab, so "back" is the Home tab.
                  onBack: () => context.goNamed(AppRoute.home.name),
                ),
                const Expanded(child: _WishlistBody()),
              ],
            ),
            const CartBarOverlay(),
          ],
        ),
      ),
    );
  }
}

class _WishlistBody extends StatelessWidget {
  const _WishlistBody();

  @override
  Widget build(BuildContext context) {
    final status = context.select((WishlistBloc bloc) => bloc.state.status);
    final products = context.select((WishlistBloc bloc) => bloc.state.products);
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + CartBarOverlay.height;

    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<WishlistBloc>()..add(WishlistRefreshed());
        await bloc.stream.firstWhere((s) => !s.isBusy);
      },
      child: CustomScrollView(
        key: const Key('wishlist_scrollView'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          switch (status) {
            WishlistStatus.initial ||
            WishlistStatus.loading => const WishlistLoadingSkeleton(
              key: Key('wishlist_loadingSkeleton'),
            ),
            WishlistStatus.failure => const SliverFillRemaining(
              hasScrollBody: false,
              child: _WishlistFailure(),
            ),
            WishlistStatus.loaded when products.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: WishlistEmptyState(
                key: const Key('wishlist_emptyState'),
                onBrowse: () => context.goNamed(AppRoute.categories.name),
              ),
            ),
            WishlistStatus.loaded => SliverPadding(
              padding: WishlistLoadingSkeleton.padding,
              sliver: SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: WishlistLoadingSkeleton.spacing),
                itemBuilder: (context, index) =>
                    WishlistProductTile(product: products[index]),
              ),
            ),
          },
          SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
        ],
      ),
    );
  }
}

class _WishlistFailure extends StatelessWidget {
  const _WishlistFailure();

  @override
  Widget build(BuildContext context) {
    final failure = context.select((WishlistBloc bloc) => bloc.state.failure);

    return ReloadWidget(
      key: const Key('wishlist_retryButton'),
      errorMessage: wishlistFailureMessage(failure),
      onReload: () => context.read<WishlistBloc>().add(WishlistRefreshed()),
    );
  }
}
```

A page that owns a screen bloc adds the provider on top (`lib/features/home/presentation/home/pages/home_page.dart`):

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

and the `_HomeView.build` wraps the `Scaffold` in the same refresh-failure `BlocListener` (key `home_refreshFailedMessage`,
`refreshFailureMessage(state.failure)`), with a `switch (status)` sliver of `HomeLoadingSkeleton` / `_HomeFailure` (`ReloadWidget`
keyed `home_retryButton`) / `_EmptyHome` / `SliverList.builder`.

Rule: the public page is a `StatelessWidget` named `<X>Page` whose `build` is **only** `BlocProvider<XBloc>(create: (_) => sl<XBloc>()[..add(XStarted(...))], child: const _XView())`
(no provider when the page reads an app-wide bloc). The body is a private `_XView` (Stateful only when it needs a controller or
timer). Private helpers are `_XBody`, `_XFailure`, `_EmptyX`, `_SaveBar`, `_PayBar`. The `Scaffold` carries `Key('<prefix>_page')`,
the scroll view `Key('<prefix>_scrollView')`. The body is a `switch (status)` expression with `||` for `initial || loading`,
and `when` guards for the empty case. Pages that float the cart bar put it last in a `Stack` and add `CartBarOverlay.height` to
their bottom padding. Back from a tab page goes `goNamed(AppRoute.home.name)`; from a root-pushed page
`context.canPop() ? context.pop() : context.goNamed(AppRoute.<fallback>.name)`.

### P8. BlocProvider `create:` seeded from app-wide blocs or route args

`AddressFormPage.build`:

```dart
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final user = auth is Authenticated ? auth.user : null;

    return BlocProvider<AddressFormBloc>(
      create: (_) => sl<AddressFormBloc>()
        ..add(
          AddressFormStarted(
            address: address,
            contactName: user?.fullName ?? '',
            contactPhone: user?.phone ?? '',
            makeDefault: makeDefault,
          ),
        ),
      child: const _AddressFormView(),
    );
  }
```

`ReviewPayPage.build`:

```dart
    return BlocProvider<ReviewPayBloc>(
      create: (context) {
        final cart = context.read<CartBloc>().state;
        return sl<ReviewPayBloc>()..add(
          ReviewPayStarted(
            items: cart.items,
            subtotal: cart.subtotal,
            coupon: context.read<CouponBloc>().state.applied,
          ),
        );
      },
      child: const _ReviewPayView(),
    );
```

Rule: a page bloc never reads another bloc; the page snapshots the app-wide state with `context.read<…>().state` (never `watch`)
and hands it to the `Started` event. Route parameters arrive as constructor fields of the page (`AddressFormPage({address, makeDefault})`),
decoded by the router from an `extra` args class (`AddressFormArgs`), and are passed on the same way.

### P9. Forwarding app-wide bloc changes into the page bloc (listeners, not reads)

From `_ReviewPayView.build`:

```dart
        // The page bloc never reads the app-wide blocs: tell it what changed.
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) => previous.items != current.items,
          listener: (context, state) => context.read<ReviewPayBloc>().add(
            ReviewPayCartChanged(items: state.items, subtotal: state.subtotal),
          ),
        ),
        BlocListener<CouponBloc, CouponState>(
          listenWhen: (previous, current) =>
              previous.applied != current.applied,
          listener: (context, state) => context.read<ReviewPayBloc>().add(
            ReviewPayCouponChanged(state.applied),
          ),
        ),
```

and the reverse direction (page bloc → app-wide bloc):

```dart
        // Every bill carries the server's balance: keep the app-wide one
        // in step, as the coins page does.
        BlocListener<ReviewPayBloc, ReviewPayState>(
          listenWhen: (previous, current) =>
              current.coinsAvailable != null &&
              current.coinsAvailable != previous.coinsAvailable,
          listener: (context, state) => context.read<MaliCoinsBloc>().add(
            MaliCoinsBalanceChanged(state.coinsAvailable!),
          ),
        ),
```

Rule: blocs talk to blocs only through the UI: a `BlocListener` on bloc A adds an event to bloc B. `app.dart` does the same for the
app-wide pairs (`BlocListener<CartBloc, CartState>` → `CouponCartChanged(state.subtotal)`; `BlocListener<ProfileBloc>` → `AuthProfileChanged`).

### P10. `listenWhen` forms used (every listener has one, and a comment saying the moment it catches)

| moment | `listenWhen` |
|---|---|
| a step/tab changed | `(previous, current) => previous.step != current.step` |
| an async action finished (either way) | `previous.status == LoginStatus.requestingOtp && current.status != LoginStatus.requestingOtp` |
| a new failure arrived (identity compare, `Failure` is not Equatable) | `current.failure != null && current.failure != previous.failure` |
| a refresh failed while data stays on screen | `current.status == HomeStatus.loaded && current.failure != null && current.failure != previous.failure` |
| a flag turned on | `!previous.isOnWaitlist && current.isOnWaitlist` ; `!previous.isPlacing && current.isPlacing` ; `current.coinsRefused && !previous.coinsRefused` |
| a value became known | `previous.placedOrder == null && current.placedOrder != null` ; `previous.quote == null && current.quote != null` |
| a value changed to non-null | `current.coinsAvailable != null && current.coinsAvailable != previous.coinsAvailable` |
| reached a terminal status once | `current.status == AddressFormStatus.saved && previous.status != AddressFormStatus.saved` |
| the signed-in user changed (not a profile edit) | `(current is Authenticated && (previous is! Authenticated \|\| previous.user.id != current.user.id)) \|\| (current is Unauthenticated && previous is! Unauthenticated)` (app.dart) |
| no `listenWhen` | only `BlocListener<AuthBloc, AuthState>(listener: _onAuthStateChanged)` in `LoginPage`, whose listener itself tests `state is Authenticated` |

Listener bodies are either small lambdas or methods on the view class with the signature `void _onX(BuildContext context, XState state)`
passed as `listener: _onX` (`_onSendResult`, `_onVerifyResult`, `_onAuthStateChanged`, `_finishOrder`, `_showPlaceFailure`).

### P11. Passing notes: the SnackBar idiom

```dart
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('home_refreshFailedMessage'),
            content: Text(refreshFailureMessage(state.failure)),
          ),
        ),
```

`_ReviewPayView` wraps it as `void _showNote(BuildContext context, Key key, String text)`. Rule: every SnackBar has a `Key` ending
in `Message`, hides the previous one first, and its text comes from a `utils/` helper. The app-wide wishlist toggle failure is
shown by the **shell** (`AppShellScaffold`), because hearts are on every tab.

### P12. Pull-to-refresh

```dart
    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<HomeBloc>()..add(HomeRefreshed());
        await bloc.stream.firstWhere((s) => !s.isBusy);
      },
      child: CustomScrollView(
        key: const Key('home_scrollView'),
        // (wishlist adds) physics: const AlwaysScrollableScrollPhysics(),
        slivers: [ … ],
      ),
    );
```

Rule: the indicator waits on the bloc's own `isBusy`; the page never times it.

### P13. Failure → text helpers map **types**, live in `presentation/<screen>/utils/failure_message.dart`

Complete file `lib/features/home/presentation/home/utils/failure_message.dart`:

```dart
import '../../../../../core/app/failure.dart';

/// User-facing text for a Home load [failure]; never shows raw codes.
String homeFailureMessage(Failure? failure) {
  return switch (failure) {
    NetworkFailure() =>
      'No internet connection. Check your connection and try again.',
    _ => "We couldn't load the shop right now. Please try again.",
  };
}

/// User-facing text for a refresh that failed while saved products stay
/// on screen; never shows raw codes.
String refreshFailureMessage(Failure? failure) {
  return switch (failure) {
    NetworkFailure() => 'No internet connection. Showing saved products.',
    _ => "Couldn't refresh right now. Showing saved products.",
  };
}
```

A helper that returns a title and a message (`auth/presentation/login/utils/failure_message.dart`):

```dart
/// Dialog title and message for a verify-OTP [failure]; never shows raw
/// codes or server details.
(String, String) verifyFailureText(Failure failure) {
  return switch (failure) {
    OtpExpiredFailure() => (
      'Request a new code',
      'This code has expired. Tap "Resend code" to get a new one.',
    ),
    // …
    NetworkFailure() => (
      'No connection',
      'Check your internet connection and try again.',
    ),
    _ => ('Something went wrong', "We couldn't verify the code. Try again."),
  };
}
```

Field patterns inside the switch (`place_order_failure_message.dart`, `coupon_failure_message.dart`, `select_location/utils/failure_message.dart`):

```dart
    OrderAddressFailure(:final issue) => _addressMessage(issue),
    OrderRefusedFailure(reason: OrderRefusalReason.couponNotApplicable) => '…',
    PaymentCancelledFailure(upiTimeout: true) => 'Payment not completed',
    PaymentFailedFailure(:final reason, :final detail) => _paymentMessage(reason, detail),
    CouponMinSubtotalFailure(:final shortfall, :final couponCode) =>
      'Add ${formatRupees(shortfall)} more to use $couponCode',
    LocationPermissionDeniedFailure(isPermanent: true) => '…',
    _ => quoteFailureMessage(failure, items: items),   // delegate to the sibling helper as the fallback
```

Rule: one file per screen named `failure_message.dart` (or `<topic>_failure_message.dart` when a feature has several), top-level
functions named `<screen>FailureMessage` / `<screen>RefreshFailureMessage` / `<thing>FailureTitle`; parameter `Failure? failure`
for load/refresh helpers (they are called with `state.failure`), `Failure failure` when the caller has already null-checked. Every
switch has `NetworkFailure()` (when it can happen) and a `_ =>` fallback. Text is the only thing that varies; the helper never reads
`failure.message`, `code`, `errorCode` or `detail` (except the `PaymentFailureReason.unknown` branch, which shows the gateway's short
text deliberately). Record-returning helpers `(String, String)` feed a title+message surface. Enum-keyed text helpers follow the
same shape (`paymentGateTitle(phase) => switch (phase) { … }`, `addressProblemMessage(problem)`).

### P14. `AppInfoSheet` from a `BlocListener` (information, success, error with one next step)

Complete file `lib/features/garden/presentation/pages/garden_home_page.dart` (BlocProvider + BlocListener + body):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/analytics/analytics_service.dart';
import '../../../../core/services/analytics/app_events.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/sheets/app_info_sheet.dart';
import '../bloc/garden_bloc.dart';
import '../widgets/garden_feature_poll.dart';
import '../widgets/garden_hero.dart';

/// Garden tab. My Garden is not built yet, so this is its "coming soon"
/// screen: what it will be, a poll of what to build first, and a button to
/// be told when it opens.
class GardenHomePage extends StatelessWidget {
  const GardenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GardenBloc>(
      create: (_) => sl<GardenBloc>(),
      child: const _GardenView(),
    );
  }
}

class _GardenView extends StatelessWidget {
  const _GardenView();

  static Future<void> _showOnTheList(BuildContext context) {
    return AppInfoSheet.show(
      context,
      key: const Key('garden_onTheListSheet'),
      tone: AppInfoSheetTone.success,
      title: "You're on the list",
      message:
          "We'll send one message the day My Garden opens. "
          'Nothing before that.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOnWaitlist = context.select(
      (GardenBloc bloc) => bloc.state.isOnWaitlist,
    );
    // The shell's floating bar covers the bottom of the page.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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

      child: Scaffold(
        key: const Key('garden_page'),
        body: SingleChildScrollView(
          key: const Key('garden_scrollView'),
          padding: EdgeInsets.only(bottom: bottomInset + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GardenHero(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GardenFeaturePoll(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: PrimaryButton(
                  key: const Key('garden_notifyButton'),
                  label: isOnWaitlist
                      ? "You're on the list"
                      : 'Tell me when it opens',
                  leadingIcon: isOnWaitlist
                      ? null
                      : Icons.notifications_none_rounded,
                  icon: isOnWaitlist ? Icons.check_rounded : null,
                  // Once on the list, the button shows the confirmation
                  // again.
                  onPressed: isOnWaitlist
                      ? () => _showOnTheList(context)
                      : () => context.read<GardenBloc>().add(
                          GardenWaitlistJoined(),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'One message, the day it opens. Nothing else.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

An error with a retry, the bloc captured **before** the `await` (`AddressFormPage`):

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
        BlocListener<AddressFormBloc, AddressFormState>(
          listenWhen: (previous, current) =>
              current.locateFailure != null &&
              current.locateFailure != previous.locateFailure,
          listener: (context, state) => AppInfoSheet.show(
            context,
            key: const Key('addressForm_locateFailedSheet'),
            tone: AppInfoSheetTone.error,
            icon: state.locateFailure is LocationServiceDisabledFailure
                ? Icons.location_off_outlined
                : null,
            title: locateFailureTitle(state.locateFailure),
            message: locateFailureMessage(state.locateFailure),
          ),
        ),
```

A failure → (action label, next step) table (`_ReviewPayView._showPlaceFailure`):

```dart
  Future<void> _showPlaceFailure(
    BuildContext context,
    ReviewPayState state,
  ) async {
    final failure = state.placeFailure!;
    final (String action, Future<void> Function()? next) = switch (failure) {
      OrderAddressFailure(issue: OrderAddressIssue.missing) => (
        'Choose address',
        () => _chooseAddress(context),
      ),
      OrderAddressFailure() => (
        'Edit address',
        () => _editAddress(context, address: state.address),
      ),
      OrderOutcomeUnknownFailure() ||
      OrderStillProcessingFailure() ||
      OrderNotRegisteredFailure() ||
      PaymentFailedFailure() => ('Try again', () => _placeOrder(context)),
      PaymentNotConfiguredFailure() => (
        'Pay on delivery',
        () async => context.read<ReviewPayBloc>().add(
          ReviewPayMethodChanged(PaymentMethod.cashOnDelivery),
        ),
      ),
      _ => ('Got it', null),
    };

    final pressed = await AppInfoSheet.show(
      context,
      key: const Key('reviewPay_placeFailedSheet'),
      tone: isPlaceOrderCancellation(failure)
          ? AppInfoSheetTone.info
          : AppInfoSheetTone.error,
      title: placeOrderFailureTitle(failure),
      message: placeOrderFailureMessage(failure, items: state.items),
      actionLabel: action,
    );
    if (pressed && next != null && context.mounted) await next();
  }
```

Rule: sheets and dialogs are opened only from the UI (a listener or a tap handler), always keyed `<prefix>_<name>Sheet`, text from
the `utils/` helpers; `show` returns `true` only for the action button. Anything needed after the `await` is read before it
(`final bloc = context.read<…>()`), and `context.mounted` / `bloc.isClosed` are checked after. A guard such as "sign in first" is
an `AppInfoSheet` with the default `'Got it'` (`reviewPay_orderSignInSheet`).

### P15. `context.select` in `build`; `context.read` in callbacks

```dart
    final step = context.select((LoginBloc bloc) => bloc.state.step);
    final isSubmitting = context.select((LoginBloc bloc) => bloc.state.isSubmitting);
    final errorText = context.select((LoginBloc bloc) => bloc.state.nameError);
    final quantity = context.select(
      (CartBloc bloc) => variant == null ? 0 : bloc.state.quantityOf(variant.id),
    );
    final fullName = context.select(
      (AuthBloc bloc) => switch (bloc.state) {
        Authenticated(:final user) => user.fullName,
        _ => null,
      },
    );
    final isOther = context.select(
      (AddressFormBloc bloc) => bloc.state.address.label == AddressLabels.other,
    );
    final showsError = context.select(
      (AddressFormBloc bloc) => problem != null && bloc.state.shows(problem),
    );
```

Dispatch: `context.read<LoginBloc>().add(SendOtpPressed())`; read-once for a snapshot: `context.read<AuthBloc>().state`.
`_ReviewPayBody` deviates with `final state = context.watch<ReviewPayBloc>().state;` because it lays out a dozen fields (see §4).
Rule: select one scalar or one equality-comparable value per call; derive booleans inside the selector; never `select` the whole
state. A `PrimaryButton` gets `isLoading: context.select(...)` and `onPressed: context.select((b) => b.state.canSubmit) ? () {…} : null`.

### P16. Field wrapper widget (feature widget over `UniversalFormField`)

Complete file `lib/features/auth/presentation/login/widgets/name_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/form_helper/field_config.dart';
import '../../../../../core/widgets/form_helper/universal_form_field.dart';
import '../bloc/login_bloc.dart';

class NameField extends StatelessWidget {
  const NameField({super.key});

  @override
  Widget build(BuildContext context) {
    final errorText = context.select((LoginBloc bloc) => bloc.state.nameError);

    return KeyedSubtree(
      key: const Key('login_nameField'),
      child:
          UniversalFormField(
            fieldType: UFFType.text,
            label: 'Full name',
            withTitle: true,
            // Non-null so the field manages its own text instead of the
            // controller UniversalFormField recreates on every build.
            initialValue: '',
            onChanged: (value) =>
                context.read<LoginBloc>().add(NameChanged(value as String)),
          ).build(
            textInputConfig: TextInputConfig(
              hintText: 'Your name',
              prefixIcon: Icons.person_outline_rounded,
              textInputType: TextInputType.name,
              errorText: errorText,
            ),
          ),
    );
  }
}
```

OTP boxes reset by re-keying (`otp_code_field.dart`):

```dart
    return KeyedSubtree(
      key: const Key('login_otpField'),
      child: KeyedSubtree(
        // A new code request starts with empty boxes.
        key: ValueKey(requestCount),
        child:
            UniversalFormField(
              fieldType: UFFType.otp,
              label: 'Enter ${LoginBloc.otpLength}-digit code',
              withTitle: true,
              onChanged: (value) =>
                  context.read<LoginBloc>().add(OtpChanged(value as String)),
            ).build(
              otpConfig: OtpConfig(
                length: LoginBloc.otpLength,
                autofocus: true,
                errorText: errorText,
                // LoginBloc submits the complete code itself.
                onCompleted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
      ),
    );
```

Rule: one widget per field named `<Thing>Field`, `KeyedSubtree(key: Key('<prefix>_<thing>Field'))` outermost, `withTitle: true`,
`initialValue: ''` on text fields, `errorText` from `context.select`, `onChanged: (value) => context.read<Bloc>().add(Event(value as String))`.
The formatting of `UniversalFormField(...).build(...)` with the odd `child:\n    UniversalFormField(` line break is `dart format`'s output; keep running `dart format`.

### P17. A long form whose fields are seeded by the bloc (`_SeededField` + `revision`)

From `address_form_fields.dart`:

```dart
/// Keys a field for tests by [field], and rebuilds it from the form's
/// seed whenever the form fills fields itself.
class _SeededField extends StatelessWidget {
  const _SeededField({required this.name, required this.builder});

  final String name;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    final revision = context.select(
      (AddressFormBloc bloc) => bloc.state.revision,
    );
    return KeyedSubtree(
      key: Key('addressForm_${name}Field'),
      child: KeyedSubtree(
        key: ValueKey('addressForm_${name}_$revision'),
        child: Builder(builder: builder),
      ),
    );
  }
}
```

used as

```dart
    return _SeededField(
      name: field.name,
      builder: (context) {
        final seed = context.read<AddressFormBloc>().state.seed;
        return UniversalFormField(
          fieldType: UFFType.text,
          label: label,
          withTitle: true,
          initialValue: _seedValue(seed),
          onChanged: (value) => context.read<AddressFormBloc>().add(
            AddressFormFieldChanged(field, value as String),
          ),
        ).build(
          textInputConfig: TextInputConfig(
            hintText: hintText,
            prefixIcon: icon,
            textInputType: textInputType,
            maxLength: maxLength,
            showCounter: false,
            inputFormatters: inputFormatters,
            autofillHints: autofillHints,
            errorText: showsError && problem != null
                ? addressProblemMessage(problem)
                : null,
          ),
        );
      },
    );
```

A dropdown (`_StateField`) passes `initialValue: seeded.isEmpty ? null : seeded` and `DropdownConfig(hintText:, prefixIcon:, dropdownOptions: [for (final state in states) DropdownOption(key: state, value: state)], errorText:)`;
a read-only field (`_CountryField`) passes `initialValue: AddressLabels.country, onChanged: (_) {}` and `const TextInputConfig(readOnly: true, prefixIcon: …)`;
a pick-one row (`_LabelField`) is `UFFType.choiceChips` with `ChoiceChipsConfig(keyPrefix: 'addressForm_label', options: [for (final option in AddressLabels.all) ChoiceChipOption(value: option, label: option, icon: addressLabelIcon(option), keyId: option.toLowerCase())])`.
Section headings are `FormSectionTitle(icon:, title:, description:)`; the leading action is `IconListTile(filled: true, isLoading: isLocating, showChevron: true, …)`;
gaps are a private `_Gap` (`SizedBox(height: 16)`); two fields share a row with `Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(...), SizedBox(width: 12), Expanded(...)])`.
The bloc keeps `address` (what the user typed) separate from `seed` (what fields start from) and bumps `revision` only when it fills
fields itself (start, GPS), so typing never resets a field. Errors show only after the first submit (`showErrors`), via
`state.shows(problem)` over the domain's `addressProblems(address)`.

### P18. Loading skeleton: real widgets inside `Skeletonizer.sliver`, theme shimmer

Complete file `lib/features/wishlist/presentation/widgets/wishlist_loading_skeleton.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/widgets/product/product_list_tile.dart';

const int _tileCount = 4;

/// Shimmering placeholder shown while the wishlist loads. It is built
/// from the real tile, so the bones line up with the loaded layout. Use it
/// as a sliver.
class WishlistLoadingSkeleton extends StatelessWidget {
  const WishlistLoadingSkeleton({super.key});

  /// Gap between two tiles, shared with the loaded list.
  static const double spacing = 13;

  /// Space around the list, shared with the loaded list.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(16, 24, 16, 0);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Skeletonizer.sliver(
      // Follow the app theme, not the platform brightness, so the shimmer
      // stays right when the user toggles dark mode in the app.
      effect: ShimmerEffect(
        baseColor: colors.surfaceContainerHighest,
        highlightColor: colors.surfaceContainerLow,
      ),
      child: SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: _tileCount,
          separatorBuilder: (_, _) => const SizedBox(height: spacing),
          itemBuilder: (_, index) => ProductListTile(
            testId: 'skeleton_$index',
            caption: 'Category',
            title: 'Product name here',
            price: 999,
            mrp: 1299,
            isWishlisted: true,
            onAdd: () {},
            onWishlistPressed: () {},
          ),
        ),
      ),
    );
  }
}
```

Rule: `<Screen>LoadingSkeleton`, a sliver, placeholder values in the real widgets, callbacks `() {}`, `testId: 'skeleton_…'`;
the layout constants the loaded list shares (`spacing`, `padding`) are `static const` on the skeleton and read by the page.
Exception in the repo: `HomeLoadingSkeleton._BannerPlaceholder` uses `Bone(height: …, borderRadius: …)` (see §4).
Tests pump fixed durations (`tester.pump(const Duration(milliseconds: 300))`) because the shimmer never settles, and assert
`SkeletonizerScope.enabled` and the real widget type (`find.byType(ProductCard), findsWidgets`).

### P19. Feature widget wraps a generic widget

Complete file `lib/features/wishlist/presentation/widgets/wishlist_product_tile.dart` (see §1); the AGENTS §21 example is
`CatalogProductCard`. Shape:

```dart
class WishlistProductTile extends StatelessWidget {
  const WishlistProductTile({super.key, required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final variant = product.cheapestVariant;
    final stock = variant?.stock;
    final quantity = context.select(
      (CartBloc bloc) =>
          variant == null ? 0 : bloc.state.quantityOf(variant.id),
    );
    final category = context.select(
      (WishlistBloc bloc) => bloc.state.categoryNameOf(product),
    );

    void remove() =>
        context.read<WishlistBloc>().add(WishlistToggled(product.id));

    return ProductListTile(
      key: Key('wishlist_item_${product.id}'),
      testId: product.id,
      caption: category,
      title: product.title,
      imageUrl: product.thumbnail,
      price: variant?.price ?? 0,
      mrp: variant?.mrp,
      discountPercent: variant?.discountPercent ?? 0,
      inStock: variant != null && (stock == null || stock > 0),
      isComingSoon: product.isComingSoon,
      isWishlisted: true,
      quantity: quantity,
      wishlistKey: Key('wishlist_toggle_${product.id}'),
      onTap: () => ProductDetailPage.open(context, product.id),
      onLongPress: remove,
      onWishlistPressed: remove,
      onAdd: variant == null
          ? null
          : () => context.read<CartBloc>().add(
              CartItemAdded(cartItemFor(product, variant), maxQuantity: stock),
            ),
      // Greyed out once the cart holds all the stock there is.
      onIncrement: variant == null || (stock != null && quantity >= stock)
          ? null
          : () => context.read<CartBloc>().add(
              CartItemIncremented(variant.id, maxQuantity: stock),
            ),
      onDecrement: variant == null
          ? null
          : () => context.read<CartBloc>().add(CartItemDecremented(variant.id)),
    );
  }
}
```

Rule: the generic widget (in `core/widgets/`) takes plain values and callbacks; the feature widget (in the feature's `widgets/`)
reads blocs with `context.select`, maps the entity to those values and dispatches events; it passes `null` to disable a callback.
Header wrappers follow the same rule over `PageHeader` (`WishlistHeader`, `AddressFormHeader`, `ReviewPayHeader`):

```dart
    return PageHeader(
      title: 'My Wishlist',
      subtitle: itemCount == 0
          ? 'Save the plants you love'
          : '$itemCount ${itemCount == 1 ? 'item' : 'items'} saved'
                ' · hold a card to remove',
      subtitleKey: const Key('wishlist_subtitle'),
      backKey: const Key('wishlist_backButton'),
      onBack: onBack,
      trailing: const _HeartBadge(),
    );
```

### P20. Picker sheets: a top-level `showXSheet` function returning `Future<T?>`, choices pop the value

Complete file `lib/features/checkout/presentation/review_pay/widgets/payment_method_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/widgets/section_label.dart';
import '../../../../../core/widgets/sheets/app_picker_sheet.dart';
import '../../../../../core/widgets/sheets/option_tile.dart';
import '../../../domain/entities/payment_method.dart';
import '../utils/payment_method_text.dart';

/// The picker for how to pay: online, or cash on delivery. Completes with
/// the chosen method, or null when the sheet was closed.
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

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.total,
    required this.selected,
    required this.codCharge,
  });

  /// The server's grand total, or null while it is not known.
  final double? total;
  final PaymentMethod selected;

  /// The cash-on-delivery charge from the charge rules; 0 when none.
  final double codCharge;

  static const EdgeInsets _labelPadding = EdgeInsets.fromLTRB(0, 8, 0, 8);

  @override
  Widget build(BuildContext context) {
    return AppPickerSheet(
      key: const Key('reviewPay_paymentSheet'),
      title: total == null
          ? 'Choose how to pay'
          : 'Bill total: ${formatRupees(total!)}',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel(title: 'Pay online', padding: _labelPadding),
          _option(context, PaymentMethod.online),
          const SizedBox(height: 12),
          const SectionLabel(title: 'Pay on delivery', padding: _labelPadding),
          _option(context, PaymentMethod.cashOnDelivery),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, PaymentMethod method) {
    return OptionTile(
      key: Key('reviewPay_payment_${method.name}'),
      label: paymentMethodLabel(method),
      subtitle: paymentMethodDescription(method, codCharge: codCharge),
      icon: paymentMethodIcon(method),
      selected: method == selected,
      onTap: () => Navigator.of(context).pop(method),
    );
  }
}
```

A sheet whose answer has two kinds uses a result class with named constructors (`delivery_address_sheet.dart`):

```dart
class DeliveryAddressPick {
  const DeliveryAddressPick.saved(SavedAddress this.address);

  const DeliveryAddressPick.addNew() : address = null;

  final SavedAddress? address;
}
```

and the caller: `final pick = await showDeliveryAddressSheet(context, addresses: …, selected: …); if (pick == null || bloc.isClosed || !context.mounted) return; if (pick.address case final address?) { bloc.add(ReviewPayAddressChanged(address)); } else { await _editAddress(context); }`.

A sheet with its own bloc (`gstin_sheet.dart`) puts the `BlocProvider` **inside the builder**, so the bloc lives with the sheet:

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

and closes itself from a `BlocListener` (`Navigator.of(context).pop(state.verified)` after `gstinSheetCloseDelay`).
Rule: pass values in, act on the result in the page; the sheet never reads the page's bloc. The sheet widget is private; only the
`show…` function and the result type are public.

### P21. Splash: dispatch, wait for a resolved state, then route

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

Tests rely on `SplashPage.displayDuration` (`await tester.pump(SplashPage.displayDuration); await tester.pumpAndSettle();`).

### P22. Blocking back and input while an operation runs

`LoginPage`: `PopScope(canPop: step == LoginStep.details, onPopInvokedWithResult: (didPop, _) { if (!didPop) context.read<LoginBloc>().add(EditPhoneNumber()); }, …)`.
`ReviewPayPage`: `PopScope(canPop: !isPlacing, child: Stack(fit: StackFit.expand, children: [Scaffold(extendBody: true, body: AbsorbPointer(absorbing: isPlacing, child: …), bottomNavigationBar: _PayBar(...)), if (paymentPhase != null) PaymentGateOverlay(key: const Key('reviewPay_paymentGate'), phase: paymentPhase, total: total, onCancel: () => context.read<ReviewPayBloc>().add(ReviewPayPaymentCancelled()))]))`.
`LoginPage` also wraps the body in `GestureDetector(onTap: () => FocusScope.of(context).unfocus(), behavior: HitTestBehavior.opaque, …)` and calls `FocusScope.of(context).unfocus()` before dispatching a submit; `AddressFormPage` uses `ListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag)`.

### P23. An invisible analytics widget wrapping `MultiBlocListener`

```dart
class ReviewPayAnalytics extends StatefulWidget {
  const ReviewPayAnalytics({super.key, required this.child});

  final Widget child;

  @override
  State<ReviewPayAnalytics> createState() => _ReviewPayAnalyticsState();
}

class _ReviewPayAnalyticsState extends State<ReviewPayAnalytics> {
  bool _billReported = false;
  // _onBill / _onProcessing / _onFailure call context.read<AnalyticsService>()…
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ReviewPayBloc, ReviewPayState>(
          listenWhen: (previous, current) =>
              previous.quote == null && current.quote != null,
          listener: (context, state) => _onBill(state),
        ),
        BlocListener<ReviewPayBloc, ReviewPayState>(
          listenWhen: (previous, current) =>
              !previous.isPlacing && current.isPlacing,
          listener: (context, state) => _onProcessing(state),
        ),
        BlocListener<ReviewPayBloc, ReviewPayState>(
          listenWhen: (previous, current) =>
              current.placeFailure != null &&
              current.placeFailure != previous.placeFailure,
          listener: (context, state) => _onFailure(state),
        ),
      ],
      child: widget.child,
    );
  }
}
```

Rule: screens report through `context.read<AnalyticsService>()` from listeners or tap handlers, never from `build`; "once" flags are
widget state. Blocs report from inside handlers through their optional `_analytics`. Screen views are reported by the router
(`AnalyticsRouteObserver`), never by pages.

### P24. Stale-answer guards: `_session` and `_request` counters

```dart
  /// Bumped on every sign-in and sign-out. An answer that arrives for an
  /// earlier user is dropped.
  int _session = 0;
  …
    final session = ++_session;     // in Started
    …
    if (session != _session) return;   // after every await
  …
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
```

`ReviewPayBloc` does the same per request: `int _request = 0; … final request = ++_request; … if (request != _request) return;`.
Every app-wide user-scoped bloc (`WishlistBloc`, `MaliCoinsBloc`, `LocationBloc`, `CouponBloc`) has `_session` and a `Cleared` event.

### P25. Route args class + router decoding + typed `pushNamed` result

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

Router (`app_router.dart`): `final extra = state.extra; final args = extra is AddressFormArgs ? extra : const AddressFormArgs(); return AddressFormPage(address: args.address, makeDefault: args.makeDefault);`.
Caller: `final saved = await context.pushNamed<SavedAddress>(AppRoute.addressForm.name, extra: AddressFormArgs(address: address, makeDefault: makeDefault)); if (saved != null && !bloc.isClosed) bloc.add(ReviewPayAddressChanged(saved));`.
Page: `void _close(BuildContext context, [SavedAddress? saved]) { if (context.canPop()) { context.pop(saved); } else { context.goNamed(AppRoute.savedAddresses.name); } }`.
Required-extra routes guard with `redirect: (context, state) => state.extra is OrderPlacedArgs ? null : AppRoute.home.path`.
Path parameters are static consts on the page (`ProductDetailPage.idParam`, opened through `ProductDetailPage.open(context, id)`);
query parameters likewise (`CategoriesPage.categoryParam`, `stockParam`, `searchParam`, `newSearchRequest()`), e.g.
`context.goNamed(AppRoute.categories.name, queryParameters: {CategoriesPage.searchParam: CategoriesPage.newSearchRequest()})`.

### P26. Clearing an old failure on the next edit (`LoginBloc._withoutFailure`)

```dart
  void _onNameChanged(NameChanged event, Emitter<LoginState> emit) {
    emit(
      _withoutFailure(state.copyWith(name: event.name, nameError: () => null)),
    );
  }
  …
  LoginState _withoutFailure(LoginState state) {
    if (state.failure == null && state.status != LoginStatus.failure) {
      return state;
    }
    return state.copyWith(
      failure: () => null,
      status: state.status == LoginStatus.failure ? LoginStatus.idle : null,
    );
  }
```

Guards at the top of action handlers: `if (!state.canSubmit || state.status == LoginStatus.requestingOtp) return;`,
`if (state.isSubmitting) return;`, `if (state.isSaving || state.status == AddressFormStatus.saved) return;`, `if (!state.canPay) return;`,
`if (state.pendingIds.contains(id)) return;`.

### P27. DI registration of blocs

```dart
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

void registerGardenFeature() {
  sl.registerFactory(GardenBloc.new);
}

void registerHomeFeature({String imageBaseUrl = ''}) {
  sl.registerFactory(
    () => HomeBloc(
      getHomeSections: sl(),
      …
      imageBaseUrl: imageBaseUrl,
    ),
  );
}
```

`configureDependencies()` calls `registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl)`; tests call `registerHomeFeature()`.
Each `register<Feature>Feature()` doc comment names the other `register…Feature()` calls that must come first.

### P28. App-wide providers and the sign-in/sign-out fan-out (`app.dart`)

```dart
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ThemeBloc>(create: (_) => sl<ThemeBloc>()),
        // Eager, so the stored cart is loaded before any screen needs it.
        BlocProvider<CartBloc>(
          lazy: false,
          create: (_) => sl<CartBloc>()..add(CartStarted()),
        ),
        BlocProvider<WishlistBloc>(create: (_) => sl<WishlistBloc>()),
        …
        RepositoryProvider<AnalyticsService>(
          create: (_) => sl<AnalyticsService>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                (current is Authenticated &&
                    (previous is! Authenticated ||
                        previous.user.id != current.user.id)) ||
                (current is Unauthenticated && previous is! Unauthenticated),
            listener: (context, state) {
              context.read<WishlistBloc>().add(
                state is Authenticated
                    ? WishlistStarted(state.user.id)
                    : WishlistCleared(),
              );
              …
            },
          ),
```

Rule: every user-scoped app-wide bloc has a `Started` (with the user id when it needs it) and a `Cleared`, both sent from this one
listener; services widgets need (`AnalyticsService`, `KoEngagementService`) are `RepositoryProvider`s so `context.read<T>()` works.

### P29. Tests

Bloc test (`home_bloc_test.dart`): construct the bloc with use cases over fake repositories, `tearDown(() => bloc.close())`, and

```dart
  Future<List<HomeState>> dispatch(HomeEvent event, int count) {
    final states = bloc.stream.take(count).toList();
    bloc.add(event);
    return states;
  }
  …
    test('shows the saved rails, then the fresh ones', () async {
      expect(await dispatch(HomeStarted(language: 'en'), 3), [
        stale,
        // The saved rails stay on screen while the fresh ones load.
        stale.copyWith(isRefreshing: true),
        loaded,
      ]);
    });
```

(`login_bloc_test.dart` also uses `Future<LoginState> dispatch(LoginEvent event) async { bloc.add(event); return bloc.stream.first; }`
and `pumpEventQueue()`; a fake's `Completer<void>? gate` holds a call open: `wishlist.gate = Completer<void>(); … wishlist.gate!.complete();`.)

Widget test (`wishlist_page_test.dart`): register fakes by repository interface, `registerFakeEngagement()`, call the
`register<Feature>Feature()` functions, `tearDown(sl.reset)`, then

```dart
  Future<void> launchHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(App(router: AppRouter().router));
    await tester.pump(SplashPage.displayDuration);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  WishlistBloc bloc(WidgetTester tester) =>
      BlocProvider.of<WishlistBloc>(tester.element(find.byType(Scaffold).last));
```

A page under test alone (`garden_home_page_test.dart`) is pumped as
`RepositoryProvider<AnalyticsService>.value(value: sl<AnalyticsService>(), child: MaterialApp(theme: AppTheme.dark, home: const GardenHomePage()))`.
A root-pushed page is reached with `unawaited(router.pushNamed(AppRoute.reviewPay.name)); await tester.pumpAndSettle();`.
Sheets are driven with `AppInfoSheet.actionKey` / `closeKey`, `AppPickerSheet.closeKey`; text by `find.text(...)`; widgets by
`tester.widget<PrimaryButton>(find.byKey(...)).onPressed`.

### P30. "Ask once per launch" widget with a static flag (`PushPermissionPrompt`)

```dart
class PushPermissionPrompt extends StatefulWidget {
  const PushPermissionPrompt({required this.child, super.key});

  final Widget child;

  static const Duration settleDelay = Duration(seconds: 1);
  static const Duration locationWait = Duration(seconds: 30);

  static bool _asked = false;

  /// Lets the prompt ask again; for tests.
  @visibleForTesting
  static void resetForTest() => _asked = false;
  …
}
```

State: `Timer? _timer;` started in `initState` when `!_asked`, cancelled in `dispose`; `_ask` re-checks `mounted` and `_asked`,
waits on another bloc's stream with `.timeout(locationWait)` catching `TimeoutException` and `StateError`, then `unawaited(engagement.registerPush())`.
`build` returns `widget.child`.

### P31. Top-level constants exported for tests

`const String placingOrderNote = '…';` at the bottom of `review_pay_page.dart`; `const Duration gstinSheetCloseDelay = Duration(milliseconds: 650);`
in `gstin_sheet.dart`; `const String paymentGateCancelLabel = 'Cancel payment';` in `payment_gate_texts.dart`;
`static const Duration displayDuration` on `SplashPage`. Tests import them rather than repeating the literal.
---

## 4. Rules observed in code

Rules the code follows that AGENTS.md does not state, or states differently. Where AGENTS.md is quoted, the quote is verbatim.

### 4.1 Rules the code adds (not in AGENTS.md)

1. **Bloc files re-export their event and state files** (`export 'x_event.dart'; export 'x_state.dart';`), so every importer uses one path `…/bloc/<x>_bloc.dart`. Every bloc in the repo does this.
2. **Page = provider only; view = everything else.** `<X>Page` (public, `StatelessWidget`, `const <X>Page({super.key})`) returns `BlocProvider<XBloc>(create: (_) => sl<XBloc>()…, child: const _XView())`; `_XView` holds the listeners and the `Scaffold`. A page over an app-wide bloc (`WishlistPage`) skips the provider and puts the listener directly in `build`.
3. **Private sub-widget naming:** `_XView`, `_XBody`, `_XFailure`, `_EmptyX`, `_StepPage`, `_SaveBar`, `_PayBar`, `_HeartBadge`, `_Gap`, `_SeededField`, `_AddressTextField`, `_PhoneField`, `_StateField`, `_CountryField`, `_LabelField`.
4. **Keys:** every `Scaffold` has `Key('<prefix>_page')`, every scroll view `Key('<prefix>_scrollView')`; SnackBars end in `Message`, sheets in `Sheet`, the retry `ReloadWidget` is `<prefix>_retryButton`, skeletons `<prefix>_loadingSkeleton`; dynamic keys interpolate an id after a second underscore (§2.7). AGENTS §10 only says "Give interactive widgets stable `Key`s (`Key('login_getOtpButton')`)".
5. **`listenWhen` on every listener plus a one-line comment above it naming the moment** (the only exception is `LoginPage`'s `BlocListener<AuthBloc>`). The forms are catalogued in §3 P10.
6. **Listener bodies become methods** `void _onX(BuildContext context, XState state)` when longer than a line, passed as `listener: _onX`.
7. **Status enums** start with `initial` (or `idle`/`editing`), every value has a doc comment, and the state exposes `isLoading`, `isBusy` (`isLoading || isRefreshing`) and feature-specific `can…` getters (`canSubmit`, `canPay`, `canRedeemCoins`).
8. **The `copyWith` doc comment is fixed text:** "Nullable fields take a getter so they can be explicitly cleared, e.g. `copyWith(<field>: () => null)`." (present on `LoginState`, `WishlistState`, `HomeState`, `AddressFormState`, `ReviewPayState`, `CouponState`, `MaliCoinsState`, `LocationState`, `CartState`).
9. **Events are never `const`**, have no `const` constructors, and every one has a doc comment saying when it is sent. Event aliases are `typedef`s. Enums that enumerate a form's fields live in the event file.
10. **A state that derives collections in its constructor is non-const** (`WishlistState`), and the derived fields are in `props`.
11. **Parallel use-case calls use records + `.wait`:** `final (a, b, c) = await (f1, f2, f3).wait;` (HomeBloc, WishlistBloc). `ReviewPayBloc._onStarted` uses `Future.wait([...])` for void futures.
12. **Stale-answer guards:** app-wide user-scoped blocs keep `int _session`, bump it in `Started` and `Cleared`, and `if (session != _session) return;` after every `await`; `ReviewPayBloc` keeps `int _request` per quote. `_reset(emit)` emits the empty state only if the state differs.
13. **Optional analytics everywhere:** blocs take `AnalyticsService? analytics` last, store `_analytics`, call `_analytics?.track(AppEvents.x, properties: {...})`; a failure is reported as `failure.runtimeType.toString()`. Widgets use `context.read<AnalyticsService>()` only in listeners/tap handlers.
14. **Bloc guards at the top of action handlers** (`if (state.isSubmitting) return;`, `if (!state.canPay) return;`, `if (state.pendingIds.contains(id)) return;`) make double taps no-ops; `_withoutFailure` clears a stale failure on the next edit.
15. **Clock injection in blocs** that create timestamps: `DateTime Function() now = DateTime.now` (`AddressFormBloc`, `CouponBloc`), tested with a fixed epoch.
16. **Navigation idioms:** tabs/replace with `context.goNamed(AppRoute.x.name)`; full-screen pushes with `context.pushNamed(...)` (optionally typed, `pushNamed<SavedAddress>`, with `extra:`); back from a root-pushed page is `context.canPop() ? context.pop() : context.goNamed(AppRoute.<fallback>.name)`; a pushed page returns its result with `context.pop(saved)`. Path/query parameter names are `static const` on the page class; a page may expose `static void open(BuildContext, id)`.
17. **After an `await` in UI code**, the bloc is captured beforehand and `bloc.isClosed` / `context.mounted` are checked before using either.
18. **Snapshots of app-wide state at creation** use `context.read<X>().state` inside `BlocProvider.create`; the device locale is read with `WidgetsBinding.instance.platformDispatcher.locale.languageCode` because `create` cannot listen to inherited widgets.
19. **Feedback placement:** a failure of an app-wide bloc that can happen on any tab (`WishlistState.toggleFailure`) is shown by the shell (`AppShellScaffold`), not by a page.
20. **Pages float the cart bar** by putting `const CartBarOverlay()` last in a `Stack` and adding `CartBarOverlay.height` (plus `MediaQuery.paddingOf(context).bottom`) to the scroll view's bottom padding; the shell uses `Scaffold(extendBody: true)` so its bar's height arrives as bottom padding.
21. **Skeleton layout constants** (`spacing`, `padding`) are `static const` on the skeleton and reused by the loaded list so bones line up.
22. **Skeleton tests** pump fixed durations (`tester.pump(const Duration(milliseconds: 100/300/500))`) because the shimmer never settles; page tests that hold a load open do the same.
23. **Widget tests** always set `tester.view.physicalSize = const Size(1170, 2532); tester.view.devicePixelRatio = 3; addTearDown(tester.view.reset);`, pump `App(router: AppRouter().router)`, wait `SplashPage.displayDuration`, register fakes by **repository interface**, call `registerFakeEngagement()` **before** `registerAuthFeature()` (the `AuthBloc`/`LoginBloc` factories resolve `analytics: sl()`), and `tearDown(sl.reset)`. A `tapKey(tester, key)` helper does `ensureVisible` → `tap` → `pumpAndSettle`.
24. **Bloc tests** build the bloc directly over fake repositories, use a `dispatch(event, count)` helper that subscribes with `bloc.stream.take(count).toList()` *before* `bloc.add`, and gate async calls with `Completer<void>` fields on the fakes.
25. **Text helpers for enums** live next to the failure helpers in `utils/` (`payment_method_text.dart`, `payment_gate_texts.dart`, `charge_notes.dart`); they are pure functions returning `String`/`IconData`, tested on their own.
26. **Sheets are functions:** `Future<T?> show<X>Sheet(BuildContext context, {…})` over `AppPickerSheet.show<T>`, private sheet widget, choices call `Navigator.of(context).pop(value)`; a two-kind answer is a small result class with named constructors. A sheet with its own bloc provides it inside the builder.
27. **Public constants that tests need** are top-level `const`s in the page/widget file (`placingOrderNote`, `gstinSheetCloseDelay`) or `static const` on the widget (`SplashPage.displayDuration`, `PushPermissionPrompt.settleDelay`).
28. **"Not built yet" is a `TODO(<feature>)` comment** on the class (`TODO(garden)`, `TODO(search)`, `TODO(settings)`, `TODO(routing)`).
29. **`Failure` is compared by identity** in `listenWhen` (`current.failure != previous.failure`); it is not Equatable, so a fresh instance of the same type re-triggers the listener (this is relied upon for repeated retries).
30. **Dart language level:** switch expressions with `||` patterns and `when` guards, record destructuring (`final (title, message) = verifyFailureText(...)`), `if (x case final y?)`, null-aware elements in collection literals (`[?_tracker?.observer()]` in `app_router.dart`, `[for (final item in items) ?byId[item.productId]]` in `wishlist_products.dart`) — the code targets a recent SDK (`pubspec.yaml`: `sdk: ^3.13.4`).

### 4.2 Where the code differs from AGENTS.md

| AGENTS.md says | the code does | files |
|---|---|---|
| §21 "Never build bones yourself: no `Bone`, `Bone.text`, `Bone.square` or other `Bone.*` widgets" | `_BannerPlaceholder` draws `Bone(height: HomeBannerCarousel.cardHeightFor(context), borderRadius: BorderRadius.circular(HomeBannerCarousel.cardRadius))` because the real carousel is a `StatefulWidget` with a timer. Only `Bone(` usage in `lib/`. | `lib/features/home/presentation/home/widgets/home_loading_skeleton.dart:55` |
| §10 "Read state with `context.select` so only the parts that changed rebuild." | `final state = context.watch<ReviewPayBloc>().state;` in `_ReviewPayBody` (also `context.watch<OrderPlacedBloc>()` in `order_placed_page.dart:180` and `context.watch<ApplyCouponBloc>()` in `apply_coupon_page.dart:100`). Everywhere else `select`. | `review_pay_page.dart:483` |
| §11 "Never use `Color(0x…)`, `Colors.xyz` or `AppColors.*` inside widgets" and "never with a hardcoded `fontSize` in a widget" | `Colors.white.withValues(alpha: 0.14)`, `Colors.white`, `TextStyle(fontSize: 26)`, `fontSize: 14` in `LoginHeader`/`_VerifyHeading`; `Colors.white`, `Colors.black.withValues(alpha: 0.12)`, `fontSize: tileSize * 0.36`, `fontSize: 14` in `BrandMark`/`BrandLogoTile`. The other five screens have none. | `login_header.dart:56-57,93,113`, `brand_mark.dart:27-31,42,76,80` |
| §1 stack table (packages) + "Do not add a package without asking the user first." | `gap` (`Gap(10)` in `login_details_step.dart`, `login_otp_step.dart`) and `loading_animation_widget` (`LoadingAnimationWidget.staggeredDotsWave` in `splash_page.dart`) are used but not listed; `pubspec.yaml` also carries `toastification`, `connectivity_plus`, `internet_connection_checker`, `intl_phone_field`, `intl`, `geolocator`, `geocoding`, `image_picker`, `package_info_plus`, `url_launcher`, `crypto` unlisted in the table. | `pubspec.yaml` |
| §22 "Do not add a new `AlertDialog`… The OTP verify dialog in `LoginPage` predates this sheet; leave it unless asked." | `LoginPage._onVerifyResult` uses `showDialog<void>` + `AlertDialog` (acknowledged legacy). Send failures use a `SnackBar`, not a sheet. | `login_page.dart:66-88` |
| §4 "Presentation maps failure **types** to user-facing text… Never show raw API codes, `detail` strings or exception messages" | `AuthBloc._onLogoutRequested` emits `AuthFailure(failure.message)` — a raw failure message in state. No widget renders it today. `placeOrderFailureMessage` shows `PaymentFailedFailure.detail` for `PaymentFailureReason.unknown` (deliberate, documented). | `auth_bloc.dart:81`, `place_order_failure_message.dart:106-111` |
| §2 layout `presentation/<screen>/{bloc,pages,widgets,utils}` | Single-screen features omit the `<screen>` level: `wishlist/presentation/{bloc,pages,widgets,utils}`, `garden/presentation/{bloc,pages,widgets}`; auth keeps `presentation/bloc` (app-wide) **and** `presentation/login/…`, `presentation/splash/pages`, `presentation/widgets`. | folder tree, §1.3 |
| §20 bloc recipe "On the start event: 1. Call the cached use case … 2. Refresh" | `HomeBloc._onHomeStarted` first stores `_language`, returns if `state.isBusy`, and calls `_showCached` only when `state.status != HomeStatus.loaded`. `WishlistBloc._onStarted` resets the state first (`_reset(emit)`) because the user may have changed. | `home_bloc.dart:65-74`, `wishlist_bloc.dart:83-94` |
| §20 "The failed-refresh message: … shows a `SnackBar` with `refreshFailureMessage(state.failure)`" | Home follows it literally; the wishlist names its helper `wishlistRefreshFailureMessage`, addresses `addressesRefreshFailureMessage` — the name is prefixed per feature except on Home. | `utils/failure_message.dart` files |
| §13 "Keep `initialValue: ''` (non-null) on a text field" | `PhoneNumberField` and `OtpCodeField` pass no `initialValue` (the phone and OTP field types keep their own text); `_StateField` passes `null` for an empty dropdown. Only `UFFType.text` fields pass `''`. | `phone_number_field.dart`, `otp_code_field.dart`, `address_form_fields.dart` |
| §21 "`AppCard` … Do not hand-build another rounded `Container` card" | Review & Pay rows sit on the cart feature's `CartSectionCard` (`Material` + `RoundedRectangleBorder`), not `AppCard`; `PaymentGateOverlay` does use `AppCard`. | `cart_section_card.dart`, review_pay widgets |
| §12 "Small inline text actions (e.g. "Resend code", "Edit") may use Material `TextButton`" | followed; additionally `IconButton.filledTonal` (login back), `IconButton` (bill (i), banner dismiss), `TextButton.icon` ("VIEW", "Change") appear in feature widgets. | `login_header.dart`, `bill_details_card.dart`, `coupon_row.dart`, `delivery_address_card.dart` |
| §10 "Events … **never** extend `Equatable`" | true for every `presentation/**/bloc/*_event.dart`. (`lib/features/orders/domain/entities/order_event.dart` defines a **domain entity** `OrderEvent extends Equatable` — a timeline entry, not a bloc event; do not confuse the two when copying.) | — |
| §17 "The signed-in user … read it with `context.select((AuthBloc b) => b.state)` and check `state is Authenticated`" | `HomeHeader` selects a projection instead (`switch (bloc.state) { Authenticated(:final user) => user.fullName, _ => null }`); `AddressFormPage`/`ReviewPayPage` use `context.read<AuthBloc>().state` + `is Authenticated`. | `home_header.dart:24-29` |

---

## 5. Packages

| package | files in this area that import it | ALWAYS / CONDITIONAL |
|---|---|---|
| `flutter_bloc` (`Bloc`, `BlocProvider`, `BlocListener`, `MultiBlocListener`, `RepositoryProvider`, `context.read/select/watch`) | every `*_bloc.dart`, every page, every bloc-reading widget (`login_details_step`, `name_field`, `wishlist_product_tile`, `home_header`, `home_section_view`, `push_permission_prompt`, `garden_feature_poll`, `address_form_fields`, `review_pay_analytics`, …) | ALWAYS |
| `bloc` | transitively (`flutter_bloc` re-exports); listed in `pubspec.yaml` | ALWAYS |
| `equatable` | every `*_state.dart` (`AuthState`, `LoginState`, `WishlistState`, `HomeState`, `GardenState`, `AddressFormState`, `ReviewPayState`), `NoParams`, entities | ALWAYS |
| `fpdart` (`Either`, `Left`, `Right`, `.match`, `.getOrElse`, `.toNullable`, `.flatMap`, `.isRight`) | `wishlist_bloc.dart`, `review_pay_bloc.dart`, `cart_bloc.dart`, `cart_event.dart`; implicitly every bloc that `match`es a use-case result | ALWAYS |
| `go_router` (`context.goNamed`, `pushNamed<T>`, `pop`, `canPop`, `StatefulNavigationShell`) | `login_page.dart`, `splash_page.dart`, `wishlist_page.dart`, `home_page.dart`, `home_header.dart`, `home_section_view.dart`, `address_form_page.dart`, `review_pay_page.dart`, `cart_bar_overlay.dart`, `app_shell_scaffold.dart`, `app_router.dart` | ALWAYS |
| `get_it` (`sl`) | pages (`login_page`, `home_page`, `garden_home_page`, `address_form_page`, `review_pay_page`, `gstin_sheet`), `app.dart`, `injection_container.dart`, tests | ALWAYS |
| `skeletonizer` (`Skeletonizer.sliver`, `ShimmerEffect`, `Bone`, `SkeletonizerScope` in tests) | `wishlist_loading_skeleton.dart`, `home_loading_skeleton.dart`, `home_loading_skeleton_test.dart` | ALWAYS (loading placeholders) |
| `flutter/services.dart` (SDK: `SystemUiOverlayStyle`, `TextInputFormatter`, `FilteringTextInputFormatter`) | `login_page.dart`, `splash_page.dart`, `phone_number_field.dart`, `otp_field.dart`, `address_form_fields.dart`, `gstin_sheet.dart` | SDK |
| `gap` (`Gap(n)`) | `login_details_step.dart`, `login_otp_step.dart` | CONDITIONAL (cosmetic; `SizedBox` elsewhere; not in AGENTS §1) |
| `loading_animation_widget` (`LoadingAnimationWidget.staggeredDotsWave`) | `splash_page.dart` | CONDITIONAL (splash spinner; not in AGENTS §1) |
| `url_launcher` (`launchUrl`, `LaunchMode.externalApplication`) | `home_page.dart` (banner web links) | CONDITIONAL(external links) |
| `intl` (`NumberFormat.currency`) via `core/utils/currency_format.dart` | `review_pay_page.dart`, `charge_notes.dart`, `payment_gate_texts.dart`, `payment_method_text.dart`, `review_pay_bar.dart`, `payment_method_sheet.dart`, `bill_details_card.dart`, `coupon_nudge_banner.dart`, `mali_coins_row.dart`, `coupon_row.dart`, `coupon_failure_message.dart` | CONDITIONAL(money formatting) |
| `cached_network_image` via `core/widgets/app_network_image.dart` | `home_banner_carousel.dart` (`AppNetworkImage`); test asserts on `CachedNetworkImage` | CONDITIONAL(network images) |
| `intl_phone_field` via `UniversalFormField` (`UFFType.phone`) | `phone_number_field.dart`, `address_form_fields.dart` | CONDITIONAL(phone input) |
| `katyayani_core` via `KoEngagementService` | `push_permission_prompt.dart` (`context.read<KoEngagementService>()`), `app.dart` | MYMALI-SPECIFIC |
| `supabase_flutter` | `injection_container.dart` only (not presentation) | CONDITIONAL(Supabase) |
| `flutter_test` + hand-written fakes (no mockito/mocktail/bloc_test) | all tests | ALWAYS |

`dart:async` (`Timer`, `Completer`, `unawaited`, `TimeoutException`) and `dart:math` are SDK imports used in `splash_page.dart`,
`resend_countdown.dart`, `home_banner_carousel.dart`, `push_permission_prompt.dart`, `wishlist_bloc.dart`, `review_pay_bloc.dart`, `garden_hero.dart`.
---

## 6. What varies per app

Exact list of things another app substitutes, and where each appears in this area.

| what | MyMali value(s) | where it appears |
|---|---|---|
| Feature names and screen prefixes for keys | `login`, `wishlist`, `home`, `garden`, `addressForm`, `reviewPay`, `gstinSheet`, `shell`, `orderPlaced`, `account`, `catalog`, `cart` | every `Key('<prefix>_…')` (§2.7) |
| Route names and paths | `AppRoute.splash('/splash')`, `login`, `home`, `categories`, `garden`, `wishlist`, `account`, `cart`, `selectLocation`, `coins`, `reviewPay`, `orderPlaced`, `invoice`, `applyCoupon`, `savedAddresses`, `addressForm`, `editProfile`, `referral`, `gstClaims`, `notifications`, `helpSupport`, `productDetail('/product/:id')`, `myOrders`, `orderDetails('/orders/:id')` | `app_routes.dart`; `goNamed`/`pushNamed` calls in `splash_page`, `login_page`, `wishlist_page`, `home_page`, `home_header`, `home_section_view`, `address_form_page`, `review_pay_page`, `cart_bar_overlay` |
| Tab branches and navigator keys | home, categories, garden, wishlist, account (`homeNavigatorKey` …) | `app_router.dart`, `navigator_keys.dart`, `app_bottom_nav_bar.dart` `_items`, `analyticsTabs` |
| App-wide blocs provided in `app.dart` | `AuthBloc`, `ThemeBloc`, `CartBloc` (eager), `WishlistBloc`, `LocationBloc`, `MaliCoinsBloc`, `ProfileBloc`, `CouponBloc` (eager) + `RepositoryProvider<KoEngagementService>`, `RepositoryProvider<AnalyticsService>` | `app.dart` providers and the `BlocListener<AuthBloc>` fan-out (`ProfileStarted/Cleared`, `WishlistStarted/Cleared`, `CartSignedIn/SignedOut`, `LocationStarted/Cleared`, `MaliCoinsStarted/Cleared`, `CouponCleared`) |
| Analytics event names | `AppEvents.*` strings ('Login Started', 'OTP Sent', 'Added To Favorite', 'Viewed All Products', 'Banner Clicked', 'Camera Search Tapped', 'Garden Waitlist Joined', 'Address Added', 'Address Changed', 'Change Address Tapped', 'Checkout Step Viewed', 'Checkout Started', 'Payment Started', 'Processing Order', 'Payment Cancelled', 'Payment Unsuccessful', 'Order Unsuccessful', 'Logout', …) and property keys (`'item_id'`, `'value'`, `'currency': 'INR'`, `'method'`, `'stage'`, `'reason'`, `'channel': 'sms'`, `'seed_type'`, `'title'`, `'cta_link'`, `'source': 'garden_home'`, `'address_id'`, `'step': 'review_pay'`, `'items_count'`, `'payment_method'`, `'total'`, `'amount'`) | `app_events.dart`; `login_bloc`, `auth_bloc`, `wishlist_bloc`, `home_page`, `home_section_view`, `garden_home_page`, `address_form_page`, `review_pay_page`, `review_pay_analytics`, `checkout_analytics` |
| Analytics screen names | `analyticsScreenNames` (`'login': 'PhoneEntry'`, `'home': 'ShopTab'`, `'reviewPay': 'ReviewPay'`, …) | `analytics_screen_tracker.dart` |
| Failure types per feature | `InvalidPhoneFailure`, `OtpSendFailure`, `InvalidOtpFailure`, `OtpExpiredFailure`, `OtpNotSentFailure`, `OtpAttemptsExceededFailure`, `OtpVerifyFailure`; `WishlistAuthRequiredFailure`, `WishlistFullFailure`, `WishlistStorageFailure`; `AddressAuthRequiredFailure`, `InvalidAddressFailure`; `LocationPermissionDeniedFailure({isPermanent})`, `LocationServiceDisabledFailure`, `PlaceNotFoundFailure`; checkout: `QuoteAuthRequiredFailure`, `QuoteItemUnavailableFailure({productIds})`, `QuoteUnavailableFailure`, `OrderPhoneMissingFailure`, `OrderAddressFailure(issue)`, `OrderItemsUnidentifiedFailure({productIds})`, `OrderRefusedFailure({reason})`, `OrderStillProcessingFailure`, `OrderOutcomeUnknownFailure`, `OrderNotRegisteredFailure`, `PaymentNotConfiguredFailure`, `PaymentCancelledFailure({upiTimeout})`, `PaymentFailedFailure({reason, detail})` | the `failure_message.dart` switches |
| Every user-facing string | 'OTP sent to …', 'Get OTP', 'Verify & Continue', 'My Wishlist', 'Save the plants you love', 'Your wishlist is empty', 'Browse products', 'Nothing on the shelves yet. Check back soon.', 'Try "tomato seeds", "neem oil"...', 'Hi there', 'Detecting location…', 'Select location', 'MY GARDEN', "You're on the list", 'Tell me when it opens', 'Add new address'/'Edit address', "We'll deliver your order right here", 'Save address', 'Review & Pay', 'Pay & Place', 'PAY USING', 'Bill Details', 'Grand Total', 'Incl. all taxes & charges', `placingOrderNote`, every failure text, every note | pages, widgets, utils |
| Branding | `BrandMark.tagline = 'Plants & garden care, delivered'`, 'my mali', `AppAssets.appLogo`, `AppTheme.displayFontFamily` (Marcellus), `SplashPage.displayDuration = 2600 ms`, `BrandBackdrop` circles | `brand_mark.dart`, `brand_backdrop.dart`, `splash_page.dart`, `login_header.dart` |
| Country / phone / code conventions | `LoginState.countryDialCode = '+91'`, `initialCountryCode: 'IN'`, `phoneNumberLength = 10`, `minNameLength = 2`, `LoginBloc.otpLength = 4`, `normalizeIndianMobile`, `indianStates` / `matchIndianState`, 6-digit pincode (`AddressProblem.pincodeInvalid`), `AddressLabels.country = 'India'`, `AddressLabels.all = ['Home', 'Work', 'Other']`, client address id `'addr_<millisecondsSinceEpoch>'` | `login_state.dart`, `login_bloc.dart`, `phone_number_field.dart`, `address_form_bloc.dart`, `address_form_fields.dart` |
| Currency | `formatRupees` (`en_IN`, `₹`, 0 decimals) | `currency_format.dart` and every money string in review_pay |
| Status enum members | `LoginStatus {idle, requestingOtp, otpSent, failure, verifyingOtp, loggedIn}`, `WishlistStatus`/`HomeStatus {initial, loading, loaded, failure}`, `AddressFormStatus {editing, saving, saved}`, `OnlinePaymentPhase {preparing, paying, placing}`, `CartStatus {initial, loading, ready, failure}` | state files |
| Cross-feature dependencies a page composes | Review & Pay: `CartBloc`, `CouponBloc`, `MaliCoinsBloc`, `AuthBloc`; Home: `MaliCoinsBloc`, `AuthBloc`, `LocationBloc`, `ThemeBloc`, `KoEngagementService`; wishlist tile: `CartBloc`; address form: `AuthBloc` | `review_pay_page.dart`, `home_page.dart`, `home_header.dart`, `push_permission_prompt.dart`, `wishlist_product_tile.dart`, `address_form_page.dart` |
| Business flows | KO-Tech order placement (~44 s COD), Razorpay online payment phases, Mali Coins redeem, coupons nudge/drop, GSTIN sheet, Medusa image base URL (`registerHomeFeature(imageBaseUrl: Env.medusaBaseUrl)`), Katyayani Core push permission | `review_pay_*`, `home_bloc.dart`, `push_permission_prompt.dart`, `injection_container.dart` |
| Test fixtures | `testSession` (user `'user-1'`, `'+919876543210'`, `'Asha'`, userKey `'91987654-3210-0000-0000-000000000000'`), `testProduct` `prod_01` 'Activated Neem Oil' ₹269/₹595 '55% OFF' '12 sold', category `pcat_01` 'Liquid Tonics', `testChargeRules` (₹199 free delivery, small-cart tiers ₹20/₹15/₹10, COD ₹25), coupons `WELCOME10`/`MALI50`, 50 coins | `test/helpers/*` |
| Phone-size test view | `Size(1170, 2532)`, `devicePixelRatio = 3` | every widget test |
| Dart/Flutter level | `sdk: ^3.13.4`, Flutter APIs `PopScope.onPopInvokedWithResult`, `MediaQuery.withClampedTextScaling`, `Color.withValues`, `IconAlignment`, `SliverList.separated` | pubspec, widgets |

---

## 7. Gotchas

1. **Events must not be `Equatable` and must not be `const`.** Pages write `HomeRefreshed()` / `WishlistCleared()` without `const`; adding `const` constructors changes nothing functionally but diverges from every file. Do not confuse with `OrderEvent extends Equatable` in `orders/domain/entities/order_event.dart`, which is a domain entity.
2. **The clearable-getter `copyWith`:** to clear pass `failure: () => null`; to set pass `failure: () => failure`; omitting (or passing `null`) keeps the old value. Mixing in a plain `Failure? failure` parameter breaks the "keep" semantics.
3. **`WishlistState()` is not `const`** (its constructor computes `ids` and `products`). Tests compare with `expect(bloc.state, WishlistState())`; equality holds because `props` includes the derived fields. Keep `super(WishlistState())` without `const`.
4. **`Failure` is not Equatable.** `listenWhen: current.failure != previous.failure` is an identity test; emit a new failure instance for every new attempt or the listener will not fire again. Bloc tests use `same(failure)`.
5. **`isBusy` guards swallow events:** `HomeStarted` during a refresh does nothing except store `_language`; `WishlistRefreshed` during a load is ignored (tested). Put anything that must always be recorded (like `_language`) **before** the guard.
6. **Record `.wait`** on futures of `Either` never throws (repositories return failures); if a future *can* throw, `.wait` raises `ParallelWaitError`, not the original error.
7. **`BlocProvider.create` cannot `watch`:** read `context.read<X>().state` or `WidgetsBinding.instance.platformDispatcher`; the comment in `HomePage` says why. `sl<HomeBloc>()..add(...)` returns the bloc (cascade).
8. **Capture before `await`:** `final bloc = context.read<X>();` before `await AppInfoSheet.show(...)`, then `if (retry) bloc.add(...)`; check `bloc.isClosed` and `context.mounted` after sheets and pushes. `AppInfoSheet.show` resolves `false` on close/swipe/outside tap/system back and `true` only on the button.
9. **Sheets open on the root navigator** (`useRootNavigator: true`), above the bottom bar and outside the page's `BlocProvider` scope: pass values in and act on the result; a sheet that needs a bloc provides its own inside the builder (`showGstinSheet`).
10. **A sheet's "closed" (null) vs "add new"** needs a result class (`DeliveryAddressPick.saved` / `.addNew()`); a bare nullable value cannot tell them apart.
11. **Keying to reset:** `KeyedSubtree(key: ValueKey(requestCount))` empties the OTP boxes on resend; `ValueKey('addressForm_${name}_$revision')` re-seeds a field only when the bloc filled it; `PageStorageKey('home_rail_${section.title}')` keeps a rail's scroll offset; `ResendCountdown(key: ValueKey(requestCount))` restarts the timer. The outer test key stays constant while the inner key changes.
12. **`UniversalFormField` controller trap:** a `UFFType.text` field needs `initialValue: ''` (non-null) or typing breaks (new controller every build); phone/OTP types omit it; a dropdown passes `null` for "nothing chosen".
13. **The skeleton never settles:** tests must `tester.pump(Duration)`; `pumpAndSettle` would hang. `Skeletonizer.sliver` takes the theme's colours explicitly (`ShimmerEffect(baseColor: colors.surfaceContainerHighest, highlightColor: colors.surfaceContainerLow)`) or it follows platform brightness.
14. **`registerFakeEngagement()` must run before `registerAuthFeature()`** in widget tests: the `AuthBloc`/`LoginBloc` factories resolve `analytics: sl()`; without an `AnalyticsService` registered `sl` throws when the bloc is created.
15. **`PushPermissionPrompt._asked` is static** — it persists across tests in one process; call `PushPermissionPrompt.resetForTest()` when a test depends on the prompt.
16. **Bloc event handlers run concurrently by default** (no `transformer`); `ReviewPayPaymentCancelled` relies on this: it sets `_cancelRequested` while `_onOrderRequested` is awaiting. `CartBloc` serialises itself with `_serial`. Do not add `sequential()` transformers to blocs that rely on an in-flight handler reading a flag.
17. **Listener order matters** in `_ReviewPayView`: the coupon-dropped-by-server listener checks `coupons.state.applied?.code != state.rejectedCouponCode` to avoid double messages; the comments above each listener explain the interplay — copy them with the code.
18. **`context.pop(result)` from a root-pushed page** works only when there is something to pop; the `_close` helper falls back to `goNamed` (deep links). `PopScope.canPop` must be false while an operation is in flight, and `AbsorbPointer` must cover the body too (two different things).
19. **`ReloadWidget` fixes its button key to `reload_button`**; the page keys the `ReloadWidget` itself (`<prefix>_retryButton`). Tests tap `reload_button`.
20. **Analytics text:** report `failure.runtimeType.toString()` (or an enum `.name`), never `failure.message`; `AppEvents` names are the React Native app's words — never type an event name at a call site.
21. **`SplashPage.displayDuration` is part of the test protocol**: every `App` test pumps exactly it before `pumpAndSettle`.
22. **Dart format quirk:** `child:\n    UniversalFormField(...)\n    .build(...)` is `dart format` output for a cascaded builder; AGENTS §15 requires `dart format`, so reproduce by formatting, not by hand.
23. **`HomeBloc` optional data degrades per field:** `appState.toNullable() ?? state.appState`, `soldCounts.getOrElse((_) => state.soldBySku)`; only the primary list is fatal. The skeleton test asserts the banner placeholder height equals `HomeBannerCarousel.heightFor(context)` — the skeleton and the real widget must share the sizing functions.
24. **`_StepPage` uses `AutomaticKeepAliveClientMixin`** so typed values survive switching `PageView` steps; `PageView(physics: NeverScrollableScrollPhysics())` because steps change only through the bloc.
25. **The login page listens to the app-wide `AuthBloc`** (`_onAuthStateChanged` → `goNamed(home)`) rather than navigating from `LoginBloc`'s `loggedIn` — the screen reports up (`AuthLoggedIn`) and navigation follows the app-wide state.
26. **`AuthFailure` state exists but no page handles it**; a port should decide whether to map it to text (AGENTS §4) or drop it.
27. **`Bone` and `context.watch`** exist in the repo (see §4.2); a port that enforces AGENTS.md literally must replace `_BannerPlaceholder` with a real `HomeBannerCarousel` placeholder (or a sized `SizedBox` with a decorated child) and split `_ReviewPayBody` into `select`s.
28. **Null-aware collection elements** (`[?a]`, `[for (…) ?x]`) and `sdk: ^3.13.4` mean the target app needs an equally recent Dart; older SDKs fail to compile `app_router.dart` and `wishlist_products.dart`.
