---
name: applying-mymali-architecture
description: Use when restructuring, standardising or migrating a Flutter app to the MyMali / Katyayani architecture (clean architecture, flutter_bloc, get_it sl, go_router, NetworkingService, UniversalFormField, PrimaryButton, AGENTS.md), or when asked to make a Flutter project "look like MyMali" or use MyMali's services
---

# Applying the MyMali architecture

## Overview

Every company Flutter app gets **MyMali's structure, names and services**,
copied from this skill's templates, while **its behaviour stays exactly as it
is**. The architecture changes how the code is built, never what the app
does.

**Two rules decide everything:**
1. **Names are MyMali's, character for character.** `NetworkingService`,
   not `ApiClient`; `sl`, not `locator`; `UseCase.call`, not
   `execute`. Copy them from `templates/`; never retype or rename.
2. **Behaviour is the app's, word for word.** Same endpoints, headers,
   statuses, timeouts, texts, storage keys, events, navigation, colours
   and **data strategy**. A network-only feature never gains a cache; a
   cache keeps its expiry; nothing is added "for later".

**Violating the letter of these rules is violating their spirit.**

## What changes and what stays

| Changes to MyMali's | Stays the app's own |
|---|---|
| Folders, class, file and method names | Endpoints, headers, bodies, statuses, timeouts |
| The services (`NetworkingService`, `Env`, `PrefUtils`, `SecureStorage`, `LocalCache`, `sl`, `AppRouter`) | Each feature's data strategy (network-only, cache-first, device-first) |
| The UI kit: `PrimaryButton`, `UniversalFormField`, `PageHeader`, `ReloadWidget`, skeletons, and feedback through `SnackBar` / `AppInfoSheet` (toast packages go) | Every text the user reads, every storage key, every analytics event |
| Start-up gains `Env.load()` and the installed services' `init()` | What the first screen is and what decides it |
| Debug builds log each request (`CurlLoggerInterceptor`); release builds log nothing | The colour values, the `ThemeData` each mode builds, and the theme mode rule |
| Colours move into `AppColors` / `AppTheme` | Navigation: where each action leads, push vs replace, back behaviour |
| Network images go through `AppNetworkImage` (disk-cached); a whole-screen spinner becomes a `skeletonizer` skeleton of the same screen; app bars become `PageHeader` | Which data is shown, when, and from where |
| Storage moves to MyMali's stores (`SecureStorage`, `LocalCache`, `PrefUtils`) | What is stored: every value moves over once from its old key, so no user loses it |

These are the architecture, not optional extras: install and use them even
when the old app looked or stored things differently. "It would change
what users see" is not a reason to skip a kit component; it is a reason to
keep the texts, colours and data identical inside it.

