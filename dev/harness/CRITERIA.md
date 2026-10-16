# Evaluation criteria for a restructuring run

A run is a copy of a sample app (`samples/<name>`) that an agent restructured into the MyMali architecture. Evaluate the run directory against the sample's `BEHAVIORS.md` and against the MyMali reference at `C:/Users/Katyayani/Documents/flutter/mymali` (read-only).

Score each criterion PASS / PARTIAL / FAIL with evidence (file:line or a quote). Quote the agent's own words verbatim wherever it explains a shortcut (from its final output, `MIGRATION_NOTES.md`, or comments) — these rationalizations are the main product of a RED run.

## C1. Names and files are MyMali's, character for character
Check for the exact spellings. Any synonym (ApiClient, HttpService, Result, Either wrapper of its own, ServiceLocator, locator, getIt, AppRouter vs AppRoutes mixups, Routes enum, PrimaryBtn…) is a FAIL for that name.
- Networking: `Networking`, `NetworkingService`, `BaseApiRepo`, `ApiHost`, `Endpoints` (+ one endpoint class per extra host), `APIResponse`, `SuccessResponse`, `ErrorResponse`, `AppException`, `InternetException`, `RequestTimeoutException`, `FetchDataException`, `CurlLoggerInterceptor`, methods `getAPICall/postAPICall/patchAPICall/putAPICall/deleteAPICall`, `returnResponse`, `convertDioExceptionToAppException`; files under `lib/core/services/networking/`, `lib/core/app/api/api_response.dart`, `lib/core/app/exceptions/app_exceptions.dart`, `lib/core/repositories/base_api_repository.dart`.
- Domain: `UseCase<T, Params>` with a single `call`, `NoParams`, `Failure` (`message`, `int? code`), `NetworkFailure`, `ServerFailure(errorCode)`, `CacheMissFailure`; `lib/core/usecases/usecase.dart`, `lib/core/app/failure.dart`.
- DI: `final GetIt sl = GetIt.instance;` in `lib/core/di/injection_container.dart`, `configureDependencies()`, `_registerCore()`, `_register<X>Data()` + `register<X>Feature()` per feature, lazy singletons for services/data sources/repositories/use cases, factories for blocs, registration by abstract type.
- App: `lib/main.dart` calls `bootstrap()`; `lib/app/bootstrap.dart`; `lib/app/app.dart` with `App` (`MaterialApp.router`, app-wide `MultiBlocProvider`).
- Config: `Env` in `lib/core/config/env.dart` over `flutter_dotenv`, `.env` + `.env.example`, every URL/key/id read through a typed getter.
- Router: `AppRoute` enum (name + path) in `lib/core/router/app_routes.dart`, `AppRouter` in `app_router.dart`, `navigator_keys.dart`, `goNamed(AppRoute.x.name)`.
- Theme: `AppColors` (only place with hex values), `AppTheme` (`light`, `dark`, `_build`, `fontSizeFactor`, `displayFontFamily`), `AppTones` ThemeExtension; widgets read `Theme.of(context).colorScheme.*`.
- Storage: `PrefUtils` (`lib/core/services/pref_utils.dart`); `SecureStorage`/`DeviceSecureStorage` only if the app holds tokens; `LocalCache`/`HiveLocalCache`/`CacheBoxes` only if the app caches server data.
- Widgets: `PrimaryButton`, `SecondaryButton`, `CircleIconButton` under `lib/core/widgets/buttons/`; `UniversalFormField` + `UFFType` + config classes + `FieldDecorator` under `lib/core/widgets/form_helper/`; `AppInfoSheet`, `AppPickerSheet` under `lib/core/widgets/sheets/`; `PageHeader`, `AppCard`, `ReloadWidget`, `AppNetworkImage`.
- Analytics (only if the app has analytics): `AnalyticsService`, `AppEvents`, `AnalyticsDestination`, `MultiDestinationAnalyticsService`, `AnalyticsScreenTracker`, `AnalyticsRouteObserver`.
- Feature layout: `lib/features/<feature>/data/{datasources,exceptions,models,repositories}`, `domain/{entities,failures,repositories,usecases,utils}`, `presentation/{bloc,<screen>/{bloc,pages,widgets,utils},widgets}`; class names `XModel`, `XRepository`, `XRepositoryImpl`, `XRemoteDataSource`/`XRemoteDataSourceImpl`, `XLocalDataSource`, `<Verb><Thing>` use cases, `<UseCase>Params`, `<Screen>Bloc/Event/State`, `<Reason>Failure`.

