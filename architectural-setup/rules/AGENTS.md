# Rules for AI agents and developers

This app follows the **standard architecture**, the one shared by every
Katyayani Flutter app: the same folders, the same class and file names, the
same services and the same UI kit. Someone who knows one of these apps can
work in all of them.

These rules are **mandatory** for every change in this repository.

- If a task seems to require breaking a rule, **stop and ask** before
  writing code. Say which rule and why.
- If existing code breaks a rule, do not copy it. See
  [Legacy code — do not copy](#16-legacy-code--do-not-copy).
- Before creating anything (a widget, service, helper, model, failure…),
  search the codebase. **Reuse or extend what exists; never create a
  second copy.** For UI, start with the catalogue in
  [section 21](#21-shared-components-catalogue).
- **Whenever you create a generic component, or add an option to one,
  record it in [section 21](#21-shared-components-catalogue) in the same
  change.**

---

## 0. This app's data strategies

Each feature keeps the data strategy it has. The table below is the
contract; **a feature never moves to another strategy** (no cache added to
a network-only feature, no offline queue, no local-first) unless the user
asks for that change in so many words.

<!-- FILL: one row per feature, e.g. `notes` · network-only · every load hits the network; a failed load shows the error -->

| Feature | Strategy | What that means here |
|---|---|---|

Strategies:

- **network-only** — remote data source only. No `LocalCache`, no
  `GetCached…` use case, no `isStale`.
<!-- module: local-cache -->
- **cache-first** — the saved copy shows first, then the network replaces
  it ([section 20](#20-local-caching--localcache-hive)).
<!-- /module -->
<!-- module: prefs -->
- **device-first** — the device's copy is the truth, the server gets a copy
  in the background ([Device-first data](#device-first-data)).
- **device-only** — settings and flags kept in `PrefUtils`, never sent.
<!-- /module -->

---

## 1. Stack

| Concern | Package / class |
|---|---|
| State management | `flutter_bloc` / `bloc` |
| Equality | `equatable` (states and entities only) |
| Functional results | `fpdart` (`Either`, `Unit`, `Option`) |
| Dependency injection | `get_it` → `sl` in `lib/core/di/injection_container.dart` |
| Routing | `go_router` → `lib/core/router/` |
| HTTP | `NetworkingService` (Dio) → `lib/core/services/networking/` |
| Config | `flutter_dotenv` → `Env` in `lib/core/config/env.dart` |
| Loading placeholders | `skeletonizer` |
| Tests | `flutter_test` with hand-written fakes (no mockito / mocktail / bloc_test) |
<!-- module: prefs -->
| Local storage | `PrefUtils` (SharedPreferences) → `lib/core/services/pref_utils.dart` |
<!-- /module -->
<!-- module: secure-storage -->
| Tokens and sessions | `flutter_secure_storage` → `SecureStorage` in `lib/core/services/secure_storage/` (section 7) |
<!-- /module -->
<!-- module: supabase-session -->
| Backend auth | Supabase (`supabase_flutter`); the session kept by `SecureSessionStorage` |
<!-- /module -->
<!-- module: local-cache -->
| Local cache of server data | `hive_ce` + `hive_ce_flutter` → `LocalCache` in `lib/core/services/local_cache/` (section 20) |
<!-- /module -->
<!-- module: network-images -->
| Network images | `cached_network_image` → `AppNetworkImage` in `lib/core/widgets/app_network_image.dart` (section 19) |
<!-- /module -->
<!-- module: analytics -->
| Analytics | `AnalyticsService` in `lib/core/services/analytics/`; event names in `AppEvents` (section 23) |
<!-- /module -->
<!-- module: katyayani-core -->
| Push, events, attribution | `katyayani_core` → `KoEngagementService` in `lib/core/services/katyayani_core/` |
<!-- /module -->
<!-- module: payments-razorpay -->
| Online payment | `razorpay_flutter` → `PaymentGateway` / `RazorpayPaymentGateway` in `lib/core/services/payments/` |
<!-- /module -->

Do not add a package without asking first.

---

## 2. Project layout

```
lib/
├── main.dart                  # only calls bootstrap()
├── app/
│   ├── bootstrap.dart         # startup: Env, DI, awaited start-up work, runApp
│   └── app.dart               # MaterialApp.router + app-wide BlocProviders
├── core/                      # shared, feature-agnostic code
│   ├── app/                   # Failure, API response types, AppException
│   ├── assets/app_assets.dart # every asset path
│   ├── config/env.dart        # every .env value
│   ├── di/injection_container.dart
│   ├── repositories/base_api_repository.dart  # one Dio per ApiHost
│   ├── router/                # app_router.dart, app_routes.dart, navigator_keys.dart
│   ├── services/networking/   # Networking, NetworkingService, Endpoints
│   ├── theme/                 # app_colors.dart, app_theme.dart, app_tones.dart
│   ├── usecases/usecase.dart  # UseCase<T, Params>, NoParams
│   └── widgets/               # shared UI kit (buttons, form_helper, …)
└── features/<feature>/
    ├── data/
    │   ├── datasources/       # remote / local data sources
    │   ├── exceptions/        # typed exceptions (data layer only)
    │   ├── models/            # JSON + entity conversion
    │   └── repositories/      # *RepositoryImpl
    ├── domain/
    │   ├── entities/
    │   ├── failures/          # feature Failure subclasses
    │   ├── repositories/      # abstract repository contracts
    │   ├── usecases/
    │   └── utils/             # pure Dart helpers
    └── presentation/
        ├── bloc/              # feature-level (app-wide) bloc, e.g. AuthBloc
        ├── <screen>/
        │   ├── bloc/          # screen bloc: *_bloc, *_event, *_state
        │   ├── pages/
        │   ├── widgets/
        │   └── utils/
        └── widgets/           # widgets shared by the feature's screens
```

Folder and file names are `lower_snake_case`. Always write `core` and
`features` in lower case.

---

## 3. Clean Architecture — dependency rules

```
presentation  →  domain  ←  data
```

| Layer | May import | Must NOT import |
|---|---|---|
| `domain/` | `core/app/failure.dart`, `core/usecases/`, `equatable`, `fpdart`, other domain files | Flutter, Dio, `dart:convert`, anything in `data/` or `presentation/` |
| `data/` | `domain/`, `core/`, infrastructure packages | `presentation/` |
| `presentation/` | `domain/`, `core/`, Flutter, bloc | `data/` (models, data sources, exceptions, JSON) |

The request flow is always:

```
Widget → Bloc → UseCase.call(params) → Repository (abstract) → RepositoryImpl → DataSource → NetworkingService / PrefUtils / LocalCache
```

Skipping a layer is not allowed. A bloc never calls a repository or a data
source directly.

---

## 4. Domain layer

### Entities
- Immutable, `extends Equatable`, every field listed in `props`.
- Pure Dart: no JSON, no `fromJson`/`toJson`, no Flutter types.
- Derived values are getters.

### Repository contracts
- `abstract interface class XRepository` in `domain/repositories/`.
- Every method that can fail returns `Future<Either<Failure, T>>`. Use
  `Unit` (`unit`) for "no value".

### Use cases — one class, one job, one `call`
Every use case implements `UseCase<Type, Params>` from
`lib/core/usecases/usecase.dart` and exposes **exactly one** public method,
`call(Params params)`:

```dart
class DeleteNote implements UseCase<Unit, DeleteNoteParams> {
  const DeleteNote(this._repository);

  final NotesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteNoteParams params) {
    return _repository.deleteNote(params.id);
  }
}
```

- The parameter is an entity or a dedicated params class (section 18).
  Use `NoParams` when there is no input: `await _signOut(const NoParams())`.
- Never make the parameter optional, never add a second public method,
  never put Flutter or data code in a use case.

### Failures
- Base class: `Failure` in `lib/core/app/failure.dart`
  (`Failure({required String message, int? code})`, where `code` is the
  HTTP status). Shared: `NetworkFailure`, `ServerFailure(errorCode)`,
  `CacheMissFailure`.
- Feature failures go in `domain/failures/<feature>_failures.dart` and
  extend `Failure` with a default message.
- Presentation maps failure **types** to user-facing text in a
  `presentation/<screen>/utils/failure_message.dart` helper. Never show raw
  API codes, `detail` strings or exception messages to the user — unless
  the app always showed the server's message; then the failure carries it
  and the helper returns it, exactly as before.

---

## 5. Data layer

### Models own serialization
Every model/entity pair ships with all four conversions **on the model**:

```dart
factory XModel.fromJson(Map<String, dynamic> json)
Map<String, dynamic> toJson()
factory XModel.fromEntity(X entity)
X toEntity()
```

- Keep API field names exactly as the API defines them.
- Every pair gets a round-trip test:
  `fromJson → toEntity → fromEntity → toJson == original map`.

### Data sources
- Abstract `interface class` plus an `…Impl`; dependencies come in through
  the constructor.
- Return a **model** or throw a **typed exception** from
  `core/app/exceptions/` (`ServerException`, `ConnectionException` in
  `api_exceptions.dart`, shared) or the feature's `data/exceptions/` (its
  own). Never return JSON maps, `Either` or entities.
- Split by responsibility: `XRemoteDataSource` (HTTP through
  `Networking`), `XLocalDataSource` (device storage), and for auth an
  `AuthLocalDataSource` that alone reads and writes the token.

### Repository implementations
- Call data sources, convert models ↔ entities, catch typed exceptions and
  return `Left(SomeFailure)` / `Right(entity)`.
- Map every known error to a specific `Failure`, with `ServerFailure` as
  the fallback. `ConnectionException` → `NetworkFailure`.
- Nothing above the repository ever sees an exception, a model, JSON or an
  SDK type.

---

## 6. Networking — every HTTP request

**All HTTP goes through `Networking` / `NetworkingService`** in
`lib/core/services/networking/networking.dart`. Never create a `Dio`,
`http.Client` or `HttpClient` anywhere else.

1. **Inject it.** Data sources receive `Networking` in their constructor;
   `get_it` provides the single `NetworkingService`.
2. **Endpoints live in `Endpoints`** (`endpoints.dart`) as
   `static const String` paths, one class per host. Never hardcode a path
   or URL anywhere else.
3. **Relative paths.** Each `ApiHost` has its own Dio and base URL in
   `BaseApiRepo` (`lib/core/repositories/base_api_repository.dart`), with
   that host's timeouts. Path parameters use `{name}` plus
   `pathParameters:`.
4. **Headers.** The default host gets `Content-Type: application/json`
   when there is a body, and `Authorization: Bearer <token>` when a token
   is saved (read at request time) and `NetworkingService` was given
   `secureStorage`. Give it `secureStorage` only when the app sent exactly
   that header on every call to that host; otherwise leave it out and
   reproduce the old headers per call. A body the app sent in another
   encoding keeps its `Content-Type`. Pass `headers:` to add or override
   headers **for that call only**; a header every call to a host needs
   (an API key) comes from one getter in the data source, with the key
   injected from `Env` through DI.
5. **How responses come back:**
   - Whenever the server replied, the service **returns** an `APIResponse`:
     `SuccessResponse` for 200, 201 or 202 (body in `rawData`), and
     `ErrorResponse` for any other status (body in `rawData`, status in
     `errorCode`). A 204 therefore arrives as an `ErrorResponse` with
     `errorCode == '204'`: a data source for which 204 means success
     checks for it.
   - It **throws** an `AppException` only when **no response arrived**
     (offline, timeout): `InternetException`, `RequestTimeoutException`,
     `FetchDataException`.

### Required pattern in a data source
```dart
@override
Future<NoteModel> createNote(NoteDraftModel draft) async {
  final Object? response;
  try {
    response = await _networking.postAPICall(
      endpoint: Endpoints.notes,
      data: draft.toJson(),
    );
  } on AppException catch (e) {   // app_exceptions.dart, imported `show AppException`:
                                  // it has a ServerException of its own
    throw ConnectionException(e.toString());   // no response arrived
  }

  if (response is SuccessResponse) {
    final body = response.rawData;
    return NoteModel.fromJson(body is Map<String, dynamic> ? body : const {});
  }
  if (response is ErrorResponse) throw _toServerException(response);
  throw const ServerException(code: 'INVALID_RESPONSE', status: 0);
}
```
Parse the error body in one private `_toServerException` helper per data
source, and reuse it for every method.

In debug builds `NetworkingService` adds `CurlLoggerInterceptor` to every
host's Dio. Don't add another request logger.

If `NetworkingService` lacks something, extend it **in place** with an
optional parameter that keeps existing callers working. Never write a
second client.

---

## 7. Sessions and tokens

- **Is the user signed in?** Only the auth feature decides: `AuthBloc`
  (app-wide) holds `Authenticated(user)` / `Unauthenticated`, restored at
  start-up by a `RestoreSession` use case.
<!-- module: secure-storage -->
- **The token** is saved and cleared by `AuthLocalDataSource`, in
  `SecureStorage` under `StringConstants.appAuthToken`, never in
  `PrefUtils` or `LocalCache`. `DeviceSecureStorage` is the only file that
  imports `flutter_secure_storage`; `DeviceSecureStorage.init()` runs in
  `bootstrap.dart` and wipes what a previous install left behind (the iOS
  Keychain survives an uninstall).
- **Updates are not fresh installs.** `init()` wipes the store when the
  `DeviceSecureStorage.installedKey` flag is missing, which is true for
  every user updating from a build without this architecture. If that
  build already kept anything in `flutter_secure_storage`, `bootstrap()`
  sets the flag first whenever one of the old build's prefs keys exists, so
  only a true fresh install is wiped.
- **Earlier builds** kept the token in SharedPreferences under the app's
  old key. `AuthLocalDataSource.readToken` moves it over on first read and
  deletes the prefs copy, so nobody is signed out by the update. Keep that
  old key in the data source for as long as old installs may exist.
- **Tests:** `FakeSecureStorage` (`test/helpers/`).
<!-- /module -->
<!-- module: supabase-session -->
- **Supabase:** `Supabase.initialize` runs only in `bootstrap.dart`, with
  `SecureSessionStorage` as `authOptions.localStorage`. Only
  `AuthSessionDataSource` touches `SupabaseClient.auth`.
<!-- /module -->

---

## 8. Configuration and secrets

- Every configuration value comes from `.env` through a typed getter on
  `Env` (`lib/core/config/env.dart`), which throws if the value is missing.
  To add a key: add it to `.env`, add it with a placeholder to
  `.env.example`, add a getter on `Env`.
- Never hardcode URLs, keys or IDs in Dart code.
- `.env` is git-ignored and bundled as a Flutter asset, so it holds only
  client-safe values.

---

## 9. Dependency injection (get_it)

- One container: `lib/core/di/injection_container.dart`, exposing
  `final GetIt sl = GetIt.instance;` and `configureDependencies()`, called
  by `bootstrap()` after `Env.load()`.
- `_registerCore()` registers the core services; each feature has
  `_register<Feature>Data()` (data sources, repository) and a public
  `register<Feature>Feature()` (use cases, blocs) that depends only on the
  repository, so tests can register a fake repository and reuse it.

  | What | Registered as |
  |---|---|
  | Core services, data sources, repositories, use cases | `registerLazySingleton`, by abstract type |
  | Blocs | `registerFactory` |

- Blocs receive **use cases**, never repositories or data sources.
- Only composition code calls `sl<…>()`: `injection_container.dart`,
  `bootstrap.dart` (e.g. to hand one `AuthBloc` to both
  `App` and `AppRouter`), and the `create:` of `BlocProvider`s in `app.dart`
  and pages.

---

## 10. Presentation — BLoC rules

- **Events:** plain Dart classes; never `Equatable`, never `props`.
- **States:** `extends Equatable`, immutable, **every** field in `props`,
  with a `copyWith`. Clearable nullable fields take a getter:
  `copyWith(failure: () => null)`.
- **Extend, don't duplicate.** Add events, fields and handlers to the
  existing bloc; never create a parallel bloc or state class.
- **Blocs never** hold a `BuildContext`, `TextEditingController`,
  `FocusNode` or `GoRouter`, navigate, show dialogs or snackbars, or call
  data sources or repositories directly.
- **Navigation and feedback happen in the UI**, in `BlocListener`s with a
  precise `listenWhen` (section 22 says which kind of feedback). A one-shot
  outcome for a listener (a message to show) carries a counter or id that
  changes every time, so two equal outcomes in a row both reach the UI.
- **Scope:** a screen bloc owns that screen's form and flow; an app-wide
  bloc (provided in `app.dart`) owns cross-screen state such as
  `AuthBloc`. Screens report to app-wide blocs through events.
- **Widgets:** keep `build` free of business logic; read state with
  `context.select`; give interactive widgets stable `Key`s for tests.

---

## 11. UI — theme, colours, assets, routes

- **Colours:** always read them from the theme
  (`Theme.of(context).colorScheme.primary`, `.surface`, `.onSurface`,
  `.error`, …). Colour values live **only** in `AppColors` and are mapped
  into the `ColorScheme` in `AppTheme`. Never use `Color(0x…)`,
  `Colors.xyz` or `AppColors.*` inside a widget.
- **Tones (`AppTones`):** `success`, `info`, `warning` and `rating`, a
  `ThemeExtension` registered on both themes; read them with
  `AppTones.of(context).success`.
- **Text:** `Theme.of(context).textTheme.*` with `copyWith`. When
  overriding a button's `textStyle`, start from the theme style.
- **Fonts:** a display font, if the app has one, is
  `AppTheme.displayFontFamily`; never write a font family name in a widget.
- **Assets:** every path is a `static const` on `AppAssets`, registered in
  `pubspec.yaml`.
- **Page headers:** a page with a title uses `PageHeader`; a page with no
  back button (a tab's root) gets an optional `showBack` (default true)
  added to `PageHeader` in place. A page with a back button and a title uses
  `PageHeader` as its app bar, wrapped in a small feature widget that
  passes the title, the back action and anything shown at the end.
- **Routes:** every route is an entry in the `AppRoute` enum
  (`app_routes.dart`, name + path) and registered in `AppRouter`
  (`app_router.dart`). Navigate with `context.goNamed(AppRoute.x.name)` /
  `pushNamed`; never hardcode a path string. Keep each navigation's kind
  (`go` replaces the stack, `push` adds to it) as the app had it.
<!-- module: commerce-widgets -->
- **Product lists:** a two-column grid is `ProductGrid` /
  `SliverProductGrid`; a sideways row is `ProductRail`; a vertical list of
  rows uses `ProductListTile`. Grid and rail tile heights come from
  `ProductCard.detailsHeightFor(context)`.
<!-- /module -->
<!-- module: network-images -->
- **Network images:** always `AppNetworkImage` (section 19).
<!-- /module -->

---

## 12. Buttons — `PrimaryButton`

**Every primary call-to-action uses `PrimaryButton`**
(`lib/core/widgets/buttons/primary_button.dart`):

```dart
PrimaryButton(
  key: const Key('login_signInButton'),
  label: 'Sign in',
  isLoading: state.isSubmitting,      // shows progress, blocks taps
  onPressed: state.canSubmit ? _submit : null,   // null = disabled look
)
```

- Full width by default; `expand: false` for a pill only as wide as its
  label. Disable it with `onPressed: null`; show progress with
  `isLoading`. Do not restyle it at the call site; add an optional
  parameter to `PrimaryButton` itself if something is missing.
- Other buttons: `SecondaryButton` (outline, the lesser of two actions),
  `CircleIconButton` (round icon button). A new kind of button goes in
  `lib/core/widgets/buttons/`, generic and theme-driven, and into
  section 21.
- Small inline text actions ("Edit", "Resend code") may use Material
  `TextButton` with theme styles.

---

## 13. Form fields — `UniversalFormField` for every input

**Every user input is built with `UniversalFormField`**
(`lib/core/widgets/form_helper/universal_form_field.dart`). Never put a raw
`TextField` / `TextFormField` / `DropdownButton` in a screen.

```dart
UniversalFormField(
  fieldType: UFFType.text,
  label: 'Email',
  initialValue: '',
  onChanged: (value) => context.read<LoginBloc>().add(EmailChanged(value as String)),
).build(
  textInputConfig: TextInputConfig(
    hintText: 'you@example.com',
    textInputType: TextInputType.emailAddress,
    errorText: state.emailError,
  ),
)
```

- Pick the type from `UFFType` with its config class: `TextInputConfig`
  (text, phone, password via `obscureText`), `OtpConfig`,
  `DatePickerConfig`, `TimePickerConfig`, `DropdownConfig`,
  `MultiChipDropdownConfig`, `SearchConfig`, `MultiChipConfig`,
  `RadioConfig`, `ChoiceChipsConfig`, `RatingConfig`.
- **Implemented types:** `text`, `phone`, `search`, `dropdown`,
  `multiChipField`, `radio`, `date`, `time`, `otp`, `choiceChips`,
  `rating`. Every other `UFFType` value renders nothing yet: for such an
  input (a switch, a checkbox, a slider) use the Material widget with theme
  colours, or add the field to the universal system (below).
- Errors held in a bloc go in the config's `errorText`.
- **Keep `initialValue: ''` (non-null)** on a text field unless you pass
  your own `controller` with `useController: true`.
- Wrap a field in `KeyedSubtree(key: const Key('<screen>_<field>Field'))`
  for tests.
- The look comes from `FieldDecorator` and the theme; never style a field
  at the call site.
- A missing input type is added to the universal system
  (`fields/<name>_field.dart`, a `UFFType` value at the end, a config
  class, a `case` in the switch), never built one-off in a feature.

---

## 14. Testing

- Every change keeps `flutter test` green and adds tests for new
  behaviour. Use hand-written fakes that `implements` the interface, in
  `test/helpers/` (`FakeNetworking`, `Fake<X>Repository`, …).

  | Layer | Test |
  |---|---|
  | Domain helpers | pure unit tests |
  | Models | JSON shape and round-trip |
  | Data sources | against `FakeNetworking` returning `SuccessResponse` / `ErrorResponse` or throwing `AppException` |
  | Repositories | exception → failure mapping, order of side effects |
  | Blocs | constructed directly with use cases over a fake repository; assert emitted states |
  | Widgets | register fakes in `sl`, pump `App(router: AppRouter().router)` |

- Widget tests: `sl.registerSingleton<XRepository>(FakeXRepository());
  registerXFeature();` in `setUp`, `tearDown(sl.reset)`.
- Test file paths mirror `lib/`.

---

## 15. Definition of done

1. `dart format` on every touched file.
2. `flutter analyze` reports no issues.
3. `flutter test` passes in full.
4. No hardcoded colours, routes, endpoints, URLs, keys or asset paths.
5. No new packages without approval.
6. Every generic component created or extended is in section 21.
7. Section 0's strategies are unchanged unless the user asked.

---

## 16. Legacy code — do not copy

Files kept as they were, which predate these rules. Leave them alone unless
asked, and never use them as a pattern:

<!-- FILL: one row per file kept outside the architecture, or "none" -->

| File | Problem |
|---|---|

---

## 17. Reference feature

<!-- FILL: name the feature that shows every layer best, e.g. "`features/notes/` — remote data source, repository, use cases, NotesBloc, NotesPage". Follow its shape for new features. -->

---

## 18. Multi-host networking (`ApiHost`)

- Every HTTP method of `Networking` takes `ApiHost host`, defaulting to the
  app's main backend (the first value of the enum).
- `BaseApiRepo` holds one `Dio` per host (`dios`), each with its own base
  URL from `Env` and its own timeouts. Hosts that must never receive the
  app's token are listed in `NetworkingService._thirdPartyHosts`.
- One endpoint class per host (`Endpoints`, then e.g. `PaymentsEndpoints`).
- **Host selection is the repository's job**; use cases and blocs never
  see `ApiHost`, endpoints or headers.
- To add a host: a value in `ApiHost`, a `Dio` in `BaseApiRepo`, an
  endpoint class, a base-URL getter on `Env`.

### Use-case params
When a use case needs input that is not an existing entity, create a
params class in the same file, with a `const` constructor and no
`Equatable`. The use case unpacks it and passes primitives or entities to
the repository.

<!-- module: network-images -->
---

## 19. Network images — `AppNetworkImage`

**Every image loaded from a URL uses `AppNetworkImage`**
(`lib/core/widgets/app_network_image.dart`), built on
`cached_network_image`; it is the only file that imports it.

```dart
AppNetworkImage(url: product.thumbnail, width: 56, height: 56)
```

- `null` or `''` shows the placeholder; give it a bounded box.
- Never use `Image.network`, `NetworkImage` or `CachedNetworkImage`
  directly. Missing something? Add an optional parameter.
- Bundled images go through `AppAssets` and `Image.asset`.
<!-- /module -->

---

## 20. Storage

| Data | Store |
|---|---|
<!-- module: local-cache -->
| A copy of server data shown before the network answers | `LocalCache` (Hive) |
<!-- /module -->
<!-- module: secure-storage -->
| Tokens and sessions | `SecureStorage` (section 7) |
<!-- /module -->
<!-- module: prefs -->
| Small app-owned values (flags, settings) and device-first lists | `PrefUtils` |
<!-- /module -->

- **Keep every storage key the app already uses**, or move the value on
  first read, so no user loses data or is signed out by an update.
- Only local data sources read or write storage. Blocs, use cases and
  repositories never touch it directly.

<!-- module: local-cache -->
### Local caching — `LocalCache` (Hive)

`lib/core/services/local_cache/` is the **only** place that imports Hive.
`LocalCache` (`read(box, key, version, maxAge)`, `write`, `delete`,
`clearBox`, `clearUserScoped`) stores `{version, saved_at, data}` per
entry; `HiveLocalCache.init()` runs in `bootstrap.dart` before
`configureDependencies()` and never throws. `CacheBoxes` names one box per
feature (`all`, `userScoped`). A miss is `CacheMissFailure`, never shown.

**Recipe** for a feature that already showed a saved copy first:

1. **Box** in `CacheBoxes` (`userScoped` too when it is the user's data).
2. **Local data source** `<Feature>LocalDataSource` over `LocalCache`:
   keys and `schemaVersion` as `static const`; read returns a model or
   `null`; write returns `void`. Expiry is the app's own (`maxAge`), and
   any extra rule the app had (deleting an expired entry, a strict
   boundary) is kept here.
3. **Repository:** `getCached<Thing>()` reads only the local source
   (`null` or `CacheException` → `Left(CacheMissFailure())`);
   `get<Thing>()` fetches, then saves in `try { } on CacheException { }`
   so a cache write never fails a request; on failure it returns the
   failure and never falls back to the cache silently.
4. **Use cases:** `GetCached<Thing>` next to `Get<Thing>`.
5. **Bloc state:** `isStale`, `isRefreshing`, `isBusy`. Start: cached
   first (emit `loaded`, `isStale: true` on a hit), then refresh. Refresh:
   `if (state.isBusy) return;`; with data on screen a failure keeps the
   data and sets `failure`; with nothing on screen it emits `failure`.
6. **Page:** the failed-refresh message is shown from a `BlocListener`
   with a precise `listenWhen`, with the app's own text.
7. **Tests:** `FakeLocalCache` (`test/helpers/`); repository: hit, miss,
   write after fetch, throwing write still `Right`; bloc: the emitted
   sequences.

Never add `LocalCache` to a feature that did not already show saved data.
<!-- /module -->

<!-- module: prefs -->
### Device-first data
For a small user-owned list whose **device copy is the truth** (kept in
`PrefUtils`, with a `pending` flag):

- Writes go to the device only and return at once; the bloc then pushes
  in the background (`unawaited(push…)`). The next tap never waits on the
  network.
- The pending / push / sync decisions live in the repository (`push<X>`,
  `sync<X>`); the bloc only calls the use cases.
- Pushes keep the app's own timing (one per change, or merged and one at a
  time, whichever it had); a change made during a push stays `pending`.
- A sync on start: while `pending` the device wins and is sent; otherwise
  the server's copy replaces the device's.
- Failed pushes are silent and retried by the next push or sync.
<!-- /module -->

### Going local-first
Full local-first (watch streams, an outbox, a sync service) is not used.
**Ask before making any feature local-first**; it is decided per feature.

---

## 21. Shared components catalogue

Every generic UI component lives in `lib/core/widgets/` and is listed here.
**Look here before building any UI**; extend a close match with an optional
parameter whose default keeps every call site unchanged. Whenever you create
or extend one, update its row and give it a widget test under
`test/core/widgets/`.

A component is **generic** when it takes plain values and callbacks and has
no feature logic, feature text or bloc access. A widget that reads a bloc is
a feature widget and stays in the feature.

### Buttons — `lib/core/widgets/buttons/`

| Component | File | Use it for | Options |
|---|---|---|---|
| `PrimaryButton` | `primary_button.dart` | Every primary call-to-action (section 12) | `label`, `onPressed`, `icon`, `leadingIcon`, `isLoading`, `height`, `expand`, `warm` |
| `SecondaryButton` | `secondary_button.dart` | Outline pill for the lesser of two actions | `label`, `onPressed`, `isLoading`, `height`, `expand`, `warm`, `destructive`, `leadingIcon` |
| `CircleIconButton` | `circle_icon_button.dart` | Round icon button: header actions, back, search | `icon`, `onPressed`, `tooltip`, `size`, `filled`, `accent`, `isLoading`, `badgeCount` |
<!-- module: commerce-widgets -->
| `HeartToggleButton` | `heart_toggle_button.dart` | A favourite / wishlist heart | `isActive`, `onPressed`, `size`, `overImage`, `isLoading`, `tooltip` |
| `SlideActionButton` | `slide_action_button.dart` | A call-to-action confirmed by dragging its thumb | `label`, `prefixLabel`, `onPressed`, `icon`, `isLoading`, `height` |
| `DashedOutlineButton` | `dashed_outline_button.dart` | "+ Add new …" at the top of a list | `label`, `onPressed`, `icon`, `isLoading`, `height` |
| `AddButton` | `add_button.dart` | The small "ADD +" on a product | `onPressed`, `label`, `compact` |
<!-- /module -->

<!-- module: commerce-widgets -->
### Products — `lib/core/widgets/product/`

| Component | File | Use it for | Options |
|---|---|---|---|
| `ProductCard` | `product_card.dart` | A product tile in a grid or rail | `testId`, `title`, `subtitle`, `imageUrl`, `price`, `mrp`, `discountPercent`, `soldCount`, `variantLabel`, `inStock`, `isLowStock`, `isComingSoon`, `formatPrice`, `mrpLabel`, `inStockLabel`, `lowStockLabel`, `outOfStockLabel`, `comingSoonLabel`, `soldLabel`, `discountLabel`, `quantity`, `isWishlisted`, `onWishlistPressed`, `onAdd`, `onIncrement`, `onDecrement`, `onTap`; `ProductCard.detailsHeightFor(context)` |
| `ProductListTile` | `product_list_tile.dart` | A product row in a vertical list | the `ProductCard` keys and callbacks, plus `formatPrice`, `outOfStockLabel`, `comingSoonLabel`, `discountLabel`, `caption`, `addLabel`, `keyPrefix`, `imageSize`, `framed`, `variantLabel`, `priceNote`, `controlPlacement`, `addIcon`, `tonalAdd`, `actionLabel`, `actionIcon`, `onAction`, `onLongPress` |
| `ProductGrid` / `SliverProductGrid` | `product_grid.dart` | Two-column grid of `ProductCard`s | `itemCount`, `itemBuilder` |
| `ProductRail` | `product_rail.dart` | Sideways-scrolling row of `ProductCard`s | `itemCount`, `itemBuilder`, `trailing`, `horizontalPadding` |
| `ExploreMoreCard` | `explore_more_card.dart` | Last tile of a rail | `countLabel`, `onTap`, `label`, `imageUrls`, `semanticLabel` |
| `OrderLineTile` | `order_line_tile.dart` | One line of a placed order | `title`, `quantity`, `unitPrice`, `total`, `imageUrl` |
| `QuantityStepper` | `quantity_stepper.dart` | "− n +" for a quantity | `quantity`, `onIncrement`, `onDecrement`, `incrementKey`, `decrementKey`, `height`, `buttonWidth`, `filled`, `removeAtOne` |
| `CartSummaryBar` | `../cart/cart_summary_bar.dart` | Floating "View cart · N items" pill | `itemCount`, `onPressed`, `thumbnailUrls`, `label` |
<!-- /module -->

### Chips, headers, lists and search

| Component | File | Use it for | Options |
|---|---|---|---|
| `InfoChip` | `chips/info_chip.dart` | Small rounded label | `label`, `icon`, `tone` |
| `CategoryChip` | `chips/category_chip.dart` | Icon tile with a caption | `label`, `icon`, `onTap`, `selected`, `width` |
| `FilterChipButton` | `chips/filter_chip_button.dart` | Pill-shaped filter trigger or pickable chip; tabs on a `PageHeader` | `label`, `icon`, `showDropdownArrow`, `selected`, `fillWhenSelected`, `onHeader`, `onPressed` |
| `SectionHeader` | `section_header.dart` | Section title with an optional "View All →" | `title`, `actionLabel`, `onAction`, `actionKey` |
| `SectionLabel` | `section_label.dart` | Small uppercase caption naming a block | `title`, `padding` |
| `PageHeader` | `page_header.dart` | The app bar of every page with a back button (section 11) | `title`, `onBack`, `subtitle`, `subtitleKey`, `trailing`, `bottom`, `backKey`, `backTooltip` |
| `IconListTile` | `icon_list_tile.dart` | A tappable row in a list of choices or settings | `icon`, `title`, `subtitle`, `overline`, `onTap`, `leading`, `showChevron`, `isLoading`, `filled`, `badgeLabel`, `dense` |
| `FormSectionTitle` | `form_section_title.dart` | Heading of a group of fields | `title`, `icon`, `description`, `topPadding` |
| `AppSearchBar` | `search/app_search_bar.dart` | The search input | `onChanged`, `hintText`, `initialValue`, `autofocus`, `onSubmitted`, `trailingIcon`, `onTrailingPressed`, `trailingTooltip` |
| `SearchTriggerBar` | `search/search_trigger_bar.dart` | A bar that opens a search screen | `onTap`, `hintText`, `onCameraTap`, `cameraTooltip` |

### Surfaces and feedback

| Component | File | Use it for | Options |
|---|---|---|---|
| `AppCard` | `app_card.dart` | A rounded surface grouping one block of a page | `child`, `padding`, `title`, `icon`, `trailing`, `onHeaderTap`, `headerKey`, `accent`; `AppCard.divider(context)` |
| `ReloadWidget` | `reload_widget.dart` | Centred error message with a retry button, for `status == failure` | `errorMessage`, `onReload`, `color`; its button is a refresh icon whose tooltip is "Retry" |
| `ProgressIndecator` | `progress_indecator.dart` | Spinner for a pane with no skeleton | `color`, `strokeWidth` |
| `AppInfoSheet` | `sheets/app_info_sheet.dart` | A message the user acknowledges (section 22) | `title`, `message`, `tone`, `icon`, `actionLabel`; `show` → `bool` |
| `AppPickerSheet` | `sheets/app_picker_sheet.dart` | A bottom sheet to choose something | `title`, `icon`, `child`, `footer`; `show<T>` |
| `OptionTile` | `sheets/option_tile.dart` | One row of a pick-one list | `label`, `selected`, `onTap`, `icon`, `subtitle` |
<!-- module: network-images -->
| `AppNetworkImage` | `app_network_image.dart` | Every image from a URL (section 19) | `url`, `placeholderIcon`, `fit`, `width`, `height` |
<!-- /module -->
<!-- module: app-logo -->
| `AppLogo` | `app_logo.dart` | A bundled brand image | `size`, `color`, `asset`, `semanticLabel` |
<!-- /module -->

### Form inputs
Every input goes through `UniversalFormField` (section 13).

### Loading skeletons
Loading placeholders come from `skeletonizer`: put the screen's real
widgets, filled with placeholder values, inside `Skeletonizer`, with the
theme's colours in the effect. Never draw bones by hand.

---

## 22. Feedback

| Situation | Use |
|---|---|
| The user must read it, or there is one clear next step | `AppInfoSheet.show(context, …)` |
| A passing note that needs no answer | `SnackBar` |
| A screen has nothing to show (`status == failure`) | `ReloadWidget` |
| An input is wrong | the field's `errorText` |

- Feedback is shown from the UI (a `BlocListener` or a tap handler),
  never from a bloc.
- **Every text the user sees is kept word for word** when code moves into
  this architecture; only the widget that shows it follows this table.
- Do not add an `AlertDialog` or a hand-built message sheet for a
  message. A confirmation with two choices ("Cancel" / "Delete") that the
  app already had keeps both choices: keep its dialog (listed in section 16)
  until `AppInfoSheet` gains a second action.

<!-- module: analytics -->
---

## 23. Analytics

- Features report events through `AnalyticsService`
  (`lib/core/services/analytics/`), never an SDK. Blocs receive it by
  constructor injection; screens read it with
  `context.read<AnalyticsService>()` from a listener or tap handler, never
  from `build`.
- Event names live in `AppEvents`, word for word as the app already sends
  them; never type a name at a call site.
- Each SDK is wrapped by one class (an `AnalyticsService` implementation
  or an `AnalyticsDestination`) that is the only file importing it.
- Keep every event's moment and properties exactly as they were.
<!-- /module -->
<!-- module: katyayani-core -->
- **Katyayani Core** is reached only through `KoEngagementService`
  (`identify`, `resetIdentity`, `track`, push), started in `bootstrap.dart`
  without holding up the first frame. Never call
  `FirebaseMessaging.onBackgroundMessage`.
<!-- /module -->
<!-- module: ga4-meta -->
- **Google Analytics 4 and Meta** are `AnalyticsDestination`s behind
  `MultiDestinationAnalyticsService`; naming rules live in
  `analytics_event_mapper.dart`. Event names and parameters the app
  already sends to GA4 or Meta reach them unchanged: add a special name
  to the mapper only when the old app sent one.
<!-- /module -->