The shared widgets take their colours from the app's `ColorScheme`, as
its unchanged `ThemeData` produces it. Where the old widgets hardcoded a
colour that the scheme does not hold (with Material 3, `primarySwatch` is
ignored, so `colorScheme.primary` is Flutter's default), a kit component
shows the scheme's colour instead: list each such case in
`MIGRATION_NOTES.md` so the owner can decide; do not change the theme to
compensate. Never add a restyle flag to a shared
widget to imitate an old widget's look.

## The procedure

Work in this order. Commit after each step.

1. **Audit.** Read all of `lib/` and `test/`, then write `BEHAVIORS.md`
   as described in [audit.md](audit.md). Pick the modules from its table.
2. **Install core.** From the project root:
   ```
   dart <skill>/tool/install_core.dart --list
   dart <skill>/tool/install_core.dart --modules <from the audit> --hosts <one per backend, main first>
   ```
   Run the `flutter pub add` line it prints: those packages are part of
   the architecture. If one of them is not allowed in this project, stop
   and ask; never rewrite a template's internals to avoid a package. The
   installer also writes `AGENTS.md` (trimmed to the modules) and
   `CLAUDE.md`. Never hand-copy or rewrite a template file; if it lacks
   something, extend it in place with an optional parameter whose default
   keeps it unchanged, and add the option to `AGENTS.md` section 21.
3. **Fill the per-app core files** (each starts empty or with
   placeholders): `env.dart` + `.env` + `.env.example` (every hardcoded
   URL / key / id, same values), `endpoints.dart` (every path),
   `base_api_repository.dart` (one Dio per host with the app's exact
   timeouts), `app_colors.dart` + `app_theme.dart` (the app's own colours
   and modes, never MyMali's green), `app_assets.dart`,
   `injection_container.dart`, `bootstrap.dart`, `app.dart`, `app_routes.dart`,
   `app_router.dart`. Shapes: [reference/app_shell.md](reference/app_shell.md).
4. **Migrate one feature at a time**, all layers, with tests (shape:
   `reference/support_feature/`):
   - `data/`: `<X>Model` with `fromJson`, `toJson`, `fromEntity`,
     `toEntity`; `<X>RemoteDataSource` + `Impl` over `Networking`
     (`AGENTS.md` section 6 pattern); typed exceptions.
   - `domain/`: entity, `abstract interface class <X>Repository`, one use
     case per action (`UseCase<T, Params>`, one `call`), failures.
   - `presentation/<screen>/`: `bloc/` (events plain, state `Equatable`
     with `copyWith`), `pages/`, `widgets/`, `utils/` (failure → text).
   - DI: `_register<X>Data()` + `register<X>Feature()`.
5. **Remove the old code** once nothing uses it: providers, services,
   models, the old HTTP client, and any half-built wrapper with another
   name. Remove a package only when nothing imports it.
6. **Fill `AGENTS.md`**: section 0 (each feature's strategy, from
   `BEHAVIORS.md`), 16 (legacy kept, or "none"), 17 (the reference feature).
7. **Verify** (below), then write `MIGRATION_NOTES.md`.

## Data strategy mapping

| The app today | After |
|---|---|
| Network only (every load hits the network) | Remote data source only. No `LocalCache`, no `GetCached…`, no `isStale` |
| Shows a saved copy first, then the network | `LocalCache` recipe (`AGENTS.md` section 20), with the app's expiry and failure behaviour |
| Device copy is the truth, server gets a copy | `PrefUtils` + `pending` flag, same storage key and JSON shape |
| Settings / flags | `PrefUtils`, same keys |
| Token in SharedPreferences | `SecureStorage`; `AuthLocalDataSource` reads the old key once, moves it, deletes it |
| A cache in SharedPreferences / a file / sqflite | `LocalCache`; the local data source reads the old entry once (old key, old shape, with its own `saved_at`), writes it to `LocalCache` and deletes it, so the first launch after the update still shows the saved copy |

| Values already in `flutter_secure_storage` | `SecureStorage` with the same keys; `bootstrap()` sets `DeviceSecureStorage.installedKey` before `init()` whenever an old prefs key exists, or every updating user is signed out |

**Every move from an old key is tested:** old value present → it is read,
moved and deleted; absent → nothing happens.

## Behaviour that must survive the move

| Old code | In MyMali's shape |
|---|---|
| A 204-only success | `NetworkingService` returns 204 as `ErrorResponse`; the data source treats `errorCode == '204'` as success, and 200 as an error, as before |
| Any 2xx is a success (Dio's default) | the data source also treats an `ErrorResponse` whose `errorCode` starts with `2` as success |
| A cache expiry with a strict boundary ("older than or equal to 10 min is stale") | `maxAge` plus the exact boundary check, and the delete of a stale entry, in the local data source |
| Device-first sync rules (pending, push, sync) | in the repository (`push<X>`, `sync<X>`), as MyMali's wishlist; the bloc only calls the use cases |
| A timeout of N seconds | `BaseOptions` of that host in `BaseApiRepo`, same N: Dio's connect / send / receive timeouts for the kinds the app set; a whole-request timeout (`http`'s `.timeout(N)`) becomes `connectTimeout` and `receiveTimeout` of N, noted in `MIGRATION_NOTES.md` as the nearest Dio equivalent |
| `ThemeData(primarySwatch: …)`, `ThemeData.dark()`, a seed | `AppTheme.light` / `.dark` return that same `ThemeData`, values from `AppColors`, plus `AppTones`; never switch it to another constructor |
| A home widget swapped in place on sign-in / sign-out | a `redirect` between exactly those two locations, so routes the old app left alone stay untouched |
| A "Retry" text button on a failed screen | `ReloadWidget`; its "Retry" is the button's tooltip and label for screen readers |
| A settings switch row | a Material `SwitchListTile` with theme colours (the UI kit has no switch yet) |
| A header on every request | default headers (token) or one header getter in the data source, key from `Env` |
| An interceptor (e.g. 401 → sign out) | the repository maps 401 to an `UnauthorizedFailure`; the bloc that got it reports `AuthSignedOutByServer` to `AuthBloc` — same trigger, same effect, nothing more |
| A toast | a `SnackBar` with the same text, at the same moment (a toast is a passing note); the toast package goes |
| A snackbar or a one-button dialog | the same text, shown per `AGENTS.md` section 22 |
| A two-choice confirmation ("Cancel" / "Delete") | kept as it is, with both choices, and listed in `AGENTS.md` section 16 |
| Headers other than `Content-Type: application/json` + `Bearer <token>` | `NetworkingService` without `secureStorage`, and the old headers passed per call or from the data source's header getter |
| The server's error text shown to the user | the failure carries it; the failure-message helper returns it |
| A hardcoded colour in a widget | an `AppColors` constant with the same value, read through an `AppTones` tone added for it (or the `ColorScheme` role whose value it already equals), so the theme itself does not change |
| `Navigator.push` / `context.go` / a swapped `home` | `AppRoute` + `goNamed` / `pushNamed`, keeping push vs replace |
| An analytics call | `AnalyticsService` + `AppEvents`, same name, properties and moment |
| An analytics SDK of its own | one `AnalyticsService` implementation wrapping it (the only file importing the SDK); its methods map one to one (`identify` → the service's identify, `reset` → sign-out) |
| `screen()` calls in `initState` | the same calls at the same moments; MyMali's router-based screen tracking only if it fires exactly the same names in the same order |

## Verify

1. `dart format .`, `flutter analyze` (no issues), `flutter test` (all pass).
2. Walk `BEHAVIORS.md` line by line and point to the code that keeps each
   one. Fix any that changed.
3. `git diff` the base commit: every package added is printed by the
   installer for a chosen module; no strategy changed.
4. `MIGRATION_NOTES.md`: modules installed and why, what moved where,
   anything kept outside the architecture (and in `AGENTS.md` section 16),
   and every open question for the user.

## Red flags — stop

- "The team lead / deadline says skip use cases / data sources" → the
  layers are the architecture; skipping them is not this skill. Do the
  layers; if truly impossible, stop and ask, and say which rule.
- "There's already an `ApiClient` / `api_service` — keep it" → its
  behaviour moves into `NetworkingService` + data sources; then delete it.
- "Keep the providers, they work" → blocs replace them; no parallel state.
- "I'll add caching / offline while I'm here" → never; see section 0.
- "Close enough name" (`ApiService`, `Result`, `locator`, `execute`) →
  copy the template's name.
- "Change the key / text / colour, it's cleaner" → keep the value.
- "MyMali has portrait lock / Firebase / Supabase, add it" → only what the
  app already had.
- "Keep it in prefs / keep the AppBar / skip the skeleton so nothing
  changes" → MyMali's store and kit, with the old values moved over and the
  old texts inside.
- "Only one host, so no `ApiHost`" / "trim the form helper to what we use"
  → install the module whole; names exist even when there is one value.

## Common mistakes

| Mistake | Fix |
|---|---|
| Writing `NetworkingService` by hand | Run `install_core.dart`; extend its file in place |
| `AppColors` left at the template value | Use the app's colours; the look must not change |
| Every endpoint on one host while the app called two | One `ApiHost` per backend, `--hosts a,b` |
| Raw `TextField` / `ElevatedButton` left in a page | `UniversalFormField` / `PrimaryButton`, same labels |
| Old tests deleted | Port each one to the new classes with the same assertions |
| URLs and keys left in Dart ("no async before first frame") | `Env` over `.env`; `Env.load()` in `bootstrap()` is part of the architecture |
| Token left in SharedPreferences "to avoid signing people out" | `SecureStorage`, with the one-time move from the old key |
| `context.appColors` or another colour accessor of its own | `Theme.of(context).colorScheme` / `AppTones.of(context)` |
| Events or params extending `Equatable` | Events are plain classes; params classes too |
| `NoteModel extends Note` | Separate model with `toEntity` / `fromEntity` |
| A use case taking a `String` / `bool` | A params class (`GetNotesParams`) or an entity |
| `Failure` in `core/error/failures.dart` | `lib/core/app/failure.dart`, from the templates |
| Retry as a `TextButton` on a failed screen | `ReloadWidget` |