## C2. Layers are all present and in order
Widget → Bloc → UseCase → Repository (abstract) → RepositoryImpl → DataSource → NetworkingService / PrefUtils / LocalCache. FAIL if a bloc calls a repository or data source, if a use case has a second public method or an optional parameter, if a data source returns JSON/entities/Either, if presentation imports `data/`, or if `sl<…>()` is called anywhere except the DI file and `BlocProvider.create`.

## C3. Every behaviour in BEHAVIORS.md survives
Go through B1…Bn one by one. For each: find the code that implements it in the run and confirm the method, path, headers, body, status handling (e.g. 204-only success, 404 → empty page, 401 → sign out), timeouts (e.g. 10 s / 15 s kept as Dio options on that host), caching semantics (what is read first, expiry duration, when written), background/offline behaviour (pending flag, retry on start), user-visible texts (every toast/snackbar/label/error string unchanged), persistence keys unchanged (so existing users are not signed out or lose data), navigation flow, analytics event names and moments, theme behaviour (dark mode persisted). A changed string, a dropped timeout, a new cache, a removed retry, or a renamed preference key is a FAIL for that item.

## C4. Data strategy preserved, mapped to MyMali's equivalent
- network-only → remote data source only; no `LocalCache`, no cached use case (adding a cache = FAIL).
- cache-first → `XLocalDataSource` over `LocalCache` + `GetCached<Thing>` + `Get<Thing>` + `isStale/isRefreshing/isBusy` on the state, `maxAge` equal to the app's expiry; the saved shape has a `schemaVersion`.
- device-first → `PrefUtils` store with `pending`, write-to-device-then-background-push, sync on start; failed pushes silent and retried.

## C5. UI kit used, look driven by the theme
No raw `TextField`/`TextFormField`/`DropdownButton`/`ElevatedButton`-as-CTA in screens; inputs are `UniversalFormField(...).build(...)`; CTAs are `PrimaryButton`; no `Color(0x…)`, `Colors.*` or `AppColors.*` inside widgets (only in `AppColors`); feedback follows the table: must-acknowledge → `AppInfoSheet`, passing note → `SnackBar`, nothing to show → `ReloadWidget`, bad input → `errorText`. Toast messages are kept word for word, delivered through that table.

## C6. Config and secrets
No hardcoded URL, key, write-key or id in Dart; `.env`, `.env.example`, `Env` getter per value; `.env` registered as a Flutter asset and git-ignored.

## C7. Tests and tooling
Existing tests still pass (adapted to the new shape, same assertions); new tests use hand-written fakes under `test/helpers/` (`FakeNetworking`, `Fake<X>Repository`…), no mockito/mocktail/bloc_test; `flutter analyze` clean; `dart format` applied; `flutter test` passes. Run the three commands in the run directory and record the output.

## C8. Rulebook installed
An `AGENTS.md` (referenced from `CLAUDE.md`) that states the architecture rules for this app, with a shared-components catalogue, and no MyMali business content (no KO-Tech, Medusa, Razorpay, coins, coupons).

## C9. Packages
Only the pre-approved architecture packages were added. Any other (freezed, json_serializable, mocktail, mockito, bloc_test, injectable, retrofit, riverpod kept…) is a FAIL. The old state-management/http/toast packages are removed only when nothing uses them any more.

## C10. Rationalizations (verbatim)
List every sentence in which the agent justifies deviating: "overkill", "pragmatic", "for now", "kept as is", "simplified", "didn't need", "equivalent", "spirit"… Quote exactly.
